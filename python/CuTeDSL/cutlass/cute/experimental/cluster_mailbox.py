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

"""Payload encoding and DSMEM cluster mailbox helpers."""

import math
import types as _types
from dataclasses import dataclass
from typing import Any

import cutlass
from cutlass import cute

from .core import MbarrierOwner, PipelineLocale, get_mbarrier


__all__ = [
    "B32PayloadCodec",
    "CTA_PAIR_PEER_LOCALE",
    "b32_payload",
    "ClusterMailbox",
]


CTA_PAIR_PEER_LOCALE = PipelineLocale.cluster(
    MbarrierOwner.CTA_PAIR_PEER,
    MbarrierOwner.CTA_PAIR_PEER,
)


def _validate_cta_pair_peer_stage_token(stage_token: Any) -> None:
    token_type = getattr(stage_token, "type", None)
    if token_type is None:
        token_value = getattr(stage_token, "value", None)
        token_type = getattr(token_value, "type", None)
    if token_type is None:
        raise TypeError(
            "ClusterMailbox.send_to_pipeline_stage expects a pipeline stage "
            f"token, got {type(stage_token)}"
        )

    token_type_text = str(token_type)
    locale_text = CTA_PAIR_PEER_LOCALE._to_ir_text()
    if locale_text not in token_type_text:
        raise ValueError(
            "ClusterMailbox.send_to_pipeline_stage requires a stage token "
            "from a CTA_PAIR_PEER_LOCALE pipeline; "
            f"got {token_type_text}"
        )


# Each entry maps a supported DSL type to the number of b32 words it occupies.
# Sub-word types occupy a full b32 word with the value in the low bits. Users
# who need tighter packing can do the bit-shifting themselves and declare the
# field as Int32.
def _supported_types() -> dict[Any, int]:
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
    dtype: Any
    word_start: int
    word_end: int


def _compute_field_descs(fields: list[tuple[str, Any]]) -> tuple[list[_FieldDesc], int]:
    """Compute field descriptors and total b32 word count."""
    type_info = _supported_types()
    descs: list[_FieldDesc] = []
    word = 0
    for name, dtype in fields:
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


def _chunk_words(total_words: int, base_align: int) -> list[tuple[int, list[int]]]:
    """Group b32 words into v4.b32 / v2.b32 / b32 store chunks."""
    chunks: list[tuple[int, list[int]]] = []
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


def _to_i32(val: Any, dtype: Any) -> Any:
    """Convert a field value to its i32 representation for a b32 store."""
    if dtype is cutlass.Float32:
        return val.bitcast(cutlass.Int32)
    if dtype in (cutlass.Float16, cutlass.BFloat16):
        return val.bitcast(cutlass.Int16).to(cutlass.Int32)
    return val.to(cutlass.Int32)


def _from_i32(i32_val: Any, dtype: Any) -> Any:
    """Convert a loaded i32 word back to the original field type."""
    if dtype is cutlass.Int32:
        return i32_val
    if dtype is cutlass.Float32:
        return i32_val.bitcast(cutlass.Float32)
    if dtype in (cutlass.Float16, cutlass.BFloat16):
        return i32_val.to(cutlass.Int16).bitcast(dtype)
    return i32_val.to(dtype)


class B32PayloadCodec:
    """Encode named scalar DSL values into b32 lanes.

    Supported field types are ``Boolean``, ``Int8``, ``Int16``, ``Int32``,
    ``Int64``, ``Float16``, ``BFloat16``, and ``Float32`` from ``cutlass``.

    This is an encoding policy, not a natural ``cute.struct`` memory layout.
    Every field uses at least one b32 lane. Sub-word types occupy the low bits
    of a full b32 lane, ``Float32`` is bitcast to ``Int32``, and ``Int64`` uses
    two consecutive b32 lanes, low word first. Consumers that write the encoded
    payload to memory should use storage typed as
    ``cute.struct.MemRange[cutlass.Int32, codec.storage_words]``.
    """

    def __init__(self, fields: list[tuple[str, Any]], name: str | None = None) -> None:
        if not fields:
            raise ValueError("B32PayloadCodec: at least one field is required")
        descs, total_words = _compute_field_descs(fields)
        self._field_descs: list[_FieldDesc] = descs
        self._field_names: list[str] = [fd.name for fd in descs]
        self.tx_bytes: int = total_words * 4
        self.storage_words: int = total_words
        self.required_alignment: int = (
            16 if total_words >= 4 else (8 if total_words >= 2 else 4)
        )
        self.__name__: str = name or "B32PayloadCodec"

    @classmethod
    def from_struct(cls, struct_cls: Any) -> "B32PayloadCodec":
        """Create a codec from a ``cute.struct`` or annotated Python class.

        For ``cute.struct`` inputs, only the declared field names and scalar
        types are used. The encoded payload still uses this codec's b32-slot
        storage policy rather than the natural byte layout of the struct.
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
        return list(self._field_names)

    def chunks_for_alignment(self, base_align: int) -> list[tuple[int, list[int]]]:
        """Return ``(chunk_size, word_indices)`` chunks for a base alignment."""
        return _chunk_words(self.storage_words, base_align)

    def encode_fields(self, fields: dict[str, Any]) -> list[Any]:
        """Encode named field values into flat i32 b32 lanes."""
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

        word_vals: list[Any] = []
        for fd in self._field_descs:
            val = fields[fd.name]
            if fd.word_end > fd.word_start:
                i64 = val.to(cutlass.Int64)
                word_vals.append((i64 & cutlass.Int64(0xFFFF_FFFF)).to(cutlass.Int32))
                word_vals.append((i64 >> cutlass.Int64(32)).to(cutlass.Int32))
            else:
                word_vals.append(_to_i32(val, fd.dtype))
        return word_vals

    def decode_from_b32_ptr(self, ptr: Any) -> _types.SimpleNamespace:
        """Decode payload fields from a local b32 pointer."""
        result: dict[str, Any] = {}
        for fd in self._field_descs:
            if fd.word_end > fd.word_start:
                # Mask before shifting to avoid sign-extension from low word.
                low = ptr[fd.word_start].to(cutlass.Int64) & cutlass.Int64(0xFFFF_FFFF)
                high = (
                    ptr[fd.word_end].to(cutlass.Int64) & cutlass.Int64(0xFFFF_FFFF)
                ) << cutlass.Int64(32)
                result[fd.name] = (low | high).to(fd.dtype)
            else:
                result[fd.name] = _from_i32(ptr[fd.word_start], fd.dtype)
        return _types.SimpleNamespace(**result)


def b32_payload(cls: Any) -> B32PayloadCodec:
    """Convert type-annotated scalar fields to a :class:`B32PayloadCodec`."""
    return B32PayloadCodec.from_struct(cls)


class ClusterMailbox:
    """One-slot DSMEM mailbox for sending a typed payload to a peer CTA.

    Owns the remote write issue protocol: ``mbarrier_expect_tx`` to the peer's
    mbarrier plus chunked ``st.async.shared::cluster`` stores. Pipeline slot
    acquisition and release remain the caller's responsibility; callers must
    separately commit/release the surrounding pipeline stage after
    ``send_to_pipeline_stage``.

    The SMEM storage must be ``cute.struct.MemRange[cutlass.Int32, N]`` where
    ``N == payload.storage_words``. Align it to 16 bytes with
    ``cute.struct.Align[..., 16]`` to enable ``v4.b32`` stores.
    """

    def __init__(self, payload: B32PayloadCodec, storage: Any) -> None:
        if not isinstance(payload, B32PayloadCodec):
            raise TypeError(
                f"ClusterMailbox: payload must be a B32PayloadCodec, "
                f"got {type(payload).__name__}"
            )
        self._codec = payload
        self._storage = storage

    def _send_with_mbarrier(
        self, full_mbar: Any, peer_rank: Any, fields: dict[str, Any]
    ) -> None:
        local_ptr = self._storage.data_ptr()
        chunks = self._codec.chunks_for_alignment(local_ptr.alignment)
        word_vals = self._codec.encode_fields(fields)

        with cute.arch.elect_one():
            cute.arch.mbarrier_expect_tx(
                full_mbar,
                self._codec.tx_bytes,
                peer_rank,
            )
            for chunk_size, word_group in chunks:
                ptr = local_ptr + word_group[0]
                value = (
                    word_vals[word_group[0]]
                    if chunk_size == 1
                    else tuple(word_vals[w] for w in word_group)
                )
                cute.arch.store_async_dsmem(ptr, value, full_mbar, peer_rank)

    def send_to_pipeline_stage(
        self, stage_token: Any, peer_rank: Any, **fields: Any
    ) -> None:
        """Send through the full mbarrier owned by a pipeline stage."""
        _validate_cta_pair_peer_stage_token(stage_token)
        full_mbar = get_mbarrier(stage_token).result
        self._send_with_mbarrier(full_mbar, peer_rank, fields)

    def recv(self) -> _types.SimpleNamespace:
        """Read the received payload fields from local SMEM.

        Call this after the pipeline consumer has waited on the mbarrier.
        """
        return self._codec.decode_from_b32_ptr(self._storage.data_ptr())


# Compatibility aliases for branch-local callers that used the original names.
# Prefer B32PayloadCodec/b32_payload in new code.
DsmemPayloadLayout = B32PayloadCodec
dsmem_payload = b32_payload
