# test/unit/conv/device/conv2d_dgrad_implicit_gemm_f32nhwc_f32nhwc_f32nhwc_simt_f32_sm80.cu
import pycutlass
from pycutlass.conv2d_operation import *
from pycutlass import *
from pycutlass.test import *
import unittest

class Conv2dDgradImplicitGemmF32nhwcF32nhwcF32nhwcSimtF32SM80(unittest.TestCase):
    def test_SM80_Device_Conv2d_Fprop_Analytic_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32(self):
        math_inst = MathInstruction(
            instruction_shape=[1, 1, 1],
            element_a=cutlass.float32, element_b=cutlass.float32, 
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.Simt,
            math_operation=MathOperation.multiply_add
        )

        A = TensorDescription(
            element=math_inst.element_a, 
            layout=cutlass.TensorNHWC,
            alignment=4)
        B = TensorDescription(
            element=math_inst.element_b, 
            layout=cutlass.TensorNHWC, 
            alignment=4)
        C = TensorDescription(
            element=cutlass.float32, 
            layout=cutlass.TensorNHWC, 
            alignment=1)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 8], stages=4, 
            warp_count=[4, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.dgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.analytic,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Unity,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.IdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation))
    
    def test_SM80_Device_Conv2d_Dgrad_Optimized_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32(self):
        math_inst = MathInstruction(
            instruction_shape=[1, 1, 1],
            element_a=cutlass.float32, element_b=cutlass.float32,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.Simt,
            math_operation=MathOperation.multiply_add
        )

        A = TensorDescription(
            element=math_inst.element_a, 
            layout=cutlass.TensorNHWC,
            alignment=4)
        B = TensorDescription(
            element=math_inst.element_b, 
            layout=cutlass.TensorNHWC, 
            alignment=4)
        C = TensorDescription(
            element=cutlass.float32,
            layout=cutlass.TensorNHWC, 
            alignment=1)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 8], stages=4, 
            warp_count=[2, 4, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.dgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.optimized,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Unity,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.IdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation))



if __name__ == '__main__':
    pycutlass.get_memory_pool(2**26, 2**26)
    unittest.main()
