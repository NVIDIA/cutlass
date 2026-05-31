/***************************************************************************************************
 * Stage 2 CHECKPOINT — minimal warp-specialized ping-pong toy（不是 GEMM，只验同步正确）
 *
 * ★ 这是 Stage 2 的综合自测（capstone）。下面给了完整脚手架：
 *     - 数据生成 + CPU 参考 + 结果比对（已写好）
 *     - smem 双 buffer + full/empty 两组 mbarrier 的声明与初始化（已写好）
 *     - producer warp 用 TMA 把 tile 从 gmem 搬进 smem（已写好骨架）
 *   ★ 留给你完成的核心（标 TODO）：producer/consumer 之间的 mbarrier 握手 +
 *     两个 consumer warpgroup 的 ping-pong 轮转 + 各自 reduction。
 *   完成并跑通（结果与 CPU 一致）即通过 Stage 2 CHECKPOINT。
 *
 * 设计：
 *   - 总数据 1MB = 256K float，切成 NUM_TILES 个 tile，每 tile TILE_ELEMS 个 float。
 *   - smem 双 buffer（STAGES=2）：producer 填一个，某个 consumer warpgroup 消费一个，错开。
 *   - 角色分工（warp specialization）：
 *       warp 0          = producer（发 TMA）
 *       warp 1..4 (WG0) = consumer warpgroup 0
 *       warp 5..8 (WG1) = consumer warpgroup 1
 *     两个 WG ping-pong：tile 0 给 WG0，tile 1 给 WG1，tile 2 给 WG0 ……
 *   - 同步：
 *       full[s]  : producer 填好 buffer s 后 arrive；consumer 等它再读（transaction barrier）
 *       empty[s] : consumer 用完 buffer s 后 arrive；producer 等它再覆写
 *
 * 硬件：🟢 5060 Ti(SM120) 可跑（TMA + mbarrier 都支持）。
 *
 * 跑：
 *   ./study_stage2_w07_ex_warpspec_pingpong_toy
 *   期望：device sum == CPU sum（相对误差 < 1e-3）
 **************************************************************************************************/
#include <cstdio>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;

using T = float;

constexpr int TOTAL_ELEMS = 256 * 1024;   // 1MB float
constexpr int TILE_ELEMS  = 4 * 1024;     // 每 tile 4K float = 16KB
constexpr int NUM_TILES   = TOTAL_ELEMS / TILE_ELEMS;  // 64 个 tile
constexpr int STAGES      = 2;            // 双 buffer
constexpr int CONSUMER_WG = 2;            // 两个 consumer warpgroup（ping-pong）

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) || defined(CUTE_ARCH_TMA_SM90_ENABLED)

template <class TmaLoad, class GTensor, class SmemLayout>
__global__ static void pingpong_kernel(CUTLASS_GRID_CONSTANT TmaLoad const tma,
                                        GTensor mA, SmemLayout tile_layout,
                                        double* out_partial)
{
  // ---- smem：STAGES 个 tile buffer + full/empty 两组 barrier --------------
  extern __shared__ char smem_raw[];
  T* smem = reinterpret_cast<T*>(smem_raw);
  // barrier 放 tile buffer 之后
  uint64_t* full  = reinterpret_cast<uint64_t*>(smem + STAGES * TILE_ELEMS);
  uint64_t* empty = full + STAGES;

  auto stage_tensor = [&](int s) {
    return make_tensor(make_smem_ptr(smem + s * TILE_ELEMS), tile_layout);
  };

  int warp_idx = threadIdx.x / 32;
  int lane     = threadIdx.x % 32;
  bool is_producer = (warp_idx == 0);
  // consumer warpgroup id：warp 1..4 -> WG0，warp 5..8 -> WG1
  int  cons_wg = is_producer ? -1 : (warp_idx - 1) / 4;

  // ---- barrier 初始化 -----------------------------------------------------
  if (threadIdx.x == 0) {
    for (int s = 0; s < STAGES; ++s) {
      initialize_barrier(full[s],  /*arrive count*/ 1);            // producer(1 个线程发 TMA) arrive
      initialize_barrier(empty[s], /*arrive count*/ 128);          // 一个 consumer warpgroup(128) arrive
    }
  }
  __syncthreads();

  int tx_bytes = TILE_ELEMS * int(sizeof(T));

  // =========================================================================
  // PRODUCER（warp 0）
  // =========================================================================
  if (is_producer) {
    bool elected = (lane == 0);
    // producer 的 empty-phase 初值 = 1（buffer 初始视为「空且就绪」）
    int empty_phase = 1;
    for (int tile = 0; tile < NUM_TILES; ++tile) {
      int s = tile % STAGES;

      // ---- TODO(1): 等 buffer s 变空再覆写 --------------------------------
      // 提示：consumer 用完会 arrive empty[s]；producer 在覆写前要 wait_barrier(empty[s], empty_phase)。
      //       每用过一遍 buffer s（即每隔 STAGES 个 tile）翻一次 empty_phase。
      //   if (tile >= STAGES) { wait_barrier(empty[s], empty_phase); /* 适时翻 phase */ }

      // ---- 发 TMA：把第 tile 块搬进 buffer s ------------------------------
      if (elected) {
        Tensor gtile = mA(_, tile);              // (TILE_ELEMS) 第 tile 块
        Tensor stile = stage_tensor(s);
        auto [tg, ts] = tma_partition(tma, Int<0>{}, Layout<_1>{},
                                      group_modes<0,1>(stile), group_modes<0,1>(gtile));
        set_barrier_transaction_bytes(full[s], tx_bytes);   // 声明本次 transaction 字节数 + arrive
        copy(tma.with(full[s]), tg, ts);                    // TMA 搬完自己 complete_tx(full[s])
      }
      // ---- TODO(2): 这里不需要 producer 显式等 full；consumer 会去 wait full[s] ----
    }
  }
  // =========================================================================
  // CONSUMER（warpgroup 0 / 1，ping-pong）
  // =========================================================================
  else {
    double local = 0.0;
    // 本 warpgroup 负责的 tile：cons_wg, cons_wg+CONSUMER_WG, cons_wg+2*CONSUMER_WG, ...
    int full_phase = 0;
    for (int tile = cons_wg; tile < NUM_TILES; tile += CONSUMER_WG) {
      int s = tile % STAGES;

      // ---- TODO(3): 等 buffer s 被 producer 填好 --------------------------
      // 提示：wait_barrier(full[s], full_phase)；每消费过一遍 buffer s 翻一次 full_phase。
      //   wait_barrier(full[s], full_phase); /* 适时翻 phase */

      // ---- TODO(4): 本 wargroup 128 线程协作 reduce 这个 tile -------------
      // 提示：Tensor stile = stage_tensor(s); 每线程跨步累加 stile(i)，i 从 (warpgroup 内 tid)
      //       起，步长 128，把 TILE_ELEMS 个元素加到 local。
      //   Tensor stile = stage_tensor(s);
      //   int wg_tid = threadIdx.x % 128;   // 0..127（注意：两个 WG 的 threadIdx 不同，需映射）
      //   for (int i = wg_tid; i < TILE_ELEMS; i += 128) local += double(stile(i));

      // ---- TODO(5): reduce 完，标记 buffer s 可被覆写 --------------------
      // 提示：__syncwarp/或确保本 WG 读完后，由本 WG 128 线程 arrive empty[s]。
      //   arrive_barrier(empty[s]);
    }

    // 本 warpgroup 把 local 规约到一个值，写回 out_partial[cons_wg]（用 atomic 或 warp/block reduce）
    // 这里给最简单的 atomicAdd（正确性优先，不追求性能）
    atomicAdd(out_partial + cons_wg, local);
  }
}

#endif // SM90/TMA

int main() {
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, 0);
  if (props.major < 9) {
    printf("CHECKPOINT 需要 SM90+（TMA + mbarrier）。当前 SM%d%d，跳过。\n", props.major, props.minor);
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) || defined(CUTE_ARCH_TMA_SM90_ENABLED)
  // host 数据 + CPU 参考
  thrust::host_vector<T> hIn(TOTAL_ELEMS);
  double cpu_sum = 0.0;
  for (int i = 0; i < TOTAL_ELEMS; ++i) { hIn[i] = T((i % 13) * 0.5f); cpu_sum += double(hIn[i]); }
  thrust::device_vector<T> dIn = hIn;
  thrust::device_vector<double> dPartial(CONSUMER_WG, 0.0);

  // gmem 视为 (TILE_ELEMS, NUM_TILES)：列 tile 为第 1 维便于按 tile 切
  auto gmem_layout = make_layout(make_shape(Int<TILE_ELEMS>{}, Int<NUM_TILES>{}),
                                 make_stride(_1{}, Int<TILE_ELEMS>{}));
  Tensor mA = make_tensor(make_gmem_ptr(dIn.data().get()), gmem_layout);
  auto tile_layout = make_layout(make_shape(Int<TILE_ELEMS>{}));

  // 单 tile 的 TMA descriptor
  Copy_Atom tma = make_tma_copy(SM90_TMA_LOAD{}, mA, tile_layout, make_shape(Int<TILE_ELEMS>{}));

  // 9 个 warp = 288 线程（producer 1 + consumer 2x128）。round 到 32 倍数。
  int threads = 32 /*producer warp*/ + CONSUMER_WG * 128;  // = 288
  int smem_bytes = STAGES * TILE_ELEMS * sizeof(T) + 2 * STAGES * sizeof(uint64_t);

  auto* kernel = &pingpong_kernel<decltype(tma), decltype(mA), decltype(tile_layout)>;
  cudaFuncSetAttribute(kernel, cudaFuncAttributeMaxDynamicSharedMemorySize, smem_bytes);

  kernel<<<1, threads, smem_bytes>>>(tma, mA, tile_layout, dPartial.data().get());
  cudaError_t e = cudaDeviceSynchronize();
  if (e != cudaSuccess) { printf("kernel error: %s\n", cudaGetErrorString(e)); return 1; }

  thrust::host_vector<double> hPartial = dPartial;
  double dev_sum = 0.0;
  for (int w = 0; w < CONSUMER_WG; ++w) dev_sum += hPartial[w];

  double rel = fabs(dev_sum - cpu_sum) / (fabs(cpu_sum) + 1e-9);
  printf("CPU sum    = %.3f\n", cpu_sum);
  printf("device sum = %.3f  (rel err %.2e)\n", dev_sum, rel);
  printf("%s\n", (rel < 1e-3) ? "PASS — Stage 2 CHECKPOINT 通过！"
                              : "FAIL — 还没填完 TODO(1..5) 的同步逻辑（当前 device sum 应为 0）");
#else
  printf("TMA 未启用，跳过。\n");
#endif
  return 0;
}
