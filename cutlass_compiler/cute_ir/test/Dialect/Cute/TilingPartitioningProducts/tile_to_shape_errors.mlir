// Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// RUN: cute-opt -verify-diagnostics --split-input-file %s

// Tests error cases for `cute.tile_to_shape`'s precondition checks.

// -----

// Operand kind not in Cute_AnyLayoutType — rejected by the ODS-level
// type constraint. Swizzle is a cute type but not a layout.
func.func @bad_operand_swizzle(%sw: !cute.swizzle<"S<3,5,4>">, %b: !cute.shape<"(8,8)">) {
  // expected-error@+1 {{'cute.tile_to_shape' op operand #0 must be}}
  %r = cute.tile_to_shape(%sw, %b)
         : (!cute.swizzle<"S<3,5,4>">, !cute.shape<"(8,8)">) -> !cute.layout<"1:0">
  return
}

// -----

// $order must be static — dynamic leaves are rejected.
func.func @dynamic_order(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(?,?)">) {
  // expected-error @below {{expects static order, but got (?,?)}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(?,?)">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return
}

// -----

// rank($order) must equal rank($shape) — rank-3 order on rank-2 shape
// is rejected.
func.func @order_rank_exceeds_shape(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(1,2,3)">) {
  // expected-error @below {{expects order rank (3) to equal target-shape rank (2)}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(1,2,3)">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return
}

// -----

// rank($order) must equal rank($shape) — rank-1 order on rank-2 shape
// is rejected too.
func.func @order_rank_below_shape(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"1">) {
  // expected-error @below {{expects order rank (1) to equal target-shape rank (2)}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"1">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return
}

// -----

// Block layout rank must be ≤ target shape rank.
func.func @block_rank_exceeds_shape(
    %a: !cute.layout<"(2,3,4):(1,2,6)">,
    %b: !cute.shape<"(8,12)">) {
  // expected-error @below {{expects block layout rank <= target shape rank, but got rank 3 block and rank 2 target shape}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(2,3,4):(1,2,6)">, !cute.shape<"(8,12)">)
        -> !cute.layout<"((2,4),(3,4)):((1,16),(2,48))">
  return
}

// -----

// Dyn block.
func.func @dyn_block(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.shape<"(6,8)">) {
  // expected-error @below {{expects valid operands, but cannot compute tile_to_shape for '!cute.layout<"(?,?):(?,?)">' and '!cute.shape<"(6,8)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  return
}

// -----

// $order must be a permutation of [0, rank($shape)) — duplicate index 0
// is rejected.
func.func @order_duplicate(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(0,0)">) {
  // expected-error @below {{expects $order to be a permutation of [0, 2), but index 0 appears more than once}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(0,0)">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return
}

// -----

// Out-of-range index 5 on a rank-2 shape is rejected.
func.func @order_out_of_range(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(0,5)">) {
  // expected-error @below {{expects $order to be a permutation of [0, 2), but got out-of-range index 5 at mode 1}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(0,5)">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return
}

// -----

// 1-based order indexing is a common mistake.
func.func @order_not_zero_based(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(1,2)">) {
  // expected-error @below {{expects $order to be a permutation of [0, 2), but got out-of-range index 2 at mode 1}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(1,2)">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return
}

// -----

// Insufficient modes.
func.func @tts_err_insufficient_modes(
    %a: !cute.layout<"(8,64):(64,1)">,
    %b: !cute.shape<"((64,1))">) {
  // expected-error @below {{expects block layout rank <= target shape rank, but got rank 2 block and rank 1 target shape}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"((64,1))">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return
}
