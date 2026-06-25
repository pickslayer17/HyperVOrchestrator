"""
HTTP/HTTPS proxy for Hyper-V VM.
Run on host, VM connects through it.
Symantec sees this as a normal application — no kernel-level filtering.
"""
import socket
import threading
import select
import sys

LISTEN_IP = "192.168.50.1"  # NATSwitch gateway — accessible from VM
LISTEN_PORT = 3128
BUFFER_SIZE = 65536


def handle_connect(client_sock, host, port):
    """HTTPS: tunnel via CONNECT"""
    try:
        remote_sock = socket.create_connection((host, port), timeout=10)
        client_sock.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")

        sockets = [client_sock, remote_sock]
        while True:
            readable, _, errors = select.select(sockets, [], sockets, 30)
            if errors:
                break
            for sock in readable:
                data = sock.recv(BUFFER_SIZE)
                if not data:
                    return
                if sock is client_sock:
                    remote_sock.sendall(data)
                else:
                    client_sock.sendall(data)
    except Exception as e:
        try:
            client_sock.sendall(f"HTTP/1.1 502 Bad Gateway\r\n\r\n{e}".encode())
        except:
            pass
    finally:
        try:
            remote_sock.close()
        except:
            pass


def handle_http(client_sock, method, url, version, header_rest):
    """HTTP: forward request"""
    try:
        # url = http://host:port/path
        if "://" in url:
            url_no_scheme = url.split("://", 1)[1]
        else:
            url_no_scheme = url

        if "/" in url_no_scheme:
            host_port, path = url_no_scheme.split("/", 1)
            path = "/" + path
        else:
            host_port = url_no_scheme
            path = "/"

        if ":" in host_port:
            host, port = host_port.split(":", 1)
            port = int(port)
        else:
            host = host_port
            port = 80

        remote_sock = socket.create_connection((host, port), timeout=10)
        request = f"{method} {path} {version}\r\n{header_rest}".encode()
        remote_sock.sendall(request)

        while True:
            data = remote_sock.recv(BUFFER_SIZE)
            if not data:
                break
            client_sock.sendall(data)

        remote_sock.close()
    except Exception as e:
        try:
            client_sock.sendall(f"HTTP/1.1 502 Bad Gateway\r\n\r\n{e}".encode())
        except:
            pass


def handle_client(client_sock):
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

        # Read rest of headers
        while b"\r\n\r\n" not in request:
            chunk = client_sock.recv(BUFFER_SIZE)
            if not chunk:
                break
            request += chunk

        header_rest = request.split(b"\r\n", 1)[1].decode()

        if method == "CONNECT":
            if ":" in url:
                host, port = url.split(":", 1)
                port = int(port)
            else:
                host = url
                port = 443
            handle_connect(client_sock, host, port)
        else:
            handle_http(client_sock, method, url, version, header_rest)
    except Exception as e:
        print(f"Error: {e}")
    finally:
        try:
            client_sock.close()
        except:
            pass


def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_IP, LISTEN_PORT))
    server.listen(50)
    print(f"Proxy listening on {LISTEN_IP}:{LISTEN_PORT}")

    while True:
        client_sock, addr = server.accept()
        print(f"Connection from {addr}")
        t = threading.Thread(target=handle_client, args=(client_sock,), daemon=True)
        t.start()


if __name__ == "__main__":
    main()