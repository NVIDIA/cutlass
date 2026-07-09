# CUTLASS Tutorial Examples for Blackwell TMA

## TMA V0: Understanding tma_partition - The Foundation of TMA Operations

This example demonstrates the fundamental building blocks of Tensor Memory Accelerator (TMA) operations on NVIDIA Blackwell (SM100) architecture using CuTe DSL. It focuses on understanding the `tma_partition` interface, which is essential for all TMA operations.

### Key Concepts

*   **TMA Load (Global → Shared)**: Asynchronous bulk data transfer from Global Memory to Shared Memory using TMA hardware
*   **TMA Store (Shared → Global)**: Asynchronous bulk data transfer from Shared Memory back to Global Memory
*   **tma_partition**: Core interface that prepares tensors for TMA operations by partitioning them according to TMA atom layout requirements
*   **group_modes**: Tensor mode grouping to define the TMA atom shape - crucial for proper tma_partition usage
*   **mbarrier Synchronization**: Hardware barriers (`mbarrier_init`, `mbarrier_arrive`, `mbarrier_wait`) for synchronizing asynchronous TMA operations

### Kernel Architecture

The `Sm100SimpleCopyKernel` performs a simple tile-based copy operation to illustrate TMA fundamentals:

#### Configuration

*   **tile_shape**: Fixed at (128, 128) - Tile dimensions (M, N)
*   **cluster_shape_mn**: Fixed at (1, 1) - Single CTA execution (no cluster parallelism)
*   **Shared Memory**: Single buffer sized to hold one tile (tile_m × tile_n elements)
*   **Synchronization**: Single mbarrier for TMA load completion

#### Key Components

1.  **TMA Descriptor Creation**: Creates TMA atoms (`tma_atom_src`, `tma_atom_dst`) that encapsulate TMA hardware instructions
2.  **Shared Memory Layout**: Row-major layout `(tile_m, tile_n):(tile_n, 1)` for simplicity
3.  **Barrier Management**: Single barrier coordinates TMA load completion before processing

### Execution Flow

1.  **Initialization**:
    *   Allocate shared memory buffer for one tile
    *   Initialize mbarrier with `elect_one()` to ensure proper synchronization semantics
    *   Set barrier to expect TMA transaction bytes (`tile_m × tile_n × element_size`)
    *   Synchronize all threads after barrier initialization

2.  **Tensor Preparation**:
    ```
    Tile global tensors into (tile_m, tile_n) blocks
    Apply group_modes to combine tile dimensions into Mode 0 (TMA atom)
    
    Example: gSrc_tiled with shape (128, 128, 4, 2)
    After group_modes(_, 0, 2): ((128, 128), 4, 2)
                                  └───┬────┘  └─┬─┘
                                   Mode 0    Rest modes
    ```

3.  **TMA Partition**:
    ```python
    tAsA, tAgA = tma_partition(
        tma_atom_src,          # TMA operation atom
        cta_id=0,              # CTA ID within cluster
        cta_layout,            # Cluster layout
        group_modes(smem_tensor, 0, 2),   # SMEM view (Mode 0 = atom)
        group_modes(gSrc_tiled, 0, 2)     # Global view (Mode 0 = atom)
    )
    # Returns:
    # tAsA: SMEM view with TMA internal layout
    # tAgA: Global view with shape ((TMA_Layout), grid_m, grid_n)
    ```

4.  **Tile Selection**:
    ```python
    # Select specific tile for this CTA
    tAgA_cta = tAgA[(None, bidx, bidy)]
    # None: keep entire TMA atom (Mode 0)
    # bidx, bidy: index into grid dimensions
    ```

5.  **TMA Load** (Global → Shared):
    ```python
    cute.copy(tma_atom_src, tAgA_cta, tAsA, tma_bar_ptr=barrier_ptr)
    # Arrive on barrier (producer signals completion)
    # Wait on barrier (all threads wait for TMA completion)
    ```

6.  **TMA Store** (Shared → Global):
    ```python
    cute.copy(tma_atom_dst, tAsA, tBgB_cta)
    # Synchronous store completes before kernel exit
    ```

### Understanding tma_partition

The `tma_partition` function is the key to TMA operations. The tutorial includes comprehensive inline diagrams showing:

*   **Input Tensor Shapes**: How tensors are organized before partitioning
*   **group_modes Effect**: How mode grouping creates the required atom structure
*   **Partition Output**: The structure of partitioned tensors for TMA operations
*   **Indexing Pattern**: How to select CTA-specific tiles from partitioned views

See lines ~155-255 in `tma_v0.py` for detailed visual explanations.

### Configuration Parameters

*   `tile_shape`: Fixed at (128, 128) - Tile dimensions (M, N)
*   `cluster_shape_mn`: Fixed at (1, 1) - Single CTA execution
*   `threads_per_cta`: 32 - Single warp (all threads participate in barriers)
*   `buffer_align_bytes`: 1024 - Shared memory alignment

### Usage

Run the copy kernel with custom matrix dimensions:

```bash
# Basic usage (default: 512×128 matrix)
python tma_v0.py

# Custom dimensions
python tma_v0.py --M 1024 --N 2048

# With custom benchmark iterations
python tma_v0.py --M 4096 --N 4096 --num_warmup 10 --num_iters 50
```

#### Example Code

```python
from tma_v0 import run_tma_copy

# Run copy on 1024×2048 matrix
run_tma_copy(M=1024, N=2048)
# Output: Performance metrics and verification result
```

### Performance Considerations

*   **Single-stage operation**: No pipelining - simple sequential load → store pattern
*   **Educational focus**: Designed for understanding TMA fundamentals, not peak performance
*   **Barrier synchronization**: Demonstrates proper mbarrier usage patterns
*   **Foundation for V1/V2**: Concepts learned here are essential for understanding multi-stage pipelines and warp specialization in V1 and V2

## TMA V1: Matrix Transpose with Producer-Consumer Pattern

This example demonstrates a TMA-based matrix transpose using producer-consumer synchronization with mbarriers on NVIDIA Blackwell (SM100) architecture.

### Key Concepts

*   **Producer-Consumer Pattern**: Different warps coordinate through mbarrier synchronization
*   **TMA Operations**: Asynchronous bulk data transfer between Global and Shared Memory
*   **Shared Memory Swizzle**: Optimized layouts to avoid bank conflicts during transpose
*   **Warp Specialization**: Dedicated warps for loading, transposing, and storing
*   **mbarrier Synchronization**: Hardware barriers coordinate asynchronous operations

### Kernel Architecture

The `Sm100MatrixTransposeKernel` performs a tiled matrix transpose (M×N → N×M) with the following design:

#### Warp Roles

1.  **TMA Load Warp** (Warp 4, Producer): Issues TMA load operations from Global Memory to Shared Memory buffer `sA`
2.  **Transpose Warps** (Warps 0-3, 4 warps, Consumer/Producer): 
    *   Wait for `sA` to be filled by TMA load (consumer of load_mbar)
    *   Transpose data from `sA` → Registers → `sB`
    *   Signal completion to TMA Store warp (producer for store_mbar)
3.  **TMA Store Warp** (Warp 5, Consumer): 
    *   Wait for `sB` to be ready (consumer of store_mbar)
    *   Issue TMA store operations from `sB` to Global Memory

#### Synchronization Barriers

The kernel uses two mbarrier instances for producer-consumer coordination:

1.  **load_mbar_ptr**: Synchronizes TMA Load → Transpose Warps
    *   Producer: TMA Load Warp (arrives after TMA completes)
    *   Consumer: Transpose Warps (wait before reading `sA`)
    *   Expected arrivals: 1 (from TMA load warp)
    *   Expected transactions: `tile_m × tile_n × element_size` bytes

2.  **store_mbar_ptr**: Synchronizes Transpose Warps → TMA Store
    *   Producer: Transpose Warps (each warp arrives after writing to `sB`)
    *   Consumer: TMA Store Warp (waits before issuing TMA store)
    *   Expected arrivals: 4 (one from each transpose warp)

#### Execution Flow

1.  **Initialization**:
    *   All warps participate in barrier initialization (thread 0 initializes)
    *   Allocate two shared memory buffers: `sA` (row-major) and `sB` (column-major)
    *   Create TMA descriptors for source and transposed destination
    *   Initialize `load_mbar` with expected count of 1 and transaction bytes
    *   Initialize `store_mbar` with expected count of 4 (number of transpose warps)

2.  **TMA Load Warp** (Producer for Load Pipeline):
    ```
    partition source tensor by tile shape
    issue TMA load: Global[block_tile] → sA
    arrive on load_mbar to signal completion
    ```

3.  **Transpose Warps** (Consumer for Load, Producer for Store):
    ```
    wait on load_mbar for TMA load to complete
    
    partition sA for reading (each thread handles subset)
    copy data: sA → Registers
    partition sB for writing
    copy data: Registers → sB (transpose happens via layout)
    
    fence to ensure smem writes are visible
    synchronize with trans_sync_barrier
    [elect one thread] arrive on store_mbar to signal completion
    ```

4.  **TMA Store Warp** (Consumer for Store Pipeline):
    ```
    wait on store_mbar for transpose to complete
    partition destination tensor by tile shape
    issue TMA store: sB → Global[block_tile]
    ```

### Key Features

*   **Simple Producer-Consumer Model**: Clear separation of concerns with dedicated warps
*   **Efficient Synchronization**: Hardware mbarriers minimize synchronization overhead
*   **Memory Layout Optimization**: Swizzled layouts prevent bank conflicts
*   **Transposition via Layouts**: Transpose is achieved through different memory layouts for `sA` and `sB`

### Configuration Parameters

*   `tile_shape`: Fixed at (128, 128) - Tile dimensions (M, N)
*   `cluster_shape_mn`: Fixed at (1, 1) - Single CTA execution
*   Warp count: 6 warps (1 TMA Load + 4 Transpose + 1 TMA Store)

### Usage

Run the transpose kernel with custom matrix dimensions:

```bash
# Basic usage (128×128 matrix)
python tma_v1.py

# Custom dimensions
python tma_v1.py --M 1024 --N 2048

# With custom benchmark iterations
python tma_v1.py --M 4096 --N 4096 --num_warmup 10 --num_iters 50
```

#### Example Code

```python
from tma_v1 import run_transpose

# Run transpose on 1024×2048 matrix
run_transpose(M=1024, N=2048)
# Output: Performance metrics and verification result
```

### Performance Considerations

*   **Single-stage pipeline**: Simpler than multi-stage but with potential for idle warps
*   **Warp specialization**: Clear roles minimize synchronization complexity
*   **Good for learning**: Demonstrates fundamental TMA and mbarrier concepts

## TMA V2: Transpose with Multi-Stage Pipeline

This example demonstrates a TMA implementation with multi-stage pipelining for efficient matrix transpose operations on NVIDIA Blackwell (SM100) architecture.

### Key Concepts

*   **Multi-Stage Pipeline**: Multiple buffers enable overlapping TMA loads, computation (transpose), and TMA stores to hide memory latency
*   **Pipeline Abstractions**: `PipelineTmaAsync` and `PipelineTmaStore` provide producer-consumer synchronization
*   **Persistent Tile Scheduler**: Efficient work distribution across CTAs for dynamic load balancing
*   **Shared Memory Swizzle**: Optimized shared memory layouts to avoid bank conflicts
*   **Warp Specialization**: Different warps handle loading and transposing; first transpose warp also handles storing

### Kernel Architecture

The `Sm100MatrixTransposeKernelV2` performs a tiled matrix transpose (M×N → N×M) with the following design:

#### Warp Roles

1.  **TMA Load Warp** (Producer): Loads tiles from Global Memory to Shared Memory buffer `sA` using TMA load operations
2.  **Transpose Warps** (4 warps, Consumer/Producer): 
    *   Wait for data in `sA` from load pipeline
    *   Transpose data from `sA` → Registers → `sB`
    *   Synchronize via named barrier to ensure all transpose warps complete
    *   First transpose warp (`trans_warp_id[0]`) issues TMA store operations from `sB` to Global Memory

#### Pipeline Stages

The kernel uses two separate pipelines for maximum parallelism:

1.  **Load Pipeline**: `TMA Load Warp` (producer) → `Transpose Warps` (consumer)
    *   Multi-stage buffer `sA` (automatically computed based on available SMEM)
    *   Enables prefetching multiple tiles while processing current tile
2.  **Store Pipeline**: `Transpose Warps` (producer) → `First Transpose Warp` (consumer, issues TMA store)
    *   Multi-stage buffer `sB` (automatically computed based on available SMEM)
    *   First transpose warp handles TMA store after all transpose warps finish writing to `sB`

#### Stage Calculation

The kernel automatically computes the optimal number of pipeline stages using `_compute_stages()`:

*   Calculates bytes needed per stage for `sA` (tile_m × tile_n) and `sB` (tile_m × tile_n)
*   Reserves space for pipeline barriers and metadata (~1KB)
*   Divides remaining shared memory by bytes per stage
*   Clamps to 2-8 stages (2 for double buffering minimum, 8 for diminishing returns)

#### Execution Flow

1.  **Initialization**:
    *   Allocate multi-stage shared memory buffers (`sA_staged`, `sB_staged`)
    *   Create TMA descriptors for source and transposed destination
    *   Initialize load and store pipelines with barrier synchronization
    *   Use persistent tile scheduler to distribute work tiles across CTAs

2.  **TMA Load Warp** (Producer for Load Pipeline):
    ```
    for each tile assigned by scheduler:
        acquire next available stage in load pipeline
        issue TMA load: Global[tile] → sA[stage]
        advance to next stage
    ```

3.  **Transpose Warps** (Consumer for Load, Producer for Store):
    ```
    for each tile assigned by scheduler:
        wait for load pipeline to fill current stage
        copy data: sA[load_stage] → Registers
        release load pipeline stage
        
        transpose and write: Registers → sB[store_stage]
        fence to ensure smem writes are visible
        synchronize all transpose warps with barrier
        
        [first transpose warp only] issue TMA store: sB[stage] → Global[tile]
        [first transpose warp only] commit to store pipeline
        [first transpose warp only] acquire next store pipeline stage
        synchronize all transpose warps with barrier
    ```

4.  **Pipeline Teardown**:
    *   Producer/consumer tail operations ensure all in-flight operations complete

### Key Features

*   **Automatic Stage Optimization**: Kernel calculates optimal number of stages based on tile size, data type, and available shared memory
*   **Persistent Tile Scheduler**: Efficient work distribution across CTAs for dynamic load balancing
*   **Memory Layout Optimization**: Uses appropriate swizzling for row-major input and column-major transposed output
*   **Efficient Synchronization**: Named barriers for intra-CTA coordination, mbarriers for pipeline stages

### Configuration Parameters

*   `tile_shape`: Fixed at (128, 128) - Tile dimensions (M, N)
*   `cluster_shape_mn`: Fixed at (1, 1) - Single CTA execution
*   Number of pipeline stages: Automatically computed based on available SMEM

### Usage

Run the transpose kernel with custom matrix dimensions:

```bash
# Basic usage (128×128 matrix)
python tma_v2.py

# Custom dimensions
python tma_v2.py --M 1024 --N 2048

python tma_v2.py --M 1024 --N 2048 --num_warmup 10 --num_iters 50
```

#### Example Code

```python
from tma_v2 import run_transpose

# Run transpose on 1024×2048 matrix
run_transpose(M=1024, N=2048)
# Output: "TransposeSuccess!" if verification passes
```

### Performance Considerations

*   **Multi-stage pipelining** hides memory latency by overlapping loads, computation, and stores
*   **Persistent scheduling** provides better load balancing for irregular matrix sizes
*   **Warp specialization** maximizes throughput: TMA load warp handles all loads, transpose warps handle computation, and first transpose warp handles stores

## TMA V3: TMA With MMA (Tensor Cores)

TBD
