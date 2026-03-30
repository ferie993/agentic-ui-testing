#!/bin/bash
# helper/runner.sh - Intelligent Dynamic Runner (Local & Remote Support)

TAGS="$1"
BASE_URL="$2"
MODE="$3"

# Log colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[$(date +%T)] INFO:${NC} $1"; }
log_success() { echo -e "${GREEN}[$(date +%T)] PASS:${NC} $1"; }
log_error() { echo -e "${RED}[$(date +%T)] FAIL:${NC} $1"; }

# 0. Smart App Readiness Check
if ! curl -sL -f -o /dev/null "$BASE_URL"; then
    log_error "Remote URL $BASE_URL is not reachable. Please check your internet connection or start your local app."
    exit 1
fi

# 1. Preparation
mkdir -p allure-results step-definitions .playwright-cli
if [[ "$TAGS" != *".feature"* ]]; then
    rm -f allure-results/*-result.json allure-results/*-attachment.png allure-results/*-screenshot.png allure-results/*.yml
fi
rm -f .playwright-cli/*.yml .playwright-cli/*.log .playwright-cli/stale_files.txt

if [ "$MODE" == "HEADED" ]; then
    log_info "Enabling Headed Mode"
    export HEADED_FLAG="--headed"
else
    export HEADED_FLAG=""
fi

generate_allure_json() {
    local feature_file="$1"
    local name="$2"
    local status="$3"
    local start="$4"
    local stop="$5"
    local error_msg="$6"
    
    local uuid=$(node -p "require('crypto').randomUUID()" 2>/dev/null || echo "$RANDOM$RANDOM")
    local hash=$(echo "$name" | md5 2>/dev/null || echo "$name" | md5sum | cut -d' ' -f1)
    
    local screenshot_file="allure-results/${name}-screenshot.png"
    local attachments_json=""
    if [ -f "$screenshot_file" ]; then
        local screenshot_name="${uuid}-attachment.png"
        mv "$screenshot_file" "allure-results/$screenshot_name"
        attachments_json="{ \"name\": \"Execution Screenshot\", \"source\": \"$screenshot_name\", \"type\": \"image/png\" }"
    fi

    local root_error_json=""
    if [ "$status" = "failed" ] && [ -n "$error_msg" ]; then
        local escaped_msg=$(echo "$error_msg" | node -e "const fs = require('fs'); console.log(JSON.stringify(fs.readFileSync(0).toString()))")
        root_error_json="\"statusDetails\": { \"message\": \"Test execution failed\", \"trace\": $escaped_msg },"
    fi

    local steps_json=""
    local total_steps=$(grep -c -E "^\s*(Given|When|Then|And|But)" "$feature_file")
    local current_step=0

    while IFS= read -r step_line; do
        current_step=$((current_step + 1))
        step_text=$(echo "$step_line" | xargs | sed 's/"/\\"/g')
        
        local step_status="passed"
        local step_details=""
        
        if [ "$status" = "failed" ] && [ "$current_step" -eq "$total_steps" ]; then
            step_status="failed"
            if [ -n "$error_msg" ]; then
                # Reuse escaped_msg from root
                step_details="\"statusDetails\": { \"message\": \"Assertion or execution failed\", \"trace\": $escaped_msg },"
            fi
        fi
        
        steps_json+="{ \"name\": \"$step_text\", \"status\": \"$step_status\", $step_details \"stage\": \"finished\", \"start\": $start, \"stop\": $stop },"
    done < <(grep -E "^\s*(Given|When|Then|And|But)" "$feature_file")
    steps_json="${steps_json%,}"
    
    cat <<EOF > "allure-results/${uuid}-result.json"
{
  "uuid": "$uuid",
  "historyId": "$hash",
  "name": "$name",
  "status": "$status",
  $root_error_json
  "stage": "finished",
  "steps": [ $steps_json ],
  "attachments": [ $attachments_json ],
  "start": $start,
  "stop": $stop,
  "labels": [
    {"name": "suite", "value": "Agentic UI Test Suite"},
    {"name": "tag", "value": "$TAGS"}
  ]
}
EOF
}

# 2. Scenario Discovery
feature_files=()
if [[ "$TAGS" == *".feature"* ]]; then
    for f in $(echo "$TAGS" | tr ',' ' '); do
        [ -f "$f" ] && feature_files+=("$f")
    done
else
    for t in $(echo "$TAGS" | tr ',' ' '); do
        while IFS= read -r line; do
            [ -n "$line" ] && feature_files+=("$line")
        done < <(grep -lR "$t" test/ 2>/dev/null)
    done
    # Remove duplicates from feature_files if multiple tags match the same file
    if [ ${#feature_files[@]} -gt 0 ]; then
        feature_files=($(echo "${feature_files[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    fi
fi

if [ ${#feature_files[@]} -eq 0 ]; then exit 3; fi

log_info "Discovered ${#feature_files[@]} scenario(s) for tag: $TAGS"

# 3. Cache Validation
stale_files=()
valid_files=()

for feature_file in "${feature_files[@]}"; do
    filename=$(basename "$feature_file" .feature)
    cache_file="step-definitions/${filename}-step.sh"
    
    if [ ! -f "$cache_file" ]; then
        log_info "Cache MISS: $filename"
        stale_files+=("$feature_file")
    elif [ "$feature_file" -nt "$cache_file" ]; then
        log_info "Cache STALE: $filename (Feature file updated)"
        rm -f "$cache_file"
        stale_files+=("$feature_file")
    else
        valid_files+=("$feature_file")
    fi
done

# 4. Execution Loop (Only for valid files)
if [ ${#valid_files[@]} -gt 0 ]; then
    total_start=$(date +%s)
    for feature_file in "${valid_files[@]}"; do
        filename=$(basename "$feature_file" .feature)
        cache_file="step-definitions/${filename}-step.sh"
        
        log_info "Executing: $filename"
        start_ms=$(node -p "Date.now()")
        
        script_output=$(bash "$cache_file" 2>&1)
        script_exit_code=$?
        
        if [ -n "$script_output" ]; then
            echo "$script_output"
        fi
        
        if [ $script_exit_code -eq 0 ]; then
            status="passed"
            stop_ms=$(node -p "Date.now()")
            log_success "$filename ($((stop_ms - start_ms))ms)"
            generate_allure_json "$feature_file" "$filename" "$status" "$start_ms" "$stop_ms" ""
        else
            status="failed"
            stop_ms=$(node -p "Date.now()")
            log_error "$filename ($((stop_ms - start_ms))ms)"
            generate_allure_json "$feature_file" "$filename" "$status" "$start_ms" "$stop_ms" "$script_output"
        fi
    done
    total_stop=$(date +%s)
    log_info "Total execution time: $((total_stop - total_start))s"
fi

rm -f .playwright-cli/*.yml .playwright-cli/*.log

# 5. Result Handling
if [ ${#stale_files[@]} -gt 0 ]; then
    echo "${stale_files[@]}" > .playwright-cli/stale_files.txt
    if [ ${#valid_files[@]} -gt 0 ]; then
        exit 4 # Partial stale (some valid already run)
    else
        exit 2 # Full stale (nothing run yet)
    fi
fi

exit 0
