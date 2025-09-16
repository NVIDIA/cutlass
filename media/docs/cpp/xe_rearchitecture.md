# Xe CuTe Architecture Redesign

## Limitations of Current Intel CuTe Architecture

* VNNI layout used by DPAS and block 2D VNNI loads is hidden from CuTe/CUTLASS.
  - Compiler inserts extra interleave/deinterleave operations if there is any computation between VNNI load and DPAS.
  - Additionally, any such computation using the native B data type (instead of int) can lead to private memory traffic.
* MMA and copy fragments must be carefully set up to match layouts
  - Fragile code, easy to break functionality
  - Sometimes it's not possible or desirable to match layouts
* Block 2D atoms are somewhat disconnected from the actual operations in HW
  - Thread-value layouts (of both atoms and TiledCopys) don't reflect the actual ownership of data by threads.
  - Necessary to introduce "fake" copy atoms (like the U4 atoms) that do not reflect actual HW operations.


## Goals

The large-scale goal of this re-architecture is to improve CUTLASS performance and flexibility on pre-Xe4 GPUs. In more detail, we want to:

* Rewrite MMA/copy atoms to accurately expose HW capabilities
  - Expose VNNI layouts for MMA B matrix and VNNI block 2D copies
  - Expose the actual block 2D operations provided by HW

* Improve performance
  - Introduce high-performance subgroup-level reorder operations for copying data that can change data types and layouts at the same time
  - Remove hidden overheads from MMA/copy atoms

* Improve ease-of-use
  - Introduce helper functions to construct accurate block 2D TiledCopy objects
  - Allow user to partition tensors to copy and MMA fragments following the usual CuTe paradigm, without worrying about whether the fragments' layouts match perfectly

* Improve maintainability
  - Reduce boilerplate/duplication in atom definitions
  - Allow more flexible sizes in block 2D atoms
  - Make it easy to add new operations for CRI

In the following sections, we will walk through the proposed changes.


## DPAS Atoms

All DPAS MMA atoms are now instantiations of a single `XE_DPAS_TT` template.

Following CuTe conventions, the `TT` part of the name reflects the interpretation of A/B as row-major matrices, although more accurately B is VNNI-transformed.

```c++
template <int M, typename TypeD, typename TypeA, typename TypeB = TypeA, typename TypeC = TypeD>
struct XE_DPAS_TT;
```

Hardware allows any `M` with 1 <= M <= 8, while `N` is fixed at 16 for all CUTLASS-supported GPUs (PVC and later). The `K` dimension depends on the data types, and can be queried from the atom.

Default template parameters are available for B/C since they often match A/D respectively, but HW can support different combinations (e.g. f16/f16/f16/f32 or s32/u8/s4/s32).

Initially, `XE_DPAS_TT` has been implemented using inline vISA; this is required in order to correctly expose matrix B's VNNI layout.


## Block 2D Copy Atoms

### Background and Atom Definition

PVC introduces 2D block messages that move fixed-size 2D tiles between global memory and registers. Their main features:

* Automatic bounds-checking -- removing out-of-bounds global memory accesses and filling out-of-bounds loaded elements with zeros
* Layout changes that in many cases allow DPAS to work directly on loaded data, without additional data reordering in registers/SLM.

These messages also come with important restrictions to know about:

* Alignment restrictions:
  - Buffer base address must be 64-byte-aligned
  - Stride must be 16-byte-aligned (in some cases on PVC, 4 or 8-byte alignment is OK)
  - Width (defined later) must be 4-byte-aligned
* Size restrictions:
  - Width/pitch are restricted to 2^24 bytes
  - Height is restricted to 2^24 elements

For debugging, the user can compile with `-DCUTE_ENABLE_XE_BLOCK_2D_ASSERT=1` to enable (expensive) runtime checks on these restrictions.

In hardware, block 2D copies come in 4 types:

* 2D load (8/16/32/64 bits per element)
* 2D load with VNNI transform (8/16 bits per element)
* 2D load with transpose (32/64 bits per element)
* 2D store (8/16/32/64 bits per element)

In addition, any load can be turned into a prefetch. However, the VNNI transform/transpose options are not relevant for prefetching, so can be safely disregarded.

All said, there are 5 operations to consider, and each of these has a corresponding templated atom class:

* Loads: `XE_LOAD_2D`, `XE_LOAD_2D_VNNI`, `XE_LOAD_2D_TRANSPOSE`
* Store: `XE_STORE_2D`
* Prefetch: `XE_PREFETCH_2D`

Block 2D messages use image terminology: a 2D buffer has a _width_ (x dimension), _height_ (y dimension), and _pitch_ (y dimension stride). Width/x always refers to the dimension that is contiguous (stride-1) **in memory**; height/y is the strided dimension. A transposing load will store the y dimension contiguously in registers, while regular load/store messages have the x dimension contiguous in registers.

In hardware, block 2D messages have 4 main configuration points:

* Data size (8/16/32/64 bit)
* Block width
* Block height
* Block count

_Block width/height_ define the size of each block. Again, this is the size as seen in global memory.

The _block count_ parameter (available for regular and VNNI loads only) can load multiple blocks at once. In memory, blocks are adjacent in the width dimension, so the total tile size loaded from memory has size `(width*count) x height`. The block count has the effect of rearranging loaded data in registers, and can be used to ensure that the loaded data can be fed directly to DPAS, without needing further rearrangement in registers.

Finally, _data size_ controls how HW interprets other parameters (e.g. block width, transposition) but does not need to match the actual data type stored in memory. For instance, we can use a 32-bit transpose load with 8-bit or 16-bit data. This results in VNNI-format data in registers, perfect for the DPAS B matrix.

These four parameters translate to template parameters for the CuTe copy atoms:

```c++
template <int Bits, int Height, int Width, int BlockWidth = Width>
struct XE_LOAD_2D;

template <int Bits, int Height, int Width, int BlockWidth = Width>
struct XE_LOAD_2D_VNNI;

template <int Bits, int Height, int Width>
struct XE_LOAD_2D_TRANSPOSE;

template <int Bits, int Height, int Width>
struct XE_STORE_2D;

template <int Bits, int Height, int Width>
struct XE_PREFETCH_2D;
```

Above, `Width` is the total width loaded (block width * block count). The `Width` and `Height` parameters are ordered to reflect a row-major view of 2D data in memory: height = #rows, width = #columns.

### Block 2D Traits

The traits classes come with further configuration parameters so we can apply these abstract copy operations onto specific global memory tensors. Most users don't need to worry about setting up these parameters, since they are automatically chosen by the `make_block_2d_copy` helper APIs (described in the following section).


```c++
template <class XMode, class YMode, typename ValType, typename TiledStrides, /*...*/>
struct Copy_Traits</* Op */, XMode, YMode, ValType, TiledStrides>;
```

* `XMode`, `YMode`: indices of the modes (dimensions) corresponding to x and y.
  - For instance, a 3D k-major tensor with indices ordered (M,K,L) would have `XMode = 1`, `YMode = 0`.
* `ValType`: actual data type (possibly having a different size than the underlying block 2D operation).
  - In CuTe, this template parameter is specified at the `Copy_Atom` level, but for Xe it's also required in the traits due to the compiler's SIMD-like register data mapping.
* `TiledStrides`: strides for modes other than x/y, for > 2D tensors.

### Creating Block 2D Atoms

Since it can be a tricky to correctly choose block 2D parameters and set up an appropriate tiling, we introduce several helpers for creating TiledCopy objects.

The high-level APIs `make_block_2d_copy_{A,B,C}` automatically create TiledCopy objects for use with an existing `TiledMMA`. They choose the copy operation and trait template parameters heuristically.

```c++
template <class Engine, class Layout, /*...*/>
CUTE_DEVICE
TiledCopy<...>
make_block_2d_copy_A(const TiledMMA<...>&,
                     const Tensor<Engine, Layout>& gmem);       // (M,K,...)

template <class Engine, class Layout, /*...*/>
CUTE_DEVICE
TiledCopy<...>
make_block_2d_copy_B(const TiledMMA<...>&,
                     const Tensor<Engine, Layout>& gmem);       // (N,K,...)

template <class Engine, class Layout, /*...*/>
CUTE_DEVICE
TiledCopy<...>
make_block_2d_copy_C(const TiledMMA<...>&,
                     const Tensor<Engine, Layout>& gmem);       // (M,N,...)
```

The user may also override the choice of copy operation:

```c++
template <class TiledMMA, class CopyOp, class GEngine, class GLayout>
CUTE_HOST_DEVICE
auto
make_block_2d_copy_A(CopyOp                   const& op,     // Copy operation
                     TiledMMA                 const& mma,    // TiledMMA instance
                     Tensor<GEngine, GLayout> const& gmem);  // Global tensor

/* Similarly for B/C */
```

The `make_block_2d_copy_*` family of functions create TiledCopy objects that match the scope of the TiledMMA. That is, the set of threads participating in the TiledMMA will also participate in the TiledCopy.

By contrast, the `make_block_2d_copy` API creates a TiledCopy object in which a single subgroup participates:

```c++
// Create tiled block 2D copy (scope = single subgroup) for a global memory tensor.
template <class CopyOp, class Engine, class Layout>
CUTE_DEVICE
TiledCopy
make_block_2d_copy(const CopyOp& op, const Tensor<Engine, Layout>& gmem);
```

For advanced usage, there are additional overloads of `make_block_2d_copy` that allow more general work distributions for copies (see `include/cute/atom/copy_traits_xe_2d.hpp`).

As the `CUTE_DEVICE` decorators imply, all the APIs above should be called from device code only, as they set up internal state that cannot be transferred from host to device.

Alternately, these APIs have variants that take strides and an optional data type override. The resulting TiledCopy objects are uninitialized.

```c++
template <class ValType, class CopyOp, class... Strides>
TiledCopy
make_block_2d_copy_A(TiledMMA<...> const& mma, Stride<Strides...> const& strides);
```

After this _placeholder_ TiledCopy is created, it can be initialized on the device in the standard CuTe fashion, using `with`:

```c++
/* host code */
TiledCopy copy_a_placeholder = make_block_2d_copy_A<float>(...);
...

/* device code */
Tensor gA = make_tensor(make_gmem_ptr(...), ...);
TiledCopy copy_a = copy_a_placeholder.with(gA);     /* copy_a is now ready to use */
```

### Using Block 2D Atoms

Block 2D copy atoms follow a "proxy copy" pattern, somewhat akin to the NVIDIA TMA copy atoms.

At creation time, a block 2D copy atom is constructed with a global tensor, which becomes part of the atom's state. When copying, instead of partitioning the global tensor, the user partitions a corresponding coordinate tensor instead, providing the coordinates (within that global tensor) that should be copied.

```c++
Tensor gA = make_tensor(make_gmem_ptr(...), ...);

/* Construct TiledCopy with global tensor */
TiledCopy copy_a = make_block_2d_copy_A(mma, gA);
ThrCopy thr_copy_a = copy_a.get_slice(...);

/* Create a proxy coordinate tensor and use it for actual copy operations */
Tensor cA = make_identity_tensor(gA.shape());
Tensor tAcA = thr_copy_a.partition_S(cA);

Tensor tArA = thr_copy_a.partition_fragment_D(cA);

/* Copy from global (via coordinate tensor) to registers */
copy(copy_a, tAcA, tArA);
```


## Subgroup Scope and Thread-Local Data

DPAS and block 2D copy atoms are _subgroup_ operations, meaning that all 16 threads of the subgroup collectively execute these operations, and collectively own all input/output data. This "subgroupness" reflects the underlying SIMD nature of Intel GPUs: the 16 "threads" are in reality a single thread of execution in HW.

In order to perform thread-level operations on subgroup-shared data, it's important to understand how the compiler splits ownership of subgroup-scoped private arrays (including register-resident data) among threads. Fortunately, there is a very simple rule for this:
```math
    \text{thread\ } i\ \ \  \text{owns elements} \ \ \ i, i+16, i+32, \ldots
```
That is to say, elements are assigned to threads in a round-robin fashion. Conversely, if we declare a vector variable (say `cute::intel::float8`) in SYCL, the compiler will interleave the vectors from each thread in the subgroup to form a length-128 (8 * 16) float array in registers.

> [!IMPORTANT]
> Note that the thread mapping _depends on the element data size._ If an array of 32-bit data, say, is reinterpreted _on a register level_ as an array of 16-bit data, data ownership will change -- i.e., in SIMT terms, it is a shuffle operation. Contrast this operation with a SIMT bitcast/reinterpret_cast, which does not change data ownership, but _does_ shuffle data in registers.

Now that we have the basic thread mapping rule, let's apply it to a simple block 2D load, with height = 8 rows and width = 4 columns. Recalling that the width dimension is contiguous in both memory and registers, we deduce the following mapping:
```math
    \begin{array}{c}
    \text{Subgroup view}\\
    \begin{array}{cccc}
    0 & 1 & 2 & 3\\
    4 & 5 & 6 & 7\\
    8 & 9 & 10 & 11\\
    12 & 13 & 14 & 15\\
    16 & 17 & 18 & 19\\
    20 & 21 & 22 & 23\\
    24 & 25 & 26 & 27\\
    28 & 29 & 30 & 31
    \end{array}
    \end{array}
    \rightarrow
    \begin{array}{c}
    \text{Thread view}\\
    \begin{array}{cccc}
    \text{T0V0} & \text{T1V0} & \text{T2V0} & \text{T3V0}\\
    \text{T4V0} & \text{T5V0} & \text{T6V0} & \text{T7V0}\\
    \text{T8V0} & \text{T9V0} & \text{T10V0} & \text{T11V0}\\
    \text{T12V0} & \text{T13V0} & \text{T14V0} & \text{T15V0}\\
    \text{T0V1} & \text{T1V1} & \text{T2V1} & \text{T3V1}\\
    \text{T4V1} & \text{T5V1} & \text{T6V1} & \text{T7V1}\\
    \text{T8V1} & \text{T9V1} & \text{T10V1} & \text{T11V1}\\
    \text{T12V1} & \text{T13V1} & \text{T14V1} & \text{T15V1}
    \end{array}
    \end{array}
```
(Following CuTe convention, `TxVy` means thread `x`, value `y`.)

An individual DPAS atom's A matrix follows the same pattern, with height ranging from 1 to 8, and width equal to 8 (tf32), 16 (f16/bf16), or 32 (s8/u8). The DPAS C matrix is also organized this way, except that its width is always 16.

As a more complicated example, let's consider a 16-bit VNNI load, with height = 4, width = 16:
```math
    \begin{array}{c}
    \text{Subgroup view}\\
    \begin{array}{cccccc}
    0 & 2 & 4 & 6 & \cdots & 30\\
    1 & 3 & 5 & 7 & \cdots & 31\\
    32 & 34 & 36 & 38 & \cdots & 62\\
    33 & 35 & 37 & 39 & \cdots & 63
    \end{array}
    \end{array}
    \rightarrow
    \begin{array}{c}
    \text{Thread view}\\
    \begin{array}{cccc}
    \text{T0V0} & \text{T2V0} & \text{T4V0} & \cdots & \text{T14V0} & \text{T0V1} & \cdots & \text{T14V1}\\
    \text{T1V0} & \text{T3V0} & \text{T5V0} & \cdots & \text{T15V0} & \text{T1V1} & \cdots & \text{T15V1}\\
    \text{T0V2} & \text{T2V2} & \text{T4V2} & \cdots & \text{T14V2} & \text{T0V3} & \cdots & \text{T14V3}\\
    \text{T1V2} & \text{T3V2} & \text{T5V2} & \cdots & \text{T15V2} & \text{T1V3} & \cdots & \text{T15V3}
    \end{array}
    \end{array}
```

The DPAS B matrix follows the same pattern.


### The SubgroupTensor Class

A new `SubgroupTensor` class represents a subgroup-scope tensor (fragment). SubgroupTensor wraps a standard CuTe rmem Tensor holding the current work-item's slice of the tensor. It implicitly decays to this fragment, so it can be used as a regular rmem Tensor.

In addition to tensor data, a SubgroupTensor holds a thread-value layout identifying logical coordinates for each element of the tensor. The interpretation of the logical coordinates is user-defined.

```c++
template <class Engine,
          class Layout,               // fragment coord -> V
          class SubgroupTVLayout>     // (T,V) -> coord in subgroup
struct SubgroupTensor;

// Create a SubgroupTensor from an existing rmem Tensor
template <...>
auto make_subgroup_tensor(Tensor<Engine, Layout> const&, SubgroupTVLayout const&);
```

To create a `SubgroupTensor`, use the new `partition_sg_fragment_*` methods of the `ThrCopy` and `ThrMMA` classes:
```c++
  template <class ATensor>
  CUTE_HOST_DEVICE constexpr auto
  ThrMMA::partition_sg_fragment_A(ATensor&& atensor) const;     // Similarly for B/C

  template <class STensor>
  CUTE_HOST_DEVICE auto
  ThrCopy::partition_sg_fragment_S(STensor&& stensor) const;    // Similarly for D
```


## Subgroup Reorders

Each subgroup-scope operation (MMA atom, copy atom) requires specific logical layouts. For, instance the DPAS B matrix needs to be in VNNI format, in blocks of Kx16 (for some specific value of K). In many cases, we can use block 2D copy atoms to load data in exactly the right layout. In other cases, we can't, because:

* The copy/MMA atoms are tiled and these tilings don't match.
* No block 2D copy produces data in the right layout, e.g.:
  - Transposed A, if the data type is less than 32 bits wide.
  - Dequantizing B, if the storage data type is smaller than the compute data type.
* The fastest load operation is not block 2D (e.g. some memory-bound kernels).
* Block 2D operations cannot be used (insufficient memory alignment, matrix size too large, etc.)
* Data needs to be broadcast/duplicated in special patterns (e.g. scales/zero points).


A flexible and powerful way to handle all these situations is via a subgroup-scope _reorder_ operation that allows arbitrary layout changes (shuffles) in registers. In addition to layout changes, reorders may include data type conversions, because these conversions can often be fused into the layout conversion for more efficient code.

The general API for a reorder looks like:

```c++
reorder(SubgroupTensor<...> const& src_fragment,
        SubgroupTensor<...>      & dst_fragment);
```

`reorder` copies subgroup-scoped data between subgroup-owned fragments `src_fragment` and `dst_fragment`. `reorder` uses the subgroup TV layout (part of the SubgroupTensor) to determine which source values map to which destination values. These are computed automatically by the `partition_sg_fragment_*` family of methods.

`reorder` acts as a "pipe" connecting copy and MMA operations (or any other subgroup-scope operations). With reorders, the kernel writer does not need to worry about perfectly matching layouts between copy and MMA atoms. In case the layouts do match perfectly (as `make_block_2d_copy_{A,B,C}` try to do), the compiler is able to remove the reorder entirely, making it a no-op.

A longer version of the reorder API takes the source and destination fragments as ordinary `Tensor` objects, in which case the subgroup TV-layouts must be passed in as auxiliary parameters.

```c++
reorder(Tensor<...> const& src_fragment,
        Tensor<...>      & dst_fragment,
        Layout<...>      & src_sg_layout,       /* (T,V) -> coord */
        Layout<...>      & dst_sg_layout)       /* (T,V) -> coord */
```


## Example CuTe GEMM

Let's combine the pieces here to make a complete CuTe-level Xe GEMM kernel. Fully runnable code can be found at [examples/cute/tutorial/xe_gemm.cpp](../../../examples/cute/tutorial/xe_gemm.cpp).

```c++
template <class ATensor, class BTensor, class CTensor,
          class TiledMMA>
void
gemm_device(ATensor   const& A,         // (M,K)
            BTensor   const& B,         // (N,K)
            CTensor        & C,         // (M,N)
            TiledMMA const & mma)
{
  // -----
  // Setup
  // -----

  /* Get workgroup and local IDs */
  auto item = sycl::ext::oneapi::this_work_item::get_nd_item<2>();
  auto wg_m = int(item.get_group(1));
  auto wg_n = int(item.get_group(0));
  auto local_id = int(item.get_local_id(0));

  /* Create proxy coordinate tensors for each global tensor */
  Tensor cA = make_identity_tensor(A.shape());   // (M,K)
  Tensor cB = make_identity_tensor(B.shape());   // (N,K)
  Tensor cC = make_identity_tensor(C.shape());   // (M,N)

  /* Split GEMM into workgroup tiles, and identify our workgroup's tile (wg_coord) */
  auto wg_tile = mma.tile_mnk();
  auto wg_coord = make_coord(wg_m, wg_n, 0);

  Tensor gA = local_tile(cA, select<0,2>(wg_tile), make_coord(wg_m,_));  // (BLK_M,BLK_K,k)
  Tensor gB = local_tile(cB, select<1,2>(wg_tile), make_coord(wg_n,_));  // (BLK_N,BLK_K,k)
  Tensor gC = local_tile(cC, wg_tile, wg_coord, Step<_1,_1, X>{});       // (BLK_M,BLK_N)

  /* Create block 2D TiledCopies */
  auto copy_a = make_block_2d_copy_A(mma, A);
  auto copy_b = make_block_2d_copy_B(mma, B);
  auto copy_c = make_block_2d_copy_C(mma, C);

  /* Slice TiledCopy/TiledMMA operations to thread (work-item) level */
  auto thr_mma    =    mma.get_slice(local_id);
  auto thr_copy_a = copy_a.get_slice(local_id);
  auto thr_copy_b = copy_b.get_slice(local_id);

  /* Register fragments for MMA */
  auto tCrA = thr_mma.partition_sg_fragment_A(gA(_,_,0));
  auto tCrB = thr_mma.partition_sg_fragment_B(gB(_,_,0));

  /* Register fragments for copies */
  auto tArA = thr_copy_a.partition_sg_fragment_D(gA(_,_,0));
  auto tBrB = thr_copy_b.partition_sg_fragment_D(gB(_,_,0));

  /* Partition global tensor (proxies) for copies */
  Tensor tAgA = thr_copy_a.partition_S(gA);
  Tensor tBgB = thr_copy_b.partition_S(gB);

  /* Partition C */
  Tensor tCrC = partition_fragment_C(mma, select<0,1>(wg_tile));
  Tensor tCgC = thr_mma.partition_C(gC);    /* also matches copy_c's source layout */

  /* Create prefetch TiledCopy instances */
  auto prefetch_a = make_block_2d_prefetch(copy_a);
  auto prefetch_b = make_block_2d_prefetch(copy_b);

  auto thr_prefetch_A = prefetch_a.get_slice(local_id);
  auto thr_prefetch_B = prefetch_b.get_slice(local_id);

  /* Partition global tensor (proxies) for prefetch */
  auto pAgA = thr_prefetch_A.partition_S(gA);
  auto pBgB = thr_prefetch_B.partition_S(gB);

  /* Prefetch distance, in units of k tiles */
  const int prefetch_dist = 2;

  // ------
  // Kernel
  // ------

  constexpr int barrier_scope = 2;

  int k_tile_count = ceil_div(shape<1>(A), get<2>(wg_tile));
  int k_tile_prefetch = 0;

  /* Clear the accumulators */
  clear(tCrC);

  /* Warm up loops with prefetch to L1 */
  CUTE_UNROLL
  for (; k_tile_prefetch < prefetch_dist; k_tile_prefetch++) {
    prefetch(prefetch_a, pAgA(_,_,_,k_tile_prefetch));
    prefetch(prefetch_b, pBgB(_,_,_,k_tile_prefetch));
  }

  /* Main loop */
  for (int k_tile = 0; k_tile < k_tile_count; k_tile++, k_tile_prefetch++) {
    /* Split barrier keeping threads loosely together */
    barrier_arrive(barrier_scope);

    /* Copy A/B from global memory (ideally L1 cache) to registers */
    copy(copy_a, tAgA(_,_,_,k_tile), tArA);
    copy(copy_b, tBgB(_,_,_,k_tile), tBrB);

    /* Prefetch A/B tiles to L1 */
    prefetch(prefetch_a, pAgA(_,_,_,k_tile_prefetch));
    prefetch(prefetch_b, pBgB(_,_,_,k_tile_prefetch));

    /* Shuffle data from copy fragments to MMA fragments */
    reorder(tArA, tCrA);
    reorder(tBrB, tCrB);

    /* Accumulate C += A * B */
    gemm(mma, tCrA, tCrB, tCrC);

    /* Other half of split barrier */
    barrier_wait(barrier_scope);
  }

  /* Write C to global memory */
  copy(copy_c, tCrC, tCgC);
}
```


## New Collective MMAs

... coming later!