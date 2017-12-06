#/******************************************************************************
# * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
# *
# * Redistribution and use in source and binary forms, with or without
# * modification, are permitted provided that the following conditions are met:
# *     * Redistributions of source code must retain the above copyright
# *       notice, this list of conditions and the following disclaimer.
# *     * Redistributions in binary form must reproduce the above copyright
# *       notice, this list of conditions and the following disclaimer in the
# *       documentation and/or other materials provided with the distribution.
# *     * Neither the name of the NVIDIA CORPORATION nor the
# *       names of its contributors may be used to endorse or promote products
# *       derived from this software without specific prior written permission.
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
# ******************************************************************************/


#-------------------------------------------------------------------------------
#
# Makefile usage
#
# make <target> sm=<XX[,YY,ZZ,..]> [transpose=<nn*|nt|tn|tt>] [verbose=<0*|1>] [keep=<0*|1>]
#
#   * : default
#
#-------------------------------------------------------------------------------

TEST_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../common.mk


#-------------------------------------------------------------------------------
# Commandline Options
#-------------------------------------------------------------------------------

ifdef transpose
	TRANSPOSE := $(transpose)
else
    TRANSPOSE := nn
endif

# If defined, GEMMs only compiled with specified alignment restrictions on A and B
# matrices. Otherwise, kernels are compiled for all feasible alignment options, and
# the appropriate kernel is selected.
ifdef alignment
	DEFINES += -DGEMM_ALIGNMENT=$(alignment)
endif

# If defined as false, ragged handling can be disabled.
ifdef ragged
	DEFINES += -DGEMM_RAGGED=$(ragged)
endif

#-------------------------------------------------------------------------------
# Include and Library paths
#-------------------------------------------------------------------------------

INC += -I$(TEST_DIR)
INC += -I$(BASE_DIR)

LIBS += -lcublas

#-------------------------------------------------------------------------------
# Preprocessor definitions
#-------------------------------------------------------------------------------

ifeq (nt, $(TRANSPOSE))
	DEFINES += -DTRANSPOSE_B
else ifeq (tn, $(TRANSPOSE))
	DEFINES += -DTRANSPOSE_A

else ifeq (tt, $(TRANSPOSE))
	DEFINES += -DTRANSPOSE_A
	DEFINES += -DTRANSPOSE_B
endif

NVCCFLAGS += -std=c++11


#-------------------------------------------------------------------------------
# Dependency Lists
#-------------------------------------------------------------------------------

DEPS := $(call rwildcard, $(BASE_DIR),*.h) \
        $(call rwildcard, $(BASE_DIR)cgl,*.h) \
        $(BASE_DIR)common.mk \
        $(TEST_DIR)Makefile


ALL :=  sgemm \
        dgemm \
        hgemm \
        igemm


#-------------------------------------------------------------------------------
# make default
#-------------------------------------------------------------------------------

default:


#-------------------------------------------------------------------------------
# make clean
#-------------------------------------------------------------------------------

clean :
	rm -f bin/*
	rm -f *.i* *.cubin *.cu.c *.cudafe* *.fatbin.c *.ptx *.hash *.cu.cpp *.o *.obj* *dlink.* *.res *.fatbin *.module_id


#-------------------------------------------------------------------------------
# make all
#-------------------------------------------------------------------------------

all : $(ALL)


#-------------------------------------------------------------------------------
# make sgemm
#-------------------------------------------------------------------------------

sgemm: bin/sgemm_$(TRANSPOSE)_$(BIN_SUFFIX)

bin/sgemm_$(TRANSPOSE)_$(BIN_SUFFIX) : gemm.cu $(DEPS)
	mkdir -p bin
	$(NVCC) -DTEST_SGEMM $(DEFINES) $(SM_TARGETS) -o $@ gemm.cu $(NVCCFLAGS) $(CPU_ARCH) $(INC) $(LIBINC) $(LIBS)

#-------------------------------------------------------------------------------
# make dgemm
#-------------------------------------------------------------------------------

dgemm: bin/dgemm_$(TRANSPOSE)_$(BIN_SUFFIX)

bin/dgemm_$(TRANSPOSE)_$(BIN_SUFFIX) : gemm.cu $(DEPS)
	mkdir -p bin
	$(NVCC) -DTEST_DGEMM $(DEFINES) $(SM_TARGETS) -o $@ gemm.cu $(NVCCFLAGS) $(CPU_ARCH) $(INC) $(LIBINC) $(LIBS)

#-------------------------------------------------------------------------------
# make hgemm
#-------------------------------------------------------------------------------

hgemm: bin/hgemm_$(TRANSPOSE)_$(BIN_SUFFIX)

bin/hgemm_$(TRANSPOSE)_$(BIN_SUFFIX) : gemm.cu $(DEPS)
	mkdir -p bin
	$(NVCC) -DTEST_HGEMM $(DEFINES) $(SM_TARGETS) -o $@ gemm.cu $(NVCCFLAGS) $(CPU_ARCH) $(INC) $(LIBINC) $(LIBS)

#-------------------------------------------------------------------------------
# make igemm
#-------------------------------------------------------------------------------

igemm: bin/igemm_$(TRANSPOSE)_$(BIN_SUFFIX)

bin/igemm_$(TRANSPOSE)_$(BIN_SUFFIX) : gemm.cu $(DEPS)
	mkdir -p bin
	$(NVCC) -DTEST_IGEMM $(DEFINES) $(SM_TARGETS) -o $@ gemm.cu $(NVCCFLAGS) $(CPU_ARCH) $(INC) $(LIBINC) $(LIBS)

#-------------------------------------------------------------------------------
# make wgemm
#-------------------------------------------------------------------------------

wgemm: bin/wgemm_$(TRANSPOSE)_$(BIN_SUFFIX)

bin/wgemm_$(TRANSPOSE)_$(BIN_SUFFIX) : gemm.cu $(DEPS)
	mkdir -p bin
	$(NVCC) -DTEST_WGEMM -DWMMA $(DEFINES) $(SM_TARGETS) -o $@ gemm.cu $(NVCCFLAGS) $(CPU_ARCH) $(INC) $(LIBINC) $(LIBS)

