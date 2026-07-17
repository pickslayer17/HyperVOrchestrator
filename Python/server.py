import sys
import os
import time
import threading
import subprocess
from multiprocessing.connection import Listener as IpcListener, Client

from manager import Manager
from netlog import log

IPC_ADDR = ("127.0.0.1", 47653)

DETACHED_PROCESS = 0x00000008
CREATE_NEW_PROCESS_GROUP = 0x00000200

HELP = """hyperv-netagent - commands:
  start
  stop
  start_proxy      -ip <ip> -port <port>
  start_fwd        -ip <bindIp> -port <listenPort> -targetip <ip> -targetport <port>
  start_dns        -ip <bindIp> -port <listenPort> [-upstream <dnsIp>]
  get_connections
  is_alive
  help"""


def parse(argv):
    if not argv:
        return None, {}
    cmd = argv[0].lower()
    opts = {}
    i = 1
    while i < len(argv):
        token = argv[i]
        if token.startswith("-"):
            key = token.lstrip("-").lower()
            has_val = i + 1 < len(argv) and not argv[i + 1].startswith("-")
            opts[key] = argv[i + 1] if has_val else True
            i += 2 if has_val else 1
        else:
            i += 1
    return cmd, opts


def apply(manager, cmd, opts):
    log("CMD", f"{cmd} {opts}")
    if cmd == "start_proxy":
        manager.start_proxy(opts["ip"], opts["port"])
        return "ok"
    if cmd == "start_fwd":
        manager.start_fwd(opts["ip"], opts["port"], opts["targetip"], opts["targetport"])
        return "ok"
    if cmd == "start_dns":
        manager.start_dns_fwd(opts["ip"], opts["port"], opts.get("upstream") if opts.get("upstream") is not True else None)
        return "ok"
    if cmd == "get_connections":
        return manager.get_connections()
    raise ValueError(f"unknown command: {cmd}")


def command_loop(ipc, manager, stop_event):
    while True:
        try:
            conn = ipc.accept()
        except OSError:
            break
        try:
            cmd, opts = conn.recv()
            if cmd == "quit":
                conn.send(("ok", "stopping"))
                log("SRV", "quit received, shutting down")
                stop_event.set()
                return
            resp = apply(manager, cmd, opts)
            conn.send(("ok", resp))
        except Exception as e:
            log("CMD", f"error: {e}")
            try:
                conn.send(("error", str(e)))
            except OSError:
                pass
        finally:
            try:
                conn.close()
            except OSError:
                pass


def serve(ipc):
    log("SRV", "became singleton, serving")
    manager = Manager()
    stop_event = threading.Event()
    threading.Thread(target=command_loop, args=(ipc, manager, stop_event), daemon=True).start()
    stop_event.wait()
    log("SRV", "GoodBye")
    try:
        ipc.close()
    except OSError:
        pass


def spawn_detached():
    args = [sys.executable, os.path.abspath(__file__), "_serve"]
    subprocess.Popen(
        args,
        creationflags=DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        close_fds=True,
    )


def send(cmd, opts):
    conn = Client(IPC_ADDR, family="AF_INET")
    conn.send((cmd, opts))
    status, payload = conn.recv()
    conn.close()
    return status, payload


def is_live():
    try:
        send("get_connections", {})
        return True
    except OSError:
        return False


def wait_live(timeout=10):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if is_live():
            return True
        time.sleep(0.2)
    return False


def cmd_start():
    if is_live():
        print("already running")
        return
    log("SRV", "no live instance, spawning detached server")
    spawn_detached()
    if wait_live(10):
        print("started")
    else:
        print("ERROR: server did not come up")
        sys.exit(1)


def cmd_stop():
    if not is_live():
        print("not running")
        return
    status, payload = send("get_connections", {})
    active = payload["active"] if status == "ok" and isinstance(payload, dict) else 0
    answer = input(f"stop server? {active} active connection(s). y/n: ").strip().lower()
    if answer != "y":
        print("cancelled")
        return
    send("quit", {})
    print("server stopping.")


def cmd_get_connections():
    if not is_live():
        print("ERROR: server not running")
        sys.exit(1)
    status, payload = send("get_connections", {})
    if status != "ok":
        print(f"ERROR: {payload}")
        sys.exit(1)
    for proxy in payload["proxy"]:
        print(f"proxy: {proxy}")
    for fwd in payload["fwd"]:
        print(f"fwd: {fwd['listen']} -> {fwd['target']}")
    for dns in payload.get("dns", []):
        print(f"dns: {dns}")
    print(f"active: {payload['active']}")


def cmd_passthrough(cmd, opts):
    if not is_live():
        print("ERROR: server not running")
        sys.exit(1)
    status, payload = send(cmd, opts)
    if status != "ok":
        print(f"ERROR: {payload}")
        sys.exit(1)
    print("ok")


def main():
    cmd, opts = parse(sys.argv[1:])
    if not cmd or cmd in ("help", "-h", "--help"):
        print(HELP)
        return
    if cmd == "_serve":
        serve(IpcListener(IPC_ADDR, family="AF_INET"))
        return
    if cmd == "is_alive":
        print("true" if is_live() else "false")
        return
    if cmd == "start":
        cmd_start()
        return
    if cmd == "stop":
        cmd_stop()
        return
    if cmd == "get_connections":
        cmd_get_connections()
        return
    if cmd in ("start_proxy", "start_fwd", "start_dns"):
        cmd_passthrough(cmd, opts)
        return
    print(f"unknown command: {cmd}")
    print(HELP)
    sys.exit(1)


if __name__ == "__main__":
    main()
