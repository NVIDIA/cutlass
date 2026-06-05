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

# Default mode
MODE="wheel"
REQUIREMENTS_FILE="requirements.txt"

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --editable|-e)
            MODE="editable"
            shift
            ;;
        --cu12)
            REQUIREMENTS_FILE="requirements.txt"
            shift
            ;;
        --cu13)
            REQUIREMENTS_FILE="requirements-cu13.txt"
            shift
            ;;
        --help|-h)
            echo "CUTLASS IR Python DSL Setup Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --editable    Install in editable/development mode"
            echo "  --cu12            Use CUDA 12 requirements (default)"
            echo "  --cu13            Use CUDA 13 requirements"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  # Install from wheel (CUDA 12)"
            echo "  $0"
            echo ""
            echo "  # Install from wheel (CUDA 13)"
            echo "  $0 --cu13"
            echo ""
            echo "  # Install in editable mode (requires CUTLASS_IR_BUILD_DIR)"
            echo "  export CUTLASS_IR_BUILD_DIR=/path/to/build"
            echo "  $0 --editable"
            echo ""
            echo "  # Install in editable mode with CUDA 13 dev deps"
            echo "  export CUTLASS_IR_BUILD_DIR=../../../build"
            echo "  $0 --editable --cu13"
            echo ""
            echo "For more details on editable install, see README.md"
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$MODE" = "editable" ]; then
    echo "====================================================================="
    echo "Installing CUTLASS IR Python DSL in EDITABLE mode"
    echo "====================================================================="
    echo ""

    # Check if CUTLASS_IR_BUILD_DIR is set
    if [ -z "$CUTLASS_IR_BUILD_DIR" ]; then
        echo "ERROR: CUTLASS_IR_BUILD_DIR environment variable is required for editable install"
        echo ""
        echo "Please set it to your CMake build directory:"
        echo "  export CUTLASS_IR_BUILD_DIR=/path/to/build"
        echo ""
        echo "Or use a relative path:"
        echo "  export CUTLASS_IR_BUILD_DIR=../../../build"
        echo ""
        echo "Then run this script again."
        exit 1
    fi

    echo "Build directory: $CUTLASS_IR_BUILD_DIR"
    echo ""

    # Install in editable mode with dev dependencies
    echo "Installing with dev dependencies..."
    pip install -e ".[dev]"

    echo ""
    echo "====================================================================="
    echo "Editable installation complete!"
    echo "====================================================================="
    echo ""
    echo "You can now import cutlass from anywhere:"
    echo "  python -c 'import cutlass; print(cutlass.__version__)'"
    echo ""
    echo "Runtime environment (CUTE_DSL_LIBS) is automatically configured."
    echo "Changes to Python code will be immediately available without reinstall."
    echo ""
    echo "See README.md for development workflow details."

else
    # Wheel installation mode
    echo "Installing CUTLASS IR Python DSL from wheel"
    echo ""

    # Check if requirements file exists
    REQUIREMENTS_PATH="${SCRIPT_DIR}/${REQUIREMENTS_FILE}"
    if [ ! -f "$REQUIREMENTS_PATH" ]; then
        echo "Error: Requirements file not found: $REQUIREMENTS_PATH"
        exit 1
    fi

    # Install requirements
    echo "Installing from: $REQUIREMENTS_FILE"
    pip install -r "$REQUIREMENTS_PATH"

    echo ""
    echo "Installation complete!"
fi
