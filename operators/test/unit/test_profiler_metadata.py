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

"""Design metadata filter correctness tests (no GPU required)."""

import argparse
import re
import typing
from abc import ABC, abstractmethod
from collections.abc import Iterable
from dataclasses import dataclass
from enum import Enum
from typing import Literal

import pytest

import cutlass.operators as ops
from cutlass.operators.arguments import GemmArguments
from cutlass.operators.base import Operator
from cutlass.operators.metadata import (
    BLASDesignMetadata,
    DesignMetadata,
    OperatorMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma, HopperWgmma
from cutlass.operators.providers import available_providers, register_provider
from cutlass.operators.providers.provider import Provider
from cutlass.operators.status import Status
from cutlass.profiler.cli_reflection import (
    build_metadata_filter,
    is_metadata_filter_identity,
)
from cutlass.profiler.cli_reflection.command_line import (
    UNSET_CLI_FIELD,
)
from cutlass.profiler.cli_reflection.fields import iter_metadata_fields
from cutlass.profiler.cli_reflection.metadata import (
    MetadataCliCategory,
    MetadataCliClass,
)
from cutlass.profiler.cli_reflection.registry import DESIGN_REGISTRY

# Test is the same regardless of arch, so pin to sm80.
pytestmark = pytest.mark.arch("80")


@pytest.fixture(scope="module")
def operator_metadata():
    """
    Return a metadata-only snapshot of built-in discovered operators.

    Performance optimization so each test does not need to re-discover all operators.
    Beforehand: 18 tests took 8 minutes to run.
    Now: 18 tests take 26 seconds to run.
    """
    return tuple(
        operator.metadata for operator in ops.get_operators(args=None, target_sm=None)
    )


def _check_design_filter(filter_args, expect_fn, operator_metadata):
    """Build filter, apply it to cached metadata, assert same set.

    Verifies both directions: no extra operators returned (all match)
    and no valid operators excluded (none missing).
    """
    design_filter = build_metadata_filter(filter_args, (DESIGN_REGISTRY,))

    actual = {md.operator_name for md in operator_metadata if design_filter(md)}
    expected = {md.operator_name for md in operator_metadata if expect_fn(md)}

    assert actual == expected, (
        "profiler design filter does not match expected operator set"
    )


class MetadataFilterNamespace(argparse.Namespace):
    """
    Namespace that returns UNSET_CLI_FIELD for all missing attributes.
    This mimics behavior of CLI parsing that cutlass profiler expects
    """

    def __getattr__(self, name: str):
        if name.startswith("__"):
            raise AttributeError(name)
        return UNSET_CLI_FIELD


def _make_filter_namespace(design_type: type | None, **overrides):
    """Build an argparse.Namespace with all fields defaulting to None."""
    ns = {}
    if design_type is not None:
        ns["design"] = design_type
    else:
        ns["design"] = UNSET_CLI_FIELD

    for field in DESIGN_REGISTRY.unique_fields():
        ns[field.add_argument_params.argparse_name] = overrides.get(
            field.add_argument_params.argparse_name, UNSET_CLI_FIELD
        )
    return MetadataFilterNamespace(**ns)


def test_is_metadata_filter_identity():
    """Test is_metadata_filter_identity returns True if no CLI flags are set."""
    ns = MetadataFilterNamespace()
    assert is_metadata_filter_identity(ns, (DESIGN_REGISTRY,))


def test_operator_class_filter_is_not_identity():
    """Test an operator-class regex makes the metadata filter non-identity."""
    ns = MetadataFilterNamespace(
        op_class=re.compile(r"^Sm100PersistentDenseGemmOperator$")
    )
    assert not is_metadata_filter_identity(ns, (DESIGN_REGISTRY,))


def test_build_metadata_filter_matches_operator_class_regex():
    """Test the shared metadata filter applies the operator-class regex."""

    class Sm100PersistentDenseGemmOperator:
        pass

    class Sm100BlockscaledStaticPersistentOperator:
        pass

    ns = MetadataFilterNamespace(
        op_class=re.compile(r"^Sm100PersistentDenseGemmOperator$")
    )
    metadata_filter = build_metadata_filter(ns, (DESIGN_REGISTRY,))

    assert metadata_filter(
        argparse.Namespace(operator_class=Sm100PersistentDenseGemmOperator)
    )
    assert not metadata_filter(
        argparse.Namespace(operator_class=Sm100BlockscaledStaticPersistentOperator)
    )


@pytest.mark.parametrize(
    "design_type, filter_kwargs",
    [
        (Sm100DesignMetadata, {}),
        (Sm100DesignMetadata, {"use_tma_store": True}),
        (Sm100DesignMetadata, {"mma_instruction_type": BlackwellTcgen05Mma}),
        (BLASDesignMetadata, {}),
    ],
)
def test_is_not_metadata_filter_identity(design_type, filter_kwargs):
    """Test is_metadata_filter_identity returns False if any CLI flags are set."""
    ns = _make_filter_namespace(design_type, **filter_kwargs)
    assert not is_metadata_filter_identity(ns, (DESIGN_REGISTRY,))


@pytest.mark.parametrize(
    "design_type, filter_kwargs, expect_fn",
    [
        pytest.param(
            Sm100DesignMetadata,
            {},
            lambda md: isinstance(md.design, Sm100DesignMetadata),
            id="sm100-all",
        ),
        pytest.param(
            BLASDesignMetadata,
            {},
            lambda md: isinstance(md.design, BLASDesignMetadata),
            id="blas-all-subclasses",
        ),
        pytest.param(
            BLASDesignMetadata,
            {"tile_shape": (128, 128, 64)},
            lambda md: (
                isinstance(md.design, BLASDesignMetadata)
                and md.design.tile_shape == (128, 128, 64)
            ),
            id="blas-tile-128x128x64",
        ),
        pytest.param(
            BLASDesignMetadata,
            {"mma_instruction_type": BlackwellTcgen05Mma},
            lambda md: (
                isinstance(md.design, BLASDesignMetadata)
                and md.design.mma_instruction_type is BlackwellTcgen05Mma
            ),
            id="blas-mma-blackwell",
        ),
        pytest.param(
            BLASDesignMetadata,
            {"mma_instruction_type": HopperWgmma},
            lambda md: (
                isinstance(md.design, BLASDesignMetadata)
                and md.design.mma_instruction_type is HopperWgmma
            ),
            id="blas-mma-hopper",
        ),
        pytest.param(
            Sm100DesignMetadata,
            {"use_tma_store": True},
            lambda md: (
                isinstance(md.design, Sm100DesignMetadata)
                and md.design.use_tma_store is True
            ),
            id="sm100-tma-store-true",
        ),
        pytest.param(
            Sm100DesignMetadata,
            {"use_tma_store": False},
            lambda md: (
                isinstance(md.design, Sm100DesignMetadata)
                and md.design.use_tma_store is False
            ),
            id="sm100-tma-store-false",
        ),
        pytest.param(
            Sm100DesignMetadata,
            {"use_2cta_mma": True, "cluster_shape": (2, 1, 1)},
            lambda md: (
                isinstance(md.design, Sm100DesignMetadata)
                and md.design.use_2cta_mma is True
                and md.design.cluster_shape == (2, 1, 1)
            ),
            id="sm100-2cta-cluster-2x1x1",
        ),
    ],
)
def test_design_filter(design_type, filter_kwargs, expect_fn, operator_metadata):
    """Filtered operator set == ground-truth set for each design/constraint combo."""
    _check_design_filter(
        _make_filter_namespace(design_type, **filter_kwargs),
        expect_fn,
        operator_metadata,
    )




def test_omitted_design_with_design_specific_field_selects_for_fields(
    operator_metadata,
):
    """Omitting design should select for operator designs that have the field"""
    _check_design_filter(
        _make_filter_namespace(None, use_tma_store=True),
        lambda md: md.design is not None and getattr(md.design, "use_tma_store", False),
        operator_metadata,
    )


def test_omitted_design_without_fields_matches_all_operators(operator_metadata):
    """Omitting design accepts all Operator classes"""
    _check_design_filter(
        _make_filter_namespace(None),
        lambda md: True,
        operator_metadata,
    )


class TestCustomMetadataCliClasses:
    """Test custom metadata classes and their interactions with the CLI reflection system."""

    def test_nested_metadata_fields_are_flattened(self):
        @dataclass
        class InnerMetadata:
            stages: int
            mode: Literal["fast", "small"]
            fixed_length_tuple: tuple[int, int, int]

        @dataclass
        class OuterMetadata:
            inner: InnerMetadata
            a_b: int

        @dataclass
        class CollisionMetadata:
            a: OuterMetadata
            a_b: int

        fields = list(iter_metadata_fields(CollisionMetadata))
        assert {field.attr_path for field in fields} >= {
            ("a", "inner", "stages"),
            ("a", "inner", "mode"),
            ("a", "inner", "fixed_length_tuple"),
            ("a", "a_b"),
            ("a_b",),
        }
        assert {field.argparse_name for field in fields} >= {
            "a__inner__stages",
            "a__inner__mode",
            "a__inner__fixed_length_tuple",
            "a__a_b",
            "a_b",
        }

    def test_abstract_class_subfields_are_registered(self):
        class FooMode(Enum):
            FAST = 1
            SMALL = 2

        @dataclass
        class FooAbc(ABC):
            @abstractmethod
            def supports(self) -> bool:
                raise NotImplementedError

        @dataclass
        class FooVariantOne(FooAbc):
            mode: FooMode
            tile_shape: tuple[int, ...]

            def supports(self) -> bool:
                return True

        @dataclass
        class FooVariantTwo(FooAbc):
            optional_depth: int | None

            def supports(self) -> bool:
                return True

        @dataclass
        class Root:
            foo: FooAbc
            optional_foo: FooAbc | None = None

        metadata_class = MetadataCliClass.register("root", Root)
        fields_by_path = {field.attr_path: field for field in metadata_class.fields}

        assert fields_by_path[("foo",)].cli_name == "--foo"
        assert fields_by_path[("foo", "mode")].cli_name == "--foo.mode"
        assert fields_by_path[("foo", "tile_shape")].cli_name == "--foo.tile_shape"
        assert (
            fields_by_path[("foo", "optional_depth")].cli_name == "--foo.optional_depth"
        )

        assert fields_by_path[("optional_foo",)].cli_name == "--optional_foo"
        assert (
            fields_by_path[("optional_foo", "mode")].cli_name == "--optional_foo.mode"
        )
        assert (
            fields_by_path[("optional_foo", "tile_shape")].cli_name
            == "--optional_foo.tile_shape"
        )
        assert (
            fields_by_path[("optional_foo", "optional_depth")].cli_name
            == "--optional_foo.optional_depth"
        )

        parse_foo = fields_by_path[("foo",)].add_argument_params.parser
        parse_optional_foo = fields_by_path[
            ("optional_foo",)
        ].add_argument_params.parser

        for variant in (FooVariantOne, FooVariantTwo):
            assert parse_foo(variant.__name__) is variant
            assert parse_optional_foo(variant.__name__) is variant
        assert parse_optional_foo("none") is None

        parse_mode = fields_by_path[("foo", "mode")].add_argument_params.parser
        parse_optional_mode = fields_by_path[
            ("optional_foo", "mode")
        ].add_argument_params.parser
        assert parse_mode("FAST") is FooMode.FAST
        assert parse_optional_mode("SMALL") is FooMode.SMALL

        parse_tile_shape = fields_by_path[
            ("foo", "tile_shape")
        ].add_argument_params.parser
        assert parse_tile_shape("1x2x3") == (1, 2, 3)

        parse_optional_depth = fields_by_path[
            ("foo", "optional_depth")
        ].add_argument_params.parser
        assert parse_optional_depth("7") == 7
        assert parse_optional_depth("none") is None

        with pytest.raises(argparse.ArgumentTypeError):
            parse_foo("MissingFooVariant")

    def test_optional_concrete_dataclass_emits_none_selector(self):
        """An optional concrete dataclass offers ``--foo none`` and its nested fields."""

        @dataclass
        class Scheduler:
            persistence: str
            stages: int

        @dataclass
        class Root:
            scheduler: Scheduler | None = None

        metadata_class = MetadataCliClass.register("optional_concrete", Root)
        fields_by_path = {field.attr_path: field for field in metadata_class.fields}

        assert fields_by_path[("scheduler",)].cli_name == "--scheduler"
        assert (
            fields_by_path[("scheduler", "persistence")].cli_name
            == "--scheduler.persistence"
        )
        assert fields_by_path[("scheduler", "stages")].cli_name == "--scheduler.stages"

        parse_scheduler = fields_by_path[("scheduler",)].add_argument_params.parser
        assert parse_scheduler("Scheduler") is Scheduler
        assert parse_scheduler("none") is None
        with pytest.raises(argparse.ArgumentTypeError):
            parse_scheduler("UnknownScheduler")

    def test_optional_iterable_field_parser(self):
        @dataclass
        class Root:
            flags: typing.Iterable[bool] | None

        metadata_class = MetadataCliClass.register("optional_iterable", Root)
        fields_by_path = {field.attr_path: field for field in metadata_class.fields}

        parse_flags = fields_by_path[("flags",)].add_argument_params.parser
        assert parse_flags("true,false") == (True, False)
        assert parse_flags("none") is None

    def test_variadic_tuple_field_parser(self):
        """tuple[T, ...] is handled like Iterable[T]."""

        class FooMode(Enum):
            FAST = 1
            SMALL = 2

        @dataclass
        class Root:
            modes: tuple[FooMode, ...]

        metadata_class = MetadataCliClass.register("variadic_tuple", Root)
        parse_modes = next(iter(metadata_class.fields)).add_argument_params.parser
        assert parse_modes("FAST,SMALL") == (FooMode.FAST, FooMode.SMALL)

    def test_required_iterable_field_is_a_leaf(self):
        @dataclass(frozen=True, slots=True)
        class EarlyStart:
            independent_operands: Iterable[str] = ()

        @dataclass(frozen=True, slots=True)
        class Root:
            early_start: EarlyStart | None = None

        metadata_class = MetadataCliClass.register("required_iterable", Root)
        fields_by_path = {field.attr_path: field for field in metadata_class.fields}

        # The optional concrete dataclass contributes a none-selector for
        # itself; the iterable stays a leaf rather than being recursed into.
        assert set(fields_by_path) == {
            ("early_start",),
            ("early_start", "independent_operands"),
        }
        parse = fields_by_path[
            ("early_start", "independent_operands")
        ].add_argument_params.parser
        assert parse("A,B") == ("A", "B")

    def test_union_field_parsers_support_leaf_types(self):
        class FooMode(Enum):
            FAST = 1
            SMALL = 2

        @dataclass
        class FooBase(ABC):
            @abstractmethod
            def supports(self) -> bool:
                raise NotImplementedError

        @dataclass
        class FooVariant(FooBase):
            def supports(self) -> bool:
                return True

        @dataclass
        class Root:
            enum_or_float: FooMode | float
            int_or_tuple: int | tuple[int, ...]
            bool_or_int: bool | int
            type_or_literal: type[FooBase] | Literal["auto"]
            iterable_union: typing.Iterable[FooMode | float]

        metadata_class = MetadataCliClass.register("leaf_unions", Root)
        fields_by_path = {field.attr_path: field for field in metadata_class.fields}

        parse_enum_or_float = fields_by_path[
            ("enum_or_float",)
        ].add_argument_params.parser
        assert parse_enum_or_float("FAST") is FooMode.FAST
        assert parse_enum_or_float("2.5") == pytest.approx(2.5)

        parse_int_or_tuple = fields_by_path[
            ("int_or_tuple",)
        ].add_argument_params.parser
        assert parse_int_or_tuple("7") == 7
        assert parse_int_or_tuple("1x2x3") == (1, 2, 3)

        parse_bool_or_int = fields_by_path[("bool_or_int",)].add_argument_params.parser
        assert parse_bool_or_int("true") is True
        assert parse_bool_or_int("7") == 7

        parse_type_or_literal = fields_by_path[
            ("type_or_literal",)
        ].add_argument_params.parser
        assert parse_type_or_literal("FooVariant") is FooVariant
        assert parse_type_or_literal("auto") == "auto"

        parse_iterable_union = fields_by_path[
            ("iterable_union",)
        ].add_argument_params.parser
        assert parse_iterable_union("FAST,2.5,SMALL") == (
            FooMode.FAST,
            2.5,
            FooMode.SMALL,
        )

        with pytest.raises(argparse.ArgumentTypeError):
            parse_enum_or_float("missing")

    def test_abstract_class_filter_function_matches_instances(self):
        class FooMode(Enum):
            FAST = 1
            SMALL = 2

        @dataclass
        class FooAbc(ABC):
            @abstractmethod
            def supports(self) -> bool:
                raise NotImplementedError

        @dataclass
        class FooVariantOne(FooAbc):
            mode: FooMode
            tile_shape: tuple[int, ...]

            def supports(self) -> bool:
                return True

        @dataclass
        class FooVariantTwo(FooAbc):
            optional_depth: int | None

            def supports(self) -> bool:
                return True

        @dataclass
        class Root:
            foo: FooAbc | None = None

        metadata_class = MetadataCliClass.register("root", Root)
        root_category = MetadataCliCategory(
            cli_category_name="--root",
            cli_category_help="Root metadata",
            argparse_dest_name="root",
            operator_metadata_attr="design",
            classes=[metadata_class],
        )
        root_filter = build_metadata_filter(
            MetadataFilterNamespace(
                root=Root,
                foo=FooVariantOne,
            ),
            (root_category,),
        )
        matching_metadata = OperatorMetadata(
            operator_name="test.foo_variant_one",
            operator_class=Operator,
            supported_targets=[ops.TargetSm("80")],
            operands=None,
            design=Root(
                foo=FooVariantOne(
                    mode=FooMode.FAST,
                    tile_shape=(1, 2, 3),
                )
            ),
        )
        non_matching_metadata = OperatorMetadata(
            operator_name="test.foo_variant_two",
            operator_class=Operator,
            supported_targets=[ops.TargetSm("80")],
            operands=None,
            design=Root(foo=FooVariantTwo(optional_depth=7)),
        )

        assert root_filter(matching_metadata)
        assert not root_filter(non_matching_metadata)

    def test_unsupported_metadata_field_type_fails_loudly(self):
        @dataclass
        class UnsupportedMetadata:
            unsupported: dict[str, int]

        with pytest.raises(TypeError, match="unsupported.*dict"):
            list(iter_metadata_fields(UnsupportedMetadata))

    def test_registered_custom_design_filter_finds_custom_operator(self, request):
        @dataclass
        class CustomNestedMetadata:
            stages: int
            mode: Literal["fast", "small"]

        @dataclass
        class CustomDesignMetadata(DesignMetadata):
            nested: CustomNestedMetadata
            enabled: bool

            def supports(self, args, target_sm=None):
                return Status.success()

        class CustomProfilerOperator(Operator):
            operator_name = "test.custom_design_operator"
            supported_args_type = GemmArguments
            designed_for_min_cc = 80

            def _compile(self, args, target_sm=None):
                raise NotImplementedError("test operator is discovery-only")

            def _run(
                self,
                args,
                compiled_artifact,
                stream,
                workspace=None,
                device_properties=None,
            ):
                raise NotImplementedError("test operator is discovery-only")

            @classmethod
            def _generate_operators(
                cls, metadata_filter, epilogue_args=None, target_sm=None, args=None
            ):
                metadata = OperatorMetadata(
                    operator_name=cls.operator_name,
                    operator_class=cls,
                    supported_targets=[ops.TargetSm("80")],
                    operands=None,
                    design=CustomDesignMetadata(
                        nested=CustomNestedMetadata(stages=2, mode="fast"),
                        enabled=True,
                    ),
                )
                return [cls(metadata)] if metadata_filter(metadata) else []

        class CustomProvider(Provider):
            @classmethod
            def generate_operators(
                cls, metadata_filter=None, epilogue_args=None, target_sm=None, args=None
            ):
                return CustomProfilerOperator._generate_operators(
                    metadata_filter or (lambda _: True),
                    epilogue_args=epilogue_args,
                    target_sm=target_sm,
                    args=args,
                )

        CUSTOM_REGISTRY = MetadataCliCategory(
            cli_category_name="--design",
            cli_category_help="Design metadata",
            argparse_dest_name="design",
            operator_metadata_attr="design",
            classes=[MetadataCliClass.register("custom", CustomDesignMetadata)]
            + DESIGN_REGISTRY.classes[:],
        )

        register_provider("custom_test")(CustomProvider)
        request.addfinalizer(lambda: available_providers.pop("custom_test", None))

        design_filter = build_metadata_filter(
            MetadataFilterNamespace(
                design=CustomDesignMetadata,
                nested__stages=2,
                nested__mode="fast",
                enabled=True,
            ),
            (CUSTOM_REGISTRY,),
        )
        operators = ops.get_operators(
            args=None, metadata_filter=design_filter, providers=[CustomProvider()]
        )
        assert {operator.metadata.operator_name for operator in operators} == {
            CustomProfilerOperator.operator_name
        }

    def test_diamond_inheritance_shared_field_not_duplicated(self):
        """x is reachable via both _DiamondA and _DiamondB;
        it must appear exactly once in fields.
        """

        @dataclass
        class _DiamondBase:
            x: int

        @dataclass
        class _DiamondA(_DiamondBase):
            a: int

        @dataclass
        class _DiamondB(_DiamondBase):
            b: int

        @dataclass
        class _DiamondC(_DiamondA, _DiamondB):
            c: int

        metadata_class = MetadataCliClass.register("diamond_c", _DiamondC)
        cli_names = [f.cli_name for f in metadata_class.fields]
        assert cli_names.count("--x") == 1

    def test_nested_vs_flat_field_cli_names_are_distinct(self):
        """Dot syntax keeps nested fields distinct from flat underscore fields."""

        @dataclass
        class _NestedInner:
            z: int

        @dataclass
        class _NestedAndFlat:
            b: _NestedInner  # nested path (b, z) -> cli --b.z, argparse b__z
            b_z: int  # flat path (b_z,) -> cli --b_z, argparse b_z

        metadata_class = MetadataCliClass.register("nested_and_flat", _NestedAndFlat)
        fields_by_path = {field.attr_path: field for field in metadata_class.fields}
        assert fields_by_path[("b", "z")].cli_name == "--b.z"
        assert fields_by_path[("b_z",)].cli_name == "--b_z"

        MetadataCliCategory(
            cli_category_name="--design",
            cli_category_help="Design metadata",
            argparse_dest_name="design",
            operator_metadata_attr="design",
            classes=[metadata_class],
        )

    def test_multilevel_nesting_field_paths(self):
        """Fields nested 3 levels deep produce the correct cli_name and argparse_name."""

        @dataclass
        class _Level2:
            x: int

        @dataclass
        class _Level1:
            c: _Level2

        @dataclass
        class _MultiLevel:
            b: _Level1  # path: b.c.x -> cli --b.c.x, argparse b__c__x

        metadata_class = MetadataCliClass.register("multi", _MultiLevel)
        field = next(f for f in metadata_class.fields if f.attr_path == ("b", "c", "x"))
        assert field.cli_name == "--b.c.x"
        assert field.argparse_name == "b__c__x"
