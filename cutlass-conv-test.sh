#!/bin/bash
# Usage:
#   ./cutlass-conv-test.sh                sync, build, and run conv2d example on batuk0105win64
#   ./cutlass-conv-test.sh sync           sync repo only
#   ./cutlass-conv-test.sh build          build only
#   ./cutlass-conv-test.sh run            run only
#   ./cutlass-conv-test.sh full           sync + build + run (default)
#
# How syncing works:
#   1. Commits any uncommitted local changes (temp commit)
#   2. Pushes to your fork on GitHub
#   3. Remote machine pulls from your fork
#
# Prerequisites:
#   - SSH access to batuk0105win64 on port 2112 as chrisz
#   - CUDA toolkit + CMake + MSVC installed on remote machine
#   - First run: you'll need to enter your password for each SSH command
#     (or set up key-based auth to avoid this)

set -e

MODE="${1:-full}"
REMOTE_HOST="batuk0105win64"
REMOTE_PORT="2112"
REMOTE_USER="chrisz"
REMOTE_DIR="C:/Users/chrisz/cutlass"
FORK_URL="https://github.com/chrisXYZhang/cutlass.git"
SSH="ssh -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TARGET="cute_tutorial_conv2d_fprop_tma_sm90"
VCVARS="\"C:\\Program Files\\Microsoft Visual Studio\\2022\\Professional\\VC\\Auxiliary\\Build\\vcvars64.bat\""

sync_repo() {
  echo "=== Syncing repo to $REMOTE_HOST via git... ==="

  cd "$SCRIPT_DIR"
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "  Local changes detected — creating temp commit..."
    git add -A
    git commit -m "WIP: temp commit for remote testing" --no-verify
  fi
  echo "  Pushing $BRANCH to origin..."
  git push origin "$BRANCH" --quiet

  # Clone or pull on remote Windows machine (PowerShell)
  $SSH "\$env:Path += ';C:\Program Files\Git\cmd'; if (Test-Path $REMOTE_DIR/.git) { cd $REMOTE_DIR; git fetch origin; git checkout $BRANCH; git reset --hard origin/$BRANCH } else { git clone --branch $BRANCH $FORK_URL $REMOTE_DIR }"

  echo "=== Sync complete ==="
}

build_cutlass() {
  echo "=== Creating build script on $REMOTE_HOST... ==="
  # Write a batch file on the remote machine, then execute it
  $SSH "Set-Content -Path $REMOTE_DIR/build_conv.bat -Value @'
@echo off
call \"C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat\"
set PATH=%PATH%;C:\Program Files\CMake\bin
set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.1
set CudaToolkitDir=%CUDA_PATH%
set PATH=%PATH%;%CUDA_PATH%\bin;C:\Users\chrisz\python312
cd /d $REMOTE_DIR
if not exist build mkdir build
cd build
cmake .. -G \"Visual Studio 17 2022\" -DCMAKE_CUDA_COMPILER=\"%CUDA_PATH%/bin/nvcc.exe\" -DCUDAToolkit_ROOT=\"%CUDA_PATH%\" -DCUTLASS_NVCC_ARCHS=90a -DCUTLASS_ENABLE_EXAMPLES=ON -DCUTLASS_ENABLE_TESTS=OFF -DCUTLASS_ENABLE_TOOLS=ON -DCUTLASS_ENABLE_LIBRARY=OFF
cmake --build . --target $TARGET --config Release -j
'@"

  echo "=== Building $TARGET on $REMOTE_HOST... ==="
  $SSH "cmd /c $REMOTE_DIR/build_conv.bat"
  echo "=== Build complete ==="
}

run_example() {
  echo "=== Running $TARGET on $REMOTE_HOST... ==="
  $SSH "cd $REMOTE_DIR/build; nvidia-smi; \$env:CUDA_VISIBLE_DEVICES='1'; ./examples/cute/tutorial/hopper/Release/$TARGET.exe"
  echo "=== Run complete ==="
}

case "$MODE" in
  sync)
    sync_repo
    ;;
  build)
    build_cutlass
    ;;
  run)
    run_example
    ;;
  full|*)
    sync_repo
    build_cutlass
    run_example
    ;;
esac
