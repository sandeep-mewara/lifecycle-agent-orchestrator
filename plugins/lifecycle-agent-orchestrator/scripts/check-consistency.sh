#!/bin/bash
# Lifecycle Agent Orchestrator — Cross-Reference Consistency Checker
# Verifies that documentation and code stay in sync.
# Run from anywhere: ./plugins/lifecycle-agent-orchestrator/scripts/check-consistency.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$PLUGIN_DIR/../.." && pwd)"
README="$REPO_DIR/README.md"
VALIDATE_PLUGIN="$SCRIPT_DIR/validate-plugin.sh"
VALIDATE_PROJECT="$SCRIPT_DIR/validate-project-skills.sh"
ORCHESTRATOR_SKILL="$PLUGIN_DIR/skills/lao/SKILL.md"
MARKETPLACE_JSON="$REPO_DIR/.claude-plugin/marketplace.json"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "=== Cross-Reference Consistency Check ==="
echo ""

# --- Skill count in README vs actual ---
echo "--- Skill Count ---"

ACTUAL_COUNT=$(find "$PLUGIN_DIR/skills" -maxdepth 2 -name "SKILL.md" | wc -l | tr -d ' ')

README_COUNT=$(grep -oE '[0-9]+ skills are available' "$README" | grep -oE '[0-9]+' | head -1)

if [ -z "$README_COUNT" ]; then
    fail "Could not find 'N skills are available' in README"
elif [ "$README_COUNT" -eq "$ACTUAL_COUNT" ]; then
    pass "README skill count ($README_COUNT) matches actual ($ACTUAL_COUNT)"
else
    fail "README says '$README_COUNT skills' but found $ACTUAL_COUNT skill directories"
fi

echo ""

# --- Skill names: actual dirs vs README table ---
echo "--- Skill Names in README ---"

ACTUAL_SKILLS=$(find "$PLUGIN_DIR/skills" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort)

for skill in $ACTUAL_SKILLS; do
    if grep -q "\`$skill\`\|/$skill\`" "$README"; then
        pass "skill '$skill' found in README"
    else
        fail "skill '$skill' exists on disk but NOT in README"
    fi
done

README_SKILL_NAMES=$(grep '^| `[a-z]' "$README" | sed 's/.*`\([a-z][a-z0-9-]*\)`.*/\1/' | sort -u)
for skill in $README_SKILL_NAMES; do
    if echo "$ACTUAL_SKILLS" | grep -q "^${skill}$"; then
        : # already checked above
    else
        fail "skill '$skill' listed in README table but NOT found on disk"
    fi
done

echo ""

# --- EXPECTED_SKILLS in validate-plugin.sh vs actual ---
echo "--- validate-plugin.sh EXPECTED_SKILLS ---"

SCRIPT_SKILLS=$(awk '/^EXPECTED_SKILLS=\(/,/\)/' "$VALIDATE_PLUGIN" | \
    grep '^ *"' | sed 's/.*"\([^"]*\)".*/\1/' | sort)

for skill in $ACTUAL_SKILLS; do
    if echo "$SCRIPT_SKILLS" | grep -q "^${skill}$"; then
        pass "'$skill' in validate-plugin.sh"
    else
        fail "'$skill' exists on disk but MISSING from validate-plugin.sh EXPECTED_SKILLS"
    fi
done

for skill in $SCRIPT_SKILLS; do
    if echo "$ACTUAL_SKILLS" | grep -q "^${skill}$"; then
        : # already checked
    else
        fail "'$skill' in validate-plugin.sh EXPECTED_SKILLS but NOT on disk"
    fi
done

echo ""

# --- BASE_ROLES in validate-project-skills.sh vs actual ---
echo "--- validate-project-skills.sh BASE_ROLES ---"

PROJECT_ROLES=$(awk '/^BASE_ROLES=\(/,/\)/' "$VALIDATE_PROJECT" | \
    grep '^ *"' | sed 's/.*"\([^"]*\)".*/\1/' | sort)

for skill in $ACTUAL_SKILLS; do
    if echo "$PROJECT_ROLES" | grep -q "^${skill}$"; then
        pass "'$skill' in validate-project-skills.sh BASE_ROLES"
    else
        fail "'$skill' exists on disk but MISSING from validate-project-skills.sh BASE_ROLES"
    fi
done

for role in $PROJECT_ROLES; do
    if echo "$ACTUAL_SKILLS" | grep -q "^${role}$"; then
        : # already checked
    else
        fail "'$role' in validate-project-skills.sh BASE_ROLES but NOT on disk"
    fi
done

echo ""

# --- Overlay-eligible roles in README vs actual skill directories ---
echo "--- Overlay-Eligible Roles ---"

README_ROLES=$(awk '/Where `<role>` matches/,/^$/' "$README" | \
    grep '^- `' | sed 's/.*`\(.*\)`.*/\1/' | sort)

OVERLAY_ELIGIBLE_SKILLS=$(find "$PLUGIN_DIR/skills" -maxdepth 1 -mindepth 1 -type d \
    ! -name "lao" ! -name "lao-dry-run" ! -name "lao-setup" \
    -exec basename {} \; | sort)

for role in $README_ROLES; do
    if echo "$OVERLAY_ELIGIBLE_SKILLS" | grep -q "^${role}$"; then
        pass "README overlay role '$role' has a matching skill directory"
    else
        fail "README lists '$role' as overlay-eligible but no skill directory exists"
    fi
done

for skill in $OVERLAY_ELIGIBLE_SKILLS; do
    if echo "$README_ROLES" | grep -q "^${skill}$"; then
        : # already checked
    else
        warn "skill '$skill' exists on disk but NOT listed as overlay-eligible in README"
    fi
done

echo ""

# --- Manifest names ---
echo "--- Manifest Consistency ---"

if [ -f "$MARKETPLACE_JSON" ] && [ -f "$PLUGIN_JSON" ]; then
    MKT_NAME=$(grep '"name"' "$MARKETPLACE_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    PLG_NAME=$(grep '"name"' "$PLUGIN_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')

    if [ "$MKT_NAME" = "$PLG_NAME" ]; then
        pass "marketplace.json name ('$MKT_NAME') matches plugin.json name ('$PLG_NAME')"
    else
        fail "marketplace.json name ('$MKT_NAME') does NOT match plugin.json name ('$PLG_NAME')"
    fi

    MKT_PLUGIN_REF=$(awk '/"plugins":/,/\]/' "$MARKETPLACE_JSON" | \
        grep '"name"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    if [ "$MKT_PLUGIN_REF" = "$PLG_NAME" ]; then
        pass "marketplace.json plugin reference ('$MKT_PLUGIN_REF') matches plugin.json name"
    else
        fail "marketplace.json plugin reference ('$MKT_PLUGIN_REF') does NOT match plugin.json name ('$PLG_NAME')"
    fi
else
    fail "Manifest files missing — marketplace.json or plugin.json not found"
fi

# --- Cursor Manifest Consistency ---
echo "--- Cursor Manifest Consistency ---"

CURSOR_MKT_JSON="$REPO_DIR/.cursor-plugin/marketplace.json"
CURSOR_PLG_JSON="$PLUGIN_DIR/.cursor-plugin/plugin.json"

if [ -f "$CURSOR_MKT_JSON" ] && [ -f "$CURSOR_PLG_JSON" ]; then
    CURSOR_MKT_NAME=$(grep '"name"' "$CURSOR_MKT_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    CURSOR_PLG_NAME=$(grep '"name"' "$CURSOR_PLG_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')

    if [ "$CURSOR_MKT_NAME" = "$CURSOR_PLG_NAME" ]; then
        pass "Cursor marketplace.json name ('$CURSOR_MKT_NAME') matches Cursor plugin.json name ('$CURSOR_PLG_NAME')"
    else
        fail "Cursor marketplace.json name ('$CURSOR_MKT_NAME') does NOT match Cursor plugin.json name ('$CURSOR_PLG_NAME')"
    fi

    CURSOR_MKT_PLUGIN_REF=$(awk '/"plugins":/,/\]/' "$CURSOR_MKT_JSON" | \
        grep '"name"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    if [ "$CURSOR_MKT_PLUGIN_REF" = "$CURSOR_PLG_NAME" ]; then
        pass "Cursor marketplace.json plugin reference ('$CURSOR_MKT_PLUGIN_REF') matches Cursor plugin.json name"
    else
        fail "Cursor marketplace.json plugin reference ('$CURSOR_MKT_PLUGIN_REF') does NOT match Cursor plugin.json name ('$CURSOR_PLG_NAME')"
    fi

    CLAUDE_VERSION=$(grep '"version"' "$PLUGIN_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/')
    CURSOR_VERSION=$(grep '"version"' "$CURSOR_PLG_JSON" | sed 's/.*: *"\([^"]*\)".*/\1/')
    if [ "$CLAUDE_VERSION" = "$CURSOR_VERSION" ]; then
        pass "Cursor plugin.json version ('$CURSOR_VERSION') matches Claude Code version ('$CLAUDE_VERSION')"
    else
        fail "Cursor plugin.json version ('$CURSOR_VERSION') does NOT match Claude Code version ('$CLAUDE_VERSION')"
    fi
else
    fail "Cursor manifest files missing — .cursor-plugin/marketplace.json or .cursor-plugin/plugin.json not found"
fi

echo ""

# --- Summary ---
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ Consistency check PASSED"
    exit 0
else
    echo "❌ Consistency check FAILED ($FAIL issues)"
    exit 1
fi
