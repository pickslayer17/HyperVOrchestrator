import socket
import threading

from netlog import log

BUFFER_SIZE = 65536


class ForwardHandler:
    def __init__(self, target_ip, target_port):
        self.target_ip = target_ip
        self.target_port = int(target_port)

    def __call__(self, client_sock, addr):
        try:
            remote = socket.create_connection((self.target_ip, self.target_port), timeout=10)
            log("FWD", f"{addr[0]} -> {self.target_ip}:{self.target_port} open")
        except Exception as e:
            log("FWD", f"{addr[0]} -> {self.target_ip}:{self.target_port} FAILED: {e}")
            self._close(client_sock)
            return
        threading.Thread(target=self._pump, args=(client_sock, remote), daemon=True).start()
        threading.Thread(target=self._pump, args=(remote, client_sock), daemon=True).start()

    def _pump(self, src, dst):
        try:
            while True:
                data = src.recv(BUFFER_SIZE)
                if not data:
                    break
                dst.sendall(data)
        except OSError:
            pass
        finally:
            self._close(src)
            self._close(dst)

    def _close(self, sock):
        try:
            sock.close()
        except OSError:
            pass
