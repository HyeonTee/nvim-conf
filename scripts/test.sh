#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
IFS= read -r nvim_version < "$repo_root/.nvim-version"
export NVIM_CONFIG_ROOT="$repo_root"
"$repo_root/.tools/neovim-$nvim_version/bin/nvim" --headless -u NONE -i NONE -l "$repo_root/tests/regression.lua"
if [[ "${1:-}" == "--smoke" ]]; then
  bash "$repo_root/scripts/nvim.sh" --headless -i NONE --cmd 'lua vim.g.ide_test = true' \
    -c 'lua dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/smoke.lua")'
fi
