rm ~/cutlass/output.log
# rm -rf ~/cutlass/build
mkdir -p ~/cutlass/build
cd ~/cutlass/build

export CUDA_VISIBLE_DEVICES=7
# export REF_PRINT_DIFF=1

cmake .. -DCUTLASS_NVCC_ARCHS=100a

# Record start time for e2e timing
start_time=$(date +%s)
echo "E2E Test Run Started at: $(date)" | tee -a ~/cutlass/output.log

targets=(
    # test_examples_77_blackwell_fmha_fp16_test_causal
    # test_examples_77_blackwell_fmha_fp16_test_varlen
    # test_examples_77_blackwell_fmha_fp16_test_local
    # test_examples_77_blackwell_fmha_fp16_test_local_00
    # test_examples_77_blackwell_fmha_fp16_test_local_01
    # test_examples_77_blackwell_fmha_fp16_test_local_02
    # test_examples_77_blackwell_fmha_fp16_test_local_03
    # test_examples_77_blackwell_fmha_fp16_test_local_04
    # test_examples_77_blackwell_fmha_fp16_test_local_05
    # test_examples_77_blackwell_fmha_fp16_test_local_06
    # test_examples_77_blackwell_fmha_fp16_test_local_07
    # test_examples_77_blackwell_fmha_fp16_test_local_08
    # test_examples_77_blackwell_fmha_fp16_test_local_09
    test_examples_77_blackwell_fmha_bwd_fp16_test_varlen
    test_examples_77_blackwell_fmha_bwd_fp16_test_local
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_00
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_01
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_02
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_03
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_04
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_05
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_06
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_07
    test_examples_77_blackwell_fmha_bwd_fp16_test_local_08
)

for test in "${targets[@]}"
do
    echo "Running $test"
    make $test  2>&1 | tee -a ~/cutlass/output.log
done

# Record end time and calculate e2e duration
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "E2E Test Run Completed at: $(date)" | tee -a ~/cutlass/output.log
echo "Total E2E Duration: ${duration} seconds" | tee -a ~/cutlass/output.log

unset CUDA_VISIBLE_DEVICES
unset REF_PRINT_DIFF
