import socket
import select

BUFFER_SIZE = 65536


class ProxyHandler:
    def __init__(self, on_activity=None):
        self.on_activity = on_activity

    def __call__(self, client_sock, addr):
        if self.on_activity:
            self.on_activity(addr[0])
        try:
            request = b""
            while b"\r\n" not in request:
                chunk = client_sock.recv(BUFFER_SIZE)
                if not chunk:
                    return
                request += chunk

            first_line = request.split(b"\r\n")[0].decode()
            parts = first_line.split()
            if len(parts) < 3:
                return
            method, url, version = parts[0], parts[1], parts[2]
            print(f"[{method}] {url}")

            while b"\r\n\r\n" not in request:
                chunk = client_sock.recv(BUFFER_SIZE)
                if not chunk:
                    break
                request += chunk
            header_rest = request.split(b"\r\n", 1)[1].decode()

            if method == "CONNECT":
                host, port = self._split_hostport(url, 443)
                self._connect(client_sock, host, port)
            else:
                self._http(client_sock, method, url, version, header_rest)
        except Exception:
            pass
        finally:
            try:
                client_sock.close()
            except OSError:
                pass

    def _split_hostport(self, hostport, default_port):
        if ":" in hostport:
            h, p = hostport.split(":", 1)
            return h, int(p)
        return hostport, default_port

    def _connect(self, client_sock, host, port):
        remote = None
        try:
            remote = socket.create_connection((host, port), timeout=10)
            client_sock.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            self._splice(client_sock, remote)
        except Exception:
            self._bad_gateway(client_sock)
        finally:
            self._close(remote)

    def _http(self, client_sock, method, url, version, header_rest):
        remote = None
        try:
            no_scheme = url.split("://", 1)[1] if "://" in url else url
            if "/" in no_scheme:
                hostport, path = no_scheme.split("/", 1)
                path = "/" + path
            else:
                hostport, path = no_scheme, "/"
            host, port = self._split_hostport(hostport, 80)

            remote = socket.create_connection((host, port), timeout=10)
            remote.sendall(f"{method} {path} {version}\r\n{header_rest}".encode())
            while True:
                data = remote.recv(BUFFER_SIZE)
                if not data:
                    break
                client_sock.sendall(data)
        except Exception:
            self._bad_gateway(client_sock)
        finally:
            self._close(remote)

    def _splice(self, a, b):
        socks = [a, b]
        while True:
            readable, _, errs = select.select(socks, [], socks, 30)
            if errs:
                break
            for s in readable:
                data = s.recv(BUFFER_SIZE)
                if not data:
                    return
                (b if s is a else a).sendall(data)

    def _bad_gateway(self, client_sock):
        try:
            client_sock.sendall(b"HTTP/1.1 502 Bad Gateway\r\n\r\n")
        except OSError:
            pass

    def _close(self, sock):
        if sock:
            try:
                sock.close()
            except OSError:
                pass
