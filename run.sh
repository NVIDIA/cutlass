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
    test_examples_77_blackwell_fmha_bwd_fp16_test_basic
    test_examples_77_blackwell_fmha_bwd_fp16_test_varlen
)

for test in "${targets[@]}"
do
    echo "Running $test"
    make $test  2>&1 | tee -a ~/cutlass/output.log
    echo "Running compute sanitizer $test"
    compute-sanitizer make $test  2>&1 | tee -a ~/cutlass/output.log
    echo "Running compute sanitizer memcheck $test"
    compute-sanitizer  --tool=memcheck make $test  2>&1 | tee -a ~/cutlass/output.log
    echo "Running compute sanitizer racecheck $test"
    compute-sanitizer  --tool=racecheck make $test  2>&1 | tee -a ~/cutlass/output.log
    echo "Running compute sanitizer synccheck $test"
    compute-sanitizer  --tool=synccheck make $test  2>&1 | tee -a ~/cutlass/output.log
done

# Record end time and calculate e2e duration
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "E2E Test Run Completed at: $(date)" | tee -a ~/cutlass/output.log
echo "Total E2E Duration: ${duration} seconds" | tee -a ~/cutlass/output.log

unset CUDA_VISIBLE_DEVICES
unset REF_PRINT_DIFF
