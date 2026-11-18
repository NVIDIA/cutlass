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

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from .fields import iter_metadata_fields

if TYPE_CHECKING:
    import types
    from collections.abc import Iterator, Sequence

    from cutlass.profiler.cli_reflection.command_line import MetadataCliField


@dataclass(frozen=True, slots=True)
class MetadataCliClass:
    """Maps a dataclass to a CLI value and its Python type.

    Maps most closely to each implementor of an ABC category class like Sm100DesignMetadata, BLASDesignMetadata, etc.
    """

    cli_name: str
    class_type: type[object]
    fields: list[MetadataCliField]

    @classmethod
    def register(
        cls,
        cli_name: str,
        metadata_class: type[object],
        user_provided_modules: Sequence[types.ModuleType] = [],
    ) -> MetadataCliClass:
        """Create a registered metadata class and discover its filterable fields."""
        fields = list(iter_metadata_fields(metadata_class, user_provided_modules))
        return cls(cli_name=cli_name, class_type=metadata_class, fields=fields)

    def __str__(self) -> str:
        return f"{self.cli_name}[{','.join(field.cli_name for field in self.fields)}]"


@dataclass(slots=True, kw_only=True)
class MetadataCliCategory:
    """For a metadata category, stores all metadata classes and their CLI values.

    Maps most closely to each top-level ABC class like DesignMetadata, OperandsMetadata, etc.
    """

    cli_category_name: str
    """CLI Name that'll appear as a flag"""
    cli_category_help: str
    """Help string for CLI flag"""
    argparse_dest_name: str
    """argparse.Namespace attribute name"""
    operator_metadata_attr: str
    """Name of attribute on OperatorMetadata
    Ex. OperatorMetadata.design -> 'design'
    """
    classes: list[MetadataCliClass]
    """List of classes within the category and associated subfields.
    Ex. 'design' -> [BLASDesignMetadata, Sm100DesignMetadata, ...]"""

    def register(self, metadata_class: MetadataCliClass) -> None:
        """Register a metadata class for the category."""
        self.classes.append(metadata_class)

    def all_fields(self) -> Iterator[MetadataCliField]:
        """Returns all fields from all classes."""
        for c in self.classes:
            yield from c.fields

    def unique_fields(self) -> Iterator[MetadataCliField]:
        """Returns deduplicated list of fields from all classes.

        Assumes that if they have the same cli_name,
        it is safe to deduplicate them.
        """
        seen_cli_names: set[str] = set()
        for field in self.all_fields():
            if field.add_argument_params.cli_name in seen_cli_names:
                continue
            seen_cli_names.add(field.add_argument_params.cli_name)
            yield field

    def _check_invariants(self) -> None:
        """Captures invariants for the category.

        1. Two fields with the same cli_name cannot have
        different argparse destination names and vice versa.

        Should be called after every method that mutates Self.
        """
        seen_by_cli: dict[str, MetadataCliField] = {}
        seen_by_dest: dict[str, MetadataCliField] = {}

        for cls in self.classes:
            for field in cls.fields:
                params = field.add_argument_params

                if params.cli_name in seen_by_cli:
                    existing = seen_by_cli[params.cli_name].add_argument_params
                    if existing.argparse_name != params.argparse_name:
                        raise TypeError(
                            f"CLI Field {params.cli_name} has conflicting argparse names: "
                            + f"{params.argparse_name} and {existing.argparse_name}"
                        )
                    continue

                if params.argparse_name in seen_by_dest:
                    existing = seen_by_dest[params.argparse_name].add_argument_params
                    if existing.cli_name != params.cli_name:
                        raise TypeError(
                            f"Argparse Field {params.argparse_name} has conflicting CLI names: "
                            + f"{params.cli_name} and {existing.cli_name}"
                        )

                seen_by_cli[params.cli_name] = field
                seen_by_dest[params.argparse_name] = field

    def __str__(self) -> str:
        return f"{self.cli_category_name}[{', '.join(cls.cli_name for cls in self.classes)}]"

    def __post_init__(self) -> None:
        self._check_invariants()
