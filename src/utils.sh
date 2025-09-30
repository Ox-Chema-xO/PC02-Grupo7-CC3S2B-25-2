#!/bin/bash

TEMP_CLONE="${TEMP_CLONE:-}"
TEMP_REPO="${TEMP_REPO:-}"

log () {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

cleanup() {
    local exit_code=$?

    if [[ -n "$TEMP_CLONE" ]] && [[ -d "$TEMP_CLONE" ]]; then
        rm -rf "$TEMP_CLONE" || true
    fi

    if [[ -n "$TEMP_REPO" ]] && [[ -d "$TEMP_REPO" ]]; then
        rm -rf "$TEMP_REPO" || true
    fi

    exit $exit_code
}
