module attributes {gpu.container_module} {
  llvm.func @_cudaLaunchKernelEx(!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
  llvm.func @_cuKernelGetAttribute(!llvm.ptr, i32, !llvm.ptr, i32) -> i32
  llvm.func @_cudaDeviceGetAttribute(!llvm.ptr, i32, i32) -> i32
  llvm.func @_cudaGetDevice(!llvm.ptr) -> i32
  llvm.func @_cudaKernelSetAttributeForDevice(!llvm.ptr, i32, i32, i32) -> i32
  llvm.func @_cudaFuncSetAttribute(!llvm.ptr, i32, i32) -> i32
  llvm.func @_cudaLibraryGetKernel(!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
  llvm.func @_cudaLibraryLoadData(!llvm.ptr, !llvm.ptr, !llvm.ptr, !llvm.ptr, i32, !llvm.ptr, !llvm.ptr, i32) -> i32
  llvm.mlir.global internal constant @kernels_binary("P\EDU\BA\01\00\10\00\F0\1E\00\00\00\00\00\00\02\00\01\01H\00\00\00\A8\1E\00\00\00\00\00\00\00\00\00\00\00\00\00\00\07\00\01\00Z\00\00\00@\00\00\00\07\00\00\00\11\00\10\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00kernels\00\7FELF\02\01\013\07\00\00\00\00\00\00\00\02\00\BE\00\81\00\00\00\00\00\00\00\00\00\00\00\90\1D\00\00\00\00\00\00P\19\00\00\00\00\00\00Z\0DZ\00@\008\00\05\00@\00\11\00\01\00\00.shstrtab\00.strtab\00.symtab\00.symtab_shndx\00.nv.info\00.text.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00.nv.info.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00.nv.shared.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00.nv.shared.reserved.0\00.debug_frame\00.debug_line\00.rel.debug_line\00.rela.debug_line\00.nv_debug_line_sass\00.rel.nv_debug_line_sass\00.rela.nv_debug_line_sass\00.nv_debug_ptx_txt\00.rel.debug_frame\00.rela.debug_frame\00.nv.callgraph\00.nv.prototype\00.nv.constant0.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00.shstrtab\00.strtab\00.symtab\00.symtab_shndx\00.nv.info\00.text.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00.nv.info.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00.nv.shared.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00.nv.reservedSmem.offset0\00.nv.shared.reserved.0\00__nv_reservedSMEM_offset_0_alias\00.debug_frame\00.debug_line\00.rel.debug_line\00.rela.debug_line\00.nv_debug_line_sass\00.rel.nv_debug_line_sass\00.rela.nv_debug_line_sass\00.nv_debug_ptx_txt\00.rel.debug_frame\00.rela.debug_frame\00.nv.callgraph\00.nv.prototype\00kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00.nv.constant0.kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\002\00\00\00\03\00\0E\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\90\01\00\00!\00\00\00\00\00\00\00\00\00\00\00\04\00\00\00\00\00\00\00\BF\01\00\00 \A0\0F\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\E0\01\00\00\03\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\ED\01\00\00\03\00\05\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\1A\02\00\00\03\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00_\02\00\00\03\00\07\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\94\02\00\00\03\00\0A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\B0\02\00\00\12\10\0E\00\00\00\00\00\00\00\00\00\80\02\00\00\00\00\00\00\1C\03\00\00\03\00\10\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\FF\FF\FF\FF$\00\00\00\00\00\00\00\FF\FF\FF\FF\FF\FF\FF\FF\03\00\04|\FF\FF\FF\FF\0F\0C\81\80\80(\00\08\FF\81\80(\08\81\80\80(\00\00\00\FF\FF\FF\FF,\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\02\00\00\00\00\00\00\04h\00\00\00\04\04\00\00\00\0C\81\80\80(\00\00\00\00\00\CB\00\00\00\02\00q\00\00\00\01\01\FB\0E\0A\00\01\01\01\01\00\00\00\01/home/jayce.su/notes/dsl/cutlass_with_notes/examples/python/CuTeDSL/ampere\00\00inline_ptx.py\00\01\94\93\EB\C9\06\81B\00\00\09\02\00\00\00\00\00\00\00\00\04\01\02\10\03\8F\01\01\03\17\02\10\01\F1\EE\03\A6\05\02\10\01\03\D9z\02\10\01\F1\EE\F0\F0\ED\F1\03p\02 \01\EA\03\15\02\10\01\03u\02\10\01\F4\F2\03s\02\10\01\F4\F4\F3\F0\F0\03\A1\09\02\10\01\02\E0\01\00\01\01\9F\00\00\00\02\00\10\00\00\00\01\01\FB\0E\0A\00\01\01\01\01\00\00\00\01\00\00\00\09\02\00\00\00\00\00\00\00\00\04\00\03\15\01\03\00\01\03\0C\02\10\01\039\02\10\01\03\0C\02\10\01\03z\02\10\01\03C\02\10\01\037\02\10\01\03\0C\02\10\01\03z\02\10\01\F5\F5\03t\02\10\01\03\0C\02\10\01\03\A9\7F\02\10\01\03\1C\02\10\01\03t\02\10\01\03\C7\00\02\10\01\03U\02\10\01\03\10\02\10\01\03\0A\02\10\01\03X\02\10\01\03\10\02\10\01\03\10\02\10\01\03\0E\02\10\01\F5\F5\F1\02\E0\01\00\01\01\00\00\00\00\00\00\00\00.version 8.8\00.target sm_90a\00.address_size 64\00\00\00\00.visible .entry kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(\00.param .align 8 .b8 kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_0[16],\00.param .align 8 .b8 kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_1[16],\00.param .align 8 .b8 kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_2[16],\00.param .align 8 .b8 kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_3[16]\00)\00.reqntid 32, 1, 1\00{\00.reg .pred \09%p<2>;\00.reg .b16 \09%rs<7>;\00.reg .b32 \09%r<9>;\00.reg .b64 \09%rd<11>;\00\00\00ld.param.u64 \09%rd1, [kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_3];\00ld.param.u64 \09%rd2, [kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_2];\00ld.param.u64 \09%rd3, [kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_1];\00ld.param.u64 \09%rd4, [kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0_param_0];\00\00mov.u32 \09%r7, %tid.x;\00\00setp.lt.u32 \09%p1, %r7, 10;\00\00vote.sync.ballot.b32 \09%r8, %p1, -1;\00\00selp.u32 \09%r6, -1, 0, %p1;\00\00{\00\00.reg .pred ps;\00\00.reg .pred pd;\00\00setp.ne.b32 ps, %r6, 0;\00\00vote.sync.any.pred pd, ps, -1;\00\00selp.b32 %r1, 1, 0, pd;\00\00}\00\00\00\00{\00\00.reg .pred ps;\00\00.reg .pred pd;\00\00setp.ne.b32 ps, %r6, 0;\00\00vote.sync.all.pred pd, ps, -1;\00\00selp.b32 %r3, 1, 0, pd;\00\00}\00\00\00\00{\00\00.reg .pred ps;\00\00.reg .pred pd;\00\00setp.ne.b32 ps, %r6, 0;\00\00vote.sync.uni.pred pd, ps, -1;\00\00selp.b32 %r5, 1, 0, pd;\00\00}\00\00\00cvt.u64.u32 \09%rd5, %r7;\00mul.wide.u32 \09%rd6, %r7, 4;\00add.s64 \09%rd7, %rd4, %rd6;\00st.global.u32 \09[%rd7], %r8;\00\00cvt.u16.u32 \09%rs1, %r1;\00and.b16  \09%rs2, %rs1, 1;\00\00add.s64 \09%rd8, %rd3, %rd5;\00st.global.u8 \09[%rd8], %rs2;\00\00cvt.u16.u32 \09%rs3, %r3;\00and.b16  \09%rs4, %rs3, 1;\00\00add.s64 \09%rd9, %rd2, %rd5;\00st.global.u8 \09[%rd9], %rs4;\00\00cvt.u16.u32 \09%rs5, %r5;\00and.b16  \09%rs6, %rs5, 1;\00\00add.s64 \09%rd10, %rd1, %rd5;\00st.global.u8 \09[%rd10], %rs6;\00\00ret;\00\00}\00\04/\08\00\09\00\00\00\14\00\00\00\04\11\08\00\09\00\00\00\00\00\00\00\04\12\08\00\09\00\00\00\00\00\00\00\047\04\00\81\00\00\00\04\17\0C\00\00\00\00\00\03\000\00\00\F0A\00\04\17\0C\00\00\00\00\00\02\00 \00\00\F0A\00\04\17\0C\00\00\00\00\00\01\00\10\00\00\F0A\00\04\17\0C\00\00\00\00\00\00\00\00\00\00\F0A\00\03P\00\00\03\1B\FF\00\04)\10\00\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\04(\10\00\E0\00\00\00\F0\00\00\00\10\01\00\00 \01\00\00\04\1C\04\00\A0\01\00\00\04\10\0C\00 \00\00\00\01\00\00\00\01\00\00\00\03\19@\00\04\0A\08\00\0A\00\00\00\10\02@\00\046\04\00\08\00\00\00\00\00\00\00\FF\FF\FF\FF\00\00\00\00\FE\FF\FF\FF\00\00\00\00\FD\FF\FF\FF\00\00\00\00\FC\FF\FF\FF\00\00\00\00~\00\00\00\00\00\00\00\02\00\00\00\09\00\00\00\00\00\00\00\00\00\00\00\1D\00\00\00\00\00\00\00\02\00\00\00\09\00\00\00\00\00\00\00\00\00\00\00D\00\00\00\00\00\00\00\02\00\00\00\09\00\00\00\00\00\00\00\00\00\00\00\82{\01\FF\00\0A\00\00\00\08\00\00\00\E2\0F\00\19y\09\00\00\00\00\00\00!\00\00\00.\0E\00\82{\02\FF\00\84\00\00\00\0A\00\00\00b\0E\00\B9z\06\00\00\8C\00\00\00\0A\00\00\00\E2\0F\00\B9z\04\00\00\88\00\00\00\0A\00\00\00\E2\0F\00\0Cx\00\09\0A\00\00\00p`\F0\03\00\E2\1F\04%x\02\09\04\00\00\00\02\00\8E\07\00\E2/\04\10|\06\09\06\00\00\00\FF\E0\F5\0F\00\C4\0F\00\10|\04\09\04\00\00\00\FF\E0\F3\0F\00\C6\0F\00$~\07\FF\07\00\00\00\FF\06\0E\09\00\E2\0F\00\B9z\06\00\00\90\00\00\00\0A\00\00\00\E2\0F\00$~\05\FF\05\00\00\00\FF\06\8E\08\00\E2\0F\00\10|\08\09\06\00\00\00\FF\E0\F5\0F\00\E2\0F\00\B9z\04\00\00\82\00\00\00\0A\00\00\00\E4\0F\00\06x\FF\00\00\00\00\00\00\01\06\04\00\E4\0F\00\06x\0B\00\00\00\00\00\00\01\0E\04\00\E2\0F\00$~\09\FF\07\00\00\00\FF\06\0E\09\00\E2\0F\00\06x\FF\00\00\00\00\00\00\00\02\04\00\C4\0F\00\06x\FF\00\00\00\00\00\00\02\00\04\00\E2\0F\00\86y\00\02\0B\00\00\00\04\19\10\0C\00\E2\0F\00\07x\0D\FF\01\00\00\00\00\00\80\05\00\E4\0F\00\07x\0F\FF\01\00\00\00\00\00\80\04\00\E4\0F\00\07x\11\FF\01\00\00\00\00\00\00\04\00\E2\0F\00\86y\00\04\0D\00\00\00\04\11\10\0C\00\E8\0F\00\86y\00\06\0F\00\00\00\04\11\10\0C\00\E8\0F\00\86y\00\08\11\00\00\00\04\11\10\0C\00\E2\0F\00My\00\00\00\00\00\00\00\00\80\03\00\EA\0F\00Gy\FC\00\FC\FF\FF\FF\FF\FF\83\03\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\18y\00\00\00\00\00\00\00\00\00\00\00\C0\0F\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00@\00\00\00\00\00\00\00\F0\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0B\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\BB\03\00\00\00\00\00\00\96\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\13\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00X\07\00\00\00\00\00\00\08\01\00\00\00\00\00\00\02\00\00\00\09\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00\A6\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00`\08\00\00\00\00\00\00h\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\B3\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\C8\08\00\00\00\00\00\00\CF\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\E0\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\97\09\00\00\00\00\00\00\A3\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00%\02\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00:\0A\00\00\00\00\00\00\0E\09\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00)\00\00\00\00\00\00p\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00H\13\00\00\00\00\00\00$\00\00\00\00\00\00\00\03\00\00\00\00\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\A4\00\00\00\00\00\00p@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00l\13\00\00\00\00\00\00\A8\00\00\00\00\00\00\00\03\00\00\00\0E\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00Z\02\00\00\01\00\00p\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\14\14\00\00\00\00\00\00 \00\00\00\00\00\00\00\03\00\00\00\00\00\00\00\04\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\CF\01\00\00\04\00\00\00@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\008\14\00\00\00\00\00\00\18\00\00\00\00\00\00\00\03\00\00\00\05\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00\0C\02\00\00\04\00\00\00@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00P\14\00\00\00\00\00\00\18\00\00\00\00\00\00\00\03\00\00\00\06\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00H\02\00\00\04\00\00\00@\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00h\14\00\00\00\00\00\00\18\00\00\00\00\00\00\00\03\00\00\00\04\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\002\00\00\00\01\00\00\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\14\00\00\00\00\00\00\80\02\00\00\00\00\00\00\03\00\00\00\09\00\00\00\80\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\90\01\00\00\08\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\17\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00v\02\00\00\01\00\00\00B\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\17\00\00\00\00\00\00P\02\00\00\00\00\00\00\00\00\00\00\0E\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\06\00\00\00\04\00\00\00\90\1D\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\18\01\00\00\00\00\00\00\18\01\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\04\00\00\00\90\1D\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\18\01\00\00\00\00\00\00\18\01\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\05\00\00\00\80\14\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\02\00\00\00\00\00\00\80\02\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\06\00\00\00\00\17\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\04\00\00\00\00\17\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00P\02\00\00\00\00\00\00P\02\00\00\00\00\00\00\08\00\00\00\00\00\00\00") {addr_space = 0 : i32, alignment = 8 : i64}
  llvm.func @cuda_init(%arg0: !llvm.ptr) -> i32 {
    %0 = llvm.mlir.zero : !llvm.ptr
    %1 = llvm.mlir.addressof @kernels_binary : !llvm.ptr
    %2 = llvm.mlir.zero : i32
    %3 = llvm.call @_cudaLibraryLoadData(%arg0, %1, %0, %0, %2, %0, %0, %2) : (!llvm.ptr, !llvm.ptr, !llvm.ptr, !llvm.ptr, i32, !llvm.ptr, !llvm.ptr, i32) -> i32
    llvm.return %3 : i32
  }
  llvm.mlir.global internal @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0() {addr_space = 0 : i32, cu_attrs = {max_dynamic_shared_size_bytes = -1 : i32, non_portable_cluster_size_allowed = 1 : i32}} : !llvm.ptr
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
    %12 = llvm.mlir.addressof @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0 : !llvm.ptr
    %13 = llvm.mlir.constant("kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00") : !llvm.array<108 x i8>
    %14 = llvm.mlir.constant(1 : i32) : i32
    %15 = llvm.alloca %14 x !llvm.array<108 x i8> : (i32) -> !llvm.ptr
    llvm.store %13, %15 : !llvm.array<108 x i8>, !llvm.ptr
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
    %7 = llvm.mlir.addressof @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0 : !llvm.ptr
    %8 = llvm.mlir.constant("kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0\00") : !llvm.array<108 x i8>
    %9 = llvm.mlir.constant(1 : i32) : i32
    %10 = llvm.alloca %9 x !llvm.array<108 x i8> : (i32) -> !llvm.ptr
    llvm.store %8, %10 : !llvm.array<108 x i8>, !llvm.ptr
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
  llvm.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.mlir.constant(32 : i32) : i32
    %2 = llvm.mlir.constant(0 : i32) : i32
    %3 = llvm.mlir.constant(0 : i64) : i64
    %4 = llvm.inttoptr %3 : i64 to !llvm.ptr
    %5 = llvm.alloca %0 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %6 = llvm.alloca %0 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %7 = llvm.getelementptr %5[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %6, %7 : !llvm.ptr, !llvm.ptr
    %8 = llvm.getelementptr %5[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %1, %8 : i32, !llvm.ptr
    %9 = llvm.getelementptr %5[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %9 : i32, !llvm.ptr
    %10 = llvm.getelementptr %5[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %10 : i32, !llvm.ptr
    %11 = llvm.getelementptr %5[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %3, %11 : i64, !llvm.ptr
    %12 = llvm.getelementptr %5[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %12 : i32, !llvm.ptr
    %13 = llvm.getelementptr %5[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %13 : i32, !llvm.ptr
    %14 = llvm.getelementptr %5[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %14 : i32, !llvm.ptr
    %15 = llvm.getelementptr %5[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %15 : i32, !llvm.ptr
    %16 = llvm.getelementptr %5[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %4, %16 : !llvm.ptr, !llvm.ptr
    %17 = llvm.alloca %0 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %18 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %5, %18 : !llvm.ptr, !llvm.ptr
    %19 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    %20 = llvm.load %19 : !llvm.ptr -> !llvm.ptr
    %21 = llvm.mlir.constant(1 : i32) : i32
    %22 = llvm.mlir.constant(4 : i32) : i32
    %23 = llvm.alloca %22 x !llvm.ptr : (i32) -> !llvm.ptr
    %24 = llvm.mlir.constant(0 : i32) : i32
    %25 = llvm.alloca %21 x !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> : (i32) -> !llvm.ptr
    llvm.store %arg0, %25 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.ptr
    %26 = llvm.getelementptr %23[%24] : (!llvm.ptr, i32) -> !llvm.ptr, !llvm.ptr
    llvm.store %25, %26 : !llvm.ptr, !llvm.ptr
    %27 = llvm.mlir.constant(1 : i32) : i32
    %28 = llvm.alloca %21 x !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> : (i32) -> !llvm.ptr
    llvm.store %arg1, %28 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.ptr
    %29 = llvm.getelementptr %23[%27] : (!llvm.ptr, i32) -> !llvm.ptr, !llvm.ptr
    llvm.store %28, %29 : !llvm.ptr, !llvm.ptr
    %30 = llvm.mlir.constant(2 : i32) : i32
    %31 = llvm.alloca %21 x !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> : (i32) -> !llvm.ptr
    llvm.store %arg2, %31 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.ptr
    %32 = llvm.getelementptr %23[%30] : (!llvm.ptr, i32) -> !llvm.ptr, !llvm.ptr
    llvm.store %31, %32 : !llvm.ptr, !llvm.ptr
    %33 = llvm.mlir.constant(3 : i32) : i32
    %34 = llvm.alloca %21 x !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> : (i32) -> !llvm.ptr
    llvm.store %arg3, %34 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.ptr
    %35 = llvm.getelementptr %23[%33] : (!llvm.ptr, i32) -> !llvm.ptr, !llvm.ptr
    llvm.store %34, %35 : !llvm.ptr, !llvm.ptr
    %36 = llvm.mlir.addressof @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0 : !llvm.ptr
    %37 = llvm.load %36 : !llvm.ptr -> !llvm.ptr
    %38 = llvm.call @_cudaLaunchKernelEx(%20, %37, %23) : (!llvm.ptr, !llvm.ptr, !llvm.ptr) -> i32
    cuda.return_if_error %38 : i32
    llvm.return %2 : i32
  }
  llvm.func @_mlir_ciface_cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0, %arg1, %arg2, %arg3) : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32
    llvm.return %0 : i32
  }
}
