# test/unit/conv/device/conv2d_fprop_fixed_channels_f16nhwc_f16nhwc_f16nhwc_tensor_op_f32_sm80.cu
import pycutlass
from pycutlass.test import *
import unittest

def conv2d_fixed_channel_problemsizes(channels):
    problem_sizes = [
        cutlass.conv.Conv2dProblemSize(
            cutlass.Tensor4DCoord(1, 8, 8, channels),
            cutlass.Tensor4DCoord(16, 3, 3, channels),
            cutlass.Tensor4DCoord(1, 1, 1, 1),
            cutlass.MatrixCoord(2, 2),
            cutlass.MatrixCoord(1, 1),
            cutlass.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass.conv.Conv2dProblemSize(
            cutlass.Tensor4DCoord(1, 224, 224, channels),
            cutlass.Tensor4DCoord(32, 7, 7, channels),
            cutlass.Tensor4DCoord(1, 1, 1, 1),
            cutlass.MatrixCoord(1, 1),
            cutlass.MatrixCoord(1, 1),
            cutlass.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass.conv.Conv2dProblemSize(
            cutlass.Tensor4DCoord(1, 224, 224, channels),
            cutlass.Tensor4DCoord(64, 7, 7, channels),
            cutlass.Tensor4DCoord(1, 1, 1, 1),
            cutlass.MatrixCoord(2, 2),
            cutlass.MatrixCoord(1, 1),
            cutlass.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass.conv.Conv2dProblemSize(
            cutlass.Tensor4DCoord(1, 224, 224, channels),
            cutlass.Tensor4DCoord(64, 5, 5, channels),
            cutlass.Tensor4DCoord(1, 1, 1, 1),
            cutlass.MatrixCoord(1, 1),
            cutlass.MatrixCoord(1, 1),
            cutlass.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass.conv.Conv2dProblemSize(
            cutlass.Tensor4DCoord(1, 224, 224, channels),
            cutlass.Tensor4DCoord(64, 5, 5, channels),
            cutlass.Tensor4DCoord(1, 1, 1, 1),
            cutlass.MatrixCoord(2, 2),
            cutlass.MatrixCoord(1, 1),
            cutlass.conv.Mode.cross_correlation,
            1, 1
        ),
    ]

    return problem_sizes

class Conv2dFpropFixedChannelsF16NHWCF16NHWCF16HNWCTensorOpF32SM80(unittest.TestCase):
    def test_SM80_Device_Conv2d_Fprop_Fixed_Channels_ImplicitGemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f32_channels_8(self):
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
            element=cutlass.float16,
            layout=cutlass.TensorNHWC, 
            alignment=8)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 64], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.fprop, iterator_algorithm=cutlass.conv.IteratorAlgorithm.fixed_channels,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.IdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation, conv2d_fixed_channel_problemsizes(8)))
    
    def test_SM80_Device_Conv2d_Fprop_Fixed_Channels_ImplicitGemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f32_channels_4(self):
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
            element=cutlass.float16,
            layout=cutlass.TensorNHWC, 
            alignment=8)

        tile_description = TileDescription(
            threadblock_shape=[128, 128, 64], stages=3, 
            warp_count=[2, 2, 1],
            math_instruction=math_inst
        )

        epilogue_functor = LinearCombination(
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.fprop, iterator_algorithm=cutlass.conv.IteratorAlgorithm.fixed_channels,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.IdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation, conv2d_fixed_channel_problemsizes(4)))
    
    def test_SM80_Device_Conv2d_Fprop_Fixed_Channels_ImplicitGemm_f16nhwc_f16nhwc_f16nhwc_tensor_op_f32_channels_2(self):
        math_inst = MathInstruction(
            instruction_shape=[16, 8, 16],
            element_a=cutlass.float16, element_b=cutlass.float16,
            element_accumulator=cutlass.float32, opcode_class=cutlass.OpClass.TensorOp,
            math_operation=MathOperation.multiply_add
        )

        A = TensorDescription(
            element=math_inst.element_a, 
            layout=cutlass.TensorNHWC,
            alignment=2)
        B = TensorDescription(
            element=math_inst.element_b, 
            layout=cutlass.TensorNHWC, 
            alignment=2)
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
            C.element, C.alignment, 
            math_inst.element_accumulator, cutlass.float32)

        operation = Conv2dOperation(
            conv_kind=cutlass.conv.Operator.fprop, iterator_algorithm=cutlass.conv.IteratorAlgorithm.fixed_channels,
            arch=80, tile_description=tile_description, A=A, B=B, C=C, 
            stride_support=StrideSupport.Strided,
            epilogue_functor=epilogue_functor,
            swizzling_functor=cutlass.IdentitySwizzle1
        )
        
        self.assertTrue(test_all_conv2d(operation, conv2d_fixed_channel_problemsizes(2)))


if __name__ == '__main__':
    pycutlass.get_memory_pool(2**26, 2**26)
    unittest.main()
