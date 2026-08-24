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
Unit tests for the ``llc{...}`` compile-option token and the ``NvvmOptions``
compile option.

``llc{<flag>[,<flag>...]}`` forwards each brace item to LLVM codegen (llc)
as an ``-Xllc -<flag>`` pair via the ``nvvm-options`` option of the
``cute-to-nvvm`` pipeline. The token is accepted everywhere compact tokens
are: ``CUTE_DSL_COMPILER_OPT``, ``cute.compile(..., options=...)``, and the
underlying ``CompileOptions._apply_opt_string``. ``NvvmOptions`` is the
matching programmatic option (``cute.compile[NvvmOptions("...")]``).
"""

import glob
import os
import subprocess
import sys
import tempfile
import unittest

import cutlass.cute as cute
from cutlass.base_dsl.common import DSLUserCodeError
from cutlass.base_dsl.compiler import (
    CompileOptions,
    NvvmOptions,
    _parse_compile_options_from_str,
)


class TestLlcTokenParsing(unittest.TestCase):
    """Parse-level tests; no GPU compilation involved."""

    def test_default_has_no_nvvm_options(self):
        # Opt-in: with no llc token the option contributes no text at all.
        self.assertNotIn("nvvm-options", CompileOptions().to_str())
        self.assertEqual(CompileOptions().options[NvvmOptions].serialize(), "")

    def test_single_flag(self):
        co = CompileOptions()
        co._apply_opt_string("llc{aggressive-machine-cse=1}")
        self.assertIn("nvvm-options='-Xllc -aggressive-machine-cse=1'", co.to_str())

    def test_multiple_flags_one_token(self):
        co = CompileOptions()
        co._apply_opt_string("llc{aggressive-machine-cse=1,enable-misched=0}")
        self.assertIn(
            "nvvm-options='-Xllc -aggressive-machine-cse=1 -Xllc -enable-misched=0'",
            co.to_str(),
        )

    def test_valueless_flag(self):
        co = CompileOptions()
        co._apply_opt_string("llc{stats}")
        self.assertIn("nvvm-options='-Xllc -stats'", co.to_str())

    def test_flags_accumulate_across_tokens(self):
        co = CompileOptions()
        co._apply_opt_string("llc{aggressive-machine-cse=1}")
        co._apply_opt_string("llc{enable-misched=0}")
        self.assertIn(
            "nvvm-options='-Xllc -aggressive-machine-cse=1 -Xllc -enable-misched=0'",
            co.to_str(),
        )

    def test_repeated_application_is_idempotent(self):
        # The env var is re-applied per compile onto a reused CompileOptions,
        # so applying the same token twice must not grow the value (which
        # would perturb the compile-cache key).
        co = CompileOptions()
        for _ in range(3):
            co._apply_opt_string("llc{aggressive-machine-cse=1}")
        self.assertIn("nvvm-options='-Xllc -aggressive-machine-cse=1'", co.to_str())
        self.assertEqual(co.options[NvvmOptions].value.count("-Xllc"), 1)

    def test_explicit_nvvm_options_wins_over_token(self):
        # Documented precedence: compact tokens are applied before the legacy
        # string API, so an explicit --nvvm-options value replaces the flags
        # contributed by llc{...} regardless of textual order.
        for opts in (
            "--nvvm-options '-Xllc -base' llc{aggressive-machine-cse=1}",
            "llc{aggressive-machine-cse=1} --nvvm-options '-Xllc -base'",
        ):
            co = _parse_compile_options_from_str(opts)
            self.assertIn("nvvm-options='-Xllc -base'", co.to_str())
            self.assertNotIn("aggressive-machine-cse", co.to_str())

    def test_string_api_pure_compact(self):
        co = _parse_compile_options_from_str("llc{aggressive-machine-cse=1}")
        self.assertIn("nvvm-options='-Xllc -aggressive-machine-cse=1'", co.to_str())

    def test_string_api_mixed_with_legacy(self):
        co = _parse_compile_options_from_str(
            "--opt-level 2 llc{aggressive-machine-cse=1}"
        )
        s = co.to_str()
        self.assertIn("opt-level=2", s)
        self.assertIn("nvvm-options='-Xllc -aggressive-machine-cse=1'", s)

    def test_coexists_with_other_compact_tokens(self):
        co = CompileOptions()
        co._apply_opt_string("warnings{nvvm} llc{aggressive-machine-cse=1}")
        s = co.to_str()
        self.assertIn("diagnostic=nvvm", s)
        self.assertIn("nvvm-options='-Xllc -aggressive-machine-cse=1'", s)


class TestLlcTokenRejectsMalformedInput(unittest.TestCase):
    def _assert_rejected(self, opt_str, msg_fragment):
        with self.assertRaises(ValueError) as ctx:
            CompileOptions()._apply_opt_string(opt_str)
        self.assertIn(msg_fragment, str(ctx.exception))

    def test_bare_name(self):
        self._assert_rejected("llc", "llc expects flag braces")

    def test_equals_form(self):
        self._assert_rejected("llc=1", "llc expects flag braces")

    def test_empty_braces(self):
        self._assert_rejected("llc{}", "Empty braces for option 'llc'")

    def test_only_separators_in_braces(self):
        self._assert_rejected("llc{ , }", "Empty braces for option 'llc'")

    def test_unclosed_brace(self):
        self._assert_rejected("llc{aggressive-machine-cse=1", "Unclosed")

    def test_leading_dash(self):
        self._assert_rejected("llc{-aggressive-machine-cse=1}", "invalid llc flag")

    def test_embedded_space(self):
        self._assert_rejected("llc{aggressive machine cse}", "invalid llc flag")

    def test_embedded_quote(self):
        self._assert_rejected("llc{foo'bar}", "invalid llc flag")

    def test_flag_value_with_quote(self):
        self._assert_rejected("llc{foo='1'}", "invalid llc flag")


class TestNvvmOptionsProgrammatic(unittest.TestCase):
    def test_exported_from_cute(self):
        self.assertIs(cute.NvvmOptions, NvvmOptions)

    def test_direct_option(self):
        co = CompileOptions((NvvmOptions("-Xllc -aggressive-machine-cse=1"),))
        self.assertIn("nvvm-options='-Xllc -aggressive-machine-cse=1'", co.to_str())

    def test_rejects_quote(self):
        with self.assertRaises(DSLUserCodeError):
            NvvmOptions("-Xllc -foo='1'")

    def test_rejects_brace(self):
        with self.assertRaises(DSLUserCodeError):
            NvvmOptions("-Xllc -foo} evil{")

    def test_rejects_quote_on_assignment(self):
        opt = NvvmOptions("-Xllc -aggressive-machine-cse=1")
        with self.assertRaises(DSLUserCodeError):
            opt.value = "-Xllc -foo='1' evil"

    def test_surrounding_quotes_are_tolerated(self):
        # serialize() strips one layer of surrounding quotes before
        # re-quoting, so a pre-quoted value is legal (this is how the
        # legacy --nvvm-options string path delivers values).
        co = CompileOptions((NvvmOptions("'-Xllc -aggressive-machine-cse=1'"),))
        self.assertIn("nvvm-options='-Xllc -aggressive-machine-cse=1'", co.to_str())


# Every test that reaches the NVVM backend runs in a disposable subprocess:
# an accepted -Xllc flag is parsed into LLVM's process-global option registry
# (see TestLlcFlagStateIsProcessGlobal below) and would otherwise stay active
# for everything compiled later in the test process. The script is written to
# a real file because the DSL retrieves @cute.jit sources via inspect. The
# probe kernel compiles first in every mode, so the victim is always the
# process's second compile (identical backend warm-state across modes and its
# PTX can be compared byte-for-byte); only in "leaked" mode does the probe
# carry the flag.
_SUBPROCESS_COMPILE_SCRIPT = r"""
import sys

import cutlass.cute as cute
from cutlass import Float32
from cutlass.base_dsl.compiler import CompilerDiagnosticError, NvvmOptions
from cutlass.cute.runtime import make_fake_tensor


@cute.kernel
def _kp(gA: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    gA[tidx] = gA[tidx] + Float32(1.0)


@cute.jit
def probe(gA: cute.Tensor):
    _kp(gA).launch(grid=(1, 1, 1), block=(32, 1, 1))


@cute.kernel
def _kv(gA: cute.Tensor, gB: cute.Tensor, gC: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    a = gA[tidx]
    b = gB[tidx]
    d = a / b
    f = a * b + d
    g = (a + b) * (a - b) + f
    gC[tidx] = d + f + g


@cute.jit
def victim(gA: cute.Tensor, gB: cute.Tensor, gC: cute.Tensor):
    _kv(gA, gB, gC).launch(grid=(1, 1, 1), block=(32, 1, 1))


mode, flag = sys.argv[1], sys.argv[2]
fa = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
fb = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
fc = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
try:
    if mode == "leaked":
        cute.compile(probe, fa, options="llc{%s}" % flag)
    else:
        cute.compile(probe, fa)
    if mode == "control":
        cute.compile(victim, fa, fb, fc, options="llc{%s}" % flag)
    elif mode == "programmatic":
        cute.compile[NvvmOptions("-Xllc -%s" % flag)](victim, fa, fb, fc)
    else:  # "clean" and "leaked": the victim never passes options
        cute.compile(victim, fa, fb, fc)
except CompilerDiagnosticError as exc:
    sys.stderr.write("BACKEND-REJECTED: %s\n" % (exc,))
    sys.exit(3)
"""


def _run_compile_subprocess(mode, flag, work_dir):
    """Run one compile ordering in a fresh interpreter, dumping PTX into
    ``work_dir``. ``CUTE_DSL_COMPILER_OPT`` is stripped from the child
    environment so an ambient ``llc{...}`` cannot contaminate the arms."""
    env = {k: v for k, v in os.environ.items() if k != "CUTE_DSL_COMPILER_OPT"}
    env.update(CUTE_DSL_KEEP="ptx", CUTE_DSL_DUMP_DIR=work_dir, PYTHONHASHSEED="0")
    script = os.path.join(work_dir, "probe_script.py")
    with open(script, "w") as f:
        f.write(_SUBPROCESS_COMPILE_SCRIPT)
    return subprocess.run(
        [sys.executable, script, mode, flag],
        env=env,
        capture_output=True,
        text=True,
        timeout=600,
    )


class TestLlcTokenCompilation(unittest.TestCase):
    """End-to-end: the serialized option must be accepted by the
    cute-to-nvvm pipeline and reach the NVVM backend."""

    def _run(self, mode, flag):
        with tempfile.TemporaryDirectory() as tmp:
            return _run_compile_subprocess(mode, flag, tmp)

    def test_compile_with_llc_flag(self):
        res = self._run("control", "aggressive-machine-cse=1")
        self.assertEqual(res.returncode, 0, res.stderr + res.stdout)

    def test_compile_with_programmatic_nvvm_options(self):
        res = self._run("programmatic", "aggressive-machine-cse=1")
        self.assertEqual(res.returncode, 0, res.stderr + res.stdout)

    def test_rejected_flag_surfaces_backend_error(self):
        # Whether a given well-formed flag is accepted is libNVVM's call. What
        # this pins is that a rejection is not swallowed: it must surface as a
        # compile-time diagnostic. If this libNVVM happens to accept the flag
        # there is nothing to assert, so skip rather than fail.
        res = self._run("control", "time-passes")
        if res.returncode == 0:
            self.skipTest("this libNVVM accepts -time-passes; nothing to assert")
        self.assertEqual(res.returncode, 3, res.stderr + res.stdout)
        self.assertIn("NVVM", res.stderr)


class TestLlcFlagStateIsProcessGlobal(unittest.TestCase):
    """Pins the documented process-global semantics of ``-Xllc`` flags.

    The backend parses ``-Xllc`` flags into LLVM's process-global option
    registry (``cl::opt``), and only compiles that pass ``nvvm-options``
    re-parse it: a kernel compiled with NO options after a flagged compile
    of a different kernel comes out identical to an explicitly flagged
    build, not to a clean one. This test discloses and pins that behavior
    (see the "Process-global flag state" section of the compilation-options
    doc). If it ever fails with ``leaked == clean``, the backend gained
    per-compile scoping and the documentation should be updated.

    One fresh interpreter per compile ordering: the state under test is
    process state, so the orderings cannot be observed in one process.
    """

    # Schedule-for-registers: changes emitted PTX even on trivial kernels
    # (unlike e.g. aggressive-machine-cse, which is a no-op on small code).
    _PROBE_FLAG = "nvptx-sched4reg"

    def _victim_ptx(self, mode, tmp):
        out = os.path.join(tmp, mode)
        os.makedirs(out, exist_ok=True)
        res = _run_compile_subprocess(mode, self._PROBE_FLAG, out)
        if res.returncode == 3 and "BACKEND-REJECTED" in res.stderr:
            self.skipTest(
                f"this libNVVM rejects -{self._PROBE_FLAG}; no observable "
                "to pin the process-global behavior with"
            )
        self.assertEqual(res.returncode, 0, res.stderr + res.stdout)
        paths = glob.glob(os.path.join(out, "*victim*.ptx"))
        self.assertEqual(len(paths), 1, paths)
        with open(paths[0], "rb") as f:
            return f.read()

    def test_unflagged_compile_inherits_earlier_llc_flag(self):
        with tempfile.TemporaryDirectory() as tmp:
            clean = self._victim_ptx("clean", tmp)
            control = self._victim_ptx("control", tmp)
            if control == clean:
                self.skipTest(
                    f"-{self._PROBE_FLAG} does not change this libNVVM's PTX; "
                    "no observable to pin the process-global behavior with"
                )
            leaked = self._victim_ptx("leaked", tmp)
            self.assertEqual(
                leaked,
                control,
                "victim no longer inherits the earlier compile's -Xllc flag; "
                "the backend appears to scope flags per compile now -- update "
                "the process-global-state documentation",
            )
            self.assertNotEqual(leaked, clean)


if __name__ == "__main__":
    unittest.main()
