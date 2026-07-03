import sys
import threading
from multiprocessing.connection import Listener as IpcListener, Client

from manager import Manager
from watcher import Watcher
from netlog import log

PIPE_ADDR = r"\\.\pipe\hyperv-netagent"
WATCH_INTERVAL = 10


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
    if cmd == "Start-Proxy":
        manager.start_proxy(opts["ip"], opts["port"])
        return "ok"
    if cmd == "AddMachine":
        manager.add_machine(opts["vmip"])
        return "ok"
    if cmd == "Set-ForwardPort":
        listen = opts.get("listenport") or opts.get("portadress")
        target = opts.get("targetport") or listen
        manager.set_forward_port(opts["vmip"], listen, target)
        return "ok"
    if cmd == "RemoveMachine":
        manager.remove_machine(opts["vmip"])
        return "ok"
    if cmd == "GetMachineNames":
        return manager.machine_names()
    raise ValueError(f"unknown command: {cmd}")


def command_loop(ipc, manager):
    while True:
        try:
            conn = ipc.accept()
        except OSError:
            break
        try:
            cmd, opts = conn.recv()
            resp = apply(manager, cmd, opts)
            conn.send(("ok", resp))
        except Exception as e:
            log("CMD", f"error: {e}")
            try:
                conn.send(("error", str(e)))
            except OSError:
                pass
        finally:
            conn.close()


def serve(ipc, first_cmd, first_opts):
    log("SRV", "became singleton, serving")
    manager = Manager()
    stop_event = threading.Event()
    manager.on_empty = stop_event.set

    apply(manager, first_cmd, first_opts)

    Watcher(manager, interval=WATCH_INTERVAL).start()
    threading.Thread(target=command_loop, args=(ipc, manager), daemon=True).start()

    stop_event.wait()
    log("SRV", "GoodBye")
    try:
        ipc.close()
    except OSError:
        pass


def main():
    cmd, opts = parse(sys.argv[1:])
    if not cmd:
        print("usage: server.py <Command> [-flag value ...]")
        return

    try:
        conn = Client(PIPE_ADDR, family="AF_PIPE")
    except (FileNotFoundError, OSError):
        conn = None

    if conn is None:
        if cmd == "Start-Proxy":
            log("SRV", f"no live instance, starting; first cmd: {cmd} {opts}")
            ipc = IpcListener(PIPE_ADDR, family="AF_PIPE")
            serve(ipc, cmd, opts)
        else:
            print("ERROR: no live server")
            sys.exit(1)
        return

    conn.send((cmd, opts))
    status, payload = conn.recv()
    conn.close()
    if cmd == "GetMachineNames":
        if status == "ok" and payload:
            for name in payload:
                print(name)
    elif status == "error":
        print(f"ERROR: {payload}")
        sys.exit(1)


if __name__ == "__main__":
    main()
