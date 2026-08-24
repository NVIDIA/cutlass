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

import unittest

import cutlass
import cutlass.cute as cute
from cutlass import Float32
from cutlass.base_dsl.common import DSLUserCodeError
from cutlass.base_dsl.compiler import (
    CompileOptions,
    CompilerDiagnosticError,
    NvvmOptions,
    _parse_compile_options_from_str,
)
from cutlass.cute.runtime import make_fake_tensor


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


def _make_entry():
    @cute.kernel
    def k(gA: cute.Tensor):
        tidx, _, _ = cute.arch.thread_idx()
        gA[tidx] = gA[tidx] + Float32(1.0)

    @cute.jit
    def entry(gA: cute.Tensor):
        k(gA).launch(grid=(1, 1, 1), block=(32, 1, 1))

    return entry


class TestLlcTokenCompilation(unittest.TestCase):
    """End-to-end: the serialized option must be accepted by the
    cute-to-nvvm pipeline and reach the NVVM backend."""

    def test_compile_with_llc_flag(self):
        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(_make_entry(), gA, options="llc{aggressive-machine-cse=1}")

    def test_compile_with_programmatic_nvvm_options(self):
        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile[NvvmOptions("-Xllc -aggressive-machine-cse=1")](_make_entry(), gA)

    def test_rejected_flag_surfaces_backend_error(self):
        # Whether a given well-formed flag is accepted is libNVVM's call. What
        # this pins is that a rejection is not swallowed: it must surface as a
        # compile-time diagnostic. If this libNVVM happens to accept the flag
        # there is nothing to assert, so skip rather than fail.
        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        try:
            cute.compile(_make_entry(), gA, options="llc{time-passes}")
        except CompilerDiagnosticError as exc:
            self.assertIn("NVVM", str(exc))
        else:
            self.skipTest("this libNVVM accepts -time-passes; nothing to assert")


if __name__ == "__main__":
    unittest.main()
