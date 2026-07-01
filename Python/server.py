import sys
import threading
import time
from multiprocessing.connection import Listener as IpcListener, Client

from manager import Manager

PIPE_ADDR = r"\\.\pipe\hyperv-netagent"
IDLE_TIMEOUT = 300


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
    if cmd == "Start-Proxy":
        manager.start_proxy(opts["ip"], opts["port"])
    elif cmd == "AddMachine":
        manager.add_machine(opts["vmip"])
    elif cmd == "Set-ForwardPort":
        listen = opts.get("listenport") or opts.get("portadress")
        target = opts.get("targetport") or listen
        manager.set_forward_port(opts["vmip"], listen, target)
    elif cmd == "RemoveMachine":
        manager.remove_machine(opts["vmip"])
    else:
        raise ValueError(f"unknown command: {cmd}")


def probe(vmip):
    return True


def watcher(manager):
    while True:
        time.sleep(IDLE_TIMEOUT)
        for m in manager.snapshot():
            if m.last_seen and (time.time() - m.last_seen) > IDLE_TIMEOUT:
                if not probe(m.vmip):
                    manager.remove_machine(m.vmip)


def command_loop(ipc, manager):
    while True:
        try:
            conn = ipc.accept()
        except OSError:
            break
        try:
            cmd, opts = conn.recv()
            apply(manager, cmd, opts)
        except Exception as e:
            print(f"command error: {e}")
        finally:
            conn.close()


def serve(ipc, first_cmd, first_opts):
    manager = Manager()
    stop_event = threading.Event()
    manager.on_empty = stop_event.set

    apply(manager, first_cmd, first_opts)

    threading.Thread(target=watcher, args=(manager,), daemon=True).start()
    threading.Thread(target=command_loop, args=(ipc, manager), daemon=True).start()

    stop_event.wait()
    print("GoodBye")
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
        ipc = IpcListener(PIPE_ADDR, family="AF_PIPE")
        serve(ipc, cmd, opts)
        return
    conn.send((cmd, opts))
    conn.close()


if __name__ == "__main__":
    main()
