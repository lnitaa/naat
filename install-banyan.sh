#!/usr/bin/env bash
# =============================================================================
# install-banyan.sh - installs the `naat` CLI (toolbox for the banyan tools)
#
#   curl -fsSL https://raw.githubusercontent.com/lnitaa/naat/main/install-banyan.sh | sudo bash
#
# or download first, then install:
#   curl -fsSL https://raw.githubusercontent.com/lnitaa/naat/main/install-banyan.sh -O
#   sudo bash install-banyan.sh
#
# Installs:
#   /usr/local/bin/naat                       the CLI
#   /usr/local/lib/naat/age                   bundled encryption tool
#   /usr/local/lib/naat/age-plugin-batchpass  (non-interactive passphrase mode)
#
# Options:      --uninstall     remove naat (user configuration in ~/.naat is kept)
# Environment:  NAAT_OWNER, NAAT_REPO, NAAT_BRANCH   where to download from
#               NAAT_PREFIX                           install prefix (/usr/local)
#               NAAT_SOURCE_DIR                       install from a local clone
#                                                     of the naat repo (offline)
# =============================================================================
set -euo pipefail

main() {
    local owner="${NAAT_OWNER:-lnitaa}"
    local repo="${NAAT_REPO:-naat}"
    local branch="${NAAT_BRANCH:-main}"
    local prefix="${NAAT_PREFIX:-/usr/local}"
    local base_url="${NAAT_RAW_URL:-https://raw.githubusercontent.com}/$owner/$repo/$branch"
    local bin_dir="$prefix/bin" lib_dir="$prefix/lib/naat"
    local source_dir="${NAAT_SOURCE_DIR:-}"

    say()  { printf '%s\n' "$*"; }
    fail() { printf 'install-banyan: error: %s\n' "$*" >&2; exit 1; }

    if [[ "${1:-}" == "--uninstall" ]]; then
        [[ -w "$prefix" || "$(id -u)" == "0" ]] || fail "run with sudo."
        rm -f "$bin_dir/naat" "$lib_dir/age" "$lib_dir/age-plugin-batchpass" "$lib_dir/LICENSE.age" "$lib_dir/VERSION.age"
        rmdir "$lib_dir" 2>/dev/null || true
        say "naat removed. Per-user configuration (~/.naat) was left untouched."
        exit 0
    fi

    [[ "$(uname -s)" == "Linux" ]] || fail "only Linux is supported."
    local arch
    case "$(uname -m)" in
        x86_64|amd64)  arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) fail "unsupported CPU architecture: $(uname -m) (amd64 and arm64 are bundled)." ;;
    esac
    if [[ "$(id -u)" != "0" && ! -w "$prefix" ]]; then
        fail "root is required to write in $prefix. Use: sudo bash install-banyan.sh"
    fi

    # When run from inside a clone of the repo, install from it (no network).
    if [[ -z "$source_dir" && -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
        local here
        here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -f "$here/bin/naat" && -d "$here/vendor/age" ]]; then source_dir="$here"; fi
    fi

    local tmp
    tmp="$(mktemp -d)"
    # shellcheck disable=SC2064  # expand $tmp now on purpose
    trap "rm -rf '$tmp'" EXIT

    fetch() {   # fetch REPO_PATH DEST
        if [[ -n "$source_dir" ]]; then
            cp "$source_dir/$1" "$2" || fail "missing $1 in $source_dir"
        else
            curl -fsSL --retry 3 -o "$2" "$base_url/$1" || fail "could not download $base_url/$1"
        fi
    }

    if [[ -n "$source_dir" ]]; then
        say "Installing naat from $source_dir ..."
    else
        command -v curl >/dev/null 2>&1 || fail "curl is required."
        say "Installing naat from github.com/$owner/$repo ($branch) ..."
    fi

    fetch "bin/naat"                                  "$tmp/naat"
    fetch "vendor/age/linux-$arch/age"                  "$tmp/age"
    fetch "vendor/age/linux-$arch/age-plugin-batchpass" "$tmp/age-plugin-batchpass"
    fetch "vendor/age/SHA256SUMS"                       "$tmp/SHA256SUMS"
    fetch "vendor/age/LICENSE"                          "$tmp/LICENSE.age"
    fetch "vendor/age/VERSION"                          "$tmp/VERSION.age"

    # Integrity check of the bundled binaries.
    local f want got
    for f in age age-plugin-batchpass; do
        want="$(awk -v p="linux-$arch/$f" '$2 == p { print $1 }' "$tmp/SHA256SUMS")"
        got="$(sha256sum "$tmp/$f" | awk '{ print $1 }')"
        [[ -n "$want" && "$want" == "$got" ]] || fail "checksum mismatch for $f (download corrupted?)."
    done
    head -n 1 "$tmp/naat" | grep -q '^#!' || fail "the downloaded naat script looks wrong."
    sed -i 's/\r$//' "$tmp/naat"

    install -d -m 755 "$bin_dir" "$lib_dir"
    install -m 755 "$tmp/age" "$tmp/age-plugin-batchpass" "$lib_dir/"
    install -m 644 "$tmp/LICENSE.age" "$tmp/VERSION.age" "$lib_dir/"
    install -m 755 "$tmp/naat" "$bin_dir/naat"

    "$lib_dir/age" --version >/dev/null 2>&1 || fail "the bundled age binary does not run on this system."

    say ""
    say "Installed: $("$bin_dir/naat" version) (age $(cat "$lib_dir/VERSION.age"), linux-$arch)"
    case ":$PATH:" in
        *":$bin_dir:"*) ;;
        *) say "Note: $bin_dir is not in your PATH." ;;
    esac
    say ""
    say "Next steps:"
    say "  naat configure          # enter the secret phrase"
    say "  naat list               # tools available in banyan"
    say "  naat download <tool>    # or: naat execute <tool>"
}

# The whole script is wrapped in main() so that a truncated `curl | bash`
# download can never run half an installation.
main "$@"
