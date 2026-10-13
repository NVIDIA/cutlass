# CUTLASS CI/CD entry points

Build and package CUTLASS through the compatibility entry point with:

```bash
python3 cutlass_cicd/build.py \
  --source-dir . \
  --workspace /tmp/cutlass-build \
  --output /tmp/cutlass.tar.gz \
  --params /path/to/buildSpec.json
```

The test entry point accepts and ignores the compatibility metadata options
`--test-spec` and `--scm-properties`, so existing job invocations can use the
migrated module without changing their generated command lines.

Run the packaged CUTLASS C++ L0 functional suite with:

```bash
python3 cutlass_cicd/test.py \
  --source-dir . \
  --workspace /tmp/cutlass-tests \
  --package-dir /path/to/extracted/cutlass-package \
  --sm 80 \
  --test L0_functional
```

The C++ suite runs examples, non-example functional tests, and the
`tmem_alloc_tracking` test set through the installed CTest manifest. Add
`--dry-run` to print the commands without requiring a GPU.

Run the public CuTeDSL L0 suite from a CUTLASS checkout with:

```bash
python3 cutlass_cicd/test.py \
  --source-dir . \
  --workspace /tmp/cutlass-tests \
  --package-dir /path/to/extracted/package \
  --sm 100 \
  --test L0_oss_dsl_test
```

`L0_oss_dsl_test` follows the clean editable-wheel workflow by default. It:

1. Recreates `<workspace>/wheel_test` as a clean virtual environment.
2. Installs the CUDA-version-specific test requirements and PyTorch runtime
   (`cu130` by default, or `cu128` when `--cuda-major 12` is specified).
3. Installs `python/CuTeDSL` as the editable core package; its dependencies
   install the public metapackage and runtime wheels from PyPI.
4. Runs the migrated pytest harness and the public example flows.

The editable project identifies itself as `nvidia-cutlass-dsl-libs-core`, so the
default CUDA 13 setup is the native
`python -m pip install -e "python/CuTeDSL[cu13]"`; no preparation or
runtime-library copying is required. Specify `--cuda-major 12` to select the
CUDA 12 requirements, PyTorch `cu128`, and an editable install without `[cu13]`.

The editable build backend creates an environment-specific merged link tree
under `python/CuTeDSL/build/`. Local core files and the installed runtime-wheel
portions appear there through symlinks, so the checked-in `cutlass` package does
not need editable-install path handling. This project configuration supports
editable installation only; `pip install .`, wheel builds, and source
distribution builds fail with a message directing users to `pip install -e .`.

The pytest harness expands the requested SM into its supported architecture variants,
applies L0 sharding, uses pytest-xdist, and writes JUnit XML files under
`<workspace>/test_outputs/junit_report`. The suite also writes
`L0_oss_dsl_test.xml` there, with one JUnit testcase for every setup command,
standalone example, distributed test, notebook, skip, and waiver. When the workspace
itself is named `test_outputs`, reports are written to `<workspace>/junit_report` to
avoid a duplicate `test_outputs/test_outputs` path. Other generated test artifacts use
the workspace as their working directory.

Use `--skip-setup` to run against an already-prepared interpreter supplied with
`--python`. Use `--dry-run` to inspect setup and test commands without executing them.
