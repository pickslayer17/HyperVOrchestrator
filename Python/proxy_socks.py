import socket
import select
import struct

from netlog import log

BUFFER_SIZE = 65536
UDP_IDLE_TIMEOUT = 60

SOCKS_VERSION = 0x05
AUTH_NONE = 0x00
AUTH_NO_ACCEPTABLE = 0xFF
CMD_CONNECT = 0x01
CMD_UDP_ASSOCIATE = 0x03
ATYP_IPV4 = 0x01
ATYP_DOMAIN = 0x03
ATYP_IPV6 = 0x04
REPLY_SUCCESS = 0x00
REPLY_GENERAL_FAILURE = 0x01
REPLY_HOST_UNREACHABLE = 0x04
REPLY_COMMAND_NOT_SUPPORTED = 0x07


class SocksHandler:
    def __init__(self, on_activity=None):
        self.on_activity = on_activity

    def __call__(self, client_sock, addr):
        if self.on_activity:
            self.on_activity(addr[0])
        try:
            if not self._negotiate_auth(client_sock, addr):
                return
            cmd, atyp = self._read_request_head(client_sock, addr)
            if cmd is None:
                return
            if cmd == CMD_CONNECT:
                self._do_connect(client_sock, addr, atyp)
            elif cmd == CMD_UDP_ASSOCIATE:
                self._do_udp_associate(client_sock, addr, atyp)
            else:
                self._reply(client_sock, REPLY_COMMAND_NOT_SUPPORTED)
                log("SOCKS", f"{addr[0]} unsupported command {cmd}")
        except Exception as e:
            log("SOCKS", f"{addr[0]} error: {e}")
        finally:
            self._close(client_sock)

    def _negotiate_auth(self, client_sock, addr):
        header = self._recv_exact(client_sock, 2)
        if not header:
            return False
        version, nmethods = header[0], header[1]
        if version != SOCKS_VERSION:
            log("SOCKS", f"{addr[0]} bad version {version}")
            return False
        methods = self._recv_exact(client_sock, nmethods)
        if methods is None:
            return False
        if AUTH_NONE not in methods:
            client_sock.sendall(bytes([SOCKS_VERSION, AUTH_NO_ACCEPTABLE]))
            log("SOCKS", f"{addr[0]} no acceptable auth method")
            return False
        client_sock.sendall(bytes([SOCKS_VERSION, AUTH_NONE]))
        return True

    def _read_request_head(self, client_sock, addr):
        header = self._recv_exact(client_sock, 4)
        if not header:
            return None, None
        version, cmd, _, atyp = header[0], header[1], header[2], header[3]
        if version != SOCKS_VERSION:
            log("SOCKS", f"{addr[0]} bad request version {version}")
            return None, None
        return cmd, atyp

    def _do_connect(self, client_sock, addr, atyp):
        host = self._read_address(client_sock, atyp, addr)
        if host is None:
            self._reply(client_sock, REPLY_GENERAL_FAILURE)
            return
        port_bytes = self._recv_exact(client_sock, 2)
        if port_bytes is None:
            return
        port = struct.unpack("!H", port_bytes)[0]
        remote = None
        try:
            remote = socket.create_connection((host, port), timeout=10)
        except Exception as e:
            log("SOCKS", f"{addr[0]} connect -> {host}:{port} FAILED: {e}")
            self._reply(client_sock, REPLY_HOST_UNREACHABLE)
            return
        try:
            self._reply(client_sock, REPLY_SUCCESS)
            log("SOCKS", f"{addr[0]} tunnel -> {host}:{port} open")
            self._splice(client_sock, remote)
            log("SOCKS", f"{addr[0]} tunnel -> {host}:{port} closed")
        finally:
            self._close(remote)

    def _do_udp_associate(self, client_sock, addr, atyp):
        self._read_address(client_sock, atyp, addr)
        self._recv_exact(client_sock, 2)
        client_relay = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        out = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            bind_ip = client_sock.getsockname()[0]
            client_relay.bind((bind_ip, 0))
            relay_port = client_relay.getsockname()[1]
            self._reply_udp(client_sock, bind_ip, relay_port)
            log("SOCKS", f"{addr[0]} udp associate on {bind_ip}:{relay_port}")
            self._udp_loop(client_sock, client_relay, out, addr)
            log("SOCKS", f"{addr[0]} udp associate closed")
        finally:
            self._close(client_relay)
            self._close(out)

    def _udp_loop(self, client_sock, client_relay, out, addr):
        client_udp_addr = None
        while True:
            readable, _, errs = select.select([client_sock, client_relay, out], [], [], UDP_IDLE_TIMEOUT)
            if not readable:
                return
            if client_sock in readable:
                if not client_sock.recv(BUFFER_SIZE):
                    return
            if client_relay in readable:
                data, src = client_relay.recvfrom(BUFFER_SIZE)
                client_udp_addr = src
                self._from_client(out, data, addr)
            if out in readable:
                data, src = out.recvfrom(BUFFER_SIZE)
                if client_udp_addr:
                    self._to_client(client_relay, data, src, client_udp_addr)

    def _from_client(self, out, data, addr):
        dst_host, dst_port, payload = self._parse_udp_request(data)
        if dst_host is None:
            return
        try:
            out.sendto(payload, (dst_host, dst_port))
        except OSError as e:
            log("SOCKS", f"{addr[0]} udp send -> {dst_host}:{dst_port} FAILED: {e}")

    def _to_client(self, client_relay, data, src, client_udp_addr):
        header = bytes([0, 0, 0, ATYP_IPV4]) + socket.inet_aton(src[0]) + struct.pack("!H", src[1])
        try:
            client_relay.sendto(header + data, client_udp_addr)
        except OSError:
            pass

    def _parse_udp_request(self, data):
        if len(data) < 4:
            return None, None, None
        atyp = data[3]
        i = 4
        if atyp == ATYP_IPV4:
            if len(data) < i + 4:
                return None, None, None
            host = socket.inet_ntoa(data[i:i + 4])
            i += 4
        elif atyp == ATYP_IPV6:
            if len(data) < i + 16:
                return None, None, None
            host = socket.inet_ntop(socket.AF_INET6, data[i:i + 16])
            i += 16
        elif atyp == ATYP_DOMAIN:
            length = data[i]
            i += 1
            if len(data) < i + length:
                return None, None, None
            host = data[i:i + length].decode()
            i += length
        else:
            return None, None, None
        if len(data) < i + 2:
            return None, None, None
        port = struct.unpack("!H", data[i:i + 2])[0]
        return host, port, data[i + 2:]

    def _read_address(self, sock, atyp, addr):
        if atyp == ATYP_IPV4:
            raw = self._recv_exact(sock, 4)
            return socket.inet_ntoa(raw) if raw else None
        if atyp == ATYP_IPV6:
            raw = self._recv_exact(sock, 16)
            return socket.inet_ntop(socket.AF_INET6, raw) if raw else None
        if atyp == ATYP_DOMAIN:
            length = self._recv_exact(sock, 1)
            if not length:
                return None
            raw = self._recv_exact(sock, length[0])
            return raw.decode() if raw else None
        log("SOCKS", f"{addr[0]} bad address type {atyp}")
        return None

    def _reply(self, client_sock, code):
        try:
            client_sock.sendall(bytes([SOCKS_VERSION, code, 0x00, ATYP_IPV4, 0, 0, 0, 0, 0, 0]))
        except OSError:
            pass

    def _reply_udp(self, client_sock, bind_ip, bind_port):
        try:
            packed = socket.inet_aton(bind_ip)
            client_sock.sendall(bytes([SOCKS_VERSION, REPLY_SUCCESS, 0x00, ATYP_IPV4]) + packed + struct.pack("!H", bind_port))
        except OSError:
            pass

    def _recv_exact(self, sock, count):
        buf = b""
        while len(buf) < count:
            chunk = sock.recv(count - len(buf))
            if not chunk:
                return None
            buf += chunk
        return buf

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

    def _close(self, sock):
        if sock:
            try:
                sock.close()
            except OSError:
                pass
