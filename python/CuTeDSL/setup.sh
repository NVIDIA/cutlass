#!/bin/bash

#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#################################################################################################

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default to requirements.txt
REQUIREMENTS_FILE="requirements.txt"

# Parse command line arguments
if [ $# -gt 0 ]; then
    case "$1" in
        --cu12)
            REQUIREMENTS_FILE="requirements.txt"
            echo "Installing CUDA 12 requirements..."
            ;;
        --cu13)
            REQUIREMENTS_FILE="requirements-cu13.txt"
            echo "Installing CUDA 13 requirements..."
            ;;
        --help|-h)
            echo "Usage: $0 [--cu12|--cu13]"
            echo "  --cu12    Install requirements for CUDA 12 (default)"
            echo "  --cu13    Install requirements for CUDA 13"
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Usage: $0 [--cu12|--cu13]"
            exit 1
            ;;
    esac
else
    echo "Installing default requirements (CUDA 12)..."
fi

# Check if requirements file exists
REQUIREMENTS_PATH="${SCRIPT_DIR}/${REQUIREMENTS_FILE}"
if [ ! -f "$REQUIREMENTS_PATH" ]; then
    echo "Error: Requirements file not found: $REQUIREMENTS_PATH"
    exit 1
fi

# Uninstall previous version of the CUTLASS DSL
echo "Trying to uninstall previous version of the CUTLASS DSL..."
pip uninstall nvidia-cutlass-dsl nvidia-cutlass-dsl-libs-base nvidia-cutlass-dsl-libs-cu13 -y

# Install requirements
echo "Installing from: $REQUIREMENTS_FILE"
pip install -r "$REQUIREMENTS_PATH"

echo "Installation complete!"
