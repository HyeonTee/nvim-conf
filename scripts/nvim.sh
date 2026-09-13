#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
IFS= read -r nvim_version < "$repo_root/.nvim-version"
managed="$repo_root/.tools/neovim-$nvim_version/bin/nvim"
if [[ ! -x "$managed" ]]; then
  echo "Managed Neovim missing. Run: bash $repo_root/scripts/bootstrap.sh" >&2
  exit 1
fi
export NVIM_CONFIG_ROOT="$repo_root"
exec "$managed" --cmd 'lua vim.opt.rtp:prepend(vim.env.NVIM_CONFIG_ROOT)' -u "$repo_root/init.lua" "$@"
