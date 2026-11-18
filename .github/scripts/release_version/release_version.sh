#!/usr/bin/env bash
# Computes the next Release Flow version (vX.Y.Z-rc.N).
#
# vX.Y.Z is bumped by git-cliff from the latest stable tag reachable from HEAD
# (the last version released to prd). N is the next free release candidate
# number for that version, so a candidate that failed in stg is retried as
# rc.N+1 of the same version unless the new commits raise the bump level.
#
# Usage: release-version.sh [override]
#   override  Optional explicit vX.Y.Z-rc.N version; it is validated and used as is.
#
# Environment:
#   GIT_CLIFF     git-cliff command (default: git-cliff).
#   CLIFF_CONFIG  git-cliff configuration (default: cliff.toml next to this script).
#
# Run it from the root of the repository being released. Stable tags must use
# the vX.Y.Z format.
#
# Scope: linear releases from a single branch. git-cliff bumps from the most
# recent stable tag in the history, so a maintenance tag of an older line merged
# after a newer release would yield a lower version; the script fails instead.
#   GITHUB_OUTPUT When set, the version is also written as the "version" output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly STABLE_VERSION_REGEX='^v[0-9]+\.[0-9]+\.[0-9]+$'
readonly RC_VERSION_REGEX='^v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$'

fail() {
	echo "release-version: $*" >&2
	exit 1
}

tag_exists() {
	git rev-parse -q --verify "refs/tags/$1" >/dev/null
}

emit() {
	echo "$1"
	if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
		echo "version=$1" >>"$GITHUB_OUTPUT"
	fi
}

latest_stable_tag() {
	git tag --merged HEAD --list 'v*' --sort=-v:refname | grep -E "$STABLE_VERSION_REGEX" | head -n 1 || true
}

# Succeeds when stable version $1 is greater than stable version $2.
version_gt() {
	local -a left right
	local i
	IFS=. read -r -a left <<<"${1#v}"
	IFS=. read -r -a right <<<"${2#v}"
	for i in 0 1 2; do
		if ((10#${left[i]} != 10#${right[i]})); then
			((10#${left[i]} > 10#${right[i]}))
			return
		fi
	done
	return 1
}

next_rc_number() {
	local base="$1" tag number next=0
	while IFS= read -r tag; do
		number="${tag##*-rc.}"
		if ((10#$number >= next)); then
			next=$((10#$number + 1))
		fi
	done < <(git tag --list "${base}-rc.*" | grep -E "^${base//./\\.}-rc\.[0-9]+$" || true)
	echo "$next"
}

main() {
	local override="${1:-}"

	if [[ -n "$override" ]]; then
		[[ "$override" =~ $RC_VERSION_REGEX ]] || fail "override '$override' must match vX.Y.Z-rc.N"
		if tag_exists "$override"; then
			fail "tag $override already exists"
		fi
		emit "$override"
		return
	fi

	local repo_root stable base
	repo_root="$(git rev-parse --show-toplevel)"
	stable="$(latest_stable_tag)"
	[[ -n "$stable" ]] || fail "no stable vX.Y.Z tag is reachable from HEAD"

	if [[ "$(git rev-list --count "${stable}..HEAD")" -eq 0 ]]; then
		fail "no commits since $stable; nothing to release"
	fi

	local -a git_cliff
	read -r -a git_cliff <<<"${GIT_CLIFF:-git-cliff}"
	base="$("${git_cliff[@]}" --repository "$repo_root" --config "${CLIFF_CONFIG:-$SCRIPT_DIR/cliff.toml}" --bumped-version)" ||
		fail "git-cliff failed to compute the bumped version"

	[[ "$base" =~ $STABLE_VERSION_REGEX ]] || fail "git-cliff returned an unexpected version '$base'"
	[[ "$base" != "$stable" ]] || fail "git-cliff did not bump $stable"
	version_gt "$base" "$stable" ||
		fail "git-cliff returned $base, which is not greater than the latest stable tag $stable; only linear releases are supported"
	if tag_exists "$base"; then
		fail "stable tag $base already exists but is not reachable from HEAD"
	fi

	emit "${base}-rc.$(next_rc_number "$base")"
}

main "$@"
