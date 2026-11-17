#!/usr/bin/env bash
# Tests for check_pr_title.sh.
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check_pr_title.sh"
readonly SCRIPT
failures=0
passes=0

expect() {
	local want="$1"; shift
	local got=pass
	bash "$SCRIPT" "$@" >/dev/null 2>&1 || got=fail
	if [[ "$got" == "$want" ]]; then
		passes=$((passes + 1)); echo "ok   - $want: $*"
	else
		failures=$((failures + 1)); echo "FAIL - expected $want: $*"
	fi
}

expect pass "fix(payment): round amounts [AIP-123]"
expect pass "feat: add export [AIP-1]"
expect pass "feat(api)!: drop legacy endpoint [AIP-9]"
expect pass "chore(deps): bump lib [NO-TICKET]"
expect pass "fix(bill-payment): handle retries [AIP-419]"
expect pass 'Revert "fix(payment): round amounts [AIP-123]"'
expect fail "Fix(payment): round amounts [AIP-123]"
expect fail "AIP-664 feat(usagebudget): include WebSearch"
expect fail "[5/5] feat(evals): expose inventory"
expect fail "feat(evals): select cases [AIP-597/598]"
expect fail "fix(payment): round amounts"
expect fail "fix(payment): round amounts AIP-123"
expect fail "mergeando a main"
expect fail "fix:missing space [AIP-1]"
expect fail "fix(Payment): uppercase scope [AIP-1]"
expect pass "fix(payment): round amounts [AIP-123]" "fix(payment): round amounts [AIP-123]"
expect fail "fix(payment): round amounts [AIP-123]" "wip"
# The literal command substitution must reach the script unexpanded.
# shellcheck disable=SC2016
expect fail 'feat: x [AIP-1]$(touch /tmp/pwned)'
if [[ -e /tmp/pwned ]]; then
	failures=$((failures + 1)); echo "FAIL - title was executed"
else
	passes=$((passes + 1)); echo "ok   - title is never executed"
fi

echo "passed: $passes, failed: $failures"
((failures == 0))
