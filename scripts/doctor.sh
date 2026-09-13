#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
IFS= read -r nvim_version < "$repo_root/.nvim-version"
export NVIM_CONFIG_ROOT="$repo_root"
if [[ ! -x "$repo_root/.tools/neovim-$nvim_version/bin/nvim" ]]; then
  echo 'Managed Neovim missing. Run bash scripts/bootstrap.sh first.' >&2
  exit 1
fi
exec "$repo_root/.tools/neovim-$nvim_version/bin/nvim" --headless -u NONE -i NONE -l "$repo_root/scripts/doctor.lua"
