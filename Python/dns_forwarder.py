import socket
import select
import threading
import subprocess

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
        ps = (
            "Get-DnsClientServerAddress -AddressFamily IPv4 | "
            "Where-Object { $_.ServerAddresses.Count -gt 0 -and $_.InterfaceAlias -notlike '*Loopback*' } | "
            "Select-Object -ExpandProperty ServerAddresses -First 1"
        )
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps],
            capture_output=True, text=True, timeout=15,
        )
        upstream = result.stdout.strip().splitlines()[0].strip()
        if not upstream:
            raise RuntimeError("could not discover host DNS server")
        return upstream
