#include <fstream>

#include "cutlass/cutlass.h"
#include "cutlass/functional.h"

#include "cutlass/gemm/kernel/default_gemm_with_broadcast.h"
#include "cutlass/gemm/device/gemm_universal.h"
#include "cutlass/gemm/device/gemm_universal_with_broadcast.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"

#include "cutlass/epilogue/thread/activation.h"
#include "cutlass/epilogue/thread/linear_combination_bias_relu.h"
#include "cutlass/epilogue/thread/linear_combination_residual_block.h"

#include "../../common/cutlass_unit_test.h"

#include "cutlass/util/host_tensor.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_elementwise.h"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/host/gemm.h"

template<typename GemmElement, typename LayoutA, typename LayoutB, typename LayoutC>
struct TestbedUtils {
  /// Initialization
  cutlass::Distribution::Kind init_A;
  cutlass::Distribution::Kind init_B;
  cutlass::Distribution::Kind init_C;
  cutlass::Distribution::Kind init_D;
  uint64_t seed;

  cutlass::HostTensor<GemmElement, LayoutA> tensor_A;          // Input A
  cutlass::HostTensor<GemmElement, LayoutB> tensor_B;          // Input B
  cutlass::HostTensor<GemmElement, LayoutC> tensor_C;          // Input C
  cutlass::HostTensor<GemmElement, LayoutC> tensor_D1;          // Input D
  cutlass::HostTensor<GemmElement, LayoutC> tensor_D2;          // Input D
  cutlass::HostTensor<GemmElement, LayoutC> tensor_Y1;          // Input Y
  cutlass::HostTensor<GemmElement, LayoutC> tensor_Y2;          // Input Y
  cutlass::HostTensor<GemmElement, LayoutC> tensor_Y_ref;
  cutlass::HostTensor<GemmElement, LayoutC> tensor_Y_transpose_ref;

  //
  // Methods
  //

  TestbedUtils(
    cutlass::Distribution::Kind init_A_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_B_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_C_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_D_ = cutlass::Distribution::Uniform,
    uint64_t seed_ = 2080
  ):
   init_A(init_A_), init_B(init_B_), init_C(init_C_), init_D(init_D_), seed(seed_) { }

  /// Helper to initialize a tensor view
  template <typename Element, typename Layout>
  bool initialize_tensor(
    cutlass::TensorView<Element, Layout> view,
    cutlass::Distribution::Kind dist_kind,
    uint64_t seed) {

    if (dist_kind == cutlass::Distribution::Uniform) {

      double scope_max, scope_min;
      int bits_input = cutlass::sizeof_bits<Element>::value;
      int bits_output = cutlass::sizeof_bits<Element>::value;

      if (bits_input == 1) {
        scope_max = 2;
        scope_min = 0;
      } else if (bits_input <= 8) {
        scope_max = 2;
        scope_min = -2;
      } else if (bits_output == 16) {
        scope_max = 5;
        scope_min = -5;
      } else {
        scope_max = 8;
        scope_min = -8;
      }

      cutlass::reference::host::TensorFillRandomUniform(
        view, seed, scope_max, scope_min, 0);
    }
    else if (dist_kind == cutlass::Distribution::AllZeros) {
      cutlass::reference::host::TensorFill(view);
    }
    else if (dist_kind == cutlass::Distribution::Identity) {

      cutlass::reference::host::TensorFillIdentity(view);
    }
    else if (dist_kind == cutlass::Distribution::Gaussian) {

      cutlass::reference::host::TensorFillRandomGaussian(view, seed, 0, 0.5);
    }
    else if (dist_kind == cutlass::Distribution::Sequential) {

      cutlass::reference::host::BlockFillSequential(
        view.data(), view.capacity());
    }
    else {
      // TODO: Implement the rest
      EXPECT_TRUE(false) << "Not implemented";
      return false;
    }

    return true;
  }

  /// Initializes data structures
  void initialize(cutlass::gemm::GemmCoord problem_size) {
    //
    // Allocate the GEMM workspace
    //

    tensor_A.resize(problem_size.mk());
    tensor_B.resize(problem_size.kn());
    tensor_C.resize({1, problem_size.n()});
    tensor_D1.resize(problem_size.mn());
    tensor_D2.resize(problem_size.mn());
    tensor_Y1.resize(problem_size.mn());
    tensor_Y2.resize(problem_size.mn());
    tensor_Y_ref.resize(problem_size.mn());
    tensor_Y_transpose_ref.resize(problem_size.mn());

    EXPECT_TRUE(initialize_tensor(tensor_A.host_view(), init_A, seed + 2019));
    EXPECT_TRUE(initialize_tensor(tensor_B.host_view(), init_B, seed + 2018));
    EXPECT_TRUE(initialize_tensor(tensor_C.host_view(), init_C, seed + 2017));
    EXPECT_TRUE(initialize_tensor(tensor_D1.host_view(), init_D, seed + 2016));
    EXPECT_TRUE(initialize_tensor(tensor_D2.host_view(), init_D, seed + 2015));
    EXPECT_TRUE(initialize_tensor(tensor_Y1.host_view(), cutlass::Distribution::AllZeros, 0));
    EXPECT_TRUE(initialize_tensor(tensor_Y2.host_view(), cutlass::Distribution::AllZeros, 0));
    EXPECT_TRUE(initialize_tensor(tensor_Y_ref.host_view(), cutlass::Distribution::AllZeros, 0));
    EXPECT_TRUE(initialize_tensor(tensor_Y_transpose_ref.host_view(), cutlass::Distribution::AllZeros, 0));

    // It is possible to randomly initialize to all zeros, so override this with non-zeros
    // in the upper left corner of each operand.
    tensor_A.host_view().at({0, 0}) = GemmElement(1);
    tensor_B.host_view().at({0, 0}) = GemmElement(1);
    tensor_C.host_view().at({0, 0}) = GemmElement(1);
    tensor_D1.host_view().at({0, 0}) = GemmElement(1);
    tensor_D2.host_view().at({0, 0}) = GemmElement(1);

    tensor_A.sync_device();
    tensor_B.sync_device();
    tensor_C.sync_device();
    tensor_D1.sync_device();
    tensor_D2.sync_device();
  }

  /// Compares computed reference with device reference and outputs to a file if incorrect
  bool compare_reference(
    cutlass::gemm::GemmCoord problem_size, cutlass::HostTensor<GemmElement, LayoutC>& tensor_Y_ref, cutlass::HostTensor<GemmElement, LayoutC>& tensor_Y) {

    tensor_Y_ref.sync_host();
    tensor_Y.sync_host();

    EXPECT_GT(cutlass::reference::host::TensorNorm(tensor_A.host_view()), 0);
    EXPECT_GT(cutlass::reference::host::TensorNorm(tensor_B.host_view()), 0);
    EXPECT_GT(cutlass::reference::host::TensorNorm(tensor_C.host_view()), 0);
    EXPECT_GT(cutlass::reference::host::TensorNorm(tensor_D1.host_view()), 0);
    EXPECT_GT(cutlass::reference::host::TensorNorm(tensor_D2.host_view()), 0);
    EXPECT_GT(cutlass::reference::host::TensorNorm(tensor_Y_ref.host_view()), 0);
    EXPECT_GT(cutlass::reference::host::TensorNorm(tensor_Y.host_view()), 0);

    bool passed = true;
    float norm_diff = 0;

    norm_diff = cutlass::reference::host::TensorNormDiff(tensor_Y_ref.host_view(), tensor_Y.host_view(), float());
    passed = (norm_diff <= 0.1f);
    EXPECT_LT(norm_diff, 0.1f) << " tensor_Y is incorrect";

    std::ofstream file("errors_testbed_gemm_broadcast_new.txt");


    file
      << "problem: " << problem_size << "\n\n";

    file
      << "capacity: \n"
      << "A: " << tensor_A.capacity()
      << "\nB: " << tensor_B.capacity()
      << "\nC: " << tensor_C.capacity()
      << "\nD1: " << tensor_D1.capacity()
      << "\nD2: " << tensor_D2.capacity()
      << "\nY: " << tensor_Y.capacity()
      << "\n\n"
      << "\nY_ref: " << tensor_Y_ref.capacity()
      << "\n\n";
    file
      << "A =\n" << tensor_A.host_view()
      << "\n\nB =\n" << tensor_B.host_view()
      << "\n\nC =\n" << tensor_C.host_view()
      << "\n\nD1 =\n" << tensor_D1.host_view()
      << "\n\nD2 =\n" << tensor_D2.host_view()
      << "\n\nY =\n" << tensor_Y.host_view()
      << "\n\nY_ref =\n" << tensor_Y_ref.host_view();

    return passed;
  }
};

#if defined(CUTLASS_ARCH_MMA_SM80_SUPPORTED)

TEST(SM80_Device_GemmWithBroadcast_CUSTOM_f16n_f16n_f16n_tensor_op_f32, 128x128_32x3_64x64x32_16x8x16) {
    using ElementOutput = cutlass::half_t;
    using ElementAccumulator = cutlass::half_t;
    const int M = 1024;
    const int K = 10240;
    const int N = 512;
    cutlass::gemm::GemmCoord problem_size{M, N, K};
    TestbedUtils<cutlass::half_t, cutlass::layout::RowMajor, cutlass::layout::ColumnMajor, cutlass::layout::RowMajor> utils;
    utils.initialize(problem_size);

{
    // Create reference Gemm.
    using Gemm = cutlass::gemm::device::GemmUniversal<
        cutlass::half_t,
        cutlass::layout::RowMajor,
        cutlass::half_t,
        cutlass::layout::ColumnMajor,
        ElementOutput, cutlass::layout::RowMajor,
        ElementAccumulator, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm75,
        cutlass::gemm::GemmShape<64, 64, 32>,
        cutlass::gemm::GemmShape<32, 32, 32>,
        cutlass::gemm::GemmShape<16, 8, 8>,
        cutlass::epilogue::thread::LinearCombination<
            ElementOutput, 128 / cutlass::sizeof_bits<ElementOutput>::value,
            ElementAccumulator, ElementAccumulator>,
        cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle,
        2,
        1,
        1>;

    //
    // Initialize the GEMM operator
    //

    typename Gemm::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      1 /* batch_count */,
      {cutlass::half_t(1) /* alpha */, cutlass::half_t(1) /* beta */},
      utils.tensor_A.device_data(),
      utils.tensor_B.device_data(),
      utils.tensor_C.device_data(),
      utils.tensor_Y_ref.device_data(),
      0,
      0,
      0,
      0,
      K,
      K,
      0,
      N,
    };

    Gemm gemm_op;
    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);
    cutlass::Status status = gemm_op.initialize(arguments, workspace.get());
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << cutlassGetStatusString(status);

    //
    // Run the GEMM
    //

    status = gemm_op();
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << cutlassGetStatusString(status);
}

{
    cutlass::gemm::GemmCoord problem_size{N, M, K};
    // Create another reference Gemm.
    using Gemm = cutlass::gemm::device::GemmUniversal<
        cutlass::half_t,
        cutlass::layout::RowMajor,
        cutlass::half_t,
        cutlass::layout::ColumnMajor,
        ElementOutput, cutlass::layout::ColumnMajor,
        ElementAccumulator, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm75,
        cutlass::gemm::GemmShape<64, 64, 32>,
        cutlass::gemm::GemmShape<32, 32, 32>,
        cutlass::gemm::GemmShape<16, 8, 8>,
        cutlass::epilogue::thread::LinearCombination<
            ElementOutput, 128 / cutlass::sizeof_bits<ElementOutput>::value,
            ElementAccumulator, ElementAccumulator>,
        cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle,
        2,
        1,
        1>;

    //
    // Initialize the GEMM operator
    //

    typename Gemm::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      1 /* batch_count */,
      {cutlass::half_t(1) /* alpha */, cutlass::half_t(1) /* beta */},
      utils.tensor_B.device_data(),
      utils.tensor_A.device_data(),
      utils.tensor_C.device_data(),
      utils.tensor_Y_transpose_ref.device_data(),
      0,
      0,
      0,
      0,
      K,
      K,
      0,
      N
    };

    Gemm gemm_op;
    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);
    cutlass::Status status = gemm_op.initialize(arguments, workspace.get());
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << int(status);

    //
    // Run the GEMM
    //
    status = gemm_op();
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << int(status);
}

    utils.compare_reference(problem_size, utils.tensor_Y_ref, utils.tensor_Y_transpose_ref);

{
    // Create GemmWithBroadcast.
    using Gemm = cutlass::gemm::device::GemmUniversalWithBroadcast<
        cutlass::half_t,
        cutlass::layout::RowMajor,
        cutlass::half_t,
        cutlass::layout::ColumnMajor,
        ElementOutput, cutlass::layout::RowMajor,
        ElementAccumulator, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm75,
        cutlass::gemm::GemmShape<64, 64, 32>,
        cutlass::gemm::GemmShape<32, 32, 32>,
        cutlass::gemm::GemmShape<16, 8, 8>,
        cutlass::epilogue::thread::LinearCombinationResidualBlock<
            ElementOutput, ElementAccumulator, ElementAccumulator,
            ElementAccumulator, 128 / cutlass::sizeof_bits<ElementOutput>::value,
            cutlass::epilogue::thread::Identity, cutlass::multiplies, cutlass::epilogue::thread::Identity>,
        cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle,
        2,
        1,
        1>;

    //
    // Initialize the GEMM operator
    //
    typename Gemm::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      1 /* batch_count */,
      {cutlass::half_t(1) /* alpha */, cutlass::half_t(1) /* beta */},
      utils.tensor_A.device_data(),
      utils.tensor_B.device_data(),
      utils.tensor_D1.device_data(),
      utils.tensor_Y1.device_data(),
      utils.tensor_C.device_data(),
      nullptr,
      0,
      0,
      0,
      0,
      0,
      0,
      K,
      K,
      N,
      N,
      0,
      0
    };

    Gemm gemm_op;
    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);
    cutlass::Status status = gemm_op.initialize(arguments, workspace.get());
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << cutlassGetStatusString(status);

    //
    // Run the GEMM
    //

    status = gemm_op();
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << cutlassGetStatusString(status);
}

    utils.tensor_Y_ref.sync_host();
    cutlass::reference::host::TensorMul(utils.tensor_Y_ref.host_view(), utils.tensor_D1.host_view());
    utils.tensor_Y_ref.sync_device();
    utils.compare_reference(problem_size, utils.tensor_Y_ref, utils.tensor_Y1);

{
    // Create GemmWithBroadcast.
    using Gemm = cutlass::gemm::device::GemmUniversalWithBroadcast<
        cutlass::half_t,
        cutlass::layout::RowMajor,
        cutlass::half_t,
        cutlass::layout::ColumnMajor,
        ElementOutput, cutlass::layout::RowMajor,
        ElementAccumulator, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm75,
        cutlass::gemm::GemmShape<64, 64, 32>,
        cutlass::gemm::GemmShape<32, 32, 32>,
        cutlass::gemm::GemmShape<16, 8, 8>,
        cutlass::epilogue::thread::LinearCombinationResidualBlock<
            ElementOutput, ElementAccumulator, ElementAccumulator,
            ElementAccumulator, 128 / cutlass::sizeof_bits<ElementOutput>::value,
            cutlass::epilogue::thread::Identity, cutlass::multiplies, cutlass::epilogue::thread::Identity, cutlass::plus>,
        cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle,
        2,
        1,
        1>;

    //
    // Initialize the GEMM operator
    //
    typename Gemm::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      1 /* batch_count */,
      {cutlass::half_t(1) /* alpha */, cutlass::half_t(1) /* beta */},
      utils.tensor_A.device_data(),
      utils.tensor_B.device_data(),
      utils.tensor_D1.device_data(),
      utils.tensor_D2.device_data(),
      utils.tensor_Y2.device_data(),
      utils.tensor_C.device_data(),
      nullptr,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      K,
      K,
      N,
      N,
      N,
      0,
      0
    };

    Gemm gemm_op;
    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);
    cutlass::Status status = gemm_op.initialize(arguments, workspace.get());
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << cutlassGetStatusString(status);

    //
    // Run the GEMM
    //

    status = gemm_op();
    EXPECT_TRUE(status == cutlass::Status::kSuccess) << cutlassGetStatusString(status);
}

    utils.tensor_Y_ref.sync_host();
    cutlass::reference::host::TensorAdd(utils.tensor_Y_ref.host_view(), utils.tensor_D2.host_view());
    utils.tensor_Y_ref.sync_device();
    utils.compare_reference(problem_size, utils.tensor_Y_ref, utils.tensor_Y2);
}

#endif
