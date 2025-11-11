# GitHub Copilot Instructions for SYCL*TLA

## Project Overview

SYCL*TLA (SYCL Templates for Linear Algebra) is a high-performance C++ template library for tensor linear algebra operations on Intel GPUs using SYCL. This repository is forked from NVIDIA CUTLASS and extends CUTLASS and CuTe API support to Intel GPUs through SYCL enablement.

## Key Technologies and Frameworks

- **SYCL**: Primary parallel programming model for Intel GPU acceleration
- **Intel oneAPI**: Compiler toolchain (icpx/icx) and runtime environment
- **CUTLASS 3.x**: Template-based GEMM library architecture
- **CuTe**: Compile-time tensor abstraction library
- **Intel Xe Architecture**: Target hardware (BMG arch=20, PVC arch=12)
- **CMake/Ninja**: Build system configuration
- **Python**: High-level interface and testing framework

## Architecture-Specific Guidelines

### Intel Xe GPU Support
- **Primary Targets**: Intel Data Center GPU Max/Flex Series (PVC) and Intel Arc B580 (BMG)
- **Architecture Constants**: Use BMG (arch=20) for consumer GPUs, PVC (arch=12) for data center
- **Compilation Targets**: 
  - BMG: `intel_gpu_bmg_g21`
  - PVC: `intel_gpu_pvc`
- **DPAS Operations**: Intel's Dot Product Accumulate Systolic instruction support

### Layout Constraints
- **Intel Xe Requirements**: Specific layout constraints for epilogue operations
- **Memory Access Patterns**: 2D block operations with Intel GPU intrinsics
- **Stride Requirements**: Use CuTe stride descriptors with int64_t types

## Code Style and Conventions

### C++ Templates
- Follow CUTLASS 3.x template parameter conventions
- Use CuTe abstractions for tensor operations
- Maintain compile-time optimization patterns
- Template specializations for Intel Xe architecture features

### SYCL-Specific Patterns
- Use `sycl::queue` for device operations
- Prefer `sycl::buffer` and `sycl::accessor` for memory management
- Follow Intel GPU subgroup programming model
- Use Intel GPU intrinsics for optimized operations

### File Organization
- **Headers**: `include/cutlass/` for core templates
- **Kernels**: Architecture-specific implementations in `include/cutlass/gemm/kernel/`
- **Examples**: `examples/` with Intel Xe demonstrations
- **Python**: `python/cutlass_library/` for high-level interface
- **Tests**: `test/` with Intel GPU validation

## Development Workflow

### Environment Setup
```bash
# Source Intel oneAPI environment
source /opt/intel/oneapi/setvars.sh

# Configure for Intel GPU compilation
export CXX=icpx
export CC=icx
```

### Build Configuration
- Use CMake with `-DCUTLASS_ENABLE_SYCL=ON`
- Specify target architecture: `-DDPCPP_SYCL_TARGET=intel_gpu_bmg_g21`
- Enable CI mode for testing: `-DCUTLASS_SYCL_RUNNING_CI=ON`

### Testing Patterns
- Validate on both BMG and PVC architectures when possible
- Include mixed-precision test cases (FP16, BF16, FP8)
- Test epilogue fusion operations
- Verify against reference implementations

## Common Anti-Patterns to Avoid

### Performance Issues
- **Avoid**: Unnecessary template instantiations
- **Avoid**: Non-coalesced memory access patterns
- **Avoid**: Suboptimal tile sizes for Intel Xe
- **Avoid**: Missing architecture-specific optimizations

### SYCL-Specific Issues
- **Avoid**: CUDA-specific code paths in SYCL builds
- **Avoid**: Hardcoded NVIDIA architecture assumptions
- **Avoid**: Missing Intel GPU intrinsic availability checks
- **Avoid**: Incorrect compilation target specifications

### Template Code Issues
- **Avoid**: Template parameter naming conflicts with CUTLASS conventions
- **Avoid**: Missing SFINAE constraints for Intel Xe specializations
- **Avoid**: Breaking CuTe compile-time optimization patterns

## Key Files and Components

### Core Templates
- `include/cutlass/gemm/kernel/xe_gemm_universal.hpp`: Intel Xe GEMM kernels
- `include/cutlass/epilogue/threadblock/xe_epilogue.hpp`: Intel Xe epilogue operations
- `include/cutlass/arch/arch.h`: Architecture detection and constants

### Python Interface
- `python/cutlass_library/generator.py`: Kernel generation logic
- `python/cutlass_library/arch_constants.py`: Architecture configuration
- `python/cutlass_library/cutlass_test_wrapper_source.cpp`: C++ wrapper

### Build System
- `CMakeLists.txt`: Main build configuration
- `SYCL.cmake`: SYCL-specific build rules
- `.github/workflows/intel_test.yml`: CI configuration

## Documentation Standards

### Code Comments
- Document Intel Xe-specific optimizations and constraints
- Explain template parameter purposes and valid ranges
- Include usage examples for complex template patterns
- Reference Intel GPU programming guides where applicable

### Commit Messages
- Use conventional commit format: `type(scope): description`
- Common types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`
- Include architecture scope when relevant: `feat(xe20): add BMG GEMM support`

### Pull Request Guidelines
- Include performance impact analysis for kernel changes
- Test on multiple Intel GPU architectures when possible
- Document any breaking changes to template interfaces
- Provide before/after benchmarks for optimizations

## Intel GPU-Specific Considerations

### Memory Hierarchy
- L3 cache optimization for Intel Xe
- Shared local memory usage patterns
- Global memory coalescing requirements

### Compute Capabilities
- DPAS instruction utilization
- Subgroup size considerations (16 or 32)
- Matrix engine programming patterns

### Debugging and Profiling
- Use Intel VTune for performance analysis
- Intel Graphics Compiler optimization flags
- SYCL profiling and debugging tools

## Integration Points

### Python Ecosystem
- PyTorch XPU backend compatibility
- NumPy array interface support
- dpctl device management integration

### Intel oneAPI Ecosystem
- oneMKL integration for reference implementations
- Level Zero runtime compatibility
- Intel GPU driver requirements

## Version and Compatibility

- **SYCL Version**: Follow Intel SYCL implementation standards
- **Intel oneAPI**: Support latest LTS and current releases
- **Python**: Maintain compatibility with Python 3.8+
- **CMake**: Minimum version 3.18 for SYCL support

When reviewing or contributing code, always consider the Intel GPU architecture implications, SYCL best practices, and template library design patterns that maintain the high-performance characteristics of the CUTLASS foundation while enabling optimal execution on Intel hardware.