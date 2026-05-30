/***************************************************************************************************
 * Ex12 — WGMMA atom 的 TV layout 打印
 *
 * 目标（呼应 W3 的 ex07，只是把 SM80 atom 换成 SM90 WGMMA atom）：
 *   对一组 N 维度（8 / 64 / 128 / 256）的 `SM90_64xNx16_F16F16F16_SS` atom，打印
 *     - Shape_MNK   : 指令的 M/N/K 尺寸
 *     - LayoutA_TV  : (thread,value) -> A 矩阵坐标 的映射
 *     - LayoutB_TV  : (thread,value) -> B 矩阵坐标
 *     - LayoutC_TV  : (thread,value) -> C 矩阵坐标
 *
 * 为什么这是纯 host 程序：
 *   构造 MMA atom + print(tiled_mma) 全是编译期 layout 代数，不发任何 PTX、不碰 GPU。
 *   所以在 5060 Ti / 没有 Hopper 卡 / 甚至 CPU-only 编译都能跑（只要能编译 cute）。
 *   这正是 W5「读 mma_traits」的最佳配套：你能亲眼看到 atom 的接线，而不必跑 H20。
 *
 * 跑：
 *   ./study_stage2_w05_ex12_wgmma_layout_print
 *
 * 预测先做（手算 / 读 mma_traits_sm90_gmma.hpp 后回答）：
 *   - WGMMA 是 warpgroup（128 线程）一条指令 → ThrID 应该是 128
 *   - LayoutC_TV 的 thread 维 size 应为 128；value 维 = 每线程持有的 C 元素数
 *   - N=8 时每线程持 C 多少个？N=256 时呢？（提示：随 N 线性增长）
 **************************************************************************************************/
#include <cstdio>
#include <cute/tensor.hpp>
#include <cute/atom/mma_atom.hpp>
#include <cute/arch/mma_sm90.hpp>
#include <cute/atom/mma_traits_sm90_gmma.hpp>
#include "cutlass/half.h"

using namespace cute;

// 打印一个 WGMMA atom 的全部接线信息。
// MMAOp 形如 SM90_64x128x16_F16F16F16_SS<Major::K, Major::K>。
template <class MMAOp>
void show_atom(char const* tag) {
  // 单 atom 直接做 TiledMMA（atom layout 默认 1x1x1，即只用一个 warpgroup）
  TiledMMA tiled_mma = make_tiled_mma(MMAOp{});

  printf("================ %s ================\n", tag);
  // print(tiled_mma) 会打出 ThrLayoutVMNK / Shape_MNK / LayoutA_TV / LayoutB_TV / LayoutC_TV
  print(tiled_mma);
  printf("\n");
  printf("  size(tiled_mma) = %d   <- 一条 WGMMA 需要的线程数\n", int(size(tiled_mma)));
  printf("\n");
}

int main() {
  // SS 模式：A、B 都从 SMEM 读。Major::K 表示 A/B 都是 K-major（TN GEMM 的习惯）。
  // 只挑 4 个有代表性的 N，看 C 的 value 维如何随 N 增长。
  show_atom<SM90_64x8x16_F16F16F16_SS  <GMMA::Major::K, GMMA::Major::K>>("SM90_64x8x16_SS   (N=8)");
  show_atom<SM90_64x64x16_F16F16F16_SS <GMMA::Major::K, GMMA::Major::K>>("SM90_64x64x16_SS  (N=64)");
  show_atom<SM90_64x128x16_F16F16F16_SS<GMMA::Major::K, GMMA::Major::K>>("SM90_64x128x16_SS (N=128)");
  show_atom<SM90_64x256x16_F16F16F16_SS<GMMA::Major::K, GMMA::Major::K>>("SM90_64x256x16_SS (N=256)");

  printf("做完对照（自检）：\n");
  printf("  1. 四个 atom 的 size 都应是 128（warpgroup = 4 warp）。\n");
  printf("  2. Shape_MNK 的 M 恒为 64、K 恒为 16，只有 N 在变 —— 这就是 m64nNk16 的来历。\n");
  printf("  3. LayoutC_TV 的 value 维 size = N*64/128 = N/2，随 N 线性增长。\n");
  printf("     -> N=8 每线程持 4 个 C；N=256 每线程持 128 个 C(register pressure!)。\n");
  printf("  4. 对比 RS 版本(把 _SS 换成 _RS)：LayoutA_TV 会从 descriptor 变成真实寄存器布局。\n");
  return 0;
}
