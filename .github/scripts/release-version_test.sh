#!/usr/bin/env bash
# Scenario tests for release-version.sh. Each case builds a throwaway git
# repository, so the tests never read or write the real repository tags.
#
# Environment:
#   GIT_CLIFF  git-cliff command passed to the script (default: git-cliff).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/release-version.sh"
CLIFF_CONFIG="$(cd "$SCRIPT_DIR/../.." && pwd)/cliff.toml"
readonly SCRIPT_DIR SCRIPT CLIFF_CONFIG

# Isolate the throwaway repositories from user and system git configuration.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export CLIFF_CONFIG

WORK_DIR="$(mktemp -d)"
readonly WORK_DIR
trap 'rm -rf "$WORK_DIR"' EXIT

failures=0
passes=0

new_repo() {
	local dir
	dir="$(mktemp -d "$WORK_DIR/repo.XXXXXX")"
	cd "$dir"
	git init -q
	commit "chore: initial commit"
}

commit() {
	git commit -q --allow-empty -m "$1"
}

# Tags are annotated like the ones created by the Release Flow.
tag() {
	git tag -a "$1" -m "$1"
}

run_script() {
	bash "$SCRIPT" "$@" 2>/dev/null
}

expect_version() {
	local name="$1" expected="$2" actual
	shift 2
	if actual="$(run_script "$@")" && [[ "$actual" == "$expected" ]]; then
		passes=$((passes + 1))
		echo "ok   - $name"
	else
		failures=$((failures + 1))
		echo "FAIL - $name: expected '$expected', got '${actual:-<error>}'"
	fi
}

expect_failure() {
	local name="$1" actual
	shift
	if actual="$(run_script "$@")"; then
		failures=$((failures + 1))
		echo "FAIL - $name: expected a failure, got '$actual'"
	else
		passes=$((passes + 1))
		echo "ok   - $name"
	fi
}

new_repo
tag v0.9.9
commit "fix(payment): first fix [DEMO-1]"
expect_version "fix since the stable tag bumps the patch" v0.9.10-rc.0

tag v0.9.10-rc.0
commit "fix(payment): fix found in stg [DEMO-2]"
expect_version "failed candidate is retried as the next rc of the same version" v0.9.10-rc.1

tag v0.9.10-rc.1
commit "feat(payment): new feature [DEMO-3]"
expect_version "feat after a failed candidate bumps the minor and restarts rc" v0.10.0-rc.0

new_repo
tag v0.9.9
commit "fix: shipped fix"
tag v0.9.10-rc.0
tag v0.9.10
commit "fix: next fix"
expect_version "released version becomes the next bump base" v0.9.11-rc.0

new_repo
tag v0.9.9
expect_failure "no commits since the stable tag fails"

new_repo
tag v0.9.9
commit "feat(api)!: remove legacy endpoint"
expect_version "breaking change bumps the minor while major is 0" v0.10.0-rc.0

new_repo
tag v0.9.9
commit "chore(deps): bump dependency"
commit "Unconventional commit message"
expect_version "non-feat and unconventional commits bump the patch" v0.9.10-rc.0

new_repo
tag v0.9.9
commit "fix: retried many times"
tag v0.9.10-rc.2
tag v0.9.10-rc.10
expect_version "rc numbers are compared numerically" v0.9.10-rc.11

new_repo
commit "fix: no release yet"
expect_failure "missing stable tag fails"

new_repo
tag v0.9.9
commit "fix: override"
expect_version "valid override is used as is" v1.0.0-rc.0 v1.0.0-rc.0
expect_failure "override without rc suffix fails" v1.0.0
tag v1.0.0-rc.0
expect_failure "override matching an existing tag fails" v1.0.0-rc.0

new_repo
tag v0.9.9
commit "fix: written to the GitHub output"
output_file="$WORK_DIR/github_output"
GITHUB_OUTPUT="$output_file" run_script >/dev/null
if [[ "$(cat "$output_file")" == "version=v0.9.10-rc.0" ]]; then
	passes=$((passes + 1))
	echo "ok   - version is written to GITHUB_OUTPUT"
else
	failures=$((failures + 1))
	echo "FAIL - version is written to GITHUB_OUTPUT: got '$(cat "$output_file")'"
fi

echo "passed: $passes, failed: $failures"
((failures == 0))
