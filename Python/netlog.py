import os
import threading
import time

_LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "log")
_LOG_FILE = os.path.join(_LOG_DIR, "netagent.log")
_lock = threading.Lock()


def _stamp():
    t = time.time()
    lt = time.localtime(t)
    return time.strftime("%Y-%m-%d %H:%M:%S", lt) + f".{int((t % 1) * 1000):03d}"


def log(tag, msg):
    line = f"{_stamp()} [{tag}] {msg}"
    with _lock:
        os.makedirs(_LOG_DIR, exist_ok=True)
        with open(_LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
            f.flush()
    print(line, flush=True)
