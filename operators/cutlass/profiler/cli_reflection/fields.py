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

"""Build MetadataCliField objects from dataclass type hints."""

import argparse
import dataclasses
import inspect
import operator
import sys
import types
from collections.abc import Callable, Iterable, Iterator, Sequence
from enum import Enum
from typing import Literal, TypeVar, Union, get_args, get_origin, get_type_hints

from .command_line import CLI_ATTRIBUTE_DIVIDER, AddArgumentParams, MetadataCliField

_NONE_STRINGS = ("none",)
_TRUE_STRINGS = ("1", "true", "t", "yes", "y", "on")
_FALSE_STRINGS = ("0", "false", "f", "no", "n", "off")


def iter_metadata_fields(
    metadata_class: type[object], user_provided_modules: Sequence[types.ModuleType] = []
) -> Iterator[MetadataCliField]:
    """Yield all supported leaf metadata fields for a metadata dataclass.

    Args:
        metadata_class: The metadata dataclass to iterate over.
        user_provided_modules: Modules to use for resolving type hints.
                               Workaround for TYPE_CHECKING.
    """
    yield from _iter_metadata_fields(
        root_metadata_class=metadata_class,
        current_metadata_class=metadata_class,
        attr_path=(),
        user_provided_modules=user_provided_modules,
    )


def dispatch_type_hint_as_metadata_field(
    type_hint: object,
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    """Create MetadataCliField from type hint plus the path from class to the field using attr_path.

    Raises if type hint is not supported.
    """
    if not attr_path:
        raise ValueError("Metadata fields require a non-empty attr_path")

    # Types with no generic arguments
    if type_hint is bool:
        return _build_bool_field(metadata_class, attr_path)
    if type_hint is int:
        return _build_metadata_field(
            metadata_class=metadata_class,
            attr_path=attr_path,
            parser=int,
        )
    if type_hint is float:
        return _build_metadata_field(
            metadata_class=metadata_class,
            attr_path=attr_path,
            parser=float,
        )
    if type_hint is str:
        return _build_str_field(metadata_class, attr_path)
    if isinstance(type_hint, type) and issubclass(type_hint, Enum):
        # enum.Enum
        return _build_enum_field(type_hint, metadata_class, attr_path)

    # Types with generic arguments

    # For Hint[X, Y, ...] -> returns Hint
    type_without_generic = get_origin(type_hint)
    # For Hint[X, Y, ...] -> returns (X, Y, Ellipsis)
    generic_arguments = get_args(type_hint)

    if is_optional_type_hint(type_hint):
        # Union[X, None]
        non_none_type_hint = type_hint_from_optional(type_hint)
        non_none_field = dispatch_type_hint_as_metadata_field(
            non_none_type_hint,
            metadata_class,
            attr_path,
        )
        return _build_optional_field(non_none_field)
    if is_union_type_hint(type_hint):
        # Union[X, Y, ...]
        return _build_union_field(type_hint, metadata_class, attr_path)
    if is_int_tuple_type_hint(type_hint):
        # tuple[int, ...]
        return _build_int_tuple_field(type_hint, metadata_class, attr_path)
    if is_iterable_type_hint(type_hint):
        # Iterable[X] or tuple[X, ...]
        return _build_iterable_field(metadata_class, attr_path, type_hint)

    if type_without_generic is Literal:
        # Literal[X, Y, ...]
        return _build_literal_field(type_hint, metadata_class, attr_path)
    if type_without_generic is type:
        # type[X]
        if len(generic_arguments) != 1 or not isinstance(generic_arguments[0], type):
            raise TypeError(
                f"Expected type[X] which can only have 1 argument, but got {type_hint!r}. {generic_arguments!r}"
            )
        return _build_subclasses_field(generic_arguments[0], metadata_class, attr_path)

    raise TypeError(f"unsupported metadata field type {type_hint!r}")


def _iter_metadata_fields(
    *,
    root_metadata_class: type[object],
    current_metadata_class: type[object],
    attr_path: tuple[str, ...],
    user_provided_modules: Sequence[types.ModuleType],
) -> Iterator[MetadataCliField]:
    if not dataclasses.is_dataclass(current_metadata_class):
        raise TypeError(f"{current_metadata_class!r} is not a dataclass")

    type_hints = _get_metadata_type_hints(current_metadata_class, user_provided_modules)
    for dataclass_field in dataclasses.fields(current_metadata_class):
        field_hint: object = type_hints[dataclass_field.name]
        field_path = (*attr_path, dataclass_field.name)

        unhandled_optional = False
        if is_optional_type_hint(field_hint):
            unhandled_optional = True
            field_hint = type_hint_from_optional(field_hint)

        if _is_abstract_metadata_class(field_hint):
            # Abstract class Ex. Foo CLI Arguments
            # 1. --foo subclasses(foo) or --foo none
            field = _build_subclasses_field(field_hint, root_metadata_class, field_path)
            if unhandled_optional:
                field = _build_optional_field(field)
                unhandled_optional = False
            yield field
            # 2. --foo.*fields_of_variants*
            for subclass in _recursive_subclasses(field_hint):
                yield from _iter_metadata_fields(
                    root_metadata_class=root_metadata_class,
                    current_metadata_class=subclass,
                    attr_path=field_path,
                    user_provided_modules=user_provided_modules,
                )
            continue

        if dataclasses.is_dataclass(field_hint):
            # Concrete dataclass with fields.
            if unhandled_optional:
                # Handle optional TileSchedulerMetadata cases.
                field = _build_subclasses_field(
                    field_hint, root_metadata_class, field_path
                )
                yield _build_optional_field(field)
                unhandled_optional = False
            yield from _iter_metadata_fields(
                root_metadata_class=root_metadata_class,
                current_metadata_class=field_hint,
                attr_path=field_path,
                user_provided_modules=user_provided_modules,
            )

            continue

        # Leaf type hint (aka no further recursion)
        field = dispatch_type_hint_as_metadata_field(
            field_hint,
            root_metadata_class,
            field_path,
        )
        if unhandled_optional:
            field = _build_optional_field(field)
        yield field


def _build_metadata_field(
    *,
    metadata_class: type[object],
    attr_path: tuple[str, ...],
    parser: Callable[[str], object],
    choices: tuple[object, ...] | None = None,
    metavar: str | None = None,
    nargs: str | None = None,
    const: object | None = None,
    match_predicate: Callable[[object, object], bool] | None = operator.eq,
) -> MetadataCliField:
    """Creates Metadata field with standardized formats for CLI and argparse interfaces."""
    return MetadataCliField(
        metadata_class=metadata_class,
        attr_path=attr_path,
        match_predicate=match_predicate,
        add_argument_params=AddArgumentParams(
            cli_name=_cli_name(attr_path),
            argparse_name=_argparse_name(attr_path),
            help=_help_text(metadata_class, attr_path),
            parser=parser,
            choices=choices,
            metavar=metavar,
            nargs=nargs,
            const=const,
        ),
    )


def _get_metadata_type_hints(
    metadata_class: type[object],
    user_provided_modules: Sequence[types.ModuleType],
) -> dict[str, object]:
    module_globals = _type_hint_namespace(metadata_class)
    for module in user_provided_modules:
        module_globals.update(vars(module))
    try:
        return get_type_hints(metadata_class, globalns=module_globals)
    except NameError as e:
        raise NameError(
            f"cutlass_profiler could not resolve type hints for {metadata_class!r}. "
            + "Please provide required type modules when registering class to CLI arguments."
        ) from e


def _type_hint_namespace(metadata_class: type[object]) -> dict[str, object]:
    """Returns required variables from class and its parent classes to resolve string type hints into objects upfront.

    Merge all globals of the class to resolve type hints upfront, especially when dealing with __future__.annotations.
    """
    module_globals: dict[str, object] = {}
    # __mro__ gives all all parent classes of metadata_class
    for cls in reversed(metadata_class.__mro__):
        module = sys.modules.get(cls.__module__)
        if module is not None:
            module_globals.update(vars(module))
    return module_globals


def _build_bool_field(
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=_parse_bool,
        choices=(True, False),
        metavar="BOOL",
        nargs="?",
        const=True,
    )


def _build_int_tuple_field(
    type_hint: object,
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    parser = _parser_for_type_hint(type_hint)
    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=parser,
        metavar="MxNxKx...|M,N,K,...",
    )


def _build_iterable_field(
    metadata_class: type[object],
    attr_path: tuple[str, ...],
    type_hint: object,
) -> MetadataCliField:
    item_parser = _parser_for_type_hint(_iterable_item_type(type_hint))
    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=lambda value: _parse_iterable_as_tuple(value, item_parser),
        metavar="v1,v2,v3,...",
    )


def _build_union_field(
    type_hint: object,
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=_parser_for_type_hint(type_hint),
        match_predicate=_type_or_eq_match_predicate,
    )


def _parser_for_type_hint(type_hint: object) -> Callable[[str], object]:
    """Map a supported type hint to the parser used for one CLI value."""
    if type_hint is bool:
        return _parse_bool
    if type_hint is int:
        return int
    if type_hint is float:
        return float
    if type_hint is str:
        return str
    if isinstance(type_hint, type) and issubclass(type_hint, Enum):
        choices = tuple(type_hint)
        return _enum_parser(type_hint, choices)

    type_without_generic = get_origin(type_hint)
    generic_arguments = get_args(type_hint)

    if is_optional_type_hint(type_hint):
        non_none_parser = _parser_for_type_hint(type_hint_from_optional(type_hint))

        def _parse_optional(raw_value: str) -> object:
            if raw_value.lower() in _NONE_STRINGS:
                return None
            return non_none_parser(raw_value)

        return _parse_optional
    if is_union_type_hint(type_hint):
        return _union_parser(generic_arguments)
    if is_int_tuple_type_hint(type_hint):
        num_int_args = (
            len(get_args(type_hint))
            if all(isinstance(arg, int) for arg in get_args(type_hint))
            else None
        )
        return lambda raw_value: _parse_int_tuple(
            raw_value, required_length=num_int_args
        )
    if is_iterable_type_hint(type_hint):
        item_parser = _parser_for_type_hint(_iterable_item_type(type_hint))
        return lambda raw_value: _parse_iterable_as_tuple(raw_value, item_parser)
    if type_without_generic is Literal:
        literal_values = get_args(type_hint)
        if not literal_values:
            raise TypeError("Literal metadata field has no choices")
        return _parse_literal(literal_values)
    if type_without_generic is type:
        if len(generic_arguments) != 1 or not isinstance(generic_arguments[0], type):
            raise TypeError(
                f"Expected type[X] which can only have 1 argument, but got {type_hint!r}. {generic_arguments!r}"
            )
        choices = _subclass_choices(generic_arguments[0])
        return _subclasses_parser(choices)

    raise TypeError(f"unsupported metadata field type {type_hint!r}")


def _build_str_field(
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    """Constructs Metadata field for string."""
    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=str,
    )


def _build_literal_field(
    type_hint: object,
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    """Constructed from Literal[X, Y, ...]."""
    literal_values = get_args(type_hint)
    if not literal_values:
        raise TypeError(f"Literal metadata field {attr_path!r} has no choices")

    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=_parse_literal(literal_values),
        choices=literal_values,
    )


def _build_enum_field(
    enum_type: type[Enum],
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    """Constructed from enum.Enum."""
    choices = tuple(enum_type)
    parser = _enum_parser(enum_type, choices)

    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=parser,
        choices=choices,
        metavar=f"{{{_choice_names(choices)}}}",
    )


def _build_subclasses_field(
    class_type: type,
    metadata_class: type[object],
    attr_path: tuple[str, ...],
) -> MetadataCliField:
    """Constructed from type[X] as a choice between all subclasses of X and X itself."""
    choices = _subclass_choices(class_type)

    return _build_metadata_field(
        metadata_class=metadata_class,
        attr_path=attr_path,
        parser=_subclasses_parser(choices),
        choices=choices,
        metavar="{" + f"{_choice_names(choices)}" + "}",
        match_predicate=_type_or_eq_match_predicate,
    )


def _build_optional_field(
    field: MetadataCliField,
) -> MetadataCliField:
    """Constructed from Union[X, None]."""
    field_params = field.add_argument_params

    def _parse_optional(raw_value: str) -> object:
        if raw_value.lower() in _NONE_STRINGS:
            return None
        return field_params.parser(raw_value)

    choices = field_params.choices
    if choices is not None:
        choices = (*choices, None)
    metavar = field_params.metavar
    if metavar is not None:
        metavar = f"{metavar}|none"

    return dataclasses.replace(
        field,
        add_argument_params=dataclasses.replace(
            field_params,
            parser=_parse_optional,
            choices=choices,
            metavar=metavar,
        ),
    )


def is_optional_type_hint(type_hint: object) -> bool:
    """Checks if a type hint is a Union[X, None]."""
    type_without_generic = get_origin(type_hint)
    generic_arguments = get_args(type_hint)
    return (
        type_without_generic in (types.UnionType, Union)
        and len(generic_arguments) == 2
        and (
            generic_arguments[0] is types.NoneType
            or generic_arguments[1] is types.NoneType
        )
    )


def is_union_type_hint(type_hint: object) -> bool:
    """Checks if a type hint is a non-optional Union."""
    return get_origin(type_hint) in (types.UnionType, Union)


def is_int_tuple_type_hint(type_hint: object) -> bool:
    """Checks for tuple[int, ...] and for fixed-length tuples e.g. tuple[int, int, int]."""
    type_without_generic = get_origin(type_hint)
    generic_arguments = get_args(type_hint)
    return (
        type_without_generic is tuple
        and generic_arguments == (int, Ellipsis)
        or all(arg is int for arg in generic_arguments)
    )


def type_hint_from_optional(type_hint: object) -> type[object]:
    """Returns the type hint of the non-None value from a Union[X, None]."""
    assert is_optional_type_hint(type_hint)
    generic_arguments = get_args(type_hint)
    return (
        generic_arguments[0]
        if generic_arguments[0] is not types.NoneType
        else generic_arguments[1]
    )


def _is_abstract_metadata_class(type_hint: object) -> bool:
    """Checks if a type hint is a bare abstract class to walk subclasses of.

    A parameterized generic such as ``Iterable[str]`` is not a metadata base
    class even though ``inspect.isabstract`` reports it as abstract on Python
    3.10 (the generic alias proxies ``__abstractmethods__`` from its origin).
    Requiring ``get_origin`` to be ``None`` keeps those hints on the leaf
    dispatch path instead of walking the origin's ABC subclasses.
    """
    return get_origin(type_hint) is None and inspect.isabstract(type_hint)


def is_iterable_type_hint(type_hint: object) -> bool:
    """Checks if a type hint is Iterable[T] or tuple[T, ...]."""
    type_without_generic = get_origin(type_hint)
    args = get_args(type_hint)
    return (
        isinstance(type_without_generic, type)
        and issubclass(type_without_generic, Iterable)
        and (len(args) == 1 or (len(args) == 2 and args[1] is Ellipsis))
    )


def _iterable_item_type(type_hint: object) -> object:
    """Returns T from Iterable[T] or tuple[T, ...]."""
    return get_args(type_hint)[0]


def _union_parser(member_types: tuple[object, ...]) -> Callable[[str], object]:
    """Combines parsers for each available type and tries each one in order.

    Raises argparse.ArgumentTypeError if no parser succeeds.
    """
    parsers = tuple(_parser_for_type_hint(member_type) for member_type in member_types)

    def _parse_union(raw_value: str) -> object:
        errors: list[str] = []
        for parser in parsers:
            try:
                return parser(raw_value)
            except (ValueError, TypeError, argparse.ArgumentTypeError) as error:  # noqa: PERF203
                errors.append(str(error))
        raise argparse.ArgumentTypeError(
            f"expected one of: {'; '.join(error for error in errors if error)}"
        )

    return _parse_union


def _enum_parser(
    enum_type: type[Enum], choices: tuple[Enum, ...]
) -> Callable[[str], Enum]:
    """Parses string into a valid value from `choices` of `enum_type` class."""

    def _parse_enum(raw_value: str) -> Enum:
        try:
            return enum_type[raw_value]
        except KeyError as e:
            raise argparse.ArgumentTypeError(
                f"expected one of {_choice_names(choices)}"
            ) from e

    return _parse_enum


def _parse_bool(raw_value: str) -> bool:
    """Parses command-line string into a boolean value."""
    normalized = raw_value.lower()
    if normalized in _TRUE_STRINGS:
        return True
    if normalized in _FALSE_STRINGS:
        return False
    raise argparse.ArgumentTypeError("expected a boolean value")


def _parse_int_tuple(
    raw_value: str, required_length: int | None = None
) -> tuple[int, ...]:
    """Parses command-line string into a tuple of integers.

    >>> assert _parse_int_tuple("1,2,3") == (1, 2, 3)
    >>> assert _parse_int_tuple("1x2x3") == (1, 2, 3)
    """
    normalized = raw_value.replace("x", ",")
    parts = normalized.split(",")
    if any(part == "" for part in parts):
        raise argparse.ArgumentTypeError(
            f"expected integers separated by ',' or 'x': {raw_value!r}"
        )
    try:
        parsed = tuple(int(part) for part in parts)
        if required_length is not None and len(parsed) != required_length:
            raise argparse.ArgumentTypeError(
                f"expected {required_length} integers separated by ',' or 'x': {raw_value!r}"
            )

        return parsed
    except ValueError as e:
        raise argparse.ArgumentTypeError(
            f"expected integers separated by ',' or 'x': {raw_value!r}"
        ) from e


Item = TypeVar("Item")


def _parse_iterable_as_tuple(
    raw_value: str, parse_item: Callable[[str], Item]
) -> tuple[Item, ...]:
    """Parses command-line string into a tuple of integers.

    >>> assert _parse_iterable_as_tuple("1,2,3", int) == (1, 2, 3)
    >>> assert _parse_iterable_as_tuple("1,2,3", str) == ("1", "2", "3")
    """
    parts = raw_value.split(",")
    if any(part == "" for part in parts):
        raise argparse.ArgumentTypeError("expected items separated by ',' or 'x'")
    try:
        return tuple(parse_item(part) for part in parts)
    except ValueError as e:
        raise argparse.ArgumentTypeError("expected items separated by ','") from e


def _parse_literal(literal_values: tuple[object, ...]) -> Callable[[str], object]:
    """Constructs a parser based on the values contained within Literal[...]."""
    literal_by_cli_value: dict[str, object] = {}
    for literal_value in literal_values:
        cli_value = _literal_cli_value(literal_value)
        if cli_value in literal_by_cli_value:
            raise TypeError(f"duplicate Literal CLI spelling {cli_value!r}")
        literal_by_cli_value[cli_value] = literal_value

    def _parse_literal(raw_value: str) -> object:
        normalized = raw_value.lower()
        if normalized in literal_by_cli_value:
            return literal_by_cli_value[normalized]
        raise argparse.ArgumentTypeError(
            f"expected one of {', '.join(literal_by_cli_value)}"
        )

    return _parse_literal


def _literal_cli_value(literal_value: object) -> str:
    """Maps the value contained within Literal[...] to the value passed on the command line.

    >>> assert _literal_cli_value(1) == "1"
    >>> assert _literal_cli_value("hello") == "hello"
    >>> assert _literal_cli_value(None) == "none"
    """
    return str(literal_value).lower()


def _recursive_subclasses(
    base_class: type[object], seen: set[type[object]] | None = None
) -> Iterator[type[object]]:
    """Recursively yields all subclasses.

    Will only iterate over each class once.
    """
    if seen is None:
        seen = set()

    for subclass in base_class.__subclasses__():
        if subclass in seen:
            continue
        # This is a workaround due to how Python handles __slots__=True
        # Python creates a copy of a class when slots=True
        # As such we'll ignore that copy
        if not _is_canonical_class(subclass):
            continue
        seen.add(subclass)

        yield subclass
        yield from _recursive_subclasses(subclass, seen)


def _is_canonical_class(cls: type[object]) -> bool:
    """Workaround because @dataclass can create a second copy of the class.

    As such, the old class appears in the parent class's __subclasses__ list, but is not the same class.
    """
    module = sys.modules.get(cls.__module__)
    if module is None:
        return True
    return getattr(module, cls.__qualname__, cls) is cls


def _subclass_choices(class_type: type[object]) -> tuple[type[object], ...]:
    return (class_type, *tuple(_recursive_subclasses(class_type)))


def _subclasses_parser(
    choices: tuple[type[object], ...],
) -> Callable[[str], type[object]]:
    choices_by_name = _choices_by_name(choices)

    def _parse_type(raw_value: str) -> type[object]:
        try:
            return choices_by_name[raw_value.lower()]
        except KeyError as e:
            raise argparse.ArgumentTypeError(
                f"expected one of {_choice_names(choices)}"
            ) from e

    return _parse_type


def _type_or_eq_match_predicate(metadata_value: object, cli_value: object) -> bool:
    if inspect.isclass(cli_value):
        if not inspect.isclass(metadata_value):
            metadata_value = type(metadata_value)
        return issubclass(metadata_value, cli_value)
    return metadata_value == cli_value


def _choices_by_name(choices: tuple[type[object], ...]) -> dict[str, type[object]]:
    """Maps __name__ to each object representing an argparse choice (X, Y, or Z)."""
    choices_by_name: dict[str, type[object]] = {}
    for choice in choices:
        if choice.__name__ in choices_by_name:
            raise TypeError(f"duplicate type choice name {choice.__name__!r}")
        choices_by_name[choice.__name__.lower()] = choice
    return choices_by_name


def _choice_names(choices: tuple[object, ...]) -> str:
    return ",".join(_choice_name(choice) for choice in choices)


def _choice_name(choice: object) -> str:
    """Constructs the CLI name for a given argparse choice."""
    if isinstance(choice, Enum):
        return choice.name
    if isinstance(choice, type):
        return choice.__name__
    return str(choice)


def _cli_name(attr_path: tuple[str, ...]) -> str:
    """Constructs the CLI name for a given attribute path.

    >>> assert _cli_name(("foo", "bar")) == "--foo.bar"
    >>> assert _cli_name(("foo_bar",)) == "--foo_bar"
    """
    return "--" + CLI_ATTRIBUTE_DIVIDER.join(attr_path)


def _argparse_name(attr_path: tuple[str, ...]) -> str:
    """Constructs the argparse name for a given attribute path.

    >>> assert _argparse_name(("foo", "bar")) == "foo__bar"
    >>> assert _argparse_name(("foo_bar",)) == "foo_bar"
    """
    return "__".join(attr_path)


def _help_text(root_class: type[object], attr_path: tuple[str, ...]) -> str:
    """Constructs the help text for a given attribute path."""
    return f"Filter by metadata field {root_class.__name__}.{'.'.join(attr_path)}"


if __name__ == "__main__":
    import doctest

    print(doctest.testmod())
