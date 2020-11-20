#
# \file generator.py
#
# \brief Generates the CUTLASS Library's instances
#

import enum
import os.path
import shutil
import argparse

from library import *
from manifest import *
###################################################################################################

#
def CudaToolkitVersionSatisfies(semantic_ver_string, major, minor, patch = 0):

  # by default, use the latest CUDA Toolkit version
  cuda_version = [11, 0, 132]

  # Update cuda_version based on parsed string
  if semantic_ver_string != '':
    for i, x in enumerate([int(x) for x in semantic_ver_string.split('.')]):
      if i < len(cuda_version):
        cuda_version[i] = x
      else:
        cuda_version.append(x)
  return cuda_version >= [major, minor, patch]


###################################################################################################
###################################################################################################

#
def CreateGemmOperator(manifest, layouts, tile_descriptions, data_type, \
  alignment_constraints, complex_transforms = None, epilogue_functor = EpilogueFunctor.LinearCombination, \
  swizzling_functor = SwizzlingFunctor.Identity8):

  if complex_transforms is None:
    complex_transforms = [(ComplexTransform.none, ComplexTransform.none),]

  element_a, element_b, element_c, element_epilogue = data_type
  
  operations = []

  # by default, only generate the largest tile and largest alignment
  if manifest.args.kernels == '':
    tile_descriptions = [tile_descriptions[0],]
    alignment_constraints = [alignment_constraints[0],]

  for layout in layouts:
    for tile_description in tile_descriptions:
      for alignment in alignment_constraints:
        for complex_transform in complex_transforms:
  
            alignment_c = min(8, alignment)
 
            A = TensorDescription(element_a, layout[0], alignment, complex_transform[0])
            B = TensorDescription(element_b, layout[1], alignment, complex_transform[1])
            C = TensorDescription(element_c, layout[2], alignment_c)

            new_operation = GemmOperation(GemmKind.Universal, tile_description.minimum_compute_capability, \
              tile_description, A, B, C, element_epilogue, epilogue_functor, swizzling_functor)

            manifest.append(new_operation)
            operations.append(new_operation)

  return operations

#
def CreateSparseGemmOperator(manifest, layouts, tile_descriptions, data_type, \
  alignment_constraints, complex_transforms = None, epilogue_functor = EpilogueFunctor.LinearCombination, \
  swizzling_functor = SwizzlingFunctor.Identity8):

  if complex_transforms is None:
    complex_transforms = [(ComplexTransform.none, ComplexTransform.none),]

  element_a, element_b, element_c, element_epilogue = data_type

  gemm_kinds = [GemmKind.Sparse]
  
  operations = []

  # by default, only generate the largest tile and largest alignment
  if manifest.args.kernels == '':
    tile_descriptions = [tile_descriptions[0],]
    alignment_constraints = [alignment_constraints[0],]

  for layout in layouts:
    for tile_description in tile_descriptions:
      for alignment in alignment_constraints:
        for complex_transform in complex_transforms:
  
            alignment_c = min(8, alignment)
 
            A = TensorDescription(element_a, layout[0], alignment, complex_transform[0])
            B = TensorDescription(element_b, layout[1], alignment, complex_transform[1])
            C = TensorDescription(element_c, layout[2], alignment_c)

            new_operation = GemmOperation(GemmKind.Sparse, tile_description.minimum_compute_capability, \
              tile_description, A, B, C, element_epilogue, epilogue_functor, swizzling_functor)

            manifest.append(new_operation)
            operations.append(new_operation)

  return operations

#
def CreateGemmPlanarComplexOperator(manifest, layouts, tile_descriptions, data_type, \
  alignment_constraints, complex_transforms):

  if complex_transforms is None:
    complex_transforms = [(ComplexTransform.none, ComplexTransform.none),]

  element_a, element_b, element_c, element_epilogue = data_type

  gemm_kinds = [GemmKind.PlanarComplex, GemmKind.PlanarComplexArray]
  
  # by default, planar complex gemm kernels are not generated
  if manifest.args.kernels == '':
    return
  
  for gemm_kind in gemm_kinds:
    for layout in layouts:
      for tile_description in tile_descriptions:
        for alignment in alignment_constraints:
          for complex_transform in complex_transforms:

            alignment_c = min(8, alignment)

            A = TensorDescription(element_a, layout[0], alignment, complex_transform[0])
            B = TensorDescription(element_b, layout[1], alignment, complex_transform[1])
            C = TensorDescription(element_c, layout[2], alignment_c)

            manifest.append(GemmOperation(gemm_kind, \
              tile_description.minimum_compute_capability, \
              tile_description, A, B, C, element_epilogue))
  return

###########################################################################################################
#   ConvolutionOperator support variations
#        ____________________________________________________________________
#         ConvolutionalOperator |        Analytic      |      Optimized
#        ____________________________________________________________________
#        |       Fprop          |     (strided)        |    (strided)
#        |       Dgrad          |   (strided, unity*)  |     (unity)
#        |       Wgrad          |     (strided)        |    (strided)
#        ____________________________________________________________________
#
# Note :  Operator marked (*) are supported but not generated to keep the instantiated kernel count low
###########################################################################################################
# Convolution for 2D operations
def CreateConv2dOperator(manifest, layout, tile_descriptions, data_type, alignment, \
  conv_kinds = [ConvKind.Fprop, ConvKind.Dgrad, ConvKind.Wgrad], epilogue_functor = EpilogueFunctor.LinearCombination):
  
  element_a, element_b, element_c, element_epilogue = data_type
  
  # one exceptional case
  alignment_c = min(8, alignment)
  
  # iterator algorithm (analytic and optimized)
  iterator_algorithms = [IteratorAlgorithm.Analytic, IteratorAlgorithm.Optimized]

  # by default, only generate the largest tile size
  if manifest.args.kernels == '':
    tile_descriptions = [tile_descriptions[0],]

  operations = []

  for tile in tile_descriptions:
    for conv_kind in conv_kinds:
      for iterator_algorithm in iterator_algorithms:
        A = TensorDescription(element_a, layout[0], alignment)
        B = TensorDescription(element_b, layout[1], alignment)
        C = TensorDescription(element_c, layout[2], alignment_c)

        # unity stride only for Optimized Dgrad
        if (iterator_algorithm == IteratorAlgorithm.Optimized) and (conv_kind == ConvKind.Dgrad):
          new_operation = Conv2dOperation(conv_kind, iterator_algorithm, tile.minimum_compute_capability, tile,\
            A, B, C, element_epilogue, StrideSupport.Unity, epilogue_functor)

          manifest.append(new_operation)
          operations.append(new_operation)

        # strided dgrad is not supported by Optimized Dgrad
        if (iterator_algorithm == IteratorAlgorithm.Optimized) and (conv_kind == ConvKind.Dgrad):
          continue 

        # strided support for Fprop (Analytic/Optimized), Dgrad (Analytic), and Wgrad (Analytic)
        new_operation = Conv2dOperation(conv_kind, iterator_algorithm, tile.minimum_compute_capability, tile,\
         A, B, C, element_epilogue, StrideSupport.Strided, epilogue_functor)

        manifest.append(new_operation)
        operations.append(new_operation)

  return operations

# Convolution for 3D operations
def CreateConv3dOperator(manifest, layout, tile_descriptions, data_type, alignment, \
  conv_kinds = [ConvKind.Fprop, ConvKind.Dgrad, ConvKind.Wgrad], epilogue_functor = EpilogueFunctor.LinearCombination):
  
  element_a, element_b, element_c, element_epilogue = data_type
  
  # one exceptional case
  alignment_c = min(8, alignment)
  
  # iterator algorithm (analytic and optimized)
  iterator_algorithms = [IteratorAlgorithm.Analytic, IteratorAlgorithm.Optimized]

  # by default, only generate the largest tile size
  if manifest.args.kernels == '':
    tile_descriptions = [tile_descriptions[0],]

  operations = []

  for tile in tile_descriptions:
    for conv_kind in conv_kinds:
      for iterator_algorithm in iterator_algorithms:
        A = TensorDescription(element_a, layout, alignment)
        B = TensorDescription(element_b, layout, alignment)
        C = TensorDescription(element_c, layout, alignment_c)
        
        # optimized conv3d iterator algorithm is only for Wgrad
        if (iterator_algorithm == IteratorAlgorithm.Optimized) \
          and ((conv_kind == ConvKind.Fprop) or (conv_kind == ConvKind.Dgrad)):
          continue

        # strided support for Fprop (Analytic/Optimized), Dgrad (Analytic), and Wgrad (Analytic)
        new_operation = Conv3dOperation(conv_kind, iterator_algorithm, tile.minimum_compute_capability, tile,\
         A, B, C, element_epilogue, StrideSupport.Strided, epilogue_functor)

        manifest.append(new_operation)
        operations.append(new_operation)


  return operations

###################################################################################################
###################################################################################################

#
def GenerateSM50_Simt(manifest, args):
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f32, DataType.f32, DataType.f32,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f64, DataType.f64, DataType.f64,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add),
  ]

  min_cc = 50
  max_cc = 1024

  alignment_constraints = [1,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128, 128, 8], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 8], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 8], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 8], 2, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  32, 8], 2, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 32, 128, 8], 2, [1, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    if math_inst.element_a == DataType.f32:
      conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
      CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 1)
#

#
def GenerateSM50_Simt_complex(manifest, args):
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f32, DataType.f32, DataType.f32,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add_complex),
  ]

  min_cc = 50
  max_cc = 1024

  alignment_constraints = [1,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128, 128, 8], 2, [4, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      DataType.cf32,
      DataType.cf32,
      DataType.cf32,
      DataType.cf32,
    ]

    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 1)
#

#
def GenerateSM50(manifest, args):
  GenerateSM50_Simt(manifest, args)
  GenerateSM50_Simt_complex(manifest, args)

###################################################################################################
###################################################################################################

#
def GenerateSM60_Simt(manifest, args):
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add),
  ]

  min_cc = 60
  max_cc = 1024

  alignment_constraints = [1,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 8], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 8], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 8], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 8], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 8], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 8], 2, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  32, 8], 2, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 32, 128, 8], 2, [1, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)
#

#
def GenerateSM60(manifest, args):
  GenerateSM60_Simt(manifest, args)

###################################################################################################
###################################################################################################

#
def GenerateSM61_Simt(manifest, args):
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 4],                                      \
      DataType.s8, DataType.s8, DataType.s32,         \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add),
  ]

  min_cc = 61
  max_cc = 1024

  alignment_constraints = [1,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128, 128, 32], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 2, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  32, 32], 2, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 32, 128, 32], 2, [1, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    data_type_mixed = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_a,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type_mixed, alignment_constraints)
#

#
def GenerateSM61(manifest, args):
  GenerateSM61_Simt(manifest, args)

###################################################################################################
###################################################################################################

#
def GenerateSM70_TensorOp_884(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 1):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [8, 8, 4],                                      \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [8, 8, 4],                                      \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
  ]

  min_cc = 70
  max_cc = 75

  alignment_constraints = [8, 4, 2, 1]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 32], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 32], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 8)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints)
    
      CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type_mixed, 8)

#
def GenerateSM70_PlanarComplexTensorOp_884(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 1):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  complex_transforms = [
    (ComplexTransform.none, ComplexTransform.none),
    (ComplexTransform.conj, ComplexTransform.none),
    (ComplexTransform.none, ComplexTransform.conj),
    (ComplexTransform.conj, ComplexTransform.conj)
  ]

  math_instructions = [
    MathInstruction(                                  \
      [8, 8, 4],                                      \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [8, 8, 4],                                      \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
  ]

  min_cc = 70
  max_cc = 75

  alignment_constraints = [8, 2, 1]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([ 64,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmPlanarComplexOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, complex_transforms)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateGemmPlanarComplexOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints, complex_transforms)
    

#
def GenerateSM70_WmmaTensorOp_161616(manifest, args):

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 16, 16],                                   \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.WmmaTensorOp,                       \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 16, 16],                                   \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.WmmaTensorOp,                       \
      MathOperation.multiply_add),
  ]

  min_cc = 70
  max_cc = 1024

  alignment_constraints = [8,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128, 128, 32], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints)

#
##################################################################################################
#

def GenerateSM70(manifest, args):
  GenerateSM70_TensorOp_884(manifest, args)
  GenerateSM70_PlanarComplexTensorOp_884(manifest, args)

  # To limit build size, WMMA GEMMs are disabled for now.
  #
  #GenerateSM70_WmmaTensorOp_161616(manifest, args)

###################################################################################################
###################################################################################################

#
def GenerateSM75_TensorOp_1688(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 2):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 8],                                     \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 8],                                     \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [8, 4, 2, 1]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 32], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 32], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 8)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints)

      CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type_mixed, 8)

#

#
def GenerateSM75_PlanarComplexTensorOp_1688(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 2):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  complex_transforms = [
    (ComplexTransform.none, ComplexTransform.none),
    (ComplexTransform.conj, ComplexTransform.none),
    (ComplexTransform.none, ComplexTransform.conj),
    (ComplexTransform.conj, ComplexTransform.conj)
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 8],                                     \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 8],                                     \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [8, 2, 1]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([ 64, 128, 32], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmPlanarComplexOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, complex_transforms)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateGemmPlanarComplexOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints, complex_transforms)

#
def GenerateSM75_TensorOp_8816_TN(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 2):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [8, 8, 16],                                     \
      DataType.s8, DataType.s8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [8, 8, 16],                                     \
      DataType.u8, DataType.u8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [16,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 64], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 64], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      DataType.s32,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
      data_type, 16, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        DataType.f32,
      ]

      operations = []

      operations += CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
    
      operations += CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
        data_type_mixed, 16, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)

      for op in operations:
        if op.tile_description.threadblock_shape[1] >= 128:
          op.C.alignment = 16
        else:
          op.C.alignment = 8

#

#
def GenerateSM75_TensorOp_8816_Interleaved(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 2):
    return

  layouts = [
    (LayoutType.ColumnMajorInterleaved32, LayoutType.RowMajorInterleaved32, LayoutType.ColumnMajorInterleaved32),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [8, 8, 16],                                     \
      DataType.s8, DataType.s8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [8, 8, 16],                                     \
      DataType.u8, DataType.u8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [16,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 64], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 64], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 64], 2, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 64], 2, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 64], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type_mixed = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_a,
      DataType.f32,
    ]
    
    operations = CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

#    conv_layout = (LayoutType.TensorNC32HW32, LayoutType.TensorC32RSK32, LayoutType.TensorNC32HW32)
#
#    operations += CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
#      data_type_mixed, 16, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)

    for op in operations:
      op.C.alignment = 8
#

#
def GenerateSM75_TensorOp_8832_TN(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 2):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [8, 8, 32],                                     \
      DataType.s4, DataType.s4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [8, 8, 32],                                     \
      DataType.u4, DataType.u4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [32,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 128], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 128], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 128], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 128], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 128], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 128], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      DataType.s32,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
      
    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
      data_type, 32, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        DataType.f32,
      ]

      operations = []

      operations += CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
    
      operations += CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
        data_type_mixed, 32, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)

      for op in operations:
        if op.tile_description.threadblock_shape[1] >= 128:
          op.C.alignment = 8
        elif op.tile_description.threadblock_shape[1] == 64:
          op.C.alignment = 8
        else:
          op.C.alignment = 4

#

#
def GenerateSM75_TensorOp_8832_Interleaved(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 2):
    return

  layouts = [
    (LayoutType.ColumnMajorInterleaved64, LayoutType.RowMajorInterleaved64, LayoutType.ColumnMajorInterleaved64),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [8, 8, 32],                                     \
      DataType.s4, DataType.s4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [8, 8, 32],                                     \
      DataType.u4, DataType.u4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [32,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 128], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 128], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 128], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 128], 2, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 128], 2, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 128], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        DataType.f32,
      ]

      operations = CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

#      conv_layout = (LayoutType.TensorNC64HW64, LayoutType.TensorC64RSK64, LayoutType.TensorNC64HW64)
#  
#      operations += CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
#        data_type_mixed, 32, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)

      for op in operations:
        op.C.alignment = 16 
#

#
def GenerateSM75_TensorOp_88128(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [8, 8, 128],                                   \
      DataType.b1, DataType.b1, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.xor_popc),
  ]

  min_cc = 75 
  max_cc = 1024

  alignment_constraints = [128,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 512], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 512], 2, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 512], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 512], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 512], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 512], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [DataType.b1, DataType.b1, DataType.s32, DataType.s32]

    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

#

#
def GenerateSM75_WmmaTensorOp_161616(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 10, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 16, 16],                                   \
      DataType.s8, DataType.s8, DataType.s32,         \
      OpcodeClass.WmmaTensorOp,                       \
      MathOperation.multiply_add),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [16,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128, 128, 32], 2, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 2, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      DataType.f32,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        DataType.f32,
      ]

      CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints)
#

#
def GenerateSM75_Simt_complex(manifest, args):
  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f32, DataType.f32, DataType.f32,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add_complex),
  ]

  min_cc = 75
  max_cc = 1024

  alignment_constraints = [1,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128, 128, 8], 5, [4, 2, 1], math_inst, min_cc, max_cc)
    ]
    data_type = [
      DataType.cf32,
      DataType.cf32,
      DataType.cf32,
      DataType.cf32
    ]

    complex_transforms = [
      (ComplexTransform.none, ComplexTransform.none),
      (ComplexTransform.conj, ComplexTransform.none),
      (ComplexTransform.none, ComplexTransform.conj),
      (ComplexTransform.conj, ComplexTransform.conj)
    ]

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 1)
#

def GenerateSM75(manifest, args):
  GenerateSM75_TensorOp_1688(manifest, args)
  GenerateSM75_PlanarComplexTensorOp_1688(manifest, args)
  GenerateSM75_TensorOp_8816_TN(manifest, args)
  GenerateSM75_TensorOp_8816_Interleaved(manifest, args)
  GenerateSM75_TensorOp_8832_TN(manifest, args)
  GenerateSM75_TensorOp_8832_Interleaved(manifest, args)
  GenerateSM75_TensorOp_88128(manifest, args)
  #GenerateSM75_WmmaTensorOp_161616(manifest, args)
  GenerateSM75_Simt_complex(manifest, args)


###################################################################################################
###################################################################################################

#
def GenerateSM80_TensorOp_16816(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 16],                                    \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 16],                                    \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 16],                                    \
      DataType.bf16, DataType.bf16, DataType.f32,     \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
  ]

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [8, 4, 2]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 32],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 32],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 32],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 32],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 32],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 10, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128, 64],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 256, 64],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 64],  4, [4, 1, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([ 64, 256, 64],  4, [1, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 128, 64],  4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 64],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 64],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 64],  5, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 8)
    CreateConv3dOperator(manifest, LayoutType.TensorNDHWC, tile_descriptions, data_type, 8)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints)

      CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type_mixed, 8)
      CreateConv3dOperator(manifest, LayoutType.TensorNDHWC, tile_descriptions, data_type_mixed, 8)
#

#
def GenerateSM80_SparseTensorOp_16832(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 1):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.RowMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.RowMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.RowMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.RowMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 32],                                    \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 32],                                    \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 32],                                    \
      DataType.bf16, DataType.bf16, DataType.f32,     \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
  ]

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [8, 4, 2]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([ 64, 128,  64],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128,  64],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 256,  64],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 128,  64],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64,  64],  3, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256,  64],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64,  64],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64,  64],  4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 128],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 128],  3, [4, 1, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128,  64, 128],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([ 64, 128, 128],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 128],  3, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateSparseGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateSparseGemmOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints)

#

#
def GenerateSM80_PlanarComplexTensorOp_16816(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  complex_transforms = [
    (ComplexTransform.none, ComplexTransform.none),
    (ComplexTransform.conj, ComplexTransform.none),
    (ComplexTransform.none, ComplexTransform.conj),
    (ComplexTransform.conj, ComplexTransform.conj)
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 16],                                    \
      DataType.f16, DataType.f16, DataType.f32,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 16],                                    \
      DataType.bf16, DataType.bf16, DataType.f32,     \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
    MathInstruction(                                  \
      [16, 8, 16],                                    \
      DataType.f16, DataType.f16, DataType.f16,       \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add),
  ]

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [8, ]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([ 64, 128, 32], 3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 32], 3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmPlanarComplexOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, complex_transforms)

    # Avoid emitting two kernels if the accumulator type does not differ from the input type (e.g. F16 accumulation)
    if math_inst.element_a != math_inst.element_accumulator:

      data_type_mixed = [
        math_inst.element_a,
        math_inst.element_b,
        math_inst.element_a,
        math_inst.element_accumulator,
      ]

      CreateGemmPlanarComplexOperator(manifest, layouts, tile_descriptions, \
        data_type_mixed, alignment_constraints, complex_transforms)

#
def GenerateSM80_TensorOp_16832_TN(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 32],                                    \
      DataType.s8, DataType.s8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [16, 8, 32],                                    \
      DataType.u8, DataType.u8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [16,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128,  64],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256,  64],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64,  64],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256,  64],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128,  64],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64,  64],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128,  64],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64,  64], 10, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128, 128],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 256, 128],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 128],  4, [4, 1, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([ 64, 256, 128],  4, [1, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 128, 128],  4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 128],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 128],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 128],  5, [2, 2, 1], math_inst, min_cc, max_cc),
    ]
  
    data_type = [math_inst.element_a, math_inst.element_b, math_inst.element_accumulator, DataType.s32]
    data_type_mixed = [math_inst.element_a, math_inst.element_b, math_inst.element_a, DataType.f32]
  
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
  
    operations = []
  
    operations += CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
      
    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
      data_type, 16, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)
    
    operations += CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
      data_type_mixed, 16, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)
  
    for op in operations:
      if op.tile_description.threadblock_shape[1] >= 128:
        op.C.alignment = 16
      else:
        op.C.alignment = 8

#

#
def GenerateSM80_SparseTensorOp_16864_TN(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 1):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.RowMajor),
  ]

  math_inst =                                         \
    MathInstruction(                                  \
      [16, 8, 64],                                    \
      DataType.s8, DataType.s8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate)

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [16,]

  tile_descriptions = [
    TileDescription([128,  64, 128],  3, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([256, 128, 128],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128, 256, 128],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128, 128, 128],  3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([256,  64, 128],  3, [4, 1, 1], math_inst, min_cc, max_cc),
    TileDescription([ 64, 256, 128],  4, [1, 4, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([ 64, 128, 128],  6, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([ 64,  64, 128],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128, 128, 256],  3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128,  64, 256],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([ 64, 128, 256],  3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([ 64,  64, 256],  3, [2, 2, 1], math_inst, min_cc, max_cc),
  ]

  data_type = [DataType.s8, DataType.s8, DataType.s32, DataType.s32]
  data_type_mixed = [DataType.s8, DataType.s8, DataType.s8, DataType.f32]

  CreateSparseGemmOperator(manifest, layouts, tile_descriptions, \
    data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

  operations = []

  operations += CreateSparseGemmOperator(manifest, layouts, tile_descriptions, \
    data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

  for op in operations:
    if op.tile_description.threadblock_shape[1] >= 128:
      op.C.alignment = 16
    else:
      op.C.alignment = 8
#

#
def GenerateSM80_TensorOp_16832_Interleaved(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajorInterleaved32, LayoutType.RowMajorInterleaved32, LayoutType.ColumnMajorInterleaved32),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 32],                                    \
      DataType.s8, DataType.s8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [16, 8, 32],                                    \
      DataType.u8, DataType.u8, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [16,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 64],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 64],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 64],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 64],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 64],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 64],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 64],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 64], 10, [2, 2, 1], math_inst, min_cc, max_cc),
    ]
  
    data_type_mixed = [math_inst.element_a, math_inst.element_b, math_inst.element_a, DataType.f32]
  
    operations = CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
 
#    conv_layout = (LayoutType.TensorNC32HW32, LayoutType.TensorC32RSK32, LayoutType.TensorNC32HW32)
#
#    operations += CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
#      data_type_mixed, 16, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)
 
    for op in operations:
      op.C.alignment = 8
#

#
def GenerateSM80_TensorOp_16864_TN(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 64],                                    \
      DataType.s4, DataType.s4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [16, 8, 64],                                    \
      DataType.u4, DataType.u4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [32,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 128],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 128],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 128],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 128],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 128],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 128],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 128],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 128], 10, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128, 256],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 256, 256],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 256],  4, [4, 1, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([ 64, 256, 256],  4, [1, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 128, 256],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128,  64, 256],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 256],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 256],  5, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    ]
  
    data_type = [math_inst.element_a, math_inst.element_b, math_inst.element_accumulator, DataType.s32]
    data_type_mixed = [math_inst.element_a, math_inst.element_b, math_inst.element_a, DataType.f32]
  
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
  
    operations = []
  
    operations += CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
  
    for op in operations:
      if op.tile_description.threadblock_shape[1] >= 128:
        op.C.alignment = 8
      elif op.tile_description.threadblock_shape[1] == 64:
        op.C.alignment = 8
      else:
        op.C.alignment = 4
#

#
def GenerateSM80_SparseTensorOp_168128_TN(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 1):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.RowMajor),
  ]

  math_inst =                                         \
    MathInstruction(                                  \
      [16, 8, 128],                                    \
      DataType.s4, DataType.s4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate)

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [32,]

  tile_descriptions = [
    TileDescription([ 64,  64, 256],  4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([256,  64, 256],  3, [4, 1, 1], math_inst, min_cc, max_cc),
    TileDescription([256, 128, 256],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128, 256, 256],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128, 128, 256],  3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([ 64, 256, 256],  4, [1, 4, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128,  64, 256],  3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([ 64, 128, 256],  6, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128, 128, 512],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128,  64, 512],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([ 64, 128, 512],  3, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([ 64,  64, 512],  3, [2, 2, 1], math_inst, min_cc, max_cc),
  ]

  data_type = [DataType.s4, DataType.s4, DataType.s32, DataType.s32]
  data_type_mixed = [DataType.s4, DataType.s4, DataType.s4, DataType.f32]

  CreateSparseGemmOperator(manifest, layouts, tile_descriptions, \
    data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

  operations = []

  operations += CreateSparseGemmOperator(manifest, layouts, tile_descriptions, \
    data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

  for op in operations:
    if op.tile_description.threadblock_shape[1] >= 128:
      op.C.alignment = 8 
    elif op.tile_description.threadblock_shape[1] == 64:
      op.C.alignment = 8
    else:
      op.C.alignment = 4 
#

#
def GenerateSM80_TensorOp_16864_Interleaved(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
      (LayoutType.ColumnMajorInterleaved64, LayoutType.RowMajorInterleaved64, LayoutType.ColumnMajorInterleaved64),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 64],                                    \
      DataType.s4, DataType.s4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
    MathInstruction(                                  \
      [16, 8, 64],                                    \
      DataType.u4, DataType.u4, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.multiply_add_saturate),
  ]

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [32,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 128],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 128],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 128],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 128],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 128],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 128],  6, [2, 2, 1], math_inst, min_cc, max_cc),
    ]
  
    data_type_mixed = [math_inst.element_a, math_inst.element_b, math_inst.element_a, DataType.f32]
    
    operations = []
  
    operations += CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type_mixed, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)
 
#    conv_layout = (LayoutType.TensorNC64HW64, LayoutType.TensorC64RSK64, LayoutType.TensorNC64HW64)
#  
#    operations += CreateConv2dOperator(manifest, conv_layout, tile_descriptions,
#      data_type_mixed, 32, [ConvKind.Fprop], EpilogueFunctor.LinearCombinationClamp)
 
    for op in operations:
      op.C.alignment = 16 
#

#
def GenerateSM80_TensorOp_168256(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [16, 8, 256],                                   \
      DataType.b1, DataType.b1, DataType.s32,         \
      OpcodeClass.TensorOp,                           \
      MathOperation.xor_popc),
  ]

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [128,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128,  512],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256,  512],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64,  512],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256,  512],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128,  512],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64,  512],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128,  512],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64,  512], 10, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128, 1024],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 1024],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 1024],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 1024],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 1024],  4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 1024],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 1024],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 1024],  5, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [DataType.b1, DataType.b1, DataType.s32, DataType.s32]

    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints, None, EpilogueFunctor.LinearCombinationClamp)

#

#
def GenerateSM80_TensorOp_1688(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                      \
      [16, 8, 8],                                         \
      DataType.tf32, DataType.tf32, DataType.f32,     \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add)
  ]

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [4, 2, 1]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 16],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 16],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 16],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 16],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 16],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 16],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 16],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 16], 10, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128, 32],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 256, 32],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 32],  4, [4, 1, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([ 64, 256, 32],  4, [1, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 128, 32],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128,  64, 32],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([64,  128, 32],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32],  5, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]

    data_type_mixed = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_a,
      math_inst.element_accumulator,
    ]

    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type_mixed, alignment_constraints)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 4)

    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type_mixed, 4)
#

#
def GenerateSM80_TensorOp_1688_fast_math(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                      \
      [16, 8, 8],                                         \
      DataType.tf32, DataType.tf32, DataType.f32,     \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add),
    MathInstruction(                                      \
      [16, 8, 8],                                         \
      DataType.f16, DataType.f16, DataType.f32,           \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add_fast_f16),
    MathInstruction(                                      \
      [16, 8, 8],                                         \
      DataType.bf16, DataType.bf16, DataType.f32,       \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add_fast_bf16)
  ]

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [4, 2, 1]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 16],  3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 16],  3, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([256,  64, 16],  4, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 16],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 16],  5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 16],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 16],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 16], 10, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128, 32],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 256, 32],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 32],  4, [4, 1, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([ 64, 256, 32],  4, [1, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 128, 32],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128,  64, 32],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32],  5, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [DataType.f32, DataType.f32, DataType.f32, DataType.f32]

    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 4)
#

#
def GenerateSM80_SparseTensorOp_16816_fast_math(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 1):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.RowMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.RowMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.RowMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.RowMajor),
  ]

  math_instructions = [
    MathInstruction(                                      \
      [16, 8, 16],                                         \
      DataType.tf32, DataType.tf32, DataType.f32,     \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add),
  ]

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [4, 2, 1]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128,  64, 32],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 32],  3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256, 128, 32],  3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128, 256, 32],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 32],  3, [4, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 256, 32],  4, [1, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 32],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 32],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 64],  3, [2, 4, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([256,  64, 64],  3, [4, 1, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([128,  64, 64],  4, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
      TileDescription([ 64, 128, 64],  3, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 64],  3, [2, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [DataType.f32, DataType.f32, DataType.f32, DataType.f32]

    CreateSparseGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)
#

#
def GenerateSM80_TensorOp_1688_complex(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_inst = MathInstruction(                  \
    [16, 8, 8],                                 \
    DataType.f32, DataType.f32, DataType.f32,   \
    OpcodeClass.TensorOp,                       \
    MathOperation.multiply_add_complex)

  min_cc = 80
  max_cc = 1024

  tile_descriptions = [
    TileDescription([64, 64, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([128, 64, 16], 4, [4, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 128, 16], 4, [2, 4, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 64, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 32, 16], 4, [2, 1, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 32, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
  ]

  data_type = [
    DataType.cf32, DataType.cf32, DataType.cf32, DataType.cf32
  ]

  alignment_constraints = [1,]

  complex_transforms = [
    (ComplexTransform.none, ComplexTransform.none),
    (ComplexTransform.conj, ComplexTransform.none),
    (ComplexTransform.none, ComplexTransform.conj),
    (ComplexTransform.conj, ComplexTransform.conj)
  ]

  CreateGemmOperator(manifest, layouts, tile_descriptions, \
    data_type, alignment_constraints, complex_transforms)
#

#
def GenerateSM80_TensorOp_884(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_inst =                                             \
    MathInstruction(                                      \
      [8, 8, 4],                                          \
      DataType.f64, DataType.f64, DataType.f64,           \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add)

  min_cc = 80
  max_cc = 1024
  max_cc_smem_limited = 80

  alignment_constraints = [1,]

  tile_descriptions = [
    TileDescription([128, 128, 16], 3, [4, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([64, 128, 16], 3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([128, 64, 16], 3, [2, 2, 1], math_inst, min_cc, max_cc_smem_limited),
    TileDescription([64, 64, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 32, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 64, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 32, 16], 5, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([16, 32, 16], 5, [1, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 16, 16], 5, [2, 1, 1], math_inst, min_cc, max_cc),
  ]

  data_type = [DataType.f64, DataType.f64, DataType.f64, DataType.f64]

  CreateGemmOperator(manifest, layouts, tile_descriptions, \
    data_type, alignment_constraints)
#

#
def GenerateSM80_TensorOp_884_complex(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_inst =                                             \
    MathInstruction(                                      \
      [8, 8, 4],                                          \
      DataType.f64, DataType.f64, DataType.f64,           \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add_complex)

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [1,]

  tile_descriptions = [
    TileDescription([128, 64, 8], 3, [4, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 128, 8], 3, [2, 4, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 64, 8], 3, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 32, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 64, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 32, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([16, 32, 8], 4, [1, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 16, 8], 4, [2, 1, 1], math_inst, min_cc, max_cc),
  ]

  data_type = [DataType.cf64, DataType.cf64, DataType.cf64, DataType.cf64]

  complex_transforms = [
    (ComplexTransform.none, ComplexTransform.none),
    (ComplexTransform.conj, ComplexTransform.none),
    (ComplexTransform.none, ComplexTransform.conj),
    (ComplexTransform.conj, ComplexTransform.conj)
  ]

  CreateGemmOperator(manifest, layouts, tile_descriptions, \
    data_type, alignment_constraints, complex_transforms)

#
def GenerateSM80_TensorOp_884_complex_gaussian(manifest, args):

  if not CudaToolkitVersionSatisfies(args.cuda_version, 11, 0):
    return

  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_inst =                                             \
    MathInstruction(                                      \
      [8, 8, 4],                                          \
      DataType.f64, DataType.f64, DataType.f64,           \
      OpcodeClass.TensorOp,                               \
      MathOperation.multiply_add_complex_gaussian)

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [1,]

  tile_descriptions = [
    TileDescription([64, 64, 8], 3, [4, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([64, 32, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 64, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 32, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([16, 32, 8], 4, [1, 2, 1], math_inst, min_cc, max_cc),
    TileDescription([32, 16, 8], 4, [2, 1, 1], math_inst, min_cc, max_cc),
  ]

  data_type = [DataType.cf64, DataType.cf64, DataType.cf64, DataType.cf64]

  complex_transforms = [
    (ComplexTransform.none, ComplexTransform.none),
    (ComplexTransform.conj, ComplexTransform.none),
    (ComplexTransform.none, ComplexTransform.conj),
    (ComplexTransform.conj, ComplexTransform.conj)
  ]

  CreateGemmOperator(manifest, layouts, tile_descriptions, \
    data_type, alignment_constraints, complex_transforms)
#

###################################################################################################

#
def GenerateSM80_Simt_f32(manifest, args):
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f32, DataType.f32, DataType.f32,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add),
  ]

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [1,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([256, 128, 8], 5, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 8], 5, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 8], 5, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([256, 128, 8], 4, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 256, 8], 4, [2, 4, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 8], 4, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 8], 5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 8], 5, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 8], 5, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  32, 8], 5, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 32, 128, 8], 5, [1, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 1)
#


#
def GenerateSM80_Simt_f64(manifest, args):
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f64, DataType.f64, DataType.f64,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add),
  ]

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [1,]

  for math_inst in math_instructions:
    tile_descriptions = [
      TileDescription([128, 128, 8], 3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 8], 4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64,  64, 8], 5, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  32, 8], 5, [2, 1, 1], math_inst, min_cc, max_cc),
      TileDescription([ 32, 128, 8], 5, [1, 2, 1], math_inst, min_cc, max_cc),
    ]

    data_type = [
      math_inst.element_a,
      math_inst.element_b,
      math_inst.element_accumulator,
      math_inst.element_accumulator,
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, \
      data_type, alignment_constraints)
#


##################################################################################################
#
def GenerateSM80_Simt_complex(manifest, args):
  math_instructions = [
    MathInstruction(                                  \
      [1, 1, 1],                                      \
      DataType.f32, DataType.f32, DataType.f32,       \
      OpcodeClass.Simt,                               \
      MathOperation.multiply_add_complex),
  ]

  min_cc = 80
  max_cc = 1024

  alignment_constraints = [1,]

  data_type = [
    DataType.cf32,
    DataType.cf32,
    DataType.cf32,
    DataType.cf32
  ]
    
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  complex_transforms = [
    (ComplexTransform.none, ComplexTransform.none),
    (ComplexTransform.conj, ComplexTransform.none),
    (ComplexTransform.none, ComplexTransform.conj),
    (ComplexTransform.conj, ComplexTransform.conj)
  ]

  for math_inst in math_instructions:

    tile_descriptions = [
      TileDescription([128, 128, 8], 5, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128, 128, 8], 4, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([64, 64, 8], 3, [4, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([ 64, 128, 16],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([128,  64, 16],  6, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([64, 32, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([32, 64, 16], 4, [2, 2, 1], math_inst, min_cc, max_cc),
      TileDescription([32, 32, 16], 5, [2, 2, 1], math_inst, min_cc, max_cc),
    ]
    
    CreateGemmOperator(manifest, layouts, tile_descriptions, data_type, alignment_constraints, complex_transforms)

    conv_layout = (LayoutType.TensorNHWC, LayoutType.TensorNHWC, LayoutType.TensorNHWC)
    CreateConv2dOperator(manifest, conv_layout, tile_descriptions, data_type, 1)
#

###################################################################################################

#
def GenerateSM80(manifest, args):
  GenerateSM80_TensorOp_16816(manifest, args)
  GenerateSM80_SparseTensorOp_16832(manifest, args)
  GenerateSM80_PlanarComplexTensorOp_16816(manifest, args)
  GenerateSM80_TensorOp_1688(manifest, args)
  GenerateSM80_TensorOp_1688_fast_math(manifest, args)
  GenerateSM80_SparseTensorOp_16816_fast_math(manifest, args)
  GenerateSM80_TensorOp_1688_complex(manifest, args)
  GenerateSM80_TensorOp_884(manifest, args)
  GenerateSM80_TensorOp_884_complex(manifest, args)
  GenerateSM80_TensorOp_884_complex_gaussian(manifest, args)
  GenerateSM80_TensorOp_16832_TN(manifest, args)
  GenerateSM80_SparseTensorOp_16864_TN(manifest, args)
  GenerateSM80_TensorOp_16832_Interleaved(manifest, args)
  GenerateSM80_TensorOp_16864_TN(manifest, args)
  GenerateSM80_SparseTensorOp_168128_TN(manifest, args)
  GenerateSM80_TensorOp_16864_Interleaved(manifest, args)
  GenerateSM80_TensorOp_168256(manifest, args)
  GenerateSM80_Simt_f32(manifest, args)
  GenerateSM80_Simt_f64(manifest, args)
  GenerateSM80_Simt_complex(manifest, args)

###################################################################################################
###################################################################################################

if __name__ == "__main__":

  parser = argparse.ArgumentParser(description="Generates device kernel registration code for CUTLASS Kernels")
  parser.add_argument("--operations", default="all", help="Specifies the operation to generate (gemm, all)")
  parser.add_argument("--build-dir", default=".", required=False, help="CUTLASS top-level build directory")
  parser.add_argument("--curr-build-dir", default=".", help="CUTLASS current build directory. cmake files will be emitted in this directory")
  parser.add_argument("--generator-target", default='library', help="Target of CUTLASS Library Generator.")
  parser.add_argument("--architectures", default='53;60;61;70;75;80', help="Target compute architectures")
  parser.add_argument("--kernels", default='', help='Comma delimited list to filter kernels by name.')
  parser.add_argument("--ignore-kernels", default='', help='Comma delimited list of kernels to exclude from build.')
  parser.add_argument("--cuda-version", default="11.0.0", help="Semantic version string of CUDA Toolkit")
  parser.add_argument('--kernel-filter-file',   type=str, default=None, required=False, help='Full path of filter file')
  parser.add_argument('--selected-kernel-list',   type=str, default=None, required=False,
                        help='Specify the output log file containing all enabled kernels in this build')

  args = parser.parse_args()

  manifest = Manifest(args)

  GenerateSM50(manifest, args)
  GenerateSM60(manifest, args)
  GenerateSM61(manifest, args)
  GenerateSM70(manifest, args)
  GenerateSM75(manifest, args)
  GenerateSM80(manifest, args)
  if 'library' in args.generator_target.split(','):
    manifest.emit(GeneratorTarget.Library)

  if args.selected_kernel_list is not None:
    if len(manifest.selected_kernels) > 0:
      with open(args.selected_kernel_list, 'w') as file_writer:
        for line in manifest.selected_kernels:
          file_writer.write("%s\n" % line)
#
###################################################################################################
