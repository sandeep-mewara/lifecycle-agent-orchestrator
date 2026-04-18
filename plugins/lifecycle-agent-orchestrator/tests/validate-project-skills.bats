#!/usr/bin/env bats
# Tests for validate-project-skills.sh

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts"
SCRIPT="$SCRIPT_DIR/validate-project-skills.sh"
FIXTURES="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/fixtures"

@test "valid project passes with 0 failures" {
    run "$SCRIPT" "$FIXTURES/valid-project"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Validation PASSED"* ]]
    [[ "$output" != *"❌"* ]]
}

@test "misnamed overlay directory produces a warning" {
    run "$SCRIPT" "$FIXTURES/misnamed-overlay"
    [[ "$output" == *"does not match any base role"* ]]
    [[ "$output" == *"⚠️"* ]]
}

@test "missing frontmatter on domain file produces a warning" {
    run "$SCRIPT" "$FIXTURES/missing-frontmatter"
    [[ "$output" == *"MISSING frontmatter"* ]]
    [[ "$output" == *"⚠️"* ]]
}

@test "invalid applies_to value produces a failure" {
    run "$SCRIPT" "$FIXTURES/bad-applies-to"
    [ "$status" -eq 1 ]
    [[ "$output" == *"bogus-role"* ]]
    [[ "$output" == *"not a recognized role"* ]]
}

@test "extra role with applies_to passes validation" {
    run "$SCRIPT" "$FIXTURES/valid-project"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies_to value 'architecture' is valid"* ]]
    [[ "$output" == *"applies_to value 'code-review' is valid"* ]]
}

@test "extra role missing applies_to produces a warning" {
    run "$SCRIPT" "$FIXTURES/missing-applies-to-extra"
    [[ "$output" == *"MISSING applies_to"* ]]
    [[ "$output" == *"will NOT be loaded"* ]]
    [[ "$output" == *"⚠️"* ]]
}

@test "empty directory produces a warning" {
    run "$SCRIPT" "$FIXTURES/empty-dir"
    [[ "$output" == *"has neither PROJECT.md nor SKILL.md"* ]]
    [[ "$output" == *"⚠️"* ]]
}

@test "missing argument prints usage and exits 1" {
    run "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "nonexistent path exits with error" {
    run "$SCRIPT" "/nonexistent/path/that/does/not/exist"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}

# --- Config mode tests ---

@test "--config valid config passes with 0 failures" {
    run "$SCRIPT" --config "$FIXTURES/valid-config/lao.config.yaml"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Validation PASSED"* ]]
    [[ "$output" == *"project_name: test-app"* ]]
    [[ "$output" != *"❌"* ]]
}

@test "--config detects overlays and domain and extra roles" {
    run "$SCRIPT" --config "$FIXTURES/valid-config/lao.config.yaml"
    [ "$status" -eq 0 ]
    [[ "$output" == *"overlay key 'architecture' matches a base role"* ]]
    [[ "$output" == *"domain: docs/domain/auth.md"* ]]
    [[ "$output" == *"extra_role key 'compliance-review' is a valid custom role name"* ]]
    [[ "$output" == *"applies_to value 'architecture' is valid"* ]]
}

@test "--config bad config fails with missing paths and invalid roles" {
    run "$SCRIPT" --config "$FIXTURES/bad-config/lao.config.yaml"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does NOT match any base role"* ]]
    [[ "$output" == *"NOT found"* ]]
    [[ "$output" == *"matches a base role — use overlays section"* ]]
}

@test "--config missing file exits with error" {
    run "$SCRIPT" --config "/nonexistent/lao.config.yaml"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "--config without path exits with error" {
    run "$SCRIPT" --config
    [ "$status" -eq 1 ]
}

# --- Scan mode tests ---

@test "--scan finds potential skill files" {
    run "$SCRIPT" --scan "$FIXTURES/scan-project"
    [[ "$output" == *"coding-standards.md"* ]]
    [[ "$output" == *"architecture-decisions.md"* ]]
}

@test "--scan finds files with frontmatter" {
    run "$SCRIPT" --scan "$FIXTURES/scan-project"
    [[ "$output" == *"auth-patterns.md"* ]]
}

@test "--scan nonexistent path exits with error" {
    run "$SCRIPT" --scan "/nonexistent/project/root"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}
