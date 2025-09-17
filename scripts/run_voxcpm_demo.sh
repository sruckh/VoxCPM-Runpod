#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
REPO_DIR="${REPO_DIR:-$WORKSPACE/VoxCPM}"
GRADIO_SERVER_NAME="${GRADIO_SERVER_NAME:-0.0.0.0}"
GRADIO_SERVER_PORT="${GRADIO_SERVER_PORT:-7860}"
GRADIO_SHARE="${GRADIO_SHARE:-true}"
GRADIO_MAX_QUEUE="${GRADIO_MAX_QUEUE:-10}"
GRADIO_SHOW_ERROR="${GRADIO_SHOW_ERROR:-true}"

export GRADIO_SERVER_NAME GRADIO_SERVER_PORT GRADIO_SHARE GRADIO_MAX_QUEUE GRADIO_SHOW_ERROR

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
fi

python - <<'PY'
import os
import app

truthy = {"1", "true", "yes", "on"}
falsey = {"0", "false", "no", "off"}

def env_bool(name: str, default: str = "true") -> bool:
    value = os.environ.get(name, default).strip().lower()
    if value in truthy:
        return True
    if value in falsey:
        return False
    return default.strip().lower() in truthy

server_name = os.environ.get("GRADIO_SERVER_NAME", "0.0.0.0")
server_port = int(os.environ.get("GRADIO_SERVER_PORT", "7860"))
share = env_bool("GRADIO_SHARE", "true")
show_error = env_bool("GRADIO_SHOW_ERROR", "true")
max_queue = int(os.environ.get("GRADIO_MAX_QUEUE", "10"))

demo = app.VoxCPMDemo()
interface = app.create_demo_interface(demo)
interface.queue(max_size=max_queue).launch(
    server_name=server_name,
    server_port=server_port,
    share=share,
    show_error=show_error,
)
PY
