#!/usr/bin/env bash
# Scenario tests for release_notes.sh in throwaway git repositories.
#
# Environment:
#   GIT_CLIFF  git-cliff command passed to the script (default: git-cliff).
# Conditions are single-quoted on purpose: check() evaluates them lazily.
# shellcheck disable=SC2016
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/release_notes.sh"
readonly SCRIPT_DIR SCRIPT

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

WORK_DIR="$(mktemp -d)"
readonly WORK_DIR
trap 'rm -rf "$WORK_DIR"' EXIT

failures=0
passes=0

check() {
	local name="$1" condition="$2"
	if eval "$condition"; then
		passes=$((passes + 1))
		echo "ok   - $name"
	else
		failures=$((failures + 1))
		echo "FAIL - $name"
		sed 's/^/       /' "$NOTES"
	fi
}

cd "$WORK_DIR"
git init -q
git commit -q --allow-empty -m "chore: initial commit"
git tag -a v1.0.0 -m v1.0.0
git commit -q --allow-empty -m "feat(history): export the history to CSV [DEMO-12] (#8)"
git commit -q --allow-empty -m "fix(summary): round amounts to two decimals [DEMO-13] (#9)"
git commit -q --allow-empty -m "perf(requests): cache the pending list [DEMO-14] (#10)"
git commit -q --allow-empty -m "feat(api)!: drop the legacy endpoint [DEMO-15] (#11)"
git commit -q --allow-empty -m "ci: tweak the pipeline (#12)"

NOTES="$WORK_DIR/notes.md"
LINEAR_WORKSPACE=demo REPOSITORY_URL=https://github.com/acme/app bash "$SCRIPT" v1.0.0 "$NOTES" 2>/dev/null

check "groups appear in order" '[[ "$(grep "^### " "$NOTES" | tr "\n" "|")" == "### Cambios importantes|### Nuevas funcionalidades|### Mejoras|### Correcciones|" ]]'
check "internal commits are hidden" '! grep -q "tweak the pipeline" "$NOTES"'
check "commit subjects lose the type prefix" 'grep -q "^- Export the history to CSV" "$NOTES"'
check "issue identifiers link to Linear" 'grep -qF "([DEMO-12](https://linear.app/demo/issue/DEMO-12))" "$NOTES"'
check "pull request numbers link to GitHub" 'grep -qF "([#9](https://github.com/acme/app/pull/9))" "$NOTES"'

bash "$SCRIPT" v1.0.0 "$NOTES" 2>/dev/null
check "links are optional" 'grep -qF "[DEMO-13] (#9)" "$NOTES"'

git tag -a v1.1.0 -m v1.1.0
git commit -q --allow-empty -m "chore(deps): bump a dependency"
bash "$SCRIPT" v1.1.0 "$NOTES" 2>/dev/null
check "only internal changes produce a fixed message" 'grep -qx "Sin cambios visibles para usuarios en esta versión." "$NOTES"'

if LINEAR_WORKSPACE='bad/ws' bash "$SCRIPT" v1.0.0 "$NOTES" 2>/dev/null; then
	failures=$((failures + 1)); echo "FAIL - invalid workspace is rejected"
else
	passes=$((passes + 1)); echo "ok   - invalid workspace is rejected"
fi
if bash "$SCRIPT" v9.9.9 "$NOTES" 2>/dev/null; then
	failures=$((failures + 1)); echo "FAIL - unknown base ref is rejected"
else
	passes=$((passes + 1)); echo "ok   - unknown base ref is rejected"
fi

FIRST_REPO="$WORK_DIR/first-release"
git init -q "$FIRST_REPO"
cd "$FIRST_REPO"
git commit -q --allow-empty -m "chore: initial commit"
git commit -q --allow-empty -m "feat(history): export the history to CSV [DEMO-12] (#8)"
if bash "$SCRIPT" "" "$NOTES" 2>/dev/null; then
	check "empty base covers the whole history" 'grep -q "^- Export the history to CSV" "$NOTES"'
else
	failures=$((failures + 1)); echo "FAIL - empty base covers the whole history"
fi

echo "passed: $passes, failed: $failures"
((failures == 0))
