/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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
/* \file
   \brief 
*/

#include "device_context.h"

namespace cutlass {
namespace profiler {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Allocates memory of a given type, capacity (elements), and name
DeviceAllocation *DeviceContext::allocate_block(
  std::string const &name,
  library::NumericTypeID type, 
  size_t capacity) {

  device_memory_.emplace_back(type, capacity);
  DeviceAllocation *allocation = &device_memory_.back();
  
  allocations_[name] = allocation;
  return allocation;
}

/// Allocates memory of a given type, capacity (elements), and name
DeviceAllocation *DeviceContext::allocate_tensor(
  std::string const &name,
  library::NumericTypeID type, 
  library::LayoutTypeID layout_id, 
  std::vector<int> const &extent, 
  std::vector<int> const &stride) {

  device_memory_.emplace_back(type, layout_id, extent, stride);
  DeviceAllocation *allocation = &device_memory_.back();
  
  allocations_[name] = allocation;
  return allocation;
}

/// Allocates memory of a given type, capacity (elements), and name
DeviceAllocation *DeviceContext::allocate_tensor(
  Options const &options,
  std::string const &name,
  library::NumericTypeID type, 
  library::LayoutTypeID layout_id, 
  std::vector<int> const &extent, 
  std::vector<int> const &stride) {

  DeviceAllocation *allocation = 
    allocate_tensor(name, type, layout_id, extent, stride);

  if (options.initialization.enabled) {
    Distribution data_distribution = options.initialization.data_distribution; 

    // check if data distribution is allowed to change
    if(!options.initialization.fix_data_distribution) {
      // change data distribution based on bit width
      switch(type) {
        case library::NumericTypeID::kB1:
          data_distribution.set_uniform(0, 2, 0);
          break;          
        case library::NumericTypeID::kS8:
          data_distribution.set_uniform(-2, 2, 0);
          break;
        case library::NumericTypeID::kU8:
          data_distribution.set_uniform(0, 4, 0);
          break;
        default: break;
      }
    }

    if (options.initialization.provider == library::Provider::kReferenceDevice) {
      allocation->initialize_random_device(
        options.initialization.seed, 
        data_distribution); 
    }
    else if (options.initialization.provider == library::Provider::kReferenceHost) {
      allocation->initialize_random_host(
        options.initialization.seed, 
        data_distribution);  
    }
  }

  return allocation;
}

/// Clears named allocations (but does not necessarily free memory)
void DeviceContext::clear() {
  allocations_.clear();
}

/// Frees all device memory allocations
void DeviceContext::free() {
  allocations_.clear();
  device_memory_.clear();
}

/// Gets the allocation by name
DeviceAllocation &DeviceContext::at(std::string const &name) {
  return *allocations_.at(name);
}

size_t DeviceContext::size() const {
  return allocations_.size();
}

DeviceContext::AllocationMap::iterator DeviceContext::begin() {
  return allocations_.begin();
}

DeviceContext::AllocationMap::iterator DeviceContext::end() {
  return allocations_.end();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass
