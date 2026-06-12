# Reproduce command:
# CUTE_DSL_ARCH=sm_100a pytest test/examples/CuTeDSL/sm_100a/epilogue/test_1d_epilogue_efc.py -v
# 
# Or run directly:
# CUTE_DSL_ARCH=sm_100a python test/examples/CuTeDSL/sm_100a/epilogue/test_1d_epilogue_efc.py

import sys
import os

import cutlass.cute as cute
import cutlass.torch as cutlass_torch
import cutlass.utils.layout as layout
import cuda.bindings.driver as cuda
import torch
import pytest
import cutlass

# To allow running directly without PYTHONPATH configured
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, "..", "..", "..", "..", ".."))

examples_epilogue_path = os.path.join(project_root, "examples", "python", "CuTeDSL", "blackwell", "epilogue")
if examples_epilogue_path not in sys.path:
    sys.path.insert(0, examples_epilogue_path)

from common_dense_gemm_efc import DenseGemmEFC

def my_fused_epilogue(efc_config, Bias, D):
    # Load Accumulator
    acc = efc_config.accum()
    # Load 1D Bias (This is where the compiler breaks if bias layout is not properly supported)
    b = Bias.load()
    # Add them
    res = acc + b
    # Apply GELU
    res = efc_config.gelu(res)
    # Store to D
    D.store(res)

class EFCKernel(DenseGemmEFC):
    def __init__(self):
        super().__init__(
            acc_dtype=cutlass.Float32,
            epi_dtype=cutlass.Float32,
            use_2cta_instrs=True,
            mma_tiler_mn=(128, 128),
            cluster_shape_mn=(2, 1),
            epilogue_function_configuration=my_fused_epilogue,
        )

def test_1d_epilogue_efc_compilation():
    gemm = EFCKernel()
    
    # 1. Define typical shapes
    M, N, K, L = 128, 128, 128, 1
    
    a_pt = cutlass_torch.matrix(L, M, K, False, cutlass.Float16)
    b_pt = cutlass_torch.matrix(L, N, K, False, cutlass.Float16)
    d_pt = cutlass_torch.matrix(L, M, N, True, cutlass.Float16)
    
    # Create the cute tensors for A, B, and D (All valid 3D/2D layouts)
    a_tensor, _ = cutlass_torch.cute_tensor_like(a_pt.cuda(), cutlass.Float16, is_dynamic_layout=True, assumed_align=16)
    b_tensor, _ = cutlass_torch.cute_tensor_like(b_pt.cuda(), cutlass.Float16, is_dynamic_layout=True, assumed_align=16)
    d_tensor, _ = cutlass_torch.cute_tensor_like(d_pt.cuda(), cutlass.Float16, is_dynamic_layout=True, assumed_align=16)
    
    # 2. Create the 1D Bias Vector, but broadcast it natively!
    bias_pt = torch.empty(N, dtype=torch.float16, device='cuda')
    # Use PyTorch broadcast semantics
    bias_pt_2d = bias_pt.unsqueeze(0).unsqueeze(0).expand(L, M, N)
    
    assert bias_pt_2d.stride() == (128, 0, 1) or bias_pt_2d.stride() == (M * N, 0, 1), f"Unexpected strides: {bias_pt_2d.stride()}"
    
    bias_tensor, _ = cutlass_torch.cute_tensor_like(bias_pt_2d, cutlass.Float16, is_dynamic_layout=True, assumed_align=16)
    
    max_active = cutlass.utils.HardwareInfo().get_max_active_clusters(2)
    stream = torch.cuda.current_stream()
    cu_stream = cuda.CUstream(stream.cuda_stream)
    
    # Attempting to compile DenseGemmEFC with 1D bias tensor
    try:
        compiled = gemm.compile(
            a_tensor, b_tensor, max_active, cu_stream,
            bias_tensor, d_tensor # Pass Bias and D to the epilogue signature
        )
    except Exception as e:
        pytest.fail(f"Compiler crash detected when using 1D bias: {str(e)}")

if __name__ == "__main__":
    test_1d_epilogue_efc_compilation()
