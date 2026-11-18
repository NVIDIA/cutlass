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

import argparse
import operator
from collections.abc import Callable
from dataclasses import dataclass
from typing import ClassVar


class _UnsetCliField:
    """Sentinel value to determine which CLI fields were not set by user.

    Important for build_metadata_filter
    where we need to know which fields to skip entirely (None can be a valid value).
    """

    num_instances: ClassVar[int] = 0

    def __init__(self) -> None:
        _UnsetCliField.num_instances += 1
        if _UnsetCliField.num_instances > 1:
            raise RuntimeError("Only one instance of UNSET_CLI_FIELD is allowed")

    def __str__(self) -> str:
        return "UNSET_CLI_FIELD"


UNSET_CLI_FIELD = _UnsetCliField()
CLI_ATTRIBUTE_DIVIDER = "."


@dataclass(frozen=True, kw_only=True, slots=True)
class AddArgumentParams:
    """Class representing the configuration parameters for ArgumentParser.add_argument.

    https://docs.python.org/3/library/argparse.html#the-add-argument-method
    """

    cli_name: str
    """Public command-line flag name passed to argparse."""

    help: str
    """Help text displayed for the generated CLI flag."""

    argparse_name: str
    """Unique argparse destination name used on argparse.Namespace.

    Nested path components should be separated with "__" so real underscores in field
    names do not collide with nesting boundaries.
    """

    cli_aliases: tuple[str, ...] = ()
    """Optional aliases for the command-line flag."""

    parser: Callable[[str], object] = lambda x: x
    """Callable used as the argparse ``type`` for this metadata field."""

    choices: tuple[object, ...] | None = None
    """Optional argparse choices for the generated CLI flag."""

    default: object = UNSET_CLI_FIELD
    """Default value used when the flag is omitted."""

    nargs: str | None = None
    """Optional argparse nargs value, used for flags like optional booleans."""

    const: object = None
    """Optional argparse const value, used when a flag is present without value."""

    metavar: str | None = None
    """Displays in help text as placeholder for the argument"""

    deprecated: bool = False
    """Mark flag as deprecated. Only usable in Python 3.13+"""

    def add_argument(
        self, parser: argparse.ArgumentParser, cli_prefix: str = ""
    ) -> object:
        """Add this field as an argument to the parser."""
        cli_name = self.cli_name
        starts_with_dashes = self.cli_name.startswith("--")
        if starts_with_dashes:
            # Need to remove dashes
            cli_name = cli_name[2:]

        cli_name = cli_prefix + cli_name
        return parser.add_argument(
            cli_name,
            *self.cli_aliases,
            **self.as_kwargs(),
        )

    def as_kwargs(self) -> dict[str, object]:
        """Return keyword arguments for argparse.add_argument.

        Keeping this as a typed object makes the supported argparse surface
        explicit while still allowing call sites to use argparse's kwargs API.
        """
        kwargs: dict[str, object] = {
            "dest": self.argparse_name,
            "type": self.parser,
            "default": self.default,
            "help": self.help,
        }

        import sys

        if sys.version_info >= (3, 13):
            # Only available in Python 3.13+
            kwargs["deprecated"] = self.deprecated
        if self.choices is not None:
            kwargs["choices"] = list(self.choices)
        if self.nargs is not None:
            kwargs["nargs"] = self.nargs
        if self.const is not None:
            kwargs["const"] = self.const
        if self.metavar is not None:
            kwargs["metavar"] = self.metavar
        return kwargs


@dataclass(frozen=True, slots=True)
class MetadataCliField:
    """Represents a dataclass field associated with an OperandMetadata-related class.

    Tracks mapping to the original dataclass, argparse CLI flags, and resulting namespace.

    Maps most closely to a field on a particular MetadataCliClass such as Sm100DesignMetadata.use_2cta_mma
    """

    metadata_class: type[object]
    """Class of the metadata object to get the field+value from."""

    attr_path: tuple[str, ...]
    """Attribute path to the leaf field. Excludes the root attribute."""

    add_argument_params: AddArgumentParams
    """Parameters for ArgumentParser.add_argument."""

    match_predicate: Callable[[object, object], bool] = operator.eq
    """Decides whether two parsed values are considered to match for filtering"""

    def matches(self, metadata_field_value: object, cli_value: object) -> bool:
        """Decides whether the metadata field value matches the requested CLI value."""
        return self.match_predicate(metadata_field_value, cli_value)

    @property
    def cli_name(self) -> str:
        """Name that appears as command-line flag."""
        return self.add_argument_params.cli_name

    @property
    def argparse_name(self) -> str:
        """Name that appears as attribute on argparse.Namespace."""
        return self.add_argument_params.argparse_name

    def add_argument(
        self, parser: argparse.ArgumentParser, cli_prefix: str = ""
    ) -> object:
        """Add this field as an argument to the parser.

        Args:
            parser: Adds argument to a Python argparse.ArgumentParser instance.
            cli_prefix: Prefix is added as-is so if you want a divider, append a dash (-) or a dot (.).
                        Include leading dashes (--) if intended for the CLI.

        Returns result of ArgumentParser.add_argument.
        """
        return self.add_argument_params.add_argument(parser, cli_prefix)

    def leaf_value(self, root_object: object) -> object:
        """Return the value of the leaf field from the root object.

        Raises an AttributeError if the leaf field is not found.
        Do note that if None is returned, it means the leaf value was set to None.
        """
        current_object = root_object
        try:
            for attr_name in self.attr_path:
                current_object = getattr(current_object, attr_name)
        except AttributeError as e:
            raise AttributeError(
                f"Attributes {self.attr_path} not found in {root_object!r}"
            ) from e

        return current_object

    def __str__(self) -> str:
        return f"{self.cli_name}:{self.argparse_name}"
