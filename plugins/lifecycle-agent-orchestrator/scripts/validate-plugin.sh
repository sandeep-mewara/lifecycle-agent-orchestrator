#!/bin/bash
# Lifecycle Agent Orchestrator Plugin Validation
# Verifies the plugin structure is intact and all required files exist.
# Run from the lifecycle-agent-orchestrator/ directory: ./scripts/validate-plugin.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "=== Lifecycle Agent Orchestrator Plugin Validation ==="
echo "Plugin directory: $PLUGIN_DIR"
echo ""

# --- Plugin Manifest ---
echo "--- Plugin Manifest ---"

if [ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    pass ".claude-plugin/plugin.json exists"
else
    fail ".claude-plugin/plugin.json MISSING"
fi

if command -v claude &> /dev/null; then
    if claude plugins validate "$PLUGIN_DIR" 2>&1 | grep -q "Validation passed"; then
        pass "Plugin manifest passes Claude Code validation"
    else
        fail "Plugin manifest failed Claude Code validation"
        claude plugins validate "$PLUGIN_DIR" 2>&1 | grep -v "^$"
    fi
else
    warn "Claude CLI not available — skipping manifest validation"
fi

# --- Cursor Plugin Manifest ---
echo "--- Cursor Plugin Manifest ---"

if [ -f "$PLUGIN_DIR/.cursor-plugin/plugin.json" ]; then
    pass ".cursor-plugin/plugin.json exists"

    CURSOR_JSON="$PLUGIN_DIR/.cursor-plugin/plugin.json"
    for field in name description version skills; do
        if grep -q "\"$field\"" "$CURSOR_JSON"; then
            pass "Cursor plugin.json has '$field' field"
        else
            fail "Cursor plugin.json MISSING '$field' field"
        fi
    done

    CURSOR_SKILLS=$(grep '"skills"' "$CURSOR_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/')
    CLAUDE_SKILLS=$(grep '"skills"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
    if [ "$CURSOR_SKILLS" = "$CLAUDE_SKILLS" ]; then
        pass "Cursor skills path ('$CURSOR_SKILLS') matches Claude Code skills path"
    else
        fail "Cursor skills path ('$CURSOR_SKILLS') does NOT match Claude Code ('$CLAUDE_SKILLS')"
    fi
else
    fail ".cursor-plugin/plugin.json MISSING"
fi

echo ""

# --- Skills ---
echo "--- Skills (13 expected) ---"

EXPECTED_SKILLS=(
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

SKILL_COUNT=0
for skill in "${EXPECTED_SKILLS[@]}"; do
    if [ -f "$PLUGIN_DIR/skills/$skill/SKILL.md" ]; then
        pass "skills/$skill/SKILL.md"
        SKILL_COUNT=$((SKILL_COUNT + 1))
    else
        fail "skills/$skill/SKILL.md MISSING"
    fi
done

echo ""
echo "  Skills found: $SKILL_COUNT / ${#EXPECTED_SKILLS[@]}"
echo ""

# --- Skill Frontmatter ---
echo "--- Skill Frontmatter ---"

for skill in "${EXPECTED_SKILLS[@]}"; do
    SKILL_FILE="$PLUGIN_DIR/skills/$skill/SKILL.md"
    if [ -f "$SKILL_FILE" ]; then
        if head -1 "$SKILL_FILE" | grep -q "^---"; then
            if grep -q "^name:" "$SKILL_FILE"; then
                pass "$skill has name in frontmatter"
            else
                fail "$skill MISSING name in frontmatter"
            fi
            if grep -q "^description:" "$SKILL_FILE"; then
                pass "$skill has description in frontmatter"
            else
                fail "$skill MISSING description in frontmatter"
            fi
        else
            fail "$skill MISSING frontmatter (no --- header)"
        fi
    fi
done

echo ""

# --- References ---
echo "--- References ---"

EXPECTED_REFS=(
    "skills/architecture/references/architecture-template.md"
    "skills/architecture/references/review-checklist.md"
    "skills/product-management/references/prd-template.md"
    "skills/intake/references/scope-summary-template.md"
    "skills/experience-design/references/design-spec-template.md"
    "skills/acceptance-validation/references/validation-report-template.md"
    "skills/shipping/references/pr-template.md"
    "skills/lao/references/phase-workflows.md"
    # coding-standards: universal + language packs
    "skills/coding-standards/references/checklist.md"
    "skills/coding-standards/references/python/checklist.md"
    "skills/coding-standards/references/python/examples.md"
    "skills/coding-standards/references/python/tooling-config.md"
    "skills/coding-standards/references/java/checklist.md"
    "skills/coding-standards/references/java/examples.md"
    "skills/coding-standards/references/java/tooling-config.md"
    "skills/coding-standards/references/csharp/checklist.md"
    "skills/coding-standards/references/csharp/examples.md"
    "skills/coding-standards/references/csharp/tooling-config.md"
    # testing-conventions: universal + language packs
    "skills/testing-conventions/references/checklist.md"
    "skills/testing-conventions/references/python/checklist.md"
    "skills/testing-conventions/references/java/checklist.md"
    "skills/testing-conventions/references/csharp/checklist.md"
    # code-review: universal + language packs
    "skills/code-review/references/code-standards.md"
    "skills/code-review/references/python/code-standards.md"
    "skills/code-review/references/java/code-standards.md"
    "skills/code-review/references/csharp/code-standards.md"
    # security: universal + language packs
    "skills/security/references/checklist.md"
    "skills/security/references/python/checklist.md"
    "skills/security/references/python/examples.md"
    "skills/security/references/java/checklist.md"
    "skills/security/references/java/examples.md"
    "skills/security/references/csharp/checklist.md"
    "skills/security/references/csharp/examples.md"
)

for ref in "${EXPECTED_REFS[@]}"; do
    if [ -f "$PLUGIN_DIR/$ref" ]; then
        pass "$ref"
    else
        fail "$ref MISSING"
    fi
done

echo ""

# --- Contracts ---
echo "--- Contracts ---"

if [ -f "$PLUGIN_DIR/contracts/phase-output-schema.md" ]; then
    pass "contracts/phase-output-schema.md"
else
    fail "contracts/phase-output-schema.md MISSING"
fi

echo ""

# --- Examples ---
echo "--- Examples ---"

if [ -f "$PLUGIN_DIR/examples/reference-walkthrough.md" ]; then
    pass "examples/reference-walkthrough.md"
else
    fail "examples/reference-walkthrough.md MISSING"
fi

if [ -f "$PLUGIN_DIR/examples/sample-requirement.md" ]; then
    pass "examples/sample-requirement.md"
else
    fail "examples/sample-requirement.md MISSING"
fi

echo ""

# --- Summary ---
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ Plugin validation PASSED"
    exit 0
else
    echo "❌ Plugin validation FAILED ($FAIL issues)"
    exit 1
fi
