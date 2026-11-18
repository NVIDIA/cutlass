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

"""CuTe JIT helpers for DSMEM peer communication.

The helpers in this module intentionally live under ``cutlass.cute`` rather
than generic ``cutlass.utils`` because they are part of the CuTe JIT surface:
they accept CuTe pointers/tensors, use ``cute.size`` for tensor-like values,
and emit ``cute.arch`` DSMEM operations while a ``@cute.jit`` function is
being traced.

Payload model
-------------

``B32PayloadCodec`` is the wire-format contract shared by a DSMEM sender and
receiver. It converts typed scalar fields to and from b32 words, computes the
transaction byte count, and chooses scalar, v2, or v4 stores from the payload
size and pointer alignment, so callers do not manually pack and unpack the
payload. The b32 representation is a policy of this helper, chosen for its
current call sites; it is not a DSMEM hardware limitation or the natural
in-memory layout of a ``cute.struct``.

Caller-armed peer stores
------------------------

Use ``store_to_peer`` when multiple lanes or threads contribute stores to one
aggregate transaction. Every receiving CTA must arm its own local mbarrier for
the total incoming byte count before any peer issues a store. The helper maps
the data and mbarrier pointers to ``peer_rank`` and emits the stores, but does
not arm or arrive on the barrier::

    value_codec = cute.dsmem.B32PayloadCodec([("value", cutlass.Float32)])

    # One elected thread arms this CTA's receive barrier for all incoming lanes.
    with cute.arch.elect_one():
        cute.arch.mbarrier_arrive_and_expect_tx(
            local_mbar, incoming_lanes * value_codec.tx_bytes
        )
    # The surrounding protocol must order this arm before peer stores begin.

    # Each participating lane sends its value to the corresponding peer slot.
    cute.dsmem.store_to_peer(
        local_slot + lane_idx,
        lane_values,  # One-element rmem tensor for this lane.
        value_codec,
        local_mbar,
        peer_rank,
    )

Typed cluster mailbox
---------------------

Use ``ClusterMailbox`` for one logical payload sent by a CTA. ``send`` elects
one thread, arms the peer mbarrier for exactly one encoded payload, and emits
the remote stores. The caller still owns the surrounding pipeline
acquire/commit and consumer wait/release operations::

    @cute.struct
    class TileCoord:
        m: cutlass.Int32
        n: cutlass.Int32

    coord_codec = cute.dsmem.B32PayloadCodec.from_struct(TileCoord)

    @cute.struct
    class SharedStorage:
        coord: cute.struct.Align[
            cute.struct.MemRange[cutlass.Int32, coord_codec.storage_words], 16
        ]

    mailbox = cute.dsmem.ClusterMailbox(
        coord_codec, storage.coord, local_full_mbar
    )
    mailbox.send(peer_rank, m=m_coord, n=n_coord)
    # Commit the surrounding producer pipeline after send().

    # After the consumer pipeline has waited on local_full_mbar:
    received = mailbox.recv()
    m_coord = received.m
    n_coord = received.n
"""

import math
import types as _types
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Protocol, cast

import cutlass
from cutlass import cute
from cutlass.cute.typing import Integer, Numeric


__all__ = [
    "B32PayloadCodec",
    "b32_payload",
    "ClusterMailbox",
    "store_b32_words_to_peer",
    "store_to_peer",
]


B32Chunk = tuple[int, list[int]]
_NumericType = type[Numeric]


# Each entry maps a supported DSL type to the number of b32 words it occupies.
# Sub-word types occupy a full b32 word with the value in the low bits. Users
# who need tighter packing can do the bit-shifting themselves and declare the
# field as Int32.
def _supported_types() -> dict[_NumericType, int]:
    return {
        cutlass.Boolean: 1,
        cutlass.Int8: 1,
        cutlass.Int16: 1,
        cutlass.Int32: 1,
        cutlass.Int64: 2,
        cutlass.Float16: 1,
        cutlass.BFloat16: 1,
        cutlass.Float32: 1,
    }


@dataclass(frozen=True)
class _FieldDesc:
    name: str
    dtype: _NumericType
    word_start: int
    word_end: int


class _IndexablePointer(Protocol):
    """CuTe pointer implementation that supports indexed loads."""

    def __getitem__(self, idx: int) -> Numeric: ...


class _StorageLike(Protocol):
    """SMEM storage object exposing its local payload pointer."""

    def data_ptr(self) -> cute.Pointer: ...


def _compute_field_descs(
    fields: Sequence[tuple[str, _NumericType]],
) -> tuple[list[_FieldDesc], int]:
    """Compute field descriptors and total b32 word count."""
    type_info = _supported_types()
    descs: list[_FieldDesc] = []
    word = 0
    for name, dtype in fields:
        if not isinstance(name, str):
            raise TypeError(
                "B32PayloadCodec: field names must be strings, "
                f"got {type(name).__name__}"
            )
        if dtype not in type_info:
            supported = ", ".join(getattr(t, "__name__", repr(t)) for t in type_info)
            raise TypeError(
                f"B32PayloadCodec: field '{name}' has unsupported type "
                f"{dtype!r}; supported types: {supported}"
            )
        word_count = type_info[dtype]
        descs.append(_FieldDesc(name, dtype, word, word + word_count - 1))
        word += word_count
    return descs, word


def _chunk_words(total_words: int, base_align: int) -> list[B32Chunk]:
    """Group b32 words into v4.b32 / v2.b32 / b32 store chunks."""
    if total_words <= 0:
        raise ValueError(f"total_words must be positive, got {total_words}")
    if not isinstance(base_align, int) or base_align <= 0:
        raise ValueError(f"base_align must be a positive integer, got {base_align!r}")

    chunks: list[B32Chunk] = []
    i = 0
    while i < total_words:
        word_byte = i * 4
        effective = math.gcd(base_align, word_byte) if word_byte > 0 else base_align
        for k in (16, 8, 4):
            if effective >= k:
                effective = k
                break
        remaining = total_words - i
        if remaining >= 4 and effective >= 16:
            size = 4
        elif remaining >= 2 and effective >= 8:
            size = 2
        else:
            size = 1
        chunks.append((size, list(range(i, i + size))))
        i += size
    return chunks


def _required_alignment(total_words: int) -> int:
    return 16 if total_words >= 4 else (8 if total_words >= 2 else 4)


def _to_i32(val: Numeric, dtype: _NumericType) -> Numeric:
    """Convert a field value to its i32 representation for a b32 store."""
    if dtype is cutlass.Float32:
        return val.bitcast(cutlass.Int32)
    if dtype in (cutlass.Float16, cutlass.BFloat16):
        return val.bitcast(cutlass.Int16).to(cutlass.Int32)
    return val.to(cutlass.Int32)


def _from_i32(i32_val: Numeric, dtype: _NumericType) -> Numeric:
    """Convert a loaded i32 word back to the original field type."""
    if dtype is cutlass.Int32:
        return i32_val
    if dtype is cutlass.Float32:
        return i32_val.bitcast(cutlass.Float32)
    if dtype in (cutlass.Float16, cutlass.BFloat16):
        return i32_val.to(cutlass.Int16).bitcast(dtype)
    return i32_val.to(dtype)


def _encode_field_value(fd: _FieldDesc, val: Numeric) -> list[Numeric]:
    if fd.word_end > fd.word_start:
        i64 = val.to(cutlass.Int64)
        return [
            (i64 & cutlass.Int64(0xFFFF_FFFF)).to(cutlass.Int32),
            (i64 >> cutlass.Int64(32)).to(cutlass.Int32),
        ]
    return [_to_i32(val, fd.dtype)]


def _check_b32_pointer(ptr: object, api_name: str) -> None:
    if not hasattr(ptr, "alignment"):
        raise TypeError(f"{api_name}: local_ptr must be a CuTe pointer with alignment")
    alignment = getattr(ptr, "alignment")
    if not isinstance(alignment, int) or alignment <= 0:
        raise TypeError(
            f"{api_name}: local_ptr.alignment must be a positive integer, "
            f"got {alignment!r}"
        )
    dtype = getattr(ptr, "dtype", None)
    if getattr(dtype, "width", None) != 32:
        raise TypeError(
            f"{api_name}: local_ptr must point to a 32-bit element, got {dtype!r}"
        )


def _check_storage_like(storage: object, api_name: str) -> None:
    data_ptr = getattr(storage, "data_ptr", None)
    if not callable(data_ptr):
        raise TypeError(f"{api_name}: storage must expose a callable data_ptr()")


def store_b32_words_to_peer(
    local_ptr: cute.Pointer,
    word_vals: Sequence[Numeric],
    chunks: Sequence[B32Chunk],
    local_mbar_ptr: cute.Pointer,
    peer_rank: object,
) -> None:
    """Issue chunked ``store_async_dsmem`` calls for encoded b32 words.

    Args:
        local_ptr: Local CTA SMEM pointer with a 32-bit pointee for the payload.
            Pointer offsets are therefore measured in b32 words. The CuTe arch
            wrapper maps this local pointer to ``peer_rank``.
        word_vals: Encoded ``Int32`` b32 words to write.
        chunks: Store chunk plan from ``B32PayloadCodec.chunks_for_alignment``.
            Each chunk size must be 1, 2, or 4 b32 words.
        local_mbar_ptr: Local CTA mbarrier pointer associated with this
            transfer. The arch wrapper maps it to ``peer_rank`` for the store
            mbarrier.
        peer_rank: Destination CTA rank in the cluster.

    Raises:
        TypeError: If ``local_ptr`` is not a CuTe pointer with a 32-bit pointee.
        ValueError: If the chunk plan refers outside ``word_vals`` or uses an
            unsupported chunk size.
    """
    _check_b32_pointer(local_ptr, "store_b32_words_to_peer")
    word_count = len(word_vals)
    for chunk_size, word_group in chunks:
        if chunk_size not in (1, 2, 4):
            raise ValueError(
                "store_b32_words_to_peer: chunk size must be 1, 2, or 4, "
                f"got {chunk_size}"
            )
        if chunk_size != len(word_group):
            raise ValueError(
                "store_b32_words_to_peer: chunk size does not match word group "
                f"length ({chunk_size} != {len(word_group)})"
            )
        if any(w < 0 or w >= word_count for w in word_group):
            raise ValueError(
                "store_b32_words_to_peer: chunk word index outside encoded "
                f"payload with {word_count} words"
            )
        ptr = local_ptr + word_group[0]
        value = (
            word_vals[word_group[0]]
            if chunk_size == 1
            else tuple(word_vals[w] for w in word_group)
        )
        cute.arch.store_async_dsmem(ptr, value, local_mbar_ptr, peer_rank)


def store_to_peer(
    local_ptr: cute.Pointer,
    values: cute.Tensor,
    payload: "B32PayloadCodec",
    local_mbar_ptr: cute.Pointer,
    peer_rank: object,
) -> None:
    """Encode and issue chunked ``store_async_dsmem`` calls to a peer CTA.

    The caller owns mbarrier arming. This helper can be executed by many lanes
    or threads, so it intentionally does not issue ``mbarrier_expect_tx``.

    Args:
        local_ptr: Local CTA SMEM pointer with a 32-bit pointee identifying the
            destination slot layout. ``store_async_dsmem`` maps this pointer to
            ``peer_rank``.
        values: Payload values to encode in codec field order. This must be a
            tensor-like object supporting ``cute.size(values)`` and
            ``values[i]``.
        payload: B32 payload codec that defines field order, transaction byte
            count, and b32 store chunking.
        local_mbar_ptr: Local CTA mbarrier pointer associated with this
            transfer. ``store_async_dsmem`` maps this pointer to ``peer_rank``.
        peer_rank: Destination CTA rank in the cluster.

    Raises:
        TypeError: If ``payload`` is not a ``B32PayloadCodec``, ``local_ptr``
            does not have a 32-bit pointee, or ``values`` is not tensor-like.
        ValueError: If ``values`` does not match the codec field count.
    """
    if not isinstance(payload, B32PayloadCodec):
        raise TypeError(
            f"store_to_peer: payload must be a B32PayloadCodec, "
            f"got {type(payload).__name__}"
        )
    _check_b32_pointer(local_ptr, "store_to_peer")

    chunks = payload.chunks_for_alignment(local_ptr.alignment)
    word_vals = payload.encode_values(values)
    store_b32_words_to_peer(local_ptr, word_vals, chunks, local_mbar_ptr, peer_rank)


class B32PayloadCodec:
    """Encode scalar DSL values into b32 lanes.

    Supported field types are ``Boolean``, ``Int8``, ``Int16``, ``Int32``,
    ``Int64``, ``Float16``, ``BFloat16``, and ``Float32`` from ``cutlass``.

    This is an encoding policy, not a natural ``cute.struct`` memory layout.
    Every field uses at least one b32 lane. Sub-word types occupy the low bits
    of a full b32 lane, ``Float32`` is bitcast to ``Int32``, and ``Int64`` uses
    two consecutive b32 lanes, low word first. Consumers that write the encoded
    payload to memory should use storage typed as
    ``cute.struct.MemRange[cutlass.Int32, codec.storage_words]``.

    Values may be encoded either by name with ``encode_fields`` or by field
    order with ``encode_values``. The ordered form is useful for flat rmem
    tensors whose element names carry no semantic meaning.
    """

    def __init__(
        self, fields: Sequence[tuple[str, _NumericType]], name: str | None = None
    ) -> None:
        """Build a b32 payload encoding policy.

        Args:
            fields: Ordered ``(field_name, dtype)`` pairs. Supported dtypes are
                the scalar cutlass types listed in the class docstring.
            name: Optional diagnostic name for errors emitted by this codec.

        Raises:
            ValueError: If ``fields`` is empty.
            TypeError: If a field name is not a string or a dtype is not
                supported by this b32 encoding policy.
        """
        if not fields:
            raise ValueError("B32PayloadCodec: at least one field is required")
        descs, total_words = _compute_field_descs(fields)
        self._field_descs: list[_FieldDesc] = descs
        self._field_names: list[str] = [fd.name for fd in descs]
        self.tx_bytes: int = total_words * 4
        self.storage_words: int = total_words
        self.required_alignment: int = _required_alignment(total_words)
        self.__name__: str = name or "B32PayloadCodec"

    @classmethod
    def from_struct(cls, struct_cls: object) -> "B32PayloadCodec":
        """Create a codec from a ``cute.struct`` or annotated Python class.

        For ``cute.struct`` inputs, only the declared field names and scalar
        types are used. The encoded payload still uses this codec's b32-slot
        storage policy rather than the natural byte layout of the struct.

        Args:
            struct_cls: ``cute.struct`` wrapper or Python class with scalar
                field annotations.

        Raises:
            TypeError: If ``struct_cls`` has no usable annotations or declares
                an unsupported field dtype.
        """
        annotations = getattr(struct_cls, "_annotations", None)
        if annotations is None:
            annotations = getattr(struct_cls, "__annotations__", None)
        if not annotations:
            raise TypeError(
                "B32PayloadCodec.from_struct expects a cute.struct or "
                "annotated class with at least one field"
            )

        wrapped_cls = getattr(struct_cls, "_cls", None)
        name = getattr(wrapped_cls, "__name__", None) or getattr(
            struct_cls, "__name__", "B32PayloadCodec"
        )
        if isinstance(name, str) and name.startswith("cute.struct::"):
            name = name.removeprefix("cute.struct::")
        return cls(list(annotations.items()), name=name)

    @property
    def field_names(self) -> list[str]:
        """Return the declared payload field names in encode/decode order."""
        return list(self._field_names)

    def chunks_for_alignment(self, base_align: int) -> list[B32Chunk]:
        """Return store chunks for a base pointer alignment.

        Args:
            base_align: Alignment in bytes of the first b32 word.

        Raises:
            ValueError: If ``base_align`` is not a positive integer.
        """
        return _chunk_words(self.storage_words, base_align)

    def encode_fields(self, fields: Mapping[str, Numeric]) -> list[Numeric]:
        """Encode named field values into flat i32 b32 lanes.

        Args:
            fields: Mapping from each codec field name to a scalar DSL value.

        Raises:
            ValueError: If the mapping does not exactly match the codec fields.
        """
        expected = set(self.field_names)
        provided = set(fields.keys())
        if expected != provided:
            missing = expected - provided
            extra = provided - expected
            parts: list[str] = []
            if missing:
                parts.append(f"missing fields: {sorted(missing)}")
            if extra:
                parts.append(f"unexpected fields: {sorted(extra)}")
            raise ValueError(
                f"B32PayloadCodec.encode_fields for payload '{self.__name__}': "
                + "; ".join(parts)
            )

        word_vals: list[Numeric] = []
        for fd in self._field_descs:
            word_vals.extend(_encode_field_value(fd, fields[fd.name]))
        return word_vals

    def encode_values(self, values: cute.Tensor) -> list[Numeric]:
        """Encode values supplied in field order into flat i32 b32 lanes.

        Args:
            values: Tensor-like value supporting ``cute.size(values)`` and
                ``values[i]`` for every declared codec field.

        Raises:
            ValueError: If ``values`` does not contain exactly one element per
                codec field.
        """
        value_count = cute.size(values)
        if value_count != len(self._field_descs):
            raise ValueError(
                f"B32PayloadCodec.encode_values for payload '{self.__name__}': "
                f"expected {len(self._field_descs)} values, got {value_count}"
            )

        word_vals: list[Numeric] = []
        for i, fd in enumerate(self._field_descs):
            word_vals.extend(_encode_field_value(fd, cast(Numeric, values[i])))
        return word_vals

    def decode_from_b32_ptr(self, ptr: cute.Pointer) -> _types.SimpleNamespace:
        """Decode payload fields from a local b32 pointer.

        Args:
            ptr: Local CTA pointer with a 32-bit pointee to b32 storage
                containing this payload.

        Raises:
            TypeError: If ``ptr`` is not a CuTe pointer with a 32-bit pointee.
        """
        _check_b32_pointer(ptr, "B32PayloadCodec.decode_from_b32_ptr")
        indexed_ptr = cast(_IndexablePointer, ptr)
        result: dict[str, Numeric] = {}
        for fd in self._field_descs:
            if fd.word_end > fd.word_start:
                # Mask before shifting to avoid sign-extension from low word.
                low = indexed_ptr[fd.word_start].to(cutlass.Int64) & cutlass.Int64(
                    0xFFFF_FFFF
                )
                high = (
                    indexed_ptr[fd.word_end].to(cutlass.Int64)
                    & cutlass.Int64(0xFFFF_FFFF)
                ) << cutlass.Int64(32)
                # Integer operators are annotated with the broader Numeric result.
                result[fd.name] = (cast(Integer, low) | high).to(fd.dtype)
            else:
                result[fd.name] = _from_i32(indexed_ptr[fd.word_start], fd.dtype)
        return _types.SimpleNamespace(**result)


def b32_payload(cls: object) -> B32PayloadCodec:
    """Convert type-annotated scalar fields to a :class:`B32PayloadCodec`.

    Args:
        cls: ``cute.struct`` wrapper or Python class with scalar field
            annotations.

    Raises:
        TypeError: If ``cls`` has no usable annotations or declares an
            unsupported field dtype.
    """
    return B32PayloadCodec.from_struct(cls)


class ClusterMailbox:
    """One-slot DSMEM mailbox for sending a typed payload to a peer CTA.

    Owns the remote write issue protocol: ``mbarrier_expect_tx`` to the peer's
    mbarrier plus chunked ``st.async.shared::cluster`` stores. Pipeline slot
    acquisition and release remain the caller's responsibility; callers must
    separately arrive/release the full barrier after ``send``.

    The SMEM storage must be ``cute.struct.MemRange[cutlass.Int32, N]`` where
    ``N == payload.storage_words``. Align it to 16 bytes with
    ``cute.struct.Align[..., 16]`` to enable ``v4.b32`` stores.
    """

    def __init__(
        self,
        payload: B32PayloadCodec,
        storage: object,
        full_mbar: cute.Pointer,
    ) -> None:
        """Create a mailbox bound to one local payload slot.

        Args:
            payload: B32 payload codec used for transaction byte count, field
                encoding, and store chunking.
            storage: Local CTA SMEM object exposing ``data_ptr()`` for the b32
                payload slot.
            full_mbar: Local CTA mbarrier pointer used by peer stores.

        Raises:
            TypeError: If ``payload`` is not a ``B32PayloadCodec`` or
                ``storage`` does not expose ``data_ptr()``.
        """
        if not isinstance(payload, B32PayloadCodec):
            raise TypeError(
                f"ClusterMailbox: payload must be a B32PayloadCodec, "
                f"got {type(payload).__name__}"
            )
        _check_storage_like(storage, "ClusterMailbox")
        self._codec = payload
        self._storage = cast(_StorageLike, storage)
        self._full_mbar = full_mbar

    def send(self, peer_rank: object, **fields: Numeric) -> None:
        """Send a typed payload to the peer CTA.

        Emits, under ``elect_one``, a remote ``mbarrier_expect_tx`` followed by
        chunked ``store_async_dsmem`` calls.
        The codec supplies the transaction byte count, field encoding, and
        ``v4.b32`` / ``v2.b32`` / ``b32`` chunk plan. This method does not
        arrive on the mbarrier; call the surrounding pipeline's producer commit
        after ``send`` to make the payload visible to consumers.

        Args:
            peer_rank: Destination CTA rank in the cluster.
            **fields: Named scalar DSL values matching the payload codec fields.

        Raises:
            ValueError: If ``fields`` does not exactly match the payload codec.
        """
        local_ptr = self._storage.data_ptr()
        chunks = self._codec.chunks_for_alignment(local_ptr.alignment)
        word_vals = self._codec.encode_fields(fields)

        with cute.arch.elect_one():
            cute.arch.mbarrier_expect_tx(
                self._full_mbar,
                self._codec.tx_bytes,
                peer_rank,
            )
            store_b32_words_to_peer(
                local_ptr, word_vals, chunks, self._full_mbar, peer_rank
            )

    def recv(self) -> _types.SimpleNamespace:
        """Read the received payload fields from local SMEM.

        Call this after the pipeline consumer has waited on the mbarrier.

        Returns:
            Simple namespace whose attributes match the payload codec fields.

        Raises:
            TypeError: If the mailbox storage no longer returns a pointer-like
                object from ``data_ptr()``.
        """
        return self._codec.decode_from_b32_ptr(self._storage.data_ptr())


# Compatibility aliases for branch-local callers that used the original names.
# Prefer B32PayloadCodec/b32_payload in new code.
DsmemPayloadLayout = B32PayloadCodec
dsmem_payload = b32_payload
