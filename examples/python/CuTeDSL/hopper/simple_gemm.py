import torch
import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils


def make_fp16_rowmajor(rows: int, cols: int):
    t = torch.empty_strided((rows, cols), (cols, 1), device="cuda", dtype=torch.float16)
    t.uniform_(-1.0, 1.0)
    t32 = t.float()
    ct = from_dlpack(t, assumed_align=16)
    ct.element_type = cutlass.Float16
    ct = ct.mark_layout_dynamic(leading_dim=1)  # row-major
    return t, t32, ct


def pick_thr_mn(T: int, epi_m: int, epi_n: int):
    for thr_n in (32, 16, 8, 4, 2, 1):
        if T % thr_n:
            continue
        thr_m = T // thr_n
        if epi_m % thr_m == 0 and epi_n % thr_n == 0:
            return thr_m, thr_n
    for thr_n in range(1, T + 1):
        if T % thr_n:
            continue
        thr_m = T // thr_n
        if epi_m % thr_m == 0 and epi_n % thr_n == 0:
            return thr_m, thr_n
    return 1, T


class Gemm128_RouteB_UltraMin:
    def __init__(self):
        self.TM = 128
        self.TN = 128
        self.THREADS = 128
        self.ALIGN = 1024
        self.gmem_bits = 16
        self.store_bits = 16
        self.acc_dtype = cutlass.Float32
        self.ab_stage = 1
        self.epi_stage = 1

        # set in setup
        self.a_dtype = None
        self.b_dtype = None
        self.c_dtype = None
        self.a_layout = None
        self.b_layout = None
        self.c_layout = None

        self.tiled_mma = None
        self.tile_mnk = None
        self.a_smem_layout = None
        self.b_smem_layout = None

        # epilogue: keep on self (avoid passing tuple as kernel arg)
        self.epi_tile = None
        self.epi_layout_tv = None
        self.epi_tiler_mn = None

        self.shared = None

    def _setup(self, A: cute.Tensor, B: cute.Tensor, C: cute.Tensor):
        self.a_dtype = A.element_type
        self.b_dtype = B.element_type
        self.c_dtype = C.element_type

        self.a_layout = utils.LayoutEnum.from_tensor(A)
        self.b_layout = utils.LayoutEnum.from_tensor(B)
        self.c_layout = utils.LayoutEnum.from_tensor(C)

        self.tiled_mma = sm90_utils.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_layout.sm90_mma_major_mode(),
            self.b_layout.sm90_mma_major_mode(),
            self.acc_dtype,
            atom_layout_mnk=(1, 1, 1),     # 1 warp-group
            tiler_mn=(64, self.TN),
        )

        mma_k = cute.size(self.tiled_mma.shape_mnk, mode=[2])
        self.tile_mnk = (self.TM, self.TN, mma_k * 4)

        self.a_smem_layout = sm90_utils.make_smem_layout_a(
            self.a_layout, self.tile_mnk, self.a_dtype, self.ab_stage
        )
        self.b_smem_layout = sm90_utils.make_smem_layout_b(
            self.b_layout, self.tile_mnk, self.b_dtype, self.ab_stage
        )

        # epi tile + TV layout for sC->gmem (store on self)
        self.epi_tile = sm90_utils.compute_tile_shape_or_override(
            self.tile_mnk, self.c_dtype, is_cooperative=False
        )
        epi_m, epi_n = self.epi_tile[0], self.epi_tile[1]

        thr_m, thr_n = pick_thr_mn(self.THREADS, epi_m, epi_n)
        val_m, val_n = epi_m // thr_m, epi_n // thr_n
        thr_layout = cute.make_layout((thr_m, thr_n), stride=(thr_n, 1))
        val_layout = cute.make_layout((val_m, val_n), stride=(val_n, 1))
        self.epi_tiler_mn, self.epi_layout_tv = cute.make_layout_tv(thr_layout, val_layout)

        c_smem_elems = epi_m * epi_n * self.epi_stage

        @cute.struct
        class Shared:
            sA: cute.struct.Align[
                cute.struct.MemRange[self.a_dtype, cute.cosize(self.a_smem_layout)],
                self.ALIGN,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[self.b_dtype, cute.cosize(self.b_smem_layout)],
                self.ALIGN,
            ]
            sC: cute.struct.Align[
                cute.struct.MemRange[self.c_dtype, c_smem_elems],
                self.ALIGN,
            ]

        self.shared = Shared

    @cute.jit
    def __call__(self, A: cute.Tensor, B: cute.Tensor, C: cute.Tensor):
        self._setup(A, B, C)

        M = cute.size(C, mode=[0])
        N = cute.size(C, mode=[1])
        grid = (M // self.TM, N // self.TN, 1)

        self.kernel(
            A, B, C,
            self.tiled_mma,
            self.a_smem_layout,
            self.b_smem_layout,
        ).launch(
            grid=grid,
            block=[self.THREADS, 1, 1],
            cluster=(1, 1, 1),
        )

    @cute.kernel
    def kernel(
        self,
        A_mk: cute.Tensor,
        B_nk: cute.Tensor,
        C_mn: cute.Tensor,
        tiled_mma: cute.TiledMma,
        a_smem_layout: cute.ComposedLayout,
        b_smem_layout: cute.ComposedLayout,
    ):
        bidx, bidy, _ = cute.arch.block_idx()
        tidx = cute.arch.thread_idx()[0]

        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(self.shared)

        sA = storage.sA.get_tensor(a_smem_layout.outer, swizzle=a_smem_layout.inner)
        sB = storage.sB.get_tensor(b_smem_layout.outer, swizzle=b_smem_layout.inner)

        epi_m, epi_n = self.epi_tile[0], self.epi_tile[1]
        epi_stage = self.epi_stage

        # plain sC with stage dim
        stride_m_major = (1, epi_m, epi_m * epi_n)
        stride_n_major = (epi_n, 1, epi_m * epi_n)
        is_m_major = cutlass.const_expr(self.c_layout.is_m_major_c())
        c_stride = stride_m_major if is_m_major else stride_n_major
        sC = storage.sC.get_tensor(cute.make_layout((epi_m, epi_n, epi_stage), stride=c_stride))

        tile_coord = (bidx, bidy, None)
        gA = cute.local_tile(A_mk, self.tile_mnk, tile_coord, proj=(1, None, 1))
        gB = cute.local_tile(B_nk, self.tile_mnk, tile_coord, proj=(None, 1, 1))
        gC = cute.local_tile(C_mn, self.tile_mnk, tile_coord, proj=(1, 1, None))  # 2D tile

        thr_mma = tiled_mma.get_slice(0)
        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)
        tCrA = tiled_mma.make_fragment_A(tCsA)
        tCrB = tiled_mma.make_fragment_B(tCsB)

        tCgC_dummy = thr_mma.partition_C(gC)
        acc = cute.make_rmem_tensor(tCgC_dummy.shape, self.acc_dtype)

        # -------- GMEM->SMEM (TiledCopy) --------
        op = cute.nvgpu.CopyUniversalOp()
        ca = cute.make_copy_atom(op, self.a_dtype, num_bits_per_copy=self.gmem_bits)
        cb = cute.make_copy_atom(op, self.b_dtype, num_bits_per_copy=self.gmem_bits)
        tcA = cute.make_tiled_copy_A(ca, tiled_mma)
        tcB = cute.make_tiled_copy_B(cb, tiled_mma)
        thA = tcA.get_slice(tidx)
        thB = tcB.get_slice(tidx)

        k_tiles = cute.size(gA, mode=[2])
        k_blocks = cute.size(tCrA, mode=[2])

        tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, False)

        for kt in cutlass.range(k_tiles, unroll=1):
            gA_k = gA[(None, None, kt)]
            gB_k = gB[(None, None, kt)]
            sA0 = sA[(None, None, 0)]
            sB0 = sB[(None, None, 0)]

            cute.copy(tcA, thA.partition_S(gA_k), thA.partition_D(sA0))
            cute.copy(tcB, thB.partition_S(gB_k), thB.partition_D(sB0))
            cute.arch.sync_threads()

            cute.nvgpu.warpgroup.fence()
            for kb in cutlass.range(k_blocks, unroll_full=True):
                cute.gemm(
                    tiled_mma, acc,
                    tCrA[(None, None, kb, 0)],
                    tCrB[(None, None, kb, 0)],
                    acc,
                )
                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)
            cute.nvgpu.warpgroup.commit_group()
            cute.nvgpu.warpgroup.wait_group(0)
            cute.arch.sync_threads()

        # -------- Epilogue: reg->sC (stmatrix) --------
        r2s = sm90_utils.sm90_get_smem_store_op(
            self.c_layout, elem_ty_d=self.c_dtype, elem_ty_acc=self.acc_dtype
        )
        st = cute.make_copy_atom(
            cute.nvgpu.warp.StMatrix8x8x16bOp(self.c_layout.is_m_major_c(), 4),
            self.c_dtype,
        )
        tcC = cute.make_tiled_copy_C_atom(st, tiled_mma)
        t_r2s = cute.make_tiled_copy_S(r2s, tcC)

        th_r2s = t_r2s.get_slice(tidx)
        tSD = th_r2s.partition_D(sC)
        tRA = t_r2s.retile(acc)

        rshape = cute.shape(th_r2s.partition_S(sC))
        rlay = cute.make_layout(rshape[:3])
        rAcc = cute.make_rmem_tensor_like(rlay, self.acc_dtype)
        rsz = cute.size(rAcc)

        # -------- sC->GMEM (TiledCopy) --------
        s2g_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), self.c_dtype, num_bits_per_copy=self.store_bits
        )
        t_s2g = cute.make_tiled_copy(s2g_atom, self.epi_layout_tv, self.epi_tiler_mn)
        th_s2g = t_s2g.get_slice(tidx)

        gC2d = gC
        tCgC_for_epi = cute.zipped_divide(gC2d, (epi_m, epi_n))
        epi_tile_num = cute.size(tCgC_for_epi, mode=[1])
        epi_tile_shape = tCgC_for_epi.shape[1]
        epi_tile_layout = cute.make_layout(epi_tile_shape, stride=(epi_tile_shape[1], 1))

        pipe_depth = cute.size(tSD, mode=[3])  # epi_stage=1 => 1

        for epi_idx in cutlass.range_constexpr(epi_tile_num):
            for v in cutlass.range_constexpr(rsz):
                rAcc[v] = tRA[epi_idx * rsz + v]

            rOut = cute.make_rmem_tensor_like(rlay, self.c_dtype)
            rOut.store(rAcc.load().to(self.c_dtype))

            epi_buf = epi_idx % pipe_depth
            cute.copy(t_r2s, rOut, tSD[(None, None, None, epi_buf)])
            cute.arch.sync_threads()

            gcoord = epi_tile_layout.get_hier_coord(epi_idx)
            gC_epi = cute.local_tile(gC2d, (epi_m, epi_n), (gcoord[0], gcoord[1]), proj=(1, 1))
            sC_tile = sC[(None, None, epi_buf)]

            cute.copy(t_s2g, th_s2g.partition_S(sC_tile), th_s2g.partition_D(gC_epi))
            cute.arch.sync_threads()


def main():
    torch.manual_seed(0)
    torch.cuda.manual_seed_all(0)

    M, N, K = 4096, 4096, 4096
    assert M % 128 == 0 and N % 128 == 0 and K % 128 == 0, "要求 M/N/K 是 128 的整数倍"

    a_t, a32, A = make_fp16_rowmajor(M, K)
    b_t, b32, B = make_fp16_rowmajor(N, K)
    c_t, _,  C = make_fp16_rowmajor(M, N)
    c_t.zero_()

    gemm = Gemm128_RouteB_UltraMin()
    compiled = cute.compile(gemm, A, B, C)
    compiled(A, B, C)
    torch.cuda.synchronize()

    ref = (a32 @ b32.t()).half().cpu()
    out = c_t.cpu()
    torch.testing.assert_close(out, ref, atol=1e-2, rtol=1e-3)
    print("PASS")


if __name__ == "__main__":
    main()