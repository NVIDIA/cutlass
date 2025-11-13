# -*- coding: utf-8 -*-
"""
cute_ir_dump_patch.py（单环境变量总开关版 - 修复版）
- 只有一个环境变量：CUTE_DSL_ON
  * 未开启时：仍可通过 `python -m cute_ir_dump_patch your_script.py ...` 运行包装脚本，
    但不会启用“只编译/跳驱动/NOOP launch”这些强力补丁。
- 一直保留：
  * Python 层 stdout/stderr 分别镜像到 {RUN_TAG}_stdout.log / {RUN_TAG}_stderr.log
  * 逐 pass IR 拆分（stderr 中的 MLIR pass After 段），默认开启
"""

from __future__ import annotations
import os
import re
import atexit
import sys
import shlex
import runpy
import tempfile
import datetime as dt
from pathlib import Path
from contextlib import contextmanager
from collections import Counter

# 单一总开关
_ENV_ON = str(os.getenv("CUTE_DSL_ON", "")).strip().lower() not in ("", "0", "false", "no")

# 默认关掉 CUTE 的文件/编译缓存，确保能触发编译与 IR 生成（内部默认即可，非用户开关）
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

_TARGET_FILE: Path | None = None   # -m 入口记录目标脚本路径
_STD_SPLIT_TEE = None

# stdout IR 片段标记与输出文件名
STDOUT_IR_START = "//===--- ------ Generated IR ------ ---===="
STDOUT_IR_END   = "//===--- --- End of Generated IR -- ---===="
def _stdout_ir_mlir_filename() -> str:
    """基于 RUN_TAG（或推断）生成 stdout IR 片段的 .mlir 文件名。"""
    tag = RUN_TAG or _infer_run_tag()
    return f"{tag}_0_with_loc.mlir"

def _now():
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def _sanitize_for_fs(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", s)

def _infer_run_tag() -> str:
    target = None
    if _TARGET_FILE:
        target = str(_TARGET_FILE)
    else:
        # 1) pytest 提示：tests/path/test_cross_entropy.py::test_xxx (nodeid)
        pt = os.getenv("PYTEST_CURRENT_TEST", "")
        if pt:
            target = pt.split("::", 1)[0]

    if not target:
        # 2) 回退：从调用栈找第一个用户代码文件
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
        # 3) 再回退到 __main__.__file__ / sys.argv[0] 旧逻辑…
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
        # 输出目录使用当前运行脚本的 stem，例如 tensorop_gemm.py -> ./tensorop_gemm
        stem = _infer_run_tag()  # 已做过文件名安全化，可能是 "tensorop_gemm" 或 "interactive"
        DUMP_DIR = Path(f"./{stem}").resolve()
        DUMP_DIR.mkdir(parents=True, exist_ok=True)

class Tee:
    def __init__(self, *streams): self.streams = streams
    def write(self, data):
        for s in self.streams:
            s.write(data); s.flush()
    def flush(self):
        for s in self.streams: s.flush()

class SplitStdoutTee:
    """
    将 stdout 同时输出到终端与两个文件：
      - 主 stdout 日志（不含 IR 片段）
      - 标记之间的 IR 片段写到单独 .mlir（可通过 CUTE_DSL_STDOUT_IR_CAPTURE 关闭）
    """
    def __init__(self, console_stream, stdout_file_stream, mlir_path: Path):
        self.console = console_stream
        self.out = stdout_file_stream
        self.mlir_path = Path(mlir_path)
        self.mlir_f = None
        self.buf = ""            # 跨 write() 粘连标记
        self.capturing = False
        self.start = STDOUT_IR_START
        self.end = STDOUT_IR_END
        self._safe_tail_keep_normal = max(0, len(self.start) - 1)
        self._safe_tail_keep_capture = max(0, len(self.end) - 1)

    def _ensure_mlir_open(self):
        if self.mlir_f is None:
            self.mlir_f = open(self.mlir_path, "w", buffering=1)

    def write(self, data):
        # 终端实时完整
        self.console.write(data); self.console.flush()
        # 解析分流
        self.buf += data
        while True:
            if not self.capturing:
                idx = self.buf.find(self.start)
                if idx == -1:
                    safe_len = max(0, len(self.buf) - self._safe_tail_keep_normal)
                    if safe_len > 0:
                        self.out.write(self.buf[:safe_len]); self.out.flush()
                        self.buf = self.buf[safe_len:]
                    break
                else:
                    pre = self.buf[:idx]
                    if pre:
                        self.out.write(pre); self.out.flush()
                    self.buf = self.buf[idx + len(self.start):]
                    self.capturing = True
                    self._ensure_mlir_open()
            else:
                idx2 = self.buf.find(self.end)
                if idx2 == -1:
                    safe_len = max(0, len(self.buf) - self._safe_tail_keep_capture)
                    if safe_len > 0:
                        if self.mlir_f:
                            self.mlir_f.write(self.buf[:safe_len]); self.mlir_f.flush()
                        self.buf = self.buf[safe_len:]
                    break
                else:
                    seg = self.buf[:idx2]
                    if seg and self.mlir_f:
                        self.mlir_f.write(seg); self.mlir_f.flush()
                    self.buf = self.buf[idx2 + len(self.end):]
                    self.capturing = False
        return len(data)

    def flush(self):
        self.console.flush(); self.out.flush()
        if self.mlir_f: self.mlir_f.flush()

    def drain(self):
        if not self.buf:
            return
        if self.capturing:
            self._ensure_mlir_open()
            if self.mlir_f:
                self.mlir_f.write(self.buf); self.mlir_f.flush()
        else:
            self.out.write(self.buf); self.out.flush()
        self.buf = ""

    def close(self):
        self.drain()
        try:
            if self.mlir_f: self.mlir_f.close()
        except Exception:
            pass

@contextmanager
def redirect_fds(stdout_path=None, stderr_path=None):
    """把进程级 fd=1/2 重定向到文件（抓住 C/LLVM 层输出，如 MLIR pass 打印）。"""
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
        f_out and f_out.close(); f_err and f_err.close()

def _op_to_text(module_or_op) -> str:
    op = getattr(module_or_op, "operation", module_or_op)
    try:
        return op.get_asm(large_elements_limit=2**31)
    except Exception:
        return str(op)

def _save_text(tag: str, content: str, suffix="txt") -> str:
    """统一命名：{RUN_TAG}_{tag}.{suffix}"""
    _ensure_dump_dir()
    name = f"{RUN_TAG}_{tag}.{suffix}"
    fn = DUMP_DIR / name
    fn.write_text(content)
    print(f"[DUMP] {tag} -> {fn} ({content.count(os.linesep)+1} lines)")
    return str(fn)

def _save_ir(tag, module_or_op) -> str:
    return _save_text(tag, _op_to_text(module_or_op), "mlir")

def _dialect_histogram(mlir_text: str):
    cnt = Counter(m.group(1) for m in re.finditer(r"(\w+)\.", mlir_text))
    return dict(sorted(cnt.items(), key=lambda x: (-x[1], x[0])))

# -------------------------
# 逐 pass 拆分（stderr 文本）
# -------------------------
def _split_pass_text_to_files(text: str) -> list[str]:
    """
    解析逐 pass 的 stderr 文本，把每个 `After` 段落写成独立 .mlir 文件。
    仅支持标记样式（单行）：
      // -----// IR Dump After <PrettyName> (<pass-id>) //----- //
    """
    lines = text.splitlines()
    re_marker = re.compile(
        r"""^\s*//\s*-{2,}\s*//\s*IR\s+Dump\s+After\s+([^(]+?)\s*\(([^)]*)\)\s*//\s*-{2,}\s*//\s*$"""
    )
    sections, cur_name, buf = [], None, []

    def flush():
        nonlocal buf, cur_name
        if cur_name and buf:
            mlir_txt = "\n".join(buf).strip() + "\n"
            sections.append((cur_name, mlir_txt))
        buf = []

    for line in lines:
        m = re_marker.match(line)
        if m:
            flush()
            cur_name = m.group(1).strip()
            continue
        if cur_name is not None:
            buf.append(line)
    flush()

    out_files = []
    for idx, (pretty_name, mlir_txt) in enumerate(sections, start=1):
        tag = f"{idx:03d}_{_sanitize_for_fs(pretty_name)}"
        out_files.append(_save_text(tag, mlir_txt, "mlir"))

    if not out_files and text.strip():
        out_files.append(_save_text("pass_dump_unparsed", text, "txt"))
        print("[WARN] per-pass markers not detected; wrote raw dump as TXT.")
    print(f"[DUMP] per-pass IR split -> {len(out_files)} files")
    return out_files

# -------------------------
# 只编译不运行：JIT/执行兜底
# -------------------------
class _DummyJIT:
    def __getattr__(self, name):
        def _noop(*args, **kwargs):
            print(f"[NOEXEC] {name} called in COMPILE-ONLY mode; ignored.")
            return None
        return _noop

def _flatten_pipeline_text(pipeline_txt: str):
    names, token, depth = [], "", 0
    for ch in pipeline_txt:
        if ch == '(':
            if token.strip(): names.append(token.strip()); token = ""
            depth += 1
        elif ch == ')':
            if token.strip(): names.append(token.strip()); token = ""
            depth -= 1
        elif ch == ',':
            if token.strip(): names.append(token.strip()); token = ""
        else:
            token += ch
    cleaned = [n for n in names if n and not n.endswith(".module") and not n.endswith(".func")]
    cleaned = [re.split(r"\{|=", n)[0].strip() for n in cleaned]
    return [n for n in cleaned if n]

# -------------------------
# 核心：补丁 Compiler.compile（dump IR + 逐 pass 拆分）
# -------------------------
def compile_and_dump(self, module, pipeline, *args, **kwargs):
    print("[PATCH] hit Compiler.compile")

    # BEFORE（保留“0_”快照）
    before_file = _save_ir("0_", module)

    # 自建 PassManager 跑 pipeline
    pm = self.passmanager.PassManager.parse(pipeline)

    # 打印 After 片段（支持不同 API）
    try:
        pm.enable_ir_printing(print_after_only=True)
    except TypeError:
        try:
            pm.enable_ir_printing()
        except Exception:
            try:
                pm.print_ir_after_all(True)
            except Exception:
                pass

    # 跑 pipeline，并收集 per-pass 文本（重定向 stderr 到临时文件）
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
        except Exception as _e:
            print("[WARN] read temp pass stderr failed:", repr(_e))
    finally:
        if tmp_file:
            try:
                Path(tmp_file).unlink(missing_ok=True)
            except Exception:
                pass

    # 按 pass 写出 .mlir
    try:
        _split_pass_text_to_files(text)
    except Exception as _e:
        print("[WARN] split per-pass text failed:", repr(_e))

    # 只编译模式：直接返回 DummyJIT
    if _ENV_ON:
        print("[INFO] COMPILE-ONLY mode: skip JIT & execution completely.")
        return _DummyJIT()

    # 非 COMPILE-ONLY：正常 JIT
    try:
        ret = self.jit(
            module,
            opt_level=kwargs.get("opt_level", 2),
            shared_libs=kwargs.get("shared_libs", ()),
        )
    except Exception as e:
        print("[ERROR] compile/jit failed:", repr(e))
        raise
    return ret

def _patch_compiler_compile():
    try:
        import cutlass.base_dsl.compiler as _cbc
    except Exception as e:
        print("[WARN] import cutlass.base_dsl.compiler failed:", repr(e)); return
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

    if _INSTALLED:
        return

    env_tag = os.getenv("CUTE_RUN_TAG", "").strip()
    RUN_TAG = (run_tag or (env_tag or None) or _infer_run_tag())
    _ensure_dump_dir()

    # Tee stdout/stderr；stdout 额外做“Generated IR”片段切分（可关）
    _SYS_STDOUT_ORIG, _SYS_STDERR_ORIG = sys.stdout, sys.stderr
    _STD_LOG_PATH = DUMP_DIR / f"{RUN_TAG}_stdout.log"
    _ERR_LOG_PATH = DUMP_DIR / f"{RUN_TAG}_stderr.log"
    _STD_LOG_F = open(_STD_LOG_PATH, "w", buffering=1)
    _ERR_LOG_F = open(_ERR_LOG_PATH, "w", buffering=1)

    mlir_out_path = DUMP_DIR / _stdout_ir_mlir_filename()
    _STD_SPLIT_TEE = SplitStdoutTee(_SYS_STDOUT_ORIG, _STD_LOG_F, mlir_out_path)
    sys.stdout = _STD_SPLIT_TEE
    sys.stderr = Tee(_SYS_STDERR_ORIG, _ERR_LOG_F)

    print(f"[INFO] Run tag: {RUN_TAG}")
    print(f"[INFO] Stdout is mirrored to (IR片段不包含在内): {_STD_LOG_PATH}")
    print(f"[INFO] Stderr is mirrored to: {_ERR_LOG_PATH}")
    print(f"[INFO] Stdout IR slice will be saved to: {mlir_out_path}")

    # 安装核心编译补丁
    _patch_compiler_compile()

    _INSTALLED = True
    print("[INFO] cute_ir_dump_patch installed.")

# -------------------------
# 模块方式运行：python -m cute_ir_dump_patch your_script.py ...
# -------------------------
def _run_target_script(argv):
    global _TARGET_FILE
    if len(argv) < 2:
        print("Usage: python -m cute_ir_dump_patch <your_script.py> [args...]")
        sys.exit(2)
    target = argv[1]
    _TARGET_FILE = Path(target).resolve()
    # 让目标脚本看到自己的 argv
    sys.argv = argv[1:]
    install()
    runpy.run_path(target, run_name="__main__")

@atexit.register
def _finalize_report():
    global _STD_LOG_F, _ERR_LOG_F, _STD_SPLIT_TEE
    try:
        if _STD_SPLIT_TEE:
            try:
                _STD_SPLIT_TEE.close()
            except Exception:
                pass
        if _SYS_STDOUT_ORIG: sys.stdout = _SYS_STDOUT_ORIG
        if _SYS_STDERR_ORIG: sys.stderr = _SYS_STDERR_ORIG
        if _STD_LOG_F: _STD_LOG_F.close()
        if _ERR_LOG_F: _ERR_LOG_F.close()
    except Exception:
        pass

if __name__ == "__main__":
    _run_target_script(sys.argv)

# import 即自动安装（由单一总开关控制）
if _ENV_ON:
    try:
        install()
    except Exception as e:
        print("[WARN] AUTOINSTALL failed:", repr(e))
