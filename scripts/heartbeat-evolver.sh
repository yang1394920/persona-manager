#!/usr/bin/env bash
# heartbeat-evolver.sh - 心跳任务：定期分析对话并自动进化人设

PERSONA_DIR="${PERSONA_DIR:-./personas}"
MEMORY_DIR="${MEMORY_DIR:-../../memory}"
LOG_FILE="${PERSONA_DIR}/.evolution.log"
STATE_FILE="${PERSONA_DIR}/.evolution-state.json"

# Ensure state file exists
if [[ ! -f "$STATE_FILE" ]]; then
    jq -n '{enabled: false, lastRun: null, signalCount: 0}' > "$STATE_FILE"
fi

show_help() {
    echo "Heartbeat Evolver - 自动进化心跳任务"
    echo ""
    echo "Usage:"
    echo "  enable              - 启用自动进化"
    echo "  disable             - 禁用自动进化"
    echo "  status              - 查看状态"
    echo "  run [force]         - 手动运行分析 (force 跳过检查)"
    echo "  config <key> <val>    - 配置参数"
    echo "  log                 - 查看进化日志"
}

get_active_persona() {
    cat "${PERSONA_DIR}/.active" 2>/dev/null
}

is_enabled() {
    jq -r '.enabled // false' "$STATE_FILE"
}

enable() {
    jq '.enabled = true' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "✓ 自动进化已启用"
    echo "  每次心跳将自动分析对话并更新人设"
}

disable() {
    jq '.enabled = false' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "✓ 自动进化已禁用"
}

show_status() {
    local enabled=$(jq -r '.enabled // false' "$STATE_FILE")
    local lastRun=$(jq -r '.lastRun // "never"' "$STATE_FILE")
    local signalCount=$(jq -r '.signalCount // 0' "$STATE_FILE")
    local active=$(get_active_persona)
    local threshold=$(jq -r '.threshold // 3' "$STATE_FILE")
    
    echo "Auto-Evolution Status"
    echo "===================="
    echo "Enabled: $enabled"
    echo "Active Persona: ${active:-none}"
    echo "Last Run: $lastRun"
    echo "Signal Count: $signalCount"
    echo "Threshold: $threshold (signals needed to trigger update)"
    echo ""
    
    if [[ "$enabled" == "true" && -n "$active" ]]; then
        echo "✓ 下次心跳时将自动分析并进化"
    elif [[ "$enabled" != "true" ]]; then
        echo "✗ 已禁用 - 运行: enable 来启用"
    else
        echo "⚠ 已启用但无人设激活"
    fi
}

# Signal detection patterns
DETECT_PATTERNS='{
    "too_long": ["太长了", "太啰嗦", "废话太多", "精简", "简短"],
    "too_short": ["详细点", "展开说", "具体点", "举例", "解释一下"],
    "direct": ["直接说", "别废话", "给结论", "告诉我结果"],
    "cost": ["便宜", "免费", "开源", "白嫖", "省钱", "有没有更"],
    "aesthetic": ["好看", "优雅", "丑", "不美观", "设计感", "字体"],
    "humor": ["哈哈", "有意思", "有趣", "幽默", "笑死"],
    "detail": ["底层", "原理", "为什么", "怎么实现的", "技术细节"],
    "speed": ["快", "急", "马上", "尽快", "效率"]
}'

analyze_recent_conversations() {
    local memory_dir="$1"
    local hours="${2:-24}"
    local since=$(date -d "$hours hours ago" +%s 2>/dev/null || date -v-${hours}H +%s)
    
    # Collect recent memory files
    local signals_found=()
    local signal_types=()
    
    for f in "$memory_dir"/*.md; do
        [[ -f "$f" ]] || continue
        local file_time=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")
        [[ "$file_time" -lt "$since" ]] && continue
        
        local content=$(cat "$f")
        
        # Check each pattern
        while IFS= read -r pattern_type; do
            local patterns=$(echo "$DETECT_PATTERNS" | jq -r ".$pattern_type[]")
            while IFS= read -r pattern; do
                if echo "$content" | grep -q "$pattern"; then
                    signals_found+=("$pattern")
                    signal_types+=("$pattern_type")
                fi
            done <<< "$patterns"
        done < <(echo "$DETECT_PATTERNS" | jq -r 'keys[]')
    done
    
    # Count and return signals
    local unique_types=$(printf "%s\n" "${signal_types[@]}" | sort -u | jq -R . | jq -s .)
    local signal_count=${#signals_found[@]}
    
    jq -n \
        --argjson signals "$(printf '%s\n' "${signal_types[@]}" | sort | uniq -c | jq -R . | jq -s .)" \
        --argjson types "$unique_types" \
        --argjson count "$signal_count" \
        '{signals: $signals, types: $types, count: $count}'
}

update_persona_from_signals() {
    local persona_name="$1"
    local analysis="$2"
    local persona_file="${PERSONA_DIR}/${persona_name}.json"
    
    [[ ! -f "$persona_file" ]] && return 1
    
    local current_desc=$(jq -r '.description' "$persona_file")
    local updates=()
    
    # Generate updates based on detected signals
    echo "$analysis" | jq -r '.types[]' | while read -r type; do
        case "$type" in
            "too_long") updates+=(" prefers concise, short answers") ;;
            "too_short") updates+=(" sometimes wants detailed explanations") ;;
            "direct") updates+=(" wants direct answers without pleasantries") ;;
            "cost") updates+=(" strongly cost-conscious, prefers free/open-source") ;;
            "aesthetic") updates+=(" values visual design and aesthetics") ;;
            "humor") updates+=(" appreciates wit and humor") ;;
            "detail") updates+=(" wants technical depth and implementation details") ;;
            "speed") updates+=(" prioritizes speed and efficiency") ;;
        esac
    done
    
    # Update if we have changes
    if [[ ${#updates[@]} -gt 0 ]]; then
        local new_traits=$(printf " • %s\n" "${updates[@]}")
        local updated_desc="${current_desc}

Observed preferences (auto-detected):
${new_traits}"
        
        local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local log_entry=$(jq -n \
            --arg time "$now" \
            --argjson types "$(printf '%s\n' "${updates[@]}" | jq -R . | jq -s .)" \
            '{time: $time, detected_types: $types}')
        
        # Update persona file
        jq --arg desc "$updated_desc" \
           --arg updated "$now" \
           --argjson log_entry "$log_entry" \
           '.description = $desc | .updated = $updated | .evolutionLog += [$log_entry]' \
           "$persona_file" > "${persona_file}.tmp" && mv "${persona_file}.tmp" "$persona_file"
        
        # Log it
        echo "[$(date -Iseconds)] Updated '$persona_name': ${#updates[@]} new traits detected" >> "$LOG_FILE"
        
        echo "✓ Persona '$persona_name' evolved with ${#updates[@]} new traits:"
        printf "  - %s\n" "${updates[@]}"
    else
        echo "○ No evolution signals detected"
    fi
}

run_evolution() {
    local force="${1:-}"
    
    # Check if enabled
    if [[ "$force" != "force" && "$(is_enabled)" != "true" ]]; then
        echo "Auto-evolution is disabled. Use 'enable' to activate or 'run force' to run once."
        return 1
    fi
    
    local active=$(get_active_persona)
    if [[ -z "$active" ]]; then
        echo "No active persona to evolve"
        return 1
    fi
    
    echo "Running auto-evolution analysis..."
    echo "Active persona: $active"
    
    # Analyze conversations
    local analysis=$(analyze_recent_conversations "$MEMORY_DIR" 24)
    local signal_count=$(echo "$analysis" | jq -r '.count')
    
    echo "Signals detected in last 24h: $signal_count"
    
    # Get threshold
    local threshold=$(jq -r '.threshold // 3' "$STATE_FILE")
    
    if [[ "$signal_count" -ge "$threshold" || "$force" == "force" ]]; then
        echo "Threshold met ($signal_count >= $threshold), updating persona..."
        update_persona_from_signals "$active" "$analysis"
        
        # Update state
        local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        jq --arg time "$now" \
           --argjson count "$signal_count" \
           '.lastRun = $time | .signalCount = $count' \
           "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    else
        echo "Signals below threshold ($threshold), skipping update"
        
        # Still update count
        jq --argjson count "$signal_count" '.signalCount = $count' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
}

view_log() {
    if [[ -f "$LOG_FILE" ]]; then
        echo "Evolution Log:"
        echo "=============="
        tail -50 "$LOG_FILE"
    else
        echo "No evolution log yet"
    fi
}

config() {
    local key="$1"
    local val="$2"
    
    jq --arg key "$key" --argjson val "$val" '.[$key] = $val' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "✓ Config updated: $key = $val"
}

# Main
case "${1:-}" in
    enable) enable ;;
    disable) disable ;;
    status) show_status ;;
    run) shift; run_evolution "$@" ;;
    config) shift; config "$@" ;;
    log) view_log ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
