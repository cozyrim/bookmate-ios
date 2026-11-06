#!/bin/bash
# Keep application thread samples beside XCTest results without changing its exit code.
set -euo pipefail
mkdir -p RuntimeSamples
sample_apps() {
    while sleep 30; do
        for process_id in $(pgrep -x BookMate || true); do
            /usr/bin/sample "$process_id" 2 -file "RuntimeSamples/${process_id}-$(date +%s).txt" >/dev/null 2>&1 || true
        done
    done
}
sample_apps >/dev/null 2>&1 &
sampler_id=$!
cleanup() {
    local command_status=$?
    kill "$sampler_id" 2>/dev/null || true
    wait "$sampler_id" 2>/dev/null || true
    exit "$command_status"
}
trap cleanup EXIT
"$@"
