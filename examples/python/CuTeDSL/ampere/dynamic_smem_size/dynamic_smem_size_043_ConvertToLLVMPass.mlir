module attributes {gpu.container_module} {
  llvm.func @_cudaLaunchKernelEx(!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
  llvm.func @_cuKernelGetAttribute(!llvm.ptr, i32, !llvm.ptr, i32) -> i32
  llvm.func @_cudaDeviceGetAttribute(!llvm.ptr, i32, i32) -> i32
  llvm.func @_cudaGetDevice(!llvm.ptr) -> i32
  llvm.func @_cudaKernelSetAttributeForDevice(!llvm.ptr, i32, i32, i32) -> i32
  llvm.func @_cudaFuncSetAttribute(!llvm.ptr, i32, i32) -> i32
  llvm.func @_cudaLibraryGetKernel(!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
  llvm.func @_cudaLibraryLoadData(!llvm.ptr, !llvm.ptr, !llvm.ptr, !llvm.ptr, i32, !llvm.ptr, !llvm.ptr, i32) -> i32
  llvm.mlir.global internal constant @kernels_binary("P\EDU\BA\01\00\10\008\18\00\00\00\00\00\00\02\00\01\01H\00\00\00\F0\17\00\00\00\00\00\00\00\00\00\00\00\00\00\00\07\00\01\00Z\00\00\00@\00\00\00\07\00\00\00\11\00\10\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00kernels\00\7FELF\02\01\013\07\00\00\00\00\00\00\00\02\00\BE\00\81\00\00\00\00\00\00\00\00\00\00\00\A0\16\00\00\00\00\00\00\A0\11\00\00\00\00\00\00Z\0DZ\00@\008\00\06\00@\00\14\00\01\00\00.shstrtab\00.strtab\00.symtab\00.symtab_shndx\00.nv.info\00.text.kernel_cutlass_kernel_no_smem_0\00.nv.info.kernel_cutlass_kernel_no_smem_0\00.nv.shared.kernel_cutlass_kernel_no_smem_0\00.nv.shared.reserved.0\00.nv.constant4\00\00\00\00.nv.global.init\00.rel.text.kernel_cutlass_kernel_no_smem_0\00.rela.text.kernel_cutlass_kernel_no_smem_0\00.debug_frame\00.debug_line\00.rel.debug_line\00.rela.debug_line\00.nv_debug_line_sass\00.rel.nv_debug_line_sass\00.rela.nv_debug_line_sass\00.nv_debug_ptx_txt\00.rel.nv.constant.pic\00.rela.nv.constant4\00\00\00\00.rel.debug_frame\00.rela.debug_frame\00.nv.callgraph\00.nv.prototype\00.nv.constant0.kernel_cutlass_kernel_no_smem_0\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00.shstrtab\00.strtab\00.symtab\00.symtab_shndx\00.nv.info\00.text.kernel_cutlass_kernel_no_smem_0\00.nv.info.kernel_cutlass_kernel_no_smem_0\00.nv.shared.kernel_cutlass_kernel_no_smem_0\00.nv.reservedSmem.offset0\00.nv.shared.reserved.0\00__nv_reservedSMEM_offset_0_alias\00.nv.constant4\00\00\00\00.nv.global.init\00printfFormat_0\00.rel.text.kernel_cutlass_kernel_no_smem_0\00.rela.text.kernel_cutlass_kernel_no_smem_0\00.debug_frame\00.debug_line\00.rel.debug_line\00.rela.debug_line\00.nv_debug_line_sass\00.rel.nv_debug_line_sass\00.rela.nv_debug_line_sass\00.nv_debug_ptx_txt\00.rel.nv.constant.pic\00.rela.nv.constant.pic\00.rel.debug_frame\00.rela.debug_frame\00.nv.callgraph\00.nv.prototype\00kernel_cutlass_kernel_no_smem_0\00vprintf\00.nv.constant0.kernel_cutlass_kernel_no_smem_0\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\002\00\00\00\03\00\10\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\AC\00\00\00!\00\00\00\00\00\00\00\00\00\00\00\04\00\00\00\00\00\00\00\DB\00\00\00 \A0\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\FC\00\00\00\03\00\0F\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0D\01\00\00\03\00\11\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\1D\01\00\00\01\00\11\00\00\00\00\00\00\00\00\00\0D\00\00\00\00\00\00\00\81\01\00\00\03\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\8E\01\00\00\03\00\05\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\BB\01\00\00\03\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\02\00\00\03\00\07\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00`\02\00\00\03\00\0A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00|\02\00\00\12\10\10\00\00\00\00\00\00\00\00\00\00\02\00\00\00\00\00\00\9C\02\00\00\12\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\A4\02\00\00\03\00\13\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\FF\FF\FF\FF$\00\00\00\00\00\00\00\FF\FF\FF\FF\FF\FF\FF\FF\03\00\04|\FF\FF\FF\FF\0F\0C\81\80\80(\00\08\FF\81\80(\08\81\80\80(\00\00\00\FF\FF\FF\FF,\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\02\00\00\00\00\00\00\04\0C\00\00\00\0C\81\80\80(\08\044\00\00\00\00\00\00\00\AE\00\00\00\02\00x\00\00\00\01\01\FB\0E\0A\00\01\01\01\01\00\00\00\01/home/jayce.su/notes/dsl/cutlass_with_notes/examples/python/CuTeDSL/ampere\00\00dynamic_smem_size.py\00\01\94\93\EB\C9\06\9C \00\00\09\02\00\00\00\00\00\00\00\00\04\01\02\10\03\D7\00\01\03\F6\05\02 \01\03\AAz\020\01\03b\02\10\01\03\1E\02\90\01\01\02\80\02\00\01\01h\00\00\00\02\00\10\00\00\00\01\01\FB\0E\0A\00\01\01\01\01\00\00\00\01\00\00\00\09\02\00\00\00\00\00\00\00\00\04\00\03\17\01\03\00\01\03\0C\02\10\01\03t\02\10\01\03\0E\02\10\01\EB\03\06\02 \01\03\0B\02\10\01\03o\02\10\01\03\0D\02\10\01\03s\02\10\01\03\11\02\10\01\EB\03\04\02 \01\03\0A\02 \01\02\80\02\00\01\01\00\00\00\00\00\00\00\00.version 8.8\00.target sm_90a\00.address_size 64\00\00\00.extern .func  (.param .b32 func_retval0) vprintf\00(\00.param .b64 vprintf_param_0,\00.param .b64 vprintf_param_1\00)\00;\00.global .align 1 .b8 printfFormat_0[13] = {72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 10};\00\00.visible .entry kernel_cutlass_kernel_no_smem_0()\00.reqntid 1, 1, 1\00{\00.local .align 8 .b8 \09__local_depot0[8];\00.reg .b64 \09%SP;\00.reg .b64 \09%SPL;\00.reg .pred \09%p<2>;\00.reg .b32 \09%r<4>;\00.reg .b64 \09%rd<4>;\00\00\00mov.u64 \09%SPL, __local_depot0;\00cvta.local.u64 \09%SP, %SPL;\00\00mov.u32 \09%r1, %ctaid.x;\00\00setp.ne.s32 \09%p1, %r1, 0;\00\00@%p1 bra \09$L__BB0_2;\00\00mov.u64 \09%rd1, printfFormat_0;\00cvta.global.u64 \09%rd2, %rd1;\00add.u64 \09%rd3, %SP, 0;\00{ // callseq 0, 0\00.param .b64 param0;\00st.param.b64 \09[param0], %rd2;\00.param .b64 param1;\00st.param.b64 \09[param1], %rd3;\00.param .b32 retval0;\00call.uni (retval0), \00vprintf, \00(\00param0, \00param1\00);\00ld.param.b32 \09%r2, [retval0];\00} // callseq 0\00$L__BB0_2:\00\00ret;\00\00}\00\04/\08\00\0C\00\00\00\18\00\00\00\04\11\08\00\0C\00\00\00\08\00\00\00\04\12\08\00\0C\00\00\00\08\00\00\00\047\04\00\81\00\00\00\03P\00\00\03\1B\FF\00\04\0F\04\00\0D\00\00\00\04F\04\00\F0\00\00\00\04\1C\08\00`\00\00\00\00\01\00\00\04\10\0C\00\01\00\00\00\01\00\00\00\01\00\00\00\046\04\00\08\00\00\00\00\00\00\00\FF\FF\FF\FF\0C\00\00\00\0D\00\00\00\00\00\00\00\FE\FF\FF\FF\00\00\00\00\FD\FF\FF\FF\00\00\00\00\FC\FF\FF\FF\00\00\00\00\85\00\00\00\00\00\00\00\02\00\00\00\0C\00\00\00\00\00\00\00\00\00\00\00\1D\00\00\00\00\00\00\00\02\00\00\00\0C\00\00\00\00\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\02\00\00\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\02\00\00\00\0D\00\00\00\00\00\00\00\00\00\00\00D\00\00\00\00\00\00\00\02\00\00\00\0C\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\82{\01\FF\00\0A\00\00\00\08\00\00\000\0E\00\C3y\04\00\00\00\00\00\00%\00\00\00b\0E\006x\01\01\F8\FF\FF\FF\00\00\00\00\00\E2\1F\00\0C|\00\FF\04\00\00\00pR\F0\0B\00\E2/\00\B9z\04\00\00\08\00\00\00\08\00\00\00\C6\0F\00\10|\06\01\04\00\00\00\FF\E0\F3\0F\00\D2\0F\00M\09\00\00\00\00\00\00\00\00\80\03\00\EA\0F\00\02x\00\00\00\00\00\00\00\0F\00\00\00\E2\0F\00\B9z\04\00\00\09\00\00\00\08\00\00\00\E2\0F\00\B9z\06\00\00\02\00\01\00\0A\00\00\00\E2\0F\00$~\07\FF\04\00\00\00\FF\06\8E\08\00\E2\0F\00\82{\02\00\00\00\00\01\00\0A\00\00\00b\00\00$~\04\FF\06\00\00\00\FF\00\8E\0F\00\E4\0F\00$~\05\FF\07\00\00\00\FF\00\8E\0F\00\CE\0F\00Ny\14\10\00\00\00\00\00\00\00\00\00\CE\0F\00Cs\00\02\00\00\00\00\00\00\C0\03\00\EA?\00My\00\00\00\00\00\00\00\00\80\03\00\EA\0F\00Gy\FC\00\FC\FF\FF\FF\FF\FF\83\03\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00Hello world\0A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00@\00\00\00\00\00\00\00a\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0B\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\E0\02\00\00\00\00\00\00\D2\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\13\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\B8\05\00\00\00\00\00\00h\01\00\00\00\00\00\00\02\00\00\00\0C\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\008\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00 \07\00\00\00\00\00\00h\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00E\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\88\07\00\00\00\00\00\00\B2\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00r\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00:\08\00\00\00\00\00\00l\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\B7\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\A6\08\00\00\00\00\00\00\AE\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00)\00\00\00\00\00\00p\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00T\0C\00\00\00\00\00\00$\00\00\00\00\00\00\00\03\00\00\00\00\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00X\00\00\00\00\00\00p@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00x\0C\00\00\00\00\00\00D\00\00\00\00\00\00\00\03\00\00\00\10\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\17\02\00\00\01\00\00p\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\BC\0C\00\00\00\00\00\00(\00\00\00\00\00\00\00\03\00\00\00\00\00\00\00\04\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00a\01\00\00\04\00\00\00@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\E8\0C\00\00\00\00\00\00\18\00\00\00\00\00\00\00\03\00\00\00\05\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00\9E\01\00\00\04\00\00\00@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0D\00\00\00\00\00\00\18\00\00\00\00\00\00\00\03\00\00\00\06\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00\DE\01\00\00\04\00\00\00@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\18\0D\00\00\00\00\00\000\00\00\00\00\00\00\00\03\00\00\00\0F\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00\05\02\00\00\04\00\00\00@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00H\0D\00\00\00\00\00\00\18\00\00\00\00\00\00\00\03\00\00\00\04\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00\C2\00\00\00\01\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00`\0D\00\00\00\00\00\00\10\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\00\00\00\00\00\00\00\002\00\00\00\01\00\00\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\0D\00\00\00\00\00\00\00\02\00\00\00\00\00\00\03\00\00\00\0C\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\D3\00\00\00\01\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\0F\00\00\00\00\00\00\0D\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\AC\00\00\00\08\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\8D\0F\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\003\02\00\00\01\00\00\00B\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\90\0F\00\00\00\00\00\00\10\02\00\00\00\00\00\00\00\00\00\00\10\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\06\00\00\00\04\00\00\00\A0\16\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00P\01\00\00\00\00\00\00P\01\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\04\00\00\00\A0\16\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00P\01\00\00\00\00\00\00P\01\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\04\00\00\00`\0D\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\05\00\00\00\80\0D\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\02\00\00\00\00\00\00\00\02\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\06\00\00\00\80\0F\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0D\00\00\00\00\00\00\00\0D\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\04\00\00\00\90\0F\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\10\02\00\00\00\00\00\00\10\02\00\00\00\00\00\00\08\00\00\00\00\00\00\00") {addr_space = 0 : i32, alignment = 8 : i64}
  llvm.func @cuda_init(%arg0: !llvm.ptr) -> i32 {
    %0 = llvm.mlir.zero : !llvm.ptr
    %1 = llvm.mlir.addressof @kernels_binary : !llvm.ptr
    %2 = llvm.mlir.zero : i32
    %3 = llvm.call @_cudaLibraryLoadData(%arg0, %1, %0, %0, %2, %0, %0, %2) : (!llvm.ptr, !llvm.ptr, !llvm.ptr, !llvm.ptr, i32, !llvm.ptr, !llvm.ptr, i32) -> i32
    llvm.return %3 : i32
  }
  llvm.mlir.global internal @kernel_cutlass_kernel_no_smem_0() {addr_space = 0 : i32, cu_attrs = {max_dynamic_shared_size_bytes = -1 : i32, non_portable_cluster_size_allowed = 1 : i32}} : !llvm.ptr
  llvm.func @cuda_load(%arg0: !llvm.ptr) -> i32 {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.alloca %0 x i32 : (i32) -> !llvm.ptr
    %2 = llvm.call @_cudaGetDevice(%1) : (!llvm.ptr) -> i32
    %3 = llvm.mlir.constant(0 : i32) : i32
    %4 = llvm.icmp "eq" %2, %3 : i32
    llvm.cond_br %4, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    llvm.return %2 : i32
  ^bb2:  // pred: ^bb0
    %5 = llvm.load %1 : !llvm.ptr -> i32
    %6 = llvm.alloca %0 x i32 : (i32) -> !llvm.ptr
    %7 = llvm.mlir.constant(97 : i32) : i32
    %8 = llvm.call @_cudaDeviceGetAttribute(%6, %7, %5) : (!llvm.ptr, i32, i32) -> i32
    %9 = llvm.mlir.constant(0 : i32) : i32
    %10 = llvm.icmp "eq" %8, %9 : i32
    llvm.cond_br %10, ^bb4, ^bb3
  ^bb3:  // pred: ^bb2
    llvm.return %8 : i32
  ^bb4:  // pred: ^bb2
    %11 = llvm.load %6 : !llvm.ptr -> i32
    %12 = llvm.mlir.addressof @kernel_cutlass_kernel_no_smem_0 : !llvm.ptr
    %13 = llvm.mlir.constant("kernel_cutlass_kernel_no_smem_0\00") : !llvm.array<32 x i8>
    %14 = llvm.mlir.constant(1 : i32) : i32
    %15 = llvm.alloca %14 x !llvm.array<32 x i8> : (i32) -> !llvm.ptr
    llvm.store %13, %15 : !llvm.array<32 x i8>, !llvm.ptr
    %16 = llvm.call @_cudaLibraryGetKernel(%12, %arg0, %15) : (!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
    %17 = llvm.mlir.constant(0 : i32) : i32
    %18 = llvm.icmp "eq" %16, %17 : i32
    llvm.cond_br %18, ^bb7, ^bb6
  ^bb5:  // pred: ^bb13
    %19 = llvm.mlir.zero : i32
    llvm.return %19 : i32
  ^bb6:  // pred: ^bb4
    llvm.return %16 : i32
  ^bb7:  // pred: ^bb4
    %20 = llvm.load %12 : !llvm.ptr -> !llvm.ptr
    %21 = llvm.mlir.constant(8 : i32) : i32
    %22 = llvm.mlir.constant(1 : i32) : i32
    %23 = llvm.mlir.constant(1 : i32) : i32
    %24 = llvm.alloca %22 x i32 : (i32) -> !llvm.ptr
    %25 = llvm.call @_cuKernelGetAttribute(%24, %23, %20, %5) : (!llvm.ptr, i32, !llvm.ptr, i32) -> i32
    %26 = llvm.mlir.constant(0 : i32) : i32
    %27 = llvm.icmp "eq" %25, %26 : i32
    llvm.cond_br %27, ^bb9, ^bb8
  ^bb8:  // pred: ^bb7
    llvm.return %25 : i32
  ^bb9:  // pred: ^bb7
    %28 = llvm.load %24 : !llvm.ptr -> i32
    %29 = llvm.sub %11, %28 : i32
    %30 = llvm.call @_cudaFuncSetAttribute(%20, %21, %29) : (!llvm.ptr, i32, i32) -> i32
    %31 = llvm.mlir.constant(0 : i32) : i32
    %32 = llvm.icmp "eq" %30, %31 : i32
    llvm.cond_br %32, ^bb11, ^bb10
  ^bb10:  // pred: ^bb9
    llvm.return %30 : i32
  ^bb11:  // pred: ^bb9
    %33 = llvm.mlir.constant(14 : i32) : i32
    %34 = llvm.mlir.constant(1 : i32) : i32
    %35 = llvm.call @_cudaFuncSetAttribute(%20, %33, %34) : (!llvm.ptr, i32, i32) -> i32
    %36 = llvm.mlir.constant(0 : i32) : i32
    %37 = llvm.icmp "eq" %35, %36 : i32
    llvm.cond_br %37, ^bb13, ^bb12
  ^bb12:  // pred: ^bb11
    llvm.return %35 : i32
  ^bb13:  // pred: ^bb11
    llvm.br ^bb5
  }
  llvm.func @cuda_load_to_device(%arg0: !llvm.ptr, %arg1: i32) -> i32 {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.alloca %0 x i32 : (i32) -> !llvm.ptr
    %2 = llvm.mlir.constant(97 : i32) : i32
    %3 = llvm.call @_cudaDeviceGetAttribute(%1, %2, %arg1) : (!llvm.ptr, i32, i32) -> i32
    %4 = llvm.mlir.constant(0 : i32) : i32
    %5 = llvm.icmp "eq" %3, %4 : i32
    llvm.cond_br %5, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    llvm.return %3 : i32
  ^bb2:  // pred: ^bb0
    %6 = llvm.load %1 : !llvm.ptr -> i32
    %7 = llvm.mlir.addressof @kernel_cutlass_kernel_no_smem_0 : !llvm.ptr
    %8 = llvm.mlir.constant("kernel_cutlass_kernel_no_smem_0\00") : !llvm.array<32 x i8>
    %9 = llvm.mlir.constant(1 : i32) : i32
    %10 = llvm.alloca %9 x !llvm.array<32 x i8> : (i32) -> !llvm.ptr
    llvm.store %8, %10 : !llvm.array<32 x i8>, !llvm.ptr
    %11 = llvm.call @_cudaLibraryGetKernel(%7, %arg0, %10) : (!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
    %12 = llvm.mlir.constant(0 : i32) : i32
    %13 = llvm.icmp "eq" %11, %12 : i32
    llvm.cond_br %13, ^bb5, ^bb4
  ^bb3:  // pred: ^bb11
    %14 = llvm.mlir.zero : i32
    llvm.return %14 : i32
  ^bb4:  // pred: ^bb2
    llvm.return %11 : i32
  ^bb5:  // pred: ^bb2
    %15 = llvm.load %7 : !llvm.ptr -> !llvm.ptr
    %16 = llvm.mlir.constant(8 : i32) : i32
    %17 = llvm.mlir.constant(1 : i32) : i32
    %18 = llvm.mlir.constant(1 : i32) : i32
    %19 = llvm.alloca %17 x i32 : (i32) -> !llvm.ptr
    %20 = llvm.call @_cuKernelGetAttribute(%19, %18, %15, %arg1) : (!llvm.ptr, i32, !llvm.ptr, i32) -> i32
    %21 = llvm.mlir.constant(0 : i32) : i32
    %22 = llvm.icmp "eq" %20, %21 : i32
    llvm.cond_br %22, ^bb7, ^bb6
  ^bb6:  // pred: ^bb5
    llvm.return %20 : i32
  ^bb7:  // pred: ^bb5
    %23 = llvm.load %19 : !llvm.ptr -> i32
    %24 = llvm.sub %6, %23 : i32
    %25 = llvm.call @_cudaKernelSetAttributeForDevice(%15, %16, %24, %arg1) : (!llvm.ptr, i32, i32, i32) -> i32
    %26 = llvm.mlir.constant(0 : i32) : i32
    %27 = llvm.icmp "eq" %25, %26 : i32
    llvm.cond_br %27, ^bb9, ^bb8
  ^bb8:  // pred: ^bb7
    llvm.return %25 : i32
  ^bb9:  // pred: ^bb7
    %28 = llvm.mlir.constant(14 : i32) : i32
    %29 = llvm.mlir.constant(1 : i32) : i32
    %30 = llvm.call @_cudaKernelSetAttributeForDevice(%15, %28, %29, %arg1) : (!llvm.ptr, i32, i32, i32) -> i32
    %31 = llvm.mlir.constant(0 : i32) : i32
    %32 = llvm.icmp "eq" %30, %31 : i32
    llvm.cond_br %32, ^bb11, ^bb10
  ^bb10:  // pred: ^bb9
    llvm.return %30 : i32
  ^bb11:  // pred: ^bb9
    llvm.br ^bb3
  }
  llvm.func @cutlass_launch_kernel2() -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.mlir.constant(0 : i32) : i32
    %2 = llvm.mlir.constant(0 : i64) : i64
    %3 = llvm.inttoptr %2 : i64 to !llvm.ptr
    %4 = llvm.alloca %0 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %5 = llvm.alloca %0 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %6 = llvm.getelementptr %4[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %5, %6 : !llvm.ptr, !llvm.ptr
    %7 = llvm.getelementptr %4[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %7 : i32, !llvm.ptr
    %8 = llvm.getelementptr %4[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %8 : i32, !llvm.ptr
    %9 = llvm.getelementptr %4[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %9 : i32, !llvm.ptr
    %10 = llvm.getelementptr %4[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %10 : i64, !llvm.ptr
    %11 = llvm.getelementptr %4[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %11 : i32, !llvm.ptr
    %12 = llvm.getelementptr %4[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %12 : i32, !llvm.ptr
    %13 = llvm.getelementptr %4[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %13 : i32, !llvm.ptr
    %14 = llvm.getelementptr %4[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %1, %14 : i32, !llvm.ptr
    %15 = llvm.getelementptr %4[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %3, %15 : !llvm.ptr, !llvm.ptr
    %16 = llvm.alloca %0 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %17 = llvm.getelementptr %16[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %4, %17 : !llvm.ptr, !llvm.ptr
    %18 = llvm.getelementptr %16[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    %19 = llvm.load %18 : !llvm.ptr -> !llvm.ptr
    %20 = llvm.mlir.constant(1 : i32) : i32
    %21 = llvm.mlir.constant(0 : i32) : i32
    %22 = llvm.alloca %21 x !llvm.ptr : (i32) -> !llvm.ptr
    %23 = llvm.mlir.addressof @kernel_cutlass_kernel_no_smem_0 : !llvm.ptr
    %24 = llvm.load %23 : !llvm.ptr -> !llvm.ptr
    %25 = llvm.call @_cudaLaunchKernelEx(%19, %24, %22) : (!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
    %26 = builtin.unrealized_conversion_cast %25 : i32 to !cuda.result
    %27 = builtin.unrealized_conversion_cast %26 : !cuda.result to i32
    cuda.return_if_error %27 : i32
    llvm.return %1 : i32
  }
  llvm.func @_mlir_ciface_cutlass_launch_kernel2() -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass_launch_kernel2() : () -> i32
    llvm.return %0 : i32
  }
}
