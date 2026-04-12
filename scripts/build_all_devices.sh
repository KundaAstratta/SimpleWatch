#!/usr/bin/env bash
# build_all_devices.sh
# ─────────────────────────────────────────────────────────────────────────────
# Compiles SimpleWatch for every device listed in manifest.xml and reports
# per-device pass/fail.  Requires:
#   • Garmin Connect IQ SDK installed
#   • A developer signing key (.der) — create one with:
#       monkeyc --generate-key --output developer_key.der
#
# Usage:
#   ./scripts/build_all_devices.sh [options]
#
# Options:
#   -k <path>   Developer key (.der).  Default: developer_key.der in project root
#   -s <path>   Path to Garmin SDK bin/ directory.  Auto-detected if omitted.
#   -o <dir>    Output directory for compiled .prg files.  Default: /tmp/sw_build
#   -j <n>      Parallel jobs (default: number of CPU cores)
#   -q          Quiet — only print failures and the final summary
#   -h          Show this help
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Default values ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${PROJECT_ROOT}/manifest.xml"
JUNGLE="${PROJECT_ROOT}/monkey.jungle"
KEY="${PROJECT_ROOT}/developer_key.der"
OUTPUT_DIR="/tmp/sw_build"
JOBS=$(sysctl -n hw.logicalcpu 2>/dev/null || nproc 2>/dev/null || echo 4)
QUIET=false
SDK_BIN=""

# ── Parse arguments ───────────────────────────────────────────────────────────
while getopts "k:s:o:j:qh" opt; do
    case $opt in
        k) KEY="$OPTARG" ;;
        s) SDK_BIN="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        j) JOBS="$OPTARG" ;;
        q) QUIET=true ;;
        h)
            sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown option -$OPTARG"; exit 1 ;;
    esac
done

# ── Locate the SDK ─────────────────────────────────────────────────────────────
find_sdk() {
    # 1. Environment variable
    if [[ -n "${GARMIN_HOME:-}" && -x "${GARMIN_HOME}/bin/monkeyc" ]]; then
        echo "${GARMIN_HOME}/bin"
        return
    fi
    # 2. macOS default: latest installed SDK via sdk-manager
    local sdk_root="${HOME}/Library/Application Support/Garmin/ConnectIQ/Sdks"
    if [[ -d "$sdk_root" ]]; then
        local latest
        latest=$(ls -1d "${sdk_root}"/connectiq-sdk-mac-* 2>/dev/null \
                 | sort -V | tail -1)
        if [[ -n "$latest" && -x "${latest}/bin/monkeyc" ]]; then
            echo "${latest}/bin"
            return
        fi
    fi
    # 3. macOS Application Support (VS Code extension path)
    local vscode_sdk="${HOME}/.vscode/extensions"
    if [[ -d "$vscode_sdk" ]]; then
        local ext_sdk
        ext_sdk=$(find "$vscode_sdk" -name "monkeyc" -type f 2>/dev/null \
                  | head -1)
        if [[ -n "$ext_sdk" ]]; then
            echo "$(dirname "$ext_sdk")"
            return
        fi
    fi
    # 4. PATH
    if command -v monkeyc &>/dev/null; then
        echo "$(dirname "$(command -v monkeyc)")"
        return
    fi
    echo ""
}

if [[ -z "$SDK_BIN" ]]; then
    SDK_BIN="$(find_sdk)"
fi

MONKEYC="${SDK_BIN}/monkeyc"

if [[ ! -x "$MONKEYC" ]]; then
    echo "ERROR: monkeyc not found."
    echo "  Set GARMIN_HOME, use -s <sdk_bin>, or add the SDK to your PATH."
    echo "  SDK_BIN probed: '${SDK_BIN}'"
    exit 1
fi

# ── Validate prerequisites ────────────────────────────────────────────────────
if [[ ! -f "$KEY" ]]; then
    echo "ERROR: Developer key not found at: $KEY"
    echo "  Create one with:  $MONKEYC --generate-key --output developer_key.der"
    exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: manifest.xml not found at: $MANIFEST"
    exit 1
fi

# ── Extract device list from manifest.xml ─────────────────────────────────────
mapfile -t DEVICES < <(
    grep '<iq:product id=' "$MANIFEST" \
    | sed 's/.*id="\([^"]*\)".*/\1/' \
    | sort
)

TOTAL=${#DEVICES[@]}
if [[ $TOTAL -eq 0 ]]; then
    echo "ERROR: No devices found in $MANIFEST"
    exit 1
fi

# ── Prepare output directory ──────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"
LOG_DIR="${OUTPUT_DIR}/logs"
mkdir -p "$LOG_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0
failed_list=()
declare -A results  # device -> "PASS" | "FAIL"

compile_device() {
    local device="$1"
    local out_prg="${OUTPUT_DIR}/${device}.prg"
    local log="${LOG_DIR}/${device}.log"

    "$MONKEYC" \
        -f "$JUNGLE" \
        -d "$device" \
        -y "$KEY" \
        -o "$out_prg" \
        2>"$log"
    return $?
}

print_result() {
    local device="$1"
    local status="$2"
    if [[ "$status" == "PASS" ]]; then
        $QUIET || printf "  ${GREEN}✓${NC}  %s\n" "$device"
    else
        printf "  ${RED}✗${NC}  %s\n" "$device"
        if [[ -s "${LOG_DIR}/${device}.log" ]]; then
            sed 's/^/      /' "${LOG_DIR}/${device}.log"
        fi
    fi
}

# ── Compile ───────────────────────────────────────────────────────────────────
echo ""
echo "SimpleWatch — multi-device build validation"
echo "  SDK:      $MONKEYC"
echo "  Key:      $KEY"
echo "  Devices:  $TOTAL"
echo "  Jobs:     $JOBS"
echo "  Output:   $OUTPUT_DIR"
echo ""

START_TIME=$(date +%s)

# Use a simple semaphore via background jobs + wait -n (bash 4.3+)
job_count=0

for device in "${DEVICES[@]}"; do
    (
        if compile_device "$device"; then
            echo "PASS:$device"
        else
            echo "FAIL:$device"
        fi
    ) &
    (( job_count++ ))
    if (( job_count >= JOBS )); then
        # Wait for any one job to finish
        if ! wait -n 2>/dev/null; then
            # wait -n not available (bash < 4.3); fall back to sequential wait
            wait
            job_count=0
        else
            (( job_count-- ))
        fi
    fi
done

# Wait for all remaining jobs
wait

# ── Collect results from the log files ────────────────────────────────────────
# Re-run sequentially to collect structured output (background jobs can't
# reliably write to the associative array in subshells)
echo "Results:"
echo "────────────────────────────────────────────────────────────────────"

for device in "${DEVICES[@]}"; do
    out_prg="${OUTPUT_DIR}/${device}.prg"
    if [[ -f "$out_prg" ]]; then
        results["$device"]="PASS"
        (( passed++ )) || true
        print_result "$device" "PASS"
    else
        results["$device"]="FAIL"
        (( failed++ )) || true
        failed_list+=("$device")
        print_result "$device" "FAIL"
    fi
done

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "────────────────────────────────────────────────────────────────────"
printf "  ${GREEN}Passed: %d${NC}  |  ${RED}Failed: %d${NC}  |  Total: %d  |  Time: %ds\n" \
    "$passed" "$failed" "$TOTAL" "$ELAPSED"
echo ""

if [[ ${#failed_list[@]} -gt 0 ]]; then
    echo -e "  ${YELLOW}Failed devices:${NC}"
    for d in "${failed_list[@]}"; do
        echo "    • $d"
    done
    echo ""
    exit 1
fi

echo -e "  ${GREEN}All devices compiled successfully.${NC}"
echo ""
exit 0
