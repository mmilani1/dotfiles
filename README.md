# DOTFILES
## How to install
This repository includes files managed by [chezmoi](https://github.com/twpayne/chezmoi). This tool will automatically
clone this repository, render and replace the managed files automatically.

* External liberaies and executables managed by chezmoi will be installed at ``$HOME/.local/bin`, so make sure this
 path is included in $PATH*

Referer to chezmoi documentation on how to get it running on your machine and run its `init` or run the command below to
install it on `$HOME/.local/bin` and start the setup:

```sh
sh -c "$(curl -fsLS get.chezmoi.ioi/lb)" -- init --apply git@github.com:mmilani1/dotfiles.git
```

## Aditional information and software
- Recommended terminal emulator: wezterm
- Shell compatibility: fish
- Color scheme: gruvbox material

