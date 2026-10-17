#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS_NAME="$(uname -s)"

COMMON_PACKAGES=(git zsh ghostty starship nvim mise gh gnupg)
MACOS_PACKAGES=(aerospace)
LINUX_PACKAGES=(niri noctalia)

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap and manage cross-platform dotfiles (macOS & Linux).
If no options are provided, runs all applicable steps (--all).

Options:
  --all       Run all applicable steps (default)
  --brew      Install Homebrew/Flatpaks and bundle packages from Brewfile
  --stow      Symlink Stow packages into \$HOME (conflict-safe)
  --shell     Configure default login shell to Zsh
  --gpg       Configure gpg-agent pinentry and import GitHub public GPG key
  --mise      Install global language runtimes via mise
  --macos     Apply macOS system defaults (Darwin only)
  -h, --help  Show this help message
EOF
}

ensure_brew_in_path() {
    if command -v brew &>/dev/null; then
        return 0
    fi
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

can_sudo() {
    sudo -n true 2>/dev/null || { [[ -t 0 ]] && sudo -v; }
}

run_brew() {
    echo "==> Setting up Homebrew & packages..."
    local rc=0
    ensure_brew_in_path
    if ! command -v brew &>/dev/null; then
        if [[ "$OS_NAME" == "Linux" ]] && ! can_sudo; then
            echo "Error: Homebrew is missing and installing it requires sudo." >&2
            return 1
        fi
        echo "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        ensure_brew_in_path
    fi

    if [[ "$OS_NAME" == "Linux" ]]; then
        if command -v pacman &>/dev/null; then
            local pacman_pkgs=(zsh ghostty flatpak tailscale ttf-jetbrains-mono-nerd ccid)
            local missing_pkgs=()
            for pkg in "${pacman_pkgs[@]}"; do
                if ! pacman -Qi "$pkg" &>/dev/null; then
                    missing_pkgs+=("$pkg")
                fi
            done
            if ((${#missing_pkgs[@]})); then
                if can_sudo; then
                    echo "Installing Linux packages via pacman (${missing_pkgs[*]})..."
                    sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}" || rc=1
                    command -v fc-cache &>/dev/null && fc-cache -f &>/dev/null || true
                else
                    echo "Warning: skipping pacman packages (needs sudo): sudo pacman -S --needed --noconfirm ${missing_pkgs[*]}" >&2
                fi
            fi
        fi

        if command -v flatpak &>/dev/null; then
            if ! flatpak remotes --system --columns=name 2>/dev/null | grep -qx flathub; then
                if can_sudo; then
                    echo "Ensuring Flathub system remote is configured..."
                    sudo flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo || rc=1
                else
                    echo "Warning: skipping Flathub system remote (needs sudo): sudo flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo" >&2
                fi
            fi
        fi
    fi

    brew bundle --file="$DOTFILES_DIR/Brewfile" --force-cleanup || {
        echo "Warning: brew bundle reported failures; continuing with remaining steps." >&2
        rc=1
    }

    if [[ "$OS_NAME" == "Linux" ]]; then
        if command -v pacman &>/dev/null && command -v systemctl &>/dev/null && command -v tailscale &>/dev/null; then
            if can_sudo; then
                echo "Ensuring system Tailscale daemon is enabled..."
                sudo systemctl enable --now tailscaled || rc=1
            else
                echo "Warning: skipping Tailscale daemon setup (needs sudo): sudo systemctl enable --now tailscaled" >&2
            fi
        fi
    fi

    if command -v gh &>/dev/null; then
        if ! gh extension list 2>/dev/null | grep -q "dlvhdr/gh-dash"; then
            echo "Installing gh-dash extension..."
            gh extension install dlvhdr/gh-dash || true
        fi
    fi

    return "$rc"
}

cleanup_legacy_path() {
    local target="$1"
    if [[ -L "$target" ]]; then
        rm -f "$target"
    elif [[ -e "$target" ]]; then
        mv "$target" "${target}.backup"
    fi
}

prepare_stow_target() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"
    local rel_path target_path parent_dir

    while IFS= read -r -d '' entry; do
        rel_path="${entry#"$pkg_dir"/}"
        target_path="$HOME/$rel_path"

        # If any parent directory along the path is a symlink (e.g., to /nix/store), remove the symlink
        parent_dir="$(dirname "$target_path")"
        while [[ "$parent_dir" != "$HOME" && "$parent_dir" != "/" && "$parent_dir" != "." ]]; do
            if [[ -L "$parent_dir" ]]; then
                rm -f "$parent_dir"
            fi
            parent_dir="$(dirname "$parent_dir")"
        done

        if [[ -L "$target_path" ]]; then
            rm -f "$target_path"
        elif [[ -e "$target_path" ]]; then
            mv "$target_path" "${target_path}.backup"
        fi
    done < <(find "$pkg_dir" \( -type f -o -type l \) -print0)
}

run_stow() {
    echo "==> Stowing dotfiles into $HOME..."
    ensure_brew_in_path
    if ! command -v stow &>/dev/null; then
        echo "Error: stow is not installed. Run ./install.sh --brew first." >&2
        return 1
    fi

    # Clean up legacy root Git files so XDG ~/.config/git/config takes precedence
    cleanup_legacy_path "$HOME/.gitconfig"
    cleanup_legacy_path "$HOME/.gitignore_global"

    local packages=("${COMMON_PACKAGES[@]}")
    if [[ "$OS_NAME" == "Darwin" ]]; then
        packages+=("${MACOS_PACKAGES[@]}")
    elif [[ "$OS_NAME" == "Linux" ]]; then
        packages+=("${LINUX_PACKAGES[@]}")
    fi

    mkdir -p "$HOME/.config" "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"

    for pkg in "${packages[@]}"; do
        prepare_stow_target "$pkg"
    done

    stow -d "$DOTFILES_DIR" -R -t "$HOME" "${packages[@]}"
    echo "Stowed packages: ${packages[*]}"
}

run_gpg() {
    echo "==> Configuring GnuPG, Smartcard/YubiKey & SSH..."
    ensure_brew_in_path
    mkdir -p "$HOME/.gnupg" "$HOME/.ssh"
    chmod 700 "$HOME/.gnupg" "$HOME/.ssh"

    # Populate known_hosts for GitHub if missing
    if [[ ! -f "$HOME/.ssh/known_hosts" ]] || ! grep -q "github.com" "$HOME/.ssh/known_hosts" 2>/dev/null; then
        if command -v ssh-keyscan &>/dev/null; then
            echo "Adding github.com to ~/.ssh/known_hosts..."
            ssh-keyscan -t ed25519,rsa github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
            chmod 644 "$HOME/.ssh/known_hosts"
        fi
    fi

    local pinentry_bin=""
    if [[ "$OS_NAME" == "Darwin" ]]; then
        if command -v brew &>/dev/null && [[ -x "$(brew --prefix)/bin/pinentry-mac" ]]; then
            pinentry_bin="$(brew --prefix)/bin/pinentry-mac"
        else
            pinentry_bin="$(command -v pinentry-mac || true)"
        fi
    else
        # Prefer distro GUI pinentry on Linux (avoids pinentry-curses in Wayland/GUI)
        if [[ -x /usr/bin/pinentry ]]; then
            pinentry_bin="/usr/bin/pinentry"
        elif [[ -x /usr/bin/pinentry-gnome3 ]]; then
            pinentry_bin="/usr/bin/pinentry-gnome3"
        elif [[ -x /usr/bin/pinentry-qt ]]; then
            pinentry_bin="/usr/bin/pinentry-qt"
        else
            pinentry_bin="$(command -v pinentry || true)"
        fi
    fi

    if [[ -z "$pinentry_bin" ]]; then
        echo "Warning: no pinentry binary found; gpg-agent will use its default prompt." >&2
    fi

    {
        echo "enable-ssh-support"
        echo "grab"
        echo "default-cache-ttl 600"
        echo "default-cache-ttl-ssh 600"
        if [[ -n "$pinentry_bin" ]]; then
            echo "pinentry-program $pinentry_bin"
        fi
    } > "$HOME/.gnupg/gpg-agent.conf"
    chmod 600 "$HOME/.gnupg/gpg-agent.conf"

    # Distro socket-activated GnuPG units respawn an older keyboxd on connect
    # (e.g. 2.4.9 vs Homebrew 2.5.24); mask them so Homebrew's daemons own the sockets.
    if [[ "$OS_NAME" == "Linux" ]] && command -v systemctl &>/dev/null; then
        if [[ "$(command -v gpgconf || true)" == *homebrew* ]]; then
            systemctl --user mask --now \
                gpg-agent.socket gpg-agent-browser.socket gpg-agent-extra.socket \
                gpg-agent-ssh.socket keyboxd.socket dirmngr.socket >/dev/null 2>&1 || true
        fi
    fi

    if command -v gpgconf &>/dev/null; then
        gpgconf --kill all >/dev/null 2>&1 || true
    fi

    if command -v gpg &>/dev/null && command -v curl &>/dev/null; then
        curl -fsSL https://github.com/mmilani1.gpg | gpg --import 2>/dev/null ||
            echo "Warning: failed to import GitHub GPG key" >&2
    fi

    # Learn connected smartcard / YubiKey stubs for GnuPG and SSH authentication
    if command -v gpg-connect-agent &>/dev/null; then
        gpg-connect-agent "scd serialno" "learn --force" /bye >/dev/null 2>&1 || true
    fi
}

run_mise() {
    echo "==> Installing global language runtimes with mise..."
    ensure_brew_in_path
    if command -v mise &>/dev/null; then
        mise install
    else
        echo "Error: mise is not installed. Run ./install.sh --brew first." >&2
        return 1
    fi
}

run_shell() {
    echo "==> Configuring login shell..."
    local current_shell=""
    if [[ "$OS_NAME" == "Darwin" ]] && command -v dscl &>/dev/null; then
        current_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
    fi
    if [[ -z "$current_shell" ]] && command -v getent &>/dev/null; then
        current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
    fi
    current_shell="${current_shell:-${SHELL:-}}"

    if [[ "$current_shell" == *"/zsh" ]]; then
        echo "Login shell is already Zsh ($current_shell)."
        return 0
    fi

    ensure_brew_in_path

    local target_zsh=""
    local candidate
    local candidates=()
    if command -v zsh &>/dev/null; then
        candidates+=("$(command -v zsh)")
    fi
    for p in /usr/bin/zsh /bin/zsh /usr/local/bin/zsh; do
        if [[ -x "$p" ]]; then candidates+=("$p"); fi
    done

    if [[ -r /etc/shells ]]; then
        for candidate in "${candidates[@]}"; do
            if grep -Fxq "$candidate" /etc/shells; then
                target_zsh="$candidate"
                break
            fi
        done
    fi

    if [[ -z "$target_zsh" ]]; then
        for candidate in "${candidates[@]}"; do
            if [[ -x "$candidate" ]]; then
                target_zsh="$candidate"
                break
            fi
        done
    fi

    if [[ -z "$target_zsh" ]]; then
        echo "Error: zsh binary not found. Install zsh or run ./install.sh --brew first." >&2
        return 1
    fi

    if [[ -r /etc/shells ]] && ! grep -Fxq "$target_zsh" /etc/shells; then
        if can_sudo; then
            echo "Adding $target_zsh to /etc/shells..."
            echo "$target_zsh" | sudo tee -a /etc/shells >/dev/null
        else
            echo "Error: $target_zsh is not in /etc/shells and adding it requires sudo." >&2
            return 1
        fi
    fi

    echo "Changing login shell from $current_shell to $target_zsh..."
    if can_sudo; then
        local changed=false
        if [[ "$OS_NAME" == "Linux" ]] && command -v usermod &>/dev/null; then
            sudo usermod -s "$target_zsh" "$USER" && changed=true
        fi
        if [[ "$changed" == false ]]; then
            if ! sudo chsh -s "$target_zsh" "$USER"; then
                echo "Warning: failed to change login shell via sudo." >&2
                return 1
            fi
        fi
    elif [[ -t 0 ]]; then
        if ! chsh -s "$target_zsh"; then
            echo "Warning: failed to change login shell via chsh." >&2
            return 1
        fi
    else
        echo "Warning: changing login shell requires an interactive terminal or sudo. Run manually: chsh -s $target_zsh" >&2
        return 1
    fi
    if [[ "$OS_NAME" == "Linux" ]] && command -v systemctl &>/dev/null; then
        systemctl --user set-environment SHELL="$target_zsh" 2>/dev/null || true
    fi

    echo "Login shell changed to $target_zsh. (Restart terminal or log out to take effect)"
}

run_macos() {
    if [[ "$OS_NAME" == "Darwin" ]]; then
        echo "==> Applying macOS defaults..."
        bash "$DOTFILES_DIR/macos_defaults.sh"
    else
        echo "==> Skipping macOS defaults on $OS_NAME."
    fi
}

DO_BREW=false
DO_STOW=false
DO_SHELL=false
DO_GPG=false
DO_MISE=false
DO_MACOS=false

if [[ $# -eq 0 ]]; then
    DO_BREW=true
    DO_STOW=true
    DO_SHELL=true
    DO_GPG=true
    DO_MISE=true
    DO_MACOS=true
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                DO_BREW=true
                DO_STOW=true
                DO_GPG=true
                DO_SHELL=true
                DO_MISE=true
                DO_MACOS=true
                ;;
            --brew)
                DO_BREW=true
                ;;
            --stow)
                DO_STOW=true
                ;;
            --shell)
                DO_SHELL=true
                ;;
            --gpg)
                DO_GPG=true
                ;;
            --mise)
                DO_MISE=true
                ;;
            --macos)
                DO_MACOS=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
        shift
    done
fi

STAGE_FAILURES=()
if [[ "$DO_BREW" == true ]]; then run_brew || STAGE_FAILURES+=("brew"); fi
if [[ "$DO_STOW" == true ]]; then run_stow || STAGE_FAILURES+=("stow"); fi
if [[ "$DO_SHELL" == true ]]; then run_shell || STAGE_FAILURES+=("shell"); fi
if [[ "$DO_GPG" == true ]]; then run_gpg || STAGE_FAILURES+=("gpg"); fi
if [[ "$DO_MISE" == true ]]; then run_mise || STAGE_FAILURES+=("mise"); fi
if [[ "$DO_MACOS" == true ]]; then run_macos || STAGE_FAILURES+=("macos"); fi

if ((${#STAGE_FAILURES[@]})); then
    echo "==> Completed with failures: ${STAGE_FAILURES[*]}" >&2
    exit 1
fi

echo "==> Dotfiles setup complete!"
