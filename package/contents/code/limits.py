#!/usr/bin/env python3

import json
import os
import select
import shutil
import subprocess
import sys
from pathlib import Path

WEEK_MINUTES = 7 * 24 * 60


def find_codex():
    if path := shutil.which("codex"):
        return path

    candidates = list(Path.home().glob(".nvm/versions/node/*/bin/codex"))
    candidates.append(Path.home() / ".local/bin/codex")
    for path in reversed(sorted(candidates)):
        if os.access(path, os.X_OK):
            return str(path)
    raise RuntimeError("Codex CLI not found")


def read_response(process, request_id):
    while select.select([process.stdout], [], [], 15)[0]:
        line = process.stdout.readline()
        if not line:
            break
        message = json.loads(line)
        if message.get("id") == request_id:
            if "error" in message:
                raise RuntimeError(message["error"].get("message", "Codex request failed"))
            return message["result"]
    raise RuntimeError("Codex did not respond")


def send(process, message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()


def weekly_window(result):
    snapshots = [result.get("rateLimits") or {}]
    snapshots += list((result.get("rateLimitsByLimitId") or {}).values())
    for snapshot in snapshots:
        for window in (snapshot.get("primary"), snapshot.get("secondary")):
            if window and window.get("windowDurationMins") == WEEK_MINUTES:
                return window
    raise RuntimeError("Codex returned no weekly limit")


def fetch():
    process = subprocess.Popen(
        [find_codex(), "app-server", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    try:
        send(
            process,
            {
                "method": "initialize",
                "id": 1,
                "params": {
                    "clientInfo": {"name": "kde-codex-limits", "version": "0.1.0"}
                },
            },
        )
        read_response(process, 1)
        send(process, {"method": "account/rateLimits/read", "id": 2})
        window = weekly_window(read_response(process, 2))
        return {"usedPercent": window["usedPercent"]}
    finally:
        process.terminate()
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            process.kill()


def self_test():
    result = {
        "rateLimits": {
            "primary": {"usedPercent": 10, "windowDurationMins": 300},
            "secondary": {"usedPercent": 42, "windowDurationMins": WEEK_MINUTES},
        }
    }
    assert weekly_window(result)["usedPercent"] == 42
    print("ok")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    else:
        try:
            print(json.dumps(fetch()))
        except Exception as error:
            print(json.dumps({"error": str(error)}))
            raise SystemExit(1)
