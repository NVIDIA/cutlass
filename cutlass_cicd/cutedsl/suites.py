# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

from cutlass_cicd.common.execution import TestContext
from cutlass_cicd.common.log import G_LOGGER, log_call
from cutlass_cicd.common.reporting import JUnitReport
from cutlass_cicd.cutedsl.paths import check_layout
from cutlass_cicd.cutedsl.setup import setup_cutedsl_environment
from cutlass_cicd.cutedsl.tests.cute_export import run_cute_export_flow
from cutlass_cicd.cutedsl.tests.distributed import run_distributed_flow
from cutlass_cicd.cutedsl.tests.examples import run_examples_flow
from cutlass_cicd.cutedsl.tests.notebooks import run_notebook_flow
from cutlass_cicd.cutedsl.tests.pytest_flow import run_pytest_flow
from cutlass_cicd.cutedsl.tests.tvm_ffi import run_tvm_ffi_flow


def run_l0_oss_dsl_test(context: TestContext) -> int:
    report = JUnitReport(testsuites_name="L0_oss_dsl_test")

    try:
        with report.testsuite_runner(
            context,
            "setup",
        ) as runner:
            if not check_layout(context.source_dir):
                runner.fail(
                    "check_layout",
                    "CUTLASS source layout validation failed",
                )
                return 1

            if context.setup_environment:
                configured_context = log_call(
                    G_LOGGER.info,
                    setup_cutedsl_environment,
                    context,
                    runner,
                )
                if configured_context is None:
                    if not report.has_failures("setup"):
                        runner.fail(
                            "setup_cutedsl_environment",
                            "CuTeDSL environment setup failed",
                        )
                    return 1
                context = configured_context

        test_groups = (
            ("pytest", run_pytest_flow),
            # TODO: Re-enable the TVM FFI and CuTe export test groups after
            # their temporary L0_oss_dsl_test disablement is lifted.
            # ("tvm_ffi", run_tvm_ffi_flow),
            # ("cute_export", run_cute_export_flow),
            ("examples", run_examples_flow),
            ("distributed", run_distributed_flow),
            ("notebooks", run_notebook_flow),
        )
        for testsuite_name, run_group in test_groups:
            with report.testsuite_runner(
                context,
                testsuite_name,
            ) as runner:
                log_call(G_LOGGER.info, run_group, context, runner)

        return report.exit_code()
    finally:
        if not context.dry_run:
            report.write(
                context.junit_report_dir / f"{report.testsuites_name}.xml"
            )
