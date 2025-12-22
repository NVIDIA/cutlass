/*! \file
  \brief CUTLASS layout visualization example
*/

#include <map>
#include <memory>

#include "cutlass/layout/matrix.h"
#include "cutlass/layout/pitch_linear.h"
#include "cutlass/layout/tensor_op_multiplicand_sm70.h"
#include "cutlass/layout/tensor_op_multiplicand_sm75.h"
#include "cutlass/layout/tensor_op_multiplicand_sm80.h"

#include "visualize_layout.h"
#include "register_layout.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

void RegisterLayouts(std::map<std::string, std::unique_ptr<VisualizeLayoutBase> > &layouts) {

  struct {
    char const *name;
    VisualizeLayoutBase *ptr;
  } layout_pairs[] = {

      {"PitchLinear", new VisualizeLayout<cutlass::layout::PitchLinear>},
      {"ColumnMajor", new VisualizeLayout<cutlass::layout::ColumnMajor>},
      {"RowMajor", new VisualizeLayout<cutlass::layout::RowMajor>},
      {"ColumnMajorInterleaved<4>",
       new VisualizeLayout<cutlass::layout::ColumnMajorInterleaved<4>>},
      {"RowMajorInterleaved<4>",
       new VisualizeLayout<cutlass::layout::RowMajorInterleaved<4>>},
      // All Ampere/Turing H/Integer matrix multiply tensor core kernels uses the same swizzling
      // layout implementation with different templates.
      //
      // mma.sync.aligned.m8n8k128.s32.b1.b1.s32 Interleaved-256
      // mma.sync.aligned.m16n8k256.s32.b1.b1.s32 Interleaved-256
      {"TensorOpMultiplicand<1,256>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<1, 256>>},
      // mma.sync.aligned.m8n8k128.s32.b1.b1.s32 TN kblock512
      // mma.sync.aligned.m16n8k256.s32.b1.b1.s32 TN kblock512
      {"TensorOpMultiplicand<1,512>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<1, 512>>},
      // mma.sync.aligned.m16n8k256.s32.b1.b1.s32 TN kblock1024
      {"TensorOpMultiplicand<1,1024>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<1, 1024>>},
      // Integer matrix multiply.int4 8832  Interleaved-64
      // Integer matrix multiply.int4 16864 Interleaved-64
      {"TensorOpMultiplicand<4,64>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<4, 64>>},
      // Integer matrix multiply.int4 8832  TN kblock128
      // Integer matrix multiply.int4 16864 TN kblock128
      {"TensorOpMultiplicand<4,128>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<4, 128>>},
      // Integer matrix multiply.int4 16864 TN kblock256
      {"TensorOpMultiplicand<4,256>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<4, 256>>},
      // Integer matrix multiply 8816  Interleaved-32
      // Integer matrix multiply 16832 Interleaved-32
      {"TensorOpMultiplicand<8,32>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<8, 32>>},
      // Integer matrix multiply 8816  TN kblock64
      // Integer matrix multiply 16832 TN kblock64
      {"TensorOpMultiplicand<8,64>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<8, 64>>},
      // Integer matrix multiply 16832 TN kblock128
      {"TensorOpMultiplicand<8,128>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<8, 128>>},
      // Matrix Multiply 1688  TN kblock32
      // Matrix multiply 16816 TN kblock32
      {"TensorOpMultiplicand<16,32>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<16, 32>>},
      // Matrix multiply 1688  NT
      // Matrix multiply 16816 NT
      // Matrix multiply 16816 TN kblock64
      {"TensorOpMultiplicand<16,64>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<16, 64>>},
      // Matrix multiply 1688.TF32 TN kblock16
      {"TensorOpMultiplicand<32,16>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<32, 16>>},
      // Matrix multiply 1688.TF32 TN kblock32
      {"TensorOpMultiplicand<32,32>",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand<32, 32>>},
      // Matrix multiply 1688 NT
      {"TensorOpMultiplicandCongruous<32,32>",
       new VisualizeLayout<
           cutlass::layout::TensorOpMultiplicandCongruous<32, 32>>},
      // Matrix multiply 884 NT
      {"TensorOpMultiplicandCongruous<64,16>",
       new VisualizeLayout<
           cutlass::layout::TensorOpMultiplicandCongruous<64, 16>>},
      // Matrix multiply 884 TN
      {"TensorOpMultiplicand64bCrosswise",
       new VisualizeLayout<cutlass::layout::TensorOpMultiplicand64bCrosswise>},
      {"TensorOpMultiplicandCongruous<128,4>",
       new VisualizeLayout<
           cutlass::layout::TensorOpMultiplicandCongruous<128, 4>>},
      {"TensorOpMultiplicandCrosswise<128,4>",
       new VisualizeLayout<
           cutlass::layout::TensorOpMultiplicandCrosswise<128, 4>>},
      {"VoltaTensorOpMultiplicandCongruous<16>",
       new VisualizeLayout<
           cutlass::layout::VoltaTensorOpMultiplicandCongruous<16>>},
      {"VoltaTensorOpMultiplicandCrosswise<16,32>",
       new VisualizeLayout<
           cutlass::layout::VoltaTensorOpMultiplicandCrosswise<16, 32>>}
  };

  for (auto layout : layout_pairs) {
    layouts.emplace(std::string(layout.name), std::unique_ptr<VisualizeLayoutBase>(layout.ptr));
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
