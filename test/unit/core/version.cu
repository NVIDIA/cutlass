/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Unit tests for cutlass/version.h.
*/

#include "../common/cutlass_unit_test.h"

#include "cutlass/version.h"

#include <string>

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(Version, numeric_version) {
  EXPECT_EQ(cutlass::getVersion(), CUTLASS_VERSION);
  EXPECT_EQ(cutlass::getVersionMajor(), uint32_t(CUTLASS_MAJOR));
  EXPECT_EQ(cutlass::getVersionMinor(), uint32_t(CUTLASS_MINOR));
  EXPECT_EQ(cutlass::getVersionPatch(), uint32_t(CUTLASS_PATCH));
  EXPECT_EQ(cutlass::getVersionBuild(), uint32_t(CUTLASS_BUILD + 0));
}

// getVersionString() and getGitRevision() must be derived from the version
// macros (or version_extended.h) rather than unsubstituted "@...@" placeholders.
TEST(Version, version_string_matches_macros) {
  std::string const expected = std::to_string(CUTLASS_MAJOR) + "." +
                               std::to_string(CUTLASS_MINOR) + "." +
                               std::to_string(CUTLASS_PATCH);

  std::string const actual = cutlass::getVersionString();

  EXPECT_EQ(actual.substr(0, expected.size()), expected);
  EXPECT_EQ(actual.find('@'), std::string::npos);
  if (cutlass::getVersionBuild()) {
    EXPECT_EQ(actual, expected + "." + std::to_string(cutlass::getVersionBuild()));
  }
}

TEST(Version, git_revision_has_no_placeholders) {
  EXPECT_EQ(cutlass::getGitRevision().find('@'), std::string::npos);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
