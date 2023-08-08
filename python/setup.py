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
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS'
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
import copy
import os
from pybind11.setup_helpers import Pybind11Extension
import setuptools
from setuptools import setup
from setuptools.command.build_ext import build_ext


def _cutlass_path_from_dir() -> str:
    cutlass_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), '../')
    if not os.path.isdir(cutlass_path):
        raise Exception(f'Environment variable "CUTLASS_PATH" is not defined, and default path of {cutlass_path} does not exist.')
    return cutlass_path


def _cuda_install_path_from_nvcc() -> str:
    import subprocess
    # Attempt to detect CUDA_INSTALL_PATH based on location of NVCC
    result = subprocess.run(['which', 'nvcc'], capture_output=True)
    if result.returncode != 0:
        raise Exception(f'Unable to find nvcc via `which` utility.')

    cuda_install_path = result.stdout.decode('utf-8').split('/bin/nvcc')[0]
    if not os.path.isdir(cuda_install_path):
        raise Exception(f'Environment variable "CUDA_INSTALL_PATH" is not defined, and default path of {cuda_install_path} does not exist.')

    return cuda_install_path


cutlass_path = (
    os.getenv('CUTLASS_PATH')
    if os.getenv('CUTLASS_PATH') is not None
    else _cutlass_path_from_dir()
)


cuda_install_path = (
    os.getenv('CUDA_INSTALL_PATH')
    if os.getenv('CUDA_INSTALL_PATH') is not None
    else _cuda_install_path_from_nvcc()
)


class BuildExtension(build_ext):
    """
    Wrapper around `build_ext` to use NVCC when compiling the CUTLASS Python-C++ bindings.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def build_extensions(self):
        original_compile = self.compiler._compile

        def custom_compile(obj, src, ext, cc_args, extra_postargs, pp_opts):
            """
            Wrapper around build_ext.compiler._compile method
            """
            postargs = copy.deepcopy(extra_postargs)
            postargs = [f for f in postargs if f not in ['-g0', '-fvisibility=hidden']]
            postargs.extend(["-Xcompiler='-fPIC'", "-Xcompiler='-g0'", "-Xcompiler='-O3'", '-x', 'cu'])
            try:
                original_compiler = self.compiler.compiler_so
                self.compiler.set_executable('compiler_so', [f'{cuda_install_path}/bin/nvcc'])
                original_compile(obj, src, ext, cc_args, postargs, pp_opts)
            finally:
                self.compiler.set_executable('compiler_so', original_compiler)

        self.compiler._compile = custom_compile
        super().build_extensions()


include_dirs = [
    cutlass_path + '/include',
    cuda_install_path + '/include',
    cutlass_path + '/tools/util/include',
    cutlass_path + '/test',
]


library_dirs = [
    cuda_install_path + '/lib64',
]


ext_modules = [
    Pybind11Extension('cutlass_bindings',
                      ['cutlass/cpp/cutlass_bindings.cpp'],
                      include_dirs=include_dirs,
                      library_dirs=library_dirs,
                      extra_compile_args=['-Xcompiler="-fpermissive"', '-w', '-std=c++17'],
                      libraries=['cudart'])
]


setup(
    name='cutlass',
    version='3.1.0',
    description='CUTLASS Pythonic Interface',
    package_dir={'': '.'},
    packages=['cutlass', 'cutlass.emit', 'cutlass.op', 'cutlass.utils', 'cutlass.backend', 'cutlass.backend.utils'],
    setup_requires=['pybind11'],
    install_requires=[
        'bfloat16',
        'cuda-python>=11.8.0',
        'pybind11',
        'scikit-build',
        'treelib'
        ],
    ext_modules=ext_modules,
    cmdclass={
                 'build_ext': BuildExtension
             }
)
