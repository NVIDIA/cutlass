/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Templates exposing warp matrix multiply-add (WMMA) operations
*/
#pragma once

#include "cutlass/arch/wmma.h"

namespace cutlass {
namespace arch {

/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  WMMA structures to enclose * PTX * instruction string 
///
/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////
/// WMMA PTX string load for A, B, and C matrices 
/////////////////////////////////////////////////////////////////////////////////////////////////
template <  
  typename Shape_,                          ///< Size of the matrix product (concept: GemmShape)
  typename Element_,                        ///< Data type of elements 
  typename Layout_,                         ///< Layout of matrix (concept: MatrixLayout)
  MemoryKind Memory = MemoryKind::kShared   ///< Data resides in shared or global memory
>
struct PtxWmmaLoadA;
/////////////////////////////////////////////////////////////////////////////////////////////////

template <  
  typename Shape_,                          ///< Size of the matrix product (concept: GemmShape)
  typename Element_,                        ///< Data type of elements 
  typename Layout_,                         ///< Layout of matrix (concept: MatrixLayout)
  MemoryKind Memory = MemoryKind::kShared   ///< Data resides in shared or global memory
>
struct PtxWmmaLoadB;
/////////////////////////////////////////////////////////////////////////////////////////////////

template <  
  typename Shape_,                          ///< Size of the matrix product (concept: GemmShape)
  typename Element_,                        ///< Data type of elements 
  typename Layout_,                         ///< Layout of matrix (concept: MatrixLayout)
  MemoryKind Memory = MemoryKind::kShared   ///< Data resides in shared or global memory
>
struct PtxWmmaLoadC;
/////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////////////
/// WMMA Matrix multiply-add operation
/////////////////////////////////////////////////////////////////////////////////////////////////
template <  
  typename Shape_,                                   ///< Size of the matrix product (concept: GemmShape)
  typename ElementA_,                                ///< Data type of A elements 
  typename LayoutA_,                                 ///< Layout of A matrix (concept: MatrixLayout)  
  typename ElementB_,                                ///< Data type of B elements
  typename LayoutB_,                                 ///< Layout of B matrix (concept: MatrixLayout)  
  typename ElementC_,                                ///< Element type of C matrix  
  typename LayoutC_,                                 /// Layout of C matrix (concept: MatrixLayout)
  typename Operator = cutlass::arch::OpMultiplyAdd   ///< Inner product operator (multiply-add, xor.popc)
>
struct PtxWmma;
/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////
/// WMMA store for matrix D
/////////////////////////////////////////////////////////////////////////////////////////////////
template <  
  typename Shape_,                          ///< Size of the matrix product (concept: GemmShape)
  typename Element_,                        ///< Data type of elements 
  typename Layout_,                         ///< Layout of matrix (concept: MatrixLayout)
  MemoryKind Memory = MemoryKind::kShared   ///< Data resides in shared or global memory
>
struct PtxWmmaStoreD;
/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace arch
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
