import distutils.cmd
from setuptools import setup
import setuptools.command.build_py
import os

# build rmm dependency
class BuildRMM(distutils.cmd.Command):
    user_options = []
    def initialize_options(self):
        pass
    def finalize_options(self):
        pass
    def run(self):
        try:
            import rmm
        except ImportError:
            print("installing rmm")
            os.system("git clone -b branch-22.08 --recurse-submodules https://github.com/rapidsai/rmm.git")
            os.chdir("./rmm")
            os.system("./build.sh librmm rmm")
            os.chdir("./python")
            os.system("python setup.py build_ext --inplace")
            os.system("python setup.py install")

cutlass_path = os.getenv('CUTLASS_PATH')
assert cutlass_path is not None, "Environment variable 'CUTLASS_PATH' is not defined."
cuda_install_path = os.getenv('CUDA_INSTALL_PATH')
assert cuda_install_path is not None, "Environment variable 'CUDA_INSTALL_PATH' is not defined."

ext_modules = []

try:
    from pybind11.setup_helpers import Pybind11Extension, build_ext
    include_dirs = [
        cutlass_path + "/include",
        cuda_install_path + "/include",
        cutlass_path + "/tools/util/include",
        cutlass_path + "/test",
        cutlass_path + "/tools/library/scripts/pycutlass/googletest/googletest/include"
    ]

    ext_modules = [
        Pybind11Extension("cutlass",
                          ["src/cpp/cutlass.cpp"],
                          include_dirs=include_dirs,
                          extra_compile_args=["-fpermissive", "-w"])
    ]
except ImportError:
    pass

setup(
    name="PyCutlass",
    version="0.0.1",
    author="Zhaodong Chen; Andrew Kerr; Haicheng Wu; Szymon Migacz; Graham Markall",
    author_email="zhaodongc@nvidia.com",
    description="Python interface for CUTLASS",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    package_dir={"": "src"},
    packages=['pycutlass', 'pycutlass.utils', 'pycutlass.test'],
    setup_requires=["pybind11", "numpy<1.23"],
    install_requires=[
        "numpy<1.23",
        'pybind11',
        'cuda-python<11.7.0',
        'typeguard',
        'bfloat16',
        'typing',
        'scikit-build',
        'treelib'
    ],
    cmdclass={
        'rmm': BuildRMM
    },
    ext_modules=ext_modules,
    python_requires=">=3.6",
)
