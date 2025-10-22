import sparse_utils as su
import cutlass
import torch
from cutlass.cute.runtime import from_dlpack
import numpy as np
import pytest


@pytest.mark.L0
def test_sparse_cpu():
    M = 128
    N = 32
    K = 32
    L = 1
    debug = False
    # generate sparse tensor
    a = torch.empty(M, K).random_(-5, 5).to(torch.float16)
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)
    if debug:
        sparse_utils.use_specific_meta_data()
    a_gen_from_cpu = sparse_utils.generate_sparse_4_2_tensor_with_tensor(a, True)
    # print(a_gen_from_cpu)
    # generate compressed tensor and meta data
    a_compressed_cpu = torch.empty(M, K // 2).to(torch.float16)
    meta_data_cpu = torch.empty(M, K // 4 // 8).to(torch.uint32)
    compressor = su.Compressor(M, K, L)
    compressor.compress(a_gen_from_cpu, a_compressed_cpu, meta_data_cpu, True)
    # # test with gemm
    b = torch.empty(N, K).random_(-5, 5).to(torch.float16).cuda()
    d = torch.empty(M, N).zero_().to(torch.float16).cuda()
    b_tensor = from_dlpack(b)
    d_tensor = from_dlpack(d)
    a_compressed_cpu_tensor = from_dlpack(a_compressed_cpu.cuda())
    meta_data_cpu_tensor = from_dlpack(meta_data_cpu.cuda())
    sparse_emulation = su.SparseEmulation(M, N, K, 1)
    sparse_emulation(a_compressed_cpu_tensor, b_tensor, d_tensor, meta_data_cpu_tensor)

    ref = torch.einsum("mk,nk->mn", a_gen_from_cpu.cpu(), b.cpu())
    if debug:
        a_ori = a_gen_from_cpu.cpu().numpy()
        np.savetxt("a.txt", a_ori, fmt="%f")
        a_compressed_cpu_ori = a_compressed_cpu.cpu().numpy()
        np.savetxt("a_compressed_cpu.txt", a_compressed_cpu_ori, fmt="%f")
        meta_data_cpu_ori = meta_data_cpu.cpu().numpy()
        np.savetxt("meta_data_cpu.txt", meta_data_cpu_ori, fmt="%f")
        d_ori = d.cpu().numpy()
        np.savetxt("d.txt", d_ori, fmt="%f")
        ref_ori = ref.cpu().numpy()
        np.savetxt("ref.txt", ref_ori, fmt="%f")
    torch.testing.assert_close(d.cpu(), ref)
    print("cpu d == ref")


@pytest.mark.L0
def test_sparse_cuda():
    M = 128
    N = 32
    K = 32
    L = 1
    debug = False
    sparse_utils = su.SparseUtils(M, K, L, cutlass.Float16)
    if debug:
        sparse_utils.use_specific_meta_data()
    # generate sparse tensor
    a = torch.empty(M, K).random_(-5, 5).to(torch.float16).cuda()
    a_gen_from_cuda = sparse_utils.generate_4_2_sparse_tensor(False)
    # print(a_gen_from_cuda)
    # generate compressed tensor and meta data
    a_compressed_cuda = torch.empty(M, K // 2).to(torch.float16).cuda()
    meta_data_cuda = torch.empty(M, K // 4 // 8).to(torch.uint32).cuda()
    compressor = su.Compressor(M, K, L)
    compressor.compress(a_gen_from_cuda, a_compressed_cuda, meta_data_cuda, False)
    # test with gemm
    b = torch.empty(N, K).random_(-5, 5).to(torch.float16).cuda()
    d = torch.empty(M, N).zero_().to(torch.float16).cuda()
    b_tensor = from_dlpack(b)
    d_tensor = from_dlpack(d)
    a_compressed_cuda_tensor = from_dlpack(a_compressed_cuda)
    meta_data_cuda_tensor = from_dlpack(meta_data_cuda)
    sparse_emulation = su.SparseEmulation(M, N, K, 1)
    sparse_emulation(
        a_compressed_cuda_tensor, b_tensor, d_tensor, meta_data_cuda_tensor
    )

    ref = torch.einsum("mk,nk->mn", a_gen_from_cuda.cpu(), b.cpu())
    if debug:
        a_ori = a_gen_from_cuda.cpu().numpy()
        np.savetxt("a.txt", a_ori, fmt="%f")
        a_compressed_cuda_ori = a_compressed_cuda.cpu().numpy()
        np.savetxt("a_compressed_cuda.txt", a_compressed_cuda_ori, fmt="%f")
        meta_data_cuda_ori = meta_data_cuda.cpu().numpy()
        np.savetxt("meta_data_cuda.txt", meta_data_cuda_ori, fmt="%f")
        d_ori = d.cpu().numpy()
        np.savetxt("d.txt", d_ori, fmt="%f")
        ref_ori = ref.cpu().numpy()
        np.savetxt("ref.txt", ref_ori, fmt="%f")
    torch.testing.assert_close(d.cpu(), ref)
    print("cuda d == ref")


if __name__ == "__main__":
    cutlass.cuda.initialize_cuda_context()
    test_sparse_cpu()
    test_sparse_cuda()
