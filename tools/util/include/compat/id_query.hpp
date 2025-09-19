/***************************************************************************
 *
 *  Copyright (C) Codeplay Software Ltd.
 *  Copyright (C) 2025 Intel Corporation, All rights reserved.
 *
 *  Part of the LLVM Project, under the Apache License v2.0 with LLVM
 *  Exceptions. See https://llvm.org/LICENSE.txt for license information.
 *  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *  SYCL compatibility extension
 *
 *  id_query.hpp
 *
 *  Description:
 *    id_query functionality for the SYCL compatibility extension
 **************************************************************************/

#pragma once

#include <sycl/ext/oneapi/free_function_queries.hpp>
#include <sycl/nd_item.hpp>

namespace compat {

using sycl::ext::oneapi::this_work_item::get_nd_item;

inline void wg_barrier() { get_nd_item<3>().barrier(); }

namespace local_id {
inline size_t x() { return get_nd_item<3>().get_local_id(2); }
inline size_t y() { return get_nd_item<3>().get_local_id(1); }
inline size_t z() { return get_nd_item<3>().get_local_id(0); }
} // namespace local_id

namespace local_range {
inline size_t x() { return get_nd_item<3>().get_local_range(2); }
inline size_t y() { return get_nd_item<3>().get_local_range(1); }
inline size_t z() { return get_nd_item<3>().get_local_range(0); }
} // namespace local_range

namespace work_group_id {
inline size_t x() { return get_nd_item<3>().get_group(2); }
inline size_t y() { return get_nd_item<3>().get_group(1); }
inline size_t z() { return get_nd_item<3>().get_group(0); }
} // namespace work_group_id

namespace work_group_range {
inline size_t x() { return get_nd_item<3>().get_group_range(2); }
inline size_t y() { return get_nd_item<3>().get_group_range(1); }
inline size_t z() { return get_nd_item<3>().get_group_range(0); }
} // namespace work_group_range

namespace global_range {
inline size_t x() { return get_nd_item<3>().get_global_range(2); }
inline size_t y() { return get_nd_item<3>().get_global_range(1); }
inline size_t z() { return get_nd_item<3>().get_global_range(0); }
} // namespace global_range

namespace global_id {
inline size_t x() { return get_nd_item<3>().get_global_id(2); }
inline size_t y() { return get_nd_item<3>().get_global_id(1); }
inline size_t z() { return get_nd_item<3>().get_global_id(0); }
} // namespace global_id

} // namespace compat
