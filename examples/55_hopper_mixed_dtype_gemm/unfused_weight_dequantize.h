#pragma once

#include "cute/tensor.hpp"

#include <cuda.h>
#include "helper.h"

template <class QuantizedElement, 
          class DequantizedElement,
          class OperandLayout,
          class ElementScale,
          class ScaleBroadCastLayout,
          class ThrLayout>
__global__ void dequantize_weight_kernel(DequantizedElement* dq_buffer,
                                         const QuantizedElement* q_buffer,
                                         const OperandLayout operand_layout,
                                         const ElementScale* scale_buffer,
                                         const ScaleBroadCastLayout broadcasted_scale_layout,
                                         ThrLayout thr_layout) {
  using namespace cute;

  // Represent the full tensors to gmem elements. 
  // These are expected to have shape [MN, K, L]
  Tensor gmem_op_dq = make_tensor(make_gmem_ptr(dq_buffer), operand_layout);
  auto init_quantized_iterator = [&]() {
    if constexpr (cute::sizeof_bits_v<QuantizedElement> >= 8) {
      return make_gmem_ptr(q_buffer);
    } else {
      return subbyte_iterator<const QuantizedElement>(q_buffer);
    }
  };
  Tensor gmem_op_q  = make_tensor(init_quantized_iterator(), operand_layout);
  // While the scales are expected to have shape [MN, G, L] but with a stride to allow broadcasting
  // It is expected that K % G == 0
  Tensor gmem_scale_broadcasted = make_tensor(make_gmem_ptr(scale_buffer), broadcasted_scale_layout);

  // Assign 1 thread per element in the thread block
  auto blk_shape = make_shape(size<0>(thr_layout), _1{}, _1{}); // 
  auto blk_coord = make_coord(_, blockIdx.x, blockIdx.y);  // (MN, K, L)

  // Tile across the block
  auto gOp_dq = local_tile(gmem_op_dq, blk_shape, blk_coord);
  auto gScale = local_tile(gmem_scale_broadcasted, blk_shape, blk_coord);
  auto gOp_q  = local_tile(gmem_op_q, blk_shape, blk_coord);
  
  auto tOpDq_gOpDq = local_partition(gOp_dq, thr_layout, threadIdx.x);
  auto tScale_gScale = local_partition(gScale, thr_layout, threadIdx.x);
  auto tOpQ_gOpQ = local_partition(gOp_q, thr_layout, threadIdx.x);

  // Make a fragment of registers to hold gmem loads
  Tensor rmem_op_q = make_fragment_like(tOpQ_gOpQ(_, _, _, 0));
  Tensor rmem_scale = make_fragment_like(tScale_gScale(_, _, _, 0));
  Tensor rmem_op_dq = make_fragment_like(tOpDq_gOpDq(_, _, _, 0));

  Tensor pred_id = make_identity_tensor(shape(operand_layout));
  auto pred_blk_tile = local_tile(pred_id, blk_shape, blk_coord);
  auto pred_thr_partition = local_partition(pred_blk_tile, thr_layout, threadIdx.x);

  const auto num_iters = size<3>(tOpDq_gOpDq);
  
  for (int ii = 0; ii < num_iters; ++ii) {
    const auto thread_offset = get<0>(pred_thr_partition(0, 0, 0, ii));
    if (thread_offset < size<0>(operand_layout)) {
      copy(tOpQ_gOpQ(_, _, _, ii), rmem_op_q);
      copy(tScale_gScale(_, _, _, ii), rmem_scale);
      transform(rmem_op_q, rmem_op_dq, [] (const QuantizedElement& elt) { return DequantizedElement(elt); } );
      transform(rmem_op_dq, rmem_scale, rmem_op_dq, multiplies{});
      copy(rmem_op_dq, tOpDq_gOpDq(_, _, _, ii));
    }
  }
}

template <class QuantizedElement, 
          class DequantizedElement,
          class OperandLayout,
          class ElementScale,
          class ScaleLayout>
void dequantize_weight(DequantizedElement* dq_buffer,
                       const QuantizedElement* q_buffer,
                       const OperandLayout operand_layout,
                       const ElementScale* scale_buffer,
                       const ScaleLayout scale_layout) {
  
  using namespace cute;

  constexpr int tpb = 128;
  auto thr_layout = make_layout(make_shape(Int<tpb>{}));

  const auto num_rows = get<0>(shape(operand_layout));
  const auto num_cols = get<1>(shape(operand_layout)); // [MN, K, L]
  const auto batches = get<2>(shape(operand_layout));  // [MN, K, L]
  const auto num_cols_scale = get<1>(shape(scale_layout)); // [MN, G, L]

  if (num_rows != size<0>(scale_layout)) {
    std::cerr << "Invalid first dimension for scales. Must match first dim for weights."
              << " But got shapes " << shape(operand_layout) << " " << shape(scale_layout) 
              << std::endl;
    exit(-1);
  }

  if (num_cols % num_cols_scale != 0) {
    std::cerr << "Invalid shape for weight / scales. Weight cols must be a multiple of scale cols."
              << " But got shapes " << shape(operand_layout) << " " << shape(scale_layout) 
              << std::endl;
    exit(-1);
  }

  const auto scale_stride0 = get<0>(stride(scale_layout));
  const auto scale_stride1 = get<1>(stride(scale_layout));
  const auto scale_stride2 = get<2>(stride(scale_layout));

  auto scale_shape_bcast = make_shape(num_rows, make_shape(num_cols / num_cols_scale, num_cols_scale), batches);
  auto scale_stride_bcast = make_stride(scale_stride0, make_stride(0, scale_stride1), scale_stride2);
  auto scale_layout_bcast = make_layout(scale_shape_bcast, scale_stride_bcast);

  const auto blocks_x = num_cols;
  const auto blocks_y = batches;

  dim3 blocks(blocks_x, blocks_y, 1);
  dequantize_weight_kernel<<<blocks, tpb>>>(dq_buffer, q_buffer, operand_layout, scale_buffer, scale_layout_bcast, thr_layout);
  CUDA_CHECK(cudaDeviceSynchronize());
}


template <int ELTS_PER_THREAD,
          class SubbyteType>
__global__ void pack_data_kernel(SubbyteType* packed_data_ptr, 
                                 const uint8_t* unpacked_data_ptr,
                                 const size_t max_elts) {
  using namespace cute;
  
  const size_t tid = blockIdx.x * blockDim.x + threadIdx.x;
  uint8_t data[ELTS_PER_THREAD];
  if (tid < max_elts) {
    const uint8_t* read_ptr = unpacked_data_ptr + tid * ELTS_PER_THREAD;    
    for (int ii = 0; ii < ELTS_PER_THREAD; ++ii) {
      data[ii] = read_ptr[ii];
    }


    using WriteType = cute::array_subbyte<SubbyteType, ELTS_PER_THREAD>;    
    WriteType* write_ptr = reinterpret_cast<WriteType*>(packed_data_ptr);

    WriteType packed_data;
    for (int ii = 0; ii < ELTS_PER_THREAD; ++ii) {
      SubbyteType elt(data[ii]);
      packed_data[ii] = elt;
    }
    write_ptr[tid] = packed_data;
  }

}

template <class SubbyteType, 
          class OperandLayout>
void pack_data(SubbyteType* packed_data, const uint8_t* unpacked_data, const OperandLayout operand_layout) {
  static_assert(cute::sizeof_bits_v<SubbyteType> < 8, "First operand must be a sub-byte type");
  constexpr int packed_elements = 8 / cute::sizeof_bits_v<SubbyteType>;

  if (cute::stride<0>(operand_layout) == 1 && (cute::shape<0>(operand_layout) % packed_elements)) {
    std::cerr << "Invalid shape / stride for dimension 0. Contiguous dimension must be a multiple of "
              << packed_elements << std::endl;
    exit(-1);    
  }

  if (cute::stride<1>(operand_layout) == 1 && (cute::shape<1>(operand_layout) % packed_elements)) {
    std::cerr << "Invalid shape / stride for dimension 1. Contiguous dimension must be a multiple of "
              << packed_elements << std::endl;
    exit(-1);    
  }

  const int64_t total_threads = cute::size(operand_layout) / packed_elements;

  const int threads_per_block = 256;
  const int64_t num_blocks = (total_threads + threads_per_block - 1) / threads_per_block;
  pack_data_kernel<packed_elements><<<int(num_blocks), threads_per_block>>>(packed_data, unpacked_data, total_threads);
  CUDA_CHECK(cudaDeviceSynchronize());
}
