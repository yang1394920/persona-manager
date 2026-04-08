#!/usr/bin/env bash
# signal-detector.sh - 实时信号检测器
# 可以 hook 到对话处理流程中

PERSONA_DIR="${PERSONA_DIR:-./personas}"
MEMORY_DIR="${MEMORY_DIR:-../../memory}"
SIGNAL_QUEUE="${PERSONA_DIR}/.signal-queue.json"

# Initialize signal queue
if [[ ! -f "$SIGNAL_QUEUE" ]]; then
    jq -n '{signals: [], lastProcessed: null}' > "$SIGNAL_QUEUE"
fi

# Signal patterns with weights and confidence levels
declare -A SIGNAL_PATTERNS=(
    # Too long / verbose
    ["太长了"]="too_long:3:0.9"
    ["太啰嗦"]="too_long:3:0.9"
    ["精简点"]="too_long:2:0.8"
    ["简短"]="too_long:2:0.7"
    ["废话"]="too_long:3:0.9"
    
    # Too short / need detail
    ["详细点"]="need_detail:2:0.8"
    ["展开说"]="need_detail:2:0.8"
    ["具体点"]="need_detail:2:0.8"
    ["解释一下"]="need_detail:2:0.7"
    ["为什么"]="need_detail:1:0.6"
    
    # Direct / no pleasantries
    ["直接说"]="direct:3:0.9"
    ["别废话"]="direct:3:0.9"
    ["给结论"]="direct:2:0.8"
    ["告诉我结果"]="direct:2:0.8"
    ["只需要"]="direct:1:0.6"
    
    # Cost conscious
    ["便宜"]="cost:2:0.8"
    ["免费"]="cost:3:0.9"
    ["开源"]="cost:2:0.8"
    ["省钱"]="cost:3:0.9"
    ["有没有更便宜"]="cost:2:0.8"
    
    # Aesthetic
    ["好看"]="aesthetic:2:0.8"
    ["优雅"]="aesthetic:2:0.8"
    ["丑"]="aesthetic:2:0.8"
    ["不美观"]="aesthetic:2:0.8"
    ["设计感"]="aesthetic:3:0.9"
    ["字体"]="aesthetic:1:0.6"
    ["颜色"]="aesthetic:1:0.6"
    
    # Humor appreciation
    ["哈哈"]="humor:2:0.7"
    ["有意思"]="humor:2:0.8"
    ["有趣"]="humor:2:0.8"
    ["幽默"]="humor:3:0.9"
    ["笑死"]="humor:2:0.8"
    
    # Technical depth
    ["底层"]="technical:2:0.8"
    ["原理"]="technical:2:0.8"
    ["怎么实现"]="technical:2:0.8"
    ["技术细节"]="technical:3:0.9"
    ["性能"]="technical:1:0.6"
    ["架构"]="technical:2:0.7"
    
    # Speed / efficiency
    ["快"]="speed:1:0.6"
    ["急"]="speed:2:0.8"
    ["马上"]="speed:2:0.8"
    ["尽快"]="speed:2:0.8"
    ["效率"]="speed:2:0.8"
    
    # Positive feedback (reinforce current style)
    ["完美"]="positive:3:0.9"
    ["正是我要的"]="positive:3:0.9"
    ["很好"]="positive:2:0.7"
    ["不错"]="positive:1:0.6"
    ["符合预期"]="positive:2:0.8"
    
    # Negative feedback (contradict current style)
    ["不对"]="negative:2:0.8"
    ["错了"]="negative:2:0.8"
    ["不行"]="negative:2:0.7"
    ["不是这样"]="negative:2:0.8"
    ["你应该"]="negative:1:0.6"
)

detect_signals_in_text() {
    local text="$1"
    local signals_detected=()
    
    for pattern in "${!SIGNAL_PATTERNS[@]}"; do
        if echo "$text" | grep -q "$pattern"; then
            signals_detected+=("${SIGNAL_PATTERNS[$pattern]}")
        fi
    done
    
    # Output as JSON
    if [[ ${#signals_detected[@]} -gt 0 ]]; then
        printf '%s\n' "${signals_detected[@]}" | \
        awk -F: '{print "{\"type\":\""$1"\",\"weight\":"$2",\"confidence\":"$3"}"}' | \
        jq -s '.'
    else
        echo '[]'
    fi
}

# Add signal to queue
queue_signal() {
    local signal_type="$1"
    local weight="$2"
    local confidence="$3"
    local context="$4"
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local signal=$(jq -n \
        --arg type "$signal_type" \
        --argjson weight "$weight" \
        --argjson confidence "$confidence" \
        --arg context "$context" \
        --arg time "$now" \
        '{type: $type, weight: $weight, confidence: $confidence, context: $context, time: $time}')
    
    jq --argjson sig "$signal" '.signals += [$sig]' "$SIGNAL_QUEUE" > "${SIGNAL_QUEUE}.tmp" && \
        mv "${SIGNAL_QUEUE}.tmp" "$SIGNAL_QUEUE"
}

# Process a message (call this when user sends a message)
process_message() {
    local message="$1"
    local active_persona="${2:-$(cat "${PERSONA_DIR}/.active" 2>/dev/null)}"
    
    [[ -z "$active_persona" ]] && return 1
    
    local signals=$(detect_signals_in_text "$message")
    local count=$(echo "$signals" | jq 'length')
    
    if [[ "$count" -gt 0 ]]; then
        echo "$signals" | jq -c '.[]' | while read -r signal; do
            local sig_type=$(echo "$signal" | jq -r '.type')
            local weight=$(echo "$signal" | jq -r '.weight')
            local conf=$(echo "$signal" | jq -r '.confidence')
            
            queue_signal "$sig_type" "$weight" "$conf" "$message"
        done
        
        echo "Detected $count signals in message"
        return 0
    fi
    
    return 1
}

# Get accumulated signals summary
get_signal_summary() {
    local hours="${1:-24}"
    local since=$(date -d "$hours hours ago" +%s 2>/dev/null || date -v-${hours}H +%s)
    
    cat "$SIGNAL_QUEUE" | jq --argjson since "$since" '
        .signals | 
        map(select((.time | fromdateiso8601 // 0) >= $since)) |
        group_by(.type) |
        map({
            type: .[0].type,
            count: length,
            total_weight: map(.weight) | add,
            avg_confidence: map(.confidence) | add / length
        }) |
        sort_by(.total_weight) | reverse
    '
}

# Check if threshold met for auto-update
should_auto_update() {
    local threshold="${1:-10}"  # Default weight threshold
    local summary=$(get_signal_summary 24)
    local total_weight=$(echo "$summary" | jq 'map(.total_weight) | add // 0')
    
    if [[ "$total_weight" -ge "$threshold" ]]; then
        echo "true"
        echo "$summary"
    else
        echo "false"
        echo "$summary"
    fi
}

# Clear processed signals
clear_signals() {
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg time "$now" '{signals: [], lastProcessed: $time}' "$SIGNAL_QUEUE" > "${SIGNAL_QUEUE}.tmp" && \
        mv "${SIGNAL_QUEUE}.tmp" "$SIGNAL_QUEUE"
}

# Export signals for external processing
export_signals() {
    cat "$SIGNAL_QUEUE"
}

# Main
case "${1:-}" in
    detect) 
        shift
        detect_signals_in_text "$1"
        ;;
    process)
        shift
        process_message "$1" "$2"
        ;;
    summary)
        shift
        get_signal_summary "${1:-24}"
        ;;
    check)
        should_auto_update "${2:-10}"
        ;;
    clear)
        clear_signals
        ;;
    export)
        export_signals
        ;;
    *)
        echo "Signal Detector - 实时信号检测"
        echo ""
        echo "Usage:"
        echo "  detect '<text>'       - 检测文本中的信号"
        echo "  process '<msg>' [p]   - 处理消息并加入队列"
        echo "  summary [hours]       - 获取信号汇总 (默认24h)"
        echo "  check [threshold]       - 检查是否达到更新阈值"
        echo "  clear                 - 清空已处理信号"
        echo "  export                - 导出所有信号"
        ;;
esac
