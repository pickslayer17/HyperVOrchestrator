import socket
import threading


class Listener:
    def __init__(self, bind_ip, port, handler):
        self.bind_ip = bind_ip
        self.port = int(port)
        self.handler = handler
        self._sock = None
        self._thread = None
        self._running = False

    def start(self):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.bind((self.bind_ip, self.port))
        self._sock.listen(50)
        self._running = True
        self._thread = threading.Thread(target=self._accept_loop, daemon=True)
        self._thread.start()
        print(f"listen {self.bind_ip}:{self.port}")

    def _accept_loop(self):
        while self._running:
            try:
                client, addr = self._sock.accept()
            except OSError:
                break
            threading.Thread(target=self.handler, args=(client, addr), daemon=True).start()

    def stop(self):
        self._running = False
        if self._sock:
            try:
                self._sock.close()
            except OSError:
                pass
            self._sock = None
