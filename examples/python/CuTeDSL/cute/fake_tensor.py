import cutlass
import cutlass.cute as cute


"""
Example of using fake tensors in CuTe.

This script demonstrates how to use fake tensors in CuTe to drive compilation without creating actual tensors
from frameworks like PyTorch or TensorFlow.

Run this file directly to see the output type information.
"""


@cute.jit
def print_tensor_type(t: cute.Tensor):
    print(t)


def run():
    from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_tensor

    shape = (3, 4)
    a = make_fake_compact_tensor(cutlass.Float16, (3, 4), stride_order=(1, 0))
    cute.compile(print_tensor_type, a)

    # 32-bit symbolic integer with divisibility 8
    shape = (3, cute.sym_int32(divisibility=8))
    a = make_fake_compact_tensor(cutlass.Float16, shape, stride_order=(1, 0))
    cute.compile(print_tensor_type, a)

    # with static stride
    a = make_fake_tensor(cutlass.Float16, shape, stride=(4, 1))
    cute.compile(print_tensor_type, a)

    # with dynamic stride using 32bit integer
    stride = (cute.sym_int32(divisibility=8), 1)
    a = make_fake_tensor(cutlass.Float16, shape, stride=stride)
    cute.compile(print_tensor_type, a)

    # with dynamic stride using 64bit integer
    stride = (cute.sym_int64(divisibility=8), 1)
    a = make_fake_tensor(cutlass.Float16, shape, stride=stride)
    cute.compile(print_tensor_type, a)


if __name__ == "__main__":
    run()
