#/******************************************************************************
# * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
# *
# * Redistribution and use in source and binary forms, with or without
# * modification, are permitted provided that the following conditions are met:
# *	 * Redistributions of source code must retain the above copyright
# *	   notice, this list of conditions and the following disclaimer.
# *	 * Redistributions in binary form must reproduce the above copyright
# *	   notice, this list of conditions and the following disclaimer in the
# *	   documentation and/or other materials provided with the distribution.
# *	 * Neither the name of the NVIDIA CORPORATION nor the
# *	   names of its contributors may be used to endorse or promote products
# *	   derived from this software without specific prior written permission.
# *
# * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
# * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *
#******************************************************************************/


#-------------------------------------------------------------------------------
# Commandline Options
#-------------------------------------------------------------------------------

# sm=<XX,...> Compute-capability to compile for, e.g., "sm=200,300,350" (SM2.0 by default).

COMMA := ,
ifdef sm
	SM_ARCH := $(subst $(COMMA),-,$(sm))
else
    $(error Please specify SM architecture makefile argument: "sm=XX")
endif

ifeq (70, $(findstring 70, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_70,code=\"sm_70,compute_70\"
endif
ifeq (62, $(findstring 62, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_62,code=\"sm_62,compute_62\"
endif
ifeq (61, $(findstring 61, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_61,code=\"sm_61,compute_61\"
endif
ifeq (60, $(findstring 60, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_60,code=\"sm_60,compute_60\"
endif
ifeq (52, $(findstring 52, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_52,code=\"sm_52,compute_52\"
endif
ifeq (37, $(findstring 37, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_37,code=\"sm_37,compute_37\"
endif
ifeq (35, $(findstring 35, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_35,code=\"sm_35,compute_35\"
endif
ifeq (30, $(findstring 30, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_30,code=\"sm_30,compute_30\"
endif
ifeq (21, $(findstring 21, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_20,code=\"sm_21,compute_20\"
endif
ifeq (20, $(findstring 20, $(SM_ARCH)))
    SM_TARGETS 	+= -gencode=arch=compute_20,code=\"sm_20,compute_20\"
endif


# [verbose=<0|1>] Verbose toolchain output from nvcc option
ifeq ($(verbose), 1)
	NVCCFLAGS += -v
endif


# [keep=<0|1>] Keep intermediate compilation artifacts option
ifeq ($(keep), 1)
	NVCCFLAGS += -keep
endif


# [debug=<0|1>] Generate debug mode code
ifeq ($(debug), 1)
	NVCCFLAGS += -G
endif


#-------------------------------------------------------------------------------
# Compiler and compilation platform
#-------------------------------------------------------------------------------

BASE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

NVCC := "$(shell which nvcc)"
ifdef nvccver
    NVCC_VERSION := $(nvccver)
else
    NVCC_VERSION := $(strip $(shell nvcc --version | grep release | sed 's/.*release //' |  sed 's/,.*//'))
endif

# Detect OS
OSUPPER := $(shell uname -s 2>/dev/null | tr [:lower:] [:upper:])

# Default flags: verbose kernel properties (regs, smem, cmem, etc.); runtimes for compilation phases
NVCCFLAGS += -O3 -Xptxas -v

ifeq (WIN_NT, $(findstring WIN_NT, $(OSUPPER)))
    # For MSVC

    # Enable more warnings and treat as errors
    NVCCFLAGS += -Xcompiler /W3 -Xcompiler /WX

    # Disable excess x86 floating point precision that can lead to results being labeled incorrectly
    NVCCFLAGS += -Xcompiler /fp:strict

	# Compiler
	CC := cl

	# Multithreaded runtime
	NVCCFLAGS += -Xcompiler /MT

	CUDART_CYG := "$(shell dirname $(NVCC))/../lib/x64/cudart.lib"
	CUDART := "$(shell cygpath -w $(CUDART_CYG))"

else
    # For g++

    # Disable excess x86 floating point precision that can lead to results being labeled incorrectly
    #NVCCFLAGS += -Xcompiler -ffloat-store

	# Compiler
    CC := g++

    CUDART := "$(shell dirname $(NVCC))/../lib64/libcudart_static.a"

endif


# Suffix to append to each binary
BIN_SUFFIX := sm$(SM_ARCH)_$(NVCC_VERSION)


#-------------------------------------------------------------------------------
# Function for computing dependency Lists
#-------------------------------------------------------------------------------

rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))


