import os
import torch
from typing import Any

from deep_gemm import jit


class Capture:
    def __init__(self) -> None:
        self.read_fd = None
        self.write_fd = None
        self.saved_stdout = None
        self.captured = None

    def __enter__(self) -> Any:
        self.read_fd, self.write_fd = os.pipe()
        self.saved_stdout = os.dup(1)
        os.dup2(self.write_fd, 1)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        os.dup2(self.saved_stdout, 1)
        os.close(self.write_fd)
        with os.fdopen(self.read_fd, 'r') as f:
            self.captured = f.read()

    def capture(self) -> str:
        return self.captured


if __name__ == '__main__':
    # Runtime
    print(f'NVCC compiler: {jit.get_nvcc_compiler()}\n')

    # Templates
    print('Generated code:')
    args = (('lhs', torch.float8_e4m3fn), ('rhs', torch.float8_e4m3fn), ('scale', torch.float), ('out', torch.bfloat16),
            ('enable_double_streams', bool), ('stream', torch.cuda.Stream))
    body = "\n"
    body += 'std::cout << reinterpret_cast<uint64_t>(lhs) << std::endl;\n'
    body += 'std::cout << reinterpret_cast<uint64_t>(rhs) << std::endl;\n'
    body += 'std::cout << reinterpret_cast<uint64_t>(scale) << std::endl;\n'
    body += 'std::cout << reinterpret_cast<uint64_t>(out) << std::endl;\n'
    body += 'std::cout << enable_double_streams << std::endl;\n'
    body += 'std::cout << reinterpret_cast<uint64_t>(stream) << std::endl;\n'
    code = jit.generate((), args, body)
    print(code)

    # Build
    print('Building ...')
    func = jit.build('test_func', args, code)

    # Test correctness
    print('Running ...')
    fp8_tensor = torch.empty((1, ), dtype=torch.float8_e4m3fn, device='cuda')
    fp32_tensor = torch.empty((1, ), dtype=torch.float, device='cuda')
    bf16_tensor = torch.empty((1, ), dtype=torch.bfloat16, device='cuda')
    with Capture() as capture:
        assert func(fp8_tensor, fp8_tensor, fp32_tensor, bf16_tensor, True, torch.cuda.current_stream()) == 0
    output = capture.capture()
    ref_output = f'{fp8_tensor.data_ptr()}\n{fp8_tensor.data_ptr()}\n{fp32_tensor.data_ptr()}\n{bf16_tensor.data_ptr()}\n1\n{torch.cuda.current_stream().cuda_stream}\n'
    assert output == ref_output, f'{output=}, {ref_output=}'

    print('JIT test passed')
