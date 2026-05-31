/***************************************************************************************************
 * Ex11 — 最小 WGMMA：单 CTA / 单 k-tile 跑一块 64x64x64 的 TN GEMM
 *
 * 这是 examples/cute/tutorial/hopper/wgmma_sm90.cu 的「瘦身版」：
 *   - 砍掉 multi-CTA grid、砍掉 software pipeline、砍掉 cluster
 *   - 只留一个 CTA、一个 warpgroup（128 线程）、一个 k-tile
 *   - 目的：把「smem swizzle 布局 → cp.async 填 smem → 一条 cute::gemm 发 WGMMA →
 *     fence/commit/wait 同步 → epilogue」这条主干看清楚，每步都有注释。
 *
 * 配置：
 *   A: (M,K)=(64,64) row-major(K-major)   B: (N,K)=(64,64) row-major(K-major)   => TN GEMM
 *   C = A * B^T，C:(M,N)=(64,64)
 *   mma atom = SM90_64x64x16_F16F16F16_SS（M64 N64 K16，SS 模式两个操作数都在 smem）
 *   K=64 / atom-K=16 => cute::gemm 内部自动发 4 条 wgmma
 *
 * 硬件：🟡 必须 Hopper(sm_90a)。5060 Ti(SM120) 没有 WGMMA，本程序在非 Hopper 上直接 return 0。
 *   静态编译看 PTX：nvcc -arch=sm_90a -ptx ex11_wgmma_minimal.cu，grep wgmma.mma_async
 *
 * 跑（在 H20 上）：
 *   ./study_stage2_w05_ex11_wgmma_minimal
 *   期望：max abs error < 1e-2（fp16 累加 fp16，单 tile 误差很小）
 **************************************************************************************************/
#include <cstdio>
#include <cstdlib>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include "cutlass/half.h"
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;

using T = cutlass::half_t;

constexpr int M = 64;
constexpr int N = 64;
constexpr int K = 64;

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

template <class SmemLayoutA, class SmemLayoutB, class TiledCopyA, class TiledCopyB, class TiledMMA>
__global__ static
__launch_bounds__(128)
void wgmma_minimal_kernel(T const* A, T const* B, T* C,
                          SmemLayoutA sA_layout, SmemLayoutB sB_layout,
                          TiledCopyA copy_a, TiledCopyB copy_b, TiledMMA mma)
{
  // ---- gmem 张量（A、B 都是 K-major：stride (K,1)）-------------------------
  Tensor mA = make_tensor(make_gmem_ptr(A), make_shape(Int<M>{}, Int<K>{}), make_stride(Int<K>{}, _1{}));
  Tensor mB = make_tensor(make_gmem_ptr(B), make_shape(Int<N>{}, Int<K>{}), make_stride(Int<K>{}, _1{}));
  Tensor mC = make_tensor(make_gmem_ptr(C), make_shape(Int<M>{}, Int<N>{}), make_stride(Int<N>{}, _1{}));

  // ---- swizzled smem（SS 模式下 WGMMA 的硬性要求：128B swizzle）------------
  __shared__ T smemA[cosize_v<SmemLayoutA>];
  __shared__ T smemB[cosize_v<SmemLayoutB>];
  Tensor sA = make_tensor(make_smem_ptr(smemA), sA_layout);  // (M,K) swizzled
  Tensor sB = make_tensor(make_smem_ptr(smemB), sB_layout);  // (N,K) swizzled

  // ---- 步骤 1：cp.async 把 A、B 从 gmem 搬进 swizzled smem ------------------
  //   注意 partition_D 的目标要用 as_position_independent_swizzle_tensor 包一层，
  //   这样 cp.async 写进去时坐标会按 swizzle 重排（WGMMA 读时才对得上）。
  ThrCopy thr_copy_a = copy_a.get_slice(threadIdx.x);
  Tensor tAgA = thr_copy_a.partition_S(mA);
  Tensor sA_pi = as_position_independent_swizzle_tensor(sA);
  Tensor tAsA = thr_copy_a.partition_D(sA_pi);

  ThrCopy thr_copy_b = copy_b.get_slice(threadIdx.x);
  Tensor tBgB = thr_copy_b.partition_S(mB);
  Tensor sB_pi = as_position_independent_swizzle_tensor(sB);
  Tensor tBsB = thr_copy_b.partition_D(sB_pi);

  copy(copy_a, tAgA, tAsA);
  copy(copy_b, tBgB, tBsB);
  cp_async_fence();      // 提交这一批 cp.async
  cp_async_wait<0>();    // 等全部 cp.async 落地
  __syncthreads();       // 全 warpgroup 都看到 smem 才能发 WGMMA

  // ---- 步骤 2：WGMMA partition + 累加器 ------------------------------------
  ThrMMA thr_mma = mma.get_slice(threadIdx.x);
  Tensor tCsA = thr_mma.partition_A(sA);            // (MMA,MMA_M,MMA_K)
  Tensor tCsB = thr_mma.partition_B(sB);            // (MMA,MMA_N,MMA_K)
  Tensor tCgC = thr_mma.partition_C(mC);            // (MMA,MMA_M,MMA_N)

  // SS 模式下 A/B 的 fragment 是 smem descriptor（不是真寄存器），无需 copy(s->r)
  Tensor tCrA = thr_mma.make_fragment_A(tCsA);
  Tensor tCrB = thr_mma.make_fragment_B(tCsB);
  Tensor tCrC = thr_mma.make_fragment_C(tCgC);      // 累加器在寄存器（warpgroup 摊开）
  clear(tCrC);

  // ---- 步骤 3：三步同步发 WGMMA --------------------------------------------
  //   fence_operand：告诉编译器累加器寄存器即将被异步指令读写（防乱序）
  //   arrive       : wgmma.fence —— 圈定 smem 操作数的可见性起点
  //   gemm         : 真正发 4 条 wgmma.mma_async（K=64/16=4）
  //   commit_batch : wgmma.commit_group —— 把刚发的打成一组
  //   wait<0>      : wgmma.wait_group 0 —— 等这组全部完成
  warpgroup_fence_operand(tCrC);
  warpgroup_arrive();
  gemm(mma, tCrA, tCrB, tCrC);
  warpgroup_commit_batch();
  warpgroup_wait<0>();
  warpgroup_fence_operand(tCrC);

  // ---- 步骤 4：epilogue，累加器写回 gmem -----------------------------------
  copy(tCrC, tCgC);
}

void run() {
  // smem 布局：K-major + 128B swizzle（WGMMA SS 的标配）
  auto sA_layout = tile_to_shape(GMMA::Layout_K_SW128_Atom<T>{}, make_shape(Int<M>{}, Int<K>{}));
  auto sB_layout = tile_to_shape(GMMA::Layout_K_SW128_Atom<T>{}, make_shape(Int<N>{}, Int<K>{}));

  // cp.async TiledCopy：16x8 线程，每线程 1x8 个 half（16B = uint128）
  TiledCopy copyA = make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS<uint128_t>, T>{},
                                    Layout<Shape<_16,_8>, Stride<_8,_1>>{},
                                    Layout<Shape< _1,_8>>{});
  TiledCopy copyB = make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS<uint128_t>, T>{},
                                    Layout<Shape<_16,_8>, Stride<_8,_1>>{},
                                    Layout<Shape< _1,_8>>{});

  TiledMMA mma = make_tiled_mma(SM90_64x64x16_F16F16F16_SS<GMMA::Major::K, GMMA::Major::K>{});

  // host 数据
  thrust::host_vector<T> hA(M*K), hB(N*K), hC(M*N);
  for (int i = 0; i < M*K; ++i) hA[i] = T(float((rand()%5) - 2));
  for (int i = 0; i < N*K; ++i) hB[i] = T(float((rand()%5) - 2));
  thrust::device_vector<T> dA = hA, dB = hB, dC(M*N);

  wgmma_minimal_kernel<<<1, 128>>>(dA.data().get(), dB.data().get(), dC.data().get(),
                                   sA_layout, sB_layout, copyA, copyB, mma);
  CUTE_CHECK_LAST();
  hC = dC;

  // CPU 参考：C[m,n] = sum_k A[m,k]*B[n,k]（B 是 N-major 即 B^T）
  float max_err = 0.f;
  for (int m = 0; m < M; ++m)
    for (int n = 0; n < N; ++n) {
      float acc = 0.f;
      for (int k = 0; k < K; ++k) acc += float(hA[m*K+k]) * float(hB[n*K+k]);
      max_err = fmaxf(max_err, fabsf(acc - float(hC[m*N+n])));
    }
  printf("max abs error = %.4f  -> %s\n", max_err, (max_err < 1e-2f) ? "PASS" : "FAIL");
}

#endif // CUTLASS_ARCH_MMA_SM90_SUPPORTED

int main() {
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, 0);
  if (props.major != 9) {
    printf("Ex11 需要 Hopper(sm_90a)。当前 SM%d%d，跳过实跑。\n", props.major, props.minor);
    printf("静态看 PTX：nvcc -arch=sm_90a -ptx ex11_wgmma_minimal.cu && grep wgmma.mma_async *.ptx\n");
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
  run();
#else
  printf("CUTLASS_ARCH_MMA_SM90_SUPPORTED 未开启，跳过。\n");
#endif
  return 0;
}
