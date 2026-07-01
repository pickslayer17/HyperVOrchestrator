import socket
import threading

from netlog import log


class Listener:
    def __init__(self, bind_ip, port, handler, name="listener"):
        self.bind_ip = bind_ip
        self.port = int(port)
        self.handler = handler
        self.name = name
        self._sock = None
        self._thread = None
        self._running = False

    def start(self):
        try:
            self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self._sock.bind((self.bind_ip, self.port))
            self._sock.listen(50)
        except OSError as e:
            log("LISTEN", f"{self.name} BIND FAILED {self.bind_ip}:{self.port} -> {e}")
            raise
        self._running = True
        self._thread = threading.Thread(target=self._accept_loop, daemon=True)
        self._thread.start()
        log("LISTEN", f"{self.name} up on {self.bind_ip}:{self.port}")

    def _accept_loop(self):
        while self._running:
            try:
                client, addr = self._sock.accept()
            except OSError:
                break
            log("ACCEPT", f"{self.name} conn from {addr[0]}:{addr[1]}")
            threading.Thread(target=self._run_handler, args=(client, addr), daemon=True).start()

    def _run_handler(self, client, addr):
        try:
            self.handler(client, addr)
        except Exception as e:
            log("HANDLER", f"{self.name} error from {addr[0]}: {e}")

    def stop(self):
        self._running = False
        if self._sock:
            try:
                self._sock.close()
            except OSError:
                pass
            self._sock = None
        log("LISTEN", f"{self.name} stopped on {self.bind_ip}:{self.port}")
