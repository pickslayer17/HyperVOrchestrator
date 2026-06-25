import socket
import threading

LISTEN_IP = "0.0.0.0"
LISTEN_PORT = 13389
TARGET_IP = "192.168.50.2"
TARGET_PORT = 3389

def forward(src, dst):
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except:
        pass
    finally:
        src.close()
        dst.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_IP, LISTEN_PORT))
    server.listen(5)
    print(f"RDP forward: {LISTEN_IP}:{LISTEN_PORT} -> {TARGET_IP}:{TARGET_PORT}")
    while True:
        client, addr = server.accept()
        print(f"Connection from {addr}")
        try:
            remote = socket.create_connection((TARGET_IP, TARGET_PORT), timeout=10)
            threading.Thread(target=forward, args=(client, remote), daemon=True).start()
            threading.Thread(target=forward, args=(remote, client), daemon=True).start()
        except Exception as e:
            print(f"Failed: {e}")
            client.close()

if __name__ == "__main__":
    main()