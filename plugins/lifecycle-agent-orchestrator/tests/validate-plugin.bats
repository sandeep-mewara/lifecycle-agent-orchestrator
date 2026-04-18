#!/usr/bin/env bats
# Tests for validate-plugin.sh

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts"
SCRIPT="$SCRIPT_DIR/validate-plugin.sh"

@test "plugin validation passes against actual plugin directory" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"validation PASSED"* ]]
}

@test "skill count output matches 13 expected" {
    run "$SCRIPT"
    [[ "$output" == *"Skills (13 expected)"* ]]
    [[ "$output" == *"Skills found: 13 / 13"* ]]
}

@test "Claude Code manifest is validated" {
    run "$SCRIPT"
    [[ "$output" == *".claude-plugin/plugin.json exists"* ]]
}

@test "Cursor manifest exists and is validated" {
    run "$SCRIPT"
    [[ "$output" == *".cursor-plugin/plugin.json exists"* ]]
    [[ "$output" == *"Cursor plugin.json has 'name' field"* ]]
    [[ "$output" == *"Cursor plugin.json has 'skills' field"* ]]
    [[ "$output" == *"Cursor skills path"* ]]
    [[ "$output" == *"matches Claude Code skills path"* ]]
}
