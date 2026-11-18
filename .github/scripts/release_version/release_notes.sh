#!/usr/bin/env bash
# Writes Markdown release notes for the commits in <base>..HEAD.
#
# Usage: release_notes.sh <base_ref> <output_file>
#   base_ref     Exclusive lower bound (usually the previous stable tag); empty
#                means the whole history.
#   output_file  Markdown file to write.
#
# Environment:
#   GIT_CLIFF         git-cliff command (default: git-cliff).
#   CLIFF_CONFIG      git-cliff configuration (default: cliff.toml next to this script).
#   LINEAR_WORKSPACE  Optional Linear workspace slug; links "[ABC-123]" to the issue.
#   REPOSITORY_URL    Optional repository URL; links "(#123)" to the pull request.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly EMPTY_NOTES="Sin cambios visibles para usuarios en esta versión."

fail() {
	echo "release-notes: $*" >&2
	exit 1
}

main() {
	[[ $# -eq 2 ]] || fail "usage: release_notes.sh <base_ref> <output_file>"
	local base="$1" output="$2"
	# Without a base git-cliff reads the whole history; it rejects a bare "HEAD" range.
	local -a range=()
	if [[ -n "$base" ]]; then
		git rev-parse -q --verify "${base}^{commit}" >/dev/null || fail "unknown base ref '$base'"
		range=("${base}..HEAD")
	fi

	local -a git_cliff
	read -r -a git_cliff <<<"${GIT_CLIFF:-git-cliff}"
	"${git_cliff[@]}" --config "${CLIFF_CONFIG:-$SCRIPT_DIR/cliff.toml}" --strip all ${range[@]+"${range[@]}"} >"$output" ||
		fail "git-cliff failed to generate the release notes"

	if ! grep -q '[^[:space:]]' "$output"; then
		echo "$EMPTY_NOTES" >"$output"
		return
	fi

	if [[ -n "${LINEAR_WORKSPACE:-}" ]]; then
		[[ "$LINEAR_WORKSPACE" =~ ^[a-z0-9-]+$ ]] || fail "invalid LINEAR_WORKSPACE '$LINEAR_WORKSPACE'"
		sed -E -i.bak "s|\\[([A-Z][A-Z0-9]*-[0-9]+)\\]|([\\1](https://linear.app/${LINEAR_WORKSPACE}/issue/\\1))|g" "$output"
	fi
	if [[ -n "${REPOSITORY_URL:-}" ]]; then
		[[ "$REPOSITORY_URL" =~ ^https://[A-Za-z0-9./_-]+$ ]] || fail "invalid REPOSITORY_URL '$REPOSITORY_URL'"
		sed -E -i.bak "s|\\(#([0-9]+)\\)|([#\\1](${REPOSITORY_URL}/pull/\\1))|g" "$output"
	fi
	rm -f "${output}.bak"
}

main "$@"
