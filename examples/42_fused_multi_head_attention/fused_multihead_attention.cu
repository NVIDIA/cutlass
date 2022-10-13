/***************************************************************************************************
 * Copyright (c) 2017 - 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holdvr nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

/*! \file
    \brief CUTLASS Attention Example.

    This workload computes an attention example with non-fixed sequence length input. Pointers of arrays
    are fed into grouped-GEMM functions fused with softmax for computation.

    Examples:

      # Run an attention example with default setup (max sequence length = 1024, batch size = 16, head size = 64, head number = 12)
      $ ./examples/41_multi_head_attention/41_multi_head_attention

      # Run an attention example with batch size = 64 and head number = 16 without checking the correctness
      $ ./examples/41_multi_head_attention/41_multi_head_attention --head_number=16 --batch_size=64 --reference-check=false

      Acknowledgement: this example is inspired by the idea originally prototyped by ByteDance Inc.

*/

/////////////////////////////////////////////////////////////////////////////////////////////////

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>
#include <unordered_map>

#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/kernel/gemm_grouped.h"
#include "cutlass/gemm/kernel/default_gemm_grouped.h"
#include "cutlass/gemm/device/gemm_grouped.h"
#include "cutlass/gemm/device/gemm_universal.h"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/host/gemm_complex.h"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/device/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_norm.h"

#include "cutlass/layout/matrix.h"
#include "cutlass/gemm/kernel/gemm_grouped.h"
#include "cutlass/gemm/kernel/gemm_transpose_operands.h"
#include "cutlass/gemm/kernel/default_gemm.h"
#include "cutlass/gemm/kernel/default_gemm_complex.h"
#include "cutlass/gemm/device/default_gemm_configuration.h"
#include "cutlass/gemm/gemm.h"

#include "cutlass/epilogue/threadblock/epilogue_with_visitor.h"
#include "cutlass/fast_math.h"
#include "kernel_forward.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Result structure
struct Result {

  double runtime_ms;
  double gflops;
  cutlass::Status status;
  cudaError_t error;
  bool passed;

  //
  // Methods
  //

  Result(
    double runtime_ms = 0,
    double gflops = 0,
    cutlass::Status status = cutlass::Status::kSuccess,
    cudaError_t error = cudaSuccess
  ):
    runtime_ms(runtime_ms), gflops(gflops), status(status), error(error), passed(true) { }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;
  bool error;
  bool reference_check;
  bool use_mask;

  std::vector<cutlass::gemm::GemmCoord> problem_sizes0;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes1;

  std::vector<cutlass::gemm::GemmCoord> problem_sizes0_real;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes1_real;

  int alignment;
  int head_number;
  int batch_size;
  int head_size;
  int seq_length;
  int iterations;
  int cuda_streams;

  // alpha0, alpha1 and beta are fixed 
  // in this multi-head attention example
  float alpha0;
  float alpha1;
  float beta;

  //
  // Methods
  // 

  Options():
    help(false),
    error(false),
    alignment(1),
    reference_check(true),
    head_number(12),
    batch_size(16),
    head_size(64),
    seq_length(1024),
    use_mask(false),
    iterations(20),
    cuda_streams(0)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("alignment", alignment, 1);
    cmd.get_cmd_line_argument("head_number", head_number, 12);
    cmd.get_cmd_line_argument("batch_size", batch_size, 16);
    cmd.get_cmd_line_argument("head_size", head_size, 64);
    cmd.get_cmd_line_argument("seq_length", seq_length, 1024);
    cmd.get_cmd_line_argument("use_mask", use_mask, false);
    cmd.get_cmd_line_argument("iterations", iterations, 20);
    cmd.get_cmd_line_argument("streams", cuda_streams, 0);
    cmd.get_cmd_line_argument("reference-check", reference_check, true);

    randomize_problems();

  }

  void randomize_problems() {

    int problem_count = head_number * batch_size;

    problem_sizes0.reserve(problem_count);
    problem_sizes1.reserve(problem_count);

    // When using mask, the original inputs are not padded
    // and we need to save these info.
    if (use_mask) {
      problem_sizes0_real.reserve(problem_count);
      problem_sizes1_real.reserve(problem_count);
    }

    for (int i = 0; i < batch_size; ++i) {
      // problems belonging to the same batch share the same seq len
      int m_real = seq_length; // (rand() % seq_length);
      int m = (m_real + alignment - 1) / alignment * alignment;
      int n = m;
      int k = head_size;

      for (int j = 0; j < head_number; ++j) {
        cutlass::gemm::GemmCoord problem0(m, n, k);
        cutlass::gemm::GemmCoord problem1(m, k, n);
        problem_sizes0.push_back(problem0);
        problem_sizes1.push_back(problem1);

        if (use_mask) {
          cutlass::gemm::GemmCoord problem0_real(m_real, m_real, k);
          cutlass::gemm::GemmCoord problem1_real(m_real, k, m_real);
          problem_sizes0_real.push_back(problem0_real);
          problem_sizes1_real.push_back(problem1_real);
        }

      }
    }
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "42_fused_multi_head_attention\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement.\n\n"
      << "  --head_number=<int>         Head number in multi-head attention (default: --head_number=12)\n"
      << "  --batch_size=<int>          Batch size in multi-head attention (default: --batch_size=16)\n"
      << "  --head_size=<int>           Head size in multi-head attention (default: --head_size=64)\n"
      << "  --seq_length=<int>          Max sequence length in multi-head attention (default: --seq_length=1024)\n"
      << "  --use_mask=<bool>           If true, performs padding-like masking in softmax.\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n"
      << "  --reference-check=<bool>    If true, performs reference check.\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s) const {

    // Number of real-valued multiply-adds 
    int64_t fmas = int64_t();

    for (auto const & problem : problem_sizes0) {
      // Two flops per multiply-add
      fmas += problem.product() * 2;
    }
    
    // Multiply another '2' because of the back-to-back GEMM problems in attention
    return 2.0 * double(fmas) / double(1.0e9) / runtime_s;
  }
};



///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Attention>
class TestbedAttention {
public:

  //
  // Type definitions
  //

  using ElementQ = typename Attention::scalar_t;
  using ElementK = typename Attention::scalar_t;
  using ElementP = typename Attention::accum_t;
  using ElementAccumulator = typename Attention::accum_t;
  using ElementV = typename Attention::scalar_t;
  using ElementO = typename Attention::output_t;

  using ElementCompute = typename Attention::accum_t;

  using ElementNorm = typename Attention::accum_t;
  using ElementSum = typename Attention::accum_t;
  using ElementSoftmaxCompute = typename Attention::accum_t;

  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::RowMajor;
  using LayoutK_T = cutlass::layout::ColumnMajor; // transposed
  using LayoutP = cutlass::layout::RowMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;

  using MatrixCoord = typename LayoutP::TensorCoord;

private:

  //
  // Data members
  //

  Options & options;

  /// Initialization
  cutlass::Distribution::Kind init_Q;
  cutlass::Distribution::Kind init_K;
  cutlass::Distribution::Kind init_P;
  cutlass::Distribution::Kind init_V;
  cutlass::Distribution::Kind init_O;
  uint32_t seed;

  cutlass::DeviceAllocation<cutlass::gemm::GemmCoord> problem_sizes_device0;
  cutlass::DeviceAllocation<cutlass::gemm::GemmCoord> problem_sizes_device1;
  cutlass::DeviceAllocation<cutlass::gemm::GemmCoord> problem_sizes_device0_real;

  std::vector<int64_t> offset_Q;
  std::vector<int64_t> offset_K;
  std::vector<int64_t> offset_P;
  std::vector<int64_t> offset_V;
  std::vector<int64_t> offset_O;

  std::vector<int64_t> ldq_host;
  std::vector<int64_t> ldk_host;
  std::vector<int64_t> ldp_host;
  std::vector<int64_t> ldv_host;
  std::vector<int64_t> ldo_host;
  std::vector<int64_t> seqlen_host;

  cutlass::DeviceAllocation<int64_t> ldq;
  cutlass::DeviceAllocation<int64_t> ldk;
  cutlass::DeviceAllocation<int64_t> ldp;
  cutlass::DeviceAllocation<int64_t> ldv;
  cutlass::DeviceAllocation<int64_t> ldo;
  cutlass::DeviceAllocation<int64_t> seqlen;

  cutlass::DeviceAllocation<ElementQ> block_Q;
  cutlass::DeviceAllocation<ElementK> block_K;
  cutlass::DeviceAllocation<ElementP> block_P;
  cutlass::DeviceAllocation<ElementV> block_V;
  cutlass::DeviceAllocation<ElementO> block_O;
  cutlass::DeviceAllocation<ElementNorm> block_Norm;
  cutlass::DeviceAllocation<ElementSum> block_Sum;

  cutlass::DeviceAllocation<int64_t> offset_P_Device;

  cutlass::DeviceAllocation<ElementQ *> ptr_Q;
  cutlass::DeviceAllocation<ElementK *> ptr_K;
  cutlass::DeviceAllocation<ElementP *> ptr_P;
  cutlass::DeviceAllocation<ElementV *> ptr_V;
  cutlass::DeviceAllocation<ElementO *> ptr_O;

public:

  //
  // Methods
  //

  TestbedAttention(
    Options &options_,
    cutlass::Distribution::Kind init_Q_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_K_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_P_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_V_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_O_ = cutlass::Distribution::Uniform,
    uint32_t seed_ = 3080
  ):
    options(options_), init_Q(init_Q_), init_K(init_K_), init_P(init_P_), init_V(init_V_), init_O(init_O_), seed(seed_) { }

  int problem_count() const {
    return (options.head_number * options.batch_size);
  }

private:

  /// Helper to initialize a tensor view
  template <typename Element>
  void initialize_tensor_(
    Element *ptr,
    size_t capacity, 
    cutlass::Distribution::Kind dist_kind,
    uint32_t seed) {

    if (dist_kind == cutlass::Distribution::Uniform) {

      Element scope_max, scope_min;
      int bits_input = cutlass::sizeof_bits<Element>::value;
      int bits_output = cutlass::sizeof_bits<ElementP>::value;

      if (bits_input == 1) {
        scope_max = 2;
        scope_min = 0;
      } else if (bits_input <= 8) {
        scope_max = 2;
        scope_min = -2;
      } else if (bits_output == 16) {
        scope_max = 8;
        scope_min = -8;
      } else {
        scope_max = 8;
        scope_min = -8;
      }

      cutlass::reference::device::BlockFillRandomUniform(
        ptr, capacity, seed, scope_max, scope_min, 0);
    } 
    else if (dist_kind == cutlass::Distribution::Gaussian) {

      cutlass::reference::device::BlockFillRandomGaussian(
        ptr, capacity, seed, Element(), Element(0.5f));
    }
    else if (dist_kind == cutlass::Distribution::Sequential) {

      // Fill with increasing elements
      cutlass::reference::device::BlockFillSequential(
        ptr, capacity, Element(1), Element());
    } 
    else {

      // Fill with all 1s
      cutlass::reference::device::BlockFillSequential(
        ptr, capacity, Element(), Element(1));
    }
  }

  /// Initializes data structures
  void initialize_() {

    //
    // Set scalors for the mha example
    //

    options.alpha0 = 1.0f / sqrt(float(options.head_size));
    options.alpha1 = 1.0f;
    options.beta = 0;

    //
    // Choose random problem sizes
    //

    // construct a few problems of random sizes
    srand(seed);

    int64_t total_elements_Q = 0;
    int64_t total_elements_K = 0;
    int64_t total_elements_P = 0;
    int64_t total_elements_V = 0;
    int64_t total_elements_O = 0;

    ldq_host.resize(problem_count());
    ldk_host.resize(problem_count());
    ldp_host.resize(problem_count());
    ldv_host.resize(problem_count());
    ldo_host.resize(problem_count());
    seqlen_host.resize(problem_count());

    for (int32_t i = 0; i < problem_count(); ++i) {

      auto problem = options.problem_sizes0.at(i);

      ldq_host.at(i) = LayoutQ::packed({problem.m(), problem.k()}).stride(0);
      ldk_host.at(i) = LayoutK::packed({problem.n(), problem.k()}).stride(0);
      ldp_host.at(i) = LayoutP::packed({problem.m(), problem.n()}).stride(0);
      ldv_host.at(i) = LayoutV::packed({problem.n(), problem.k()}).stride(0);
      ldo_host.at(i) = LayoutO::packed({problem.m(), problem.k()}).stride(0);

      // m = n for attention problems.
      seqlen_host.at(i) = problem.m();

      offset_Q.push_back(total_elements_Q);
      offset_K.push_back(total_elements_K);
      offset_P.push_back(total_elements_P);
      offset_V.push_back(total_elements_V);
      offset_O.push_back(total_elements_O);

      int64_t elements_Q = problem.m() * problem.k();
      int64_t elements_K = problem.k() * problem.n();
      int64_t elements_P = problem.m() * problem.n();
      int64_t elements_V = problem.n() * problem.k();
      int64_t elements_O = problem.m() * problem.k();

      total_elements_Q += elements_Q;
      total_elements_K += elements_K;
      total_elements_P += elements_P;
      total_elements_V += elements_V;
      total_elements_O += elements_O;

    }

    problem_sizes_device0.reset(problem_count());
    problem_sizes_device1.reset(problem_count());
    problem_sizes_device0.copy_from_host(options.problem_sizes0.data());
    problem_sizes_device1.copy_from_host(options.problem_sizes1.data());

    if (options.use_mask) {
      problem_sizes_device0_real.reset(problem_count());
      problem_sizes_device0_real.copy_from_host(options.problem_sizes0_real.data());
    }

    ldq.reset(problem_count());
    ldk.reset(problem_count());
    ldp.reset(problem_count());
    ldv.reset(problem_count());
    ldo.reset(problem_count());
    seqlen.reset(problem_count());

    ldq.copy_from_host(ldq_host.data());
    ldk.copy_from_host(ldk_host.data());
    ldp.copy_from_host(ldp_host.data());
    ldv.copy_from_host(ldv_host.data());
    ldo.copy_from_host(ldo_host.data());
    seqlen.copy_from_host(seqlen_host.data());

    //
    // Assign pointers
    //

    block_Q.reset(total_elements_Q);
    block_K.reset(total_elements_K);
    block_P.reset(total_elements_P);
    block_V.reset(total_elements_V);
    block_O.reset(total_elements_O);

    offset_P_Device.reset(problem_count());

    // sync offset with device
    cutlass::device_memory::copy_to_device(offset_P_Device.get(), offset_P.data(), offset_P.size());

    std::vector<ElementQ *> ptr_Q_host(problem_count());
    std::vector<ElementK *> ptr_K_host(problem_count());
    std::vector<ElementP *> ptr_P_host(problem_count());
    std::vector<ElementV *> ptr_V_host(problem_count());
    std::vector<ElementO *> ptr_O_host(problem_count());
    std::vector<ElementNorm *> ptr_norm_host(problem_count());
    std::vector<ElementSum *> ptr_sum_host(problem_count());

    for (int32_t i = 0; i < problem_count(); ++i) {
      ptr_Q_host.at(i) = block_Q.get() + offset_Q.at(i);
      ptr_K_host.at(i) = block_K.get() + offset_K.at(i);
      ptr_P_host.at(i) = block_P.get() + offset_P.at(i);
      ptr_V_host.at(i) = block_V.get() + offset_V.at(i);
      ptr_O_host.at(i) = block_O.get() + offset_O.at(i);
    }

    ptr_Q.reset(problem_count());
    ptr_Q.copy_from_host(ptr_Q_host.data());
    
    ptr_K.reset(problem_count());
    ptr_K.copy_from_host(ptr_K_host.data());
    
    ptr_P.reset(problem_count());
    ptr_P.copy_from_host(ptr_P_host.data());

    ptr_V.reset(problem_count());
    ptr_V.copy_from_host(ptr_V_host.data());

    ptr_O.reset(problem_count());
    ptr_O.copy_from_host(ptr_O_host.data());

    //
    // Initialize the problems of the workspace
    //

    initialize_tensor_(block_Q.get(), total_elements_Q, init_Q, seed + 1);
    initialize_tensor_(block_K.get(), total_elements_K, init_K, seed + 2);
    initialize_tensor_(block_V.get(), total_elements_V, init_V, seed + 3);

  }

  template<typename Element>
  bool verify_tensor_(std::vector<Element> vector_Input, \
                       std::vector<Element> vector_Input_Ref,
                       int64_t verify_length = -1) {

    int64_t size = (vector_Input.size() < vector_Input_Ref.size()) ? vector_Input.size() : vector_Input_Ref.size();
    size = (verify_length == -1) ? size : verify_length;

    // 0.05 for absolute error
    float abs_tol = 5e-2f;
    // 10% for relative error
    float rel_tol = 1e-1f;
    for (int64_t i = 0; i < size; ++i) {
      float diff = (float)(vector_Input.at(i) - vector_Input_Ref.at(i));
      float abs_diff = fabs(diff);
      float abs_ref = fabs((float)vector_Input_Ref.at(i) + 1e-5f);
      float relative_diff = abs_diff / abs_ref;
      if ( (isnan(abs_diff) || isinf(abs_diff)) ||  (abs_diff > abs_tol && relative_diff > rel_tol)) {
        printf("[%d/%d] diff = %f, rel_diff = %f, {computed=%f, ref=%f}.\n", int(i), int(size), abs_diff, relative_diff, (float)(vector_Input.at(i)), (float)(vector_Input_Ref.at(i)));
        return false;
      }

    }

    return true;
  }

  /// Verifies the result is a GEMM
  bool verify_() {

    bool passed = true;

    for (int32_t i = 0; i < problem_count(); ++i) {
      cutlass::gemm::GemmCoord problem = options.problem_sizes0.at(i);
      cutlass::gemm::GemmCoord problem1 = options.problem_sizes1.at(i);

      LayoutQ layout_Q(ldq_host.at(i));
      LayoutK_T layout_K(ldk_host.at(i));
      LayoutP layout_P(ldp_host.at(i));
      LayoutV layout_V(ldv_host.at(i));
      LayoutO layout_O(ldo_host.at(i));

      MatrixCoord extent_Q{problem.m(), problem.k()};
      MatrixCoord extent_K{problem.n(), problem.k()};
      MatrixCoord extent_P{problem.m(), problem.n()};
      MatrixCoord extent_V{problem.n(), problem.k()};
      MatrixCoord extent_O{problem.m(), problem.k()};

      cutlass::TensorView<ElementQ, LayoutQ> view_Q(block_Q.get() + offset_Q.at(i), layout_Q, extent_Q);
      cutlass::TensorView<ElementK, LayoutK_T> view_K(block_K.get() + offset_K.at(i), layout_K, extent_K);
      cutlass::TensorView<ElementP, LayoutP> view_P(block_P.get() + offset_P.at(i), layout_P, extent_P);
      cutlass::TensorView<ElementV, LayoutV> view_V(block_V.get() + offset_V.at(i), layout_V, extent_V);

      cutlass::DeviceAllocation<ElementP>    block_Ref(layout_P.capacity(extent_P));
      cutlass::TensorView<ElementP, LayoutP> view_Ref_device(block_Ref.get(), layout_P, extent_P);

      cutlass::DeviceAllocation<ElementO>    block_Ref_O(layout_O.capacity(extent_O));
      cutlass::TensorView<ElementO, LayoutO> view_Ref_O_device(block_Ref_O.get(), layout_O, extent_O);

      // Reference GEMM
      cutlass::reference::device::GemmComplex<
          ElementQ, LayoutQ,
          ElementK, LayoutK_T,
          ElementP, LayoutP, 
          ElementCompute, ElementAccumulator
      >(
        problem,
        ElementAccumulator(options.alpha0), 
        view_Q,
        Attention::MM0::Mma::kTransformA,
        view_K,
        Attention::MM0::Mma::kTransformB,
        ElementAccumulator(options.beta), 
        view_P, 
        view_Ref_device, 
        ElementAccumulator(0)
      );

      // Compute softmax for P. We need to explicitly compute softmax
      // over P because softmax is fused to the second GEMM in the
      // profiled implementation.
      std::vector<ElementP> matrix_Ref(layout_P.capacity(extent_P));
      cutlass::device_memory::copy_to_host(matrix_Ref.data(), block_Ref.get(), matrix_Ref.size());
      cutlass::TensorView<ElementP, LayoutP> view_Ref_host(matrix_Ref.data(), layout_P, extent_P);
      std::vector<ElementNorm> vector_Norm_Ref(problem.m());
      std::vector<ElementSum> vector_Sum_Ref(problem.m());

      int n_dim = options.use_mask ? options.problem_sizes0_real.at(i).n() : problem.n();

      // Compute softmax for referece matrix
      // Assumed a row-major storage
      for (int m = 0; m < problem.m(); m++) {
        ElementSoftmaxCompute max = ElementSoftmaxCompute(view_Ref_host.ref().at({m, 0}));
        for (int n = 1; n < n_dim; n++) {
           max = std::max(max, ElementSoftmaxCompute(view_Ref_host.ref().at({m, n})));
        }

        vector_Norm_Ref.at(m) = ElementNorm(max);

        ElementSoftmaxCompute sum = ElementSoftmaxCompute();
        for (int n = 0; n < n_dim; n++) {
          sum += std::exp( ElementSoftmaxCompute(view_Ref_host.ref().at({m, n})) - max );
        }
        ElementSoftmaxCompute inv_sum = ElementSoftmaxCompute(1.0f / sum);

        vector_Sum_Ref.at(m) = ElementSum(inv_sum);

        for (int n = 0; n < n_dim; n++) {
          view_Ref_host.ref().at({m, n}) = ElementP(
            std::exp( ElementSoftmaxCompute(view_Ref_host.ref().at({m, n})) - max ) * inv_sum
          );
        }

      }

      // when not using mask, problem_real and problem share the same sizes
      if (options.use_mask) {
        for (int m = 0; m < problem.m(); m++) {
          for (int n = n_dim; n < problem.n(); n++) {
            view_Ref_host.ref().at({m, n}) = ElementP(0);
          }
        }
      }

      cutlass::device_memory::copy_to_device(block_P.get() + offset_P.at(i), matrix_Ref.data(), matrix_Ref.size());

      // Reference GEMM
      cutlass::reference::device::GemmComplex<
          ElementP, LayoutP,
          ElementV, LayoutV,
          ElementO, LayoutO, 
          ElementCompute, ElementAccumulator
      >(
        problem1,
        ElementAccumulator(options.alpha1), 
        view_P,
        Attention::MM0::Mma::kTransformA,
        view_V,
        Attention::MM0::Mma::kTransformB,
        ElementAccumulator(options.beta), 
        view_Ref_O_device, 
        view_Ref_O_device, 
        ElementAccumulator(0)
      );

      // Copy to host memory
      cutlass::TensorView<ElementP, LayoutP> view_Ref(matrix_Ref.data(), layout_P, extent_P);

      std::vector<ElementO> matrix_O(layout_O.capacity(extent_O));
      cutlass::device_memory::copy_to_host(matrix_O.data(),   block_O.get() + offset_O.at(i), matrix_O.size());
      std::vector<ElementO> matrix_Ref_O(layout_O.capacity(extent_O));
      cutlass::device_memory::copy_to_host(matrix_Ref_O.data(), block_Ref_O.get(), matrix_Ref_O.size());

      // printf("Pb %d: \n    Q=(offset=%d, ldq=%d)\n    K=(offset=%d, ldk=%d)\n    O=(offset=%d, ldo=%d)\n",
      //   int(i), int(offset_Q[i]), int(ldq_host[i]), int(offset_K[i]), int(ldk_host[i]), int(offset_O[i]), int(ldo_host[i]));
  
      bool verified_O = false;

      if (!verified_O) {
        verified_O = verify_tensor_<ElementO>(matrix_O, matrix_Ref_O);
      }

      passed = passed && verified_O;

      if (!passed) {
        std::cerr << "\n***\nError - problem " << i << " failed the QA check\n***\n" << std::endl;

        if (!verified_O) {
          std::cout << "Final matrix output is incorrect" << std::endl;
        }

        return passed;
      }

    }

    return passed;
  }

public:


  /// Executes a CUTLASS Attention kernel and measures runtime.
  Result profile_grouped() {

    Result result;
    result.passed = false;

    // Initialize the problem
    initialize_();

    typename Attention::Params p;
    { // set parameters
      p.query_ptr = block_Q.get();
      p.key_ptr = block_K.get();
      p.value_ptr = block_V.get();
      p.logsumexp_ptr = nullptr; // Only needed for bw
      p.output_accum_ptr = nullptr;
      if (Attention::kNeedsOutputAccumulatorBuffer) {
        cudaMalloc(&p.output_accum_ptr, block_O.size() * sizeof(typename Attention::output_accum_t));
      }
      p.output_ptr = block_O.get();

      // TODO: support arbitrary seq lengths
      // if (cu_seqlens_q.has_value()) {
      //   p.cu_seqlens_q_ptr = (int32_t*)cu_seqlens_q->data_ptr();
      //   p.cu_seqlens_k_ptr = (int32_t*)cu_seqlens_k->data_ptr();
      // }

      p.num_heads = options.head_number;
      p.num_batches = options.batch_size;
      p.head_dim = options.head_size;
      p.head_dim_value = options.head_size;
      p.num_queries = options.seq_length;
      p.num_keys = options.seq_length;
      p.causal = false; // TODO: add an option to test causal as well

      p.q_strideM = ldq_host[0];
      p.k_strideM = ldk_host[0];
      p.v_strideM = ldv_host[0];
      p.q_strideH = p.q_strideM * options.seq_length;
      p.k_strideH = p.k_strideM * options.seq_length;
      p.v_strideH = p.v_strideM * options.seq_length;
      p.o_strideH = options.head_size * options.seq_length;
      p.q_strideB = p.q_strideH * options.head_number;
      p.k_strideB = p.k_strideH * options.head_number;
      p.v_strideB = p.v_strideH * options.head_number;
      p.o_strideB = options.head_size * options.seq_length * options.head_number;
    }

    // launch kernel :)
    constexpr auto kernel_fn = attention_kernel_batched_impl<Attention>;
    int smem_bytes = sizeof(typename Attention::SharedStorage);
    if (smem_bytes > 0xc000) {
      cudaFuncSetAttribute(kernel_fn, cudaFuncAttributeMaxDynamicSharedMemorySize, smem_bytes);
    }
    if (!Attention::check_supported(p)) {
      std::cerr << "Kernel does not support these inputs" << std::endl;
      return result;
    }
    kernel_fn<<<p.getBlocksGrid(), p.getThreadsGrid(), smem_bytes>>>(p);

    // Wait for completion
    result.error = cudaDeviceSynchronize();

    if (result.error != cudaSuccess)  {
      std::cerr << "Kernel execution error: " << cudaGetErrorString(result.error);
      return result;
    }

    //
    // Verify correctness
    //
    result.passed = true;

    if (options.reference_check) {
      result.passed = verify_();
    }

    //
    // Warm-up run of the grouped GEMM object
    //

    kernel_fn<<<p.getBlocksGrid(), p.getThreadsGrid(), smem_bytes>>>(p);

    if (result.status != cutlass::Status::kSuccess) {
      std::cerr << "Failed to run CUTLASS Attention kernel." << std::endl;
      return result;
    }

    //
    // Construct events
    //

    cudaEvent_t events[2];

    for (auto & event : events) {
      result.error = cudaEventCreate(&event);
      if (result.error != cudaSuccess) {
        std::cerr << "cudaEventCreate() failed: " << cudaGetErrorString(result.error) << std::endl;
        return -1;
      }
    }

    // Record an event at the start of a series of GEMM operations
    result.error = cudaEventRecord(events[0]);
    if (result.error != cudaSuccess) {
      std::cerr << "cudaEventRecord() failed: " << cudaGetErrorString(result.error) << std::endl;
      return result;
    }

    //
    // Run profiling loop
    //

    for (int iter = 0; iter < options.iterations; ++iter) {
      kernel_fn<<<p.getBlocksGrid(), p.getThreadsGrid(), smem_bytes>>>(p);
    }

    //
    // Stop profiling loop
    //

    // Record an event when the GEMM operations have been launched.
    result.error = cudaEventRecord(events[1]);
    if (result.error != cudaSuccess) {
      std::cerr << "cudaEventRecord() failed: " << cudaGetErrorString(result.error) << std::endl;
      return result;
    }

    // Wait for work on the device to complete.
    result.error = cudaEventSynchronize(events[1]);
    if (result.error != cudaSuccess) {
      std::cerr << "cudaEventSynchronize() failed: " << cudaGetErrorString(result.error) << std::endl;
      return result;
    }

    // Measure elapsed runtime
    float runtime_ms = 0;
    result.error = cudaEventElapsedTime(&runtime_ms, events[0], events[1]);
    if (result.error != cudaSuccess) {
      std::cerr << "cudaEventElapsed() failed: " << cudaGetErrorString(result.error) << std::endl;
      return result;
    }

    // Compute average runtime and GFLOPs.
    result.runtime_ms = double(runtime_ms) / double(options.iterations);
    result.gflops = options.gflops(result.runtime_ms / 1000.0);

    //
    // Cleanup
    //

    for (auto event : events) {
      (void)cudaEventDestroy(event);
    }

    std::cout << std::endl;
    std::cout << "CUTLASS Attention:\n"
      << "====================================================" << std::endl;
    std::cout << "    " << " {max sequence length, head size, head number, batch size} = {" << options.seq_length \
      << ", " << options.head_size << ", " << options.head_number << ", " << options.batch_size << "}." << std::endl;
    std::cout << std::endl;
    std::cout << "    " << "Runtime: " << result.runtime_ms << " ms" << std::endl;
    std::cout << "    " << "GFLOPs: " << result.gflops << std::endl;

    return result;
  }


};

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  //
  // This example uses mma.sync to directly access Tensor Cores to achieve peak performance.
  //

  cudaDeviceProp props;

  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (error != cudaSuccess) {
    std::cerr << "cudaGetDeviceProperties() returned an error: " << cudaGetErrorString(error) << std::endl;
    return -1;
  }

  if (__CUDACC_VER_MAJOR__ < 11 || props.major < 8) {
  
    //
    // This example requires an NVIDIA Ampere-architecture GPU.
    //

    std::cout 
      << "CUTLASS's CUTLASS Attention example requires a GPU of NVIDIA's Ampere Architecture or "
      << "later (compute capability 80 or greater).\n";

    return 0;
  }

  //
  // Parse options
  //

  Options options;
  
  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  if (options.use_mask) {
    std::cerr << "--use_mask is not supported at the moment\n";
    return -2;
  }
  if (options.alignment != 1) {
    std::cerr << "--alignment=1 is the only supported value\n";
    return -2;
  }
  using ArchTag = cutlass::arch::Sm80;

  constexpr bool kIs64x64 = true;
  // Set grid size
  constexpr int64_t kQueriesPerBlock = kIs64x64 ? 64 : 32;
  constexpr int64_t kKeysPerBlock = kIs64x64 ? 64 : 128;
  if (kIs64x64 && options.head_size > kKeysPerBlock) {
    std::cerr << "WARNING: you will get better performance with `kIs64x64=false`\n";
  }

  constexpr bool kSingleValueIteration = true;
  if (kSingleValueIteration && options.head_size > kKeysPerBlock) {
    std::cerr << "ERROR  : Use kSingleValueIteration to keep output in RF. " \
    "This requires to have `head_size <= kKeysPerBlock` " \
    "but head_size=" << options.head_size << " and kKeysPerBlock=" << kKeysPerBlock << "\n";
    return -2;
  }
  if (!kSingleValueIteration && options.head_size <= kKeysPerBlock) {
    std::cerr << "WARNING: you will get better performance with `kSingleValueIteration=true` (keeps the output in RF rather than GMEM)\n";
  }

  using Attention = AttentionKernel<
    cutlass::half_t, // scalar_t
    ArchTag,
    true, // memory is aligned
    kQueriesPerBlock,
    kKeysPerBlock,
    kSingleValueIteration
  >;

  //
  // Test and profile
  //

  TestbedAttention<Attention> testbed(options);

  Result result = testbed.profile_grouped();
  if (!result.passed) {
    std::cout << "Profiling CUTLASS attention has failed.\n";
    std::cout << "\nFailed\n";
    return -1;
  }

  std::cout << "\nPassed\n";

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
