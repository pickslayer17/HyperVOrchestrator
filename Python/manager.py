import threading

from listener import Listener
from proxy import ProxyHandler
from forwarder import ForwardHandler
from netlog import log


class Manager:
    def __init__(self):
        self._proxies = {}
        self._forwards = {}
        self._lock = threading.RLock()

    def start_proxy(self, ip, port):
        port = int(port)
        key = f"{ip}:{port}"
        with self._lock:
            existing = self._proxies.get(key)
            if existing:
                existing.stop()
            listener = Listener(ip, port, ProxyHandler(), name=f"proxy:{key}")
            listener.start()
            self._proxies[key] = listener
        log("MGR", f"proxy listening on {key}")

    def start_fwd(self, bind_ip, listen_port, target_ip, target_port):
        listen_port = int(listen_port)
        target_port = int(target_port)
        with self._lock:
            existing = self._forwards.get(listen_port)
            if existing:
                existing[0].stop()
            listener = Listener(bind_ip, listen_port,
                                ForwardHandler(target_ip, target_port),
                                name=f"fwd:{listen_port}")
            listener.start()
            self._forwards[listen_port] = (listener, target_ip, target_port)
        log("MGR", f"forward {bind_ip}:{listen_port} -> {target_ip}:{target_port}")

    def get_connections(self):
        with self._lock:
            proxies = [f"{listener.bind_ip}:{listener.port}" for listener in self._proxies.values()]
            forwards = [
                {"listen": f"{listener.bind_ip}:{listener.port}", "target": f"{target_ip}:{target_port}"}
                for listener, target_ip, target_port in self._forwards.values()
            ]
            return {"proxy": proxies, "fwd": forwards, "active": self._count_active()}

    def _count_active(self):
        total = 0
        for listener in self._proxies.values():
            total += listener.active
        for listener, _, _ in self._forwards.values():
            total += listener.active
        return total
