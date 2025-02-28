import os
import setuptools
import shutil
import subprocess
from setuptools.command.develop import develop
from setuptools.command.install import install

current_dir = os.path.dirname(os.path.realpath(__file__))
jit_include_dirs = ('deep_gemm/include/deep_gemm', )
cutlass_dirs = '../../include'
third_party_include_dirs = (os.path.join(cutlass_dirs, 'cute'), os.path.join(cutlass_dirs, 'cutlass'))
print(third_party_include_dirs)


class PostDevelopCommand(develop):
    def run(self):
        develop.run(self)
        self.make_jit_include_symlinks()

    @staticmethod
    def make_jit_include_symlinks():
        # Make symbolic links of third-party include directories
        for d in third_party_include_dirs:
            dirname = d.split('/')[-1]
            src_dir = f'{current_dir}/{d}'
            dst_dir = f'{current_dir}/deep_gemm/include/{dirname}'
            if not os.path.exists(src_dir):
                os.makedirs(src_dir, exist_ok=True)
            assert os.path.exists(src_dir)
            if os.path.exists(dst_dir):
                assert os.path.islink(dst_dir)
                os.unlink(dst_dir)
            os.symlink(src_dir, dst_dir, target_is_directory=True)


class PostInstallCommand(install):
    def run(self):
        install.run(self)
        self.copy_jit_includes()

    def copy_jit_includes(self):
        # Copy include directories needed by JIT
        shutil.rmtree(f'{self.build_lib}/deep_gemm/include', ignore_errors=True)
        os.makedirs(f'{self.build_lib}/deep_gemm/include', exist_ok=False)
        for d in jit_include_dirs + third_party_include_dirs:
            src_dir = f'{current_dir}/{d}'
            dst_dir = f'{self.build_lib}/deep_gemm/include/{d.split("/")[-1]}'
            assert os.path.exists(src_dir)
            shutil.copytree(src_dir, dst_dir)


if __name__ == '__main__':
    # noinspection PyBroadException
    try:
        cmd = ['git', 'rev-parse', '--short', 'HEAD']
        revision = '+' + subprocess.check_output(cmd).decode('ascii').rstrip()
    except:
        revision = ''

    # noinspection PyTypeChecker
    setuptools.setup(
        name='deep_gemm',
        version='1.0.0' + revision,
        packages=['deep_gemm', 'deep_gemm/jit', 'deep_gemm/jit_kernels'],
        cmdclass={
            'develop': PostDevelopCommand,
            'install': PostInstallCommand
        }
    )
