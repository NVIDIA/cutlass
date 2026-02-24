# -*- coding: utf-8 -*-
"""
cute_ir_dump_patch.py（单环境变量总开关版 + 全量generic打印版）

目标：
- 所有落盘的 .mlir（0_ / per-pass / stdout slice）尽可能全部是 MLIR generic form
  即等价于 --mlir-print-op-generic 的效果（但不依赖命令行全局开关）

说明：
- PassManager 的 enable_ir_printing/print_ir_after_all 有的版本无法传 OpPrintingFlags
  所以这里采用：
  1) 尝试让 PM 自己 generic 打印（若支持）
  2) 无论 PM 输出是什么，split 后对每段做 parse->generic 重打印（强兜底）
"""

from __future__ import annotations
import os
import re
import atexit
import sys
import runpy
import tempfile
from pathlib import Path
from contextlib import contextmanager

# 单一总开关
_ENV_ON = str(os.getenv("CUTE_DSL_ON", "")).strip().lower() not in ("", "0", "false", "no")

# 默认关掉 CUTE 的文件/编译缓存，确保能触发编译与 IR 生成
os.environ.setdefault("CUTE_DSL_DISABLE_FILE_CACHING", "1")

# 常量与全局状态
DUMP_DIR: Path | None = None
RUN_TAG: str | None = None

_STD_LOG_PATH: Path | None = None
_ERR_LOG_PATH: Path | None = None
_STD_LOG_F = None
_ERR_LOG_F = None

_SYS_STDOUT_ORIG = None
_SYS_STDERR_ORIG = None
_INSTALLED = False

_TARGET_FILE: Path | None = None    # -m 入口记录目标脚本路径
_STD_SPLIT_TEE = None

# 记录最近一次可用的 MLIR Context（用于 parse->generic 重打印）
_LAST_MLIR_CONTEXT = None

# stdout IR 片段标记与输出文件名
STDOUT_IR_START = "//===--- ------ Generated IR ------ ---===="
STDOUT_IR_END   = "//===--- --- End of Generated IR -- ---===="

def _stdout_ir_mlir_filename() -> str:
    tag = RUN_TAG or _infer_run_tag()
    return f"{tag}_0_with_loc.mlir"

def _sanitize_for_fs(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", s)

def _infer_run_tag() -> str:
    target = None
    if _TARGET_FILE:
        target = str(_TARGET_FILE)
    else:
        pt = os.getenv("PYTEST_CURRENT_TEST", "")
        if pt:
            target = pt.split("::", 1)[0]

    if not target:
        try:
            import inspect, site
            sitepkgs = set(site.getsitepackages() + [site.getusersitepackages()])
            for fr in inspect.stack()[1:]:
                fn = fr.filename
                if fn.endswith(".py") and "cute_ir_dump_patch.py" not in fn and not any(fn.startswith(sp) for sp in sitepkgs):
                    target = fn
                    break
        except Exception:
            pass

    if not target:
        try:
            import __main__
            target = getattr(__main__, "__file__", "") or ""
        except Exception:
            target = target or (sys.argv[0] if sys.argv else "")

    stem = Path(target).stem if target else "interactive"
    return _sanitize_for_fs(stem)

def _ensure_dump_dir():
    global DUMP_DIR
    if DUMP_DIR is None:
        stem = _infer_run_tag()
        DUMP_DIR = Path(f"./{stem}").resolve()
        DUMP_DIR.mkdir(parents=True, exist_ok=True)

class Tee:
    def __init__(self, *streams): self.streams = streams
    def write(self, data):
        for s in self.streams: s.write(data)
    def flush(self):
        for s in self.streams: s.flush()

class SplitStdoutTee:
    """
    stdout 同时写到 console 和 stdout.log
    并识别 Generated IR 标记，把 IR slice 写入一个单独的 .mlir 文件
    """
    def __init__(self, console_stream, stdout_file_stream, mlir_path: Path):
        self.console = console_stream
        self.out = stdout_file_stream
        self.mlir_path = Path(mlir_path)
        self.mlir_f = None
        self.buf = ""
        self.capturing = False
        self.start = STDOUT_IR_START
        self.end = STDOUT_IR_END
        self._safe_tail_keep_normal = max(0, len(self.start) - 1)
        self._safe_tail_keep_capture = max(0, len(self.end) - 1)

    def _ensure_mlir_open(self):
        if self.mlir_f is None:
            self.mlir_f = open(self.mlir_path, "w")

    def write(self, data):
        self.console.write(data)
        self.buf += data
        while True:
            if not self.capturing:
                idx = self.buf.find(self.start)
                if idx == -1:
                    safe_len = max(0, len(self.buf) - self._safe_tail_keep_normal)
                    if safe_len > 0:
                        self.out.write(self.buf[:safe_len])
                        self.out.flush()
                        self.buf = self.buf[safe_len:]
                    break
                else:
                    pre = self.buf[:idx]
                    if pre:
                        self.out.write(pre)
                        self.out.flush()
                    self.buf = self.buf[idx + len(self.start):]
                    self.capturing = True
                    self._ensure_mlir_open()
            else:
                idx2 = self.buf.find(self.end)
                if idx2 == -1:
                    safe_len = max(0, len(self.buf) - self._safe_tail_keep_capture)
                    if safe_len > 0:
                        if self.mlir_f:
                            self.mlir_f.write(self.buf[:safe_len])
                            self.mlir_f.flush()
                        self.buf = self.buf[safe_len:]
                    break
                else:
                    seg = self.buf[:idx2]
                    if seg and self.mlir_f:
                        self.mlir_f.write(seg)
                        self.mlir_f.flush()
                    self.buf = self.buf[idx2 + len(self.end):]
                    self.capturing = False
        return len(data)

    def fileno(self):
        return self.console.fileno()

    def flush(self):
        self.console.flush()
        self.out.flush()
        if self.mlir_f: self.mlir_f.flush()

    def drain(self):
        if not self.buf: return
        if self.capturing:
            self._ensure_mlir_open()
            if self.mlir_f: self.mlir_f.write(self.buf)
        else:
            self.out.write(self.buf)
        self.buf = ""

    def close(self):
        self.drain()
        self.flush()
        try:
            if self.mlir_f: self.mlir_f.close()
        except Exception:
            pass

@contextmanager
def redirect_fds(stdout_path=None, stderr_path=None):
    import os as _os
    old_out, old_err = _os.dup(1), _os.dup(2)
    f_out = f_err = None
    try:
        if stdout_path:
            f_out = open(stdout_path, "w")
            _os.dup2(f_out.fileno(), 1)
        if stderr_path:
            f_err = open(stderr_path, "w")
            _os.dup2(f_err.fileno(), 2)
        yield
    finally:
        _os.dup2(old_out, 1); _os.dup2(old_err, 2)
        _os.close(old_out); _os.close(old_err)
        if f_out: f_out.close()
        if f_err: f_err.close()

# -------------------------
# MLIR genericize (强兜底)
# -------------------------
def _get_mlir_ir_module():
    try:
        from mlir import ir  # type: ignore
        return ir
    except Exception:
        return None

def _ctx_with_unregistered(ctx):
    try:
        ctx.allow_unregistered_dialects = True
    except Exception:
        pass
    return ctx

def _print_generic_from_op(op) -> str:
    # 统一走 generic form
    try:
        return op.get_asm(print_generic_op_form=True, large_elements_limit=2**31)
    except TypeError:
        # 某些版本参数名不同/不支持，退化
        return op.get_asm(large_elements_limit=2**31)

def _genericize_mlir_text(asm: str, context=None) -> tuple[str, bool]:
    """
    返回 (generic_text, ok)
    ok=False 表示 parse/重打印失败，返回原文
    """
    ir = _get_mlir_ir_module()
    if ir is None:
        return asm, False

    txt = asm if asm.endswith("\n") else (asm + "\n")
    if not txt.strip():
        return asm, False

    # 选择 context：优先使用已有（能识别 cute/cuda 等 dialect 的 custom asm）
    try:
        if context is None:
            ctx = _ctx_with_unregistered(ir.Context())
        else:
            ctx = _ctx_with_unregistered(context)
    except Exception:
        return asm, False

    # 1) 尝试按完整 module parse
    try:
        with ctx:
            m = ir.Module.parse(txt, context=ctx)
            return _print_generic_from_op(m.operation), True
    except Exception:
        pass

    # 2) 尝试按 operation parse（某些 pass dump 可能不是完整 module）
    try:
        with ctx:
            op = ir.Operation.parse(txt, context=ctx)  # type: ignore
            return _print_generic_from_op(op), True
    except Exception:
        pass

    # 3) 尝试 wrap 成 module { ... }
    wrapped = "module {\n" + txt + "\n}\n"
    try:
        with ctx:
            m = ir.Module.parse(wrapped, context=ctx)
            return _print_generic_from_op(m.operation), True
    except Exception:
        pass

    return asm, False

def _rewrite_file_generic(path: Path, context=None) -> bool:
    try:
        txt = path.read_text(errors="ignore")
    except Exception:
        return False
    out, ok = _genericize_mlir_text(txt, context=context)
    if not ok:
        return False
    try:
        path.write_text(out, encoding="utf-8")
        return True
    except Exception:
        return False

def _op_to_text(module_or_op) -> str:
    """
    对内存里的 module/op 直接 generic 打印（无需 parse）
    """
    op = getattr(module_or_op, "operation", module_or_op)
    try:
        return op.get_asm(print_generic_op_form=True, large_elements_limit=2**31)
    except Exception:
        try:
            return op.get_asm(large_elements_limit=2**31)
        except Exception:
            return str(op)

def _save_text(tag: str, content: str, suffix="txt") -> str:
    _ensure_dump_dir()
    name = f"{RUN_TAG}_{tag}.{suffix}"
    fn = DUMP_DIR / name
    fn.write_text(content, encoding='utf-8')
    print(f"[DUMP] {tag} -> {fn} ({content.count(os.linesep)+1} lines)")
    return str(fn)

def _save_ir(tag, module_or_op) -> str:
    return _save_text(tag, _op_to_text(module_or_op), "mlir")

def _split_pass_text_to_files(text: str, *, context=None) -> list[str]:
    """
    从 pass manager 的 stderr dump 中切分每个 pass 的 IR。
    关键：每段写盘前强制 genericize（parse->generic），写盘后再文件级兜底重写一次。
    """
    if not text.strip():
        return []

    pat = re.compile(
        r"^\s*//\s*-{2,}\s*//\s*IR\s+Dump\s+After\s+([^(]+?)\s*\(([^)]*)\)\s*//\s*-{2,}\s*//\s*$",
        re.MULTILINE
    )
    parts = pat.split(text)

    out_files: list[str] = []
    if len(parts) < 4:
        # 尝试把整个 stderr 当成 MLIR genericize 一次再落盘
        whole, ok = _genericize_mlir_text(text, context=context)
        if ok:
            out_files.append(_save_text("pass_dump_all_generic", whole, "mlir"))
            print("[WARN] per-pass markers not detected; wrote whole dump as GENERIC MLIR (best effort).")
        else:
            out_files.append(_save_text("pass_dump_unparsed", text, "txt"))
            print("[WARN] per-pass markers not detected; wrote raw dump as TXT.")
        return out_files

    for i in range(1, len(parts), 3):
        pass_name = parts[i].strip()
        content = (parts[i+2] or "").strip() + "\n"

        generic, ok = _genericize_mlir_text(content, context=context)
        if not ok:
            # 失败也照样写盘，但标记一下，方便定位
            generic = content

        idx = (i // 3) + 1
        tag = f"{idx:03d}_{_sanitize_for_fs(pass_name)}"
        fn = _save_text(tag, generic, "mlir")
        out_files.append(fn)

        # 文件级再兜底重写一次（确保最终是 generic）
        try:
            _rewrite_file_generic(Path(fn), context=context)
        except Exception:
            pass

    print(f"[DUMP] per-pass IR split -> {len(out_files)} files")
    return out_files

# -------------------------
# 只编译不运行：JIT/执行兜底
# -------------------------
class _DummyJIT:
    def __call__(self, *args, **kwargs):
        print("[NOEXEC] JIT object called directly in COMPILE-ONLY mode; ignored.")
        return None

    def __getattr__(self, name):
        return lambda *a, **kw: print(f"[NOEXEC] {name} called in COMPILE-ONLY mode; ignored.")

# -------------------------
# 只编译模式：跳过架构兼容性检查
# -------------------------
def _get_result_payload(result):
    if isinstance(result, (tuple, list)):
        if len(result) <= 1: return None
        elif len(result) == 2: return result[1]
        else: return result[1:]
    return None

def _checkCudaErrors_compile_only(result):
    first = result[0] if isinstance(result, (tuple, list)) and len(result) > 0 else result
    error_code = getattr(first, "value", first)

    if error_code == 209:  # CUDA_ERROR_NO_BINARY_FOR_GPU
        print("[COMPILE-ONLY] Ignoring CUDA_ERROR_NO_BINARY_FOR_GPU (arch mismatch) in compile-only mode")
        return _get_result_payload(result)

    orig = getattr(_patch_cuda_runtime_for_compile_only, "_original_checkCudaErrors", None)
    if orig:
        return orig(result)

    if error_code not in (0, None):
        raise RuntimeError(f"CUDA error code {error_code}")

    return _get_result_payload(result)

def _load_kernels_from_ir_module_compile_only(module, kernel_info):
    print(f"[COMPILE-ONLY] Skipping CUDA kernel loading (compile-only mode, {len(kernel_info) if kernel_info else 0} kernels)")
    return []

def _patch_cuda_runtime_for_compile_only():
    if not _ENV_ON: return
    try:
        import cutlass.base_dsl.runtime.cuda as _cuda_rt
        import cutlass.base_dsl.jit_executor as _jit_exec
    except Exception as e:
        print(f"[WARN] import cutlass modules for compile-only patch failed: {e}")
        return

    if not hasattr(_patch_cuda_runtime_for_compile_only, "_patched"):
        _patch_cuda_runtime_for_compile_only._original_checkCudaErrors = _cuda_rt.checkCudaErrors
        _cuda_rt.checkCudaErrors = _checkCudaErrors_compile_only
        _jit_exec.load_kernels_from_ir_module = _load_kernels_from_ir_module_compile_only
        _patch_cuda_runtime_for_compile_only._patched = True
        print("[INFO] Patched CUDA runtime for COMPILE-ONLY mode (skip arch compatibility check)")

def _patch_hardware_info_for_compile_only():
    if not _ENV_ON: return
    try:
        import cutlass.utils.hardware_info as _hwi
    except ImportError:
        print("[WARN] Could not import cutlass.utils.hardware_info to patch occupancy check.")
        return

    if hasattr(_hwi, "HardwareInfo"):
        _hwi.HardwareInfo.get_max_active_clusters = lambda self, *args, **kwargs: 1
        print("[INFO] Patched HardwareInfo.get_max_active_clusters for COMPILE-ONLY mode")

# -------------------------
# PassManager 打印：尽可能启用 generic
# -------------------------
def _enable_pm_ir_printing_best_effort(pm):
    """
    兼容不同 MLIR Python 绑定版本：尽量让 PM 自己在 dump 时就用 generic form。
    如果不支持，就退化到原来的 enable_ir_printing / print_ir_after_all。
    """
    # 常见组合：enable_ir_printing(print_after_only=True, print_generic_op_form=True)
    candidates = []

    if hasattr(pm, "enable_ir_printing"):
        candidates += [
            ("enable_ir_printing", dict(print_after_only=True, print_generic_op_form=True)),
            ("enable_ir_printing", dict(print_generic_op_form=True)),
            ("enable_ir_printing", dict(print_after_only=True)),
            ("enable_ir_printing", dict()),
        ]
    if hasattr(pm, "print_ir_after_all"):
        candidates += [
            ("print_ir_after_all", dict(_arg=True)),  # 兼容只接收 bool 的版本
        ]

    for method, kwargs in candidates:
        try:
            fn = getattr(pm, method)
            if method == "print_ir_after_all":
                fn(True)
            else:
                if kwargs:
                    fn(**kwargs)
                else:
                    fn()
            return True
        except TypeError:
            # 可能不接受这些 kwargs，继续尝试
            continue
        except Exception:
            continue
    return False

# -------------------------
# 核心：补丁 Compiler.compile
# -------------------------
def compile_and_dump(self, module, pipeline, *args, **kwargs):
    global _LAST_MLIR_CONTEXT
    print("[PATCH] hit Compiler.compile")

    # 记录 context（用于后续 parse->generic）
    _LAST_MLIR_CONTEXT = getattr(module, "context", None)
    if _LAST_MLIR_CONTEXT is None:
        try:
            _LAST_MLIR_CONTEXT = module.operation.context
        except Exception:
            _LAST_MLIR_CONTEXT = None

    # 0_：内存 module 直接 generic 打印
    _save_ir("0_", module)

    pm = self.passmanager.PassManager.parse(pipeline)

    # 让 PM 尽可能 generic dump（如果版本支持）
    _enable_pm_ir_printing_best_effort(pm)

    tmp_file = None
    text = ""
    try:
        _ensure_dump_dir()
        with tempfile.NamedTemporaryFile(prefix=f"{RUN_TAG}_pass_", suffix=".tmp", dir=str(DUMP_DIR), delete=False) as tf:
            tmp_file = tf.name

        with redirect_fds(stderr_path=tmp_file):
            pm.enable_verifier(kwargs.get("enable_verifier", False))
            pm.run(module.operation)

        try:
            text = Path(tmp_file).read_text(errors="ignore")
        except Exception:
            pass
    finally:
        if tmp_file:
            Path(tmp_file).unlink(missing_ok=True)

    # per-pass：split 后每段强制 genericize 再落盘
    try:
        _split_pass_text_to_files(text, context=_LAST_MLIR_CONTEXT)
    except Exception as _e:
        print(f"[WARN] split per-pass text failed: {_e}")

    if _ENV_ON:
        print("[INFO] COMPILE-ONLY mode: skip JIT & execution completely.")
        return _DummyJIT()

    try:
        return self.jit(module, opt_level=kwargs.get("opt_level", 2), shared_libs=kwargs.get("shared_libs", ()))
    except Exception as e:
        print(f"[ERROR] compile/jit failed: {e}")
        raise

def _patch_compiler_compile():
    try:
        import cutlass.base_dsl.compiler as _cbc
    except Exception as e:
        print(f"[WARN] import cutlass.base_dsl.compiler failed: {e}")
        return

    if getattr(_patch_compiler_compile, "_installed", False):
        return
    _cbc.Compiler.compile = compile_and_dump
    _patch_compiler_compile._installed = True
    print("[INFO] Patched Compiler.compile -> compile_and_dump")

# -------------------------
# 安装补丁（对外入口）
# -------------------------
def install(run_tag: str | None = None):
    global RUN_TAG, _INSTALLED
    global _SYS_STDOUT_ORIG, _SYS_STDERR_ORIG
    global _STD_LOG_F, _ERR_LOG_F, _STD_LOG_PATH, _ERR_LOG_PATH, _STD_SPLIT_TEE

    if _INSTALLED: return

    env_tag = os.getenv("CUTE_RUN_TAG", "").strip()
    RUN_TAG = (run_tag or (env_tag or None) or _infer_run_tag())
    _ensure_dump_dir()

    _SYS_STDOUT_ORIG, _SYS_STDERR_ORIG = sys.stdout, sys.stderr
    _STD_LOG_PATH = DUMP_DIR / f"{RUN_TAG}_stdout.log"
    _ERR_LOG_PATH = DUMP_DIR / f"{RUN_TAG}_stderr.log"

    _STD_LOG_F = open(_STD_LOG_PATH, "w")
    _ERR_LOG_F = open(_ERR_LOG_PATH, "w")

    mlir_out_path = DUMP_DIR / _stdout_ir_mlir_filename()
    _STD_SPLIT_TEE = SplitStdoutTee(_SYS_STDOUT_ORIG, _STD_LOG_F, mlir_out_path)
    sys.stdout = _STD_SPLIT_TEE
    sys.stderr = Tee(_SYS_STDERR_ORIG, _ERR_LOG_F)

    print(f"[INFO] Run tag: {RUN_TAG}")
    print(f"[INFO] Stdout mirrored to: {_STD_LOG_PATH}")
    print(f"[INFO] Stderr mirrored to: {_ERR_LOG_PATH}")
    print(f"[INFO] Stdout IR slice saved to: {mlir_out_path}")

    _patch_compiler_compile()
    _patch_cuda_runtime_for_compile_only()
    _patch_hardware_info_for_compile_only()

    _INSTALLED = True
    print("[INFO] cute_ir_dump_patch installed.")

def _run_target_script(argv):
    global _TARGET_FILE
    if len(argv) < 2:
        print("Usage: python -m cute_ir_dump_patch <your_script.py> [args...]")
        sys.exit(2)
    target = argv[1]
    _TARGET_FILE = Path(target).resolve()
    sys.argv = argv[1:]
    install()
    runpy.run_path(target, run_name="__main__")

@atexit.register
def _finalize_report():
    """
    进程退出时的清理与安全退出逻辑。
    额外：把 stdout IR slice 的 .mlir 强制重写成 generic form（去糖）。
    """
    global _STD_LOG_F, _ERR_LOG_F, _STD_SPLIT_TEE
    global _LAST_MLIR_CONTEXT

    # 1) Flush & drain
    try:
        if _STD_SPLIT_TEE:
            _STD_SPLIT_TEE.flush()
            _STD_SPLIT_TEE.drain()
        if _STD_LOG_F: _STD_LOG_F.flush()
        if _ERR_LOG_F: _ERR_LOG_F.flush()
        if _SYS_STDOUT_ORIG: _SYS_STDOUT_ORIG.flush()
        if _SYS_STDERR_ORIG: _SYS_STDERR_ORIG.flush()
    except Exception:
        pass

    # 2) 关闭 stdout tee 的 mlir 文件句柄（确保可被重写）
    try:
        if _STD_SPLIT_TEE:
            _STD_SPLIT_TEE.close()
    except Exception:
        pass

    # 3) stdout slice：文件级强制 genericize
    try:
        if DUMP_DIR and RUN_TAG:
            p = DUMP_DIR / _stdout_ir_mlir_filename()
            if p.exists():
                ok = _rewrite_file_generic(p, context=_LAST_MLIR_CONTEXT)
                if ok and _SYS_STDOUT_ORIG:
                    _SYS_STDOUT_ORIG.write(f"[DUMP] genericized stdout IR slice -> {p}\n")
                    _SYS_STDOUT_ORIG.flush()
    except Exception:
        pass

    # 4) 非 COMPILE-ONLY 才恢复 stdout/stderr 并关文件
    if not _ENV_ON:
        try:
            if _SYS_STDOUT_ORIG: sys.stdout = _SYS_STDOUT_ORIG
            if _SYS_STDERR_ORIG: sys.stderr = _SYS_STDERR_ORIG
            if _STD_LOG_F: _STD_LOG_F.close()
            if _ERR_LOG_F: _ERR_LOG_F.close()
        except Exception:
            pass

    # 5) COMPILE-ONLY 直接退出
    if _ENV_ON:
        os._exit(0)

if __name__ == "__main__":
    _run_target_script(sys.argv)

if _ENV_ON:
    try: install()
    except Exception as e: print(f"[WARN] AUTOINSTALL failed: {e}")