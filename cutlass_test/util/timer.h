/******************************************************************************
 * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

#pragma once

/**
 * \file
 * GPU kernel timer
 */

#include <cuda_runtime.h>

#include <cutlass/util/debug.h>

namespace cutlass {


/******************************************************************************
 * gpu_timer
 ******************************************************************************/

/**
 * GPU event-based timer
 */
struct gpu_timer
{
    cudaEvent_t _start;
    cudaEvent_t _stop;

    gpu_timer()
    {
        CUDA_PERROR_EXIT(cudaEventCreate(&_start));
        CUDA_PERROR_EXIT(cudaEventCreate(&_stop));
    }

    ~gpu_timer()
    {
        CUDA_PERROR_EXIT(cudaEventDestroy(_start));
        CUDA_PERROR_EXIT(cudaEventDestroy(_stop));
    }

    void start()
    {
        CUDA_PERROR_EXIT(cudaEventRecord(_start, 0));
    }

    void stop()
    {
        CUDA_PERROR_EXIT(cudaEventRecord(_stop, 0));
    }

    float elapsed_millis()
    {
        float elapsed = 0.0;
        CUDA_PERROR_EXIT(cudaEventSynchronize(_stop));
        CUDA_PERROR_EXIT(cudaEventElapsedTime(&elapsed, _start, _stop));
        return elapsed;
    }
};


/******************************************************************************
 * sleep_millis
 ******************************************************************************/

#ifdef _WIN32
    #include <windows.h>

    void sleep_millis(unsigned milliseconds)
    {
        Sleep(milliseconds);
    }
#else
    #include <unistd.h>

    void sleep_millis(unsigned milliseconds)
    {
        usleep(milliseconds * 1000); // takes microseconds
    }
#endif


} // namespace cutlass
