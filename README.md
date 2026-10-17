# Dotfiles Monorepo (`Homebrew` + `GNU Stow` + `mise` + `NixOS`)

Unified multi-host configuration repository serving three machines without duplication:

| Host | OS / Architecture | Package & System Layer | Dotfiles / Home Layer | Window Manager / Services |
| :--- | :--- | :--- | :--- | :--- |
| **MacBook** | `aarch64-darwin` (macOS) | Homebrew (`Brewfile`) + `macos_defaults.sh` | GNU Stow + `mise` | AeroSpace (`aerospace`) |
| **Gaming / AI PC** | `x86_64-linux` (CachyOS) | Linuxbrew + Flatpaks (`Brewfile`) + `pacman` (`tailscale`) | GNU Stow + `mise` | Niri (`niri`) |
| **Mini PC Server** (`homelab`) | `x86_64-linux` (NixOS) | NixOS Flake (`nixos/flake.nix`, `nixos/configuration.nix`) + `sops-nix` | Home Manager (`nixos/home.nix`) sourcing shared Stow files | AdGuard Home, Caddy, Homepage, Vaultwarden, Syncthing, Uptime Kuma, Glances, PairDrop, Restic |

---

## Repository Layout

- `Brewfile` — Cross-platform Homebrew bundle (`OS.mac?` Casks & `pinentry-mac`; `OS.linux?` Flatpaks & `pinentry`).
- `install.sh` — Modular bootstrap script (`--all`, `--brew`, `--stow`, `--shell`, `--gpg`, `--mise`, `--macos`, `--help`).
- `macos_defaults.sh` — macOS system preferences, Dock layout, Caps Lock → Escape (`hidutil` + LaunchAgent), and Touch ID for `sudo`.
- `.sops.yaml` — SOPS encryption rules for `nixos/secrets.yaml`.
- **GNU Stow Packages**:
  - `git/` — XDG Git configuration (`~/.config/git/config`, `~/.config/git/ignore`) with `delta`, GPG signing, and `gh` credential helper.
  - `zsh/` — Zsh configuration (`~/.zshrc`, `~/.zprofile`, `~/.zsh_plugins.txt`, `~/.config/zsh-abbr/user-abbreviations`) powered by Antidote.
  - `ghostty/` — Ghostty terminal configuration (`~/.config/ghostty/config`) with Gruvbox Dark theme.
  - `starship/` — Starship prompt (`~/.config/starship.toml`).
  - `nvim/` — Self-bootstrapping `lazy.nvim` configuration (`~/.config/nvim/init.lua`) with Gruvbox Dark, `fzf-lua`, and `nvim-treesitter`.
  - `mise/` — Global runtime declarations (`~/.config/mise/config.toml`: Node LTS, Python, `uv`, Go, Rust, Bun, Deno).
  - `gh/` — GitHub CLI & `gh-dash` configs (`~/.config/gh/config.yml`, `~/.config/gh-dash/config.yml`).
  - `gnupg/` — Hardened GnuPG settings (`~/.gnupg/gpg.conf`, `~/.gnupg/common.conf`).
  - `aerospace/` — macOS tiling window manager config (`~/.config/aerospace/aerospace.toml`).
  - `niri/` — CachyOS scrollable-tiling Wayland compositor config (`~/.config/niri/config.kdl`) with AeroSpace keybinding parity.
- **NixOS Homelab (`nixos/`)**:
  - `nixos/flake.nix` — NixOS unstable + Home Manager + `sops-nix` flake for `homelab`.
  - `nixos/configuration.nix` — Hardened SSH, Tailscale, AdGuard Home (`:53`/`:3000`), Caddy reverse proxy (`*.homelab.internal`), Homepage (`:8082`), Vaultwarden (`:8222`), Syncthing (`:8384`), Uptime Kuma (`:3001`), Glances (`:61208`), Docker + PairDrop (`:3002`), and Restic encrypted backups.
  - `nixos/home.nix` — Headless user environment directly linking `../git`, `../nvim`, `../starship`, `../gh`, and `../zsh`.

---

## Quick Start

### 1. macOS (MacBook) & CachyOS Linux (Gaming / AI PC)

Run the full bootstrap:

```bash
git clone https://github.com/mmilani1/dotfiles.git ~/.dev/dotfiles
cd ~/.dev/dotfiles
./install.sh
```

Or run individual stages with flags:

```bash
./install.sh --brew    # Sync Homebrew/Flatpaks from Brewfile (installs new, uninstalls removed)
./install.sh --stow    # Conflict-safe GNU Stow symlink deployment into $HOME
./install.sh --shell   # Configure default login shell to Zsh
./install.sh --gpg     # Generate OS-specific gpg-agent.conf, mask distro GnuPG systemd user units (Linux), and import GitHub GPG key
./install.sh --mise    # Install global language runtimes declared in mise/config.toml
./install.sh --macos   # Apply macOS defaults, Dock layout, CapsLock->Escape, and Touch ID sudo
```

### 2. NixOS Mini PC Home Server (`homelab`)

Apply the declarative system and Home Manager configuration:

```bash
git clone https://github.com/mmilani1/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo nixos-rebuild switch --flake ./nixos#homelab
```

#### Provisioning Encrypted Homelab Secrets (`sops-nix`)

1. Convert the Mini PC host SSH key to an `age` public key and add it to `.sops.yaml`:
   ```bash
   ssh-keyscan homelab | ssh-to-age
   ```
2. Create and encrypt `nixos/secrets.yaml` with `restic_repo` and `restic_password`:
   ```bash
   sops nixos/secrets.yaml
   ```
3. Re-run `sudo nixos-rebuild switch --flake ./nixos#homelab` to activate automated daily Restic backups.
