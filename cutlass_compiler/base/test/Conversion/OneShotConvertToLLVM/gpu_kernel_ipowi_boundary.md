# Integer power native lowering boundary

The `one-shot-convert-to-llvm` prototype lowers device-side `math.ipowi` before GPU LLVM/NVVM conversion. Upstream `convert-math-to-funcs` generates a `func.func` helper at the enclosing module scope; `localizeIpowiHelpers` clones each referenced helper into its `gpu.module` and rewrites the call because GPU modules have an independent symbol table. The helper is then lowered to LLVM/NVVM arithmetic and control flow.

This test validates the open-source `cutlass_compiler` pipeline only. The installed CuTe DSL wheel uses the packaged native `cute-to-nvvm` implementation in a stripped `_cutlass_ir` shared library, which is not part of this checkout and cannot be patched by this change. Applying the native repair to that runtime requires rebuilding and replacing the packaged compiler binary. The Python square-and-multiply expansion remains the compatible mitigation for an existing wheel.
