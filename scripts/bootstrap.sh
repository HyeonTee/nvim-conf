#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
IFS= read -r nvim_version < "$repo_root/.nvim-version"
for cmd in curl git tar make cc unzip node npm go rustup tree-sitter python3 rg; do
  command -v "$cmd" >/dev/null || { echo "Missing prerequisite: $cmd (see README.md)" >&2; exit 1; }
done
case "$(uname -s)" in Darwin) os=macos ;; Linux) os=linux ;; *) echo 'Only macOS/Linux supported' >&2; exit 1 ;; esac
case "$(uname -m)" in arm64|aarch64) arch=arm64 ;; x86_64) arch=x86_64 ;; *) echo 'Unsupported architecture' >&2; exit 1 ;; esac
managed="$repo_root/.tools/neovim-$nvim_version"
if [[ ! -x "$managed/bin/nvim" ]]; then
  mkdir -p "$repo_root/.tools"
  staging=$(mktemp -d "$repo_root/.tools/download.XXXXXX")
  archive="nvim-$os-$arch.tar.gz"
  base="https://github.com/neovim/neovim/releases/download/v$nvim_version"
  curl --fail --location --retry 3 "$base/$archive" -o "$staging/$archive"
  checksums="$repo_root/checksums/neovim-$nvim_version.sha256"
  (cd "$staging" && if command -v sha256sum >/dev/null; then sha256sum --check --ignore-missing "$checksums"; else shasum -a 256 --check --ignore-missing "$checksums"; fi)
  tar -xzf "$staging/$archive" -C "$staging"
  # 이미 존재하는 불완전 설치를 덮어쓰지 않는다.
  [[ ! -e "$managed" ]] || { echo "Incomplete install at $managed; inspect it before retrying" >&2; exit 1; }
  mv "$staging/nvim-$os-$arch" "$managed"
fi
export NVIM_CONFIG_ROOT="$repo_root"
rustup component add rust-src rust-analyzer rustfmt clippy
"$managed/bin/nvim" --headless -u NONE -i NONE -l "$repo_root/scripts/bootstrap.lua"
echo "Installed. Run bash scripts/doctor.sh and launch with bash scripts/nvim.sh"
