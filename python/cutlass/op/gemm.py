#################################################################################################
#
# Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################

"""
    Ease-of-use interface for constructing, compiling, and running GEMMs.

    The ``Gemm`` interface is meant to allow one to easily instantiate, compile, and run
    GEMM operations in CUTLASS via Python, without specifying many configuration parameters.
    Under the hood, the interface will select sensible default parameters for the many template
    parameters for CUTLASS GEMMs.

    Note: optimal performance is not to be expected from this interface. To achieve optimal
    performance, one should specify and tune each configuration parameter.

    The simplest example of using this interface is the following:

    .. highlight:: python
    .. code-block:: python

        # A, B, C, and D are torch/numpy/cupy tensor objects
        plan = cutlass.op.Gemm(A, B, C, D)
        plan.run()


    One can also use the interface by specifying data types of operands at construction
    and using different tensor objects with these data types at runtime:

    .. highlight:: python
    .. code-block:: python

        # The following is shorthand for:
        #        cutlass.op.Gemm(element_A=torch.float32, element_B=torch.float32,
        #                        element_C=torch.float32, element_D=torch.float32,
        #                        element_accumulator=torch.float32,
        #                        layout=cutlass.LayoutType.RowMajor)
        plan = cutlass.op.Gemm(element=torch.float32, layout=cutlass.LayoutType.RowMajor)

        A0 = torch.rand((128, 256), device='cuda')
        B0 = torch.rand((256, 64), device='cuda')
        C0 = torch.zeros((128, 64), device='cuda')
        D0 = torch.zeros((128, 64), device.'cuda')
        plan.run(A0, B0, C0, D0)

        A = torch.rand((32, 128), device='cuda')
        B = torch.rand((128, 256), device='cuda')
        C = torch.zeros((32, 256), device='cuda')
        D = torch.zeros((32, 256), device.'cuda')
        plan.run(A1, B1, C1, D1)

    The interface additionally enables one to decouple the compilation of the underlying CUTLASS
    kernel from its execution:

    .. highlight:: python
    .. code-block:: python

        plan = cutlass.op.Gemm(element=np.float32, layout=cutlass.LayoutType.RowMajor)
        plan.compile()

        # Do other work...

        plan.run(A0, B0, C0, D0)

        # Do other work...

        plan.run(A1, B1, C1, D1)

    Elementwise activation functions are easily fused to the GEMM via the interface:

    .. highlight:: python
    .. code-block:: python

        plan = cutlass.op.Gemm(element=np.float32, layout=cutlass.LayoutType.RowMajor)
        plan.activation = cutlass.epilogue.relu

    Operations can also be run asynchronously:

    .. highlight:: python
    .. code-block:: python

        plan = cutlass.op.Gemm(element=np.float32, layout=cutlass.LayoutType.RowMajor)
        args = plan.run()

        # Do other work...

        args.sync()
"""

import cutlass_bindings

import cutlass
from cutlass import epilogue, swizzle
from cutlass.backend import compiler
from cutlass.backend.gemm_operation import GemmArguments, GemmOperationUniversal
from cutlass.backend.library import TensorDescription, TileDescription
from cutlass.op.op import OperationBase
from cutlass.utils import check, datatypes


class Gemm(OperationBase):
    """
    Constructs a ``Gemm`` object.

    The data types and layouts of operands A, B, and C, along with the data type of output D
    and that used for accumulation, are bound to the ``Gemm`` object throughout its lifetime --
    these are not to be changed after a ``Gemm`` has been constructed.

    The constructor has optional parameters for flexibly setting these parameters. The following
    constructors are equivalent:

    .. highlight:: python
    .. code-block:: python

        # Use F32 for A, B, C, D, and accumulation. All operands are row major.

        # Use the generic ``element`` and ``layout`` parameters to concisely set all data types and layouts
        # for operands to the same values.
        Gemm(element=cutlass.DataType.f32, layout=cutlass.LayoutType.RowMajor)

        # Explicitly specify the data types to use for A, B, C, and D. Use the generic ``layout``.
        Gemm(element_A=cutlass.DataType.f32, element_B=cutlass.DataType.f32, element_C=cutlass.DataType.f32,
            element_D=cutlass.DataType.f32, layout=cutlass.LayoutType.RowMajor)

        # Set the data types and elements from existing tensors. Note that one can use different tensors when
        # executing GEMM via the ``run()`` method than passed in here (though those passed in to ``run()`` must
        # have the same data type and layout as those passed in here).
        # A, B, C, and D are row-major torch.Tensor objects of type torch.float32
        Gemm(A=A, B=B, C=C, D=D)

        # Use the generic ``element`` and explicitly specify the layouts to use for A, B, and C (layout of D is
        # the same as that for D, at present)
        Gemm(element=cutlass.DataType.f32, layout_A=cutlass.LayoutType.RowMajor,
            layout_B=cutlass.LayoutType.RowMajor, layout_C=cutlass.LayoutType.RowMajor)

        # Explicitly specify the data type and layout for only some of A, B, C, and D. Unspecified data types
        # and layouts will inherit those passed in via the generic ``element`` and ``layout``
        Gemm(element_A=cutlass.DataType.f32, layout_B=cutlass.LayoutType.RowMajor,
            element=cutlass.DataType.f32, layout=cutlass.LayoutType.RowMajor)

    The order of precedence for the setting of the data type and layout for a given operand/output is as follows:
        1) If the tensor type is specified (e.g., ``A``), use the data type and layout inferred from this tensor
        2) Otherwise, if the data type/layout (e.g., ``element_A``, ``layout_A``) is specified, use those
        3) Otherwise, use the generic values (e.g., ``element``, ``layout``)

    :param cc: compute capability of device for which kernels should be compiled. For example, if running on H100, this should be set to 90
    :type cc: int
    :param kernel_cc: compute capability of kernels to generate. For example, if running on SM90, but desiring to use a CUTLASS 2.x-style Ampere kernel, this should be set to 80
    :type kernel_cc: int
    :param A: tensor representing data type and layout of operand A
    :param B: tensor representing data type and layout of operand B
    :param C: tensor representing data type and layout of operand C
    :param D: tensor representing data type and layout of operand D
    :param alpha: scalar paramter alpha from GEMM computation that scales the product of operands A and B
    :param beta: scalar parameter beta from GEMM operation that scales operand C
    :param element_accumulator: data type to be used in accumulation of the product of operands A and B
    :type element_accumulator: cutlass.DataType
    :param element: generic data type to be used for operands A, B, C, D, as well as the accumulation data type
    :type element: cutlass.DataType
    :param layout: generic layout type to be used for operands A, B, C, and D
    :type layout: cutlass.LayoutType
    :param element_A: data type to be used for operand A
    :type element_A: cutlass.DataType
    :param element_B: data type to be used for operand B
    :type element_B: cutlass.DataType
    :param element_C: data type to be used for operand C
    :type element_C: cutlass.DataType
    :param element_D: data type to be used for operand D
    :type element_D: cutlass.DataType
    :type layout_A: layout of operand A
    :param layout_A: cutlass.LayoutType
    :type layout_B: layout of operand B
    :param layout_B: cutlass.LayoutType
    :type layout_C: layout of operand C
    :param layout_C: cutlass.LayoutType
    :type layout_D: layout of operand D
    :param layout_D: cutlass.LayoutType
    """

    def __init__(
        self, A=None, B=None, C=None, D=None,
        alpha=1.0, beta=0.0, element_accumulator=None,
        element=None, layout=None,
        element_A=None, element_B=None, element_C=None, element_D=None,
        layout_A=None, layout_B=None, layout_C=None,
        cc: int = None, kernel_cc: int = None
    ):
        super().__init__(cc=cc, kernel_cc=kernel_cc)
        self.name = "gemm"
        self.compiled = False

        elements = []
        layouts = []

        # Check that at least one of the following is set for each tensor (illustrated assuming tensor A):
        # ``A``, ``element_A``, ``element`` and ``A``, ``layout_A``, ``layout``
        for elt, lay, tens, name in zip([element_A, element_B, element_C, element_D],
                                        [layout_A, layout_B, layout_C, layout_C],
                                        [A, B, C, D],
                                        ["A", "B", "C", "D"]):
            if elt is not None and tens is not None:
                raise Exception(f'Must not specify both element_{name} and tensor {name}')
            if lay is not None and tens is not None:
                raise Exception(f'Must not specify both layout_{name} and tensor {name}')
            if elt is None and tens is None and element is None:
                raise Exception(f'Must specify one of element_{name}, tensor {name}, or generic element.')
            if lay is None and tens is None and layout is None:
                raise Exception(f'Must specify one of layout_{name}, tensor {name}, or generic layout.')

            elt_to_set = None
            lay_to_set = None
            if tens is not None:
                elt_to_set, lay_to_set = datatypes.get_datatype_and_layout(tens)
            else:
                elt_to_set = elt if elt is not None else element
                lay_to_set = lay if lay is not None else layout

            elements.append(datatypes.library_type(elt_to_set))
            layouts.append(datatypes.library_layout(lay_to_set))

        self._element_a, self._element_b, self._element_c, self._element_d = elements
        self._layout_a, self._layout_b, self._layout_c, self._layout_d = layouts

        if element_accumulator is None:
            self._element_accumulator = self._element_c
        else:
            self._element_accumulator = datatypes.library_type(element_accumulator)

        self.A = A
        self.B = B
        self.C = C
        self.D = D

        self.alpha = alpha
        self.beta = beta

        self.epilogue_functor = None
        self.op_class = None

        self._reset_operations()

        self._swizzling_functor = cutlass.swizzle.IdentitySwizzle1

    def _reset_operations(self, reset_epilogue: bool = True):
        # Set the default op class
        datatype_comb = (self._element_a, self._element_b, self._element_accumulator)
        layout_comb = (self._layout_a, self._layout_b)
        self.possible_op_classes = self.options.supporting_opclasses(
            self._element_a, self._element_b, self._element_accumulator,
            self._layout_a, self._layout_b)

        if cutlass.OpcodeClass.TensorOp in self.possible_op_classes:
            self.opclass = cutlass.OpcodeClass.TensorOp
        elif cutlass.OpcodeClass.Simt in self.possible_op_classes:
            self.opclass = cutlass.OpcodeClass.Simt
        else:
            raise Exception(f'No kernel configuration found for supported data type and layout '
                            f'combination {datatype_comb}x{layout_comb}')

        if reset_epilogue:
            self._reset_epilogue_functor_activation(epilogue.identity)

    def _reset_epilogue_functor_activation(self, activation):
        if self.epilogue_functor is None:
            if self.op_class == cutlass.OpcodeClass.Simt:
                elements_per_access = 1
            else:
                elements_per_access = 128 // cutlass.DataTypeSize[self._element_c]
        else:
            elements_per_access = self.epilogue_functor.epilogue_vector_length

        if not self.specified_kernel_cc:
            if self.current_cc == 90 and activation != epilogue.identity:
                # CUTLASS 3.0 kernels currently only support identity activation. If one requests a non-identity activation,
                # revert to using a CUTLASS 2.x kernel by using SM80-tagged kernels.
                cutlass.logger.warning("Reverting to using SM80-tagged kernel. Opclass may change.")
                self._reset_options(80)
                self._reset_operations(reset_epilogue=False)
            elif (self.cc == 90 and self.current_cc != 90 and activation == epilogue.identity):
                # SM80 fallback kernels are currently used. Since an identity activation is requested,
                # we can switch back to using SM90 kernels.
                self._reset_options(90)
                self._reset_operations(reset_epilogue=False)
        else:
            if self.current_cc == 90 and activation != epilogue.identity:
                raise Exception("Epilogues with elementwise fusion are not currently supported "
                                "in the Python interface for 3.x kernels. To use 2.x kernels "
                                "with fused elementwise epilogues, do not set the `kernel_cc` "
                                "parameter when constructing the Gemm object.")

        self.epilogue_functor = epilogue.get_activation_epilogue(
            activation,
            datatypes.binding_type(self._element_c),
            elements_per_access,
            datatypes.binding_type(self._element_accumulator),
            datatypes.binding_type(self._element_accumulator),
        )

    def _reset_epilogue_functor_alignment(self, alignment):
        if self.epilogue_functor is None or not hasattr(self.epilogue_functor, 'activation_functor'):
            activation = epilogue.identity
        else:
            activation = type(self.epilogue_functor.activation_functor)

        self.epilogue_functor = epilogue.get_activation_epilogue(
            activation,
            datatypes.binding_type(self._element_c),
            alignment,
            datatypes.binding_type(self._element_accumulator),
            datatypes.binding_type(self._element_accumulator),
        )

    @property
    def activation(self):
        """
        Returns the type of the current activation function used
        """
        return type(self.epilogue_functor.activation_functor)

    @activation.setter
    def activation(self, act):
        """
        Sets the type of the activation function to use
        """
        self._reset_epilogue_functor_activation(act)

    @property
    def opclass(self) -> cutlass.OpcodeClass:
        """
        Returns the opcode class currently in use by the GEMM

        :return: opcode class currently in use
        :rtype: cutlass.OpcodeClass
        """
        return self.op_class

    @opclass.setter
    def opclass(self, oc: cutlass.OpcodeClass):
        """
        Sets the opcode class to use in the GEMM. If the opcode class is not supported under
        the given compute capability and element/layout combinations of the GEMM, an exception is raised.
        """
        if oc in self.possible_op_classes:
            self.op_class = oc
        else:
            raise Exception(
                f'Unsupported operation class {oc} for CC {self.cc} and data type combination '
                f'({self._element_a}, {self._element_b}, {self._element_accumulator}) and '
                f'layout combination ({self._layout_a}, {self._layout_b}).')

        # Changing the op class changes the elements per access in the epilogue. Reset this.
        if self.op_class == cutlass.OpcodeClass.Simt:
            elements_per_access = 1
        else:
            elements_per_access = 128 // cutlass.DataTypeSize[self._element_c]

        if self.epilogue_functor is not None:
            self._reset_epilogue_functor_alignment(elements_per_access)

        # Changing the op class also changes the possible operations available. Reset these.
        self.possible_operations = self.options.operations(
            self.op_class, self._element_a, self._element_b,
            self._element_accumulator, self._layout_a, self._layout_b)

    @property
    def swizzling_functor(self):
        """
        Returns the type of the swizzling functor currently being used by the GEMM

        :return: swizzing functor type
        """
        return self._swizzling_functor

    @swizzling_functor.setter
    def swizzling_functor(self, swizzling_functor):
        """
        Sets the swizzling functor to the type specified by `swizzling_functor`
        """
        if swizzling_functor == swizzle.ThreadblockSwizzleStreamK:
            if self.op_class == cutlass.OpcodeClass.Simt:
                raise Exception('ThreadblockSwizzleStreamK is currently only supported with opcode class TensorOp')

            if self.current_cc == 90:
                raise Exception('ThreadblockSwizzleStreamK is currently unsupported on SM90')
        self._swizzling_functor = swizzling_functor

    def _valid_tile_description(self, td: TileDescription) -> tuple:
        """
        Checks whether the provided tile description is valid for the given compute capability. At present,
        this checks the following:

        - Does the tile description use a number of stages supported by the compute capability in question?
        - Does the tile size requested fit within shared memory?
        - Are cluster dimensions outside the valid range requested for a given architecture (e.g.,
          more non-unit cluster dimensions for pre-SM90 architectures)?
        - Is the kernel schedule being used supported on the architecture in question?

        :param td: tile description to validate
        :type td: cutlass.backend.TileDescription
        :return: tuple in which the first element is a bool indicating that the tile description is valid
                 and the second element is a string providing an optional error message.
        :rtype: tuple
        """
        # Check stage count based on the CC to which we are compiling (self.cc), rather
        # than the CC from which we find kernels (self.current_cc)
        valid, msg = check.valid_stage_count(self.cc, td)
        if not valid:
            return (valid, msg)

        valid, msg = check.valid_cluster_shape(self.current_cc, td.cluster_shape)
        if not valid:
            return (valid, msg)

        valid, msg = check.valid_kernel_schedule(self.current_cc, td.kernel_schedule)
        return valid, msg

    def tile_descriptions(self) -> list:
        """
        Returns a list of valid tile descriptions for the operations

        :returns: list of valid tile descriptions for the operations
        :rtype: list
        """
        return [datatypes.td_from_profiler_op(op) for op in self.possible_operations.all_operations]

    def construct(
        self, tile_description: TileDescription = None,
        alignment_A: int = None, alignment_B: int = None, alignment_C: int = None) -> GemmOperationUniversal:
        """
        Constructs a ``cutlass.backend.GemmUniversalOperation`` based on the input parameters and current
        kernel specification of the ``Gemm`` object.

        :param tile_description: tile description specifying shapes and operand types to use in the kernel
        :type tile_description: cutlass.backend.TileDescription
        :param alignment_A: alignment of operand A
        :type alignment_A: int
        :param alignment_B: alignment of operand B
        :type alignment_B: int
        :param alignment_C: alignment of operand C
        :type alignment_C: int

        :return: operation that was constructed
        :rtype: cutlass.backend.GemmOperationUniversal
        """
        alignment_pref_A = min(128 // cutlass.DataTypeSize[self._element_a], max(self.possible_operations.alignments))
        alignment_pref_B = min(128 // cutlass.DataTypeSize[self._element_b], max(self.possible_operations.alignments))
        alignment_pref_C = min(128 // cutlass.DataTypeSize[self._element_c], max(self.possible_operations.alignments))
        alignment_A = check.alignment_or_default(alignment_A, alignment_pref_A)
        alignment_B = check.alignment_or_default(alignment_B, alignment_pref_B)
        alignment_C = check.alignment_or_default(alignment_C, alignment_pref_C)

        self._reset_epilogue_functor_alignment(alignment_C)

        tensor_A = TensorDescription(
            datatypes.binding_type(self._element_a),
            datatypes.binding_layout(self._layout_a),
            alignment_A
        )
        tensor_B = TensorDescription(
            datatypes.binding_type(self._element_b),
            datatypes.binding_layout(self._layout_b),
            alignment_B
        )
        tensor_C = TensorDescription(
            datatypes.binding_type(self._element_c),
            datatypes.binding_layout(self._layout_c),
            alignment_C
        )

        if tile_description is None:
            op = self.possible_operations.operations(alignment_A)[0]
            tile_description = datatypes.td_from_profiler_op(op)
        else:
            valid, err_str = self._valid_tile_description(tile_description)
            if not valid:
                raise Exception(f"Invalid tile description. {err_str}")
            self.tile_description = tile_description

        operation = GemmOperationUniversal(
            arch=self.current_cc,
            tile_description=tile_description,
            A=tensor_A, B=tensor_B, C=tensor_C,
            epilogue_functor=self.epilogue_functor,
            swizzling_functor=self._swizzling_functor,
        )

        return operation

    def compile(self, tile_description: TileDescription = None,
                alignment_A: int = None, alignment_B: int = None, alignment_C: int = None,
                print_module: bool = False) -> cutlass.backend.GemmOperationUniversal:
        """
        Emits and compiles the kernel currently specified. If ``tile_description`` and any
        of the ``alignment`` parameters are set, the kernel will be chosen using this
        tile description and alignments. Otherwise, a default tile description and alignment
        will be used.

        :param tile_description: tile description specifying shapes and operand types to use in the kernel
        :type tile_description: cutlass.backend.TileDescription
        :param alignment_A: alignment of operand A
        :type alignment_A: int
        :param alignment_B: alignment of operand B
        :type alignment_B: int
        :param alignment_C: alignment of operand C
        :type alignment_C: int
        :param print_module: whether to print the emitted C++ code
        :type print_module: bool

        :return: operation that was compiled
        :rtype: cutlass.backend.GemmOperationUniversal
        """
        self.operation = self.construct(tile_description, alignment_A, alignment_B, alignment_C)

        if print_module:
            print(self.operation.rt_module.emit())

        compiler.add_module([self.operation,])
        return self.operation

    def _verify_type_and_layout(self, tensor, ref_type, ref_layout, name):
        """
        Verifies that ``tensor`` has data type ``ref_type`` and layout ``ref_layout``. An exception
        is raised if it does not.

        :param tensor: object representing a tensor passed in to verify, or ``None`` if no tensor was passed in
        :type tensor: numpy/cupy/torch array/tensor object
        :param ref_dtype: data type for the tensor that this object was initialized to
        :param ref_layout: layout for the tensor that this object was initialized to
        :param name: identifier of the tensor to verify. Used in raising exceptions
        :type name: str
        """
        dtype, layout = datatypes.get_datatype_and_layout(tensor)
        if dtype != ref_type or layout != ref_layout:
            raise Exception(f'Tensor {name} with type and layout ({dtype}, {layout}) '
                            f'does not match the expected type and '
                            f'layout of ({ref_type}, {ref_layout}).')

    def _verify_tensor(self, tensor, ref_tensor, ref_dtype, ref_layout, name):
        """
        Verifies the following properties:
            1) Either ``tensor`` or ``ref_tensor`` must be set (i.e., not ``None``)
            2) If ``tensor`` is not ``None``, its datatype and layout must match matches the current versions
               set by the plan (i.e., those in ``ref_dtype`` and ``ref_layout``)

        If either of these properties does not hold, an exception is raised. If these properties hold and
        ``tensor`` is not ``None``, ``tensor`` is returned. Otherwise, ``ref_tensor`` is returned.

        :param tensor: object representing a tensor passed in to verify, or ``None`` if no tensor was passed in
        :type tensor: numpy/cupy/torch array/tensor object
        :param ref_tensor: object representing a tensor passed in on construction of this object, or ``None`` if no tensor was passed in
        :type ref_tensor: numpy/cupy/torch array/tensor object
        :param ref_dtype: data type for the tensor that this object was initialized to
        :param ref_layout: layout for the tensor that this object was initialized to
        :param name: identifier of the tensor to verify. Used in raising exceptions
        :type name: str

        :return: valid tensor object to use
        :rtype: numpy/cupy/torch array/tensor object
        """
        if tensor is None:
            if ref_tensor is None:
                raise Exception(f"Tensor {name} must be set.")
            return ref_tensor

        self._verify_type_and_layout(tensor, ref_dtype, ref_layout, name)
        return tensor

    def _verify_scalar(self, scalar, ref_scalar, ref_dtype, name):
        """
        Verifies the following properties:
            1) Either ``scalar`` or ``ref_scakar`` must be set (i.e., not ``None``)
            2) If ``scalar`` is not ``None``, its datatype must match matches the current version
               set by the plan (i.e., those in ``ref_dtype``)

        If either of these properties does not hold, an exception is raised. If these properties hold and
        ``scalar`` is not ``None``, ``scalar`` is returned. Otherwise, ``ref_scalar`` is returned.

        :param scalar: object representing a tensor passed in to verify, or ``None`` if no tensor was passed in
        :type scalar: numpy/cupy/torch scalar
        :param ref_scalar: object representing a tensor passed in on construction of this object, or ``None`` if no tensor was passed in
        :type ref_scalar: numpy/cupy/torch scalar
        :param ref_dtype: data type for the scalar that this object was initialized to
        :param name: identifier of the scalar to verify. Used in raising exceptions
        :type name: str

        :return: valid scalar to use
        :rtype: numpy/cupy/torch scalar
        """
        if scalar is None:
            if ref_scalar is None:
                raise Exception(f"Scalar {name} must be set.")
            return ref_scalar
        dtype = datatypes.library_type(scalar.dtype)
        if dtype != ref_dtype:
            raise Exception(
                f"Tensor {name} with type {dtype} does not match expected type {ref_dtype}."
            )
        return scalar

    def run(self, A=None, B=None, C=None, D=None,
            alpha=None, beta=None, batch_count: int = 1,
            sync: bool = True, print_module: bool = False) -> GemmArguments:
        """
        Runs the kernel currently specified. If it has not already been, the kernel is emitted and
        compiled. Tensors holding operands and outputs of the kernel are sourced either from the
        ``A``, ``B``, ``C``, ``D``, ``alpha``, and ``beta``
        parameters provided in this call, or from those
        passed in on the construction of this object -- one of the two must be specified.

        By default, this call returns only once the kernel has completed. To launch the kernel
        and immediately return, set ``sync=False``. In this case, it is the responsibility of the
        caller to syncrhonize the results of the kernel before attempting to access outputs
        by calling ``sync()`` on the arguments returned from this call.

        :param A: tensor representing data type and layout of operand A
        :param B: tensor representing data type and layout of operand B
        :param C: tensor representing data type and layout of operand C
        :param D: tensor representing data type and layout of operand D
        :param alpha: scalar paramter alpha from GEMM computation that scales the product of operands A and B
        :param beta: scalar parameter beta from GEMM operation that scales operand C
        :param batch_count: number of GEMMs in the batch
        :type batch_count: int
        :param sync: whether the call should wait for the kernel to complete before returning
        :type sync: bool
        :param print_module: whether to print the emitted C++ code
        :type print_module: bool

        :return: arguments passed in to the kernel
        :rtype: cutlass.backend.GemmArguments
        """
        if batch_count < 1:
            raise Exception(f"Invalid batch count {batch_count}. Value must be an integer >= 1.")

        A = self._verify_tensor(A, self.A, self._element_a, self._layout_a, "A")
        B = self._verify_tensor(B, self.B, self._element_b, self._layout_b, "B")
        C = self._verify_tensor(C, self.C, self._element_c, self._layout_c, "C")
        D = self._verify_tensor(D, self.D, self._element_d, self._layout_d, "D")
        alpha = self._verify_scalar(alpha, self.alpha, self._element_c, "alpha")
        beta = self._verify_scalar(beta, self.beta, self._element_c, "beta")

        alignment_a = self.possible_operations.find_alignment(A.shape, self._layout_a)
        alignment_b = self.possible_operations.find_alignment(B.shape, self._layout_b)
        alignment_c = self.possible_operations.find_alignment(C.shape, self._layout_c)
        self.compile(self.tile_description, alignment_A=alignment_a, alignment_B=alignment_b,
                     alignment_C=alignment_c, print_module=print_module)

        problem_size = cutlass_bindings.gemm.GemmCoord(A.shape[0], B.shape[1], A.shape[1])

        if batch_count == 1:
            mode = cutlass_bindings.gemm.Mode.Gemm
            kwargs = {'split_k_slices': 1}
        else:
            mode = cutlass_bindings.gemm.Mode.Batched
            kwargs = {'batch': batch_count}

        arguments = GemmArguments(
            operation=self.operation, problem_size=problem_size,
            A=A, B=B, C=C, D=D,
            output_op=self.operation.epilogue_type(alpha, beta),
            gemm_mode=mode,
            **kwargs
        )

        self.operation.run(arguments)

        if sync:
            arguments.sync()

        return arguments
