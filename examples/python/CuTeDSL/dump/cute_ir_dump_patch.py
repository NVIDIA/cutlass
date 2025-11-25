# -*- coding: utf-8 -*-
"""
cute_ir_dump_patch.py（单环境变量总开关版）
- 只有一个环境变量：CUTE_DSL_ON
  * 未开启时：仍可通过 `python -m cute_ir_dump_patch your_script.py ...` 运行包装脚本，
    但不会启用"只编译/跳驱动/NOOP launch"这些强力补丁。
  * 开启时（CUTE_DSL_ON=1）：启用 COMPILE-ONLY 模式
    - 跳过 JIT 和执行，只进行编译
    - 跳过 CUDA 内核加载，避免架构兼容性检查
    - 允许编译不同架构的代码（如 sm_100a, sm_120）即使当前 GPU 不支持
    - Mock HardwareInfo.get_max_active_clusters 防止脚本计算 Occupancy 时崩溃

- 一直保留：
  * Python 层 stdout/stderr 分别镜像到 {RUN_TAG}_stdout.log / {RUN_TAG}_stderr.log
  * 逐 pass IR 拆分（stderr 中的 MLIR pass After 段），默认开启

使用示例（编译不同架构的代码）：
  CUTE_DSL_ON=1 python examples/python/CuTeDSL/blackwell/dense_gemm.py --help
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
            self.mlir_f = open(self.mlir_path, "w")  # Default buffering

    def write(self, data):
        # Removed aggressive flush() for performance
        self.console.write(data)
        self.buf += data
        while True:
            if not self.capturing:
                idx = self.buf.find(self.start)
                if idx == -1:
                    safe_len = max(0, len(self.buf) - self._safe_tail_keep_normal)
                    if safe_len > 0:
                        self.out.write(self.buf[:safe_len])
                        self.buf = self.buf[safe_len:]
                    break
                else:
                    pre = self.buf[:idx]
                    if pre:
                        self.out.write(pre)
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
                        self.buf = self.buf[safe_len:]
                    break
                else:
                    seg = self.buf[:idx2]
                    if seg and self.mlir_f:
                        self.mlir_f.write(seg)
                    self.buf = self.buf[idx2 + len(self.end):]
                    self.capturing = False
        return len(data)

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

def _op_to_text(module_or_op) -> str:
    op = getattr(module_or_op, "operation", module_or_op)
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

def _split_pass_text_to_files(text: str) -> list[str]:
    # Simplified and optimized using regex split instead of line-by-line iteration
    if not text.strip():
        return []

    # Matches markers: //----- // IR Dump After <name> (<arg>) //----- //
    # Captures: 1=name, 2=arg
    pat = re.compile(
        r"^\s*//\s*-{2,}\s*//\s*IR\s+Dump\s+After\s+([^(]+?)\s*\(([^)]*)\)\s*//\s*-{2,}\s*//\s*$",
        re.MULTILINE
    )
    parts = pat.split(text)
    
    # parts format: [pre_text, name1, arg1, content1, name2, arg2, content2, ...]
    out_files = []
    if len(parts) < 4:
        out_files.append(_save_text("pass_dump_unparsed", text, "txt"))
        print("[WARN] per-pass markers not detected; wrote raw dump as TXT.")
    else:
        for i in range(1, len(parts), 3):
            pass_name = parts[i].strip()
            # parts[i+1] is arg, currently unused
            content = parts[i+2].strip() + "\n"
            
            idx = (i // 3) + 1
            tag = f"{idx:03d}_{_sanitize_for_fs(pass_name)}"
            out_files.append(_save_text(tag, content, "mlir"))
            
    print(f"[DUMP] per-pass IR split -> {len(out_files)} files")
    return out_files

# -------------------------
# 只编译不运行：JIT/执行兜底
# -------------------------
class _DummyJIT:
    def __getattr__(self, name):
        return lambda *a, **kw: print(f"[NOEXEC] {name} called in COMPILE-ONLY mode; ignored.")

# -------------------------
# 只编译模式：跳过架构兼容性检查
# -------------------------
def _get_result_payload(result):
    """Helper to extract payload from potential (status, payload) tuple"""
    if isinstance(result, (tuple, list)):
        if len(result) <= 1: return None
        elif len(result) == 2: return result[1]
        else: return result[1:]
    return None

def _checkCudaErrors_compile_only(result):
    # Handle specific error code extraction if it's an object with .value
    first = result[0] if isinstance(result, (tuple, list)) and len(result) > 0 else result
    error_code = getattr(first, "value", first)

    if error_code == 209: # CUDA_ERROR_NO_BINARY_FOR_GPU
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
        # Mock get_max_active_clusters to always return 1
        _hwi.HardwareInfo.get_max_active_clusters = lambda self, *args, **kwargs: 1
        print("[INFO] Patched HardwareInfo.get_max_active_clusters for COMPILE-ONLY mode")

# -------------------------
# 核心：补丁 Compiler.compile
# -------------------------
def compile_and_dump(self, module, pipeline, *args, **kwargs):
    print("[PATCH] hit Compiler.compile")
    _save_ir("0_", module)
    
    pm = self.passmanager.PassManager.parse(pipeline)
    
    # Try various methods to enable IR printing
    for method in ["enable_ir_printing", "print_ir_after_all"]:
        try:
            attr = getattr(pm, method)
            # Try calling with print_after_only=True if it's enable_ir_printing
            if method == "enable_ir_printing":
                try: attr(print_after_only=True)
                except TypeError: attr()
            else:
                attr(True)
            break
        except Exception:
            continue

    tmp_file = None
    text = ""
    try:
        _ensure_dump_dir()
        # Use default temp file handling
        with tempfile.NamedTemporaryFile(prefix=f"{RUN_TAG}_pass_", suffix=".tmp", dir=str(DUMP_DIR), delete=False) as tf:
            tmp_file = tf.name
        
        with redirect_fds(stderr_path=tmp_file):
            pm.enable_verifier(kwargs.get("enable_verifier", False))
            pm.run(module.operation)
            
        try: text = Path(tmp_file).read_text(errors="ignore")
        except Exception: pass
    finally:
        if tmp_file: Path(tmp_file).unlink(missing_ok=True)

    try: _split_pass_text_to_files(text)
    except Exception as _e: print(f"[WARN] split per-pass text failed: {_e}")

    if _ENV_ON:
        print("[INFO] COMPILE-ONLY mode: skip JIT & execution completely.")
        return _DummyJIT()

    try:
        return self.jit(module, opt_level=kwargs.get("opt_level", 2), shared_libs=kwargs.get("shared_libs", ()))
    except Exception as e:
        print(f"[ERROR] compile/jit failed: {e}")
        raise

def _patch_compiler_compile():
    try: import cutlass.base_dsl.compiler as _cbc
    except Exception as e: print(f"[WARN] import cutlass.base_dsl.compiler failed: {e}"); return
    
    if getattr(_patch_compiler_compile, "_installed", False): return
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
    
    # Use default buffering for performance (not 1=line buffered)
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
    """
    global _STD_LOG_F, _ERR_LOG_F, _STD_SPLIT_TEE
    
    # 1. 极其激进的 Flush，确保日志落盘
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

    # 2. 只有在非 COMPILE-ONLY 模式下，才尝试还原 stdout
    if not _ENV_ON:
        try:
            if _SYS_STDOUT_ORIG: sys.stdout = _SYS_STDOUT_ORIG
            if _SYS_STDERR_ORIG: sys.stderr = _SYS_STDERR_ORIG
            if _STD_SPLIT_TEE: _STD_SPLIT_TEE.close()
            if _STD_LOG_F: _STD_LOG_F.close()
            if _ERR_LOG_F: _ERR_LOG_F.close()
        except Exception:
            pass

    # 3. [核选项] COMPILE-ONLY 模式下，直接调用 os._exit(0)
    if _ENV_ON:
        os._exit(0)

if __name__ == "__main__":
    _run_target_script(sys.argv)

if _ENV_ON:
    try: install()
    except Exception as e: print(f"[WARN] AUTOINSTALL failed: {e}")