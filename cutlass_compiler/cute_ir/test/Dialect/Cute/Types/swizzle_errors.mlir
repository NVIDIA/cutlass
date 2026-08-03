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

// RUN: cute-opt %s -split-input-file -verify-diagnostics

// Negative tests for !cute.swizzle type parser.

// -----

// Missing string argument.
// expected-error@+1 {{expected string}}
func.func @missing_string(%a: !cute.swizzle<32>) {
  return
}

// -----

// Completely unparseable string.
// expected-error@+1 {{failed to parse swizzle from "not_valid"}}
func.func @bad_string(%a: !cute.swizzle<"not_valid">) {
  return
}

// -----

// Empty string.
// expected-error@+1 {{failed to parse swizzle from ""}}
func.func @empty_string(%a: !cute.swizzle<"">) {
  return
}

// -----

// Too few parameters — S<bits,base> is missing shift.
// expected-error@+1 {{failed to parse swizzle from "S<1,0>"}}
func.func @missing_shift(%a: !cute.swizzle<"S<1,0>">) {
  return
}

// -----

// Invariant #1: `|num_shift| + num_bits + num_base <= 32`.
//   `S<5,29,5>`     → 5 + 29 + 5 = 39 > 32 — overflows working width.
//   `S<10,20,10>`   → 10 + 20 + 10 = 40 > 32 — overflows working width.
//
// Invariant #2: `|num_shift| >= num_bits`.
//   `S<3,4,2>`      → |shift|=2 < bits=3 — mask wider than shift.
//   `S<5,0,1>`      → |shift|=1 < bits=5 — mask wider than shift.
//   `S<3,4,-2>`     → |shift|=2 < bits=3 — same as #3 with negative shift.

// expected-error@+1 {{failed to parse swizzle from "S<5,29,5>"}}
func.func @sum_overflow_5_29_5(%a: !cute.swizzle<"S<5,29,5>">) {
  return
}

// -----

// expected-error@+1 {{failed to parse swizzle from "S<10,20,10>"}}
func.func @sum_overflow_10_20_10(%a: !cute.swizzle<"S<10,20,10>">) {
  return
}

// -----

// expected-error@+1 {{failed to parse swizzle from "S<3,4,2>"}}
func.func @shift_lt_bits_3_4_2(%a: !cute.swizzle<"S<3,4,2>">) {
  return
}

// -----

// expected-error@+1 {{failed to parse swizzle from "S<5,0,1>"}}
func.func @shift_lt_bits_5_0_1(%a: !cute.swizzle<"S<5,0,1>">) {
  return
}

// -----

// expected-error@+1 {{failed to parse swizzle from "S<3,4,-2>"}}
func.func @shift_lt_bits_neg_shift(%a: !cute.swizzle<"S<3,4,-2>">) {
  return
}
