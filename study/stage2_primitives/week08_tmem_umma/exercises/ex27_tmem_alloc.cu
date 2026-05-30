/***************************************************************************************************
 * Ex27 — TMEM 分配 / 写入 / 读回（SM100）
 *
 * 目标：
 *   1. 用 cute::TMEM::Allocator1Sm 在运行期分配一段 TMEM（tcgen05.alloc）
 *   2. 用 RMEM→TMEM 的 store（tcgen05.st）写入一个已知 pattern
 *   3. 用 TMEM→RMEM 的 load（tcgen05.ld）读回，比对，验证 TMEM 读写闭环
 *   4. 体会 TMEM 与 __shared__ 的本质差别：TMEM 是「运行期分配的列资源」，
 *      地址是 alloc 返回的 base（编译期不知道），不像 __shared__ 是编译期固定偏移。
 *
 * 硬件：🔴 仅 B200(sm_100a) 可跑。5060 Ti(SM120) 无 TMEM —— 本程序在非 SM100 上 return 0。
 *   静态看 PTX：nvcc -arch=sm_100a -ptx ex27_tmem_alloc.cu && grep "tcgen05.alloc\|tcgen05.ld\|tcgen05.st" *.ptx
 *
 * 自检（README Q1/Q2/Q5）：
 *   - TMEM 是 SM 私有还是 cluster 共享？（per-SM；cta_group::1 一个 SM 独占自己那 256KB）
 *   - tcgen05.alloc 是运行期、__shared__ 是编译期 —— 差别体现在哪？
 *   - tcgen05.ld/st 一次搬多少 byte/thread？（看 32dp32b1x 的命名）
 **************************************************************************************************/
#include <cstdio>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include <cute/arch/tmem_allocator_sm100.hpp>
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;

constexpr int LANES = 128;   // TMEM 的 128 lanes（固定）
constexpr int COLS  = 128;   // 用 128 列（< 512 上限）

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

__global__ static void tmem_roundtrip_kernel(float* out, float* in) {
  __shared__ uint32_t tmem_base;  // alloc 把 base 地址写这里

  using TmemAllocator = cute::TMEM::Allocator1Sm;
  TmemAllocator alloc{};

  // ---- 分配 TMEM（只让 warp0 干，alloc 是 CTA-scope）----------------------
  bool elect_warp = (threadIdx.x / 32 == 0);
  if (elect_warp) {
    alloc.allocate(TmemAllocator::Sm100TmemCapacityColumns, &tmem_base);
  }
  __syncthreads();

  // ---- 构造一个 TMEM 张量：(128 lanes, COLS)，lane 在高位寻址 -------------
  //   stride (1<<16, 1)：128 个 lane 各占一行（高 16 位 = lane），列连续。
  auto tmem_layout = make_layout(make_shape(Int<LANES>{}, Int<COLS>{}),
                                 make_stride(Int<(1<<16)>{}, _1{}));
  Tensor tTMEM = make_tensor(make_tmem_ptr<float>(tmem_base), tmem_layout);

  // ---- TiledCopy：RMEM<->TMEM 的 store / load -----------------------------
  TiledCopy r2t = make_tmem_copy(SM100_TMEM_STORE_32dp32b1x{}, tTMEM);  // RMEM -> TMEM
  TiledCopy t2r = make_tmem_copy(SM100_TMEM_LOAD_32dp32b1x{},  tTMEM);  // TMEM -> RMEM

  ThrCopy thr_r2t = r2t.get_slice(threadIdx.x);
  ThrCopy thr_t2r = t2r.get_slice(threadIdx.x);

  // gmem 视图（与 TMEM 同形，行优先），用来灌入 / 倒出
  auto gmem_layout = make_layout(make_shape(Int<LANES>{}, Int<COLS>{}), LayoutRight{});
  Tensor gIn  = make_tensor(make_gmem_ptr(in),  gmem_layout);
  Tensor gOut = make_tensor(make_gmem_ptr(out), gmem_layout);

  // ---- 写：gmem -> RMEM -> TMEM -------------------------------------------
  Tensor tTMEM_s = thr_r2t.partition_D(tTMEM);          // 本线程负责的 TMEM 段
  Tensor rSrc    = make_fragment_like(thr_r2t.partition_S(gIn));
  copy(thr_r2t.partition_S(gIn), rSrc);                 // gmem -> RMEM
  copy(r2t, rSrc, tTMEM_s);                             // RMEM -> TMEM (tcgen05.st)

  __syncthreads();  // 确保写入完成再读

  // ---- 读：TMEM -> RMEM -> gmem -------------------------------------------
  Tensor tTMEM_l = thr_t2r.partition_S(tTMEM);
  Tensor rDst    = make_fragment_like(thr_t2r.partition_D(gOut));
  copy(t2r, tTMEM_l, rDst);                             // TMEM -> RMEM (tcgen05.ld)
  copy(rDst, thr_t2r.partition_D(gOut));                // RMEM -> gmem

  __syncthreads();

  // ---- 释放 TMEM ----------------------------------------------------------
  if (elect_warp) {
    alloc.release_allocation_lock();
    alloc.free(tmem_base, TmemAllocator::Sm100TmemCapacityColumns);
  }
}

#endif

int main() {
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, 0);
  if (props.major != 10) {
    printf("Ex27 需要 Blackwell SM100(sm_100a)。当前 SM%d%d，跳过实跑。\n", props.major, props.minor);
    printf("静态看 PTX：nvcc -arch=sm_100a -ptx ex27_tmem_alloc.cu && grep tcgen05 *.ptx\n");
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
  int n = LANES * COLS;
  thrust::host_vector<float> hIn(n);
  for (int i = 0; i < n; ++i) hIn[i] = float(i % 97) - 48.f;
  thrust::device_vector<float> dIn = hIn, dOut(n, -1.f);

  tmem_roundtrip_kernel<<<1, 128>>>(dOut.data().get(), dIn.data().get());
  CUTE_CHECK_LAST();

  thrust::host_vector<float> hOut = dOut;
  float max_err = 0.f;
  for (int i = 0; i < n; ++i) max_err = fmaxf(max_err, fabsf(hOut[i] - hIn[i]));
  printf("TMEM round-trip max abs error = %.4f -> %s\n", max_err, (max_err == 0.f) ? "PASS" : "FAIL");
#else
  printf("CUTLASS_ARCH_MMA_SM100_SUPPORTED 未开启，跳过。\n");
#endif
  return 0;
}
