#!/usr/bin/env bash
# persona-manager main script
# Handles: set, show, use, list, combine

PERSONA_DIR="${SKILL_ROOT:-.}/personas"
ACTIVE_PERSONA_FILE="${PERSONA_DIR}/.active"

# Ensure directory exists
mkdir -p "$PERSONA_DIR"

show_help() {
    echo "Usage:"
    echo "  set <name> <description>     - Create/update a persona"
    echo "  show [name]                   - Show persona details (or active one)"
    echo "  use <name>                    - Activate a persona"
    echo "  list                          - List all personas"
    echo "  combine <n1,n2,...> [as <n>]  - Combine multiple personas"
    echo "  clear                         - Clear active persona"
    echo "  delete <name>                 - Delete a persona"
}

create_persona() {
    local name="$1"
    shift
    local description="$*"
    
    if [[ -z "$name" || -z "$description" ]]; then
        echo "Error: Name and description required"
        exit 1
    fi
    
    local file="$PERSONA_DIR/${name}.json"
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Read existing tags if updating
    local tags="[]"
    if [[ -f "$file" ]]; then
        tags=$(jq -r '.tags // []' "$file" 2>/dev/null || echo "[]")
    fi
    
    jq -n \
        --arg name "$name" \
        --arg desc "$description" \
        --argjson tags "$tags" \
        --arg created "$now" \
        --arg updated "$now" \
        '{name: $name, description: $desc, tags: $tags, created: $created, updated: $updated}' \
        > "$file"
    
    # If first persona or no active one, auto-activate
    if [[ ! -f "$ACTIVE_PERSONA_FILE" ]] || [[ -z "$(cat "$ACTIVE_PERSONA_FILE" 2>/dev/null)" ]]; then
        echo "$name" > "$ACTIVE_PERSONA_FILE"
        echo "✓ Persona '$name' created and activated"
    else
        echo "✓ Persona '$name' created/updated"
    fi
}

show_persona() {
    local name="${1:-$(cat "$ACTIVE_PERSONA_FILE" 2>/dev/null)}"
    
    if [[ -z "$name" ]]; then
        echo "No active persona. Use: use <name>"
        exit 1
    fi
    
    local file="$PERSONA_DIR/${name}.json"
    if [[ ! -f "$file" ]]; then
        echo "Persona '$name' not found"
        exit 1
    fi
    
    ACTIVE="$(cat "$ACTIVE_PERSONA_FILE" 2>/dev/null)"
    cat "$file" | jq -r --arg active "$ACTIVE" '
        "Name: \(.name)",
        "Active: \(if $active == .name then "✓" else "" end)",
        "Tags: \(.tags | join(", ") // "none")",
        "Created: \(.created)",
        "Updated: \(.updated)",
        "",
        "Description:",
        "\(.description)"
    '
}

use_persona() {
    local name="$1"
    local file="$PERSONA_DIR/${name}.json"
    
    if [[ ! -f "$file" ]]; then
        echo "Persona '$name' not found. Use 'list' to see available personas."
        exit 1
    fi
    
    echo "$name" > "$ACTIVE_PERSONA_FILE"
    
    # Update timestamp
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg updated "$now" '.updated = $updated' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    
    echo "✓ Now using persona: $name"
    echo ""
    show_persona "$name"
}

list_personas() {
    local active=$(cat "$ACTIVE_PERSONA_FILE" 2>/dev/null)
    
    echo "Available personas:"
    echo ""
    
    for f in "$PERSONA_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == ".active" ]] && continue
        
        local name=$(jq -r '.name' "$f")
        local prefix="  "
        [[ "$name" == "$active" ]] && prefix="✓ "
        
        local desc=$(jq -r '.description[:50] + "..."' "$f")
        local tags=$(jq -r '.tags | join(", ") // ""' "$f")
        
        echo "${prefix}${name}"
        [[ -n "$tags" ]] && echo "     tags: $tags"
        echo "     ${desc}"
        echo ""
    done
}

combine_personas() {
    local names="$1"
    local new_name=""
    shift
    
    # Parse "as <name>" if provided
    if [[ "$1" == "as" && -n "$2" ]]; then
        new_name="$2"
    fi
    
    # Split comma-separated names
    IFS=',' read -ra NAME_ARRAY <<< "$names"
    
    local descriptions=()
    local all_tags=()
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    for n in "${NAME_ARRAY[@]}"; do
        n=$(echo "$n" | xargs) # trim
        local file="$PERSONA_DIR/${n}.json"
        
        if [[ ! -f "$file" ]]; then
            echo "Persona '$n' not found"
            exit 1
        fi
        
        local desc=$(jq -r '.description' "$file")
        local tags=$(jq -r '.tags[]' "$file" 2>/dev/null)
        
        descriptions+=("[$n] $desc")
        all_tags+=("$tags")
    done
    
    # Generate default name if not provided
    if [[ -z "$new_name" ]]; then
        new_name=$(IFS='-'; echo "${NAME_ARRAY[*]}")
    fi
    
    # Combine
    local combined_desc=$(printf "%s\n\n" "${descriptions[@]}")
    local unique_tags=$(printf "%s\n" "${all_tags[@]}" | sort -u | jq -R . | jq -s .)
    
    jq -n \
        --arg name "$new_name" \
        --arg desc "$combined_desc" \
        --argjson tags "$unique_tags" \
        --arg created "$now" \
        --arg updated "$now" \
        --argjson source "$(printf '%s\n' "${NAME_ARRAY[@]}" | jq -R . | jq -s .)" \
        '{name: $name, description: $desc, tags: $tags, created: $created, updated: $updated, combined_from: $source}' \
        > "$PERSONA_DIR/${new_name}.json"
    
    # Auto-activate
    echo "$new_name" > "$ACTIVE_PERSONA_FILE"
    echo "✓ Combined persona '$new_name' created and activated"
}

clear_persona() {
    rm -f "$ACTIVE_PERSONA_FILE"
    echo "✓ Active persona cleared"
}

delete_persona() {
    local name="$1"
    local file="$PERSONA_DIR/${name}.json"
    
    if [[ ! -f "$file" ]]; then
        echo "Persona '$name' not found"
        exit 1
    fi
    
    rm "$file"
    
    # Clear if it was active
    local active=$(cat "$ACTIVE_PERSONA_FILE" 2>/dev/null)
    [[ "$active" == "$name" ]] && rm -f "$ACTIVE_PERSONA_FILE"
    
    echo "✓ Persona '$name' deleted"
}

# Main
case "${1:-}" in
    set) shift; create_persona "$@" ;;
    show) shift; show_persona "$@" ;;
    use) shift; use_persona "$@" ;;
    list) list_personas ;;
    combine) shift; combine_personas "$@" ;;
    clear) clear_persona ;;
    delete) shift; delete_persona "$@" ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
