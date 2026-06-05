.. _cute_dsl_naming_conventions:

CuTe DSL Naming Conventions
===========================

This page summarizes the Hungarian-style naming conventions used for identifiers across the DSL examples and epilogue helpers: tensor partitions, per-thread copy-partitioners, copy atoms, and the axis-order suffixes that encode tensor layouts. It is meant as a lookup reference while reading example code — not as a style rule enforced on new code.

Memory/space scopes
-------------------

- ``g``: Global memory view (GMEM), e.g., ``gB_nkl``, ``tTR_gC``
- ``s``: Shared memory view (SMEM), e.g., ``sA``, ``tRS_sC``, ``bSG_sC``
- ``r``: Register view (RMEM), e.g., ``tTR_rAcc``, ``tRS_rC``
- ``t``: Tensor-memory view (TMEM), used for any TMEM-resident fragment or layout regardless of role. The classical case is the accumulator (``tCtAcc``, ``tTR_tAcc``). The same scope letter also appears for non-accumulator TMEM tensors such as ``tCtE``, ``tCtState``, ``tCtQState``, ``tCtShared``. Read the operand suffix to distinguish the role from the memory scope.

Per-thread/partitioned views and families
-----------------------------------------

- ``tA…`` / ``tB…``: TMA load path for A/B

  - ``tAgA`` / ``tAsA``: per-thread partitioned global/shared A for TMA load
  - ``tBgB`` / ``tBsB``: per-thread partitioned global/shared B for TMA load
  - NVFP4/FP8 scale factors mirror this: ``tAgSFA`` / ``tAsSFA``, ``tBgSFB`` / ``tBsSFB``

- ``tC…``: Compute/epilogue path for C/Acc

  - ``tCgA`` / ``tCgB`` / ``tCgC``: per-thread partitions used by MMA/epilogue (derived from global tensors)
  - ``tCrA`` / ``tCrB``: per-thread fragments used by MMA (derived from SMEM A/B)
  - ``tCtAcc``: per-thread accumulator fragment/layout in TMEM
  - Additional ``tC*`` tensors follow the same schema for kernels that carry more than the classical A/B/C/Acc operands (see Operands and roles below): e.g. ``tCtState`` / ``tCtQState`` / ``tCtShared`` (gated-delta-net recurrent state in TMEM), ``tCrValpha`` / ``tCrVbeta`` / ``tCrVbias`` (EVT/EFC broadcast vectors in registers), ``tCtAccInter`` / ``tCtAccIntra`` (hierarchical accumulators)

  ..  {$nv-internal-release begin}

  - Sparse GEMM additionally defines ``tCtE`` for the sparsity metadata tensor in TMEM (sm_140 / Feynman sparse GEMM, not yet released)

  ..  {$nv-internal-release end}

- ``tTM…``: Per-thread TMEM tiled-copy partitions used by FMHA/attention kernels (e.g. ``tTMrO`` as the register-side view of a TMEM load partitioned through ``thr_tmem_load``)

- Attention/MLA path families (``tQ…``, ``tK…``, ``tV…``, ``tP…``, ``tO…``): same schema as ``tA…`` / ``tB…`` / ``tC…`` but specialised to the Q/K/V/P/O operands of attention kernels, e.g.:

  - ``tQsQ`` / ``tQgQ_qdl``: per-thread SMEM / GMEM partitions of Q for TMA load
  - ``tKrK`` / ``tVrV``: per-thread register fragments for K / V
  - ``tOtO`` / ``tOrO``: per-thread TMEM / register views of the attention output accumulator O
  - ``tPrP``: per-thread register fragment for the softmax probability matrix P

Data-movement copy paths
------------------------

- ``tTR_*``: TMEM → Register (T2R)

  - ``tTR_tAcc``: TMEM accumulator source for T2R
  - ``tTR_rAcc``: Register destination for T2R
  - ``tTR_gC``: When not using TMA store, Register → Global C destination partition

- ``tRS_*``: Register → Shared (R2S)

  - ``tRS_rC``: Register source (C dtype)
  - ``tRS_sC``: Shared destination

- ``bSG_*``: Thread(b)lock partition for Shared → Global via TMA store

  - ``bSG_sC``: Shared source for TMA store
  - ``bSG_gC``: Global destination for TMA store
  - Also used for accumulator in some flows: ``bSG_sAcc``, ``bSG_gAcc``
  - The same schema extends to additional store operands: ``bSG_sD`` / ``bSG_gD``, ``bSG_sP`` / ``bSG_gP``, ``bSG_sY`` / ``bSG_gY``

- ``bGS_*``: Thread(b)lock partition for Global → Shared via TMA **load** (the load-path mirror of ``bSG_*``)

  - ``bGS_gC`` / ``bGS_sC``: Global source / Shared destination for TMA load of C-like operands (seen in EFC row/column broadcast prologues)

- ``simt_atom``: SIMT copy path used when TMA store is disabled (Register → Global)
- Generic SIMT / tiled copy atoms ``<src>2<dst>_atom[_suffix]`` name the copy direction between two memory scopes:

  - ``s2r_atom_*``: Shared → Register atom used in specialised epilogues and attention loads (e.g. ``s2r_atom_delta``, ``s2r_atom_cumsum``, ``s2r_atom_d`` in Mamba2 SSD)
  - ``r2s_atom``: Register → Shared atom
  - ``t2r_atom`` / ``r2t_atom``: Tensor memory ↔ Register atoms (paired with ``thr_tmem_load`` / ``thr_tmem_store``)
  - ``s2s_atom``: Shared → Shared atom (reshape/remap without register spill)
  - ``s2t``: Shared → Tensor memory atom

  ..  {$nv-internal-release begin}

  - ``sp2t_copy_op_*``: Sparse source → Tensor memory copy op (sm_140 / Feynman sparse GEMM, not yet released: e.g. ``Sp2TAsACopyOp``, ``Sp2TAsECopyOp``)

  ..  {$nv-internal-release end}

  - Custom ``autovec_copy`` paths appear where the DSL auto-vectorises a bespoke layout

Operands and roles
------------------

- ``A``, ``B``, ``C``: GEMM operands
- ``Acc``: Accumulator (TMEM/Register paths). Hierarchical MMA kernels split this into ``AccInter`` / ``AccIntra`` for the inter-/intra-CTA accumulator halves
- Classical extra outputs / intermediates: ``D`` (additional output), ``Y`` (fused output), ``SFA`` / ``SFB`` (per-operand scale-factor arrays for NVFP4/FP8), ``SF`` (generic scale factor)
- Attention / MLA operand letters (Q/K/V/P/O schema):

  - ``Q`` (query), ``K`` (key), ``V`` (value), ``P`` (softmax probability / score matrix), ``O`` (attention output)
  - Variants: ``Kt`` / ``Vt`` for the transposed view of K/V, ``Qi`` / ``Ki`` / ``Vi`` for per-iteration slices, ``QK`` / ``PV`` / ``QKV`` where a single fragment spans multiple operands of the two back-to-back matmuls
- Mamba / recurrent-state letters: ``Delta`` / ``DeltaA`` (time-step and A-decay), ``State`` / ``QState`` / ``Shared`` (gated-delta-net recurrent state tensors), ``Cumsumlog`` / ``Cumprod`` (running reductions), ``Gate``, ``DecayV``

..  {$nv-internal-release begin}

- Sparse-GEMM letters (sm_140 / Feynman, not yet released): ``E`` (sparsity metadata tensor in TMEM; paired with ``sp2t_*`` copy ops)

..  {$nv-internal-release end}

- EVT / EFC broadcast vectors: ``Valpha`` / ``Vbeta`` (alpha/beta scalars broadcast as vectors), ``Vbias`` (bias vector), ``Ainv`` (inverse of A for fused solvers)

..  {$nv-internal-release begin}

- LUT-based block-scaled GEMM letter (Rubin, not yet released): ``LutB`` (look-up-table operand)

..  {$nv-internal-release end}
- Communication operands (multi-CTA / multicast flows): ``CommInMC`` / ``CommOutMC`` (multicast in/out), ``CommOutUC`` (unicast out)
- Head-dimension variants: ``Dv`` (value head dimension when distinct from Q/K dim), ``Nv`` (number of value heads)

Axis-order suffixes
-------------------

- Suffix encodes axis order of the view (lowercase letters each stand for one tensor mode):

  - GEMM layouts use ``m``/``n``/``k``/``l``:

    - ``_mnl``, ``_nkl``, ``_mkl``, … map to (M, N, K, L) ordering
    - Example: ``gB_nkl`` is B with axes (N, K, L); ``gC_mnl`` is C with (M, N, L)

  - Attention / FMHA layouts use ``q``/``k``/``d``/``l`` (sequence-Q, sequence-K, head-dim, batch):

    - ``mQ_qdl``: Q tensor with axes (SeqQ, HeadDim, Batch)
    - ``mK_kdl``: K tensor with axes (SeqK, HeadDim, Batch)
    - ``mV_dkl``: V tensor with axes (HeadDim, SeqK, Batch) — the ``d``-first order reflects the V-transpose that makes the second matmul (P·V) a standard row-major ``MxK·KxN``

  - Lower-rank 2D slices drop the batch letter: ``_mn``, ``_mk``, ``_nk``

- Internally, CuTe layouts also expose grouped modes like ``MMA_M/N/K``, ``EPI_M/N``, ``RestM/N/K/L``, ``STAGE``, etc. (these are typically implementation details not directly used in example code).

Reading compound tokens
-----------------------

- From left to right: ``[t|b][A|B|C|Q|K|V|P|O|TR|RS|SG|GS|TM]_[g|s|r|t][Operand/Role][AxisSuffix?]``

  - ``t`` = per-thread/partitioned view; ``b`` = block/threadblock partition context
  - family/path letters:

    - Operand-based: ``A`` / ``B`` / ``C`` (GEMM), ``Q`` / ``K`` / ``V`` / ``P`` / ``O`` (attention)
    - Direction-based: ``TR`` (TMEM → Register), ``RS`` (Register → Shared), ``SG`` (Shared → Global, store), ``GS`` (Global → Shared, load), ``TM`` (TMEM tiled-copy partition), ``R2G`` / ``S2R`` / ``T2R`` / ``R2T`` convenience aliases
  - memory = ``g``/``s``/``r``/``t``
  - operand/role = ``A``/``B``/``C``/``Acc``/``SFA``/``SFB``/``Q``/``K``/``V``/``P``/``O``/``E``/``State``/…
  - axis suffix = ``_mnl``, ``_nkl``, ``_qdl``, ``_kdl``, ``_dkl``, ``_mn``, … when applicable

- Per-thread-partitioner objects follow a parallel ``thr_*`` vocabulary, grouped by role:

  - MMA partitioner: ``thr_mma``
  - Tiled-copy direction variants ``thr_copy_<src>2<dst>``: ``thr_copy_g2s``, ``thr_copy_s2r``, ``thr_copy_t2r``, ``thr_copy_r2s``, ``thr_copy_r2t``, ``thr_copy_s2t``
  - Role-qualified copy variants: ``thr_copy_sfa``, ``thr_copy_sfb``, ``thr_copy_load``, ``thr_copy_beta_g2s``
  - MMA variants for multi-matmul kernels: ``thr_mma_qk``, ``thr_mma_pv``, ``thr_mma_kv``, ``thr_mma_qkv``, ``thr_mma_intra1`` / ``thr_mma_intra2``, ``thr_mma_leader_cta``, ``thr_mma_sfb``
  - TMEM access partitioners: ``thr_tmem_load``, ``thr_tmem_store`` (with ``_stats`` / ``_vec`` suffix variants)

  The tensor produced by ``thr_foo.partition_S(X)`` or ``.partition_D(X)`` is then named by the ``[t|b]FamilyPrefix_*`` convention above.

Concrete references
-------------------

Open these files in the repository to see each pattern in context:

- TMA load partitions for A/B:

  - ``tAgA``, ``tAsA``, ``tBgB``, ``tBsB``
  - ``CuTeDSL/cute/blackwell/kernel/dense_gemm/dense_gemm.py`` (around TMA partition of A/B)

- Accumulator fragment in TMEM:

  - ``tCtAcc``
  - ``CuTeDSL/cute/blackwell/kernel/dense_gemm/dense_gemm.py`` (accumulator creation and use)

- TMEM → Register (T2R):

  - ``tTR_tAcc``, ``tTR_rAcc``, ``tTR_gC``
  - ``CuTeDSL/cute/blackwell/kernel/dense_gemm/dense_gemm.py`` (``epilog_tmem_copy_and_partition``)

- Register → Shared (R2S):

  - ``tRS_rC``, ``tRS_sC``
  - ``CuTeDSL/cute/blackwell/kernel/mixed_input_gemm/mixed_input_gemm.py`` (``epilog_smem_copy_and_partition``)

- Shared → Global via TMA store:

  - ``bSG_sC``, ``bSG_gC``
  - ``CuTeDSL/cute/blackwell/kernel/blockscaled_gemm/dense_blockscaled_gemm_persistent.py`` (``epilog_gmem_copy_and_partition``)

- NVFP4/FP8 scale factors:

  - ``tAgSFA``/``tAsSFA``, ``tBgSFB``/``tBsSFB``
  - ``CuTeDSL/cute/blackwell/tutorial/tutorial_gemm/nvfp4_gemm_0.py`` (scale factor partition and usage)

- Additional examples across ``examples/``:

  - Register → Global helper naming in MLA: ``tR2G_rO_src``, ``tR2G_rO_dst``
  - ``CuTeDSL/cute/blackwell/kernel/attention/mla/mla_decode_fp16.py`` (output store section)

  - Shared → Register SIMT atoms in Mamba2 SSD: ``s2r_atom_delta``, ``s2r_atom_cumsum``, ``s2r_atom_d``
  - ``CuTeDSL/cute/blackwell/kernel/attention/mamba2_ssd/mamba2_ssd.py`` (SMEM load paths for delta and D)

  - ``thr_*`` slices for partitioning per-thread work: ``thr_mma``, ``thr_copy_t2r``, ``thr_copy_r2s``, etc.
  - ``CuTeDSL/cute/blackwell/kernel/dense_gemm/dense_gemm.py`` (``thr_mma``, ``thr_copy_t2r``, ``thr_copy_r2s``)

- Axis-order suffix examples:

  - ``gB_nkl``, ``gC_mnl``
  - ``CuTeDSL/cute/blackwell/kernel/dense_gemm/dense_gemm.py`` (global tensor tiling and partitioning)

- Global → Shared (TMA load) block partition ``bGS_*``:

  - ``bGS_gC``, ``bGS_sC``
  - ``CuTeDSL/cute/blackwell/efc/common_efc.py`` (row/column broadcast prologue building the C-like input for EVT)

- Attention Q/K/V/P/O families and ``_qdl`` / ``_kdl`` / ``_dkl`` axis suffixes:

  - ``tQsQ``, ``tQgQ_qdl``, ``mK_kdl``, ``mV_dkl``
  - ``CuTeDSL/cute/hopper/kernel/attention/fmha.py`` (Q/K/V TMA partitions)
  - ``tOtO``, ``tOrO``, ``tPrP``
  - ``CuTeDSL/cute/blackwell/tutorial/tutorial_fmha/fmha_0.py`` (output and softmax fragments)
  - ``tKrK``, ``tVrV``
  - ``CuTeDSL/cute/blackwell/kernel/attention/mixed_input_fmha/mixed_input_fmha_decode.py`` (mixed-input K/V register fragments)

- TMEM tiled-copy ``tTM*`` family and the generalised ``<src>2<dst>_atom`` naming:

  - ``tTMrO`` driven by ``thr_tmem_load``
  - ``CuTeDSL/cute/blackwell/tutorial/tutorial_fmha/fmha_0.py``

- Recurrent-state operands (``State`` / ``QState`` / ``Shared``) in TMEM:

  - ``tCtState``, ``tCtQState``, ``tCtShared``
  - ``CuTeDSL/cute/blackwell/kernel/attention/gated_delta_net/gated_delta_net_chunked.py``

..  {$nv-internal-release begin}

- Sparse-metadata operand ``E`` and ``sp2t_*`` copy ops (sm_140 / Feynman, not yet released):

  - ``tCtE``, ``sp2t_copy_op_A``, ``sp2t_copy_op_E``
  - ``CuTeDSL/internal/feynman/sm140_sparse_gemm.py`` and ``sm140_sparse_gemm_temporal_split_k.py``

- LUT-based block-scaled GEMM operand ``LutB`` (Rubin, not yet released):

  - ``CuTeDSL/cute/rubin/kernel/blockscaled_gemm/dense_blockscaled_gemm_lut.py``
  - ``CuTeDSL/cute_ext/rubin/dense_gemm_lutb.py``

..  {$nv-internal-release end}

- Richer ``thr_*`` and ``thr_copy_*`` / ``thr_mma_*`` / ``thr_tmem_*`` partitioner taxonomy:

  - ``thr_copy_g2s``, ``thr_copy_s2r``, ``thr_copy_s2t``, ``thr_copy_r2t``, ``thr_mma_qk``, ``thr_mma_pv``, ``thr_tmem_load``, ``thr_tmem_store``
  - The attention and Mamba2 examples above are the densest references; any ``fmha_*.py`` or ``mamba2_ssd.py`` file will show the full vocabulary in use
