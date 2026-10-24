/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 **************************************************************************************************/

///////////////////////////////////////////////////////////////////////////////////////////////////
//
//        CuTe Tutorial for SM100 Programming -- MXFP8 x MXFP8 block-scaled variant (TMA mainloop)
//
// This file is a block-scaled MXFP8 (E4M3 x E4M3 -> F32) variant of 02_mma_tma_sm100.cu.
// Compared to 01_mma_sm100_mxfp8.cu it loads A and B GMEM -> SMEM via TMA (as in 02).
// SFA / SFB are small, so they are still moved with a cooperative_copy and then staged to
// TMEM via UTCCP (SM100_UTCCP_4x32dp128bit_1cta) before they feed the block-scaled UMMA.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

#include <iostream>
#include <cstdio>

// Use Thrust to handle host/device allocations
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

// Cutlass includes
#include <cutlass/half.h>
#include <cutlass/float8.h>                                 // cutlass::float_e4m3_t, float_ue8m0_t
#include <cutlass/util/print_error.hpp>
#include <cutlass/arch/barrier.h>
#include <cutlass/cluster_launch.hpp>
#include <cutlass/detail/sm100_blockscaled_layout.hpp>      // Sm1xxBlockScaledConfig
#include <cutlass/detail/sm100_tmem_helper.hpp>             // find_tmem_tensor_col_offset

// CuTe includes
#include <cute/tensor.hpp>
#include <cute/arch/cluster_sm90.hpp>
#include <cute/numeric/integral_constant.hpp>
#include <cute/algorithm/cooperative_copy.hpp>
#include <cute/arch/tmem_allocator_sm100.hpp>
#include <cute/atom/copy_traits_sm100.hpp>

// Tutorial helpers
#include "example_utils.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

// Shared storage with four SMEM buffers: A, B, SFA, SFB
template <class TypeA, class TypeB, class TypeSF,
          class ASmemLayout, class BSmemLayout,
          class SFASmemLayout, class SFBSmemLayout>
struct SharedStorage
{
  alignas(128) cute::ArrayEngine<TypeA,  cute::cosize_v<ASmemLayout>>   A;
  alignas(128) cute::ArrayEngine<TypeB,  cute::cosize_v<BSmemLayout>>   B;
  alignas(128) cute::ArrayEngine<TypeSF, cute::cosize_v<SFASmemLayout>> SFA;
  alignas(128) cute::ArrayEngine<TypeSF, cute::cosize_v<SFBSmemLayout>> SFB;

  alignas(16) cute::uint64_t mma_barrier;   // Tracks completion of UMMA on SMEM A/B
  alignas(16) cute::uint64_t tma_barrier;   // Tracks completion of TMA A/B loads to SMEM

  alignas(16) cute::uint32_t tmem_base_ptr; // Base pointer for TMEM allocation

  CUTE_DEVICE constexpr auto tensor_sA()   { return make_tensor(make_smem_ptr(A.begin()),   ASmemLayout{});   }
  CUTE_DEVICE constexpr auto tensor_sB()   { return make_tensor(make_smem_ptr(B.begin()),   BSmemLayout{});   }
  CUTE_DEVICE constexpr auto tensor_sSFA() { return make_tensor(make_smem_ptr(SFA.begin()), SFASmemLayout{}); }
  CUTE_DEVICE constexpr auto tensor_sSFB() { return make_tensor(make_smem_ptr(SFB.begin()), SFBSmemLayout{}); }
};

template <class SharedStorage,
          class ATensor, class BTensor, class CTensor, class DTensor,
          class SFATensor, class SFBTensor,
          class MmaTiler_MNK, class TiledMMA, class ClusterShape_MNK,
          class TmaAtomA, class TmaAtomB,
          class Alpha, class Beta>
__global__ static
void
gemm_device(ATensor   mA, BTensor   mB, CTensor   mC, DTensor   mD,
            SFATensor mSFA, SFBTensor mSFB,
            MmaTiler_MNK mma_tiler, TiledMMA tiled_mma, ClusterShape_MNK cluster_shape,
            CUTE_GRID_CONSTANT TmaAtomA const tma_atom_A,
            CUTE_GRID_CONSTANT TmaAtomB const tma_atom_B,
            Alpha alpha, Beta beta)
{
  // --- Prologue: tiling ------------------------------------------------------
  Layout cluster_layout_vmnk = tiled_divide(make_layout(cluster_shape),
                                            make_tile(typename TiledMMA::AtomThrID{}));

  auto mma_coord_vmnk = make_coord(blockIdx.x % size<0>(cluster_layout_vmnk),
                                   blockIdx.x / size<0>(cluster_layout_vmnk),
                                   blockIdx.y,
                                   _);
  auto mma_coord = select<1,2,3>(mma_coord_vmnk);

  // A and B are TMA coordinate tensors here; SFA and SFB are regular GMEM pointer tensors.
  Tensor gA   = local_tile(mA,   mma_tiler, mma_coord, Step<_1, X,_1>{});
  Tensor gB   = local_tile(mB,   mma_tiler, mma_coord, Step< X,_1,_1>{});
  Tensor gC   = local_tile(mC,   mma_tiler, mma_coord, Step<_1,_1, X>{});
  Tensor gD   = local_tile(mD,   mma_tiler, mma_coord, Step<_1,_1, X>{});
  Tensor gSFA = local_tile(mSFA, mma_tiler, mma_coord, Step<_1, X,_1>{});
  Tensor gSFB = local_tile(mSFB, mma_tiler, mma_coord, Step< X,_1,_1>{});

  // --- SMEM tensors ----------------------------------------------------------
  extern __shared__ char shared_memory[];
  SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(shared_memory);

  Tensor tCsA   = shared_storage.tensor_sA();
  Tensor tCsB   = shared_storage.tensor_sB();
  Tensor tCsSFA = shared_storage.tensor_sSFA();
  Tensor tCsSFB = shared_storage.tensor_sSFB();

  // --- MMA partitioning for A/B/C -------------------------------------------
  auto mma_v = get<0>(mma_coord_vmnk);
  ThrMMA cta_mma = tiled_mma.get_slice(mma_v);
  Tensor tCgA = cta_mma.partition_A(gA);
  Tensor tCgB = cta_mma.partition_B(gB);
  Tensor tCgC = cta_mma.partition_C(gC);
  Tensor tCgD = cta_mma.partition_C(gD);

  Tensor tCrA  = cta_mma.make_fragment_A(tCsA);
  Tensor tCrB  = cta_mma.make_fragment_B(tCsB);
  Tensor tCtAcc = cta_mma.make_fragment_C(tCgC);

  // --- SFA / SFB TMEM "fragments" -------------------------------------------
  Tensor tCtSFA = make_tensor<typename TiledMMA::FrgTypeSFA>(shape(tCsSFA));
  Tensor tCtSFB = make_tensor<typename TiledMMA::FrgTypeSFB>(shape(tCsSFB));

  uint32_t elect_one_thr  = cute::elect_one_sync();
  uint32_t elect_one_warp = (threadIdx.x / 32 == 0);

  using TmemAllocator = cute::TMEM::Allocator1Sm;
  TmemAllocator tmem_allocator{};

  if (elect_one_warp) {
    tmem_allocator.allocate(TmemAllocator::Sm100TmemCapacityColumns, &shared_storage.tmem_base_ptr);
  }
  __syncthreads();

  uint32_t tmem_base_addr = shared_storage.tmem_base_ptr;
  tCtAcc.data() = tmem_base_addr;
  tCtSFA.data() = tCtAcc.data().get() + cutlass::detail::find_tmem_tensor_col_offset(tCtAcc);
  tCtSFB.data() = tCtSFA.data().get() + cutlass::detail::find_tmem_tensor_col_offset(tCtSFA);

  // --- Compact SMEM / TMEM views for UTCCP S->T -----------------------------
  auto tCsSFA_compact = make_tensor(tCsSFA.data(), filter_zeros(tCsSFA.layout()));
  auto tCtSFA_compact = make_tensor(tCtSFA.data(), filter_zeros(tCtSFA.layout()));
  auto tCsSFB_compact = make_tensor(tCsSFB.data(), filter_zeros(tCsSFB.layout()));
  auto tCtSFB_compact = make_tensor(tCtSFB.data(), filter_zeros(tCtSFB.layout()));

  using UtccpOp = SM100_UTCCP_4x32dp128bit_1cta;
  auto tiled_copy_s2t_SFA = make_utccp_copy(UtccpOp{}, tCtSFA_compact);
  auto tiled_copy_s2t_SFB = make_utccp_copy(UtccpOp{}, tCtSFB_compact);

  auto thr_copy_s2t_SFA = tiled_copy_s2t_SFA.get_slice(0);
  auto thr_tCsSFA_s2t_ = thr_copy_s2t_SFA.partition_S(tCsSFA_compact);
  auto thr_tCsSFA_s2t  = get_utccp_smem_desc_tensor<UtccpOp>(thr_tCsSFA_s2t_);
  auto thr_tCtSFA_s2t  = thr_copy_s2t_SFA.partition_D(tCtSFA_compact);

  auto thr_copy_s2t_SFB = tiled_copy_s2t_SFB.get_slice(0);
  auto thr_tCsSFB_s2t_ = thr_copy_s2t_SFB.partition_S(tCsSFB_compact);
  auto thr_tCsSFB_s2t  = get_utccp_smem_desc_tensor<UtccpOp>(thr_tCsSFB_s2t_);
  auto thr_tCtSFB_s2t  = thr_copy_s2t_SFB.partition_D(tCtSFB_compact);

  // --- TMA partitioning for A / B -------------------------------------------
  auto [tAgA, tAsA] = tma_partition(tma_atom_A,
                                    Int<0>{}, Layout<_1>{},
                                    group_modes<0,3>(tCsA), group_modes<0,3>(tCgA));

  auto [tBgB, tBsB] = tma_partition(tma_atom_B,
                                    Int<0>{}, Layout<_1>{},
                                    group_modes<0,3>(tCsB), group_modes<0,3>(tCgB));

  int tma_transaction_bytes = sizeof(make_tensor_like(tAsA))
                            + sizeof(make_tensor_like(tBsB));

  // --- Barriers -------------------------------------------------------------
  if (elect_one_warp && elect_one_thr) {
    cute::initialize_barrier(shared_storage.mma_barrier, /* num_ctas */    1);
    cute::initialize_barrier(shared_storage.tma_barrier, /* num_threads */ 1);
  }
  int mma_barrier_phase_bit = 0;
  int tma_barrier_phase_bit = 0;
  __syncthreads();

  // --- Mainloop -------------------------------------------------------------
  tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;

  for (int k_tile = 0; k_tile < size<3>(tCgA); ++k_tile)
  {
    // SFA / SFB : GMEM -> SMEM via cooperative_copy (all 128 threads).
    cooperative_copy<128>(threadIdx.x, gSFA(_,_,k_tile), tCsSFA);
    cooperative_copy<128>(threadIdx.x, gSFB(_,_,k_tile), tCsSFB);

    // A / B : GMEM -> SMEM via TMA (single thread triggers, barrier tracks completion).
    if (elect_one_warp && elect_one_thr) {
      cute::set_barrier_transaction_bytes(shared_storage.tma_barrier, tma_transaction_bytes);
      copy(tma_atom_A.with(shared_storage.tma_barrier), tAgA(_,k_tile), tAsA);
      copy(tma_atom_B.with(shared_storage.tma_barrier), tBgB(_,k_tile), tBsB);
    }

    cute::wait_barrier(shared_storage.tma_barrier, tma_barrier_phase_bit);
    tma_barrier_phase_bit ^= 1;

    // Make the cooperative_copy of SFs visible to the MMA warp.
    __syncthreads();

    if (elect_one_warp) {
      // SMEM -> TMEM once per k_tile for the scale factors.
      copy(tiled_copy_s2t_SFA, thr_tCsSFA_s2t, thr_tCtSFA_s2t);
      copy(tiled_copy_s2t_SFB, thr_tCsSFB_s2t, thr_tCtSFB_s2t);

      for (int k_block = 0; k_block < size<2>(tCrA); ++k_block) {
        gemm(tiled_mma.with(tiled_mma.accumulate_,
                            tCtSFA(_,_,k_block),
                            tCtSFB(_,_,k_block)),
             tCrA(_,_,k_block),
             tCrB(_,_,k_block),
             tCtAcc);
        tiled_mma.accumulate_ = UMMA::ScaleOut::One;
      }
      cutlass::arch::umma_arrive(&shared_storage.mma_barrier);
    }
    cute::wait_barrier(shared_storage.mma_barrier, mma_barrier_phase_bit);
    mma_barrier_phase_bit ^= 1;
  }

  // --- Epilogue: TMEM -> RMEM -> GMEM ---------------------------------------
  TiledCopy tiled_t2r_copy = make_tmem_copy(SM100_TMEM_LOAD_32dp32b1x{}, tCtAcc);
  ThrCopy   thr_t2r_copy   = tiled_t2r_copy.get_slice(threadIdx.x);

  Tensor tDgC = thr_t2r_copy.partition_D(tCgC);
  Tensor tDrC = make_fragment_like(tDgC);
  copy(tDgC, tDrC);

  Tensor tDtAcc = thr_t2r_copy.partition_S(tCtAcc);
  Tensor tDgD   = thr_t2r_copy.partition_D(tCgD);
  using AccType = typename decltype(tCtAcc)::value_type;
  Tensor tDrAcc = make_tensor<AccType>(shape(tDgD));
  copy(tiled_t2r_copy, tDtAcc, tDrAcc);

  axpby(alpha, tDrAcc, beta, tDrC);
  copy(tDrC, tDgD);

  __syncthreads();

  if (elect_one_warp) {
    tmem_allocator.release_allocation_lock();
    tmem_allocator.free(shared_storage.tmem_base_ptr, TmemAllocator::Sm100TmemCapacityColumns);
  }
}

template <class TypeA, class LayoutA,
          class TypeB, class LayoutB,
          class TypeC, class LayoutC,
          class TypeD, class LayoutD,
          class TypeSF, class LayoutSFA, class LayoutSFB,
          class Alpha, class Beta>
void gemm_host_mxfp8_f32_f32_tnt(TypeA  const* device_ptr_A,   LayoutA   layout_A,
                                 TypeB  const* device_ptr_B,   LayoutB   layout_B,
                                 TypeC  const* device_ptr_C,   LayoutC   layout_C,
                                 TypeD       * device_ptr_D,   LayoutD   layout_D,
                                 TypeSF const* device_ptr_SFA, LayoutSFA layout_SFA,
                                 TypeSF const* device_ptr_SFB, LayoutSFB layout_SFB,
                                 Alpha const alpha, Beta const beta)
{
  assert(shape<0>(layout_A) == shape<0>(layout_C));
  assert(shape<0>(layout_B) == shape<1>(layout_C));
  assert(shape<1>(layout_A) == shape<1>(layout_B));

  Tensor mA   = make_tensor(make_gmem_ptr(device_ptr_A),   layout_A);
  Tensor mB   = make_tensor(make_gmem_ptr(device_ptr_B),   layout_B);
  Tensor mC   = make_tensor(make_gmem_ptr(device_ptr_C),   layout_C);
  Tensor mD   = make_tensor(make_gmem_ptr(device_ptr_D),   layout_D);
  Tensor mSFA = make_tensor(make_gmem_ptr(device_ptr_SFA), layout_SFA);
  Tensor mSFB = make_tensor(make_gmem_ptr(device_ptr_SFB), layout_SFB);

  auto Gemm_M = shape<0>(layout_A);
  auto Gemm_N = shape<0>(layout_B);
  auto Gemm_K = shape<1>(layout_A);
  std::cout << "Running for problem shape (MxNxK): " << Gemm_M << "x" << Gemm_N << "x" << Gemm_K << std::endl;

  // Block-scaled UMMA: 128 x 256 x 32 MXFP8 x MXFP8 -> F32.
  TiledMMA tiled_mma = make_tiled_mma(
      SM100_MMA_MXF8F6F4_SS<TypeA, TypeB, TypeC, TypeSF,
                            128, 256,
                            UMMA::Major::K, UMMA::Major::K>{});
  print(tiled_mma);

  auto bM = tile_size<0>(tiled_mma);
  auto bN = tile_size<1>(tiled_mma);
  auto bK = tile_size<2>(tiled_mma) * Int<4>{};   // 32 * 4 = 128
  auto mma_tiler = make_shape(bM, bN, bK);

  if (not evenly_divides(shape(mma_tiler), tile_shape(tiled_mma))) {
    std::cerr << "The MMA Shape should evenly divide the MMA Tiler." << std::endl;
    return;
  }
  if (not evenly_divides(make_shape(Gemm_M, Gemm_N, Gemm_K), mma_tiler)) {
    std::cerr << "OOB accesses are not supported. MmaTiler_MNK should evenly divide ProblemShape_MNK." << std::endl;
    return;
  }

  auto mma_shape_A = partition_shape_A(tiled_mma, make_shape(size<0>(mma_tiler), size<2>(mma_tiler)));
  auto mma_shape_B = partition_shape_B(tiled_mma, make_shape(size<1>(mma_tiler), size<2>(mma_tiler)));

  auto sA_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeA>{}, mma_shape_A);
  auto sB_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TypeB>{}, mma_shape_B);

  using SfConfig = cutlass::detail::Sm1xxBlockScaledConfig<32>;
  auto sSFA_layout = SfConfig::deduce_smem_layoutSFA(tiled_mma, mma_tiler);
  auto sSFB_layout = SfConfig::deduce_smem_layoutSFB(tiled_mma, mma_tiler);

  print("sA_layout:\t");   print(sA_layout);   print("\n");
  print("sB_layout:\t");   print(sB_layout);   print("\n");
  print("sSFA_layout:\t"); print(sSFA_layout); print("\n");
  print("sSFB_layout:\t"); print(sSFB_layout); print("\n");

  using SMEMStorage = SharedStorage<TypeA, TypeB, TypeSF,
                                    decltype(sA_layout), decltype(sB_layout),
                                    decltype(sSFA_layout), decltype(sSFB_layout)>;

  auto cluster_shape = make_shape(Int<1>{}, Int<1>{}, Int<1>{});
  Layout cluster_layout_vmnk = tiled_divide(make_layout(cluster_shape),
                                            make_tile(typename decltype(tiled_mma)::AtomThrID{}));

  // TMA descriptors for A and B.
  Copy_Atom tma_atom_A = make_tma_atom(
      SM90_TMA_LOAD{},
      mA,
      sA_layout,
      select<0,2>(mma_tiler));
  Tensor mA_tma = tma_atom_A.get_tma_tensor(shape(mA));

  Copy_Atom tma_atom_B = make_tma_atom(
      SM90_TMA_LOAD{},
      mB,
      sB_layout,
      select<1,2>(mma_tiler));
  Tensor mB_tma = tma_atom_B.get_tma_tensor(shape(mB));

  print("tma_atom_A:\t"); print(tma_atom_A); print("\n");
  print("tma_atom_B:\t"); print(tma_atom_B); print("\n");

  dim3 dimBlock(128);
  dim3 dimCluster(size<0>(cluster_shape), size<1>(cluster_shape), size<2>(cluster_shape));
  dim3 dimGrid(size(ceil_div(Gemm_M, bM * size<1>(cluster_layout_vmnk))) * dimCluster.x,
               size(ceil_div(Gemm_N, bN * size<2>(cluster_layout_vmnk))) * dimCluster.y);
  int  smemBytes = sizeof(SMEMStorage);

  auto* kernel_ptr = &gemm_device<SMEMStorage,
                                  decltype(mA_tma), decltype(mB_tma), decltype(mC), decltype(mD),
                                  decltype(mSFA), decltype(mSFB),
                                  decltype(mma_tiler), decltype(tiled_mma), decltype(cluster_shape),
                                  decltype(tma_atom_A), decltype(tma_atom_B),
                                  Alpha, Beta>;

  CUTE_CHECK_ERROR(cudaFuncSetAttribute(kernel_ptr,
                                        cudaFuncAttributeMaxDynamicSharedMemorySize,
                                        smemBytes));

  printf("Grid launched: %d, %d, %d\n", dimGrid.x, dimGrid.y, dimGrid.z);
  printf("Cluster launched: %d, %d, %d\n", dimCluster.x, dimCluster.y, dimCluster.z);

  cutlass::ClusterLaunchParams params = {dimGrid, dimBlock, dimCluster, smemBytes};
  cutlass::Status status = cutlass::launch_kernel_on_cluster(params, (void const*) kernel_ptr,
                                                             mA_tma, mB_tma, mC, mD, mSFA, mSFB,
                                                             mma_tiler, tiled_mma, cluster_shape,
                                                             tma_atom_A, tma_atom_B,
                                                             alpha, beta);
  CUTE_CHECK_LAST();

  if (status != cutlass::Status::kSuccess) {
    std::cerr << "Error: Failed at kernel Launch" << std::endl;
  }
}

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

// Block-scaled reference GEMM:
//   D(m,n) = alpha * sum_k( A(m,k) * B(n,k) * SFA(m,k) * SFB(n,k) ) + beta * C(m,n)
template <class AccType,
          class TensorA, class TensorB, class TensorC, class TensorD,
          class TensorSFA, class TensorSFB,
          class Alpha, class Beta>
void
reference_gemm_blockscaled(TensorA   const& A,   TensorB const& B,
                           TensorC   const& C,   TensorD      & D,
                           TensorSFA const& SFA, TensorSFB const& SFB,
                           Alpha alpha, Beta beta)
{
  using namespace cute;
  for (int m = 0; m < size<0>(D); ++m) {
    for (int n = 0; n < size<1>(D); ++n) {
      AccType acc = AccType(0.f);
      for (int k = 0; k < size<1>(A); ++k) {
        float a  = float(A(m,k));
        float b  = float(B(n,k));
        float sa = float(SFA(m,k));
        float sb = float(SFB(n,k));
        acc += AccType(a * sa * b * sb);
      }
      D(m,n) = AccType(alpha) * acc + AccType(beta) * AccType(C(m,n));
    }
  }
}

int main(int argc, char** argv)
{
  cudaDeviceProp props;
  int current_device_id;
  cudaGetDevice(&current_device_id);
  cudaGetDeviceProperties(&props, current_device_id);
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (error != cudaSuccess) {
    std::cerr << "cudaGetDeviceProperties() returned an error: " << cudaGetErrorString(error) << std::endl;
    return -1;
  }

  if ((props.major != 10) || (props.major == 10 && props.minor > 1)) {
    std::cerr << "This example requires NVIDIA's Blackwell Architecture GPU with compute capability 100a." << std::endl;
    std::cerr << "  Found " << props.major << "." << props.minor << std::endl;
    return -1;
  }

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

  int Gemm_M = 512;  if (argc >= 2) sscanf(argv[1], "%d", &Gemm_M);
  int Gemm_N = 1024; if (argc >= 3) sscanf(argv[2], "%d", &Gemm_N);
  int Gemm_K = 256;  if (argc >= 4) sscanf(argv[3], "%d", &Gemm_K);

  using TypeA  = cutlass::float_e4m3_t;    auto type_str_a = "e4m3";
  using TypeB  = cutlass::float_e4m3_t;    auto type_str_b = "e4m3";
  using TypeSF = cutlass::float_ue8m0_t;
  using TypeC  = float;                    [[maybe_unused]] auto type_str_c = "float";
  using TypeD  = float;                    auto type_str_d = "float";
  using TypeAccumulator = float;

  Layout layout_A = make_layout(make_shape (Gemm_M,   Gemm_K),
                                make_stride(Gemm_K, Int<1>{}));
  Layout layout_B = make_layout(make_shape (Gemm_N,   Gemm_K),
                                make_stride(Gemm_K, Int<1>{}));
  Layout layout_C = make_layout(make_shape (Gemm_M,   Gemm_N),
                                make_stride(Gemm_N, Int<1>{}));
  Layout layout_D = make_layout(make_shape (Gemm_M,   Gemm_N),
                                make_stride(Gemm_N, Int<1>{}));

  using SfConfig = cutlass::detail::Sm1xxBlockScaledConfig<32>;
  auto layout_SFA = SfConfig::tile_atom_to_shape_SFA(make_shape(Gemm_M, Gemm_N, Gemm_K));
  auto layout_SFB = SfConfig::tile_atom_to_shape_SFB(make_shape(Gemm_M, Gemm_N, Gemm_K));
  print("layout_SFA:\t"); print(layout_SFA); print("\n");
  print("layout_SFB:\t"); print(layout_SFB); print("\n");

  thrust::host_vector<TypeA>  host_A (Gemm_M * Gemm_K);
  thrust::host_vector<TypeB>  host_B (Gemm_N * Gemm_K);
  thrust::host_vector<TypeC>  host_C (Gemm_M * Gemm_N);
  thrust::host_vector<TypeSF> host_SFA(cute::cosize(layout_SFA));
  thrust::host_vector<TypeSF> host_SFB(cute::cosize(layout_SFB));

  Tensor host_tensor_A   = make_tensor(host_A.data(),   layout_A);
  Tensor host_tensor_B   = make_tensor(host_B.data(),   layout_B);
  Tensor host_tensor_C   = make_tensor(host_C.data(),   layout_C);
  Tensor host_tensor_SFA = make_tensor(host_SFA.data(), layout_SFA);
  Tensor host_tensor_SFB = make_tensor(host_SFB.data(), layout_SFB);

  initialize_tensor(host_tensor_A);
  initialize_tensor(host_tensor_B);
  initialize_tensor(host_tensor_C);

  // Random UE8M0 scale factors with biased exponent in [122, 132] -> scale in [2^-5, 2^5].
  srand(0xC0FFEE);
  auto random_ue8m0 = []() {
    int exp = 122 + (rand() % 11);
    return TypeSF::bitcast(uint8_t(exp));
  };
  for (size_t i = 0; i < host_SFA.size(); ++i) host_SFA[i] = random_ue8m0();
  for (size_t i = 0; i < host_SFB.size(); ++i) host_SFB[i] = random_ue8m0();

  thrust::device_vector<TypeA>  device_A   = host_A;
  thrust::device_vector<TypeB>  device_B   = host_B;
  thrust::device_vector<TypeC>  device_C   = host_C;
  thrust::device_vector<TypeSF> device_SFA = host_SFA;
  thrust::device_vector<TypeSF> device_SFB = host_SFB;
  thrust::device_vector<TypeD>  device_D(Gemm_M * Gemm_N);

  using Alpha = float;
  using Beta  = float;
  Alpha alpha = 1.0f;
  Beta  beta  = 0.0f;

  gemm_host_mxfp8_f32_f32_tnt(device_A.data().get(),   layout_A,
                              device_B.data().get(),   layout_B,
                              device_C.data().get(),   layout_C,
                              device_D.data().get(),   layout_D,
                              device_SFA.data().get(), layout_SFA,
                              device_SFB.data().get(), layout_SFB,
                              alpha, beta);

  thrust::host_vector<TypeD> host_D = device_D;
  Tensor host_tensor_D = make_tensor(host_D.data(), layout_D);

  thrust::host_vector<TypeD> host_reference_D(Gemm_M * Gemm_N);
  auto host_reference_tensor_D = make_tensor(host_reference_D.data(), layout_D);
  reference_gemm_blockscaled<TypeAccumulator>(host_tensor_A, host_tensor_B,
                                              host_tensor_C, host_reference_tensor_D,
                                              host_tensor_SFA, host_tensor_SFB,
                                              alpha, beta);

  auto relative_error = print_matrix_multiply_mollified_relative_error(
      type_str_a, host_tensor_A,
      type_str_b, host_tensor_B,
      type_str_d, host_tensor_D, host_reference_tensor_D);
  bool success = relative_error <= 1e-2;
  std::cout << "Execution is " << ((success) ? "successful." : "failed.") << std::endl;
#else
  std::cout << "CUTLASS_ARCH_MMA_SM100_SUPPORTED must be enabled, but it is not. Test is waived \n" << std::endl;
#endif

  return 0;
}
