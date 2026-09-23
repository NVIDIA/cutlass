# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
Regression tests: re-applying the same compiler-option string to one
``CompileOptions`` object must not grow ``ExtraCompilerOpts``.

``apply_envar_settings`` runs on every compilation, and the public
``cute.compile`` entrypoint is a module-global ``CompileCallable`` whose
``CompileOptions`` outlives individual compiles.  Re-applying the env-var
option string appended its emitted raw fragments to ``ExtraCompilerOpts``
again on every compile, so the serialized pass-pipeline string grew without
bound and, because ``CompileOptions.to_str()`` is hashed into the module
cache key, the same kernel could map to different cache keys at different
points in the process lifetime.

The fix skips only *consecutive* re-emissions of the same fragment batch.
A single application stays byte-identical (including order-sensitive inputs
such as ``foo=1 foo=2 foo=1``), alternating batches keep re-asserting
last-wins exactly as before, different option strings keep accumulating, and
named options are still re-applied per compile (their per-compile reset is
load-bearing, e.g. ``link-libraries``).
"""

import hashlib
import os
import subprocess
import sys
import textwrap
import unittest

from cutlass.base_dsl.compiler import (
    CompileOptions,
    ExtraCompilerOpts,
)
from cutlass.base_dsl.env_manager import EnvironmentVarManager


def _make_envar(compiler_opt):
    """An EnvironmentVarManager with a fixed option string and no dependence
    on ambient ``CUTE_DSL_*`` variables.

    Env reads are lru_cached module-level helpers, so the constructor runs
    under a scrubbed environment with cleared caches (constructor side
    effects such as the keep-SASS nvdisasm probe must not see ambient
    settings), and the caches are cleared again afterwards so later reads
    observe the real environment.  The settings consumed by
    apply_envar_settings are then pinned directly.
    """
    from unittest import mock

    from cutlass.base_dsl import env_manager

    def _clear_env_caches():
        for helper in (
            env_manager.get_str_env_var,
            env_manager.get_bool_env_var,
            env_manager.get_int_env_var,
            env_manager.get_int_or_none_env_var,
            env_manager.has_env_var,
        ):
            helper.cache_clear()

    with mock.patch.dict(os.environ):
        for key in list(os.environ):
            if key.startswith("CUTE_DSL_") and key != "CUTE_DSL_LIBS":
                del os.environ[key]
        _clear_env_caches()
        envar = EnvironmentVarManager("CUTE_DSL")
    _clear_env_caches()
    envar.compiler_opt = compiler_opt
    envar.debug = False
    envar.remarks = ""
    envar.keep_ptx = envar.keep_cubin = envar.keep_sass = False
    envar.enable_pyir = False
    envar.enable_assertions = False
    envar.lineinfo = False
    envar.enable_tvm_ffi = False
    return envar


class TestEnvarReapplicationIsIdempotent(unittest.TestCase):
    """apply_envar_settings re-runs per compile; re-emitting the same raw
    fragment batch must not grow the options.  No GPU compilation involved."""

    def _extra(self, co):
        return co.options[ExtraCompilerOpts].value

    def _apply_n(self, compiler_opt, n=3):
        envar = _make_envar(compiler_opt)
        co = CompileOptions()
        seen = []
        for _ in range(n):
            co.apply_envar_settings(envar, "fn")
            seen.append(self._extra(co))
        return co, seen

    def test_compact_token_stable_across_three_compiles(self):
        co, seen = self._apply_n("iket")
        self.assertEqual(
            seen,
            ["enable-iket=true"] * 3,
            f"ExtraCompilerOpts grew across re-applications: {seen}",
        )

    def test_raw_flag_stable_across_three_compiles(self):
        # Unknown names fall through to raw pipeline fragments; those must
        # not accumulate either.
        co, seen = self._apply_n("my-flag=1")
        self.assertEqual(seen, ["my-flag=1"] * 3)

    def test_serialization_and_cache_key_input_stable(self):
        # to_str() builds the pass-pipeline string and feeds the module
        # cache key; it must not change across compiles.
        envar = _make_envar("iket")
        co = CompileOptions()
        strs = []
        for _ in range(3):
            co.apply_envar_settings(envar, "fn")
            strs.append(co.to_str())
        digests = {hashlib.sha256(s.encode()).hexdigest() for s in strs}
        self.assertEqual(
            len(set(strs)),
            1,
            f"serialized options changed across compiles: {strs}",
        )
        self.assertEqual(len(digests), 1)

    def test_mixed_diagnostics_stable_with_per_compile_serialization(self):
        # warnings/remarks emit diagnostic= fragments, and to_str() (called
        # once per real compile) canonicalizes the first one in place via
        # _ensure_compiler_diagnostic_selector.  Re-application after that
        # mutation must not append further fragments (which could flip the
        # effective last-wins selector between compiles).
        envar = _make_envar("warnings{nvvm} remarks{ptx}")
        co = CompileOptions()
        strs = []
        for _ in range(3):
            co.apply_envar_settings(envar, "fn")
            strs.append(co.to_str())
        self.assertEqual(
            len(set(strs)),
            1,
            f"serialized options changed across compiles: {strs}",
        )
        # Effective semantics must match the historical first cycle: the
        # canonicalized selector followed by the ptx fragment (last-wins
        # selector stays ptx).
        self.assertIn("diagnostic=nvvm,ptx diagnostic=ptx", strs[0])

    def test_single_application_preserves_order_and_duplicates(self):
        # A single application must stay byte-identical to the historical
        # behavior, including repeated keys and repeated identical
        # fragments: downstream pipeline options are last-wins, so
        # "foo=1 foo=2 foo=1" must keep all three fragments in order.
        co, seen = self._apply_n("foo=1 foo=2 foo=1")
        self.assertEqual(seen, ["foo=1 foo=2 foo=1"] * 3)

    def test_distinct_applications_still_accumulate(self):
        # Only consecutive re-emission of the same batch is skipped;
        # different option strings applied to the same object keep
        # accumulating.
        co = CompileOptions()
        co._apply_opt_string("foo=1")
        co._apply_opt_string("bar=2")
        self.assertEqual(self._extra(co), "foo=1 bar=2")

    def test_alternating_batches_reassert_last_wins(self):
        # A batch that was applied before but has since been superseded by a
        # different batch MUST be re-appended: pipeline options are
        # last-wins, and the persistent options object can serve DSLs with
        # different env namespaces whose option strings alternate (e.g.
        # CUTE_DSL_COMPILER_OPT=iket vs
        # CUTE_EXPERIMENTAL_DSL_COMPILER_OPT=enable-iket=false).
        co = CompileOptions()
        co.apply_envar_settings(_make_envar("iket"), "fn")
        co.apply_envar_settings(_make_envar("enable-iket=false"), "fn")
        co.apply_envar_settings(_make_envar("iket"), "fn")
        self.assertEqual(
            self._extra(co),
            "enable-iket=true enable-iket=false enable-iket=true",
        )
        # ... and re-applying the (now last) batch again must not grow it.
        co.apply_envar_settings(_make_envar("iket"), "fn")
        self.assertEqual(
            self._extra(co),
            "enable-iket=true enable-iket=false enable-iket=true",
        )

    def test_named_options_are_still_reapplied_per_compile(self):
        # The guard covers only the raw-fragment append.  Named options must
        # keep their per-compile replace semantics: the persistent options
        # object can serve DSLs with different env namespaces
        # (CUTE_DSL_* / CUTE_EXPERIMENTAL_DSL_*), whose option strings must
        # keep overriding each other.
        from cutlass.base_dsl.compiler import OptLevel

        co = CompileOptions()
        co.apply_envar_settings(_make_envar("opt-level=1"), "fn")
        self.assertEqual(str(co.options[OptLevel].value), "1")
        co.apply_envar_settings(_make_envar("opt-level=2"), "fn")
        self.assertEqual(str(co.options[OptLevel].value), "2")
        co.apply_envar_settings(_make_envar("opt-level=1"), "fn")
        self.assertEqual(str(co.options[OptLevel].value), "1")

    def test_link_libraries_reset_per_compile_is_preserved(self):
        # The compiler appends FFI bitcode sources to LinkLibraries during
        # each compilation; on the persistent options object it is the
        # env-string re-application that resets the list.  The guard must
        # not break that (otherwise per-kernel bitcode accumulates and leaks
        # into later kernels).
        from cutlass.base_dsl.compiler import LinkLibraries

        envar = _make_envar("link-libraries=base.bc")
        co = CompileOptions()
        co.apply_envar_settings(envar, "fn")
        self.assertEqual(co.options[LinkLibraries].value, "base.bc")
        # Simulate the per-compile FFI append done in generate_mlir.
        co.options[LinkLibraries] = LinkLibraries("base.bc,ffi_kernel_a.bc")
        co.apply_envar_settings(envar, "fn")
        self.assertEqual(co.options[LinkLibraries].value, "base.bc")


class TestEnvOptCompilationLifetime(unittest.TestCase):
    """End-to-end: the persistent ``cute.compile`` options object must not
    accumulate env-var fragments across real compilations.

    Runs in a subprocess so ``CUTE_DSL_COMPILER_OPT`` is set before DSL
    initialization, exactly as a user would hit this.
    """

    def test_three_compiles_do_not_grow_options(self):
        import tempfile

        script = textwrap.dedent(
            """
            import os
            import sys

            # Import the same `cutlass` package as the parent test process
            # (an installed wheel may inject its own path entries via .pth
            # hooks ahead of PYTHONPATH).
            sys.path.insert(0, os.environ["_TEST_CUTLASS_PKG_ROOT"])

            import cutlass
            import cutlass.cute as cute
            from cutlass import Float32
            from cutlass.base_dsl.compiler import ExtraCompilerOpts
            from cutlass.cute.runtime import make_fake_tensor

            @cute.kernel
            def k(gA: cute.Tensor):
                tidx, _, _ = cute.arch.thread_idx()
                gA[tidx] = gA[tidx] + Float32(1.0)

            @cute.jit
            def entry(gA: cute.Tensor):
                k(gA).launch(grid=(1, 1, 1), block=(32, 1, 1))

            gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
            seen = []
            for _ in range(3):
                cute.compile(entry, gA)
                seen.append(
                    cute.compile._compile_options.options[ExtraCompilerOpts].value
                )
            for i, s in enumerate(seen, 1):
                print(f"after compile {i}: {s!r}")
            if seen != ["enable-iket=true"] * 3:
                raise SystemExit(f"options object grew across compiles: {seen}")
            """
        )
        import cutlass

        # Import the same cutlass package in the subprocess, and drop
        # ambient settings that would perturb the exact expected fragment
        # (other CUTE_DSL_* variables, e.g. CUTE_DSL_LIBS, must survive).
        pkg_root = os.path.dirname(os.path.dirname(os.path.abspath(cutlass.__file__)))
        scrub = {
            "CUTE_DSL_COMPILER_OPT",
            "CUTE_DSL_DEBUG",
            "CUTE_DSL_REMARKS",
            "CUTE_DSL_KEEP",
            "CUTE_DSL_KEEP_IR",
            "CUTE_DSL_KEEP_PTX",
            "CUTE_DSL_KEEP_CUBIN",
            "CUTE_DSL_KEEP_SASS",
            "CUTE_DSL_LINEINFO",
            "CUTE_DSL_ENABLE_ASSERTIONS",
            "CUTE_DSL_ENABLE_PYIR",
            "CUTE_DSL_ENABLE_TVM_FFI",
            "PYTHONOPTIMIZE",
        }
        env = {k: v for k, v in os.environ.items() if k not in scrub}
        env["CUTE_DSL_COMPILER_OPT"] = "iket"
        env["_TEST_CUTLASS_PKG_ROOT"] = pkg_root
        # The DSL re-parses jit function sources, so the script must live in
        # a real file (``python -c`` has no retrievable source).
        with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as f:
            f.write(script)
            script_path = f.name
        try:
            proc = subprocess.run(
                [sys.executable, script_path],
                env=env,
                capture_output=True,
                text=True,
            )
        finally:
            os.unlink(script_path)
        self.assertEqual(
            proc.returncode,
            0,
            f"stdout:\n{proc.stdout}\nstderr:\n{proc.stderr}",
        )


if __name__ == "__main__":
    unittest.main()
