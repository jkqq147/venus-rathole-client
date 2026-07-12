#!/usr/bin/env python3
"""Run rathole and expose its local state through Venus D-Bus."""

import os
import re
import signal
import subprocess
import sys
import time

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


BASE_DIR = "/data/venus-rathole"
CONFIG_FILE = os.path.join(BASE_DIR, "client.toml")
RATHOLE_BIN = os.path.join(BASE_DIR, "bin", "rathole")
SERVICE_NAME = "com.victronenergy.rathole"
SETTINGS_PREFIX = "/Settings/Rathole"
RESTART_DELAY_SECONDS = 5

for path in (
    "/opt/victronenergy/dbus-systemcalc-py/ext/velib_python",
    "/opt/victronenergy/dbus-tempsensor-relay/ext/velib_python",
):
    if os.path.exists(os.path.join(path, "vedbus.py")):
        sys.path.insert(1, path)
        break

from settingsdevice import SettingsDevice  # noqa: E402
from vedbus import VeDbusService  # noqa: E402


def read_client_config():
    """Read the rathole config for status display without changing it."""
    result = {"remote_addr": "", "token": "", "targets": []}
    if not os.path.isfile(CONFIG_FILE):
        return result

    service_pattern = re.compile(r"^\[client\.services\.([A-Za-z0-9_-]+)\]$")
    current_target = None
    with open(CONFIG_FILE, "r", encoding="utf-8") as config:
        for raw_line in config:
            line = raw_line.strip()
            if line.startswith("remote_addr = "):
                result["remote_addr"] = line.split("=", 1)[1].strip().strip('"')
            match = service_pattern.match(line)
            if match:
                current_target = {"name": match.group(1), "local_addr": ""}
                result["targets"].append(current_target)
            elif line.startswith("token = "):
                if not result["token"]:
                    result["token"] = line.split("=", 1)[1].strip().strip('"')
            elif current_target and line.startswith("local_addr = "):
                current_target["local_addr"] = line.split("=", 1)[1].strip().strip('"')
    return result


class RatholeManager:
    def __init__(self):
        self.bus = dbus.SystemBus()
        self.process = None
        self.next_start_at = 0
        self.service = VeDbusService(SERVICE_NAME, register=False)
        self.service.add_mandatory_paths(
            processname=__file__, processversion="0.2.0", connection="rathole",
            deviceinstance=0, productid=0, productname="Rathole Client",
            firmwareversion="0.2.0", hardwareversion=None, connected=1,
        )
        self.service.add_path("/StatusText", "Starting")
        self.service.add_path("/Enabled", 1, writeable=True, onchangecallback=self._enabled_changed)
        self.service.add_path("/ServerAddress", "")
        self.service.add_path("/Token", "")
        self.service.add_path("/TargetCount", 0)
        self.service.register()
        self.settings = SettingsDevice(
            self.bus,
            {"enabled": [f"{SETTINGS_PREFIX}/Enabled", 1, 0, 1]},
            self._setting_changed,
            timeout=10,
        )
        self.tick()

    def _setting_changed(self, _setting, _old_value, _new_value):
        self.tick()

    def _enabled_changed(self, _path, value):
        self.settings["enabled"] = 1 if int(value) else 0
        return True

    def _stop_process(self):
        if self.process is None:
            return
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
        self.process = None

    def _start_process(self):
        self.process = subprocess.Popen(
            [RATHOLE_BIN, "--client", CONFIG_FILE],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setsid,
        )

    def _publish(self, status, config):
        self.service["/StatusText"] = status
        self.service["/ServerAddress"] = config["remote_addr"]
        self.service["/Token"] = config["token"]
        self.service["/TargetCount"] = len(config["targets"])
        self.service["/Enabled"] = 1 if self.settings["enabled"] else 0

    def tick(self):
        config = read_client_config()
        configured = (
            bool(config["remote_addr"])
            and bool(config["token"])
            and bool(config["targets"])
            and all(target["local_addr"] for target in config["targets"])
            and os.path.isfile(RATHOLE_BIN)
        )
        enabled = bool(self.settings["enabled"])

        if not enabled:
            self._stop_process()
            self._publish("Disabled", config)
            return True
        if not configured:
            self._stop_process()
            self._publish("Configuration required", config)
            return True

        if self.process is not None and self.process.poll() is None:
            self._publish("Running", config)
            return True

        now = time.monotonic()
        if self.process is not None:
            self.process = None
            self.next_start_at = now + RESTART_DELAY_SECONDS
        if now >= self.next_start_at:
            try:
                self._start_process()
            except OSError as error:
                self.next_start_at = now + RESTART_DELAY_SECONDS
                self._publish("Start failed", config)
                return True
            self._publish("Starting", config)
        else:
            self._publish("Restarting", config)
        return True

    def stop(self):
        self._stop_process()


def main():
    DBusGMainLoop(set_as_default=True)
    loop = GLib.MainLoop()
    manager = RatholeManager()

    def stop(_signal, _frame):
        manager.stop()
        loop.quit()

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    GLib.timeout_add_seconds(1, manager.tick)
    loop.run()


if __name__ == "__main__":
    main()
