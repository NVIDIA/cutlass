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

"""Pipeline wiring for the Blackwell FMHA prefill kernel.

Builds the warp-specialized, multi-stage software pipeline connecting the
kernel's producer/consumer roles. Stage flow per KV iteration:

    LOAD -> MMA_QK -> SOFTMAX -> MMA_AV -> CORRECTION -> EPILOGUE

  - LOAD:       TMA-stage Q/K/V tiles into SMEM.
  - MMA_QK:     S = Q . K^T on the tensor core.
  - SOFTMAX:    online softmax of S -> P (ping-pong across two warpgroups).
  - MMA_AV:     O += P . V on the tensor core.
  - CORRECTION: rescale O by the running softmax max/denominator.
  - EPILOGUE:   write O (and optional LSE) back to GMEM.

Every edge is an LIR pipeline (``cute_ext.*Pipeline``): an mbarrier-backed
circular buffer whose producer commits when its output is ready and whose
consumer waits on the barrier before reading, which enforces ordering and
provides backpressure. The pipelines allocate their own mbarriers, and LIR
makes their init visible CTA-wide itself (it inserts ``fence.mbarrier_init``
plus a CTA barrier after the ``create_pipeline`` ops); the kernel's own
fence/sync after ``make_fmha_pipeline`` is therefore not required for
correctness and is kept only because the later warp-alignment point measures
slightly better on persistent/short-Q shapes.

Each pipeline object carries an independent producer and consumer cursor;
under warp specialization each role only touches its own side.
"""

from cutlass.cute import experimental as cute_ext
from cutlass.cutlass_dsl import extract_mlir_values, new_from_mlir_values


class SoftmaxPipes:
    """Named carrier for the pipelines the softmax warpgroups thread through
    their staged loops.

    Replaces the positional 6-tuple that previously crossed three function
    layers (kernel -> softmax -> softmax_loop -> softmax_step) and every
    ``cutlass.range`` iteration -- where a silently swapped index compiles
    and deadlocks. Implements the DSL value protocol so instances are
    loop-carried through staged control flow exactly like the pipeline
    objects they hold: callees mutate fields (pipeline cursors, the
    ``si_peek`` token) and return the carrier; callers rebind.

    Fields:
      - ``si_peek``: peek token from ``mma_si.consumer_try_wait()`` for the
        next S tile (``cutlass.Boolean``).
      - ``mma_si``: QK MMA -> softmax score pipeline (consumer side here).
      - ``si_corr``: softmax -> correction row-vec pipeline (producer side).
      - ``pi_mma``: softmax -> PV MMA probability pipeline (producer side).
      - ``inplace_produce`` / ``inplace_consume``: the cross-warpgroup
        in-place P exchange semaphores (this warpgroup produces on the
        first, consumes on the second).
    """

    _fields = (
        "si_peek",
        "mma_si",
        "si_corr",
        "pi_mma",
        "inplace_produce",
        "inplace_consume",
    )

    def __init__(
        self,
        *,
        si_peek,
        mma_si,
        si_corr,
        pi_mma,
        inplace_produce,
        inplace_consume,
    ):
        self.si_peek = si_peek
        self.mma_si = mma_si
        self.si_corr = si_corr
        self.pi_mma = pi_mma
        self.inplace_produce = inplace_produce
        self.inplace_consume = inplace_consume

    def __extract_mlir_values__(self):
        values = []
        for name in self._fields:
            values.extend(extract_mlir_values(getattr(self, name)))
        return values

    def __new_from_mlir_values__(self, values):
        kwargs = {}
        for name in self._fields:
            field = getattr(self, name)
            # Size each field's slice off the current field object; the
            # structure is static so the counts match the extracted layout.
            count = len(extract_mlir_values(field))
            kwargs[name] = new_from_mlir_values(field, values[:count])
            values = values[count:]
        return type(self)(**kwargs)


class FmhaPipeline:
    def __init__(
        self,
        load_q,
        load_kv,
        qk_to_softmax0,
        qk_to_softmax1,
        softmax0_to_mma_av,
        softmax1_to_mma_av,
        softmax0_to_correction,
        softmax1_to_correction,
        correction_to_epilogue,
        mma_av_to_correction,
        softmax0_to_softmax1_p1,
        softmax1_to_softmax0_p0,
    ):
        self.load_q = load_q
        self.load_kv = load_kv
        self.qk_to_softmax0 = qk_to_softmax0
        self.qk_to_softmax1 = qk_to_softmax1
        self.softmax0_to_mma_av = softmax0_to_mma_av
        self.softmax1_to_mma_av = softmax1_to_mma_av
        self.softmax0_to_correction = softmax0_to_correction
        self.softmax1_to_correction = softmax1_to_correction
        self.correction_to_epilogue = correction_to_epilogue
        self.mma_av_to_correction = mma_av_to_correction
        self.softmax0_to_softmax1_p1 = softmax0_to_softmax1_p1
        self.softmax1_to_softmax0_p0 = softmax1_to_softmax0_p0


def make_fmha_pipeline(config):
    # TMA -> QK/PV MMA operand staging. The load warp acquires a stage, issues
    # the TMA load against the stage mbarrier (which sets the expected
    # transaction bytes), and the TMA engine's completion arrives the full
    # barrier. The MMA warp releases via tcgen05 UMMA completion.
    load_q = cute_ext.TMAToUMMAPipeline.create(
        num_stages=config.q_stage,
        mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
    )
    load_kv = cute_ext.TMAToUMMAPipeline.create(
        num_stages=config.kv_stage,
        mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
    )

    # QK MMA -> softmax_i score handoff. The MMA warp commits via tcgen05
    # UMMA completion; the softmax_i warpgroup reads S from TMEM (T2R) and
    # releases cooperatively.
    softmax_arv = config.threads_per_warp * len(config.softmax0_warp_ids)
    # Consumer is declared T2R so the release orders the softmax's tcgen05.ld
    # of S before the mbarrier arrive. tcgen05.ld is asynchronous:
    # register dataflow alone does not order its completion against the
    # arrive under the PTX memory model, so the wait::ld LIR emits here is
    # required for correctness. It is also effectively free -- it lowers to a
    # scoreboard req already covered by the register reads -- and, unlike a
    # generic (UNDEF) release, keeps the release->MMA edge within the tcgen05
    # proxy, avoiding a cross-proxy fence (MEMBAR.ALL.CTA) per release.
    qk_to_softmax0 = cute_ext.UMMAtoAsyncPipeline.create(
        num_stages=config.mma_softmax_stage,
        mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
        consumer_release_threads_per_cta=softmax_arv,
    )
    qk_to_softmax1 = cute_ext.UMMAtoAsyncPipeline.create(
        num_stages=config.mma_softmax_stage,
        mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
        consumer_release_threads_per_cta=softmax_arv,
    )
    # softmax_i -> PV MMA probability handoff. The softmax_i warpgroup stores
    # P to TMEM (R2T) and commits cooperatively; the MMA warp releases via
    # UMMA completion.
    softmax0_to_mma_av = cute_ext.AsyncToUMMAPipeline.create(
        num_stages=config.p_mma_stage,
        producer=cute_ext.OperationTypeEnum.SM100_COPY_R2T,
        producer_commit_threads_per_cta=softmax_arv,
        mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
    )
    softmax1_to_mma_av = cute_ext.AsyncToUMMAPipeline.create(
        num_stages=config.p_mma_stage,
        producer=cute_ext.OperationTypeEnum.SM100_COPY_R2T,
        producer_commit_threads_per_cta=softmax_arv,
        mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
    )
    # softmax_i -> correction row-vec handoff.
    # Producers: the softmax_i warpgroup stores the row max/sum vec to TMEM
    # (R2T) and the MMA warp contributes an ordering-only arrive that gates
    # the vec slot on the previous correction read (the vec slot aliases the
    # S accumulator TMEM). Consumer: the correction warpgroup loads the vec
    # back from TMEM (T2R).
    softmax_corr_producer_arv = config.threads_per_warp * len(
        (*config.softmax0_warp_ids, config.mma_warp_id)
    )
    correction_arv = config.threads_per_warp * len(config.correction_warp_ids)
    softmax0_to_correction = cute_ext.GenericPipeline.create(
        producer=cute_ext.OperationTypeEnum.SM100_COPY_R2T,
        consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
        producer_arv_count=softmax_corr_producer_arv,
        consumer_arv_count=correction_arv,
        num_stages=config.softmax_corr_stage,
    )
    softmax1_to_correction = cute_ext.GenericPipeline.create(
        producer=cute_ext.OperationTypeEnum.SM100_COPY_R2T,
        consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
        producer_arv_count=softmax_corr_producer_arv,
        consumer_arv_count=correction_arv,
        num_stages=config.softmax_corr_stage,
    )
    # correction -> epilogue O tile handoff. The correction warpgroup stores
    # the normalized O tile to SMEM; the epilogue warp TMA-stores it to GMEM
    # and releases once the bulk group has drained.
    correction_to_epilogue = cute_ext.GenericPipeline.create(
        producer=cute_ext.OperationTypeEnum.ST_SHARED,
        consumer=cute_ext.OperationTypeEnum.SM90_TMA_STORE,
        producer_arv_count=correction_arv,
        consumer_arv_count=config.threads_per_warp * len([config.epilogue_warp_id]),
        num_stages=config.epi_stage,
    )
    # PV MMA -> correction O handoff. The MMA warp commits via tcgen05 UMMA
    # completion; the correction warpgroup reads O from TMEM (T2R) and
    # releases cooperatively.
    mma_av_to_correction = cute_ext.UMMAtoAsyncPipeline.create(
        num_stages=config.mma_corr_stage,
        mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
        consumer_release_threads_per_cta=correction_arv,
    )
    # softmax0 <-> softmax1 in-place P exchange. These are pure ordering
    # semaphores around the shared in-place P TMEM region: the producer side
    # commits after its R2T P stores, the consumer side only waits (it never
    # releases -- backpressure comes from the MMA pipelines).
    # Declared UNDEF/UNDEF (generic synchronous): these are pure ordering
    # semaphores -- no data crosses the edge, so tcgen05 store/load fences
    # from R2T/T2R declarations would be per-iteration overhead with nothing
    # to make visible.
    softmax0_to_softmax1_p1 = cute_ext.GenericPipeline.create(
        producer=cute_ext.OperationTypeEnum.UNDEF,
        consumer=cute_ext.OperationTypeEnum.UNDEF,
        producer_arv_count=softmax_arv,
        consumer_arv_count=softmax_arv,
        num_stages=config.p_mma_stage,
    )
    softmax1_to_softmax0_p0 = cute_ext.GenericPipeline.create(
        producer=cute_ext.OperationTypeEnum.UNDEF,
        consumer=cute_ext.OperationTypeEnum.UNDEF,
        producer_arv_count=softmax_arv,
        consumer_arv_count=softmax_arv,
        num_stages=config.p_mma_stage,
    )

    return FmhaPipeline(
        load_q,
        load_kv,
        qk_to_softmax0,
        qk_to_softmax1,
        softmax0_to_mma_av,
        softmax1_to_mma_av,
        softmax0_to_correction,
        softmax1_to_correction,
        correction_to_epilogue,
        mma_av_to_correction,
        softmax0_to_softmax1_p1,
        softmax1_to_softmax0_p0,
    )
