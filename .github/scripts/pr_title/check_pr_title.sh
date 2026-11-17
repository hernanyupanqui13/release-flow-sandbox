#!/usr/bin/env bash
# Validates that a pull request title, and the commit subject when the pull
# request has a single commit, follow:
#   type(scope)!: description [ABC-123]
# With the COMMIT_OR_PR_TITLE squash setting, a single-commit pull request is
# merged with the commit subject instead of the pull request title, so both
# must comply.
#
# Usage: check_pr_title.sh <title> [<single commit subject>]
#
# Environment:
#   PR_TITLE_TYPES    Allowed types separated by "|" (default: conventional types).
#   PR_TITLE_TICKET   Ticket regex inside the brackets (default: [A-Z]+-[0-9]+|NO-TICKET).
set -euo pipefail

readonly TYPES="${PR_TITLE_TYPES:-feat|fix|perf|refactor|test|docs|build|ci|chore|revert}"
readonly TICKET="${PR_TITLE_TICKET:-[A-Z][A-Z0-9]*-[0-9]+|NO-TICKET}"
readonly PATTERN="^(${TYPES})(\([a-z0-9._/-]+\))?!?: [^ ].* \[(${TICKET})\]$"
# Reverts created by the GitHub "Revert" button keep the original title.
readonly REVERT_PATTERN='^Revert ".+"$'

errors=0

check() {
	local label="$1" value="$2"
	if [[ "$value" =~ $PATTERN || "$value" =~ $REVERT_PATTERN ]]; then
		echo "ok: ${label}: ${value}"
		return
	fi
	errors=$((errors + 1))
	echo "::error title=Invalid ${label}::'${value}' must match 'type(scope): description [ABC-123]' (scope and ! are optional; use [NO-TICKET] when there is no Linear issue)."
}

main() {
	[[ $# -ge 1 && $# -le 2 ]] || { echo "usage: check_pr_title.sh <title> [<single commit subject>]" >&2; exit 2; }
	check "pull request title" "$1"
	if [[ $# -eq 2 ]]; then
		check "commit subject (single-commit pull requests are squashed with the commit subject)" "$2"
	fi
	((errors == 0))
}

main "$@"
