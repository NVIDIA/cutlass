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
from gemm_operation import *
###################################################################################################

#
def CudaToolkitVersionSatisfies(semantic_ver_string, major, minor, patch = 0):
  if semantic_ver_string == '':
    cuda_version = [10, 2, 0]
  else:
    cuda_version = [int(x) for x in semantic_ver_string.split('.')]

    return cuda_version >= [major, minor, patch]

###################################################################################################

#
def GenerateSM50(manifest, args):

  min_cc = 50
  max_cc = 1024
  stages = 2

  # single-precision
  inst = MathInstruction([1, 1, 1], DataType.f32, DataType.f32, DataType.f32, OpcodeClass.Simt)
  tile_descriptions = [
    TileDescription([128, 128, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
    TileDescription([128, 256, 8], stages, [2, 4, 1], inst, min_cc, max_cc),
    TileDescription([256, 128, 8], stages, [4, 2, 1], inst, min_cc, max_cc),
    TileDescription([64, 128, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
    TileDescription([128, 64, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
    TileDescription([128, 32, 8], stages, [4, 1, 1], inst, min_cc, max_cc),
    TileDescription([32, 128, 8], stages, [1, 4, 1], inst, min_cc, max_cc),
  ]

  GenerateGemmSimt(GemmKind.Gemm, manifest, tile_descriptions, min_cc)
  GenerateGemmSimt(GemmKind.Batched, manifest, tile_descriptions, min_cc)

  # double precision
  inst = MathInstruction([1, 1, 1], DataType.f64, DataType.f64, DataType.f64, OpcodeClass.Simt)
  tile_descriptions = [
    TileDescription([128, 128, 8], stages, [4, 2, 1], inst, min_cc, max_cc),
    TileDescription([64, 128, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
    TileDescription([128, 64, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
    TileDescription([128, 32, 8], stages, [4, 1, 1], inst, min_cc, max_cc),
    TileDescription([32, 128, 8], stages, [1, 4, 1], inst, min_cc, max_cc),
  ]

  GenerateGemmSimt(GemmKind.Gemm, manifest, tile_descriptions, min_cc)
  GenerateGemmSimt(GemmKind.Batched, manifest, tile_descriptions, min_cc)

###################################################################################################

#
def GenerateSM60(manifest, args):

  min_cc = 60
  max_cc = 1024
  stages = 2

  math_instructions = [
    MathInstruction([1, 1, 1], DataType.f16, DataType.f16, DataType.f16, OpcodeClass.Simt),
  ]

  tile_descriptions = []

  for inst in math_instructions:
    tile_descriptions += [
      TileDescription([256, 256, 8], stages, [4, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 256, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 128, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([64, 128, 8], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([32, 128, 8], stages, [1, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 32, 8], stages, [2, 1, 1], inst, min_cc, max_cc),
    ]

  GenerateGemmSimt(GemmKind.Gemm, manifest, tile_descriptions, min_cc)

###################################################################################################

#
def GenerateSM61(manifest, args):

  min_cc = 61
  max_cc = 1024
  stages = 2

  math_instructions = [
    MathInstruction([1, 1, 4], DataType.s8, DataType.s8, DataType.s32, OpcodeClass.Simt),
  ]

  tile_descriptions = []

  for inst in math_instructions:
    tile_descriptions += [
      TileDescription([128, 256, 32], stages, [2, 4, 1], inst, min_cc, max_cc),
      TileDescription([256, 128, 32], stages, [4, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 128, 32], stages, [2, 4, 1], inst, min_cc, max_cc),
      TileDescription([64, 128, 32], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 64, 32], stages, [4, 1, 1], inst, min_cc, max_cc),
      TileDescription([32, 128, 32], stages, [1, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 32, 32], stages, [2, 1, 1], inst, min_cc, max_cc),
    ]

  GenerateGemmSimt(GemmKind.Gemm, manifest, tile_descriptions, min_cc)

###################################################################################################

#
def GenerateSM70(manifest, args):

  min_cc = 70
  max_cc = 75
  stages = 2
  k_groups = 8

  math_instructions = [
    MathInstruction([8, 8, 4], DataType.f16, DataType.f16, DataType.f16, OpcodeClass.TensorOp),
    MathInstruction([8, 8, 4], DataType.f16, DataType.f16, DataType.f32, OpcodeClass.TensorOp),
  ]

  tile_descriptions = []

  for inst in math_instructions:
    kblock = k_groups * inst.instruction_shape[2]
    tile_descriptions += [
      TileDescription([256, 128, kblock], stages, [4, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 256, kblock], stages, [2, 4, 1], inst, min_cc, max_cc),
      TileDescription([128, 128, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([64, 128, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 64, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([64, 64, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
    ]

  if CudaToolkitVersionSatisfies(args.cuda_version, 10, 1):
    GenerateGemmTensorOp(GemmKind.Gemm, manifest, tile_descriptions, min_cc)
    GenerateGemmTensorOp(GemmKind.Batched, manifest, tile_descriptions, min_cc)

  # wmma tensor op SM70 Gemm kernels
  stages = 2
  k_groups = 2

  math_instructions = [
    MathInstruction([16, 16, 16], DataType.f16, DataType.f16, DataType.f16, OpcodeClass.WmmaTensorOp),
    MathInstruction([16, 16, 16], DataType.f16, DataType.f16, DataType.f32, OpcodeClass.WmmaTensorOp),
  ]

  tile_descriptions = []

  for inst in math_instructions:
    kblock = k_groups * inst.instruction_shape[2]
    tile_descriptions += [
      TileDescription([128, 128, kblock], stages, [2, 4, 1], inst, min_cc, max_cc),
      TileDescription([64, 128, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 64, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([64, 64, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
    ]

  GenerateGemmWmmaTensorOp(GemmKind.Gemm, manifest, tile_descriptions, min_cc)

###################################################################################################

#
def GenerateSM75(manifest, args):

  min_cc = 75
  max_cc = 1024
  stages = 2
  k_groups = 4

  math_instructions = [
    MathInstruction([16, 8, 8], DataType.f16, DataType.f16, DataType.f16, OpcodeClass.TensorOp),
    MathInstruction([16, 8, 8], DataType.f16, DataType.f16, DataType.f32, OpcodeClass.TensorOp),
    MathInstruction([8, 8, 16], DataType.s8, DataType.s8, DataType.s32, OpcodeClass.TensorOp),
    MathInstruction([8, 8, 32], DataType.s4, DataType.s4, DataType.s32, OpcodeClass.TensorOp)
  ]

  tile_descriptions = []

  for inst in math_instructions:
    kblock = k_groups * inst.instruction_shape[2]
    tile_descriptions += [
      TileDescription([256, 128, kblock], stages, [4, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 256, kblock], stages, [2, 4, 1], inst, min_cc, max_cc),
      TileDescription([128, 128, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([64, 128, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([128, 64, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
      TileDescription([64, 64, kblock], stages, [2, 2, 1], inst, min_cc, max_cc),
    ]

  if CudaToolkitVersionSatisfies(args.cuda_version, 10, 2):
    GenerateGemmTensorOp(GemmKind.Gemm, manifest, tile_descriptions, min_cc)
    GenerateGemmTensorOp(GemmKind.Batched, manifest, tile_descriptions, min_cc)


###################################################################################################
###################################################################################################

if __name__ == "__main__":

  parser = argparse.ArgumentParser(description="Generates device kernel registration code for CUTLASS Kernels")
  parser.add_argument("--operations", default="gemm", help="Specifies the operation to generate (gemm, all)")
  parser.add_argument("--build-dir", default=".", required=False, help="CUTLASS top-level build directory")
  parser.add_argument("--curr-build-dir", default=".", help="CUTLASS current build directory. cmake files will be emitted in this directory")
  parser.add_argument("--generator-target", default='library', help="Target of CUTLASS Library Generator.")
  parser.add_argument("--architectures", default='50 60 61 75', help="Target compute architectures")
  parser.add_argument("--kernels", default='', help='Comma delimited list to filter kernels by name.')
  parser.add_argument("--cuda-version", default="10.2.0", help="Semantic version string of CUDA Toolkit")


  args = parser.parse_args()

  manifest = Manifest(args)

  GenerateSM50(manifest, args)
  GenerateSM60(manifest, args)
  GenerateSM61(manifest, args)
  GenerateSM70(manifest, args)
  GenerateSM75(manifest, args)
  if 'library' in args.generator_target.split(','):
    manifest.emit(GeneratorTarget.Library)

#
###################################################################################################
