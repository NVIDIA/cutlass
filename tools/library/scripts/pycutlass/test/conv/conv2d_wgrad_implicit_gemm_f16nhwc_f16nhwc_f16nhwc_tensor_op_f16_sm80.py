# test/unit/conv/device/conv2d_wgrad_implicit_gemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f16_sm80.cu
import pycutlass
from pycutlass import *
from pycutlass.test import *
import unittest

class Conv2dWgradImplicitGemmF16nhwcF16nhwcF16nhwcTensorOpF16SM80(unittest.TestCase):
    def test_Device_Conv2d_Wgrad_Analytic_ImplicitGemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f16(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float16, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add
        )

        A = TensorDescription(
            element=math_inst.element_a, 
            layout=cutlass.TensorNHWC,
            alignment=8)
        B = TensorDescription(
            element=math_inst.element_b, 
            layout=cutlass.TensorNHWC, 
            alignment=8)
        C = TensorDescription(
            element=cutlass.float16,
            layout=cutlass.TensorNHWC, 
            alignment=8)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 64], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, math_inst.element_accumulator, 
            cutlass.float16
        )

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.wgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.analytic,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.IdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation))
    
    def test_Device_Conv2d_Wgrad_Optimized_ImplicitGemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f16(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float16, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add
        )

        A = TensorDescription(
            element=math_inst.element_a, 
            layout=cutlass.TensorNHWC,
            alignment=8)
        B = TensorDescription(
            element=math_inst.element_b, 
            layout=cutlass.TensorNHWC, 
            alignment=8)
        C = TensorDescription(
            element=cutlass.float16,
            layout=cutlass.TensorNHWC, 
            alignment=8)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 64], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, math_inst.element_accumulator, 
            cutlass.float16
        )

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.wgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.optimized,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.IdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation))

if __name__ == '__main__':
    pycutlass.get_memory_pool(2**26, 2**26)
    unittest.main()
