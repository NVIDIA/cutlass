# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


import pytest

import cutlass

import cutlass.operators.utils.generate as generate
from cutlass.operators.metadata import OperatorMetadata, Sm107DesignMetadata
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.providers.cutedsl.gemm.sm107_dense_gemm import (
    Sm107DenseGemmOperator,
)


def _make_design(**overrides) -> Sm107DesignMetadata:
    params = {
        "mma_instruction_type": RubinTcgen05Mma,
        "use_2cta_mma": True,
        "tile_shape": (256, 256, 128),
        "cluster_shape": (4, 2, 1),
        "fallback_cluster_shape": (2, 1, 1),
        "use_tma_store": True,
        "enable_breuse": True,
    }
    params.update(overrides)
    return Sm107DesignMetadata(**params)


def _make_metadata(**design_overrides) -> OperatorMetadata:
    operands = generate.construct_dense_gemm_operands(
        a_dtype=cutlass.Float8E4M3FN,
        b_dtype=cutlass.Float8E4M3FN,
        out_dtype=cutlass.Float16,
        acc_dtype=cutlass.Float32,
        stride_A=(0, 0, 1),
        stride_B=(0, 0, 1),
        stride_out=(0, 0, 1),
        alignment_bytes=16,
    )
    return OperatorMetadata(
        operator_name="test_sm107_dense_gemm",
        operator_class=Sm107DenseGemmOperator,
        supported_targets=[],
        operands=operands,
        design=_make_design(**design_overrides),
    )


@pytest.mark.parametrize(
    "tile_shape, use_2cta_mma, enable_breuse, expected_inst_shape",
    [
        ((128, 128, 128), False, False, (128, 128, 64)),
        ((128, 128, 128), True, False, (256, 128, 64)),
        ((256, 256, 128), True, True, (256, 256, 64)),
        ((256, 256, 256), True, True, (256, 256, 64)),
    ],
)
def test_sm107_operator_derives_instruction_shape(
    tile_shape, use_2cta_mma, enable_breuse, expected_inst_shape
):
    metadata = _make_metadata(
        tile_shape=tile_shape,
        use_2cta_mma=use_2cta_mma,
        enable_breuse=enable_breuse,
    )
    design = metadata.design

    assert (
        Sm107DenseGemmOperator._inst_shape_mnk(metadata.operands, design)
        == expected_inst_shape
    )
    assert design.use_fallback_cluster()
    assert design.enable_breuse is enable_breuse


@pytest.mark.parametrize(
    "overrides, error",
    [
        (
            {"fallback_cluster_shape": (0, 1, 1)},
            "fallback_cluster_shape dimensions must be positive",
        ),
        (
            {"tile_shape": (0, 256, 128)},
            "tile_shape dimensions must be positive",
        ),
    ],
)
def test_sm107_design_rejects_invalid_configs(overrides, error):
    with pytest.raises(ValueError, match=error):
        _make_design(**overrides)


@pytest.mark.parametrize(
    "tile_shape",
    [
        (128, 256, 128),
        (256, 256, 96),
        (257, 256, 128),
        (256, 160, 128),
        (256, 192, 128),
        (256, 224, 128),
    ],
)
def test_sm107_operator_rejects_invalid_tile_shape(tile_shape):
    assert not Sm107DenseGemmOperator._valid_metadata(
        _make_metadata(tile_shape=tile_shape)
    )


@pytest.mark.parametrize(
    "out_dtype, expected",
    [
        (cutlass.BFloat16, True),
        (cutlass.Float16, True),
        (cutlass.Float8E4M3FN, False),
        (cutlass.Float8E5M2, False),
    ],
)
def test_sm107_operator_validates_fp16_accumulator_output_dtype(out_dtype, expected):
    operands = generate.construct_dense_gemm_operands(
        a_dtype=cutlass.Float8E4M3FN,
        b_dtype=cutlass.Float8E4M3FN,
        out_dtype=out_dtype,
        acc_dtype=cutlass.Float16,
        stride_A=(0, 0, 1),
        stride_B=(0, 0, 1),
        stride_out=(0, 0, 1),
        alignment_bytes=16,
    )

    assert Sm107DenseGemmOperator._valid_operands(operands) is expected
