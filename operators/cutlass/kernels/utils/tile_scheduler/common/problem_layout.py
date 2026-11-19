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

"""Derive the tile-count and cluster-count problem grids for the tile scheduler.

All grids are 3D (M, N, L). Tile-count grids count CTA tiles; cluster-count
grids count clusters. Both are rounded up to a whole number of clusters, and
the swizzled cluster layout reorders the cluster raster for L2 locality.
"""

import cutlass.cute as cute
from cutlass.cutlass_dsl import Int32, dsl_user_op
from cutlass.kernels.utils.tile_scheduler.params import TileSchedulerTemplateParams


@dsl_user_op
def get_problem_shape_ntile(
    template_params: TileSchedulerTemplateParams,
    problem_shape_mnl: cute.Shape,
    *,
    loc=None,
    ip=None,
) -> cute.Shape:
    """Tile-count grid (M, N, L) in CTA-tile units, rounded up to whole clusters.

    M and N are ``ceil_div`` of the problem extents by the CTA tile shape; the L
    extent is multiplied by ``split_k``. The result is rounded up so each
    dimension is a multiple of the corresponding cluster extent (M-major).

    :param template_params: scheduler template parameters (CTA tile / cluster shape)
    :param problem_shape_mnl: problem extents (M, N, L) in elements
    :return: tile-count grid (M, N, L)
    :rtype: cute.Shape
    """
    cta_m, cta_n, _ = template_params.cta_tile_shape_mnk
    prob_m, prob_n, prob_l = problem_shape_mnl
    cluster_m, cluster_n, cluster_l = template_params.cluster_shape
    problem_shape_ntile_mnl = cute.round_up(
        (
            cute.ceil_div(prob_m, cta_m),
            cute.ceil_div(prob_n, cta_n),
            prob_l * template_params.split_k,
        ),
        (cluster_m, cluster_n, cluster_l),
    )
    return problem_shape_ntile_mnl


@dsl_user_op
def get_problem_shape_ncluster(
    template_params: TileSchedulerTemplateParams,
    problem_shape_mnl: cute.Shape,
    *,
    loc=None,
    ip=None,
) -> cute.Shape:
    """Cluster-count grid (M, N, L): the tile-count grid divided by the cluster shape.

    :param template_params: scheduler template parameters (cluster shape)
    :param problem_shape_mnl: problem extents (M, N, L) in elements
    :return: cluster-count grid (M, N, L)
    :rtype: cute.Shape
    """
    problem_shape_ncluster_mnl = cute.ceil_div(
        get_problem_shape_ntile(template_params, problem_shape_mnl),
        template_params.cluster_shape,
    )
    return problem_shape_ncluster_mnl


@cute.jit
def get_swizzled_problem_layout_ncluster(
    template_params: TileSchedulerTemplateParams,
    problem_shape_mnl: cute.Shape,
    swizzle_size,
    raster_along_m,
) -> cute.Layout:
    """Cluster raster layout that maps a cluster-linear index to a cluster coord.

    :param template_params: scheduler template parameters (CTA tile / cluster shape)
    :param problem_shape_mnl: problem extents (M, N, L) in elements
    :param swizzle_size: tiles per swizzle group (1 disables swizzling)
    :param raster_along_m: True rasterizes M-major, False N-major
    :return: swizzled cluster raster layout, in ``(major, (swizzle, c_minor_rest), L)`` form
    :rtype: cute.Layout
    """
    m_clusters, n_clusters, l_clusters = get_problem_shape_ncluster(
        template_params, problem_shape_mnl
    )

    c_major, c_minor = Int32(0), Int32(0)
    if raster_along_m:
        c_major = Int32(cute.size(m_clusters))
        c_minor = Int32(cute.size(n_clusters))
    else:
        c_major = Int32(cute.size(n_clusters))
        c_minor = Int32(cute.size(m_clusters))

    swizzle = Int32(swizzle_size)
    c_minor_rest = (c_minor + swizzle - Int32(1)) // swizzle
    c_minor_rounded = c_minor_rest * swizzle

    return cute.make_layout(
        (c_major, (swizzle, c_minor_rest), cute.size(l_clusters)),
        stride=(
            swizzle,
            (1, swizzle * c_major),
            c_major * c_minor_rounded,
        ),
    )


@dsl_user_op
def derive_affine_divisors(
    layout: cute.Layout,
    *,
    loc=None,
    ip=None,
) -> tuple[cute.FastDivmodDivisor, cute.FastDivmodDivisor]:
    """Derive the major and minor divisors for affine coordinate decoding.

    :param layout: Swizzled cluster layout in major/minor/batch order.
    :param loc: Optional MLIR source location.
    :param ip: Optional MLIR insertion point.
    :return: Major/minor divisors for the unswizzled fast path (swizzle size one).
    :rtype: tuple[cute.FastDivmodDivisor, cute.FastDivmodDivisor]
    """
    major_size = cute.size(layout, mode=[0], loc=loc, ip=ip)
    minor_size = cute.size(layout, mode=[1], loc=loc, ip=ip)
    major_fdd = cute.fast_divmod_create_divisor(major_size, loc=loc, ip=ip)
    minor_fdd = cute.fast_divmod_create_divisor(minor_size, loc=loc, ip=ip)
    return major_fdd, minor_fdd


def get_host_cluster_counts_mn(
    template_params: TileSchedulerTemplateParams,
    problem_shape_mnkl,
) -> tuple[int, int]:
    """Return the (M, N) cluster counts for ``problem_shape_mnkl``, in plain Python.

    :param template_params: scheduler template parameters (CTA tile / cluster shape)
    :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
    :return: cluster counts along M and N
    :rtype: tuple[int, int]
    """
    m, n = problem_shape_mnkl[0], problem_shape_mnkl[1]
    cta_m, cta_n, _ = template_params.cta_tile_shape_mnk
    cluster_m, cluster_n, _ = template_params.cluster_shape
    return (
        cute.ceil_div(cute.ceil_div(m, cta_m), cluster_m),
        cute.ceil_div(cute.ceil_div(n, cta_n), cluster_n),
    )


def get_host_num_clusters(
    template_params: TileSchedulerTemplateParams,
    problem_shape_mnkl,
    swizzle_size: int,
    raster_along: str,
) -> int:
    """Return the cluster count of the swizzled raster, in plain Python.

    Mirrors :func:`get_swizzled_problem_layout_ncluster`: the batch is expanded
    by ``split_k`` and the minor raster axis is rounded up to whole swizzle
    groups.

    :param template_params: scheduler template parameters (CTA tile / cluster shape)
    :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
    :param swizzle_size: tiles per swizzle group (1 disables swizzling)
    :param raster_along: one of ``"m"`` / ``"n"``
    :return: number of clusters in the swizzled raster
    :rtype: int
    """
    m_clusters, n_clusters = get_host_cluster_counts_mn(
        template_params, problem_shape_mnkl
    )
    cluster_z = template_params.cluster_shape[2]
    l_clusters = cute.ceil_div(
        problem_shape_mnkl[3] * template_params.split_k, cluster_z
    )
    major, minor = (
        (m_clusters, n_clusters) if raster_along == "m" else (n_clusters, m_clusters)
    )
    return major * cute.round_up(minor, max(swizzle_size, 1)) * l_clusters
