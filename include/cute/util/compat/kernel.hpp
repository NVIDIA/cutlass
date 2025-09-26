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
 *  kernel.hpp
 *
 *  Description:
 *    kernel functionality for the SYCL compatibility extension.
 **************************************************************************/

// The original source was under the license below:
//==---- kernel.hpp -------------------------------*- C++ -*----------------==//
//
// Copyright (C) Intel Corporation
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// See https://llvm.org/LICENSE.txt for license information.
//
//===----------------------------------------------------------------------===//

#pragma once
#pragma GCC system_header

#ifdef _WIN32
#include <unordered_set>
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#if defined(__has_include) && __has_include(<filesystem>)
#include <filesystem>
#elif defined(__has_include) && __has_include(<experimental/filesystem>)
#include <experimental/filesystem>
#else
#error "SYCLomatic runtime requires C++ filesystem support"
#endif

#include <fstream>
#include <random>

#include <sycl/image.hpp>
#include <sycl/info/info_desc.hpp>
#include <sycl/nd_range.hpp>
#include <sycl/queue.hpp>

namespace compat {

typedef void (*kernel_functor)(sycl::queue &, const sycl::nd_range<3> &,
                               unsigned int, void **, void **);

struct kernel_function_info {
  int max_work_group_size = 0;
};

static inline void get_kernel_function_info(kernel_function_info *kernel_info,
                                            const void *function) {
  kernel_info->max_work_group_size =
      detail::dev_mgr::instance()
          .current_device()
          .get_info<sycl::info::device::max_work_group_size>();
}

static inline kernel_function_info
get_kernel_function_info(const void *function) {
  kernel_function_info kernel_info;
  kernel_info.max_work_group_size =
      detail::dev_mgr::instance()
          .current_device()
          .get_info<sycl::info::device::max_work_group_size>();
  return kernel_info;
}

namespace detail {

#if defined(__has_include) && __has_include(<filesystem>)
namespace fs = std::filesystem;
#else
namespace fs = std::experimental::filesystem;
#endif

/// Write data to temporary file and return absolute path to temporary file.
/// Temporary file is created in a temporary directory both of which have random
/// names with only the user having access permissions.  Only one temporary file
/// will be created in the temporary directory.
static inline fs::path write_data_to_file(char const *const data, size_t size) {
  std::error_code ec;

  if (sizeof(size_t) >= sizeof(std::streamsize) &&
      size > (std::numeric_limits<std::streamsize>::max)())
    throw std::runtime_error("[Compat] data file too large");

  // random number generator
  std::random_device dev;
  std::mt19937 prng(dev());
  std::uniform_int_distribution<uint64_t> rand(0);

  // find temporary directory
  auto tmp_dir = fs::temp_directory_path(ec);
  if (ec)
    throw std::runtime_error("[Compat] could not find temporary directory");

  // create private directory
  std::stringstream directory;
  fs::path directory_path;
  constexpr int max_attempts = 5;
  int i;

  for (i = 0; i < max_attempts; i++) {
    directory << std::hex << rand(prng);
    directory_path = tmp_dir / directory.str();
    if (fs::create_directory(directory_path)) {
      break;
    }
  }
  if (i == max_attempts)
    throw std::runtime_error("[Compat] could not create directory");

  // only allow owner permissions to private directory
  fs::permissions(directory_path, fs::perms::owner_all, ec);
  if (ec)
    throw std::runtime_error(
        "[Compat] could not set directory permissions");

  // random filename in private directory
  std::stringstream filename;
  filename << std::hex << rand(prng);
#ifdef _WIN32
  auto filepath = directory_path / (filename.str() + ".dll");
#else
  auto filepath = directory_path / filename.str();
#endif

  // write data to temporary file
  auto outfile = std::ofstream(filepath, std::ios::out | std::ios::binary);
  if (outfile) {
    // only allow program to write file
    fs::permissions(filepath, fs::perms::owner_write, ec);
    if (ec)
      throw std::runtime_error("[Compat] could not set permissions");

    outfile.write(data, size);
    if (!outfile.good())
      throw std::runtime_error("[Compat] could not write data");
    outfile.close();

    // only allow program to read/execute file
    fs::permissions(filepath, fs::perms::owner_read | fs::perms::owner_exec,
                    ec);
    if (ec)
      throw std::runtime_error("[Compat] could not set permissions");
  } else
    throw std::runtime_error("[Compat] could not write data");

  // check temporary file contents
  auto infile = std::ifstream(filepath, std::ios::in | std::ios::binary);
  if (infile) {
    bool mismatch = false;
    size_t cnt = 0;

    while (1) {
      char c;
      infile.get(c);
      if (infile.eof())
        break;
      if (c != data[cnt++])
        mismatch = true;
    }
    if (cnt != size || mismatch)
      throw std::runtime_error(
          "[Compat] file contents not written correctly");
  } else
    throw std::runtime_error("[Compat] could not validate file");

  if (!filepath.is_absolute())
    throw std::runtime_error("[Compat] temporary filepath is not absolute");

  return filepath;
}

static inline uint16_t extract16(unsigned char const *const ptr) {
  uint16_t ret = 0;

  ret |= static_cast<uint16_t>(ptr[0]) << 0;
  ret |= static_cast<uint16_t>(ptr[1]) << 8;

  return (ret);
}

static inline uint32_t extract32(unsigned char const *const ptr) {
  uint32_t ret = 0;

  ret |= static_cast<uint32_t>(ptr[0]) << 0;
  ret |= static_cast<uint32_t>(ptr[1]) << 8;
  ret |= static_cast<uint32_t>(ptr[2]) << 16;
  ret |= static_cast<uint32_t>(ptr[3]) << 24;

  return (ret);
}

static inline uint64_t extract64(unsigned char const *const ptr) {
  uint64_t ret = 0;

  ret |= static_cast<uint64_t>(ptr[0]) << 0;
  ret |= static_cast<uint64_t>(ptr[1]) << 8;
  ret |= static_cast<uint64_t>(ptr[2]) << 16;
  ret |= static_cast<uint64_t>(ptr[3]) << 24;
  ret |= static_cast<uint64_t>(ptr[4]) << 32;
  ret |= static_cast<uint64_t>(ptr[5]) << 40;
  ret |= static_cast<uint64_t>(ptr[6]) << 48;
  ret |= static_cast<uint64_t>(ptr[7]) << 56;

  return (ret);
}

static inline uint64_t get_lib_size(char const *const blob) {
#ifdef _WIN32
  ///////////////////////////////////////////////////////////////////////
  // Analyze DOS stub
  unsigned char const *const ublob =
      reinterpret_cast<unsigned char const *const>(blob);
  if (ublob[0] != 0x4d || ublob[1] != 0x5a) {
    throw std::runtime_error("[Compat] blob is not a Windows DLL.");
  }
  uint32_t pe_header_offset = extract32(ublob + 0x3c);

  ///////////////////////////////////////////////////////////////////////
  // Ananlyze PE-header
  unsigned char const *const pe_header = ublob + pe_header_offset;

  // signature
  uint32_t pe_signature = extract32(pe_header + 0);
  if (pe_signature != 0x00004550) {
    throw std::runtime_error(
        "[Compat] PE-header signature is not 0x00004550");
  }

  // machine
  uint16_t machine = extract16(pe_header + 4);
  if (machine != 0x8664) {
    throw std::runtime_error("[Compat] only DLLs for x64 supported");
  }

  // number of sections
  uint16_t number_of_sections = extract16(pe_header + 6);

  // sizeof optional header
  uint16_t sizeof_optional_header = extract16(pe_header + 20);

  // magic
  uint16_t magic = extract16(pe_header + 24);
  if (magic != 0x10b && magic != 0x20b) {
    throw std::runtime_error("[Compat] MAGIC is not 0x010b or 0x020b");
  }

  ///////////////////////////////////////////////////////////////////////
  // Analyze tail of optional header
  constexpr int coff_header_size = 24;

  unsigned char const *const tail_of_optional_header =
      pe_header + coff_header_size + sizeof_optional_header;
  if (extract64(tail_of_optional_header - 8) != 0) {
    throw std::runtime_error("Optional header not zero-padded");
  }

  ///////////////////////////////////////////////////////////////////////
  // Analyze last section header
  constexpr int section_header_size = 40;
  unsigned char const *const last_section_header =
      tail_of_optional_header + section_header_size * (number_of_sections - 1);

  uint32_t sizeof_raw_data = extract32(last_section_header + 16);
  uint32_t pointer_to_raw_data = extract32(last_section_header + 20);

  return sizeof_raw_data + pointer_to_raw_data;
#else
  if (blob[0] != 0x7F || blob[1] != 'E' || blob[2] != 'L' || blob[3] != 'F')
    throw std::runtime_error("[Compat] blob is not in ELF format");

  if (blob[4] != 0x02)
    throw std::runtime_error("[Compat] only 64-bit headers are supported");

  if (blob[5] != 0x01)
    throw std::runtime_error(
        "[Compat] only little-endian headers are supported");

  unsigned char const *const ublob =
      reinterpret_cast<unsigned char const *const>(blob);
  uint64_t e_shoff = extract64(ublob + 0x28);
  uint16_t e_shentsize = extract16(ublob + 0x3A);
  uint16_t e_shnum = extract16(ublob + 0x3C);

  return e_shoff + (e_shentsize * e_shnum);
#endif
}

#ifdef _WIN32
class path_lib_record {
public:
  void operator=(const path_lib_record &) = delete;
  ~path_lib_record() {
    for (auto entry : lib_to_path) {
      FreeLibrary(static_cast<HMODULE>(entry.first));
      fs::permissions(entry.second, fs::perms::owner_all);
      fs::remove_all(entry.second.remove_filename());
    }
  }
  static void record_lib_path(fs::path path, void *library) {
    lib_to_path[library] = path;
  }
  static void remove_lib(void *library) {
    auto path = lib_to_path[library];
    std::error_code ec;

    FreeLibrary(static_cast<HMODULE>(library));
    fs::permissions(path, fs::perms::owner_all);
    if (fs::remove_all(path.remove_filename(), ec) != 2 || ec)
      // one directory and one temporary file should have been deleted
      throw std::runtime_error("[Compat] directory delete failed");

    lib_to_path.erase(library);
  }

private:
  static inline std::unordered_map<void *, fs::path> lib_to_path;
};
#endif

} // namespace detail

class kernel_library {
public:
  constexpr kernel_library() : ptr{nullptr} {}
  constexpr kernel_library(void *ptr) : ptr{ptr} {}

  operator void *() const { return ptr; }

private:
  void *ptr;
#ifdef _WIN32
  static inline detail::path_lib_record single_instance_to_trigger_destructor;
#endif
};

namespace detail {

static inline kernel_library load_dl_from_data(char const *const data,
                                               size_t size) {
  fs::path filename = write_data_to_file(data, size);
#ifdef _WIN32
  void *so = LoadLibraryW(filename.wstring().c_str());
#else
  void *so = dlopen(filename.c_str(), RTLD_LAZY);
#endif
  if (so == nullptr)
    throw std::runtime_error("[Compat] failed to load kernel library");

#ifdef _WIN32
  detail::path_lib_record::record_lib_path(filename, so);
#else
  std::error_code ec;

  // Windows DLL cannot be deleted while in use
  if (fs::remove_all(filename.remove_filename(), ec) != 2 || ec)
    // one directory and one temporary file should have been deleted
    throw std::runtime_error("[Compat] directory delete failed");
#endif

  return so;
}

} // namespace detail

/// Load kernel library and return a handle to use the library.
/// \param [in] name The name of the library.
static inline kernel_library load_kernel_library(const std::string &name) {
  std::ifstream ifs;
  ifs.open(name, std::ios::in | std::ios::binary);

  std::stringstream buffer;
  buffer << ifs.rdbuf();

  const std::string buffer_string = buffer.str();
  return detail::load_dl_from_data(buffer_string.c_str(), buffer_string.size());
}

/// Load kernel library whose image is alreay in memory and return a handle to
/// use the library.
/// \param [in] image A pointer to the image in memory.
static inline kernel_library load_kernel_library_mem(char const *const image) {
  const size_t size = detail::get_lib_size(image);

  return detail::load_dl_from_data(image, size);
}

/// Unload kernel library.
/// \param [in,out] library Handle to the library to be closed.
static inline void unload_kernel_library(const kernel_library &library) {
#ifdef _WIN32
  detail::path_lib_record::remove_lib(library);
#else
  dlclose(library);
#endif
}

class kernel_function {
public:
  constexpr kernel_function() : ptr{nullptr} {}
  constexpr kernel_function(kernel_functor ptr) : ptr{ptr} {}

  operator void *() const { return ((void *)ptr); }

  void operator()(sycl::queue &q, const sycl::nd_range<3> &range,
                  unsigned int local_mem_size, void **args, void **extra) {
    ptr(q, range, local_mem_size, args, extra);
  }

private:
  kernel_functor ptr;
};

/// Find kernel function in a kernel library and return its address.
/// \param [in] library Handle to the kernel library.
/// \param [in] name Name of the kernel function.
static inline kernel_function get_kernel_function(kernel_library &library,
                                                  const std::string &name) {
#ifdef _WIN32
  kernel_functor fn = reinterpret_cast<kernel_functor>(
      GetProcAddress(static_cast<HMODULE>(static_cast<void *>(library)),
                     (name + std::string("_wrapper")).c_str()));
#else
  kernel_functor fn = reinterpret_cast<kernel_functor>(
      dlsym(library, (name + std::string("_wrapper")).c_str()));
#endif
  if (fn == nullptr)
    throw std::runtime_error("[Compat] failed to get function");
  return fn;
}

/// Invoke a kernel function.
/// \param [in] function kernel function.
/// \param [in] queue SYCL queue used to execute kernel
/// \param [in] group_range SYCL group range
/// \param [in] local_range SYCL local range
/// \param [in] local_mem_size The size of local memory required by the kernel
///             function.
/// \param [in] kernel_params Array of pointers to kernel arguments.
/// \param [in] extra Extra arguments.
static inline void invoke_kernel_function(kernel_function &function,
                                          sycl::queue &queue,
                                          sycl::range<3> group_range,
                                          sycl::range<3> local_range,
                                          unsigned int local_mem_size,
                                          void **kernel_params, void **extra) {
  function(queue, sycl::nd_range<3>(group_range * local_range, local_range),
           local_mem_size, kernel_params, extra);
}

} // namespace compat
