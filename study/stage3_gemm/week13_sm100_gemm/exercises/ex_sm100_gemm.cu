/***************************************************************************************************
 * Ex_sm100_gemm — 把 Stage 3 v3 移植到 SM100（UMMA + TMEM + 2-CTA cluster）
 *
 * 这是把你 W12 完成的 v3 (SM90 WGMMA) 改成 SM100 版本。
 * 改动清单见同目录 MIGRATION_DIFF.md，5 处改动总共 < 100 行。
 *
 * 脚手架给你：
 *   - host driver、CPU ref、verify 完全照搬 v3
 *   - SharedStorage 已加 tmem_base_ptr 字段
 *   - 5 处改动点都已经标 TODO，对应 MIGRATION_DIFF.md 的编号
 *
 * 硬件：
 *   🟢 5060 Ti(SM120)：只能编译看 PTX，不能跑 —— SM120 没有 UMMA/TMEM
 *      静态验证：nvcc -arch=sm_100a -ptx ex_sm100_gemm.cu | grep -c "tcgen05.mma"
 *   🔴 B200(sm_100a)：实跑
 **************************************************************************************************/
#include <cstdio>
#include <cstdlib>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include <cute/arch/tmem_allocator_sm100.hpp>
#include "cutlass/arch/barrier.h"
#include "cutlass/half.h"
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;
using TA = cutlass::half_t;
using TC = float;

constexpr int BLK_M = 128;
constexpr int BLK_N = 256;     // SM100 atom 默认 128×256
constexpr int BLK_K = 64;
constexpr int STAGES = 4;

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

template <class SmemLayoutA, class SmemLayoutB>
struct SharedStorage {
  alignas(128) cute::ArrayEngine<TA, cosize_v<SmemLayoutA>> A;
  alignas(128) cute::ArrayEngine<TA, cosize_v<SmemLayoutB>> B;
  alignas(16) uint64_t full[STAGES];
  alignas(16) uint64_t empty[STAGES];
  // NEW for SM100:
  alignas(16) uint64_t tmem_consumer[STAGES];  // 改动 4：TMEM 消费完成 mbarrier
  alignas(16) uint32_t tmem_base_ptr;          // 改动 2：TMEM alloc 写入
};

template <class ...>
__global__ static void sm100_gemm_kernel(/* 同 v3 签名 */) {
  // TODO(改动 2)：TMEM alloc
  //   using TmemAllocator = cute::TMEM::Allocator1Sm;
  //   if (warp0 && elect_one) allocator.allocate(..., &tmem_base_ptr);
  //   __syncthreads();
  //
  // TODO(改动 1)：TiledMMA 换成 SM100_MMA_F16BF16_SS
  //   TiledMMA tiled_mma = make_tiled_mma(
  //       SM100_MMA_F16BF16_SS<TA, TA, TC, 128, 256, UMMA::Major::K, UMMA::Major::K>{});
  //
  //   accumulator: Tensor tCtAcc = cta_mma.make_fragment_C(tCgC);  // TMEM tensor
  //   tCtAcc.data() = tmem_base_ptr;
  //
  // ----- producer (与 v3 完全一样) -----
  // TODO(沿用 v3 producer)：发 TMA load A/B
  //
  // ----- consumer (主要改动在这) -----
  // TODO(改动 4)：用 PipelineTmaUmmaAsync 的同步逻辑：
  //   除了 full/empty barrier 外，还要 wait_barrier(tmem_consumer[s], ...)
  //   确保 TMEM 累加器在 epilogue 之前的 MMA 已经完成
  //
  // TODO(改动 1.b)：单线程发 UMMA
  //   if (elect_one_warp) {
  //     tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;
  //     for (k) {
  //       gemm(tiled_mma, tCrA(_,_,k), tCrB(_,_,k), tCtAcc);
  //       tiled_mma.accumulate_ = UMMA::ScaleOut::One;
  //     }
  //     cutlass::arch::umma_arrive(&tmem_consumer[s]);
  //   }
  //
  // TODO(改动 3)：epilogue TMEM → RMEM → GMEM
  //   TiledCopy t2r = make_tmem_copy(SM100_TMEM_LOAD_32dp32b1x{}, tCtAcc);
  //   ... (参考 W8 ex28 / MIGRATION_DIFF.md 改动 3)
  //
  // TODO(收尾)：TMEM 释放
  //   if (warp0 && elect_one) { allocator.release_allocation_lock(); allocator.free(...); }
}

#endif

int main(int argc, char** argv) {
  int M = argc > 1 ? atoi(argv[1]) : 8192;
  int N = argc > 2 ? atoi(argv[2]) : 8192;
  int K = argc > 3 ? atoi(argv[3]) : 8192;

  cudaDeviceProp props; cudaGetDeviceProperties(&props, 0);
  if (props.major != 10) {
    printf("Ex sm100_gemm 需要 Blackwell SM100(sm_100a)。当前 SM%d%d，跳过实跑。\n",
           props.major, props.minor);
    printf("静态看 PTX：nvcc -arch=sm_100a -ptx ex_sm100_gemm.cu | grep -c tcgen05.mma\n");
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
  printf("SM100 GEMM 脚手架 (M=%d N=%d K=%d)。完成 5 处 TODO 后接 CPU 验证 + ncu 性能。\n", M, N, K);
  printf("CHECKPOINT 标线：B200 上 FP16 ≥ 70%% cuBLAS（cuBLAS 约 1.5-1.8 PFLOPS dense）\n");
#endif
  return 0;
}
