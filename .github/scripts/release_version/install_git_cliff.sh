#!/usr/bin/env bash
# Installs a pinned git-cliff release on Linux x86_64 runners after verifying
# its SHA-512 checksum, and adds it to GITHUB_PATH.
set -euo pipefail

readonly VERSION="2.14.2"
readonly SHA512="26d1f7c8ea2400f2ccb0b2e7f321635f600b583bf4cd1f7afaa5e8c24068ad1088a2504e0a4d9f4333d4bb20a80329327d9462634343ee3af91e1a7fbdc6f18a"
readonly ARCHIVE="git-cliff-${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
readonly URL="https://github.com/orhun/git-cliff/releases/download/v${VERSION}/${ARCHIVE}"

if [[ "$(uname -s)-$(uname -m)" != "Linux-x86_64" ]]; then
	echo "install-git-cliff: only Linux x86_64 runners are supported" >&2
	exit 1
fi

install_dir="${RUNNER_TEMP:-/tmp}/git-cliff-${VERSION}"
mkdir -p "$install_dir"
curl -fsSL --retry 3 -o "${install_dir}/${ARCHIVE}" "$URL"
echo "${SHA512}  ${install_dir}/${ARCHIVE}" | sha512sum --check --quiet -
tar -xzf "${install_dir}/${ARCHIVE}" -C "$install_dir" --strip-components=1 "git-cliff-${VERSION}/git-cliff"
"${install_dir}/git-cliff" --version
echo "$install_dir" >>"${GITHUB_PATH:-/dev/null}"
