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

"""Build argparse options and metadata predicates from discovered fields."""

from __future__ import annotations

import argparse
from typing import TYPE_CHECKING

from .command_line import (
    CLI_ATTRIBUTE_DIVIDER,
    UNSET_CLI_FIELD,
    MetadataCliField,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Sequence

    from cutlass.operators.metadata import OperatorMetadata

    from .metadata import MetadataCliCategory


def add_cli_arguments(
    parser: argparse.ArgumentParser,
    metadata_category: MetadataCliCategory,
) -> list[argparse.Action]:
    """Register one metadata category and the fields of its classes with the parser.

    Returns the argparse return values for the added arguments. Category action is first.
    """
    classes_by_cli_name = {cls.cli_name: cls for cls in metadata_category.classes}

    def parse_metadata_class(raw_value: str) -> type[object]:
        try:
            return classes_by_cli_name[raw_value].class_type
        except KeyError as e:
            valid = ", ".join(classes_by_cli_name)
            raise argparse.ArgumentTypeError(
                f"expected one of {valid}. Got {raw_value!r}."
            ) from e

    meta_var = ", ".join(cls.cli_name for cls in metadata_category.classes)

    category_action = parser.add_argument(
        metadata_category.cli_category_name,
        help=metadata_category.cli_category_help,
        type=parse_metadata_class,
        dest=metadata_category.argparse_dest_name,
        choices=[cls.class_type for cls in metadata_category.classes],
        metavar=f"{meta_var}",
        default=UNSET_CLI_FIELD,
    )
    parser_actions = [category_action]

    category_prefix = metadata_category.cli_category_name + CLI_ATTRIBUTE_DIVIDER
    for metadata_field in metadata_category.unique_fields():
        field_action = metadata_field.add_argument(parser, category_prefix)
        parser_actions.append(field_action)

    return parser_actions


def is_metadata_filter_identity(
    cli_namespace: argparse.Namespace,
    metadata_categories: Sequence[MetadataCliCategory],
) -> bool:
    """Checks build_metadata_filter output will be the identity filter.

    This is only the case if no operator-class or metadata-category filters are set.

    If return is True, the metadata filter is equivalent to lambda _: True
    """
    operator_class_pattern = getattr(cli_namespace, "op_class", None)
    if (
        operator_class_pattern is not None
        and operator_class_pattern is not UNSET_CLI_FIELD
    ):
        return False

    for category in metadata_categories:
        # Ensure category is not set
        cli_category_value = getattr(cli_namespace, category.argparse_dest_name)
        if cli_category_value is not UNSET_CLI_FIELD:
            return False

        # Ensure all fields for category are not set
        for metadata_field in category.unique_fields():
            cli_field_value = getattr(cli_namespace, metadata_field.argparse_name)
            if cli_field_value is not UNSET_CLI_FIELD:
                return False
    return True


def build_metadata_filter(
    cli_namespace: argparse.Namespace,
    metadata_categories: Sequence[MetadataCliCategory],
) -> Callable[[OperatorMetadata], bool]:
    """Build a metadata filter from the parsed CLI arguments and metadata fields.

    Filter can be passed into get_operators()
    """
    _validate_metadata_namespace(cli_namespace, metadata_categories)

    operator_class_pattern = getattr(cli_namespace, "op_class", None)
    if operator_class_pattern is UNSET_CLI_FIELD:
        operator_class_pattern = None

    if is_metadata_filter_identity(cli_namespace, metadata_categories):
        # Short-circuit if the metadata filter matches all operators
        # Not functionally necessary but improves perf of the metadata filter
        return lambda _: True

    def _filter_category(
        metadata: OperatorMetadata, category: MetadataCliCategory
    ) -> bool:
        cli_category_value = getattr(cli_namespace, category.argparse_dest_name)
        if cli_category_value is UNSET_CLI_FIELD:
            # All values are valid if user did not set CLI flag
            return True

        # Check metadata if it has this class set for category
        operator_category_value = getattr(metadata, category.operator_metadata_attr)

        # If user set cli value, then operator metadata value should be equal
        return isinstance(operator_category_value, cli_category_value)

    def _filter_field(
        metadata: OperatorMetadata,
        category: MetadataCliCategory,
        field: MetadataCliField,
    ) -> bool:
        # Grab value from CLI
        # If CLI raises, it's a legitimate error. Bug in metadata_field.
        cli_value = getattr(
            cli_namespace,
            field.argparse_name,
        )
        if cli_value is UNSET_CLI_FIELD:
            # All values are valid if user did not set CLI flag
            return True

        # Grab the relevant object from OperatorMetadata
        root_metadata = getattr(
            metadata,
            category.operator_metadata_attr,
        )

        # Grab value from metadata
        try:
            value = field.leaf_value(root_metadata)
        except AttributeError:
            # If metadata raises, the operator is not valid for filter
            return False

        return field.matches(value, cli_value)

    def _filter(metadata: OperatorMetadata) -> bool:
        if (
            operator_class_pattern is not None
            and operator_class_pattern.search(metadata.operator_class.__name__) is None
        ):
            return False

        for category in metadata_categories:
            if not _filter_category(metadata, category):
                return False

            for metadata_field in category.unique_fields():
                if not _filter_field(metadata, category, metadata_field):
                    return False

        return True

    return _filter


def _validate_metadata_namespace(
    cli_namespace: argparse.Namespace,
    metadata_categories: Sequence[MetadataCliCategory],
) -> None:
    """Validate CLI Metadata Category invariants.

    Within a category, all flags set should be within the selected metadata class.
    If no class is selected, all flags should at least be within one of the classes.
    """
    for category in metadata_categories:
        fields_by_argparse_name, argparse_names_by_class_type = (
            _category_metadata_cli_fields(category)
        )
        selected_field_names = {
            argparse_name
            for argparse_name in fields_by_argparse_name
            if getattr(cli_namespace, argparse_name) is not UNSET_CLI_FIELD
        }

        selected_class: object = getattr(cli_namespace, category.argparse_dest_name)
        if selected_class is UNSET_CLI_FIELD:
            _validate_without_selected_metadata_class(
                category,
                selected_field_names,
                fields_by_argparse_name,
                argparse_names_by_class_type,
            )
        else:
            if not isinstance(selected_class, type):
                valid_values = ", ".join(cls.cli_name for cls in category.classes)
                raise ValueError(
                    f"{category.cli_category_name}: expected one of {valid_values}"
                )
            _validate_selected_metadata_class(
                category,
                selected_class,
                selected_field_names,
                fields_by_argparse_name,
                argparse_names_by_class_type,
            )


def _category_metadata_cli_fields(
    category: MetadataCliCategory,
) -> tuple[dict[str, MetadataCliField], dict[type[object], set[str]]]:
    fields_by_argparse_name: dict[str, MetadataCliField] = {}
    argparse_names_by_class_type: dict[type[object], set[str]] = {}

    for metadata_class in category.classes:
        argparse_names_for_class: set[str] = set()
        for field in metadata_class.fields:
            _ = fields_by_argparse_name.setdefault(field.argparse_name, field)
            argparse_names_for_class.add(field.argparse_name)
        argparse_names_by_class_type[metadata_class.class_type] = (
            argparse_names_for_class
        )

    return fields_by_argparse_name, argparse_names_by_class_type


def _validate_selected_metadata_class(
    category: MetadataCliCategory,
    selected_class: type[object],
    selected_field_names: set[str],
    fields_by_argparse_name: dict[str, MetadataCliField],
    argparse_names_by_class_type: dict[type[object], set[str]],
) -> None:
    """Ensures that all fields belong to the selected metadata class."""
    try:
        valid_field_names = argparse_names_by_class_type[selected_class]
    except KeyError as e:
        valid_values = ", ".join(cls.cli_name for cls in category.classes)
        raise ValueError(
            f"{category.cli_category_name}: expected one of {valid_values}"
        ) from e

    invalid_field_names = selected_field_names - valid_field_names
    if not invalid_field_names:
        return

    invalid_cli_names = _metadata_field_cli_names(
        invalid_field_names,
        fields_by_argparse_name,
    )
    raise ValueError(
        f"{category.cli_category_name} {selected_class.__name__} "
        + f"does not support metadata filter flag(s): {invalid_cli_names}"
    )


def _validate_without_selected_metadata_class(
    category: MetadataCliCategory,
    selected_field_names: set[str],
    fields_by_argparse_name: dict[str, MetadataCliField],
    argparse_names_by_class_type: dict[type[object], set[str]],
) -> None:
    """Ensures that selected fields can be satisfied by 1 or more registered metadata classes.

    e.g. --design.use_2cta_mma and --design.use_tma_store are both valid because Sm100 supports both
    Turns what would be a filter resulting in 0 operators into an early-error.
    """
    # If only one field is selected, it is always valid
    # This is because argparse would have raised an error if the field did not exist.
    if len(selected_field_names) <= 1:
        return

    satisfiable_classes = [
        class_type
        for class_type, argparse_names in argparse_names_by_class_type.items()
        if selected_field_names <= argparse_names
    ]
    if satisfiable_classes:
        return

    invalid_cli_names = _metadata_field_cli_names(
        selected_field_names,
        fields_by_argparse_name,
    )
    raise ValueError(
        f"{category.cli_category_name} metadata filter flags cannot all apply "
        + f"to the same registered metadata class: {invalid_cli_names}"
    )


def _metadata_field_cli_names(
    field_names: set[str],
    fields_by_argparse_name: dict[str, MetadataCliField],
) -> str:
    return ", ".join(
        sorted(
            fields_by_argparse_name[argparse_name].cli_name
            for argparse_name in field_names
        )
    )
