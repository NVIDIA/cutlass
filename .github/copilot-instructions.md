# Copilot Coding Agent Onboarding — SYCL*TLA

Purpose
-------
This file is a short, focused onboarding guide so a coding agent (Copilot coding agent) can make correct, CI-safe changes to the SYCL*TLA repository without long exploratory searches. Keep edits conservative: prefer small, well-tested changes and follow the PR checklist described below.

Top-level constraints (read first)
---------------------------------
- **Intel copyright headers**: Many files carry dual NVIDIA/Intel copyright headers. Do not remove or alter copyright headers on modified files.
- **Intel Xe APIs**: The codebase uses new Intel "Xe" APIs (Xe12 for PVC, Xe20 for BMG) and Intel oneAPI toolchain conventions; prefer SYCL-compatible code and avoid adding CUDA-only code paths without explicit gating.
- **CI Requirements**: Changes must build and pass CI workflows in `.github/workflows/*` (notably `intel_test.yml`, `intel_test_gpp_host.yml`, `sycl_python_test.yml`).
- **Test Coverage**: Check for test coverage before making changes. C++ tests are in `test/unit/`, Python tests in `test/python/`.
- **PR Descriptions**: Must include: what changed, why, local build/test steps performed, and expected CI/benchmark impact (see PR templates in `.github/PULL_REQUEST_TEMPLATE/`).

Quick actions to always run locally before creating a PR
------------------------------------------------------
1. **ALWAYS source Intel environment first** (required for builds that target Intel compilers; if not available, CMake configure will still catch syntax errors but linking will fail):

```bash
source /opt/intel/oneapi/setvars.sh
export CXX=icpx
export CC=icx
```

2. **ALWAYS create a clean build directory** and configure for SYCL:

```bash
rm -rf build && mkdir build && cd build
cmake .. -G Ninja \
  -DCUTLASS_ENABLE_SYCL=ON \
  -DDPCPP_SYCL_TARGET=intel_gpu_bmg_g21 \
  -DCUTLASS_SYCL_RUNNING_CI=ON
ninja
```

**Critical Notes:**
- `-DDPCPP_SYCL_TARGET` must match your hardware: `intel_gpu_bmg_g21` for BMG (Arc B580), `intel_gpu_pvc` for PVC (Data Center Max). This affects intrinsic availability.
- Build time: ~10-20 minutes for full build on 8-core machine.
- If Intel oneAPI is not installed, CMake configure will still catch syntax errors but linking and target-specific checks will fail.
- **NEVER commit without running a full build locally first**.

Build / Test / Lint summary
---------------------------
- **Bootstrap**: No special bootstrap required. Python dependencies in `pyproject.toml` (`networkx`, `numpy`, `pydot`, `scipy`, `treelib`) are needed for Python tests. Install with `pip install -e .` in project root.
- **Build**: Use CMake 3.22+ and Ninja (see commands above). **ALWAYS** run from clean build directory to avoid stale state.
- **C++ Unit Tests**: After build, run `cmake --build . --target test_unit` (runs all unit tests in `test/unit/`).
- **C++ Examples**: `cmake --build . --target test_examples` (builds and validates examples in `examples/`).
- **Python Tests**: 
  ```bash
  cd python
  python3 -m pytest -q
  ```
  CI runs specific test like `test/python/cutlass/gemm/gemm_bf16_pvc.py`. **ALWAYS** set `export CUTLASS_USE_SYCL=1` before running Python tests.
- **Linting**: No automated linter. Follow existing code style and ensure `-Werror` flag passes (set in CI).

**Environment Variables Required for Runtime:**
```bash
export ONEAPI_DEVICE_SELECTOR=level_zero:gpu
export IGC_ExtraOCLOptions="-cl-intel-256-GRF-per-thread"
export SYCL_PROGRAM_COMPILE_OPTIONS="-ze-opt-large-register-file -gline-tables-only"
export IGC_VectorAliasBBThreshold=100000000000
```
These are set in CI workflows and should be set locally for accurate testing.

Common failure modes & mitigations
---------------------------------
- **Missing Intel environment**: builds fail at linking or with unknown compilers. Mitigation: Source `/opt/intel/oneapi/setvars.sh` or unset `CXX`/`CC` to use system compilers for syntax-only checks.
- **Wrong SYCL target**: some intrinsics are target-specific (e.g., 2D block prefetch intrinsics). Match the CI target or use conservative code paths.
- **Layout constraints in Intel Xe epilogues** (ColumnMajor/RowMajor): prefer to reuse existing epilogue code and tests to avoid violating layout constraints. If making changes, run the affected tests locally.
- **Missing libraries in LD_LIBRARY_PATH** for runtime: set `LD_LIBRARY_PATH` to include `build/tools/library` when running `python` tests that load `.so` wrappers.
- **CMake cache issues**: If you see unexpected build behavior, **ALWAYS** delete `build/` completely and reconfigure. Stale CMake cache causes many hard-to-debug issues.
- **Python import errors**: If Python tests fail with import errors, run `pip install -e .` from project root first.

CI and validation pipelines (what will run)
-------------------------------------------
- See `.github/workflows/` for exact pipelines. Most important:
  - `intel_test.yml` — primary CI build for Intel targets
  - `intel_test_gpp_host.yml` — GPP host builds
  - `sycl_python_test.yml` — Python test workflow
  - `nvidia_test.yml` / `cuda_test.yml` — CUDA-targeted tests (keep changes SYCL-first unless explicitly modifying CUDA paths)

How the agent should validate its changes
-----------------------------------------
1. Run a local CMake configure and build (fast smoke test):

```bash
rm -rf build && mkdir build && cd build
cmake .. -G Ninja -DCUTLASS_ENABLE_SYCL=ON -DDPCPP_SYCL_TARGET=intel_gpu_bmg_g21 -DCUTLASS_SYCL_RUNNING_CI=ON
ninja -k 0
```

2. Run the Python test subset that touches modified components (or all Python tests if the change is cross-cutting):

```bash
cd python
python3 -m pytest -q
```

3. For C++ kernel changes, run unit tests: `cmake --build . --target test_unit -j 8`

4. For examples changes, run: `cmake --build . --target test_examples -j 1`
--------------------------------------------------
- Short summary of change and the files modified.
- Build steps executed locally (CMake + Ninja commands, environment variables set).
- Tests run and their results (include pytest subset names and pass/fail counts).
- If the change affects performance or kernel selection, include expected performance impact and a short benchmark (size and results).
- State whether the Intel oneAPI environment was required to fully validate the change.

Project layout (quick map)
--------------------------
- Root files: `CMakeLists.txt`, `README.md`, `CHANGELOG-SYCL.md`, `SYCL.cmake`, `pyproject.toml`
- Major directories:
  - `include/` — core headers and kernel templates
  - `python/` — Python wrapper, generator, tests
  - `examples/` — usage examples, e.g., `11_xe20_cutlass_library`
  - `test/` — C++ tests and validation kernels
  - `tools/` — build/test utilities
  - `media/` — documentation and architecture notes (search `media/docs/cpp/xe_rearchitecture.md`, `media/docs/python/xe_cutlass_library.md`)

Files the agent should inspect when making changes
--------------------------------------------------
- `python/cutlass_library/generator.py` — kernel generation and filtering logic
- `python/cutlass_library/arch_constants.py` — architecture detection and constants
- `include/cutlass/gemm/kernel/*` — GEMM kernel implementations
- `.github/workflows/*` — CI steps; ensure changes don't break these workflows

Search tips
-----------
- Use `grep -R "HACK\|TODO\|WORKAROUND\|FIXME"` to find fragile areas.
- Search for `intel` and `Xe` keywords to find Intel-specific code paths.

Testing coverage
----------------
- The repo contains Python tests in `python/` and C++ tests under `test/`.
- Before assuming full coverage, run the test suite locally and include failing tests in your PR notes.

Special rules for changes
-------------------------
- Keep changes minimal and well-scoped. If modifying kernel selection or architecture constants, include tests or fallbacks.
- Preserve Intel copyright headers.
- Avoid introducing CUDA-only code paths in SYCL code.

When to run a wider search
--------------------------
Trust these instructions first. Only perform a broad code search if:
- The instructions are clearly missing information for the requested change, or
- A test or build step fails unexpectedly after following these steps.

Where to look for help
----------------------
- `README.md` and `media/docs/*` for architecture details
- `.github/workflows/` for CI expectations
- Open issues and PR templates in `.github/ISSUE_TEMPLATE` and `.github/PULL_REQUEST_TEMPLATE`

Short checklist before opening a PR
-----------------------------------
- [ ] Build configured and compiled locally (or syntax-checked if environment unavailable)
- [ ] Relevant tests run locally and passed
- [ ] PR description includes steps and validation results
- [ ] No removal of Intel copyright headers

If anything here proves inaccurate
----------------------------------
Run the minimal searches you need, then update this file with the corrected steps so future agents benefit.

---
This file is intentionally short (<= 2 pages). For deeper onboarding, consult `README.md`, `media/docs/*`, and the workflows in `.github/workflows/`.
