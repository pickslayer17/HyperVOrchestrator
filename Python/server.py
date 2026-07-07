import sys
import os
import time
import threading
import subprocess
from multiprocessing.connection import Listener as IpcListener, Client

from manager import Manager
from watcher import Watcher
from netlog import log

PIPE_ADDR = r"\\.\pipe\hyperv-netagent"
WATCH_INTERVAL = 10

DETACHED_PROCESS = 0x00000008
CREATE_NEW_PROCESS_GROUP = 0x00000200

HELP = """hyperv-netagent - commands:
  start_proxy              -ip <ip> -port <port>
  add_machine              -vmip <ip>
  set_forward_port         -vmip <ip> -portadress <listenPort> [-targetport <port>]
  remove_machine           -vmip <ip>
  get_machine_names
  get_host_vm_forward_port -vmip <ip>
  status
  quit
  help"""


def parse(argv):
    if not argv:
        return None, {}
    cmd = argv[0]
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
    if cmd == "add_machine":
        manager.add_machine(opts["vmip"])
        return "ok"
    if cmd == "set_forward_port":
        listen = opts.get("listenport") or opts.get("portadress")
        target = opts.get("targetport") or listen
        manager.set_forward_port(opts["vmip"], listen, target)
        return "ok"
    if cmd == "remove_machine":
        manager.remove_machine(opts["vmip"])
        return "ok"
    if cmd == "get_machine_names":
        return manager.machine_names()
    if cmd == "get_host_vm_forward_port":
        return manager.host_vm_forward_port(opts["vmip"])
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


def serve(ipc, first_cmd, first_opts):
    log("SRV", "became singleton, serving")
    manager = Manager()
    stop_event = threading.Event()
    manager.on_empty = stop_event.set

    apply(manager, first_cmd, first_opts)

    Watcher(manager, interval=WATCH_INTERVAL).start()
    threading.Thread(target=command_loop, args=(ipc, manager, stop_event), daemon=True).start()

    stop_event.wait()
    log("SRV", "GoodBye")
    try:
        ipc.close()
    except OSError:
        pass


def spawn_detached(ip, port):
    args = [sys.executable, os.path.abspath(__file__), "_serve", "-ip", str(ip), "-port", str(port)]
    subprocess.Popen(
        args,
        creationflags=DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        close_fds=True,
    )


def is_live():
    try:
        conn = Client(PIPE_ADDR, family="AF_PIPE")
        conn.send(("get_machine_names", {}))
        conn.recv()
        conn.close()
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


def main():
    cmd, opts = parse(sys.argv[1:])
    if not cmd or cmd.lower() in ("help", "-h", "--help"):
        print(HELP)
        return

    if cmd == "_serve":
        ipc = IpcListener(PIPE_ADDR, family="AF_PIPE")
        serve(ipc, "start_proxy", opts)
        return

    if cmd.lower() == "status":
        print("alive" if is_live() else "dead")
        return

    if cmd == "quit":
        ans = input("are you sure? y/n: ").strip().lower()
        if ans != "y":
            print("cancelled")
            return

    try:
        conn = Client(PIPE_ADDR, family="AF_PIPE")
    except OSError as e:
        if isinstance(e, PermissionError) or getattr(e, "winerror", None) == 5:
            print("ERROR: access denied to the agent - it runs elevated, start this as Administrator")
            sys.exit(1)
        conn = None

    if conn is None:
        if cmd == "start_proxy":
            log("SRV", f"no live instance, spawning detached server: {opts}")
            spawn_detached(opts["ip"], opts["port"])
            if wait_live(10):
                print("proxy server started (detached).")
            else:
                print("ERROR: proxy server did not come up")
                sys.exit(1)
        else:
            print("ERROR: no live server")
            sys.exit(1)
        return

    conn.send((cmd, opts))
    status, payload = conn.recv()
    conn.close()
    if cmd == "get_machine_names":
        if status == "ok" and payload:
            for name in payload:
                print(name)
    elif cmd == "get_host_vm_forward_port":
        if status == "error":
            print(f"ERROR: {payload}")
            sys.exit(1)
        if payload is not None:
            print(payload)
    elif cmd == "quit":
        print("server stopping.")
    elif status == "error":
        print(f"ERROR: {payload}")
        sys.exit(1)


if __name__ == "__main__":
    main()
