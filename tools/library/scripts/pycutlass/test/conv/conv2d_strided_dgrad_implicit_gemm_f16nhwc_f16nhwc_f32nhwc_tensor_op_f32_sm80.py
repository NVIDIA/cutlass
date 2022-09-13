# test/unit/conv/device/conv2d_strided_dgrad_implicit_gemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_sm80.cu
import pycutlass
from pycutlass import *
from pycutlass.test import *
import unittest

class Conv2dStridedDgradImplicitGemmF16NHWCF16NHWCF32NHWCTensorOpF32SM80(unittest.TestCase):
    def test_SM80_Device_Conv2d_Strided_Dgrad_Analytic_ImplicitGemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_128x128_32x3_64x64x32(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
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
            element=cutlass.float32,
            layout=cutlass.TensorNHWC, 
            alignment=4)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 32], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.dgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.analytic,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.StridedDgradIdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation))
    
    def test_SM80_Device_Conv2d_Strided_Dgrad_Analytic_ImplicitGemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_128x256_64x3_64x64x64(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
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
            element=cutlass.float32,
            layout=cutlass.TensorNHWC, 
            alignment=4)

        tile_description = TileDescription(
            threadblock_shape=[128, 256, 64], stages=3, 
            warp_count=[2, 4, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.dgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.analytic,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.StridedDgradIdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation))
    
    def test_SM80_Device_Conv2d_Strided_Dgrad_Analytic_ImplicitGemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_align4_128x128_32x3_64x64x32(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
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
            alignment=4)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 32], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.dgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.analytic,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.StridedDgradIdentitySwizzle1
        )
        
        problem_sizes = [
            cutlass.conv.Conv2dProblemSize(
                cutlass.Tensor4DCoord(1, 4, 4, 12),
                cutlass.Tensor4DCoord(8, 3, 3, 12),
                cutlass.Tensor4DCoord(0, 0, 0, 0),
                cutlass.MatrixCoord(3, 3),
                cutlass.MatrixCoord(1, 1),
                cutlass.conv.Mode.cross_correlation,
                1, 1
            ),
        ]
        
        self.assertTrue(test_all_conv2d(operation, problem_sizes))
    
    def test_SM80_Device_Conv2d_Strided_Dgrad_Optimized_ImplicitGemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_128x128_32x3_64x64x32(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
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
            element=cutlass.float32,
            layout=cutlass.TensorNHWC, 
            alignment=4)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 32], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.dgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.optimized,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.StridedDgradIdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation))
    
    def test_SM80_Device_Conv2d_Strided_Dgrad_Optimized_ImplicitGemm_f16nhwc_f16nhwc_f32nhwc_tensor_op_f32_128x128_32x3_64x64x32_align4(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
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
            alignment=4)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 32], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.dgrad, iterator_algorithm=cutlass.conv.IteratorAlgorithm.optimized,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.StridedDgradIdentitySwizzle1
        )
        
        problem_sizes = [
            cutlass.conv.Conv2dProblemSize(
                cutlass.Tensor4DCoord(1, 56, 56, 12),
                cutlass.Tensor4DCoord(8, 1, 1, 12),
                cutlass.Tensor4DCoord(0, 0, 0, 0),
                cutlass.MatrixCoord(2, 2),
                cutlass.MatrixCoord(1, 1),
                cutlass.conv.Mode.cross_correlation,
                1, 1
            ),
            cutlass.conv.Conv2dProblemSize(
                cutlass.Tensor4DCoord(1, 55, 55, 12),
                cutlass.Tensor4DCoord(8, 1, 1, 12),
                cutlass.Tensor4DCoord(0, 0, 0, 0),
                cutlass.MatrixCoord(2, 2),
                cutlass.MatrixCoord(1, 1),
                cutlass.conv.Mode.cross_correlation,
                1, 1
            ),
        ]
        
        self.assertTrue(test_all_conv2d(operation, problem_sizes))



if __name__ == '__main__':
    pycutlass.get_memory_pool(2**26, 2**26)
    unittest.main()
