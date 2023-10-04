# TMA tensors

TMA tensors have three differences from
"ordinary" global memory tensors.

1. The tensor's iterator stores a base coordinate,
   not a pointer.

2. The tensor's actual global memory pointer
   does not live in the tensor.
   Instead, it lives in a TMA descriptor,
   which is stored in the TMA `Copy_Traits` specialization.

3. The tensor's strides aren't just integers.
   Instead, they are linear combinations of "basis functions."

The following sections will elaborate these differences.

## Iterator stores a base coordinate, not a pointer

"Ordinary" tensors of global memory have an iterator type
(the "Engine" template parameter) that wraps a pointer.
For example, `gmem_ptr<T>` wraps a `T*`.
A TMA tensor's iterator type is `ArithmeticTupleIterator`.
`ArithmeticTupleIterator` stores a coordinate
(a tuple of integers) instead of a pointer.
The coordinate is represented as an `ArithmeticTuple`,
which is just a (public subclass of) `cute::tuple`
that has an overloaded `operator+`.
The sum of two tuples is the tuple of the sum of the elements.

When we perform the TMA load or store,
the iterator's coordinate goes into the PTX instruction.
(For TMA specializations of `Copy_Traits`,
this happens in the `private` member function `copy_unpack_`.)
The coordinate represents the tensor's "base coordinate."
For tiled TMA, the base coordinate of the whole tensor
might start out as (0, 0, ..., 0).  However, slicing the tensor
might result in a different base coordinate.
For im2col TMA load, the base coordinate is the lower corner.

## Pointer lives in TMA descriptor, not tensor

The TMA descriptor has the actual pointer to global memory in it.
Storing the TMA descriptor in the tensor would make tensors
expensive to copy and slice, as the TMA descriptor is 128 bytes.
Instead, we store the TMA descriptor
in the `Copy_Traits` specialization.

## Tensor's strides aren't just integers

For "ordinary" tensors, the layout takes a coordinate
`(i, j)` as input, and returns a single integer offset `k`.
The resulting pointer-to-element
is the base pointer, plus the offset k.
However, TMA loads and stores don't take a pointer.
They take a TMA descriptor, and a coordinate `(i, j)`.
Building the strides out of "basis functions"
is the trick to make the layout return a coordinate --
a tuple of integers -- instead of just a single integer offset.
A "basis function" for strides
is a lot like a basis function for Euclidean space,
except that strides' basis functions can be hierarchical.

Layouts work by taking the inner product
of their input coordinate with the strides.
For "ordinary" integer strides, e.g., `(1, 100)`,
the inner product of the input coordinate `(i, j)`
and the strides is `i + 100j`.
That gives the formula for the offset.
For strides built of basis functions, for example,
if the strides are `(_1@0, _1@1)`,
then the inner product of the input coordinate `(i, j)`
with the strides is `i@0 + j@1`.
The `i` here is a coefficient of the basis function `@0`,
and `j` is a coefficient of the basis function `@1`.
The result is a vector sum.  We _interpret_ this result as
"the zeroth coefficient is i, and the first coefficient is j."
That translates into the (TMA) coordinate `(i, j)`.
If we wanted to reverse the coordinates,
then we could use `(_1@1, _1@0)` as the strides.
Evaluating the layout would give `i@1 + j@0`,
that is, `(j, i)`.
