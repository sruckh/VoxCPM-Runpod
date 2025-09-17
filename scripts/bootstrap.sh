#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
REPO_URL="${REPO_URL:-https://github.com/OpenBMB/VoxCPM.git}"
REPO_DIR="${REPO_DIR:-$WORKSPACE/VoxCPM}"
VENV_DIR="${VENV_DIR:-$WORKSPACE/.venv}"
MARKER_FILE="${MARKER_FILE:-$WORKSPACE/.voxcpm_bootstrapped}"
PIP_EXTRA_INDEX_URL="${PIP_EXTRA_INDEX_URL:-https://download.pytorch.org/whl/cu124}"
PIP_PREFER_BINARY="${PIP_PREFER_BINARY:-1}"
ENV_FILE="$WORKSPACE/.env"
DEFAULT_CMD="${DEFAULT_CMD:-run_voxcpm_demo.sh}"

if [ "${FORCE_BOOTSTRAP:-0}" = "1" ]; then
    rm -f "$MARKER_FILE"
fi

log() {
    echo "[$(date --iso-8601=seconds)] $*"
}

ensure_workspace() {
    mkdir -p "$WORKSPACE"
}

install_system_packages() {
    log "Updating apt cache"
    apt-get update -y
    log "Installing runtime dependencies"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        python3 \
        python3-venv \
        python3-pip \
        build-essential \
        ffmpeg \
        libsndfile1 \
        libgl1 \
        pkg-config \
        ca-certificates \
        curl
    rm -rf /var/lib/apt/lists/*
    update-ca-certificates
}

clone_or_update_repo() {
    if [ ! -d "$REPO_DIR/.git" ]; then
        log "Cloning $REPO_URL"
        git clone "$REPO_URL" "$REPO_DIR"
    else
        log "Updating existing repository"
        git -C "$REPO_DIR" pull --ff-only
    fi
}

create_venv() {
    if [ ! -d "$VENV_DIR" ]; then
        log "Creating virtual environment"
        python3 -m venv "$VENV_DIR"
    fi
    # shellcheck disable=SC1090
    source "$VENV_DIR/bin/activate"
    log "Upgrading pip tooling"
    pip install --upgrade pip setuptools wheel
}

install_python_packages() {
    log "Installing VoxCPM python dependencies"
    export PIP_EXTRA_INDEX_URL PIP_PREFER_BINARY
    pip install --no-cache-dir --prefer-binary -e "$REPO_DIR"
}

write_env_hint() {
    cat <<'ENVEOF' > "$ENV_FILE"
# Environment variables for VoxCPM runtime
# Customize as needed before launching workloads.
HF_HOME=${HF_HOME:-/workspace/.cache/huggingface}
TORCH_HOME=${TORCH_HOME:-/workspace/.cache/torch}
OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}
ENVEOF
}

main() {
    ensure_workspace
    install_system_packages
    clone_or_update_repo
    create_venv
    install_python_packages
    write_env_hint
    touch "$MARKER_FILE"
    log "Bootstrap finished"
}

if [ ! -f "$MARKER_FILE" ]; then
    main
else
    log "Bootstrap already completed, skipping setup"
fi

if [ -d "$VENV_DIR" ]; then
    # shellcheck disable=SC1090
    source "$VENV_DIR/bin/activate"
    if [ -f "$ENV_FILE" ]; then
        set -o allexport
        # shellcheck disable=SC1090
        source "$ENV_FILE"
        set +o allexport
    fi
fi

if [ "$#" -gt 0 ]; then
    exec "$@"
else
    if [ -d "$REPO_DIR" ]; then
        cd "$REPO_DIR"
    fi
    log "No command provided, defaulting to: $DEFAULT_CMD"
    exec bash -lc "$DEFAULT_CMD"
fi
