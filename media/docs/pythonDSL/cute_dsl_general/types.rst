.. _types:
.. |DSL| replace:: CuTe DSL

Types
=====

Overview
--------

|DSL| provides a set of core types that form the foundation of tensor layout algebra and GPU programming. These types enable precise control over memory layout, data representation, and tensor operations. This document covers the key types available in ``cutlass.cute.core``.


Core Numeric Types
------------------

IntValue
~~~~~~~~

``IntValue`` is an internal representation of constrained integer types with divisibility information. It serves as a proxy for constrained integer types in the CuTe IR, automatically tracking divisibility constraints that are crucial for layout operations.

**Key Features:**

- Inherits from ``ArithValue`` with extensions for divisibility tracking
- Automatically emits ``cute.get_scalars`` operations in the IR
- Supports arithmetic operations that propagate divisibility information
- Used internally for type-safe integer operations in layout algebra

**API Methods:**

- ``get_typed_value()`` - Returns the value as an IntTupleType
- ``get_divisibility()`` - Returns the divisibility constraint of the value
- ``divisibility`` - Property that returns the divisibility constraint

**Supported Operations:**

The ``IntValue`` type supports standard arithmetic operations with divisibility tracking:

.. code-block:: python

    # Addition, subtraction, multiplication, division, and modulo
    result = int_val1 + int_val2
    result = int_val1 - int_val2
    result = int_val1 * int_val2
    result = int_val1 // int_val2
    result = int_val1 % int_val2

**String Representation:**

.. code-block:: python

    # IntValue with divisibility 1
    str(int_val)  # Returns "?"

    # IntValue with divisibility 4
    str(int_val)  # Returns "?{div=4}"


Ratio
~~~~~

``Ratio`` represents a rational number as a ratio of two integers. It is used in CuTe to represent exact fractional values that arise in tensor layout operations, particularly in composition operations where divisibility conditions may not be satisfied.

**Constructor:**

.. code-block:: python

    ratio = cute.Ratio(numerator, denominator)

:param numerator: The numerator of the ratio
:type numerator: int
:param denominator: The denominator of the ratio
:type denominator: int
:raises TypeError: If numerator or denominator are not integers

**Methods:**

- ``is_integral()`` - Returns ``True`` if the ratio represents an integer value (numerator divisible by denominator)
- ``reduced()`` - Returns a new Ratio with numerator and denominator reduced to lowest terms
- ``to(dtype)`` - Converts the ratio to another type (Ratio, float, or int)

**Arithmetic Operations:**

.. code-block:: python

    # Multiplication with another ratio
    ratio1 = cute.Ratio(1, 2)
    ratio2 = cute.Ratio(3, 4)
    result = ratio1 * ratio2  # Returns Ratio(3, 8)

    # Multiplication with integer
    ratio = cute.Ratio(2, 3)
    result = ratio * 5  # Returns Ratio(10, 3)
    result = 5 * ratio  # Returns Ratio(10, 3)

**Type Conversion:**

.. code-block:: python

    ratio = cute.Ratio(3, 2)

    # Convert to float
    float_val = ratio.to(float)  # Returns 1.5

    # Convert to int (floor division)
    int_val = ratio.to(int)  # Returns 1


Layout Algebra Types
--------------------

ScaledBasis
~~~~~~~~~~~

``ScaledBasis`` represents a scaled basis element in CuTe's layout algebra. It consists of a scale value and a mode that identifies which basis element in the layout algebra is being referenced. ScaledBasis elements are fundamental to CuTe's coordinate system representation.

**Constructor:**

.. code-block:: python

    sb = cute.ScaledBasis(value, mode)

:param value: The scale value
:type value: Union[int, Integer, Ratio, ir.Value]
:param mode: The mode identifying the basis element
:type mode: Union[int, List[int]]
:raises TypeError: If mode is not an integer or list of integers

**Examples:**

.. code-block:: python

    # Create a scaled basis with integer scale and mode
    sb1 = cute.ScaledBasis(2, 0)  # 2 * E(0)

    # Create a scaled basis with a Ratio scale
    sb2 = cute.ScaledBasis(cute.Ratio(1, 2), 1)  # (1/2) * E(1)

    # Create a scaled basis with a list of modes
    sb3 = cute.ScaledBasis(4, [0, 1])  # 4 * E([0, 1])

    # Scaled basis elements are commonly used in layout strides
    layout = cute.make_layout((4, 8), stride=(cute.ScaledBasis(2, 0), cute.ScaledBasis(1, 1)))

    # This creates a layout with strides (2@0, 1@1) representing
    # a coordinate system where each dimension has its own basis

    # Example: Mapping coordinates to indices using the layout
    coord = (2, 3)
    idx = cute.crd2idx(coord, layout)  # Maps (2, 3) to (4, 3)

**Properties:**

- ``value`` - Get the scale value
- ``mode`` - Get the mode as a list of integers
- ``is_static()`` - Returns ``True`` if the value is statically known

**Methods:**

- ``to(dtype)`` - Convert to another type (ScaledBasis or internal _ScaledBasis)

**Operations:**

.. code-block:: python

    # Right multiplication by a scale factor
    sb = cute.ScaledBasis(2, 0)
    result = 3 * sb  # Creates ScaledBasis(6, 0)

**Utility Function:**

.. code-block:: python

    # Create a basis element with unit scale
    basis = cute.E(mode)  # Equivalent to ScaledBasis(1, mode)


Swizzle
~~~~~~~

``Swizzle`` is a transformation that permutes the elements of a layout. Swizzles are used to rearrange data elements to improve memory access patterns and computational efficiency, particularly for avoiding bank conflicts in shared memory.

**Swizzle Parameters:**

A swizzle is defined by three parameters:

- **MBase**: The number of least-significant bits to keep constant
- **BBits**: The number of bits in the mask
- **SShift**: The distance to shift the mask

**Bit Pattern:**

.. code-block:: text

    0bxxxxxxxxxxxxxxxYYYxxxxxxxZZZxxxx
                                  ^--^ MBase (least-sig bits kept constant)
                     ^-^       ^-^     BBits (number of bits in mask)
                       ^---------^     SShift (distance to shift YYY)
                                          (positive: right, negative: left)

    Given:    0bxxxxxxxxxxxxxxxxYYxxxxxxxxxZZxxx
    Result:   0bxxxxxxxxxxxxxxxxYYxxxxxxxxxAAxxx
              where AA = ZZ xor YY

**Usage:**

Swizzles are typically created using CuTe's swizzle factory functions and composed with layouts to create optimized memory access patterns.


Layout
~~~~~~

``Layout`` is CuTe's core abstraction for representing tensor layouts. A Layout maps from a logical coordinate space to an index space, defined by a pair of (Shape, Stride). Layouts present a common interface to multidimensional array access that abstracts away the details of how array elements are organized in memory.

**Key Concepts:**

- **Shape**: Defines the abstract dimensions of the Layout
- **Stride**: Defines how coordinates within the Shape map to linear indices
- **Hierarchical Structure**: CuTe layouts are inherently hierarchical, constructed from smaller nested layouts

**Properties:**

- ``shape`` - An IntTuple representing the dimensions of the layout
- ``stride`` - An IntTuple representing the strides of the layout
- ``max_alignment`` - The maximum alignment of the layout in bytes

**Examples:**

.. code-block:: python

    # Creating a layout with shape (4,8) and default stride (column major)
    layout = cute.make_layout((4, 8))

    # Creating a layout with explicit shape and stride (row major)
    layout = cute.make_layout((4, 8), stride=(8, 1))

    # Accessing layout properties
    shape = layout.shape      # Returns (4, 8)
    stride = layout.stride    # Returns (8, 1)

    # Mapping a coordinate to an index: (2, 3) -> 2 * 8 + 3 * 1 = 19
    idx = cute.crd2idx((2, 3), layout)

**Layout Operations:**

Layouts support a rich algebra of operations:

- **Concatenation**: Combining layouts along dimensions
- **Coalescence**: Merging adjacent modes
- **Composition**: Composing layouts with functions or other layouts
- **Complement**: Computing the complement space
- **Inversion**: Inverting the layout mapping

**String Representation:**

.. code-block:: python

    layout = cute.make_layout((4, 8), stride=(1, 4))
    print(layout)  # Prints "shape:stride" format, e.g., "(4,8):(1,4)"


ComposedLayout
~~~~~~~~~~~~~~

``ComposedLayout`` represents a composition of layouts and transformations. It is a generalization of normal layouts that can support arbitrary function mappings from coordinate to coordinate as an inner layout.

**Structure:**

A ComposedLayout consists of three components:

- **inner**: The inner transformation (Swizzle or Layout)
- **offset**: An offset applied to coordinates
- **outer**: The outer layout

**Properties:**

- ``inner`` - Returns the inner transformation (Union[Swizzle, Layout])
- ``offset`` - Returns the offset as an IntTuple
- ``outer`` - Returns the outer layout
- ``shape`` - Returns the shape of the composed layout
- ``max_alignment`` - Returns the maximum alignment
- ``is_normal`` - Returns ``True`` if this is a normal layout (not a general composition)

**Examples:**

.. code-block:: python

    # ComposedLayouts are typically created through composition operations
    # For example, composing a layout with a swizzle
    layout = cute.make_layout((8, 8))
    swizzle = cute.make_swizzle(...)
    composed = cute.composition(swizzle, layout)

    # Accessing components
    inner = composed.inner      # Returns the swizzle
    outer = composed.outer      # Returns the layout
    offset = composed.offset    # Returns the offset

**String Representation:**

.. code-block:: python

    print(composed)  # Prints "inner o offset o outer" format


Memory and Pointer Types
-------------------------

Pointer
~~~~~~~

``Pointer`` represents a memory address with specific properties. Pointers are a fundamental type of iterator/engine that support random-access operations. They can be offset by elements of a layout's codomain and dereferenced to produce values.

**Properties:**

- ``dtype`` - The type of value this pointer points to
- ``type`` - The MLIR type of the pointer
- ``memspace`` - The memory space where the pointer data resides (e.g., ``gmem``, ``smem``, ``rmem``)
- ``alignment`` - The alignment of the pointer in bytes
- ``max_alignment`` - The maximum alignment of the pointer in bytes

**Operations:**

.. code-block:: python

    # Pointer arithmetic
    ptr2 = ptr + offset     # Offset pointer forward
    ptr3 = offset + ptr     # Offset pointer forward (commutative)
    ptr4 = ptr - offset     # Offset pointer backward

    # Convert pointer to integer
    int_addr = ptr.toint()

    # Align pointer to specified byte boundary
    aligned_ptr = ptr.align(16)  # Align to 16-byte boundary

**Tensor Composition:**

When composed with a layout, a pointer forms a tensor: ``T = E ∘ L``, where ``E`` is the pointer (engine) and ``L`` is the layout. The tensor evaluates the layout by mapping a coordinate ``c`` to the codomain, offsets the pointer accordingly, and dereferences the result:

.. code-block:: python

    T(c) = (E ∘ L)(c) = *(E + L(c))

**Methods:**

- ``llvm_ptr`` - Get the LLVM pointer representation (low-level use only)
- ``align(min_align)`` - Align pointer to specified byte alignment (must be power of 2)
- ``toint()`` - Convert pointer to integer address (Int64 for gmem/generic, Int32 otherwise)

**Examples:**

.. code-block:: python

    # Create a pointer from a tensor's data
    ptr = tensor.data()

    # Offset the pointer
    offset_ptr = ptr + 16

    # Check pointer properties
    print(f"Memory space: {ptr.memspace}")
    print(f"Alignment: {ptr.alignment}")
    print(f"Data type: {ptr.dtype}")


Structured Data Types
---------------------

struct
~~~~~~

The ``struct`` decorator abstracts C structures in Python DSL. It allows you to define structured data types with precise control over layout, alignment, and nesting.

**Supported Elements:**

- Base DSL scalar int/float elements
- Arrays (MemRange)
- Nested structures
- Aligned elements

**Basic Usage:**

.. code-block:: python

    # Define a simple struct
    @cute.struct
    class complex:
        real : cutlass.Float32
        imag : cutlass.Float32

    # Define a struct with arrays and nested structures
    @cute.struct
    class StorageA:
        mbarA : cute.struct.MemRange[cutlass.Int64, stage]
        compA : complex
        intA : cutlass.Int16

**Alignment Control:**

.. code-block:: python

    # Define a struct with explicit alignment
    @cute.struct
    class StorageB:
        a: cute.struct.Align[
            cute.struct.MemRange[cutlass.Float32, size_a], 1024
        ]
        b: cute.struct.Align[
            cute.struct.MemRange[cutlass.Float32, size_b], 1024
        ]
        x: cute.struct.Align[cutlass.Int32, 16]
        compA: cute.struct.Align[complex, 16]

**Static Queries:**

.. code-block:: python

    # Get size and alignment at compile time
    size = StorageB.__sizeof__()
    align = StorageB.__alignof__()

**Allocation and Access:**

.. code-block:: python

    # Allocate and reference elements
    storage = allocator.allocate(StorageB)

    # Access struct members
    storage.a[0] = ...
    storage.x = ...
    storage.compA.real = ...

**Methods:**

- ``__sizeof__()`` - Returns the size of the struct in bytes
- ``__alignof__()`` - Returns the alignment of the struct in bytes
- ``size_in_bytes()`` - Returns the size of the struct in bytes


struct.MemRange
^^^^^^^^^^^^^^^

``MemRange`` defines a contiguous range of memory with a specific element type and size.

**Syntax:**

.. code-block:: python

    cute.struct.MemRange[dtype, size]

:param dtype: The data type (must be a DSL scalar type)
:type dtype: Type[Numeric]
:param size: The number of elements in the range
:type size: int

**Properties:**

- ``size`` - Number of elements in the range
- ``elem_width`` - Width of each element in bits
- ``size_in_bytes`` - Total size in bytes

**Methods:**

- ``data_ptr()`` - Returns a pointer to the start of the memory range
- ``get_tensor(layout, swizzle=None, dtype=None)`` - Creates a tensor from the memory range
- ``__getitem__(index)`` - Returns the element at the specified index

**Examples:**

.. code-block:: python

    @cute.struct
    class Buffer:
        data : cute.struct.MemRange[cutlass.Float32, 128]

    # Allocate buffer
    buf = allocator.allocate(Buffer)

    # Get pointer to data
    ptr = buf.data.data_ptr()

    # Access individual elements
    element_ptr = buf.data[5]

    # Create tensor from memory range
    layout = cute.make_layout((8, 16))
    tensor = buf.data.get_tensor(layout)


struct.Align
^^^^^^^^^^^^

``Align`` specifies explicit alignment requirements for struct members.

**Syntax:**

.. code-block:: python

    cute.struct.Align[dtype, alignment]

:param dtype: The type to align (scalar, MemRange, or struct)
:type dtype: Type
:param alignment: The alignment in bytes (must be > 0)
:type alignment: int

**Properties:**

- ``dtype`` - The data type being aligned
- ``align`` - The alignment value

**Examples:**

.. code-block:: python

    @cute.struct
    class AlignedStorage:
        # Align scalar to 16 bytes
        counter: cute.struct.Align[cutlass.Int32, 16]

        # Align array to 1024 bytes
        buffer: cute.struct.Align[
            cute.struct.MemRange[cutlass.Float32, 256], 1024
        ]


union
~~~~~

The ``union`` decorator abstracts C unions in Python DSL. Similar to ``struct``, but all members start at offset 0, and the size is the maximum size of all members.

**Layout Characteristics:**

- All objects start at offset 0
- Alignment is the maximum alignment of all objects
- Size is the maximum size of all objects

**Usage:**

.. code-block:: python

    # Define a union with scalar elements
    @cute.union
    class value_union:
        as_int : cutlass.Int32
        as_float : cutlass.Float32

    # Allocate union
    val = allocator.allocate(value_union)

    # Access different interpretations of same memory
    val.as_int = 42
    float_val = val.as_float  # Interpret same bits as float

**Methods:**

Same as ``struct``:

- ``__sizeof__()`` - Returns the size of the union in bytes
- ``__alignof__()`` - Returns the alignment of the union in bytes


Deprecated Types
----------------

ThrMma
~~~~~~

.. deprecated::
    ``cute.core.ThrMma`` is deprecated, use ``cute.ThrMma`` instead

ThrCopy
~~~~~~~

.. deprecated::
    ``cute.core.ThrCopy`` is deprecated, use ``cute.ThrCopy`` instead


Type Hierarchies and Relationships
-----------------------------------

**Type Protocol Support:**

Many CuTe types implement standard Python protocols for integration:

- ``__str__()`` - String representation for debugging
- ``__eq__()`` / ``__ne__()`` - Equality comparison
- ``__getitem__()`` - Indexing operations
- ``__add__()`` / ``__sub__()`` / ``__mul__()`` / ``__floordiv__()`` / ``__mod__()`` - Arithmetic

**MLIR Integration:**

Internal types like ``IntValue``, ``Layout``, ``Pointer``, and ``ComposedLayout`` are registered as MLIR value casters, enabling seamless integration with the underlying compiler infrastructure.


Best Practices
--------------

**Choosing Between Static and Dynamic:**

- Use static values (Python ``int``) when dimensions are known at compile time for maximum optimization
- Use dynamic values (``IntValue``) when dimensions must be determined at runtime
- Refer to :doc:`dsl_dynamic_layout` for detailed guidance on static vs dynamic layouts

**Memory Alignment:**

- Always specify alignment requirements for shared memory structures to avoid bank conflicts
- Use ``struct.Align`` to enforce alignment constraints
- Check ``max_alignment`` properties to verify pointer and layout alignment

**Layout Operations:**

- Prefer built-in layout operations (``make_layout``, ``composition``, etc.) over manual construction
- Use ``ScaledBasis`` for explicit control over stride modes in multi-modal layouts
- Leverage ``ComposedLayout`` for complex transformations like swizzling

**Type Safety:**

- Use type annotations in ``@jit`` and ``@kernel`` functions
- Let the DSL infer types when possible for cleaner code
- Check ``dtype`` and ``memspace`` properties when working with pointers


See Also
--------

- :doc:`dsl_introduction` - Introduction to CuTe DSL decorators and calling conventions
- :doc:`dsl_control_flow` - Control flow with static and dynamic values
- :doc:`dsl_dynamic_layout` - Working with static and dynamic layouts
- :doc:`framework_integration` - Integration with deep learning frameworks
- :doc:`debugging` - Debugging techniques for CuTe DSL programs
