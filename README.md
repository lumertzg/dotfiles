# Dotfiles

Personal Linux dotfiles managed with [chezmoi](https://www.chezmoi.io/).
The macOS settings are optional and are kept for reuse on another machine.

## Install

```sh
chezmoi init --apply <repository-url>
```

Review changes before later updates:

```sh
chezmoi diff
chezmoi apply
```

## Main dependencies

- Fish, Git, tmux, Neovim, mise, ripgrep, fzf, `sd`, `delta`, and Starship
- Kitty, Ghostty, Foot, or Herdr
- Berkeley Mono for the configured terminal font
- Optional commands used by bindings: Scout and Lazygit
- Language servers and compilers are installed separately through mise or system packages

Machine-specific Git identity and credentials belong in `~/.gitconfig.local`, which is included by the managed Git configuration.
