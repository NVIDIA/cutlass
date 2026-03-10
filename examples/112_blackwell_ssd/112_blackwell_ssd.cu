/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
 * 3. Neither the name of the copyright holder nor the names of its
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

#include <iostream>
#include "cutlass/util/command_line.h"

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cute/layout.hpp"
#include "cutlass/kernel_hardware_info.hpp"

#include "thrust/universal_vector.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/device/tensor_fill.h"
#include "cutlass/util/reference/device/tensor_compare.h"

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

#include "reference/reference_ssd_cumsum.hpp"
#include "reference/reference_ssd.hpp"

#include "cutlass/transform/device/transform_universal_adapter.hpp"

#include "device/ssd.hpp"
#include "kernel/sm100_ssd_kernel_builder.hpp"

using namespace cute;

// Command line options parsing
struct Options {

  using Element = cutlass::bfloat16_t;
  using ElementAcc = float;
  using ElementDA = float;
  static constexpr bool D_HAS_HDIM = true;
  static constexpr bool HAS_D = true;
  // Blackwell SSD doesn't support Z now(huge perf drop).
  static constexpr bool HAS_Z = false;

  bool help;
  bool error;
  
  // All static number now
  int G = 2;
  int B = 3;
  int E = 2;
  int H = 2;
  // Reference kernel doesn't support dynamic C now.
  static constexpr auto C = Int<8>{};
  static constexpr auto D = Int<64>{};
  static constexpr auto L = Int<128>{};
  static constexpr auto N = Int<128>{};
  int EH = E * H;

  int iterations;
  bool verify;
  bool verbose;

  int warmups;
  bool measure;

  Options():
    help(false),
    error(false),
    iterations(1), verify(true),
    measure(false), warmups(3)
  {}

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    Options defaults;

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("iterations", iterations, defaults.iterations);
    cmd.get_cmd_line_argument("G", G, defaults.G);
    cmd.get_cmd_line_argument("B", B, defaults.B);
    cmd.get_cmd_line_argument("E", E, defaults.E);
    cmd.get_cmd_line_argument("H", H, defaults.H);
    verbose = cmd.check_cmd_line_flag("verbose");
    verify = !(cmd.check_cmd_line_flag("without_verify"));

    EH = E*H;

    if (iterations > 1) {
      measure = true;
      verbose = true;
    }

    auto problem_shape = cute::make_tuple(G, B, EH, C, L, D, N);
    cute::print("problem_shape : "); cute::print(problem_shape); cute::print("\n");
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "112_blackwell_ssd\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --iterations=<int>          Benchmarking iterations.\n"
      << "  --without_verify            Don't verify the results.\n"
      << "  --verbose                   Print execution time per kernel\n"
      << "  --G=<int>                   Group\n"
      << "  --B=<int>                   Batch\n"
      << "  --E=<int>                   Expanded factor\n"
      << "  --H=<int>                   Number of heads\n"
      << "\n";

    return out;
  }

  
  auto get_problem_shape() const {
    return cute::make_tuple(G, B, EH, C, L, D, N);
  }

  // acceptable layout by cuDNN
  // x       [b, eh, d, c, l]
  // delta   [b, eh, c, l]
  // delta_A [b, eh, c, l]
  // B       [b,  g, n, c, l]
  // C       [b,  g, n, c, l]
  // y       [b, eh, d, c, l]
  // fstate  [b, eh, d, n]

  auto layoutX() const {
    auto layout = make_layout(make_shape(L, C, D, EH, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  auto layoutDelta() const {
    auto layout = make_layout(make_shape(L, C, EH, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  auto layoutDeltaA() const {
    auto layout = make_layout(make_shape(L, C, EH, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  auto layoutB() const {
    auto layout = make_layout(make_shape(L, C, N, G, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  auto layoutC() const {
    auto layout = make_layout(make_shape(L, C, N, G, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  auto layoutY() const {
    auto layout = make_layout(make_shape(L, C, D, EH, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  auto layoutF() const {
    auto layout = make_layout(make_shape(N, D, EH, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  auto layoutD() const {
    if constexpr (D_HAS_HDIM) {
      auto layout = make_layout(make_shape(D, EH));
      return make_layout(reverse(layout.shape()), reverse(layout.stride()));
    }
    else {
      auto layout = make_layout(make_shape(Int<1>{}, EH));
      return make_layout(reverse(layout.shape()), reverse(layout.stride()));
    }
  }

  auto layoutZ() const {
    auto layout = make_layout(make_shape(L, C, D, EH, B));
    return make_layout(reverse(layout.shape()), reverse(layout.stride()));
  }

  // transformed layout for kernel parameters

  auto layoutX_transformed() const {
    auto layout = make_layout(make_shape(L,int32_t(C),D,EH*B));
    return make_layout(
      make_shape(D,L,int32_t(C),EH*B),
      make_stride(
        stride<2>(layout),
        stride<0>(layout),
        stride<1>(layout),
        stride<3>(layout)
      )
    );
  }

  auto layoutB_transformed() const {
    auto layout = make_layout(make_shape(L,int32_t(C),N,G*B));
    return make_layout(
      make_shape(L,N,int32_t(C),G*B),
      make_stride(
        stride<0>(layout),
        stride<2>(layout),
        stride<1>(layout),
        stride<3>(layout)
      )
    );
  }

  auto layoutC_transformed() const {
    auto layout = make_layout(make_shape(L,int32_t(C),N,G*B));
    return make_layout(
      make_shape(L,N,int32_t(C),G*B),
      make_stride(
        stride<0>(layout),
        stride<2>(layout),
        stride<1>(layout),
        stride<3>(layout)
      )
    );
  }

  auto layoutDelta_transformed() const {
    return make_layout(make_shape(L,int32_t(C),EH*B));
  }

  auto layoutY_transformed() const {
    auto layout = make_layout(make_shape(L,int32_t(C),D,EH*B));
    return make_layout(
      make_shape(L,D,int32_t(C),EH*B), // (M,K,L,...)
      make_stride(
        stride<0>(layout),
        stride<2>(layout),
        stride<1>(layout),
        stride<3>(layout)
      )
    );
  }

  auto layoutF_transformed() const {
    auto layout = make_layout(make_shape(N,D,EH*B));
    return make_layout(
      make_shape(D,N,EH*B),
      make_stride(
        stride<1>(layout),
        stride<0>(layout),
        stride<2>(layout)
      )
    );
  }

  auto layoutD_transformed() const {
    if constexpr (D_HAS_HDIM) {
      return make_layout(make_shape(D, EH));
    }
    else {
      return make_layout(make_shape(Int<1>{}, EH));
    }
  }

  auto layoutZ_transformed() const {
    auto layout = make_layout(make_shape(L,int32_t(C),D,EH*B));
    return make_layout(
      make_shape(L,D,int32_t(C),EH*B),
      make_stride(
        stride<0>(layout),
        stride<2>(layout),
        stride<1>(layout),
        stride<3>(layout)
      )
    );
  }

};

template <typename Element>
static void
initialize_values(
    thrust::universal_vector<Element>& dst_ptr,
    cutlass::Distribution::Kind dist_kind,
    uint64_t seed,
    Element var = Element(1.f)) {
  if (cutlass::Distribution::Uniform == dist_kind) {
    int scope = 2;
    cutlass::reference::host::BlockFillRandomUniform(
        dst_ptr.data().get(), dst_ptr.size(), seed, scope, -scope, 0);
  }
  else if (cutlass::Distribution::AllZeros == dist_kind) {
    cutlass::reference::host::BlockFillRandomUniform(
        dst_ptr.data().get(), dst_ptr.size(), seed, 0, 0, 0);
  }
  else if (cutlass::Distribution::AllOnes == dist_kind) {
    cutlass::reference::host::BlockFillRandomUniform(
        dst_ptr.data().get(), dst_ptr.size(), seed, 1, 1, 0);
  } 
  else if (cutlass::Distribution::Gaussian == dist_kind) {
    cutlass::reference::device::BlockFillRandomGaussian(
      dst_ptr.data().get(), dst_ptr.size(), seed, (Element) 0, var);
  }
  else if (cutlass::Distribution::Sequential == dist_kind) {
    cutlass::reference::host::BlockFillSequential(dst_ptr.data().get(), dst_ptr.size());
  }
  else {
    std::cerr << "Invalid distribution kind!\n.";
    exit(1);
  }
}

template <
  class Options_
>
struct TestBed {
  using Option = Options_;
  using Element = typename Option::Element;
  using ElementDA = typename Option::ElementDA;
  using ElementAcc = typename Option::ElementAcc;

  thrust::universal_vector<Element> tensor_X;
  thrust::universal_vector<Element> tensor_DeltaA;
  thrust::universal_vector<ElementDA> tensor_DeltaA_cumsum;
  thrust::universal_vector<Element> tensor_Delta;
  thrust::universal_vector<Element> tensor_B;
  thrust::universal_vector<Element> tensor_C;
  thrust::universal_vector<Element> tensor_D;
  thrust::universal_vector<Element> tensor_Y;
  thrust::universal_vector<Element> tensor_Z;
  thrust::universal_vector<Element> tensor_Y_ref_0;
  thrust::universal_vector<Element> tensor_Y_ref_1;
  thrust::universal_vector<Element> tensor_F;
  thrust::universal_vector<Element> tensor_F_ref_0;
  thrust::universal_vector<Element> tensor_F_ref_1;

  cutlass::Distribution::Kind init_X      = cutlass::Distribution::Uniform;
  cutlass::Distribution::Kind init_DeltaA = cutlass::Distribution::Gaussian;
  cutlass::Distribution::Kind init_Delta  = cutlass::Distribution::Gaussian;
  cutlass::Distribution::Kind init_B      = cutlass::Distribution::Uniform;
  cutlass::Distribution::Kind init_C      = cutlass::Distribution::Uniform;

  using TileShape = decltype(make_shape(Options::L, Options::D, Options::N)); // (L, D, N)
  using SsdOperation = cutlass::ssd::device::SSD<
    typename cutlass::ssd::kernel::Sm100SsdBuilder<
      Element, ElementDA, ElementAcc, Element,
      TileShape,
      Option::HAS_D, Option::D_HAS_HDIM
    >::Kernel>;
  using CumsumKenrel = cutlass::ssd::kernel::CumsumKernel<Element, ElementDA, TileShape>;
  using CumsumOperation = cutlass::transform::device::TransformUniversalAdapter<CumsumKenrel>;

  bool initialize(Options const& options, const cutlass::KernelHardwareInfo& hw_info, uint64_t seed = 2024) {
    auto [g, b, eh, c, l, d, n] = options.get_problem_shape();
    assert(g == 1 && "Only group size == 1 is supported") ;

    auto size_X      = b * eh * c * l * d;
    auto size_DeltaA = b * eh * c * l;
    auto size_Delta  = b * eh * c * l;
    auto size_B      = g * b * c * n * l;
    auto size_C      = g * b * c * n * l;
    auto size_Y      = b * eh * c * l * d;
    auto size_F      = b * eh * d * n;

    tensor_X      .resize(sizeof(Element) * size(options.layoutX()));
    tensor_DeltaA .resize(sizeof(Element) * size(options.layoutDeltaA()));
    tensor_Delta  .resize(sizeof(Element) * size(options.layoutDelta()));
    tensor_B      .resize(sizeof(Element) * size(options.layoutB()));
    tensor_C      .resize(sizeof(Element) * size(options.layoutC()));
    tensor_D      .resize(sizeof(Element) * size(options.layoutD()));
    tensor_Z      .resize(sizeof(Element) * size(options.layoutZ()));
    tensor_Y      .resize(sizeof(Element) * size(options.layoutY()));
    tensor_Y_ref_0.resize(sizeof(Element) * size(options.layoutY()));
    tensor_Y_ref_1.resize(sizeof(Element) * size(options.layoutY()));
    tensor_F      .resize(sizeof(Element) * size(options.layoutF()));
    tensor_F_ref_0.resize(sizeof(Element) * size(options.layoutF()));
    tensor_F_ref_1.resize(sizeof(Element) * size(options.layoutF()));

    tensor_DeltaA_cumsum.resize(sizeof(ElementDA) * size(options.layoutDeltaA()));

    // Limit distribution to reduce skew between hosts and devices
    initialize_values(tensor_X, init_X, seed);
    initialize_values(tensor_DeltaA, init_DeltaA, seed + 1, Element(0.05f));
    initialize_values(tensor_Delta, init_Delta, seed + 3, Element(0.05f));
    initialize_values(tensor_B, init_B, seed + 5);
    initialize_values(tensor_C, init_C, seed + 7);
    initialize_values(tensor_D, init_C, seed + 9);
    initialize_values(tensor_Z, init_X, seed);

    cudaError_t result;
    result = cudaDeviceSynchronize();
    if (result != cudaSuccess) {
      std::cerr << "Error running the Initialization kernel. Last CUDA error is: "
                << cudaGetErrorString(result) << std::endl;
    }

    // apply cumsum(device) before kernel launch
    typename CumsumOperation::Arguments arguments{
      make_shape(int(b), int(eh), int(c), int(l)),
      {
        tensor_DeltaA.data().get(),
        tensor_DeltaA_cumsum.data().get(),
      },
      hw_info
    };

    CumsumOperation op;

    size_t workspace_size = CumsumOperation::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    cutlass::Status status = op.can_implement(arguments);
    if (status != cutlass::Status::kSuccess) {
      std::cerr << "This kernel is not supported. Last CUDA error is: "
                << cudaGetErrorString(cudaGetLastError()) << std::endl;
      return false;
    }

    status = op.initialize(arguments, workspace.get());
    if (status != cutlass::Status::kSuccess) {
      std::cerr << "Failed to initialize the CUTLASS kernel. Last CUDA error is: "
                << cudaGetErrorString(cudaGetLastError()) << std::endl;
      return false;
    }

    // may be used uninitialized 
    cudaEvent_t start;
    cudaEvent_t end;
    cudaEventCreate(&start);
    cudaEventCreate(&end);

    // warm up
    if (options.measure) {
      for (int i = 0; i < options.warmups; i++) {
        status = op.run();
        if (status != cutlass::Status::kSuccess) {
          std::cerr << "Failed to launch the CUTLASS kernel. Last CUDA error is: "
                    << cudaGetErrorString(cudaGetLastError()) << std::endl;
          return false;
        }
      }
    }
    result = cudaEventRecord(start);
    if (result != cudaSuccess) {
      std::cerr << "cudaEventRecord() failed: " << cudaGetErrorString(result) << std::endl;
      return false;
    }
    // Run
    for (int i = 0; i < options.iterations; i++) {
      status = op.run();
      if (status != cutlass::Status::kSuccess) {
        std::cerr << "Failed to launch the CUTLASS kernel. Last CUDA error is: "
                  << cudaGetErrorString(cudaGetLastError()) << std::endl;
        return false;
      }
    }
    result = cudaEventRecord(end);
    if (result != cudaSuccess) {
      std::cerr << "cudaEventRecord() failed: " << cudaGetErrorString(result) << std::endl;
      return false;
    }

    result = cudaDeviceSynchronize();
    if (result != cudaSuccess) {
      std::cerr << "Error running the CUTLASS kernel. Last CUDA error is: "
                << cudaGetErrorString(result) << std::endl;
      return false;
    }

    float runtime_ms = 0;
    result = cudaEventElapsedTime(&runtime_ms, start, end);
    if (result != cudaSuccess) {
      std::cerr << "cudaEventElapsed() failed: " << cudaGetErrorString(result) << std::endl;
      return false;
    }
    runtime_ms /= static_cast<float>(options.iterations);

    if (options.verbose) {
      printf("[iters = %d, warmups = %d] cumsum kernel runtime_ms = %.4f\n", options.iterations, options.warmups, runtime_ms);
    }

    return true;
  }

  bool sufficient() const {
    int device_idx;
    cudaError_t result = cudaGetDevice(&device_idx);
    if (result != cudaSuccess) {
      throw std::runtime_error("cudaGetDevice() API call failed.");
    }

    int max_smem_size;
    result = cudaDeviceGetAttribute(&max_smem_size, cudaDevAttrMaxSharedMemoryPerBlockOptin, device_idx);
    if (result != cudaSuccess) {
      throw std::runtime_error("cudaDeviceGetAttribute() failed");
    }

    return true;
  }

  bool run(Options const& options, const cutlass::KernelHardwareInfo& hw_info) {
    if (!sufficient()) {
      std::cerr << "Test waived due to insufficient CUDA device.\n";
      return true;
    }

    if (!initialize(options, hw_info)) {
      std::cerr << "Failed to initialize the test.\n";
      return true;
    };

    auto [g, b, eh, c, l, d, n] = options.get_problem_shape();
    typename SsdOperation::Arguments arguments{
      make_shape(int(g), int(b), int(eh), int(c), int(l), int(d), int(n)),
      { 
        tensor_X.data().get(),
        tensor_DeltaA_cumsum.data().get(),
        tensor_Delta.data().get(),
        tensor_B.data().get(),
        tensor_C.data().get(),
        options.layoutX_transformed(),
        options.layoutB_transformed(),
        options.layoutC_transformed(),
        options.layoutDelta_transformed()
      },
      { 
        tensor_Y.data().get(),
        tensor_F.data().get(),
        tensor_D.data().get(),
        // tensor_Z.data().get(),
        options.layoutY_transformed(),
        options.layoutF_transformed(),
        options.layoutD_transformed(),
        // options.layoutZ_transformed()
      },
      hw_info
    };

    SsdOperation op;

    size_t workspace_size = SsdOperation::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    cutlass::Status status = op.can_implement(arguments);
    if (status != cutlass::Status::kSuccess) {
      std::cerr << "This kernel is not supported. Last CUDA error is: "
                << cudaGetErrorString(cudaGetLastError()) << std::endl;
      return false;
    }

    status = op.initialize(arguments, workspace.get());
    if (status != cutlass::Status::kSuccess) {
      std::cerr << "Failed to initialize the CUTLASS kernel. Last CUDA error is: "
                << cudaGetErrorString(cudaGetLastError()) << std::endl;
      return false;
    }

    cudaError_t result;
    // may be used uninitialized 
    cudaEvent_t start;
    cudaEvent_t end;
    cudaEventCreate(&start);
    cudaEventCreate(&end);

    // warm up
    if (options.measure) {
      for (int i = 0; i < options.warmups; i++) {
        status = op.run();
        if (status != cutlass::Status::kSuccess) {
          std::cerr << "Failed to launch the CUTLASS kernel. Last CUDA error is: "
                    << cudaGetErrorString(cudaGetLastError()) << std::endl;
          return false;
        }
      }
    }
    result = cudaEventRecord(start);
    if (result != cudaSuccess) {
      std::cerr << "cudaEventRecord() failed: " << cudaGetErrorString(result) << std::endl;
      return false;
    }
    // Run
    for (int i = 0; i < options.iterations; i++) {
      status = op.run();
      if (status != cutlass::Status::kSuccess) {
        std::cerr << "Failed to launch the CUTLASS kernel. Last CUDA error is: "
                  << cudaGetErrorString(cudaGetLastError()) << std::endl;
        return false;
      }
    }
    result = cudaEventRecord(end);
    if (result != cudaSuccess) {
      std::cerr << "cudaEventRecord() failed: " << cudaGetErrorString(result) << std::endl;
      return false;
    }

    result = cudaDeviceSynchronize();
    if (result != cudaSuccess) {
      std::cerr << "Error running the CUTLASS kernel. Last CUDA error is: "
                << cudaGetErrorString(result) << std::endl;
      return false;
    }

    float runtime_ms = 0;
    result = cudaEventElapsedTime(&runtime_ms, start, end);
    if (result != cudaSuccess) {
      std::cerr << "cudaEventElapsed() failed: " << cudaGetErrorString(result) << std::endl;
      return false;
    }
    runtime_ms /= static_cast<float>(options.iterations);

    if (options.verbose) {
      printf("[iters = %d, warmups = %d] ssd kernel runtime_ms = %.4f\n", options.iterations, options.warmups, runtime_ms);
      printf("smem size = %d\n", SsdOperation::Kernel::SharedStorageSize);
    }
    // Matrix
    // x       [b, eh, d, c, l]
    // delta   [b, eh, c, l]
    // delta_A [b, eh, c, l]
    // B       [b,  g, n, c, l]
    // C       [b,  g, n, c, l]
    // y       [b, eh, d, c, l]
    // fstate  [b, eh, d, n]
    auto mY_ref_0 = cute::make_tensor(tensor_Y_ref_0.data().get(), options.layoutY());
    auto mY_ref_1 = cute::make_tensor(tensor_Y_ref_1.data().get(), options.layoutY());
    auto mY_res   = cute::make_tensor(tensor_Y.data().get(),       options.layoutY());
    auto mF_ref_0 = cute::make_tensor(tensor_F_ref_0.data().get(), options.layoutF());
    auto mF_ref_1 = cute::make_tensor(tensor_F_ref_1.data().get(), options.layoutF());
    auto mF_res   = cute::make_tensor(tensor_F.data().get(),       options.layoutF());
    auto mX       = cute::make_tensor(tensor_X.data().get(),       options.layoutX());
    auto mB       = cute::make_tensor(tensor_B.data().get(),       options.layoutB());
    auto mC       = cute::make_tensor(tensor_C.data().get(),       options.layoutC());
    auto mD       = cute::make_tensor(tensor_D.data().get(),       options.layoutD());
    auto mZ       = cute::make_tensor(tensor_Z.data().get(),       options.layoutZ());
    auto mDelta   = cute::make_tensor(tensor_Delta.data().get(),   options.layoutDelta());
    auto mDeltaA  = cute::make_tensor(tensor_DeltaA.data().get(),  options.layoutDeltaA());

    // Reference Device kernel
    if (options.verify) {
      ssd_reference<Option::HAS_D, Option::D_HAS_HDIM, Option::HAS_Z>(
        mY_ref_1,
        mF_ref_1,
        mX,
        mDelta,
        mDeltaA,
        mB,
        mC,
        mD,
        mZ,
        options
      );
    }

    bool passed = true;

    if (options.verify) {
      printf("[TensorY]verifying...\n");
      passed &= compare_reference<5>(mY_ref_1, mY_res);
      printf("[TensorF]verifying...\n");
      passed &= compare_reference<4>(mF_ref_1, mF_res);
    }

    return passed;
  }

  template<
    int TensorDim,
    class Engine, class Layout
  >
  static constexpr bool
  compare_reference(
      cute::Tensor<Engine, Layout> const& reference,
      cute::Tensor<Engine, Layout> const& computed,
      float epsilon = 0.05f) {
    if (size(reference) != size(computed)) {
      return false;
    }

    bool passed = true;
    if (epsilon == 0.0f) {
      // fast refcheck w/o epsilon
      for (size_t i = 0; i < size_t(size(reference)); ++i) {
        if (reference(i) != computed(i)) {
          passed = false;
          printf("[%llu] %f, %f\n", static_cast<unsigned long long>(i),
            float(reference(i)), float(computed(i)));
          break;
        }
      }
    }
    else {
      // refcheck with epsilon
      for (size_t i = 0; i < size_t(size(reference)); ++i) {
        auto ref = static_cast<float>(reference(i));
        auto act = static_cast<float>(computed(i));
        auto abs_error = std::abs(act - ref);
        auto rel_error = abs_error / (std::max(std::abs(act), std::abs(ref)) + 0.00001f);
        if (std::isnan(abs_error) || std::isnan(rel_error) ||
            std::min(rel_error, abs_error) > epsilon) {
          passed = false;
          printf("[%llu] %f, %f\n", static_cast<unsigned long long>(i),
            float(reference(i)), float(computed(i)));
          break;
        }
      }
    }
    if (not passed) {
      // x       [b, eh, d, c, l]
      // delta   [b, eh, c, l]
      // delta_A [b, eh, c, l]
      // B       [b,  g, n, c, l]
      // C       [b,  g, n, c, l]
      // y       [b, eh, d, c, l]
      // fstate  [b, eh, d, n]
      auto m = cute::shape<2>(reference);
      auto n = cute::shape<TensorDim-1>(reference);
      printf("reference:\n");
      for (int mi = 0; mi < m; ++mi) {
        for (int ni = 0; ni < n; ++ni) {
          if constexpr (TensorDim == 5) {
            printf("%.4f ", static_cast<float>(reference(0,0,mi,0,ni)));
          }
          else {
            printf("%.4f ", static_cast<float>(reference(0,0,mi,ni)));
          }
        }
        printf("\n");
      }
      printf("\n");
      printf("computed:\n");
      for (int mi = 0; mi < m; ++mi) {
        for (int ni = 0; ni < n; ++ni) {
          if constexpr (TensorDim == 5) {
            printf("%.4f ", static_cast<float>(computed(0,0,mi,0,ni)));
          }
          else {
            printf("%.4f ", static_cast<float>(computed(0,0,mi,ni)));
          }
        }
        printf("\n");
      }
      printf("\n");
    }
    return passed;
  }
};

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

int main(int argc, char const **args) {

  cudaDeviceProp props;

  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (error != cudaSuccess) {
    std::cerr << "cudaGetDeviceProperties() returned an error: " << cudaGetErrorString(error) << std::endl;
    return -1;
  }

  if (__CUDACC_VER_MAJOR__ < 12 || props.major < 10) {
    std::cout
      << "This example requires a GPU of NVIDIA's Blackwell Architecture or "
      << "later (compute capability 100 or greater) and CUDA 12.0 or greater.\n";
    return 0;
  }
  else if (__CUDACC_VER_MAJOR__ < 12 || (props.major != 10 || props.minor != 0)) {
    std::cout
      << "This example requires a GPU of NVIDIA's Blackwell Architecture "
      << "(compute capability 100) and CUDA 12.0 or greater.\n";
    return 0;
  }

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

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

  // Execute kernel

  printf("start testing....\n");

  // The KernelHardwareInfo struct holds the number of SMs on the GPU with a given device ID. This
  // information is used by the underlying kernel.
  cutlass::KernelHardwareInfo hw_info;

  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.device_id = 0;
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  // Check Device/Host ref kernel
  TestBed<Options> testbed{};
  bool passed = testbed.run(options, hw_info);

  if (passed) {
    printf("everything is ok.\n");
  }
  else {
    printf("something is wrong!!!!!\n");
  }

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

  return 0;
}
