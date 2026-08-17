# CuTe MACA Compiler Support

本项目基于 CUTLASS 官方库修改，目标是在尽量贴近上游 CuTe C++ 源码结构的前提下，
增加其它 GPGPU 厂商编译器的原生编译支持。

当前目录用于验证 MACA/MXMACA 编译器路径。这里的示例重点是确认 CuTe C++ 核心
模板、host/device 修饰、基础 runtime、kernel launch、copy 和标量 GEMM 代码能够被
MACA 编译器正确编译和运行。它不是 MACA 平台的最终高性能 GEMM 实现，也暂不包含
MMA、TMA 或平台专用矩阵指令适配。

## SGEMM NT

`sgemm_1.maca` 对照 CuTe 官方 `examples/cute/tutorial/sgemm_1.cu` 的结构，
实现一个 MACA 版本的基础验证用例。它使用 MACA `mc*` runtime API，包含确定性的
host 输入、可选 CPU reference GEMM、device kernel launch、device-to-host copy、
误差检查和基础耗时输出。

直接使用 MXMACA 编译运行：

```bash
/opt/maca-3.5.3/mxgpu_llvm/bin/mxcc -x maca -std=c++17 -O3 \
  --maca-path=/opt/maca-3.5.3 \
  -I/path/to/cutex/include \
  -I/opt/maca-3.5.3/include \
  -I/opt/maca-3.5.3/tools/cu-bridge/include \
  -I/opt/maca-3.5.3/tools/cu-bridge/include/cuda \
  examples/cute/maca/sgemm_1.maca \
  -o cute_maca_sgemm_1

./cute_maca_sgemm_1
./cute_maca_sgemm_1 256 256 16 N T 100
./cute_maca_sgemm_1 512 512 1024 N T 5000 0
```

最后一个参数控制是否执行 CPU reference 校验。省略或传 `1` 会执行正确性校验；
传 `0` 会跳过 CPU reference，更适合观察 GPU kernel timing。

输出保留 CUDA tutorial 的 `CUTE_GEMM` 吞吐格式，同时增加 MACA 路径的正确性信息：

```text
M = 128
N = 128
K = 8
C = A^N B^T
alpha=1.25 beta=0.5
result_check=enabled
Computing CPU reference...
max_abs_error=0 max_rel_error=0 at C(0,0): got=1.66992 ref=1.66992
CUTE_GEMM:     [   ...]GFlop/s  (...ms)
PASS
```

CMake 构建：

```bash
cmake -S examples/cute/maca -B build-cute-maca \
  -DCMAKE_CXX_COMPILER=/opt/maca-3.5.3/mxgpu_llvm/bin/mxcc \
  -DCUTE_MACA_ROOT=/opt/maca-3.5.3
cmake --build build-cute-maca --target cute_maca_sgemm_1 -v
```
