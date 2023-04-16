#################################################################################################
#
# Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#################################################################################################

"""
Utilities for generating source for building a PyTorch CUDA extension that using a CUTLASS kernel.
If specified, the extension can be JIT compiled via PyTorch's ``cpp_extension.load`` method.

Example usage with JIT compilation:

.. highlight:: python
.. code-block:: python

    plan = cutlass.op.Gemm(element=torch.float32, layout=cutlass.LayoutType.RowMajor)
    op = plan.construct()
    mod = cutlass.emit.pytorch(op, 'cutlass_gemm', 80, jit=True)

    # Generate inputs for the GEMM
    A, B, C = [torch.ones((512, 512)).to('cuda') for _ in range(3)]

    # Run the module
    D = mod.run(A, B, C)


Example usage without JIT compilation:

.. highlight:: python
.. code-block:: python

    plan = cutlass.op.Gemm(element=torch.float32, layout=cutlass.LayoutType.RowMajor)
    op = plan.construct()
    cutlass.emit.pytorch(op, 'cutlass_gemm', 80, jit=False, sourcedir='output')

After this call, the directory ``output`` contains ``setup.py``,
``cutlass_gemm.cpp``, and ``cutlass_gemm_kernel.cu``. The module can be built from
within ``output`` by running: ``TORCH_CUDA_ARCH_LIST="8.0" python setup.py develop --user``.

The module can later be used in Python via:

.. highlight:: python
.. code-block:: python

    import torch
    import cutlass_gemm

    # Generate inputs for the GEMM
    A, B, C = [torch.ones((512, 512)).to('cuda') for _ in range(3)]

    # Run the module
    D = cutlass_gemm.run(A, B, C)
"""

import logging
import os

import cutlass_bindings

from cutlass import CUTLASS_PATH, logger, swizzle
from cutlass.backend.gemm_operation import GemmOperationGrouped, GemmOperationUniversal
from cutlass.backend.library import ApiVersion
from cutlass.backend.utils.software import CheckPackages, SubstituteTemplate
from cutlass.emit import common

torch_available = CheckPackages().check_torch()
if torch_available:
    import torch


_PYTORCH_CUDA_TEMPLATE = common._CSTYLE_AUTOGEN_COMMENT + """
#include <torch/extension.h>
#include <ATen/ATen.h>

#include "cutlass/cutlass.h"
#include "cutlass/util/device_memory.h"

${includes}
${declaration}
${impl}
"""

_PYTORCH_GEMM_CPP_TEMPLATE = common._CSTYLE_AUTOGEN_COMMENT + """
#include <torch/extension.h>
#include <ATen/ATen.h>
#include <pybind11/stl.h>

// CUDA forward declarations
at::Tensor ${name}_kernel(const at::Tensor& A, const at::Tensor& B, at::optional<const at::Tensor> C=at::nullopt, float alpha=1.f, float beta=0.f);

// C++ interface
at::Tensor ${name}(const at::Tensor& A, const at::Tensor& B, at::optional<const at::Tensor> C=at::nullopt, float alpha=1.f, float beta=0.f) {
  return ${name}_kernel(A, B, C, alpha, beta);
}

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
  m.def("run", py::overload_cast<const at::Tensor&, const at::Tensor&, at::optional<const at::Tensor>, float, float>(&${name}), py::arg("A"), py::arg("B"), py::arg("C") = nullptr, py::arg("alpha") = 1.f, py::arg("beta") = 0.f);
}
"""

_PYTORCH_GROUPED_GEMM_CPP_TEMPLATE = common._CSTYLE_AUTOGEN_COMMENT + """
#include <torch/extension.h>
#include <ATen/ATen.h>
#include <pybind11/stl.h>

// CUDA forward declarations
std::vector<at::Tensor> ${name}_kernel(const std::vector<at::Tensor>& A, const std::vector<at::Tensor>& B, at::optional<const std::vector<at::Tensor>> C=at::nullopt, float alpha=1.f, float beta=0.f);

// C++ interface
std::vector<at::Tensor> ${name}(const std::vector<at::Tensor>& A, const std::vector<at::Tensor>& B, at::optional<const std::vector<at::Tensor>> C=at::nullopt, float alpha=1.f, float beta=0.f) {
  return ${name}_kernel(A, B, C, alpha, beta);
}

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
  m.def("run", py::overload_cast<const std::vector<at::Tensor>&, const std::vector<at::Tensor>&, at::optional<const std::vector<at::Tensor>>, float, float>(&${name}),
        py::arg("A"), py::arg("B"), py::arg("C") = nullptr, py::arg("alpha") = 1.f, py::arg("beta") = 0.f);
}
"""

_PYTORCH_GEMM_INCLUDES = {
    ApiVersion.v2x: """
#include "cutlass/gemm/device/gemm_universal.h"
""",
    ApiVersion.v3x: """
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/util/packed_stride.hpp"
""",
}

_PYTORCH_GROUPED_GEMM_INCLUDES = """
#include "cutlass/gemm/kernel/default_gemm_grouped.h"
#include "cutlass/gemm/device/gemm_grouped.h"
"""

_CUTLASS_TYPE_TO_TORCH_TYPE = {
    cutlass_bindings.float16: "torch::kF16",
    cutlass_bindings.float32: "torch::kF32",
    cutlass_bindings.float64: "torch::kF64",
    cutlass_bindings.int8: "torch::I8",
    cutlass_bindings.int32: "torch::I32",
}

_PYTORCH_GEMM_IMPL_TEMPLATE_2x = (
    common._CUTLASS_KERNEL_RUN_GEMM_2x
    + """
at::Tensor ${name}_kernel(const at::Tensor& A, const at::Tensor& B, at::optional<const at::Tensor> C, float alpha, float beta) {
    int M = A.size(0);
    int N = B.size(1);
    int K = A.size(1);

    typename DeviceKernel::ElementC* ptrC = (C == at::nullopt) ?
                                            nullptr :
                                            reinterpret_cast<typename DeviceKernel::ElementC*>(C->contiguous().data_ptr());
    at::Tensor D = B.new_empty({M, N}, ${torch_type_C});

    cutlass::Status status = ${name}_kernel_run(M, N, K,
                                                reinterpret_cast<typename DeviceKernel::ElementA*>(A.contiguous().data_ptr()),
                                                reinterpret_cast<typename DeviceKernel::ElementB*>(B.contiguous().data_ptr()),
                                                ptrC,
                                                reinterpret_cast<typename DeviceKernel::ElementC*>(D.contiguous().data_ptr()),
                                                ElementCompute(alpha), ElementCompute(beta));

    TORCH_CHECK(status == cutlass::Status::kSuccess, "CUTLASS kernel failed");
    return D;
}
"""
)

_PYTORCH_GEMM_IMPL_TEMPLATE_3x = (
    common._CUTLASS_KERNEL_RUN_GEMM_3x
    + """
bool hw_info_queried = false;
cutlass::KernelHardwareInfo hw_info;

at::Tensor ${name}_kernel(const at::Tensor& A, const at::Tensor& B, at::optional<const at::Tensor> C, float alpha, float beta) {
    int M = A.size(0);
    int N = B.size(1);
    int K = A.size(1);
    int L = 1;

    // Query hardware info if we haven't already
    if (!hw_info_queried) {
        hw_info.device_id = 0;
        hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);
    }

    typename DeviceKernel::ElementC* ptrC = (C == at::nullopt) ?
                                            nullptr :
                                            reinterpret_cast<typename DeviceKernel::ElementC*>(C->contiguous().data_ptr());
    at::Tensor D = B.new_empty({M, N}, ${torch_type_C});

    cutlass::Status status = ${name}_kernel_run(M, N, K, L,
                                                reinterpret_cast<typename DeviceKernel::ElementA*>(A.contiguous().data_ptr()),
                                                reinterpret_cast<typename DeviceKernel::ElementB*>(B.contiguous().data_ptr()),
                                                ptrC,
                                                reinterpret_cast<typename DeviceKernel::ElementC*>(D.contiguous().data_ptr()),
                                                ElementCompute(alpha), ElementCompute(beta),
                                                hw_info);

    TORCH_CHECK(status == cutlass::Status::kSuccess, "CUTLASS kernel failed");
    return D;
}
"""
)


_PYTORCH_GROUPED_GEMM_IMPL_TEMPLATE = (
    common._CUTLASS_KERNEL_RUN_GROUPED_GEMM_2x
    + """
std::vector<at::Tensor> ${name}_kernel(const std::vector<at::Tensor>& A, const std::vector<at::Tensor>& B, at::optional<const std::vector<at::Tensor>> C, float alpha, float beta) {
    size_t num = A.size();

    // To avoid performing many small cudaMallocs and host-to-device copies,
    // we serialize the grouped GEMM arguments on the host, allocate one
    // large chunk of device memory, and perform a single cudaMemcpy to
    // copy the host data to the device. Allocation overheads could be
    // avoided by using a memory pool.

    // Calculate the total size of the data to be copied from host to device
    size_t total_size = sizeof(cutlass::gemm::GemmCoord) +
                        sizeof(DeviceKernel::ElementA*) +
                        sizeof(DeviceKernel::ElementB*) +
                        sizeof(DeviceKernel::ElementC*) +
                        sizeof(DeviceKernel::ElementC*) +
                        sizeof(int64_t) +
                        sizeof(int64_t) +
                        sizeof(int64_t);
    total_size *= num;

    // num * sizeof(cutlass::gemm::GemmCoord) may leave one at a non-multiple
    // of sizeof(DeviceKernel::ElementA*) (which will be 64 on a 64-bit system).
    // To ensure that we don't end up having misaligned loads in the kernel,
    // we pad to the nearest multiple of 8.
    //
    // Note that, even on a 32-bit system (for which sizeof(X*) will not equal
    // sizeof(int64_t)), only padding between the list of GemmCoords and the
    // list of ptr_As is sufficient because the set of four equal-length lists of pointers
    // (A*, B*, C*, D*) will ensure that the first list of int64_ts will always
    // start on a multiple of 8.
    int64_t padding = 8 - (total_size % 8);
    total_size += padding;

    uint8_t* host_data = new uint8_t[total_size];
    cutlass::DeviceAllocation<uint8_t> device_data(total_size);

    uint8_t* start = host_data;
    cutlass::gemm::GemmCoord* problem_sizes_host = reinterpret_cast<cutlass::gemm::GemmCoord*>(start);

    // Apply the padding after the list of GemmCoords
    start += num * sizeof(cutlass::gemm::GemmCoord) + padding;

    int64_t ptr_A_offset = start - host_data;
    DeviceKernel::ElementA** ptr_A_host = reinterpret_cast<DeviceKernel::ElementA**>(start);
    start += num * sizeof(DeviceKernel::ElementA*);

    int64_t ptr_B_offset = start - host_data;
    DeviceKernel::ElementB** ptr_B_host = reinterpret_cast<DeviceKernel::ElementB**>(start);
    start += num * sizeof(DeviceKernel::ElementB*);

    int64_t ptr_C_offset = start - host_data;
    DeviceKernel::ElementC** ptr_C_host = reinterpret_cast<DeviceKernel::ElementC**>(start);
    start += num * sizeof(DeviceKernel::ElementC*);

    int64_t ptr_D_offset = start - host_data;
    DeviceKernel::ElementC** ptr_D_host = reinterpret_cast<DeviceKernel::ElementC**>(start);
    start += num * sizeof(DeviceKernel::ElementC*);

    int64_t lda_offset = start - host_data;
    int64_t* lda_host = reinterpret_cast<int64_t*>(start);
    start += num * sizeof(int64_t);

    int64_t ldb_offset = start - host_data;
    int64_t* ldb_host = reinterpret_cast<int64_t*>(start);
    start += num * sizeof(int64_t);

    int64_t ldc_offset = start - host_data;
    int64_t* ldc_host = reinterpret_cast<int64_t*>(start);
    start += num * sizeof(int64_t);

    std::vector<at::Tensor> D(num);

    bool need_C = (C != at::nullopt) && (beta != 0.f);
    for (size_t i = 0; i < num; ++i) {
        int M = A[i].size(0);
        int N = B[i].size(1);
        int K = A[i].size(1);
        *(problem_sizes_host + i) = {M, N, K};
        *(ptr_A_host + i) = reinterpret_cast<typename DeviceKernel::ElementA*>(A[i].contiguous().data_ptr());
        *(ptr_B_host + i) = reinterpret_cast<typename DeviceKernel::ElementB*>(B[i].contiguous().data_ptr());

        if (need_C) {
            *(ptr_C_host + i) = reinterpret_cast<typename DeviceKernel::ElementC*>(C->at(i).contiguous().data_ptr());
        }
        else {
            *(ptr_C_host + i) = nullptr;
        }

        D[i] = B[i].new_empty({M, N}, ${torch_type_C});
        *(ptr_D_host + i) = reinterpret_cast<typename DeviceKernel::ElementC*>(D[i].contiguous().data_ptr());

        *(lda_host + i) = DeviceKernel::LayoutA::packed({M, K}).stride(0);
        *(ldb_host + i) = DeviceKernel::LayoutB::packed({K, N}).stride(0);
        *(ldc_host + i) = DeviceKernel::LayoutC::packed({M, N}).stride(0);
    }

    device_data.copy_from_host(host_data);

    cutlass::Status status = ${name}_kernel_run(
        num,
        reinterpret_cast<cutlass::gemm::GemmCoord*>(device_data.get()),
        reinterpret_cast<DeviceKernel::ElementA**>(device_data.get() + ptr_A_offset),
        reinterpret_cast<DeviceKernel::ElementB**>(device_data.get() + ptr_B_offset),
        reinterpret_cast<DeviceKernel::ElementC**>(device_data.get() + ptr_C_offset),
        reinterpret_cast<DeviceKernel::ElementC**>(device_data.get() + ptr_D_offset),
        reinterpret_cast<int64_t*>(device_data.get() + lda_offset),
        reinterpret_cast<int64_t*>(device_data.get() + ldb_offset),
        reinterpret_cast<int64_t*>(device_data.get() + ldc_offset),
        reinterpret_cast<int64_t*>(device_data.get() + ldc_offset),
        ElementCompute(alpha), ElementCompute(beta));

    delete[] host_data;

    TORCH_CHECK(status == cutlass::Status::kSuccess, "CUTLASS kernel failed");
    return D;
}
"""
)


_PYTORCH_SETUP_PY = common._PYSTYLE_AUTOGEN_COMMENT + """
from setuptools import setup
from torch.utils.cpp_extension import BuildExtension, CUDAExtension

setup(
    name='${name}',
    ext_modules=[
        CUDAExtension('${name}', [
            '${name}.cpp',
            '${name}_kernel.cu',
        ],
        include_dirs=['${cutlass_path}/include', '${cutlass_path}/tools/util/include'],
        extra_compile_args=['-std=c++17']
        ),
    ],
    cmdclass={
        'build_ext': BuildExtension
    })

"""


def _generate_setup(name: str, sourcedir: str):
    """
    Generates a setup.py file for the extension

    :param name: name of the module to generate
    :type name: str
    :param sourcedir: directory to which generated source files should be written
    :type sourcedir: str
    """
    setup_py_file = os.path.join(sourcedir, "setup.py")
    setup_source = SubstituteTemplate(
        _PYTORCH_SETUP_PY, {"name": name, "cutlass_path": CUTLASS_PATH}
    )
    with open(setup_py_file, "w") as outfile:
        outfile.write(setup_source)


class _ArchListSetter:
    """
    Utility context manager for temporarily setting the value of the ``TORCH_CUDA_ARCH_LIST``
    environment variable when building a PyTorch CUDA module.

    ``TORCH_CUDA_ARCH_LIST`` is a space-delmited list of compute capabilites for which a PyTorch
    CUDA module should be compiled.

    For example, ``TORCH_CUDA_ARCH_LIST="7.0 8.0"`` would result in the inclusion of
    ``-gencode=arch=compute_70,code=sm_70`` and ``-gencode=arch=compute_80,code=sm_80`` in the
    compilation of the module.

    This utility wraps the building of a PyTorch CUDA module with a setting of this environment
    variable according to the current compute capability being targetted.

    Example usage:

    .. highlight:: python
    .. code-block:: python

        # Temporarily set TORCH_CUDA_ARCH_LIST="8.0"
        with _ArchListSetter(80):
            # Perform JIT compilation and loading of the module
            mod = torch.utils.cpp_extension.load(...)

    :param cc: compute capability
    :type cc: int
    """

    _TORCH_CUDA_ARCH_LIST = "TORCH_CUDA_ARCH_LIST"

    def __init__(self, cc: int):
        self.cc_str = ".".join(list(str(cc)))

    def __enter__(self):
        """
        Saves the old value of TORCH_CUDA_ARCH_LIST and reset it to the new value based on ``cc``
        """
        self.old_arch_list = os.getenv(_ArchListSetter._TORCH_CUDA_ARCH_LIST)
        os.environ[_ArchListSetter._TORCH_CUDA_ARCH_LIST] = self.cc_str

        return self

    def __exit__(self, exc_type, exc_val, traceback):
        """
        Restores the old value of TORCH_CUDA_ARCH_LIST
        """
        os.environ[_ArchListSetter._TORCH_CUDA_ARCH_LIST] = self.old_arch_list


def _jit(name: str, cc: int, cpp_file: str, cuda_file: str):
    """
    JIT compiles and loads a PyTorch CUDA extension.

    :param name: name of the module to generate
    :type name: str
    :param cc: compute capability of the device the module should target
    :type cc: int
    :param cpp_file: path to file containing extension's C++ interface
    :type cpp_file: str
    :param cuda_file: path to file containing extension's CUDA interface
    :type cuda_file: str

    :return: loaded PyTorch module
    """

    from torch.utils.cpp_extension import load

    extra_cuda_cflags = ["-std=c++17"]
    if cc == 90:
        # PyTorch does not currently add the sm_90a target when compute capability
        # 9.0 is set within TORCH_CUDA_ARCH_LIST. Thus, we manually add the sm_90a target.
        extra_cuda_cflags.append("-gencode=arch=compute_90a,code=sm_90a")

    with _ArchListSetter(cc):
        jitmodule = load(
            name,
            [cpp_file, cuda_file],
            extra_cuda_cflags=extra_cuda_cflags,
            extra_include_paths=[
                os.path.join(CUTLASS_PATH, "include"),
                os.path.join(CUTLASS_PATH, "tools/util/include"),
            ],
            verbose=(logger.level == logging.DEBUG)
        )
    return jitmodule


def _pytorch_gemm(op, name: str, cc: int, jit: bool = False, sourcedir: str = ""):
    """
    Generates source for building a PyTorch CUDA module that leverages the CUTLASS GEMM
    specified by ``op``. If the ``jit`` parameter is set to true, the module is just-in-time
    compiled, loaded, and returned.

    :param op: operation to emit in the module
    :param name: name of the module to generate
    :type name: str
    :param cc: compute capability of the device the module should target
    :type cc: int
    :param jit: whether the module should be just-in-time compiled
    :type jit: bool
    :param sourcedir: directory to which generated source files should be written
    :type sourcedir: str

    :return: loaded PyTorch module if ``jit=True`` or ``None`` otherwise
    """
    if sourcedir != "" and not os.path.isdir(sourcedir):
        os.makedirs(sourcedir)

    cuda_file = os.path.join(sourcedir, name + "_kernel.cu")
    extra_kw = {}
    if op.api == ApiVersion.v3x:
        impl_template = _PYTORCH_GEMM_IMPL_TEMPLATE_3x
    else:
        impl_template = _PYTORCH_GEMM_IMPL_TEMPLATE_2x
        if isinstance(op.swizzling_functor, swizzle.ThreadblockSwizzleStreamK):
            extra_kw["args"] = common._CUTLASS_KERNEL_ARGS_2x_STREAM_K
        else:
            extra_kw["args"] = common._CUTLASS_KERNEL_ARGS_2x
    impl_template = (
        _PYTORCH_GEMM_IMPL_TEMPLATE_3x
        if op.api == ApiVersion.v3x
        else _PYTORCH_GEMM_IMPL_TEMPLATE_2x
    )
    cuda_impl = SubstituteTemplate(impl_template, {"name": name, **extra_kw})
    cuda_source = SubstituteTemplate(
        _PYTORCH_CUDA_TEMPLATE,
        {
            "includes": _PYTORCH_GEMM_INCLUDES[op.api],
            "declaration": op.rt_module.emit(),
            "procedural_name": op.procedural_name(),
            "impl": cuda_impl,
            "torch_type_C": _CUTLASS_TYPE_TO_TORCH_TYPE[op.C.element],
        },
    )
    with open(cuda_file, "w") as outfile:
        outfile.write(cuda_source)

    cpp_file = os.path.join(sourcedir, name + ".cpp")
    cpp_source = SubstituteTemplate(
        _PYTORCH_GEMM_CPP_TEMPLATE,
        {"name": name, "description": f"CUTLASS {op.procedural_name()} GEMM"},
    )
    with open(cpp_file, "w") as outfile:
        outfile.write(cpp_source)

    _generate_setup(name, sourcedir)

    if jit:
        return _jit(name, cc, cpp_file, cuda_file)

    return None


def _pytorch_grouped_gemm(
    op, name: str, cc: int, jit: bool = False, sourcedir: str = ""
):
    """
    Generates source for building a PyTorch CUDA module that leverages the CUTLASS grouped GEMM
    specified by ``op``. If the ``jit`` parameter is set to true, the module is just-in-time
    compiled, loaded, and returned.

    :param op: operation to emit in the module
    :param name: name of the module to generate
    :type name: str
    :param cc: compute capability of the device the module should target
    :type cc: int
    :param jit: whether the module should be just-in-time compiled
    :type jit: bool
    :param sourcedir: directory to which generated source files should be written
    :type sourcedir: str

    :return: loaded PyTorch module if ``jit=True`` or ``None`` otherwise
    """
    if op.api != ApiVersion.v2x:
        raise Exception("Grouped GEMM is currently only supported for CUTLASS 2.x")

    if sourcedir != "" and not os.path.isdir(sourcedir):
        os.makedirs(sourcedir)

    cuda_file = os.path.join(sourcedir, name + "_kernel.cu")
    cuda_impl = SubstituteTemplate(_PYTORCH_GROUPED_GEMM_IMPL_TEMPLATE, {"name": name})
    cuda_source = SubstituteTemplate(
        _PYTORCH_CUDA_TEMPLATE,
        {
            "includes": _PYTORCH_GROUPED_GEMM_INCLUDES,
            "declaration": op.rt_module.emit(),
            "procedural_name": op.procedural_name(),
            "impl": cuda_impl,
            "torch_type_C": _CUTLASS_TYPE_TO_TORCH_TYPE[op.C.element],
        },
    )
    with open(cuda_file, "w") as outfile:
        outfile.write(cuda_source)

    cpp_file = os.path.join(sourcedir, name + ".cpp")
    cpp_source = SubstituteTemplate(
        _PYTORCH_GROUPED_GEMM_CPP_TEMPLATE,
        {"name": name, "description": f"CUTLASS {op.procedural_name()} grouped GEMM"},
    )
    with open(cpp_file, "w") as outfile:
        outfile.write(cpp_source)

    _generate_setup(name, sourcedir)

    if jit:
        return _jit(name, cc, cpp_file, cuda_file)

    return None


def pytorch(op, name: str, cc: int, jit: bool = False, sourcedir: str = ""):
    """
    Generates source for building a PyTorch CUDA module that leverages the CUTLASS kernel
    specified by ``op``. If the ``jit`` parameter is set to true, the module is just-in-time
    compiled, loaded, and returned.

    The result of this method is files within ``sourcedir`` that can be used for building
    a PyTorch module.

    :param op: operation to emit in the module
    :param name: name of the module to generate
    :type name: str
    :param cc: compute capability of the device the module should target
    :type cc: int
    :param jit: whether the module should be just-in-time compiled
    :type jit: bool
    :param sourcedir: directory to which generated source files should be written
    :type sourcedir: str

    :return: loaded PyTorch module (if ``jit=True``) or None
    """
    device_op = op.device_op()
    if isinstance(op, GemmOperationUniversal):
        return _pytorch_gemm(device_op, name, cc, jit, sourcedir)
    elif isinstance(op, GemmOperationGrouped):
        return _pytorch_grouped_gemm(device_op, name, cc, jit, sourcedir)
    else:
        raise Exception(
            f"Operation type {type(op)} is not currently supported for PyTorch emission."
        )
