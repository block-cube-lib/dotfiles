# dotfiles

Personal configuration, mainly Neovim (dpp.vim) + WezTerm + zsh.

## Layout

This repository is cloned as `~/.config` itself
(`XDG_CONFIG_HOME=$HOME/.config`), so directories in the repo are
used in place — nothing is copied or symlinked:

- `nvim/` → `$XDG_CONFIG_HOME/nvim/`
- `wezterm/` → `$XDG_CONFIG_HOME/wezterm/`
- `starship.toml` → `$XDG_CONFIG_HOME/starship.toml`
- `git/` → `$XDG_CONFIG_HOME/git/` — git reads `git/config` as
  global config and `git/ignore` as the global excludes file,
  so no `~/.gitconfig` placement step is needed either.
  Machine-specific git settings go to `~/.gitconfig.local`
  (note: `git config --global` writes into `git/config` itself
  when no `~/.gitconfig` exists — use
  `git config --file ~/.gitconfig.local` for local edits).

zsh startup files (`~/.zshenv`, `~/.zshrc`) live in `$HOME`,
outside this repository, and are kept per machine.
The files under `zsh/` in this repo are the shared parts.
Other apps also write into `~/.config`; their directories are
listed in `.gitignore` so `git status` stays clean.

## Shared vs. machine-specific settings

Settings shared by every machine live in this repository.
Settings that differ per machine do NOT go into the shared files;
each shared entry point loads a local file that is kept only on
that machine (git-ignored):

- zsh: the startup files in `$HOME` are the per-machine layer
  (`.zshenv`: XDG variables, PATH, Homebrew, SDKs).
  `~/.zshrc` itself only loads the shared base:

      source "$HOME/.config/zsh/.zshrc"

  and the shared base in turn loads `~/.zshrc.local` at the end.
  Move the lines your current `~/.zshrc` has (Google Cloud SDK,
  Ruby, Unity CLI, ...) into `~/.zshrc.local`.
  Prompt is starship; the old
  hand-written vcs_info prompt was removed from the shared base.
- Neovim/dpp: plugins shared by every machine go into the toml
  files under `nvim/dpp/toml/`. Machine-only plugins can be kept
  in `nvim/dpp/toml/local.toml` (git-ignored).

Rule of thumb: if a line would break or be meaningless on another
machine, it goes into the local file, not the shared one.
