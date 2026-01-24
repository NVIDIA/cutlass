# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from abc import ABC, ABCMeta, abstractmethod
from typing import Type, Union, Optional, Any, overload

from .typing import Shape, Layout, Tile, Tensor, Numeric, Int32
from .core import (
    composition,
    coalesce,
    left_inverse,
    filter,
    pretty_str,
    is_static,
    make_layout,
    make_layout_tv,
    rank,
    size,
    static,
)
from .tuple import product_each

# Internal utils
from .core import _unpack_x_tuple, _pack_shape, _pack_coord, _pack_tile
from .tensor import _Tensor, make_tensor

from cutlass.cutlass_dsl import extract_mlir_values, new_from_mlir_values, dsl_user_op

from cutlass._mlir import ir
from cutlass._mlir.dialects import cute as _cute_ir
from cutlass._mlir.dialects import cute_nvgpu as _cute_nvgpu_ir


class Op(ABC):
    """
    Operation abstract base class.
    """

    pass


class MmaOp(Op, metaclass=ABCMeta):
    """
    MMA Operation abstract base class.
    """

    @abstractmethod
    def _make_trait(self, *, loc=None, ip=None, **kwargs):
        pass


class CopyOp(Op, metaclass=ABCMeta):
    """
    Copy Operation abstract base class.
    """

    @abstractmethod
    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ):
        pass


class Trait(ABC):
    """
    Trait abstract base class.

    Traits are internal-only classes used by Atoms that wrap the underlying IR Value. The Python
    user should only interact with Ops and Atoms.
    """

    def __init__(self, value: ir.Value) -> None:
        self.value = value

    def __extract_mlir_values__(self):
        return [self.value]

    def __new_from_mlir_values__(self, values):
        return self.__class__(values[0])

    def set(self, field, value, *, loc=None, ip=None) -> None:
        raise NotImplementedError(
            "set not implemented, the requesting Atom has likely no runtime state"
        )

    def get(self, field, *, loc=None, ip=None) -> Any:
        raise NotImplementedError(
            "get not implemented, the requesting Atom has likely no runtime state"
        )

    def unpack(self, *, loc=None, ip=None, **kwargs) -> ir.Value:
        return self.value

    def with_(self, *, loc=None, ip=None, **kwargs) -> "Trait":
        return self.__class__(self.unpack(loc=loc, ip=ip, **kwargs))


def make_atom(ty, values=None, *, loc=None, ip=None):
    """
    This is a wrapper around the _cute_ir.make_atom operation, providing default value for the values argument.
    """
    if values is None:
        values = []
    return _cute_ir.make_atom(ty, values, loc=loc, ip=ip)


class Atom(ABC):
    """
    Atom base class.

    An Atom is the composition of

    - a MMA or Copy Operation;
    - an internal MMA or Copy Trait.

    An Operation is a pure Python class that is used to model a specific MMA or Copy instruction.
    The Trait wraps the underlying IR Value and provides access to the metadata of the instruction
    encoded using CuTe Layouts. When the Trait can be constructed straighforwardly from an
    Operation, the ``make_mma_atom`` or ``make_copy_atom`` API should be used. There are cases where
    constructing the metadata is not trivial and requires more information, for example to determine
    the number of bytes copied per TMA instruction ("the TMA vector length"). In such cases,
    dedicated helper functions are provided with an appropriate API such that the Atom is
    constructed internally in an optimal fashion for the user.
    """

    def __init__(self, op: Op, trait: Trait) -> None:
        self._op = op
        self._trait = trait

    def __extract_mlir_values__(self):
        return extract_mlir_values(self._trait) + extract_mlir_values(self._op)

    def __new_from_mlir_values__(self, values):
        traits_value = values[: len(extract_mlir_values(self._trait))]
        op_value = values[len(extract_mlir_values(self._trait)) :]

        new_trait = new_from_mlir_values(self._trait, traits_value)
        new_op = new_from_mlir_values(self._op, op_value)
        return self.__class__(new_op, new_trait)

    @property
    def op(self) -> Op:
        return self._op

    @property
    def type(self):
        return self._trait.value.type

    @dsl_user_op
    def set(self, modifier, value, *, loc=None, ip=None) -> None:
        """
        Sets runtime fields of the Atom.

        Some Atoms have runtime state, for example a tcgen05 MMA Atom


        .. code-block:: python

            tiled_mma = cute.make_tiled_mma(some_tcgen05_mma_op)
            tiled_mma.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

        The ``set`` method provides a way to the user to modify such runtime state. Modifiable
        fields are provided by arch-specific enumerations, for example ``tcgen05.Field``. The Atom
        instance internally validates the field as well as the value provided by the user to set
        the field to.
        """
        self._trait.set(modifier, value, loc=loc, ip=ip)

    @dsl_user_op
    def get(self, field, *, loc=None, ip=None) -> Any:
        """
        Gets runtime fields of the Atom.

        Some Atoms have runtime state, for example a tcgen05 MMA Atom

        .. code-block:: python

            tiled_mma = cute.make_tiled_mma(some_tcgen05_mma_op)
            accum = tiled_mma.get(cute.nvgpu.tcgen05.Field.ACCUMULATE)

        The ``get`` method provides a way to the user to access such runtime state. Modifiable
        fields are provided by arch-specific enumerations, for example ``tcgen05.Field``. The Atom
        instance internally validates the field as well as the value provided by the user to set
        the field to.
        """
        return self._trait.get(field, loc=loc, ip=ip)

    def with_(self, *, loc=None, ip=None, **kwargs) -> "Atom":
        """
        Returns a new Atom with the new Operation and Trait with the given runtime state. The runtime state
        is provided as keyword arguments and it is Atom-specific.

        .. code-block:: python

            tiled_copy = cute.make_tiled_copy(tma_copy_op)
            new_tiled_copy = tiled_copy.with_(tma_bar_ptr=tma_bar_ptr, cache_policy=cute.CacheEvictionPriority.EVICT_LAST)

        The ``with_`` method provides a way to the user to modify such runtime state or create an executable Atom
        (e.g. an Executable TMA Load Atom).
        """
        return self.__class__(self.op, self._trait.with_(loc=loc, ip=ip, **kwargs))

    def _unpack(self, *, loc=None, ip=None, **kwargs) -> ir.Value:
        return self._trait.unpack(loc=loc, ip=ip, **kwargs)


####################################################################################################
#
# MMA Atoms, TiledMma, and ThrMma
#
####################################################################################################


class MmaAtom(Atom):
    """
    The MMA Atom class.
    """

    def __str__(self) -> str:
        res = "MMA Atom\n"
        res += "  ThrID:       " + pretty_str(self.thr_id) + "\n"
        res += "  Shape MNK:   " + pretty_str(self.shape_mnk) + "\n"
        res += "  TV Layout A: " + pretty_str(self.tv_layout_A) + "\n"
        res += "  TV Layout B: " + pretty_str(self.tv_layout_B) + "\n"
        res += "  TV Layout C: " + pretty_str(self.tv_layout_C)
        return res

    #
    # Properties
    #

    @property
    @dsl_user_op
    def thr_id(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.thr_id, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def shape_mnk(self, *, loc=None, ip=None) -> Shape:
        return _unpack_x_tuple(self._trait.value.type.shape_mnk, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def tv_layout_A(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.layout_a_tv, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def tv_layout_B(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.layout_b_tv, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def tv_layout_C(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.layout_c_tv)

    #
    # make_fragment
    #

    @dsl_user_op
    def make_fragment_A(self, input, *, loc=None, ip=None):
        # input could be memref/shape/layout for tmem based fragment
        if isinstance(input, _Tensor):
            if self.op is not None:
                self.op._verify_fragment_A(input, loc=loc, ip=ip)
            input = input.value
        if isinstance(input, tuple):
            input = _pack_shape(input, loc=loc, ip=ip)
        return _cute_ir.mma_make_fragment(
            _cute_ir.MmaOperand.A, self._trait.value, input, loc=loc, ip=ip
        )

    @dsl_user_op
    def make_fragment_B(self, input, *, loc=None, ip=None):
        if isinstance(input, _Tensor):
            if self.op is not None:
                self.op._verify_fragment_B(input, loc=loc, ip=ip)
            input = input.value
        return _cute_ir.mma_make_fragment(
            _cute_ir.MmaOperand.B, self._trait.value, input, loc=loc, ip=ip
        )

    @dsl_user_op
    def make_fragment_C(self, input, *, loc=None, ip=None):
        # input could be memref/shape/layout for tmem based fragment
        if isinstance(input, _Tensor):
            input = input.value
        if isinstance(input, tuple):
            input = _pack_shape(input, loc=loc, ip=ip)
        return _cute_ir.mma_make_fragment(
            _cute_ir.MmaOperand.C, self._trait.value, input, loc=loc, ip=ip
        )


class TiledMma(MmaAtom):
    """
    The tiled MMA class.
    """

    def __str__(self) -> str:
        res = "Tiled MMA\n"
        res += "  Thr Layout VMNK: " + pretty_str(self.thr_layout_vmnk) + "\n"
        res += "  Permutation MNK: " + pretty_str(self.permutation_mnk) + "\n"
        res += "MMA Atom\n"
        res += "  ThrID:           " + pretty_str(self.thr_id) + "\n"
        res += "  Shape MNK:       " + pretty_str(self.shape_mnk) + "\n"
        res += "  TV Layout A:     " + pretty_str(self.tv_layout_A) + "\n"
        res += "  TV Layout B:     " + pretty_str(self.tv_layout_B) + "\n"
        res += "  TV Layout C:     " + pretty_str(self.tv_layout_C)
        return res

    #
    # Properties
    #

    @property
    @dsl_user_op
    def tv_layout_A_tiled(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.layout_a_tv_tiled, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def tv_layout_B_tiled(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.layout_b_tv_tiled, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def tv_layout_C_tiled(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.layout_c_tv_tiled, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def permutation_mnk(self, *, loc=None, ip=None) -> Tile:
        return _unpack_x_tuple(self._trait.value.type.permutation_mnk, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def thr_layout_vmnk(self, *, loc=None, ip=None) -> Layout:
        return static(self._trait.value.type.thr_layout_vmnk, loc=loc, ip=ip)

    @property
    def size(self) -> int:
        return self._trait.value.type.size

    #
    # Tiler
    #

    def get_tile_size(self, mode_idx: int) -> Shape:
        assert (mode_idx >= 0) and (mode_idx < 3)
        perm_tile = self.permutation_mnk[mode_idx]
        if perm_tile is None:
            thr_layout_vmnk = self.thr_layout_vmnk
            atom_shape_mnk = self.shape_mnk
            return size(atom_shape_mnk, mode=[mode_idx]) * size(
                thr_layout_vmnk, mode=[mode_idx + 1]
            )
        else:
            return size(perm_tile)

    #
    # get_slice
    #

    def get_slice(self, thr_idx: Union[int, Int32]) -> "ThrMma":
        return ThrMma(self.op, self._trait, thr_idx)

    #
    # partition_shape
    #

    def _partition_shape(self, operand_id, shape, *, loc=None, ip=None):
        shape = _pack_shape(shape, loc=loc, ip=ip)
        return _unpack_x_tuple(
            _cute_ir.tiled_mma_partition_shape(
                operand_id, self._trait.value, shape, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def partition_shape_A(self, shape_mk, *, loc=None, ip=None):
        return self._partition_shape(_cute_ir.MmaOperand.A, shape_mk, loc=loc, ip=ip)

    @dsl_user_op
    def partition_shape_B(self, shape_nk, *, loc=None, ip=None):
        return self._partition_shape(_cute_ir.MmaOperand.B, shape_nk, loc=loc, ip=ip)

    @dsl_user_op
    def partition_shape_C(self, shape_mn, *, loc=None, ip=None):
        return self._partition_shape(_cute_ir.MmaOperand.C, shape_mn, loc=loc, ip=ip)

    #
    # _thrfrg
    #

    @overload
    def _thrfrg(self, operand_id, input: Layout, *, loc=None, ip=None) -> Layout: ...

    @overload
    def _thrfrg(self, operand_id, input: Tensor, *, loc=None, ip=None) -> Tensor: ...

    def _thrfrg(self, operand_id, input, *, loc=None, ip=None) -> Union[Tensor, Layout]:
        if isinstance(input, Tensor):
            return make_tensor(
                input.iterator,
                self._thrfrg(operand_id, input.layout, loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        elif isinstance(input, Layout):
            if not is_static(input.type):
                raise ValueError(f"Expects a static layout but got {input.type}")
            return static(
                self._trait.value.type.thrfrg(operand_id, input), loc=loc, ip=ip
            )

        raise ValueError(
            f"Expects a layout or a tensor as input but got {type(input)=}"
        )

    def _thrfrg_A(
        self, input: Union[Layout, Tensor], *, loc=None, ip=None
    ) -> Union[Layout, Tensor]:
        return self._thrfrg(_cute_ir.MmaOperand.A, input, loc=loc, ip=ip)

    def _thrfrg_B(
        self, input: Union[Layout, Tensor], *, loc=None, ip=None
    ) -> Union[Layout, Tensor]:
        return self._thrfrg(_cute_ir.MmaOperand.B, input, loc=loc, ip=ip)

    def _thrfrg_C(
        self, input: Union[Layout, Tensor], *, loc=None, ip=None
    ) -> Union[Layout, Tensor]:
        return self._thrfrg(_cute_ir.MmaOperand.C, input, loc=loc, ip=ip)


class ThrMma(TiledMma):
    """
    The thread MMA class for modeling a thread-slice of a tiled MMA.
    """

    def __init__(self, op: Op, trait: Trait, thr_idx: Union[int, Int32]) -> None:
        super().__init__(op, trait)
        self._thr_idx = thr_idx

    def __new_from_mlir_values__(self, values):
        return self.__class__(
            self.op, new_from_mlir_values(self._trait, values), self.thr_idx
        )

    @property
    def thr_idx(self):
        return self._thr_idx

    @dsl_user_op
    def partition_A(self, input_mk: Tensor, *, loc=None, ip=None) -> Tensor:
        thr_idx = _pack_coord(self.thr_idx, loc=loc, ip=ip)
        return _cute_ir.tiled_mma_partition(
            _cute_ir.MmaOperand.A,
            self._trait.value,
            input_mk.value,
            thr_idx,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def partition_B(self, input_nk: Tensor, *, loc=None, ip=None) -> Tensor:
        thr_idx = _pack_coord(self.thr_idx, loc=loc, ip=ip)
        return _cute_ir.tiled_mma_partition(
            _cute_ir.MmaOperand.B,
            self._trait.value,
            input_nk.value,
            thr_idx,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def partition_C(self, input_mn: Tensor, *, loc=None, ip=None) -> Tensor:
        thr_idx = _pack_coord(self.thr_idx, loc=loc, ip=ip)
        return _cute_ir.tiled_mma_partition(
            _cute_ir.MmaOperand.C,
            self._trait.value,
            input_mn.value,
            thr_idx,
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def make_mma_atom(op: MmaOp, *, loc=None, ip=None, **kwargs) -> MmaAtom:
    """
    Makes an MMA Atom from an MMA Operation.

    This function creates an MMA Atom from a given MMA Operation. Arbitrary kw arguments can be
    provided for Op-specific additional parameters. They are not used as of today.

    :param op: The MMA Operation to construct an Atom for
    :type op:  MmaOp
    :return:   The MMA Atom
    :rtype:    MmaAtom
    """
    trait = op._make_trait(loc=loc, ip=ip, **kwargs)
    return MmaAtom(op, trait)


@dsl_user_op
def make_tiled_mma(
    op_or_atom: Union[Op, MmaAtom],
    atom_layout_mnk=(1, 1, 1),
    permutation_mnk=None,
    *,
    loc=None,
    ip=None,
    **kwargs,
) -> TiledMma:
    """
    Makes a tiled MMA from an MMA Operation or an MMA Atom.

    :param op_or_atom:      The MMA Operation or Atom
    :type op_or_atom:       Union[Op, MmaAtom]
    :param atom_layout_mnk: A Layout describing the tiling of Atom across threads
    :type atom_layout_mnk:  Layout
    :param permutation_mnk: A permutation Tiler describing the tiling of Atom across values including any permutation of such tiling
    :type permutation_mnk:  Tiler
    :return:                The resulting tiled MMA
    :rtype:                 TiledMma
    """
    if isinstance(op_or_atom, Op):
        op = op_or_atom
        atom = make_mma_atom(op_or_atom, loc=loc, ip=ip, **kwargs)
    elif isinstance(op_or_atom, MmaAtom):
        op = op_or_atom.op
        atom = op_or_atom
    else:
        raise TypeError(
            f"expected an MMA Op or Atom, but got an instance of {type(op_or_atom)}"
        )
    if isinstance(atom_layout_mnk, tuple):
        atom_layout_mnk = make_layout(atom_layout_mnk, loc=loc, ip=ip)
    if rank(atom_layout_mnk) != 3:
        raise ValueError(f"expects rank-3 MNK atom layout, but got {atom_layout_mnk}")
    permutation_mnk_ty = None
    if permutation_mnk is not None:
        permutation_mnk_ty = _pack_tile(permutation_mnk, loc=loc, ip=ip).type
    ty = _cute_nvgpu_ir.TiledMmaType.get(
        atom._trait.value.type,
        atom_layout_mnk.type,
        permutation_mnk_ty,
    )
    val = _cute_ir.make_tiled_mma(ty, atom._trait.value, loc=loc, ip=ip)
    # Instead of modifying atom which might have been provided by the user, create a brand new
    # trait instance and replace the Atom ir.Value with the tiled one
    trait = new_from_mlir_values(atom._trait, [val])
    return TiledMma(op, trait)


####################################################################################################
#
# Copy Atoms, TiledCopy, and ThrCopy
#
####################################################################################################


class CopyAtom(Atom):
    """
    The Copy Atom class.
    """

    def __str__(self) -> str:
        res = "Copy Atom\n"
        res += "  ThrID:         " + str(self.thr_id) + "\n"
        res += "  TV Layout Src: " + str(self.layout_src_tv) + "\n"
        res += "  TV Layout Dst: " + str(self.layout_dst_tv) + "\n"
        res += "  Value type:    " + str(self._trait.value.type.value_type)
        return res

    #
    # Properties
    #

    @property
    def value_type(self) -> Type[Numeric]:
        return Numeric.from_mlir_type(self._trait.value.type.value_type)

    @property
    def thr_id(self) -> Layout:
        return static(self._trait.value.type.thr_id)

    @property
    def layout_src_tv(self) -> Layout:
        return static(self._trait.value.type.layout_src_tv)

    @property
    def layout_dst_tv(self) -> Layout:
        return static(self._trait.value.type.layout_dst_tv)

    @property
    def smem_layout(self):
        """
        Convenience property to access the SMEM layout for TMA copy atoms.

        This is a shortcut for ``atom.op.smem_layout`` that checks if the operation
        is a TMA operation and provides a clearer error message if not.

        :return: The SMEM layout
        :rtype: Layout or ComposedLayout
        :raises TypeError: If the operation is not a TMA operation
        :raises ValueError: If the SMEM layout is not set

        Example:
            >>> layout = tma_atom.smem_layout  # Instead of tma_atom.op.smem_layout
        """
        # Import here to avoid circular dependency
        from .nvgpu.cpasync.copy import TmaCopyOp

        if not isinstance(self.op, TmaCopyOp):
            raise TypeError(
                f"smem_layout is only available for TMA copy operations, "
                f"but this atom uses {type(self.op).__name__}"
            )

        return self.op.smem_layout


class TiledCopy(CopyAtom):
    """
    The tiled Copy class.
    """

    def __str__(self) -> str:
        res = "Tiled Copy\n"
        res += "  Tiler MN:        " + pretty_str(self.tiler_mn) + "\n"
        res += "  TV Layout tiled: " + str(self.layout_tv_tiled) + "\n"
        res += "Copy Atom\n"
        res += "  ThrID:           " + str(self.thr_id) + "\n"
        res += "  TV Layout Src:   " + str(self.layout_src_tv) + "\n"
        res += "  TV Layout Dst:   " + str(self.layout_dst_tv) + "\n"
        res += "  Value type:      " + str(self._trait.value.type.value_type)
        return res

    #
    # Properties
    #

    @property
    def layout_tv_tiled(self) -> Layout:
        return static(self._trait.value.type.layout_tv_tiled)

    @property
    def tiler_mn(self) -> Tile:
        return _unpack_x_tuple(self._trait.value.type.tiler_mn)

    @property
    def layout_src_tv_tiled(self) -> Layout:
        return static(self._trait.value.type.layout_src_tv_tiled)

    @property
    def layout_dst_tv_tiled(self) -> Layout:
        return static(self._trait.value.type.layout_dst_tv_tiled)

    @property
    def size(self) -> int:
        return self._trait.value.type.size

    #
    # get_slice and retile
    #

    def get_slice(self, thr_idx: Union[int, Int32]) -> "ThrCopy":
        return ThrCopy(self.op, self._trait, thr_idx)

    @dsl_user_op
    def retile(self, src, *, loc=None, ip=None):
        return _cute_ir.tiled_copy_retile(
            tiled_copy=self._trait.value, input=src.value, loc=loc, ip=ip
        )


class ThrCopy(TiledCopy):
    """
    The thread Copy class for modeling a thread-slice of a tiled Copy.
    """

    def __init__(self, op: Op, trait: Trait, thr_idx: Union[int, Int32]) -> None:
        super().__init__(op, trait)
        self._thr_idx = thr_idx

    def __new_from_mlir_values__(self, values):
        return self.__class__(
            self.op, new_from_mlir_values(self._trait, values), self.thr_idx
        )

    @property
    def thr_idx(self):
        return self._thr_idx

    @dsl_user_op
    def partition_S(self, src: Tensor, *, loc=None, ip=None) -> Tensor:
        thr_idx = _pack_coord(self.thr_idx, loc=loc, ip=ip)
        return _cute_ir.tiled_copy_partition_S(
            self._trait.value, src.value, thr_idx, loc=loc, ip=ip
        )

    @dsl_user_op
    def partition_D(self, dst: Tensor, *, loc=None, ip=None) -> Tensor:
        thr_idx = _pack_coord(self.thr_idx, loc=loc, ip=ip)
        return _cute_ir.tiled_copy_partition_D(
            self._trait.value, dst.value, thr_idx, loc=loc, ip=ip
        )


@dsl_user_op
def make_copy_atom(
    op: CopyOp, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
) -> CopyAtom:
    """
    Makes a Copy Atom from a Copy Operation.

    This function creates a Copy Atom from a given Copy Operation. Arbitrary kw arguments can be
    provided for Op-specific additional parameters.

    Example:

    .. code-block:: python

        op = cute.nvgpu.CopyUniversalOp()
        atom = cute.make_copy_atom(op, tensor_dtype, num_bits_per_copy=64)

    :param op:                 The Copy Operation to construct an Atom for
    :type op:                  CopyOp
    :param copy_internal_type: An internal data type used to construct the source/destination layouts in unit of tensor elements
    :type copy_internal_type:  Type[Numeric]
    :return:                   The Copy Atom
    :rtype:                    CopyAtom
    """
    trait = op._make_trait(copy_internal_type, loc=loc, ip=ip, **kwargs)
    return CopyAtom(op, trait)


def _make_tiled_copy(atom, layout_tv, tiler_mn, *, loc=None, ip=None):
    if type(tiler_mn) is tuple:
        tiler_mn = _pack_tile(tiler_mn, loc=loc, ip=ip)

    assert isinstance(tiler_mn, ir.Value) and _cute_ir.TileType.isinstance(
        tiler_mn.type
    ), f"tiler_mn must be a Tile, but got {type(tiler_mn)}"
    assert is_static(layout_tv.type) and is_static(tiler_mn.type), (
        "layout tv and tiler mn must be static"
    )
    tiled_copy_ty = _cute_nvgpu_ir.TiledCopyType.get(
        atom.type, layout_tv.type, tiler_mn.type
    )

    val = _cute_ir.make_tiled_copy(tiled_copy_ty, atom._trait.value, loc=loc, ip=ip)
    # Instead of modifying atom which might have been provided by the user, create a brand new
    # trait instance and replace the Atom ir.Value with the tiled one
    trait = new_from_mlir_values(atom._trait, [val])
    return TiledCopy(atom.op, trait)


def make_tiled_copy(atom, layout_tv, tiler_mn, *, loc=None, ip=None):
    """Create a tiled type given a TV partitioner and tiler.

    :param atom: Copy atom, e.g. smit_copy and simt_async_copy, tma_load, etc.
    :type atom: CopyAtom
    :param layout_tv: Thread-value layout
    :type layout_tv: Layout
    :param tiler_mn: Tile size
    :type tiler_mn: Tiler
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for the partitioner
    :rtype: TiledCopy
    """
    return _make_tiled_copy(atom, layout_tv, tiler_mn, loc=loc, ip=ip)


@dsl_user_op
def make_tiled_copy_tv(
    atom: CopyAtom, thr_layout: Layout, val_layout: Layout, *, loc=None, ip=None
) -> TiledCopy:
    """Create a tiled copy given separate thread and value layouts.

    A TV partitioner is inferred based on the input layouts. The input thread layout
    must be compact.

    :param atom: Copy atom
    :type atom: CopyAtom
    :param thr_layout: Layout mapping from ``(TileM,TileN)`` coordinates to thread IDs (must be compact)
    :type thr_layout: Layout
    :param val_layout: Layout mapping from ``(ValueM,ValueN)`` coordinates to value IDs
    :type val_layout: Layout
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for the partitioner
    :rtype: TiledCopy
    """

    tiler_mn, layout_tv = make_layout_tv(thr_layout, val_layout, loc=loc, ip=ip)
    tiler_mn = _pack_tile(product_each(tiler_mn, loc=loc, ip=ip), loc=loc, ip=ip)
    return _make_tiled_copy(atom, layout_tv, tiler_mn, loc=loc, ip=ip)


@dsl_user_op
def make_cotiled_copy(
    atom: CopyAtom, atom_layout_tv: Layout, data_layout: Layout, *, loc=None, ip=None
) -> TiledCopy:
    """
    Produce a TiledCopy from thread and value offset maps.
    The TV Layout maps threads and values to the codomain of the data_layout.
    It is verified that the intended codomain is valid within data_layout.
    Useful when threads and values don't care about owning specific coordinates, but
    care more about the vector-width and offsets between them.

    Parameters
    ----------
    atom : copy atom, e.g. simt_copy and simt_async_copy, tgen05.st, etc.
    atom_layout_tv : (tid, vid) -> data addr
    data_layout : data coord -> data addr
    loc     : source location for mlir (optional)
    ip      : insertion point (optional)

    Returns
    -------
    tiled_copy
            A tuple of A tiled copy and atom
    """
    assert is_static(atom_layout_tv.type) and is_static(data_layout.type), (
        "atom_layout_tv and data_layout must be static"
    )
    # data addr -> data coord
    inv_layout_ = left_inverse(data_layout, loc=loc, ip=ip)
    inv_data_layout = make_layout(
        (inv_layout_.shape, (1)), stride=(inv_layout_.stride, (0)), loc=loc, ip=ip
    )
    # (tid,vid) -> data_coord
    layout_tv_data = composition(inv_data_layout, atom_layout_tv, loc=loc, ip=ip)

    # check validity
    atom_layout_v_to_check = coalesce(
        make_layout(
            atom_layout_tv.shape[1], stride=atom_layout_tv.stride[1], loc=loc, ip=ip
        ),
        loc=loc,
        ip=ip,
    )
    data_layout_v_to_check = coalesce(
        composition(
            data_layout,
            make_layout(
                layout_tv_data.shape[1], stride=layout_tv_data.stride[1], loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        ),
        loc=loc,
        ip=ip,
    )
    assert data_layout_v_to_check == atom_layout_v_to_check, (
        "the memory pointed to by atom_layout_tv does not exist in the data_layout."
    )

    flat_data_shape = product_each(data_layout.shape, loc=loc, ip=ip)
    tiler = tuple(
        filter(
            composition(
                make_layout(
                    flat_data_shape,
                    stride=tuple(
                        0 if j != i else 1 for j in range(rank(flat_data_shape))
                    ),
                    loc=loc,
                    ip=ip,
                ),
                layout_tv_data,
                loc=loc,
                ip=ip,
            ),
            loc=loc,
            ip=ip,
        )
        for i in range(rank(flat_data_shape))
    )
    # tile_coord -> data_coord
    tile2data = composition(
        make_layout(flat_data_shape, loc=loc, ip=ip), tiler, loc=loc, ip=ip
    )
    # (tid,vid) -> tile_coord
    layout_tv = composition(
        left_inverse(tile2data, loc=loc, ip=ip), layout_tv_data, loc=loc, ip=ip
    )
    return _make_tiled_copy(atom, layout_tv, tiler, loc=loc, ip=ip)


@dsl_user_op
def make_tiled_copy_A(atom, tiled_mma, *, loc=None, ip=None):
    """Create a tiled copy out of the copy_atom that matches the A-Layout of tiled_mma.

    :param atom: Copy atom
    :type atom: CopyAtom
    :param tiled_mma: Tiled MMA
    :type tiled_mma: TiledMma
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for the partitioner
    :rtype: TiledCopy
    """

    return _make_tiled_copy(
        atom,
        tiled_mma.tv_layout_A_tiled,
        (tiled_mma.get_tile_size(0), tiled_mma.get_tile_size(2)),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_tiled_copy_B(atom, tiled_mma, *, loc=None, ip=None):
    """Create a tiled copy out of the copy_atom that matches the B-Layout of tiled_mma.

    :param atom: Copy atom
    :type atom: CopyAtom
    :param tiled_mma: Tiled MMA
    :type tiled_mma: TiledMma
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for the partitioner
    :rtype: TiledCopy
    """

    return _make_tiled_copy(
        atom,
        tiled_mma.tv_layout_B_tiled,
        (tiled_mma.get_tile_size(1), tiled_mma.get_tile_size(2)),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_tiled_copy_C(atom, tiled_mma, *, loc=None, ip=None):
    """Create a tiled copy out of the copy_atom that matches the C-Layout of tiled_mma.

    :param atom: Copy atom
    :type atom: CopyAtom
    :param tiled_mma: Tiled MMA
    :type tiled_mma: TiledMma
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for the partitioner
    :rtype: TiledCopy
    """

    return _make_tiled_copy(
        atom,
        tiled_mma.tv_layout_C_tiled,
        (tiled_mma.get_tile_size(0), tiled_mma.get_tile_size(1)),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_tiled_copy_S(atom, tiled_copy, *, loc=None, ip=None):
    """Create a tiled copy out of the copy_atom that matches the Src-Layout of tiled_copy.

    :param atom: Copy atom
    :type atom: CopyAtom
    :param tiled_copy: Tiled copy
    :type tiled_copy: TiledCopy
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for the partitioner
    :rtype: TiledCopy
    """

    return _make_tiled_copy(
        atom, tiled_copy.layout_src_tv_tiled, tiled_copy.tiler_mn, loc=loc, ip=ip
    )


@dsl_user_op
def make_tiled_copy_D(atom, tiled_copy, *, loc=None, ip=None):
    """Create a tiled copy out of the copy_atom that matches the Dst-Layout of tiled_copy.

    :param atom: Copy atom
    :type atom: CopyAtom
    :param tiled_copy: Tiled copy
    :type tiled_copy: TiledCopy
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for the partitioner
    :rtype: TiledCopy
    """

    return _make_tiled_copy(
        atom, tiled_copy.layout_dst_tv_tiled, tiled_copy.tiler_mn, loc=loc, ip=ip
    )


@dsl_user_op
def make_tiled_copy_C_atom(atom: CopyAtom, mma: TiledMma, *, loc=None, ip=None):
    """Create the smallest tiled copy that can retile LayoutC_TV for use with pipelined epilogues with subtiled stores.

    :param atom: Copy atom
    :type atom: CopyAtom
    :param mma: Tiled MMA
    :type mma: TiledMma
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional

    :return: A tiled copy for partitioner
    :rtype: TiledCopy

    :raises ValueError: If the number value of CopyAtom's source layout is greater than the size of TiledMma's LayoutC_TV
    """
    # Truncate the V-layout to just the Copy_Atom, keep the V-order
    layoutC_tv = mma.tv_layout_C_tiled
    val_layout_src = atom.layout_src_tv
    num_val_src = size(val_layout_src, mode=[1], loc=loc, ip=ip)
    num_val_layoutC_tv = size(layoutC_tv, mode=[1], loc=loc, ip=ip)
    if num_val_src > num_val_layoutC_tv:
        raise ValueError(
            f"The number value of CopyAtom's source layout {num_val_src} "
            f"is greater than the size of TiledMma's LayoutC_TV {num_val_layoutC_tv}"
        )
    layout_TV = composition(
        layoutC_tv,
        make_layout(
            (size(layoutC_tv, mode=[0], loc=loc, ip=ip), num_val_src), loc=loc, ip=ip
        ),
        loc=loc,
        ip=ip,
    )

    # Recompute tiler and restride the TV layout for the new tiler

    # Tiler -- Find the active elements in the MMA tensor and generate a tiler to extract them
    # Convert to the awkward by-mode tiler to preserve the modes of the tiled MMA
    mma_tiler = (mma.get_tile_size(0), mma.get_tile_size(1))

    tiler_0 = filter(
        composition(
            make_layout(mma_tiler, stride=(1, 0), loc=loc, ip=ip),
            layout_TV,
            loc=loc,
            ip=ip,
        ),
        loc=loc,
        ip=ip,
    )
    tiler_1 = filter(
        composition(
            make_layout(mma_tiler, stride=(0, 1), loc=loc, ip=ip),
            layout_TV,
            loc=loc,
            ip=ip,
        ),
        loc=loc,
        ip=ip,
    )
    tiler = (tiler_0, tiler_1)

    tile2mma = composition(
        make_layout(mma_tiler, loc=loc, ip=ip), tiler, loc=loc, ip=ip
    )
    layout_tv = composition(
        left_inverse(tile2mma, loc=loc, ip=ip), layout_TV, loc=loc, ip=ip
    )

    tiler_mn = _pack_tile(tiler, loc=loc, ip=ip)

    return _make_tiled_copy(atom, layout_tv, tiler_mn, loc=loc, ip=ip)


@dsl_user_op
def copy_atom_call(
    atom: CopyAtom,
    src: Tensor,
    dst: Tensor,
    *,
    pred: Optional[Tensor] = None,
    loc=None,
    ip=None,
    **kwargs,
) -> None:
    """Executes a single copy atom operation between two tensors.

    :param atom: Copy atom specifying the transfer operation
    :type atom: CopyAtom
    :param src: Source tensor with layout profile ``(V)``
    :type src: Tensor
    :param dst: Destination tensor with layout profile ``(V)``
    :type dst: Tensor
    :param pred: Optional predication tensor for conditional transfers, defaults to None
    :type pred: Optional[Tensor], optional
    :param loc: Source location information, defaults to None
    :type loc: Any, optional
    :param ip: Insertion point, defaults to None
    :type ip: Any, optional
    :param kwargs: Additional copy atom specific arguments
    :type kwargs: Dict[str, Any]
    :raises TypeError: If source and destination element type bit widths differ
    :return: None
    :rtype: None

    The copy_atom_call operation executes a single copy atom with the given operands.
    Source and destination tensors with layout profile like ``(V)``.

    The ``V-mode`` represents either:

    - A singular mode directly consumable by the provided Copy Atom
    - A composite mode requiring recursive decomposition, structured as ``(V, Rest...)``,

    For src/dst layout like ``(V, Rest...)``, the layout profile of ``pred`` must match ``(Rest...)``.

    **Examples**:

    .. code-block:: python

        # Basic copy atom operation
        cute.copy_atom_call(copy_atom, src, dst)

        # Predicated copy atom operation
        cute.copy_atom_call(copy_atom, src, dst, pred=pred)

    .. note::

        - Certain Atoms may require additional operation-specific keyword arguments.
        - Current implementation limits ``V-mode`` rank to 2 or less. Support for higher ranks is planned
          for future releases.

    """
    if isinstance(src.type, _cute_ir.MemRefType) and isinstance(
        dst.type, _cute_ir.MemRefType
    ):
        if src.element_type.width != dst.element_type.width:
            raise TypeError(
                "`copy_atom_call` currently only supports equal source and destination "
                "element type bit width"
            )

    if rank(src, mode=[0]) > 2 or rank(dst, mode=[0]) > 2:
        raise NotImplementedError(
            "V-mode (mode-0) with rank > 2 is not supported yet, "
            f"but got rank(src, mode=[0]) = {rank(src, mode=[0])} and rank(dst, mode=[0]) = {rank(dst, mode=[0])}"
        )

    value = atom._unpack(loc=loc, ip=ip, **kwargs)
    if isinstance(pred, Tensor):
        pred = pred.value
    return _cute_ir.copy_atom_call(
        value, src.value, dst.value, pred=pred, loc=loc, ip=ip
    )
