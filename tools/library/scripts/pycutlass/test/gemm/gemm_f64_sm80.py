import pycutlass
from pycutlass import *
from pycutlass.test import *
import unittest

from pycutlass.test.gemm_testbed import test_all_gemm

class GemmF64TensorOpSm80(unittest.TestCase):
    def test_SM80_Device_Gemm_f64n_f64t_f64t_tensor_op_f64_32x32x16_16x16x16(self):
        math_inst = MathInstruction(
            instruction_shape=[8, 8, 4],
            element_a=cutlass.float64, element_b=cutlass.float64,
            element_accumulator=cutlass.float64, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add
        )

        tile_description = TileDescription(
            threadblock_shape=[32, 32, 16],
            stages=4, warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        # alignment 1 restricted for double
        A = TensorDescription(
            element=cutlass.float64, layout=cutlass.ColumnMajor,
            alignment=1
        )
        B = TensorDescription(
            element=cutlass.float64, layout=cutlass.RowMajor,
            alignment=1
        )
        C = TensorDescription(
            element=cutlass.float64, layout=cutlass.RowMajor,
            alignment=1
        )

        element_epilogue = cutlass.float64

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
    
    def test_SM80_Device_Gemm_f64t_f64n_f64t_tensor_op_f64_64x64x16_32x32x16(self):
        math_inst = MathInstruction(
            instruction_shape=[8, 8, 4],
            element_a=cutlass.float64, element_b=cutlass.float64,
            element_accumulator=cutlass.float64, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add
        )

        tile_description = TileDescription(
            threadblock_shape=[64, 64, 16],
            stages=4, warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        # alignment 1 restricted for double
        A = TensorDescription(
            element=cutlass.float64, layout=cutlass.RowMajor,
            alignment=1
        )
        B = TensorDescription(
            element=cutlass.float64, layout=cutlass.ColumnMajor,
            alignment=1
        )
        C = TensorDescription(
            element=cutlass.float64, layout=cutlass.RowMajor,
            alignment=1
        )

        element_epilogue = cutlass.float64

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
    unittest.main()
