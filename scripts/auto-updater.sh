#!/bin/bash
# Auto-updater for persona evolution
# This script updates persona JSON based on detected signals

PERSONA_DIR="${PERSONA_DIR:-./personas}"

update_persona() {
    local name="$1"
    local signal_type="$2"
    local signal_weight="$3"
    
    local file="${PERSONA_DIR}/${name}.json"
    [[ ! -f "$file" ]] && return 1
    
    # Generate update text based on signal type
    local update_text=""
    case "$signal_type" in
        too_long) update_text="Observed: prefers concise, short answers" ;;
        need_detail) update_text="Observed: sometimes wants detailed explanations" ;;
        direct) update_text="Observed: wants direct answers without pleasantries" ;;
        cost) update_text="Observed: strongly cost-conscious, prefers free/open-source" ;;
        aesthetic) update_text="Observed: values visual design and aesthetics" ;;
        humor) update_text="Observed: appreciates wit and humor" ;;
        technical) update_text="Observed: wants technical depth and implementation details" ;;
        speed) update_text="Observed: prioritizes speed and efficiency" ;;
        positive) update_text="Observed: positive feedback - current approach working" ;;
        negative) update_text="Observed: negative feedback - approach needs adjustment" ;;
    esac
    
    [[ -z "$update_text" ]] && return 0
    
    # Read current description
    local current=$(jq -r '.description' "$file")
    
    # Check if already has observed section
    if echo "$current" | grep -q "Observed preferences"; then
        # Append to existing
        local new_desc="${current}
${update_text}"
    else
        # Add new section
        local new_desc="${current}

Observed preferences (auto-detected):
${update_text}"
    fi
    
    # Update file
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local log_entry=$(jq -n --arg time "$now" --arg type "$signal_type" --argjson weight "$signal_weight" '{time: $time, signal_type: $type, weight: $weight}')
    
    jq --arg desc "$new_desc" --arg updated "$now" --argjson log "$log_entry" \
       '.description = $desc | .updated = $updated | .evolutionLog += [$log]' \
       "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    
    echo "Updated $name: $update_text"
}

# Batch update from signal summary
batch_update() {
    local persona="$1"
    local summary_file="$2"
    
    [[ ! -f "$summary_file" ]] && return 1
    
    cat "$summary_file" | jq -c '.[]' | while read -r item; do
        local sig_type=$(echo "$item" | jq -r '.type')
        local weight=$(echo "$item" | jq -r '.total_weight')
        
        [[ "$weight" -ge 2 ]] && update_persona "$persona" "$sig_type" "$weight"
    done
}

case "${1:-}" in
    update) shift; update_persona "$@" ;;
    batch) shift; batch_update "$@" ;;
    *) echo "Usage: update <persona> <signal> <weight> | batch <persona> <summary.json>" ;;
esac
