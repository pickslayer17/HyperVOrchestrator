import socket
import select
import threading
import ctypes
from ctypes import wintypes

from netlog import log

BUFFER_SIZE = 65536
UPSTREAM_TIMEOUT = 5


class DnsForwarder:
    def __init__(self, bind_ip, port, upstream=None):
        self.bind_ip = bind_ip
        self.port = int(port)
        self.upstream = upstream or self._discover_upstream()
        self._sock = None
        self._thread = None
        self._running = False

    def start(self):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.bind((self.bind_ip, self.port))
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()
        log("DNSFWD", f"up on {self.bind_ip}:{self.port} -> {self.upstream}:53")

    def _loop(self):
        while self._running:
            try:
                readable, _, _ = select.select([self._sock], [], [], 1)
                if not readable:
                    continue
                data, client = self._sock.recvfrom(BUFFER_SIZE)
            except OSError:
                break
            threading.Thread(target=self._resolve, args=(data, client), daemon=True).start()

    def _resolve(self, data, client):
        up = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        up.settimeout(UPSTREAM_TIMEOUT)
        try:
            up.sendto(data, (self.upstream, 53))
            answer, _ = up.recvfrom(BUFFER_SIZE)
            self._sock.sendto(answer, client)
        except OSError as e:
            log("DNSFWD", f"{client[0]} resolve FAILED via {self.upstream}: {e}")
        finally:
            up.close()

    def stop(self):
        self._running = False
        if self._sock:
            try:
                self._sock.close()
            except OSError:
                pass
            self._sock = None
        log("DNSFWD", f"stopped on {self.bind_ip}:{self.port}")

    def _discover_upstream(self):
        try:
            return self._query_os_dns()
        except Exception as e:
            log("DNSFWD", f"discover upstream FAILED: {e}")
            raise

    def _query_os_dns(self):
        DNS_CONFIG_DNS_SERVER_LIST = 6
        buf_len = wintypes.DWORD(0)
        dnsapi = ctypes.windll.dnsapi
        dnsapi.DnsQueryConfig(DNS_CONFIG_DNS_SERVER_LIST, 0, None, None, None, ctypes.byref(buf_len))
        if buf_len.value == 0:
            raise RuntimeError("DnsQueryConfig returned empty server list")

        buf = (ctypes.c_byte * buf_len.value)()
        rc = dnsapi.DnsQueryConfig(DNS_CONFIG_DNS_SERVER_LIST, 0, None, None, buf, ctypes.byref(buf_len))
        if rc != 0:
            raise RuntimeError(f"DnsQueryConfig failed with code {rc}")

        count = ctypes.cast(buf, ctypes.POINTER(wintypes.DWORD))[0]
        if count == 0:
            raise RuntimeError("no DNS servers reported by OS")

        addr = ctypes.cast(buf, ctypes.POINTER(wintypes.DWORD))[1]
        return socket.inet_ntoa(addr.to_bytes(4, "little"))
