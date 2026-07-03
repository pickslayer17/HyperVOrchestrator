import threading

from listener import Listener
from proxy import ProxyHandler
from forwarder import ForwardHandler
from netlog import log


class Machine:
    def __init__(self, vmip):
        self.vmip = vmip
        self.forward = None
        self.target_port = None


class Manager:
    def __init__(self):
        self._machines = {}
        self._proxy = None
        self._lock = threading.RLock()
        self.forward_bind_ip = "0.0.0.0"
        self.on_empty = None

    def start_proxy(self, ip, port):
        with self._lock:
            if self._proxy:
                self._proxy.stop()
            self._proxy = Listener(ip, port, ProxyHandler(), name="proxy")
            self._proxy.start()
        log("MGR", f"proxy started {ip}:{port}")

    def set_forward_bind(self, ip):
        with self._lock:
            self.forward_bind_ip = ip
        log("MGR", f"forward bind set {ip}")

    def add_machine(self, vmip):
        with self._lock:
            self._machines.setdefault(vmip, Machine(vmip))
        log("MGR", f"machine added {vmip}")

    def set_forward_port(self, vmip, listen_port, target_port):
        with self._lock:
            m = self._machines.setdefault(vmip, Machine(vmip))
            if m.forward:
                m.forward.stop()
            m.target_port = int(target_port)
            m.forward = Listener(self.forward_bind_ip, listen_port,
                                 ForwardHandler(vmip, target_port), name=f"fwd:{vmip}")
            m.forward.start()
        log("MGR", f"forward set {self.forward_bind_ip}:{listen_port} -> {vmip}:{target_port}")

    def remove_machine(self, vmip):
        with self._lock:
            m = self._machines.pop(vmip, None)
            if m and m.forward:
                m.forward.stop()
            empty = not self._machines
        log("MGR", f"machine removed {vmip} (empty={empty})")
        if empty and self.on_empty:
            self.on_empty()

    def machine_names(self):
        with self._lock:
            return list(self._machines.keys())

    def snapshot(self):
        with self._lock:
            return list(self._machines.values())
