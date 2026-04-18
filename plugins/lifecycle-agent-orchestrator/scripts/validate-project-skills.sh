#!/bin/bash
# Lifecycle Agent Orchestrator — Project Skills Validation
# Validates a consuming project's overlay, domain, and extra role structure.
#
# Usage:
#   ./validate-project-skills.sh <path-to-project-skills-dir>       # Convention mode
#   ./validate-project-skills.sh --config <path-to-lao.config.yaml> # Config mode
#   ./validate-project-skills.sh --scan <path-to-project-root>       # Scan mode

set -e

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

BASE_ROLES=(
    "lao"
    "lao-dry-run"
    "lao-setup"
    "product-management"
    "intake"
    "experience-design"
    "architecture"
    "coding-standards"
    "testing-conventions"
    "code-review"
    "security"
    "acceptance-validation"
    "shipping"
)

VALID_APPLIES_TO=(
    "all"
    "product-management"
    "intake"
    "experience-design"
    "architecture"
    "coding-standards"
    "testing-conventions"
    "code-review"
    "security"
    "acceptance-validation"
    "shipping"
)

LAO_KEYWORDS="architecture|coding-standards|testing-conventions|code-review|shipping|experience-design|product-management|intake|acceptance-validation|design|conventions|standards|patterns|domain"

is_base_role() {
    local name="$1"
    for role in "${BASE_ROLES[@]}"; do
        [ "$role" = "$name" ] && return 0
    done
    return 1
}

is_valid_applies_to() {
    local value="$1"
    for valid in "${VALID_APPLIES_TO[@]}"; do
        [ "$valid" = "$value" ] && return 0
    done
    return 1
}

has_frontmatter() {
    local file="$1"
    head -1 "$file" 2>/dev/null | grep -q "^---"
}

has_field() {
    local file="$1"
    local field="$2"
    awk '/^---$/{n++; next} n==1' "$file" | grep -q "^${field}:"
}

check_domain_file() {
    local file="$1"
    local label="$2"

    if has_frontmatter "$file"; then
        pass "$label has frontmatter"
        if has_field "$file" "name"; then
            pass "$label has name"
        else
            fail "$label MISSING name in frontmatter"
        fi
        if has_field "$file" "description"; then
            pass "$label has description"
        else
            fail "$label MISSING description in frontmatter"
        fi

        local applies_line
        applies_line=$(awk '/^---$/{n++; next} n==1' "$file" | grep "^applies_to:" || true)
        if [ -n "$applies_line" ]; then
            local values
            values=$(echo "$applies_line" | sed 's/^applies_to:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            for val in $values; do
                if is_valid_applies_to "$val"; then
                    pass "$label applies_to value '$val' is valid"
                else
                    fail "$label applies_to value '$val' is not a recognized role (expected: ${VALID_APPLIES_TO[*]})"
                fi
            done
        else
            pass "$label — no applies_to (defaults to 'all')"
        fi
    else
        warn "$label MISSING frontmatter — will be treated as applies_to: all with filename as name"
    fi
}

check_extra_role_file() {
    local file="$1"
    local label="$2"

    if has_frontmatter "$file"; then
        pass "$label has frontmatter"
        if has_field "$file" "name"; then
            pass "$label has name"
        else
            fail "$label MISSING name in frontmatter"
        fi
        if has_field "$file" "description"; then
            pass "$label has description"
        else
            fail "$label MISSING description in frontmatter"
        fi

        local applies_line
        applies_line=$(awk '/^---$/{n++; next} n==1' "$file" | grep "^applies_to:" || true)
        if [ -n "$applies_line" ]; then
            local values
            values=$(echo "$applies_line" | sed 's/^applies_to:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            for val in $values; do
                if is_valid_applies_to "$val"; then
                    pass "$label applies_to value '$val' is valid"
                else
                    fail "$label applies_to value '$val' is not a recognized role (expected: ${VALID_APPLIES_TO[*]})"
                fi
            done
        else
            warn "$label MISSING applies_to — this role will NOT be loaded at any phase. Add applies_to to specify when it should be active."
        fi
    else
        fail "$label MISSING frontmatter (no --- header)"
    fi
}

print_summary() {
    echo ""
    echo "=== Summary ==="
    echo "  Passed: $PASS"
    echo "  Failed: $FAIL"
    echo "  Warnings: $WARN"
    echo ""

    if [ $FAIL -eq 0 ]; then
        echo "✅ Validation PASSED"
        exit 0
    else
        echo "❌ Validation FAILED ($FAIL issues)"
        exit 1
    fi
}

# ============================================================
# Mode: --config
# ============================================================
run_config_mode() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        echo "Error: config file '$config_file' does not exist."
        exit 1
    fi

    local config_dir
    config_dir="$(cd "$(dirname "$config_file")" && pwd)"

    echo "=== LAO Config Validation ==="
    echo "Config file: $config_file"
    echo ""

    # --- project_name ---
    echo "--- Project Name ---"
    local project_name
    project_name=$(grep "^project_name:" "$config_file" | sed 's/^project_name:[[:space:]]*//' | tr -d '"' | tr -d "'" | sed 's/[[:space:]]*$//')
    if [ -n "$project_name" ]; then
        pass "project_name: $project_name"
    else
        fail "project_name is MISSING (required)"
    fi
    echo ""

    # --- languages ---
    echo "--- Languages ---"
    local VALID_LANGUAGES="python java csharp react"
    local languages_found=0

    # Check for 'languages:' list (new format)
    local in_languages=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "^languages:"; then
            in_languages=1
            continue
        fi
        if [ $in_languages -eq 1 ]; then
            if echo "$line" | grep -q "^[[:space:]]*-[[:space:]]"; then
                local lang_val
                lang_val=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | tr -d '"' | tr -d "'" | sed 's/[[:space:]]*$//')
                if echo "$VALID_LANGUAGES" | grep -qw "$lang_val"; then
                    pass "languages[]: $lang_val"
                    languages_found=$((languages_found + 1))
                else
                    fail "languages[] '$lang_val' is not valid (expected: $VALID_LANGUAGES)"
                fi
            elif echo "$line" | grep -q "^[a-z]"; then
                break
            fi
        fi
    done < "$config_file"

    # Fallback: check for 'language:' string (backward compat)
    if [ $languages_found -eq 0 ]; then
        local language
        language=$(grep "^language:" "$config_file" 2>/dev/null | sed 's/^language:[[:space:]]*//' | tr -d '"' | tr -d "'" | sed 's/[[:space:]]*$//' || true)
        if [ -n "$language" ]; then
            if echo "$VALID_LANGUAGES" | grep -qw "$language"; then
                pass "language: $language"
            else
                fail "language '$language' is not valid (expected: $VALID_LANGUAGES)"
            fi
        else
            pass "language(s) not set (will auto-detect at runtime)"
        fi
    fi
    echo ""

    # --- Overlays ---
    echo "--- Overlays ---"
    local in_overlays=0
    local overlay_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "^overlays:"; then
            in_overlays=1
            continue
        fi
        if [ $in_overlays -eq 1 ]; then
            if echo "$line" | grep -qE "^[a-z]" || [ -z "$line" ]; then
                break
            fi
            if echo "$line" | grep -qE "^  [a-z]"; then
                local key val
                key=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f1)
                val=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")

                if is_base_role "$key"; then
                    pass "overlay key '$key' matches a base role"
                else
                    fail "overlay key '$key' does NOT match any base role"
                fi

                local full_path="$config_dir/$val"
                if [ -f "$full_path" ]; then
                    pass "overlay file exists: $val"
                    overlay_count=$((overlay_count + 1))
                else
                    fail "overlay file NOT found: $val"
                fi
            fi
        fi
    done < "$config_file"
    echo ""
    echo "  Overlays found: $overlay_count"
    echo ""

    # --- Workflows ---
    echo "--- Workflow Overrides ---"
    local VALID_WORKFLOW_KEYS="plan implement validate ship"
    local in_workflows=0
    local workflow_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "^workflows:"; then
            in_workflows=1
            continue
        fi
        if [ $in_workflows -eq 1 ]; then
            if echo "$line" | grep -qE "^[a-z]" || [ -z "$line" ]; then
                break
            fi
            if echo "$line" | grep -qE "^  #"; then
                continue
            fi
            if echo "$line" | grep -qE "^  [a-z]"; then
                local key val
                key=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f1)
                val=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")

                if echo "$VALID_WORKFLOW_KEYS" | grep -qw "$key"; then
                    pass "workflow key '$key' is valid"
                else
                    fail "workflow key '$key' is not valid (expected: $VALID_WORKFLOW_KEYS)"
                fi

                local full_path="$config_dir/$val"
                if [ -f "$full_path" ]; then
                    pass "workflow file exists: $val"
                    workflow_count=$((workflow_count + 1))
                else
                    fail "workflow file NOT found: $val"
                fi
            fi
        fi
    done < "$config_file"
    echo ""
    echo "  Workflow overrides found: $workflow_count"
    echo ""

    # --- Domain ---
    echo "--- Domain Context ---"
    local in_domain=0
    local domain_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "^domain:"; then
            in_domain=1
            continue
        fi
        if [ $in_domain -eq 1 ]; then
            if echo "$line" | grep -qE "^[a-z]"; then
                break
            fi
            if echo "$line" | grep -qE "^  - "; then
                local entry
                entry=$(echo "$line" | sed 's/^[[:space:]]*- //' | tr -d '"' | tr -d "'")

                if echo "$entry" | grep -q '[*?]'; then
                    local expanded
                    expanded=$(cd "$config_dir" && ls -1 $entry 2>/dev/null || true)
                    if [ -z "$expanded" ]; then
                        warn "domain glob '$entry' matched no files"
                    else
                        while IFS= read -r match; do
                            local full_path="$config_dir/$match"
                            if [ -f "$full_path" ]; then
                                domain_count=$((domain_count + 1))
                                check_domain_file "$full_path" "domain: $match"
                            fi
                        done <<< "$expanded"
                    fi
                else
                    local full_path="$config_dir/$entry"
                    if [ -f "$full_path" ]; then
                        domain_count=$((domain_count + 1))
                        check_domain_file "$full_path" "domain: $entry"
                    else
                        fail "domain file NOT found: $entry"
                    fi
                fi
            fi
        fi
    done < "$config_file"
    echo ""
    echo "  Domain files found: $domain_count"
    echo ""

    # --- Extra Roles ---
    echo "--- Extra Roles ---"
    local in_extra=0
    local extra_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "^extra_roles:"; then
            in_extra=1
            continue
        fi
        if [ $in_extra -eq 1 ]; then
            if echo "$line" | grep -qE "^[a-z]" || [ -z "$line" ]; then
                break
            fi
            if echo "$line" | grep -qE "^  [a-z]"; then
                local key val
                key=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f1)
                val=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr -d '"' | tr -d "'")

                if is_base_role "$key"; then
                    fail "extra_role key '$key' matches a base role — use overlays section instead"
                else
                    pass "extra_role key '$key' is a valid custom role name"
                fi

                local full_path="$config_dir/$val"
                if [ -f "$full_path" ]; then
                    extra_count=$((extra_count + 1))
                    check_extra_role_file "$full_path" "extra_role: $key ($val)"
                else
                    fail "extra_role file NOT found: $val"
                fi
            fi
        fi
    done < "$config_file"
    echo ""
    echo "  Extra roles found: $extra_count"
    echo ""

    print_summary
}

# ============================================================
# Mode: --scan
# ============================================================
run_scan_mode() {
    local project_root="$1"

    if [ ! -d "$project_root" ]; then
        echo "Error: directory '$project_root' does not exist."
        exit 1
    fi

    project_root="$(cd "$project_root" && pwd)"

    echo "=== LAO Project Scan ==="
    echo "Scanning: $project_root"
    echo ""

    local found=0

    # Check for existing config
    if [ -f "$project_root/lao.config.yaml" ]; then
        echo "  Found lao.config.yaml — this project uses config-based discovery."
        echo "  Run with --config to validate it."
        echo ""
    fi

    # Check for convention directory
    local convention_dirs
    convention_dirs=$(find "$project_root/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)
    if [ -n "$convention_dirs" ]; then
        echo "  Found convention directory: skills/"
        echo "  Run without flags to validate: $0 <skills-dir>"
        echo ""
    fi

    echo "--- Potential Overlay Files ---"
    echo ""

    while IFS= read -r file; do
        [ -f "$file" ] || continue
        local rel_path="${file#$project_root/}"

        # Skip convention directory and node_modules/.git
        case "$rel_path" in
            skills/*|node_modules/*|.git/*|*.min.*) continue ;;
        esac

        local basename_lower
        basename_lower=$(basename "$file" .md | tr '[:upper:]' '[:lower:]')

        if echo "$basename_lower" | grep -qE "$LAO_KEYWORDS"; then
            echo "  $rel_path"
            found=$((found + 1))
        fi
    done < <(find "$project_root" -name "*.md" -type f 2>/dev/null)

    echo ""
    echo "--- Potential Domain Files (with frontmatter) ---"
    echo ""

    while IFS= read -r file; do
        [ -f "$file" ] || continue
        local rel_path="${file#$project_root/}"

        case "$rel_path" in
            skills/*|node_modules/*|.git/*) continue ;;
        esac

        if has_frontmatter "$file" && has_field "$file" "name" && has_field "$file" "description"; then
            echo "  $rel_path"
            found=$((found + 1))
        fi
    done < <(find "$project_root" -name "*.md" -type f 2>/dev/null)

    echo ""
    echo "=== Scan Complete ==="
    echo "  Potential files found: $found"
    echo ""

    if [ $found -gt 0 ]; then
    echo "  Consider adding these to lao.config.yaml or moving them to"
    echo "  the convention directory (skills/)."
    else
        echo "  No potential skill files found outside convention paths."
    fi
}

# ============================================================
# Mode: Convention (existing behavior)
# ============================================================
run_convention_mode() {
    local PROJECT_DIR="$1"

    echo "=== LAO Project Skills Validation ==="
    echo "Project directory: $PROJECT_DIR"
    echo ""

    # --- Role Overlays ---
    echo "--- Role Overlays ---"

    local OVERLAY_COUNT=0
    for dir in "$PROJECT_DIR"/*/; do
        [ -d "$dir" ] || continue
        local dirname
        dirname="$(basename "$dir")"
        [ "$dirname" = "domain" ] && continue

        if [ -f "$dir/PROJECT.md" ]; then
            if is_base_role "$dirname"; then
                pass "overlay: $dirname/PROJECT.md"
                OVERLAY_COUNT=$((OVERLAY_COUNT + 1))
            else
                warn "$dirname/PROJECT.md — directory name does not match any base role (did you mean one of: ${BASE_ROLES[*]})?"
            fi
        elif [ -f "$dir/SKILL.md" ]; then
            : # handled in extra roles section
        else
            warn "$dirname/ — directory has neither PROJECT.md nor SKILL.md"
        fi
    done

    echo ""
    echo "  Overlays found: $OVERLAY_COUNT"
    echo ""

    # --- Extra Project Roles ---
    echo "--- Extra Project Roles ---"

    local EXTRA_COUNT=0
    for dir in "$PROJECT_DIR"/*/; do
        [ -d "$dir" ] || continue
        local dirname
        dirname="$(basename "$dir")"
        [ "$dirname" = "domain" ] && continue
        [ -f "$dir/SKILL.md" ] || continue

        if is_base_role "$dirname"; then
            warn "$dirname/SKILL.md — matches a base role name. Use PROJECT.md for overlays, SKILL.md for standalone roles."
            continue
        fi

        EXTRA_COUNT=$((EXTRA_COUNT + 1))
        check_extra_role_file "$dir/SKILL.md" "$dirname/SKILL.md"
    done

    echo ""
    echo "  Extra roles found: $EXTRA_COUNT"
    echo ""

    # --- Domain Context ---
    echo "--- Domain Context ---"

    local DOMAIN_DIR="$PROJECT_DIR/domain"

    if [ -d "$DOMAIN_DIR" ]; then
        local DOMAIN_COUNT=0

        for file in "$DOMAIN_DIR"/*; do
            [ -f "$file" ] || continue
            local filename
            filename="$(basename "$file")"

            if [[ "$filename" != *.md ]]; then
                warn "domain/$filename — not a .md file (will be ignored by orchestrator)"
                continue
            fi

            DOMAIN_COUNT=$((DOMAIN_COUNT + 1))
            check_domain_file "$file" "domain/$filename"
        done

        echo ""
        echo "  Domain files found: $DOMAIN_COUNT"
    else
        echo "  No domain/ directory found (optional — skipping)"
    fi

    echo ""

    print_summary
}

# ============================================================
# Entry point — route to the right mode
# ============================================================

show_usage() {
    echo "Usage:"
    echo "  $0 <path-to-project-skills-dir>        # Validate convention-based project"
    echo "  $0 --config <path-to-lao.config.yaml>  # Validate config-based project"
    echo "  $0 --scan <path-to-project-root>         # Scan project for potential skill files"
    echo ""
    echo "Examples:"
    echo "  $0 ./skills"
    echo "  $0 --config lao.config.yaml"
    echo "  $0 --scan /path/to/my-project"
    exit 1
}

if [ -z "$1" ]; then
    show_usage
fi

case "$1" in
    --config)
        [ -z "$2" ] && { echo "Error: --config requires a path to lao.config.yaml"; exit 1; }
        run_config_mode "$2"
        ;;
    --scan)
        [ -z "$2" ] && { echo "Error: --scan requires a path to the project root"; exit 1; }
        run_scan_mode "$2"
        ;;
    --*)
        echo "Error: unknown flag '$1'"
        show_usage
        ;;
    *)
        PROJECT_DIR="$(cd "$1" 2>/dev/null && pwd)" || {
            echo "Error: directory '$1' does not exist."
            exit 1
        }
        run_convention_mode "$PROJECT_DIR"
        ;;
esac
