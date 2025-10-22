import numpy as np
import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
import torch


@cute.jit
def print_tensor_dlpack(src: cute.Tensor):
    print(src)
    cute.print_tensor(src)


# Sparse emulation
class SparseEmulation:
    def __init__(self, M: int, N: int, K: int, L: int):
        self.M = M
        self.N = N
        self.K = K
        self.L = L

    @cute.jit
    def __call__(self, a: cute.Tensor, b: cute.Tensor, d: cute.Tensor, e: cute.Tensor):
        """Sparse emulation"""
        num_threads = 128
        grid = (cute.ceil_div(self.M, num_threads), 1, 1)
        block = (num_threads, 1, 1)
        self.kernel(a, b, d, e).launch(grid=grid, block=block)
        return

    @cute.kernel
    def kernel(self, a: cute.Tensor, b: cute.Tensor, d: cute.Tensor, e: cute.Tensor):
        """CUDA kernel to emulate sparse tensor core"""
        tidx, tidy, tidz = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()

        row_idx = tidx + bidx * self.M
        meta_idx = self.K // 4 // 8
        if row_idx < self.M:
            # each thread process 1 row
            for col in range(self.N):
                # each meta_idx stands for 32 elements
                for e_idx in range(meta_idx):
                    meta_val = e[(row_idx, e_idx)]
                    for k in range(8):
                        # each k stands for 4 elements
                        meta_row = (meta_val >> (k * 4)) & 0xF
                        idx0 = meta_row & 0x3
                        idx1 = (meta_row >> 2) & 0x3
                        # calculate the idx in b tensor which has value in A tensor
                        km = e_idx * 16 + k * 2
                        km_1 = km + 1
                        kn = e_idx * 32 + k * 4 + idx0
                        kn_1 = e_idx * 32 + k * 4 + idx1
                        d[row_idx, col] += a[row_idx, km] * b[col, kn]
                        d[row_idx, col] += a[row_idx, km_1] * b[col, kn_1]
        return


# Compressor
# compress a sparse tensor to a dense tensor && generate metadata
class Compressor:
    def __init__(self, M: int, K: int, L: int):
        self.M = M
        self.K = K
        self.L = L
        self.pos_map = {
            0x4: [0, 1],
            0x8: [0, 2],
            0xC: [0, 3],
            0x9: [1, 2],
            0xD: [1, 3],
            0xE: [2, 3],
        }

    @cute.jit
    def _init__(self, a: cute.Tensor):
        self.__init__(a.shape[0], a.shape[1], a.shape[2])

    def compress(self, a, a_compressed, meta, run_on_cpu: bool):
        if run_on_cpu:
            if a.device.type != "cpu":
                raise ValueError("a must be on cpu")
            return self.__compress_on_cpu(a, a_compressed, meta)
        else:
            if a.device.type != "cuda":
                raise ValueError("a must be on cuda")
            return self.__compress_on_cuda(a, a_compressed, meta)

    def __compress_on_cpu(self, a, a_compressed, meta):
        """
        compress the tensor on cpu
        # Convert to 4-bit metadata value
        # The metadata value represents which 2 elements are non-zero
        # 0x4: [1,1,0,0] - first two elements are non-zero
        # 0x8: [1,0,1,0] - first and third elements are non-zero
        # 0xC: [1,0,0,1] - first and fourth elements are non-zero
        # 0x9: [0,1,1,0] - second and third elements are non-zero
        # 0xD: [0,1,0,1] - second and fourth elements are non-zero
        # 0xE: [0,0,1,1] - third and fourth elements are non-zero
        # special case:
        # [0,0,0,0]  == [0,0,1,1]
        # [1,0,0,0]  == [1,0,0,1]
        # [0,1,0,0]  == [0,1,0,1]
        # [0,0,1,0]  == [0,0,1,1]
        # [0,0,0,1]  == [0,0,1,1]
        """
        M, K = a.shape
        assert a_compressed.shape == (
            M,
            K // 2,
        ), f"Expected a_compressed shape {(M, K // 2)}, got {a_compressed.shape}"
        assert meta.shape == (
            M,
            K // 4 // 8,
        ), f"Expected meta shape {(M, K // 4 // 8)}, got {meta.shape}"
        for m in range(M):
            k_meta = 0
            for k in range(0, K, 4):
                chunk = a[m, k : k + 4]

                non_zero_indices = torch.nonzero(chunk).squeeze()
                meta_val = 0xE
                if torch.equal(non_zero_indices, torch.tensor([0, 1])):
                    meta_val = 0x4
                elif torch.equal(non_zero_indices, torch.tensor([0, 2])):
                    meta_val = 0x8
                elif torch.equal(non_zero_indices, torch.tensor([0, 3])) or torch.equal(
                    non_zero_indices, torch.tensor(0)
                ):
                    meta_val = 0xC
                elif torch.equal(non_zero_indices, torch.tensor([1, 2])):
                    meta_val = 0x9
                elif torch.equal(non_zero_indices, torch.tensor([1, 3])) or torch.equal(
                    non_zero_indices, torch.tensor(1)
                ):
                    meta_val = 0xD
                elif torch.equal(non_zero_indices, torch.tensor([2, 3])) or torch.equal(
                    non_zero_indices, torch.tensor(2)
                ):
                    meta_val = 0xE
                elif torch.equal(non_zero_indices, torch.tensor([])) or torch.equal(
                    non_zero_indices, torch.tensor(3)
                ):
                    meta_val = 0xE
                else:
                    raise ValueError(f"Invalid non-zero pattern: {non_zero_indices}")
                meta_idx = k // 4 // 8
                meta_bit_pos = (k // 4) % 8
                if k_meta == meta_idx:
                    k_meta = meta_idx + 1
                    meta[m, meta_idx] = 0
                meta[m, meta_idx] |= meta_val << (meta_bit_pos * 4)
                compressed_idx = k // 2
                index = self.pos_map[meta_val]
                a_compressed[m, compressed_idx] = chunk[index[0]]
                a_compressed[m, compressed_idx + 1] = chunk[index[1]]

    def __compress_on_cuda(self, a, a_compressed, meta):
        """
        compress the tensor on cuda
        """
        a_tensor = from_dlpack(a)
        a_compressed_tensor = from_dlpack(a_compressed)
        meta_tensor = from_dlpack(meta)
        self.compress_on_cuda_impl(a_tensor, a_compressed_tensor, meta_tensor)
        return

    @cute.jit
    def compress_on_cuda_impl(
        self, a: cute.Tensor, a_compressed: cute.Tensor, meta: cute.Tensor
    ):
        """Compress the input tensor using the metadata"""
        num_threads = 128
        grid = (cute.ceil_div(self.M, num_threads), 1, 1)
        block = (num_threads, 1, 1)
        self.compressor_impl(a, a_compressed, meta).launch(grid=grid, block=block)

    @cute.kernel
    def compressor_impl(
        self, a: cute.Tensor, a_compressed: cute.Tensor, meta: cute.Tensor
    ):
        """CUDA kernel to compress the tensor"""
        tidx, tidy, tidz = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()
        m = a.shape[0]
        k = a.shape[1]

        # each thread process 1 row
        row_idx = tidx + bidx * self.M
        meta_idx = self.K // 4 // 8
        if row_idx < self.M:
            # each meta_idx stands for 32 elements
            for i in range(meta_idx):
                meta[row_idx, i] = 0
                # each k stands for 4 elements
                for j in range(8):
                    val = a[row_idx, i * 32 + j * 4]
                    val_1 = a[row_idx, i * 32 + j * 4 + 1]
                    val_2 = a[row_idx, i * 32 + j * 4 + 2]
                    val_3 = a[row_idx, i * 32 + j * 4 + 3]
                    value_idx = 0
                    value_idx_1 = 0
                    value_idx_2 = 0
                    value_idx_3 = 0
                    pos0 = 0
                    pos1 = 0
                    if val != 0:
                        value_idx = 1
                        pos0 = 0
                    if val_1 != 0:
                        value_idx_1 = 1
                    if val_2 != 0:
                        value_idx_2 = 1
                    if val_3 != 0:
                        value_idx_3 = 1
                    pos = [value_idx, value_idx_1, value_idx_2, value_idx_3]
                    tmp = 0
                    if pos == [0, 0, 0, 0]:
                        tmp = 0xE
                        pos0 = 2
                        pos1 = 3
                    elif pos == [1, 0, 0, 0]:
                        tmp = 0xC
                        pos0 = 0
                        pos1 = 3
                    elif pos == [0, 1, 0, 0]:
                        tmp = 0xD
                        pos0 = 1
                        pos1 = 3
                    elif pos == [0, 0, 1, 0]:
                        tmp = 0xE
                        pos0 = 2
                        pos1 = 3
                    elif pos == [0, 0, 0, 1]:
                        tmp = 0xE
                        pos0 = 2
                        pos1 = 3
                    elif pos == [1, 1, 0, 0]:
                        tmp = 0x4
                        pos0 = 0
                        pos1 = 1
                    elif pos == [1, 0, 1, 0]:
                        tmp = 0x8
                        pos0 = 0
                        pos1 = 2
                    elif pos == [1, 0, 0, 1]:
                        tmp = 0xC
                        pos0 = 0
                        pos1 = 3
                    elif pos == [0, 1, 1, 0]:
                        tmp = 0x9
                        pos0 = 1
                        pos1 = 2
                    elif pos == [0, 1, 0, 1]:
                        tmp = 0xD
                        pos0 = 1
                        pos1 = 3
                    elif pos == [0, 0, 1, 1]:
                        tmp = 0xE
                        pos0 = 2
                        pos1 = 3
                    # cute.printf(row_idx, cutlass.Float32(val), cutlass.Float32(val_1), cutlass.Float32(val_2), cutlass.Float32(val_3), tmp)
                    meta[row_idx, i] |= tmp << (j * 4)

                    a_compressed[row_idx, i * 16 + j * 2] = a[
                        row_idx, i * 32 + j * 4 + pos0
                    ]
                    a_compressed[row_idx, i * 16 + j * 2 + 1] = a[
                        row_idx, i * 32 + j * 4 + pos1
                    ]

        return


# SparseUtils is used to generate sparse tensor
# format torch.Tensor
class SparseUtils:
    #!brief: SparseUtils is used to generate sparse tensor
    #!param: M: int, K: int, L: int, dtype: cutlass.DataType
    def __init__(self, M: int, K: int, L: int, dtype):
        self.M = M
        self.K = K
        self.L = L
        self.dtype = dtype
        self.meta_data = self._generate_meta_data_4_2()
        self._use_specific_meta_data = False

    #!brief: cast cutlass.DataType to torch.Tensor
    def _get_type(self):
        if self.dtype == cutlass.Float16:
            return torch.float16
        elif self.dtype == cutlass.Float32:
            return torch.float32
        elif self.dtype == cutlass.Int8:
            return torch.int8
        else:
            raise ValueError(f"Unsupported dtype: {self.dtype}")

    def _generate_meta_data_4_2(self):
        # metadata for 4:2 sparse will in range( 4,8,9,c,d,e)
        # represents
        # 0: [1,1,0,0] no zero pos 00,01 -> 0100 = 4
        # 1: [1,0,1,0] no zero pos 00,10 -> 1000 = 8
        # 2: [1,0,0,1] no zero pos 00,11 -> 1100 = c
        # 3: [0,1,1,0] no zero pos 01,10 -> 1001 = 9
        # 4: [0,1,0,1] no zero pos 01,11 -> 1101 = d
        # 5: [0,0,1,1] no zero pos 10,11 -> 1011 = e
        meta_value = [0x4, 0x8, 0x9, 0xC, 0xD, 0xE]
        # 4:2 sparse, so each chunk is 4 elements, map to 4 bits
        K_NumChunk = self.K // 4
        meta_data = np.random.choice(
            meta_value, size=(self.M, K_NumChunk), replace=True
        )
        meta_data = torch.from_numpy(
            np.array(meta_data).astype(np.uint8).reshape(self.M, K_NumChunk)
        )
        return meta_data

    #!brief: pack meta data
    def _pack_meta_data(self):
        tmp = []
        K_NumChunk = self.K // 4
        for i in range(self.M):
            for j in range(K_NumChunk // 8):
                v = 0
                for k in range(8):
                    vv = int(self.meta_data[i, j * 8 + k] & 0xF)
                    tt = vv << (k * 4)
                    v = v | tt
                tmp.append(v)
        # debug print
        # print([hex(vt) for vt in tmp])
        result = torch.from_numpy(
            np.array(tmp).astype(np.uint32).reshape(self.M, K_NumChunk // 8)
        )
        return result

    #!brief: use specific meta data
    def use_specific_meta_data(self, meta_data: torch.Tensor = None):
        if meta_data is not None:
            self.meta_data = meta_data
        self._use_specific_meta_data = True

    #!brief: generate sparse tensor with tensor
    #!param: a: torch.Tensor
    #!param: run_on_cpu: bool
    #!return: torch.Tensor
    def generate_sparse_4_2_tensor_with_tensor(self, a, run_on_cpu):
        if run_on_cpu:
            if a.device.type != "cpu":
                raise ValueError("a must be on cpu")
            return self.__generate_sparse_tensor_cpu(a)
        else:
            if a.device.type != "cuda":
                raise ValueError("a must be on cuda")
            a_tensor = from_dlpack(a)
            packed_meta_data = self._pack_meta_data()
            meta_tensor = from_dlpack(packed_meta_data.cuda())
            self.__generate_sparse_tensor_cuda(a_tensor, meta_tensor)
            return a

    #!brief: generate sparse tensor
    #!param: run_on_cpu: bool
    #!return: torch.Tensor
    def generate_4_2_sparse_tensor(self, run_on_cpu):
        dtype = self._get_type()
        a = torch.empty(self.M, self.K).random_(-5, 5).to(dtype)
        if run_on_cpu:
            return self.generate_sparse_4_2_tensor_with_tensor(a, run_on_cpu)
        else:
            return self.generate_sparse_4_2_tensor_with_tensor(a.cuda(), run_on_cpu)

    #!brief: generate sparse tensor on cpu
    #!param: a: torch.Tensor
    #!return: torch.Tensor
    def __generate_sparse_tensor_cpu(self, a):
        if not self._use_specific_meta_data:
            for m in range(self.M):
                for k in range(0, self.K, 4):
                    # random choose 2 zero positions
                    zero_indices = torch.randperm(4)[:2]
                    a[m, k + zero_indices[0]] = 0
                    a[m, k + zero_indices[1]] = 0
            return a
        else:
            # use specific meta data
            tensor_mask = []
            for i in range(self.M):
                for j in range(self.K // 4):
                    meta_val = self.meta_data[i, j]
                    tmp = []
                    if meta_val == 0x4:
                        tmp = [1, 1, 0, 0]
                    elif meta_val == 0x8:
                        tmp = [1, 0, 1, 0]
                    elif meta_val == 0xC:
                        tmp = [1, 0, 0, 1]
                    elif meta_val == 0x9:
                        tmp = [0, 1, 1, 0]
                    elif meta_val == 0xD:
                        tmp = [0, 1, 0, 1]
                    elif meta_val == 0xE:
                        tmp = [0, 0, 1, 1]
                    tensor_mask.extend(tmp)
            a = torch.reshape(a, (-1,))
            mask = torch.tensor(tensor_mask)
            a = a * mask
            a = torch.reshape(a, (self.M, self.K))
            return a

    @cute.jit
    def __generate_sparse_tensor_cuda(self, a: cute.Tensor, meta: cute.Tensor):
        """Generate a sparse tensor from a dense tensor using metadata"""
        assert a.shape[0] == self.M and a.shape[1] == self.K
        assert meta.shape[0] == self.M and meta.shape[1] == self.K // 4 // 8
        num_threads = 128
        grid = (cute.ceil_div(self.M, num_threads), 1, 1)
        block = (num_threads, 1, 1)
        self.kernel(a, meta).launch(grid=grid, block=block)

    @cute.kernel
    def kernel(self, a: cute.Tensor, meta: cute.Tensor):
        """Apply sparsity mask to input tensor using metadata"""
        tidx, tidy, tidz = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()

        # each thread process 1 ro
        row_idx = tidx + bidx * self.M
        meta_idx = self.K // 4 // 8
        # each thread process 1 row
        if row_idx < self.M:
            # iterate over each chunk(32 elements)
            for i in range(meta_idx):
                meta_val = meta[(row_idx, i)]
                # iterate over each sparse pattern(4 elements)
                for j in range(8):
                    meta_row = (meta_val >> (j * 4)) & 0xF
                    idx0 = meta_row & 0x3
                    idx1 = (meta_row >> 2) & 0x3
                    r_id0 = 0
                    r_id1 = 0
                    # r_id is the idx that value is 0
                    if idx0 >= 2 and idx1 >= 2:
                        r_id0 = 0
                        r_id1 = 1
                    elif idx0 <= 1 and idx1 <= 1:
                        r_id0 = 2
                        r_id1 = 3
                    else:
                        r_id0 = idx0 ^ 0b1
                        r_id1 = idx1 ^ 0b1
                    row_id0 = r_id0 + i * 32 + j * 4
                    row_id1 = r_id1 + i * 32 + j * 4
                    a[row_idx, row_id0] = self.dtype(0.0)
                    a[row_idx, row_id1] = self.dtype(0.0)
        return
