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

        t1 = threading.Thread(target=self._pipe, args=(client_sock, remote), daemon=True)
        t2 = threading.Thread(target=self._pipe, args=(remote, client_sock), daemon=True)
        t1.start()
        t2.start()
        t1.join()
        t2.join()
        self._close(client_sock)
        self._close(remote)
        log("FWD", f"{addr[0]} -> {self.target_ip}:{self.target_port} closed")

    def _pipe(self, src, dst):
        try:
            while True:
                data = src.recv(BUFFER_SIZE)
                if not data:
                    break
                dst.sendall(data)
        except OSError:
            pass
        finally:
            try:
                dst.shutdown(socket.SHUT_WR)
            except OSError:
                pass

    def _close(self, sock):
        try:
            sock.close()
        except OSError:
            pass
