import socket
import threading
import time

from netlog import log


class Watcher:
    def __init__(self, manager, interval=10, timeout=2):
        self.manager = manager
        self.interval = interval
        self.timeout = timeout
        self._thread = None
        self._running = False

    def start(self):
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()
        log("WATCH", f"watcher up (every {self.interval}s)")

    def stop(self):
        self._running = False

    def _loop(self):
        while self._running:
            time.sleep(self.interval)
            for m in self.manager.snapshot():
                if m.target_port is None:
                    continue
                if not self._alive(m.vmip, m.target_port):
                    log("WATCH", f"{m.vmip} not responding on {m.target_port}, removing")
                    self.manager.remove_machine(m.vmip)

    def _alive(self, ip, port):
        try:
            with socket.create_connection((ip, int(port)), timeout=self.timeout):
                return True
        except OSError:
            return False
