/***************************************************************************************************
 * Copyright (c) 2017 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/***************************************************************************************************
 Example contrasting the Stream-K parallel decomposition for GEMM threadblocks versus the
 "classic data-parallel" and "Split-K" decompositions + residual add.

 For more details regarding the Stream-K method, see "Stream-K: Work-centric Parallel Decomposition
 for Dense Matrix-Matrix Multiplication on the GPU" (https://arxiv.org/abs/2301.03598)

 Requires NVIDIA Ampere or newer device (SM80+).

 - To lock persistence mode, power (400W), clocks (1005MHz) for evaluation (assumes device 0 and A100)

     cutlass$ sudo nvidia-smi -pm 1 -i 0

     cutlass$ sudo nvidia-smi -i 0 -pl 400

     cutlass$ sudo nvidia-smi -i 0 -lgc 1005

 - Build and run:

     cutlass$ mkdir build

     cutlass$ cd build

     cutlass/build$ cmake .. -DCUTLASS_NVCC_ARCHS=80

     cutlass/build$ make 47a_ampere_gemm_universal_streamk_residual

     cutlass/build$ ./examples/47a_ampere_gemm_universal_streamk_residual/47_ampere_gemm_universal_streamk_residual

 **************************************************************************************************/

#include <iostream>
#include <string>

#include "cutlass/cutlass.h"
#include "cutlass/gemm/device/gemm_universal.h"
#include "cutlass/gemm/device/gemm_universal_with_broadcast.h"
#include "cutlass/gemm/device/gemm_universal_streamk_with_broadcast.h"
#include "cutlass/epilogue/thread/linear_combination_residual_block.h"

#include "cutlass/util/command_line.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/device/gemm.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_foreach.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/tensor_view_io.h"

#include "helper.h"



/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations (cutlass_tensorop_h16816gemm_128x128_32x4_nn_align8)
/////////////////////////////////////////////////////////////////////////////////////////////////

// A matrix configuration
using         ElementA         = cutlass::half_t;                                  // Element type for A matrix operand
using         LayoutA          = cutlass::layout::RowMajor;                        // Layout type for A matrix operand
constexpr int AlignmentA       = 128 / cutlass::sizeof_bits<ElementA>::value;      // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         ElementB         = cutlass::half_t;                                  // Element type for B matrix operand
using         LayoutB          = cutlass::layout::RowMajor;                        // Layout type for B matrix operand
constexpr int AlignmentB       = 128 / cutlass::sizeof_bits<ElementB>::value;      // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// C/D/T/Z matrix configuration
using         ElementC         = cutlass::half_t;                                  // Element type for C matrix operands
using         LayoutC          = cutlass::layout::RowMajor;                        // Layout type for C matrix operands
constexpr int AlignmentC       = 128 / cutlass::sizeof_bits<ElementC>::value;      // Memory access granularity/alignment of C matrices in units of elements (up to 16 bytes)

// Output matrix configuration
using         ElementOutput    = cutlass::half_t;                                  // Element type for output matrix operands
using         LayoutOutput     = cutlass::layout::RowMajor;                        // Layout type for output matrix operands
// constexpr int AlignmentOutput  = 128 / cutlass::sizeof_bits<ElementOutput>::value; // Memory access granularity/alignment of output matrices in units of elements (up to 16 bytes)

// Multiply-accumulate blocking/pipelining details
using ElementAccumulator  = cutlass::half_t;                          // Element type for internal accumulation
using ElementCompute      = cutlass::half_t;                          // Element type for compute
using ArchTag             = cutlass::arch::Sm80;                      // Tag indicating the minimum SM that supports the intended feature
using OperatorClass       = cutlass::arch::OpClassTensorOp;           // Operator class tag
using ThreadblockShape    = cutlass::gemm::GemmShape<128, 128, 32>;   // Threadblock-level tile size (concept: GemmShape)
using WarpShape           = cutlass::gemm::GemmShape<64, 64, 32>;     // Warp-level tile size (concept: GemmShape)
using InstructionShape    = cutlass::gemm::GemmShape<16, 8, 16>;      // Instruction-level tile size (concept: GemmShape)
constexpr int NumStages   = 4;                                        // Number of global->shared pipeline stages used in the GEMM mainloop

// Residual block configuration

// Epilogue output operator
/// Using LinearCombinationResidualBlock
/// Models a residual block of the form: UnaryOp(BinaryOp(BinaryOp(ActivationOp(TensorOp(X) + bias), residual1), residual2))
using EpilogueOp = cutlass::epilogue::thread::LinearCombinationResidualBlock<  
    ElementOutput,                        // Element type for output matrix
    ElementAccumulator,                   // Element type from internal accumulation
    ElementCompute,                       // Element type from internal accumulation
    ElementC,                             // Element type for C/D/T/Z matrix operands
    AlignmentC,                           // Memory access granularity of C and D matrix in units of elements
    cutlass::epilogue::thread::Identity,  // Activation
    cutlass::plus,                        // Binary operation 1
    cutlass::epilogue::thread::Identity   // Unary operation
    >;

// Reference device GEMM implementation type
using DeviceGemmReference = cutlass::reference::device::Gemm<
  ElementA,
  LayoutA,
  ElementB,
  LayoutB,
  ElementC,
  LayoutC,
  ElementAccumulator,
  ElementAccumulator>;

// Classic data-parallel device GEMM implementation type
using DeviceGemmBasic = cutlass::gemm::device::GemmUniversalWithBroadcast<
    ElementA, LayoutA,
    ElementB, LayoutB,
    ElementC, LayoutC,
    ElementAccumulator,
    OperatorClass,
    ArchTag,
    ThreadblockShape,
    WarpShape,
    InstructionShape,
    EpilogueOp,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    NumStages,
    AlignmentA,
    AlignmentB>;

// StreamK device GEMM implementation type
using DeviceGemmStreamK = cutlass::gemm::device::GemmUniversalStreamkWithBroadcast<
    ElementA, LayoutA,
    ElementB, LayoutB,
    ElementC, LayoutC,
    ElementAccumulator,
    OperatorClass,
    ArchTag,
    ThreadblockShape,
    WarpShape,
    InstructionShape,
    EpilogueOp,
    cutlass::gemm::threadblock::ThreadblockSwizzleStreamK,
    NumStages,
    AlignmentA,
    AlignmentB>;


/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Result structure
struct Result
{
  double avg_runtime_ms;
  double gflops;
  cutlass::Status status;
  cudaError_t error;
  bool passed;

  Result(
    double avg_runtime_ms = 0,
    double gflops = 0,
    cutlass::Status status = cutlass::Status::kSuccess,
    cudaError_t error = cudaSuccess)
  :
    avg_runtime_ms(avg_runtime_ms), gflops(gflops), status(status), error(error), passed(true)
  {}

};


/// Command line options parsing
struct Options
{
  std::string               command_name;
  bool                      help;
  cutlass::gemm::GemmCoord  problem_size;
  float                     alpha;
  float                     beta;
  int                       split_k_factor;
  int                       avail_sms;
  bool                      reference_check;
  int                       iterations;

  cutlass::HostTensor<ElementA, LayoutA> tensor_a;
  cutlass::HostTensor<ElementB, LayoutB> tensor_b;
  cutlass::HostTensor<ElementC, LayoutC> tensor_c;
  cutlass::HostTensor<ElementC, LayoutC> tensor_d;
  cutlass::HostTensor<ElementC, LayoutC> tensor_ref_d;
  cutlass::HostTensor<ElementC, LayoutC> tensor_z;
  cutlass::HostTensor<ElementC, LayoutC> tensor_t;

  Options(std::string command_name) :
    command_name(command_name),
    help(false),
    problem_size({2048, 2048, 2048}),
    alpha(1.0f),
    beta(0.0f),
    split_k_factor(1),
    avail_sms(-1),              // Number of device SMs to use is unlimited
    reference_check(true),
    iterations(10000)
  {}

  bool valid() const
  {
    return true;
  }

  void parse(int argc, char const **args)
  {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
    }

    cmd.get_cmd_line_argument("m", problem_size.m());
    cmd.get_cmd_line_argument("n", problem_size.n());
    cmd.get_cmd_line_argument("k", problem_size.k());
    cmd.get_cmd_line_argument("alpha", alpha);
    cmd.get_cmd_line_argument("beta", beta);
    cmd.get_cmd_line_argument("split", split_k_factor);
    cmd.get_cmd_line_argument("iterations", iterations);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const
  {
    out
      << "Performs a GEMM computation.\n"
      << "\n"
      << "Options:\n"
      << "\n"
      << "  --help                      If specified, displays this usage statement.\n\n"
      << "  --m=<int>                   GEMM M dimension\n"
      << "  --n=<int>                   GEMM N dimension\n"
      << "  --k=<int>                   GEMM K dimension\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --split=<int>               Split-K factor to emulate\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << command_name << " --m=1024 --n=512 --k=1024 --alpha=2 --beta=0.707 \n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s) const
  {
    // Two flops per multiply-add
    return 2.0 * double(problem_size.product()) / double(1.0e9) / runtime_s;
  }
};


/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Populates a DeviceGemmBasic::Arguments structure from the given commandline options
typename DeviceGemmBasic::Arguments args_from_options(
    const DeviceGemmBasic &device_gemm,
    const Options &options,
    cutlass::HostTensor<ElementA, LayoutA> &tensor_a,
    cutlass::HostTensor<ElementB, LayoutB> &tensor_b,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_c,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_d,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_z,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_t
    )
{
  return typename DeviceGemmBasic::Arguments(
    cutlass::gemm::GemmUniversalMode::kGemm,  // universal mode
    options.problem_size,                     // problem_size
    options.split_k_factor,                   // batch count / splitk slices
    {                                         // epilogue parameters
      ElementAccumulator(options.alpha),
      ElementAccumulator(options.beta)
    },
    tensor_a.device_data(),                   // ptr_A
    tensor_b.device_data(),                   // ptr_B
    tensor_c.device_data(),                   // ptr_C
    tensor_d.device_data(),                   // ptr_D
    tensor_z.device_data(),                   // ptr_Vector
    tensor_t.device_data(),                   // ptr_Tensor
    options.problem_size.mk().product(),      // batch_stride_A
    options.problem_size.nk().product(),      // batch_stride_B
    options.problem_size.mn().product(),      // batch_stride_C
    options.problem_size.mn().product(),      // batch_stride_D
    options.problem_size.mn().product(),      // batch_stride_Vector
    options.problem_size.mn().product(),      // batch_stride_Tensor
    tensor_a.layout().stride(0),              // stride_a
    tensor_b.layout().stride(0),              // stride_b
    tensor_c.layout().stride(0),              // stride_c
    tensor_d.layout().stride(0),              // stride_d
    tensor_z.layout().stride(0),              // stride_Vector
    tensor_t.layout().stride(0));             // stride_Tensor
}

/// Populates a DeviceGemmStreamK::Arguments structure from the given commandline options
typename DeviceGemmStreamK::Arguments args_from_options(
    const DeviceGemmStreamK &device_gemm,
    const Options &options,
    cutlass::HostTensor<ElementA, LayoutA> &tensor_a,
    cutlass::HostTensor<ElementB, LayoutB> &tensor_b,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_c,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_d,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_z,
    cutlass::HostTensor<ElementC, LayoutC> &tensor_t
    )
{
  return typename DeviceGemmStreamK::Arguments(
    cutlass::gemm::GemmUniversalMode::kGemm,  // universal mode
    options.problem_size,                     // problem_size
    options.split_k_factor,                   // batch count / splitk slices
    {                                         // epilogue parameters
      ElementAccumulator(options.alpha),
      ElementAccumulator(options.beta)
    },
    tensor_a.device_data(),                   // ptr_A
    tensor_b.device_data(),                   // ptr_B
    tensor_c.device_data(),                   // ptr_C
    tensor_d.device_data(),                   // ptr_D
    tensor_z.device_data(),                   // ptr_Vector
    tensor_t.device_data(),                   // ptr_Tensor
    options.problem_size.mk().product(),      // batch_stride_A
    options.problem_size.nk().product(),      // batch_stride_B
    options.problem_size.mn().product(),      // batch_stride_C
    options.problem_size.mn().product(),      // batch_stride_D
    options.problem_size.mn().product(),      // batch_stride_Vector
    options.problem_size.mn().product(),      // batch_stride_Tensor
    tensor_a.layout().stride(0),              // stride_a
    tensor_b.layout().stride(0),              // stride_b
    tensor_c.layout().stride(0),              // stride_c
    tensor_d.layout().stride(0),              // stride_d
    tensor_z.layout().stride(0),              // stride_Vector
    tensor_t.layout().stride(0),              // stride_Tensor
    options.avail_sms);                       // avail_sms
}


/// Tensor MSE function
//// Useful when we expect outputs to approximately match, but 
//// not exactly.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorMSEFunc {

  //
  // Data members
  //

  cutlass::TensorView<Element, Layout> lhs;
  cutlass::TensorView<Element, Layout> rhs;
  double err;
  double cnt;

  /// Ctor
  TensorMSEFunc(): err(0), cnt(0) { }

  /// Ctor
  TensorMSEFunc(
    cutlass::TensorView<Element, Layout> const &lhs_,
    cutlass::TensorView<Element, Layout> const &rhs_
  ) :
    lhs(lhs_), rhs(rhs_), err(0), cnt(0) { }

  /// Visits a coordinate
  void operator()(cutlass::Coord<Layout::kRank> const &coord) {

    Element lhs_ = lhs.at(coord);
    Element rhs_ = rhs.at(coord);
    
    cnt += double(1.0);
    double diff = double(lhs_) - double(rhs_);
    err += double(diff * diff);
  }

  double get_err() const {
    if (cnt == double(0.0))
      return double(0.0);
    return err / cnt;
  }
};

/// Mean squared error
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
double TensorMSE(
  cutlass::TensorView<Element, Layout> const &lhs, 
  cutlass::TensorView<Element, Layout> const &rhs) {

  // Extents must be identical
  if (lhs.extent() != rhs.extent()) {
    return double(-1);
  }

  TensorMSEFunc<Element, Layout> func(lhs, rhs);
  cutlass::reference::host::TensorForEach(
    lhs.extent(),
    func
  );

  return func.get_err();
}

/// Execute a given example GEMM computation
template <typename DeviceGemmT>
Result run(std::string description, Options &options)
{
  // Display test description
  std::cout << std::endl << description << std::endl;

  // Zero-initialize test output matrix D
  cutlass::reference::host::TensorFill(options.tensor_d.host_view());
  options.tensor_d.sync_device();

  // Instantiate CUTLASS kernel depending on templates
  DeviceGemmT device_gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of DeviceGemmT
  auto arguments = args_from_options(device_gemm, options, 
      options.tensor_a, options.tensor_b, options.tensor_c, options.tensor_d, 
      options.tensor_z, options.tensor_t);

  // Using the arguments, query for extra workspace required for matrix multiplication computation
  size_t workspace_size = DeviceGemmT::get_workspace_size(arguments);

  // Allocate workspace memory
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  // Check the problem size is supported or not
  CUTLASS_CHECK(device_gemm.can_implement(arguments));

  // Initialize CUTLASS kernel with arguments and workspace pointer
  CUTLASS_CHECK(device_gemm.initialize(arguments, workspace.get()));

  // Correctness / Warmup iteration
  CUTLASS_CHECK(device_gemm());

  // Copy output data from CUTLASS and reference kernel to host for comparison
  options.tensor_d.sync_host();

  // Check if output from CUTLASS kernel and reference kernel are equal or not
  Result result;
  result.passed = cutlass::reference::host::TensorEquals(
    options.tensor_d.host_view(),
    options.tensor_ref_d.host_view());

  double err = TensorMSE(
    options.tensor_d.host_view(),
    options.tensor_ref_d.host_view());

  std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << " - MSE: " << err << std::endl;

  // Run profiling loop
  if (options.iterations > 0)
  {
    GpuTimer timer;
    timer.start();
    for (int iter = 0; iter < options.iterations; ++iter) {
      CUTLASS_CHECK(device_gemm());
    }
    timer.stop();

    // Compute average runtime and GFLOPs.
    float elapsed_ms = timer.elapsed_millis();
    result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

    std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  GFLOPs: " << result.gflops << std::endl;
  }

  // TODO: uncomment when results match
  //if (!result.passed) {
  //  exit(-1);
  //}

  return result;
}


/// Program entrypoint
int main(int argc, const char **argv)
{
  // CUTLASS must be compiled with CUDA 11.0 Toolkit to run these examples.
  if (!(__CUDACC_VER_MAJOR__ >= 11)) {
    std::cerr << "Ampere Tensor Core operations must be compiled with CUDA 11.0 Toolkit or later." << std::endl;

    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  // Current device must must have compute capability at least 80
  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  if (!((props.major * 10 + props.minor) >= 80))
  {
    std::cerr << "Ampere Tensor Core operations must be run on a machine with compute capability at least 80."
              << std::endl;

    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  // Parse commandline options
  Options options("ampere_streamk_residual_gemm");
  options.parse(argc, argv);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  std::cout <<
    options.iterations << " timing iterations of " <<
    options.problem_size.m() << " x " <<
    options.problem_size.n() << " x " <<
    options.problem_size.k() << " matrix-matrix multiply" << std::endl;

  if (!options.valid()) {
    std::cerr << "Invalid problem." << std::endl;
    return -1;
  }


  //
  // Initialize GEMM datasets
  //

  // Initialize tensors using CUTLASS helper functions
  options.tensor_a.resize(options.problem_size.mk());       // <- Create matrix A with dimensions M x K
  options.tensor_b.resize(options.problem_size.kn());       // <- Create matrix B with dimensions K x N
  options.tensor_c.resize(options.problem_size.mn());       // <- Create matrix C with dimensions M x N
  options.tensor_d.resize(options.problem_size.mn());       // <- Create matrix D with dimensions M x N used to store output from CUTLASS kernel
  options.tensor_ref_d.resize(options.problem_size.mn());   // <- Create matrix D with dimensions M x N used to store output from reference kernel
  options.tensor_z.resize(options.problem_size.mn());       // <- Create residual matrix Z with dimensions M x N
  options.tensor_t.resize(options.problem_size.mn());       // <- Create residual matrix T with dimensions M x N

  // Fill matrix A on host with uniform-random data [4, -4]
  cutlass::reference::host::TensorFillRandomUniform(
      options.tensor_a.host_view(),
      1,
      ElementA(2),
      ElementA(-2),
      8);

  // Fill matrix B on host with uniform-random data [4, -4]
  cutlass::reference::host::TensorFillRandomUniform(
      options.tensor_b.host_view(),
      1,
      ElementB(2),
      ElementB(-2),
      8);

  // Fill matrix C on host with uniform-random data [4, -4]
  cutlass::reference::host::TensorFillRandomUniform(
      options.tensor_c.host_view(),
      1,
      ElementC(2),
      ElementC(-2),
      8);

  // Fill matrix Z on host with uniform-random data [4, -4]
  cutlass::reference::host::TensorFillRandomUniform(
      options.tensor_z.host_view(),
      1,
      ElementC(2),
      ElementC(-2),
      8);

  // Fill matrix T on host with uniform-random data [4, -4]
  cutlass::reference::host::TensorFillRandomUniform(
      options.tensor_t.host_view(),
      1,
      ElementC(2),
      ElementC(-2),
      8);


  //
  // Compute reference output
  //

  // Copy data from host to GPU
  options.tensor_a.sync_device();
  options.tensor_b.sync_device();
  options.tensor_c.sync_device();
  options.tensor_z.sync_device();
  options.tensor_t.sync_device();

  // Zero-initialize reference output matrix D
  cutlass::reference::host::TensorFill(options.tensor_ref_d.host_view());
  options.tensor_ref_d.sync_device();

  // Create instantiation for device reference gemm kernel
  DeviceGemmReference gemm_reference;

  // Launch device reference gemm kernel
  gemm_reference(
    options.problem_size,
    ElementAccumulator(options.alpha),
    options.tensor_a.device_ref(),
    options.tensor_b.device_ref(),
    ElementAccumulator(options.beta),
    options.tensor_c.device_ref(),
    options.tensor_ref_d.device_ref());

  // Wait for kernels to finish
  CUDA_CHECK(cudaDeviceSynchronize());

  // Copy output data from reference kernel to host for comparison
  options.tensor_ref_d.sync_host();

  // TODO: move over to reference? 
  // TODO: move to device?
  for (int idx=0; idx < options.problem_size.mn().product(); ++idx) {
      ElementC* ptr_D = (ElementC*)(options.tensor_ref_d.host_view().ref().data());
      ElementC* ptr_Z = (ElementC*)(options.tensor_z.host_view().ref().data());
      ElementC* ptr_T = (ElementC*)(options.tensor_t.host_view().ref().data());
      ptr_D[idx] = (ptr_D[idx] + ptr_Z[idx]) + ptr_T[idx];
  }

  //
  // Evaluate CUTLASS kernels
  //

  // Test default operation
  if (options.split_k_factor == 1)
  {
    // Compare basic data-parallel version versus StreamK version using default load-balancing heuristics
    Result basic_dp         = run<DeviceGemmBasic>("Basic data-parallel GEMM", options);
    Result streamk_default  = run<DeviceGemmStreamK>("StreamK GEMM with default load-balancing", options);

    printf("  Speedup vs Basic-DP: %.3f\n", (basic_dp.avg_runtime_ms / streamk_default.avg_runtime_ms));

    // Show that StreamK can emulate basic data-parallel GEMM when we set the number of SMs to load-balance across = 1
    options.avail_sms       = 1;        // Set loadbalancing width to 1 SM (no load balancing)
    Result streamk_dp       = run<DeviceGemmStreamK>("StreamK emulating basic data-parallel GEMM", options);
    options.avail_sms       = -1;       // Reset loadbalancing width to unspecified SMs (i.e., the number of device SMs)

    printf("  Speedup vs Basic-DP: %.3f\n", (basic_dp.avg_runtime_ms / streamk_dp.avg_runtime_ms));

    options.split_k_factor++;     // Increment splitting factor for next evaluation

  }

  // Show that StreamK can emulate "Split-K" with a tile-splitting factor
  Result basic_splitk = run<DeviceGemmBasic>(
    std::string("Basic split-K GEMM with tile-splitting factor ") + std::to_string(options.split_k_factor),
    options);

  Result streamk_splitk = run<DeviceGemmStreamK>(
    std::string("StreamK emulating Split-K GEMM with tile-splitting factor ") + std::to_string(options.split_k_factor),
    options);

  printf("  Speedup vs Basic-SplitK: %.3f\n", (basic_splitk.avg_runtime_ms / streamk_splitk.avg_runtime_ms));

  return 0;
}
