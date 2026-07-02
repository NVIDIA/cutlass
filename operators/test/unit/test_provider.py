# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Unit tests for Provider class and argument type filtering.
"""

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.providers.provider import Provider


class TestProvider(Provider):
    """Test provider for unit testing."""


def args_for_type(args_type: type[ops.RuntimeArguments]) -> ops.RuntimeArguments:
    """Construct arguments for a given argument type."""
    if args_type is ops.GemmArguments:
        return ops.GemmArguments(
            A=torch.empty((1, 1, 1), dtype=torch.float16),
            B=torch.empty((1, 1, 1), dtype=torch.float16),
            out=torch.empty((1, 1, 1), dtype=torch.float16),
            accumulator_type=torch.float16,
        )
    elif args_type is ops.GroupedGemmArguments:
        return ops.GroupedGemmArguments(
            A=torch.empty((1, 1, 1), dtype=torch.float16),
            B=torch.empty((1, 1, 1), dtype=torch.float16),
            out=torch.empty((1, 1, 1), dtype=torch.float16),
            offsets=torch.empty((1,), dtype=torch.int32),
            accumulator_type=torch.float16,
        )
    else:
        raise ValueError(f"Unsupported argument type: {args_type}")


class TestProviderArgumentTypeFiltering:
    """Tests for filtering Operator classes by argument type."""

    def setup_method(self):
        """Reset the test provider's Operator classes before each test."""
        TestProvider._operator_classes_by_argtype = {}

    def test_register_operator_class_with_supported_args_type(self):
        """Operator classes with supported_args_type should register successfully."""

        @TestProvider.register
        class MockGemmOperator(ops.Operator):
            supported_args_type = ops.GemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["gemm_operator"]

        assert ops.GemmArguments in TestProvider._operator_classes_by_argtype
        assert (
            MockGemmOperator
            in TestProvider._operator_classes_by_argtype[ops.GemmArguments]
        )

    def test_generate_operators_filters_by_args_type(self):
        """generate_operators should only call Operator classes matching args_type."""

        @TestProvider.register
        class MockGemmOperator(ops.Operator):
            supported_args_type = ops.GemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["gemm_operator"]

        @TestProvider.register
        class MockGroupedGemmOperator(ops.Operator):
            supported_args_type = ops.GroupedGemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["grouped_gemm_operator"]

        # Filter by GemmArguments - should only get gemm operators
        gemm_operators = TestProvider.generate_operators(
            metadata_filter=None, args=args_for_type(ops.GemmArguments)
        )
        assert gemm_operators == ["gemm_operator"]

        # Filter by GroupedGemmArguments - should only get grouped gemm operators
        grouped_operators = TestProvider.generate_operators(
            metadata_filter=None, args=args_for_type(ops.GroupedGemmArguments)
        )
        assert grouped_operators == ["grouped_gemm_operator"]

    def test_generate_operators_returns_all_when_args_type_is_none(self):
        """generate_operators should return all operators when args_type is None."""

        @TestProvider.register
        class MockGemmOperator(ops.Operator):
            supported_args_type = ops.GemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["gemm_operator"]

        @TestProvider.register
        class MockGroupedGemmOperator(ops.Operator):
            supported_args_type = ops.GroupedGemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["grouped_gemm_operator"]

        # No args filter - should get all operators
        all_operators = TestProvider.generate_operators()
        assert set(all_operators) == {"gemm_operator", "grouped_gemm_operator"}

    def test_multiple_operators_same_args_type(self):
        """Multiple Operator classes with the same args_type should all be returned."""

        @TestProvider.register
        class MockGemmOperator1(ops.Operator):
            supported_args_type = ops.GemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["gemm_operator_1"]

        @TestProvider.register
        class MockGemmOperator2(ops.Operator):
            supported_args_type = ops.GemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["gemm_operator_2"]

        operators = TestProvider.generate_operators(
            metadata_filter=None, args=args_for_type(ops.GemmArguments)
        )
        assert set(operators) == {"gemm_operator_1", "gemm_operator_2"}


class TestProviderSubclassIsolation:
    """Tests that different provider subclasses have isolated state."""

    def test_subclasses_have_separate_operator_dicts(self):
        """Each provider subclass should have its own _operator_classes_by_argtype."""

        class ProviderA(Provider):
            pass

        class ProviderB(Provider):
            pass

        @ProviderA.register
        class MockOperatorA(ops.Operator):
            supported_args_type = ops.GemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["operator_a"]

        @ProviderB.register
        class MockOperatorB(ops.Operator):
            supported_args_type = ops.GemmArguments

            @classmethod
            def generate_operators(
                cls, metadata_filter, epilogue_args, target_sm, args
            ):
                return ["operator_b"]

        # Each provider should only have its own operator
        operators_a = ProviderA.generate_operators(
            metadata_filter=None, args=args_for_type(ops.GemmArguments)
        )
        operators_b = ProviderB.generate_operators(
            metadata_filter=None, args=args_for_type(ops.GemmArguments)
        )

        assert operators_a == ["operator_a"]
        assert operators_b == ["operator_b"]


class TestOperatorSubclassRequirements:
    """Tests for required class attributes on concrete Operator subclasses."""

    def test_missing_supported_args_type_raises_at_class_definition(self):
        with pytest.raises(TypeError, match="supported_args_type"):

            class MissingSupportedArgsTypeOperator(ops.Operator):
                designed_for_min_cc = 80

                def _compile(self, args, target_sm=None):
                    raise NotImplementedError

                def _run(self, args, compiled_artifact, stream, workspace=None):
                    raise NotImplementedError

                @classmethod
                def _generate_operators(
                    cls,
                    metadata_filter,
                    epilogue_args=None,
                    target_sm=None,
                    args=None,
                ):
                    return []

    def test_missing_designed_for_min_cc_raises_at_class_definition(self):
        with pytest.raises(TypeError, match="designed_for_min_cc"):

            class MissingMinCcOperator(ops.Operator):
                supported_args_type = ops.GemmArguments

                def _compile(self, args, target_sm=None):
                    raise NotImplementedError

                def _run(self, args, compiled_artifact, stream, workspace=None):
                    raise NotImplementedError

                @classmethod
                def _generate_operators(
                    cls,
                    metadata_filter,
                    epilogue_args=None,
                    target_sm=None,
                    args=None,
                ):
                    return []
