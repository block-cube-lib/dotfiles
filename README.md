# dotfiles

Personal configuration, mainly Neovim (dpp.vim) + WezTerm + zsh.

## Layout

| In this repo | Placed at |
|---|---|
| `nvim/` | `~/.config/nvim/` |
| `wezterm/` | `~/.config/wezterm/` |
| `zsh/.zshrc`, `zsh/.zshenv` | `~/` |
| `starship.toml` | `~/.config/starship.toml` |
| `.editorconfig` | `~/` |
| `cpp/.clang-format` | as needed per project |

## Shared vs. machine-specific settings

Settings shared by every machine live in this repository.
Settings that differ per machine do NOT go into the shared files;
each shared entry point loads a local file that is kept only on
that machine (git-ignored):

- zsh: `~/.zshrc` loads `~/.zshrc.local` at the end.
  Per-machine lines such as `eval "$(starship init zsh)"`,
  the Homebrew prefix or work-only tools belong there.
- Neovim/dpp: plugins shared by every machine go into the toml
  files under `nvim/dpp/toml/`. Machine-only plugins can be kept
  in `nvim/dpp/toml/local.toml` (git-ignored).

Rule of thumb: if a line would break or be meaningless on another
machine, it goes into the local file, not the shared one.
