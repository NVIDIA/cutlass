# PyCUTLASS: CUTLASS Python Interface

PyCUTLASS is a python interface of CUTLASS C++ template library. PyCUTLASS takes user-defined operation descriptions, emits C++ code, and compiles it with `nvcc` or `nvrtc`. It also provides wrappers for user-provide arguments from [numpy](https://numpy.org/), [torch](https://pytorch.org/), and [cupy](https://github.com/cupy/cupy) and encode them to kernel's parameters.

```python
import pycutlass
from pycutlass import *
import torch

pycutlass.get_memory_pool(2**8, 2**32)

math_inst = MathInstruction(
    [1, 1, 1], cutlass.float32, cutlass.float32, cutlass.float32,
    cutlass.OpClass.Simt, MathOperation.multiply_add
)

tile_description = TileDescription(
    [128, 128, 8], 4, [2, 4, 1],
    math_inst, 80, 80
)

A = TensorDescription(
    cutlass.float32, cutlass.RowMajor, 1
)

B = TensorDescription(
    cutlass.float32, cutlass.RowMajor, 1
)

C = TensorDescription(
    cutlass.float32, cutlass.RowMajor, 1
)

operation = GemmOperationUniversal(
    arch=80, tile_description=tile_description,
    A=A, B=B, C=C, element_epilogue=cutlass.float32,
    epilogue_functor=EpilogueFunctor.LinearCombination, 
    swizzling_functor=cutlass.IdentitySwizzle1
)

pycutlass.compiler.add_module([operation,])

problem_size = cutlass.gemm.GemmCoord(512, 256, 128)

tensor_A = torch.ceil(torch.empty(size=(problem_size.m(), problem_size.k()), dtype=torch.float32, device="cuda").uniform_(-8.5, 7.5))
tensor_B = torch.ceil(torch.empty(size=(problem_size.k(), problem_size.n()), dtype=torch.float32, device="cuda").uniform_(-8.5, 7.5))
tensor_C = torch.ceil(torch.empty(size=(problem_size.m(), problem_size.n()), dtype=torch.float32, device="cuda").uniform_(-8.5, 7.5))
tensor_D = torch.empty_like(tensor_C)


alpha = 1.0
beta = 0.0

arguments = GemmArguments(
    operation=operation, problem_size=problem_size,
    A=tensor_A, B=tensor_B, C=tensor_C, D=tensor_D,
    output_op=LinearCombinationFunctorArguments(alpha, beta),
    gemm_mode=cutlass.gemm.Mode.Gemm, split_k_splices=1
)

operation.run(arguments)

arguments.sync()

tensor_D_ref = alpha * tensor_A @ tensor_B + beta * tensor_C

assert torch.equal(tensor_D, tensor_D_ref)
```
PyCUTLASS also provides infrastructures for profiling, compiled artifact management, and pool memory manager 

## Installation

### Using Docker
You can run the PyCUTLASS on NGC pytorch container. 
```shell
docker run --gpus all -it --rm nvcr.io/nvidia/pytorch:22.08-py3
```
PyCUTLASS requires additional dependency Boost C++ library, which can be installed with
```bash
apt-get update
apt-get -y install libboost-all-dev
```



### Environment variables
PyCUTLASSS requires two environment variables:
* `CUTLASS_PATH`: the root directory of CUTLASS
* `CUDA_INSTALL_PATH`: the directory where cuda toolkit is installed

After setting these two environment variables, PyCUTLASS can be installed with 
```shell
cd $CUTLASS_PATH/tools/library/scripts/pycutlass && bash build.sh
```

## Examples
Examples can be found in `$CUTLASS_PATH/examples/40_cutlass_py`

## Test
The test cases are listed in `$CUTLASS_PATH//tools/library/scripts/pycutlass/test`. The unit test can be run with
```shell
cd $CUTLASS_PATH/tools/library/scripts/pycutlass/test/unit && python test_sm80.py
```


## Troubleshooting

### Issue 1: permission denied
Building PyCUTLASS requires installing dependencies to python. So conda could an option if you don't have permission.

### Issue 2: rmm: module not found
PyCUTLASS manages the device memory with [RMM](https://github.com/rapidsai/rmm). Our `build.sh` automatically pull the [rmm branch-22.08](https://github.com/rapidsai/rmm/tree/branch-22.08) from github and build it from source. The rmm is allocated at `$CUTLASS_PATH/tools/library/scripts/pycutlass/rmm`. It requires `cmake > 3.20.1`. If the build fails, it can be manually fixed with the following steps:
```shell
cd $CUTLASS_PATH/tools/library/scripts/pycutlass/rmm && ./build.sh librmm rmm

cd $CUTLASS_PATH/tools/library/scripts/pycutlass/rmm/python
python setup.py build_ext --inplace
python setup.py install
```
To test whether rmm is successfully installed, try `import rmm`. For other issues related to rmm, please check https://github.com/rapidsai/rmm/issues. 
