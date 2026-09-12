#!/usr/bin/env python3
"""Fetch Codex rate-limit windows for the Plasma widget."""

# ---------- Imports ----------

import json
import os
import select
import shutil
import subprocess
from pathlib import Path

# ---------- Constants ----------

WEEK_MINUTES = 7 * 24 * 60
FIVE_HOUR_MINUTES = 5 * 60


# ---------- Codex communication ----------


def find_codex():
    # apparently """text starting here is a py convencion
    """Locate an executable Codex CLI across common user installations.
    Used when starting the app-server subprocess for each widget refresh.
    """
    if path := shutil.which("codex"):
        return path

    candidates = list(Path.home().glob(".nvm/versions/node/*/bin/codex"))
    candidates.append(Path.home() / ".local/bin/codex")
    for path in reversed(sorted(candidates)):
        if os.access(path, os.X_OK):
            return str(path)
    raise RuntimeError("Codex CLI not found")


def read_response(process, request_id):
    """Read the matching JSON-RPC response with a bounded wait.
    Used by the rate-limit request sequence to avoid hanging Plasma.
    """
    while select.select([process.stdout], [], [], 15)[0]:
        line = process.stdout.readline()
        if not line:
            break
        message = json.loads(line)
        if message.get("id") == request_id:
            if "error" in message:
                raise RuntimeError(
                    message["error"].get("message", "Codex request failed")
                )
            return message["result"]
    raise RuntimeError("Codex did not respond")


def send(process, message):
    print(json.dumps(message), file=process.stdin, flush=True)


# ---------- Rate-limit parsing ----------


def weekly_window(result):
    snapshot = result.get("rateLimits") or {}
    for window in (snapshot.get("primary"), snapshot.get("secondary")):
        if window and window.get("windowDurationMins") == WEEK_MINUTES:
            return window
    raise RuntimeError("Codex returned no weekly limit")


def five_hour_window(result):
    snapshot = result.get("rateLimits") or {}
    for window in (snapshot.get("primary"), snapshot.get("secondary")):
        if window and window.get("windowDurationMins") == FIVE_HOUR_MINUTES:
            return window
    raise RuntimeError("Codex returned no 5-hour limit")


# ---------- Public workflow ----------


def fetch():
    """Fetch and normalize the usage windows displayed by the widget.
    Used by the command-line entry point invoked from QML.
    """
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
        result = read_response(process, 2)
        weekly = weekly_window(result)
        five_hour = five_hour_window(result)
        return {
            "weeklyUsedPercent": weekly["usedPercent"],
            "weeklyResetsAt": weekly["resetsAt"],
            "fiveHourUsedPercent": five_hour["usedPercent"],
            "fiveHourResetsAt": five_hour["resetsAt"],
        }
    finally:
        process.terminate()
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            process.kill()


# ---------- Entry point ----------

if __name__ == "__main__":
    try:
        print(json.dumps(fetch()))
    except Exception as error:
        print(json.dumps({"error": str(error)}))
        raise SystemExit(1)
