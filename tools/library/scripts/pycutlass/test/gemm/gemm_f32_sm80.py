import pycutlass
from pycutlass import *
from pycutlass.memory_manager import get_allocated_size
from pycutlass.test import *
import unittest

from pycutlass.test.gemm_testbed import test_all_gemm


class GemmF32nF32nF32nTensorOpF32Sm80(unittest.TestCase):
    def test_SM80_Device_Gemm_f32t_f32n_f32t_tensor_op_bf16_f32_128x128x32_64x64x32(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 8],
            element_a=cutlass.float32, element_b=cutlass.float32,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add_fast_bf16
        )

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 32],
            stages=3, warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        A = TensorDescription(
            element=cutlass.float32, layout=cutlass.RowMajor,
            alignment=4
        )
        B = TensorDescription(
            element=cutlass.float32, layout=cutlass.ColumnMajor,
            alignment=4
        )
        C = TensorDescription(
            element=cutlass.float32, layout=cutlass.RowMajor,
            alignment=4
        )

        element_epilogue = cutlass.float32

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, element_epilogue)
        
        swizzling_functor = cutlass.IdentitySwizzle1

        operation = GemmOperationUniversal(
            arch=80, tile_description=tile_description,
            A=A, B=B, C=C,
            epilogue_functor=epilogue_functor, swizzling_functor=swizzling_functor
        )

        self.assertTrue(test_all_gemm(operation, "universal"))


    def test_SM80_Device_Gemm_f32n_f32n_f32t_tensor_op_f32_128x128x32_64x64x32(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 8],
            element_a=cutlass.float32, element_b=cutlass.float32,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add
        )

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 32],
            stages=3, warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        A = TensorDescription(
            element=cutlass.float32, layout=cutlass.ColumnMajor,
            alignment=4
        )
        B = TensorDescription(
            element=cutlass.float32, layout=cutlass.ColumnMajor,
            alignment=4
        )
        C = TensorDescription(
            element=cutlass.float32, layout=cutlass.RowMajor,
            alignment=4
        )

        element_epilogue = cutlass.float32

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, element_epilogue)
        
        swizzling_functor = cutlass.IdentitySwizzle1

        operation = GemmOperationUniversal(
            arch=80, tile_description=tile_description,
            A=A, B=B, C=C, 
            epilogue_functor=epilogue_functor, swizzling_functor=swizzling_functor
        )

        self.assertTrue(test_all_gemm(operation, "universal"))
    
    def test_SM80_Device_Gemm_f32n_f32n_f32t_tensor_op_fast_accurate_f32_64x64x32_32x32x32(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 8],
            element_a=cutlass.float32, element_b=cutlass.float32,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add_fast_f32
        )

        tile_description = TileDescription(
            threadblock_shape=[64, 64, 32],
            stages=3, warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        A = TensorDescription(
            element=cutlass.float32, layout=cutlass.ColumnMajor,
            alignment=4
        )
        B = TensorDescription(
            element=cutlass.float32, layout=cutlass.ColumnMajor,
            alignment=4
        )
        C = TensorDescription(
            element=cutlass.float32, layout=cutlass.RowMajor,
            alignment=4
        )

        element_epilogue = cutlass.float32

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, element_epilogue)
        
        swizzling_functor = cutlass.IdentitySwizzle1

        operation = GemmOperationUniversal(
            arch=80, tile_description=tile_description,
            A=A, B=B, C=C, 
            epilogue_functor=epilogue_functor, swizzling_functor=swizzling_functor
        )

        self.assertTrue(test_all_gemm(operation, "universal"))

if __name__ == '__main__':
    pycutlass.get_memory_pool(2**24, 2**24)
    pycutlass.compiler.load_from_cache()
    unittest.main()
