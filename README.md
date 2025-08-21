# DOTFILES

This repository is based on nix tooling to describe and manage my development setup and tools.

## How to install
### macOS
1. Install Nix with flakes support. Determinate-Nix installer is recommended

2. Install Homebrew

3. Inside the repo, run `sudo nix run nix-darwin --switch --flake .`. This should handle all the setup by itself.

4. In order to use the correct login shell binary:
4.1 Run `which zsh` to determine the correct path of the nix-managed zsh binary
4.2 Edit `/etc/shells` and append the output from the last command to the end of file.

## Aditional information and software
- Recommended terminal emulator: ghostty
- Shell: zsh
- Prefered color scheme: gruvbox material

