/***************************************************************************************************
 * Ex_sm100_gemm — 把 Stage 3 SM100 v3 移植到 SM120（文件名沿用，移植目标是 SM120）
 *
 * ⚠️ 方向反转：W12 产出的是 SM100 v3（UMMA + TMEM + 2-SM cluster）；本周（W13）把它
 *    **移植到 5060 Ti(SM120)**：mma.sync + RMEM 累加器 + 无 2-SM（cluster 退化）+ 1-SM。
 * 改动清单见同目录 MIGRATION_DIFF.md，5 处改动总共 < 100 行。
 *
 * 脚手架给你：
 *   - host driver、CPU ref、verify 完全照搬 SM100 v3
 *   - 5 处改动点都已经标 TODO，对应 MIGRATION_DIFF.md 的编号（SM100 → SM120 方向）
 *
 * 硬件：
 *   🔴 B200(SM100)：移植的**源头**。W12 的 SM100 v3 在这里实跑通过
 *   🟢 5060 Ti(SM120)：移植的**目标**。本地实跑验证 —— mma.sync + RMEM，无 UMMA/TMEM/2-SM
 *      编译：nvcc -arch=sm_120a ...
 **************************************************************************************************/
#include <cstdio>
#include <cstdlib>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
// 注：SM120 目标用 RMEM 累加器，不需要 tmem_allocator_sm100.hpp（SM100 源头才用）
#include "cutlass/arch/barrier.h"
#include "cutlass/half.h"
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;
using TA = cutlass::half_t;
using TC = float;

constexpr int BLK_M = 128;
constexpr int BLK_N = 128;     // SM120 mma.sync：N 回到 128（无 UMMA 128×256 atom）
constexpr int BLK_K = 64;
constexpr int STAGES = 4;

#if defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) || defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

template <class SmemLayoutA, class SmemLayoutB>
struct SharedStorage {
  alignas(128) cute::ArrayEngine<TA, cosize_v<SmemLayoutA>> A;
  alignas(128) cute::ArrayEngine<TA, cosize_v<SmemLayoutB>> B;
  alignas(16) uint64_t full[STAGES];
  alignas(16) uint64_t empty[STAGES];
  // SM120 退化：累加器回到 RMEM，不再需要 SM100 的 tmem_consumer / tmem_base_ptr 字段
};

template <class ...>
__global__ static void sm120_gemm_kernel(/* SM100 v3 签名，cluster 退化到 1×1×1 */) {
  // ⚠️ SM100 → SM120 移植：以下都是 "把 SM100 v3 的 UMMA/TMEM/2-SM 退化掉" 的方向
  //
  // TODO(改动 1)：TiledMMA 从 SM100_MMA_F16BF16_SS（UMMA）换回 SM120 mma.sync atom
  //   - 去掉 cta_group::2 / AtomThrID=<2,1,1>，回到 CTA-local 的 1-SM
  //   accumulator: Tensor tCrC = thr_mma.make_fragment_C(tCgC);  // RMEM（不再是 TMEM）
  //   clear(tCrC);                                               // 用 clear 代替 ScaleOut::Zero
  //
  // ----- producer (与 SM100 v3 完全一样) -----
  // TODO(沿用 v3 producer)：发 TMA load A/B（SM120 仍有 TMA）
  //
  // ----- consumer (主要改动在这) -----
  // TODO(改动 4)：pipeline 从 PipelineTmaUmmaAsync 退回 PipelineTmaAsync
  //   只剩 producer(TMA) ↔ consumer(mma.sync) 两段；去掉 tmem-consumer 这第三段
  //
  // TODO(改动 1.b)：warpgroup 发 mma.sync（不再是 elect_one 单线程发 UMMA）
  //   for (k) { gemm(tiled_mma, tCrA(_,_,k), tCrB(_,_,k), tCrC); }   // 累加进 RMEM
  //   arrive empty[s]
  //
  // TODO(改动 3)：epilogue 直接 RMEM → GMEM（不再走 TMEM → RMEM → GMEM）
  //   copy(tCrC, thr_mma.partition_C(gC));
  //
  // 注意：SM120 无 2-SM，cluster 退化到 1×1×1（改动 5 在本目标上是"删掉"）
}

#endif

int main(int argc, char** argv) {
  int M = argc > 1 ? atoi(argv[1]) : 8192;
  int N = argc > 2 ? atoi(argv[2]) : 8192;
  int K = argc > 3 ? atoi(argv[3]) : 8192;

  cudaDeviceProp props; cudaGetDeviceProperties(&props, 0);
  // 移植目标是 SM120（5060 Ti）；SM100(B200) 是移植源头，也允许跑退化路径做对照
  if (props.major < 10) {
    printf("Ex sm100→sm120 移植需要 Blackwell（SM100 源 / SM120 目标）。当前 SM%d%d，跳过实跑。\n",
           props.major, props.minor);
    printf("静态看 PTX：nvcc -arch=sm_120a -ptx ex_sm100_gemm.cu | grep -c mma.sync\n");
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) || defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
  printf("SM100→SM120 移植脚手架 (M=%d N=%d K=%d)。完成 5 处退化 TODO 后接 CPU 验证 + ncu 性能。\n", M, N, K);
  printf("CHECKPOINT 标线：5060 Ti(SM120) 上 FP16 移植版能正确跑通 + 性能对照 SM100 v3（cuBLAS % 见 stage7 baseline）\n");
#endif
  return 0;
}
