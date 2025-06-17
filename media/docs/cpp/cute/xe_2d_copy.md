# 2D Copy Operations for Intel XE Architecture

## Overview

This document describes the **2D copy operations** introduced in CUTLASS for the **Intel XE architecture**.
These operations are designed to efficiently load and store 2D blocks of data between
**global memory** and **registers**. 

## Related links

* [ Intel SPIR-V extension for 2D Block load ][spirv-format]
* [ VNNI format ][vnni-format-link]

[spirv-format]: https://github.khronos.org/SPIRV-Registry/extensions/INTEL/SPV_INTEL_2d_block_io.html
[vnni-format-link]: https://github.com/intel/llvm/blob/sycl/sycl/doc/extensions/experimental/sycl_ext_matrix/sycl_ext_intel_matrix.asciidoc#packed-layout-format

---

## Copy Operation Naming Convention

Each 2D copy operation follows this naming pattern:

```c++
XE_2D_[Packed_]<DataType>x<Rows>x<Cols>_<LD|ST>_<N|T|V>
```

Where: 

| Component            | Description                                                               |
|----------------------|---------------------------------------------------------------------------|
| `XE_2D`              | Indicates 2D copy for Intel XE                                            |
| `Packed_` (optional) | Indicates packed copy (only for `U8` and `U4` MMA operations)             |
| `<DataType>`         | Data type to load/store into registers: `U4`, `U8`, `U16`, `U32`          |
| `<BlockHeight>x<BlockWidth>`      | Dimensions of the 2D block in elements                                    |
| `LD` / `ST`          | `LD` = Load from global memory; `ST` = Store to global memory             |
| `N`, `T`, `V`        | Memory layout: `N` (row-major), `T` (column-major), `V` ([VNNI][vnni-format-link], row-major) |

Note: DataType does not represent the actual type of the data being loaded, but rather the width of the data type.
For example, when loading an array of FP8 values a U8 copy operation should be used. 

---

## 2D Copy Execution Model

All copy operations are performed at the **subgroup** level. Each **subgroup consists of 16 work-items**, 
and these **work-items** cooperate to move a 2D block of data.

### Data Distribution (Unpacked Copies)

For a load like `XE_2D_U16x32x16_LD_N`, the 32 rows by 16 columns block of elements is split such that:

- Each **work-item gets one column** with **32 elements**

#### Example:
| Work-item | Columns Loaded |
|-----------|----------------|
| 0         | Column 0       |
| 1         | Column 1       |
| ...       | ...            |
| 15        | Column 15      |

If we increase BlockWidth, for example using a `XE_2D_U16x32x32_LD_N` copy,
it will load a 32 rows by 32 columns block of elements such that:

- Each **work-item gets two columns**, each with **32 elements**
- The columns are **16 apart**

#### Example:
| Work-item | Columns Loaded          |
|-----------|-------------------------|
| 0         | Column 0 and Column 16  |
| 1         | Column 1 and Column 17  |
| ...       | ...                     |
| 15        | Column 15 and Column 31 |

The same applies to the LD_V and LD_T operations.

> ⚠️ VNNI combines elements from multiple rows of a single column, packing them into 32-bit values.
It does not transform or modify the actual data, it only changes the storage format. 

### Data Distribution (Packed Copies)

When using MMA operations with **U8** or **U4** data types, such as `XE_8x16x32_S32S8S8S32_TT`, 
the data for the A matrix must be packed (packed here meaning each workitem having data for 
multiple consecutive columns) before being consumed by the MMA instructions. In these cases, 
a packed load operation must be used.

```c++
XE_2D_Packed_<DataType>x<BlockHeight>x<BlockWidth>_<LD|ST>_<N|T>
```
Example for `XE_2D_Packed_U8x8x32_LD_N` which loads a 8 rows by 32 columns block of elements, 
each **work-item gets two adjacent columns**, each containing **8 elements**

| Work-item | Columns Loaded |
|-----------|----------------|
| 0         | Column 0, 1    |
| 1         | Column 2, 3    |
| 2         | Column 4, 5    |
| ...       | ...            |
| 15        | Column 30, 31  |

If we increase BlockWidth, for example using a `XE_2D_Packed_U8x8x64_LD_N` copy,
it will load an 8 rows by 32 columns block of elements such that:

- Each **work-item gets two groups of two adjacent columns**, each column with **8 elements**
- The group of two columns are **32 apart**

#### Example:
| Work-item | Columns Loaded                  |
|-----------|---------------------------------|
| 0         | Column 0, 1 and Column 32, 33   |
| 1         | Column 2, 3 and Column 34, 35   |
| ...       | ...                             |
| 15        | Column 30, 31 and Column 62, 63 |

---

## Supported Layout Modes

The following table summarizes the available copy variants:

| Operation  | Description                    | Matrix | Layout       | 
|------------|--------------------------------|--------|--------------|
| `LD_N`     | Load, Row-major                | A      | Row-major    |
| `LD_T`     | Load, Column-major (Transpose) | A/B    | Column-major |
| `LD_V`     | Load, VNNI layout, Row-major   | B      | Row-major    |
| `ST_N`     | Store, Row-major               | D      | Row-major    |

The `LD_V` operation is not available for the `U32` data type. Use `LD_N` instead. 

---

## Integration into GEMM Workloads

### Loading A Matrix:
- Use `LD_N` (if row-major)
- Use `LD_T` (if column-major)
- For `U8` or `U4` MMAs: use `Packed_U8` / `Packed_U4` copies

### Loading B Matrix:
- Use `LD_V` (if row-major)
- Use `LD_T` (if column-major)
- Use `LD_N` (if row-major and U32 data type)

### Storing Result Matrix:
- Use `ST_N` (row-major only)

