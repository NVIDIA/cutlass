#!/usr/bin/env bash
# W12 benchmark：6 个 shape × 2 个 schedule × cuBLAS 对照
# 用法：
#   cd build && make study_stage3_w12_ex_warpspec_gemm_v3_pingpong -j
#               make study_stage3_w12_ex_warpspec_gemm_v3_cooperative -j
#   bash study/stage3_gemm/week12_pingpong_vs_coop/exercises/bench.sh
#
# 输出：写到 PERFORMANCE.md 表格

set -e
PINGPONG=./study_stage3_w12_ex_warpspec_gemm_v3_pingpong
COOPERATIVE=./study_stage3_w12_ex_warpspec_gemm_v3_cooperative

# (M, N, K, 类型注释)
declare -a SHAPES=(
  "8192 8192 8192 :大GEMM"
  "4096 4096 4096 :中等"
  "128  8192 8192 :短M-decode类"
  "8192 128  8192 :短N"
  "4096 4096 16384 :大K"
  "16   8192 4096 :极短M"
)

printf "| Shape (M,N,K) | 类型 | Pingpong TFLOPS | Cooperative TFLOPS | 优势方 |\n"
printf "|---------------|------|-----------------|---------------------|--------|\n"

for entry in "${SHAPES[@]}"; do
  IFS=':' read -r dims tag <<< "$entry"
  read -r M N K <<< "$dims"
  PP=$($PINGPONG    $M $N $K 2>/dev/null | grep -oE '[0-9]+\.[0-9]+ TFLOPS' | head -1 | awk '{print $1}')
  CO=$($COOPERATIVE $M $N $K 2>/dev/null | grep -oE '[0-9]+\.[0-9]+ TFLOPS' | head -1 | awk '{print $1}')
  WINNER=$(awk -v p=${PP:-0} -v c=${CO:-0} 'BEGIN{print (p>c)?"Pingpong":"Cooperative"}')
  printf "| %-13s | %-4s | %-15s | %-19s | %-6s |\n" "$M,$N,$K" "$tag" "${PP:-?}" "${CO:-?}" "$WINNER"
done

echo ""
echo "把上表填到 PERFORMANCE.md，并对每一行写一句"为什么这个 schedule 赢"。"
