#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS_NAME="$(uname -s)"

COMMON_PACKAGES=(git zsh ghostty starship nvim mise gh gnupg)
MACOS_PACKAGES=(aerospace)
LINUX_PACKAGES=(niri)

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap and manage cross-platform dotfiles (macOS & Linux).
If no options are provided, runs all applicable steps (--all).

Options:
  --all       Run all applicable steps (default)
  --brew      Install Homebrew/Flatpaks and bundle packages from Brewfile
  --stow      Symlink Stow packages into \$HOME (conflict-safe)
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

run_brew() {
    echo "==> Setting up Homebrew & packages..."
    ensure_brew_in_path
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        ensure_brew_in_path
    fi

    if [[ "$OS_NAME" == "Linux" ]]; then
        if command -v flatpak &>/dev/null; then
            echo "Ensuring Flathub remote is configured..."
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        fi
    fi

    brew bundle --file="$DOTFILES_DIR/Brewfile"

    if [[ "$OS_NAME" == "Linux" ]]; then
        if command -v pacman &>/dev/null && command -v systemctl &>/dev/null; then
            echo "Ensuring system Tailscale daemon is installed and enabled..."
            sudo pacman -S --needed --noconfirm tailscale
            sudo systemctl enable --now tailscaled
        fi
    fi

    if command -v gh &>/dev/null; then
        if ! gh extension list 2>/dev/null | grep -q "dlvhdr/gh-dash"; then
            echo "Installing gh-dash extension..."
            gh extension install dlvhdr/gh-dash || true
        fi
    fi
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
    echo "==> Configuring GnuPG & importing public key..."
    ensure_brew_in_path
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"

    local pinentry_bin=""
    if [[ "$OS_NAME" == "Darwin" ]]; then
        if command -v brew &>/dev/null && [[ -x "$(brew --prefix)/bin/pinentry-mac" ]]; then
            pinentry_bin="$(brew --prefix)/bin/pinentry-mac"
        else
            pinentry_bin="/opt/homebrew/bin/pinentry-mac"
        fi
    else
        pinentry_bin="$(command -v pinentry || echo "/usr/bin/pinentry")"
    fi

    cat > "$HOME/.gnupg/gpg-agent.conf" <<EOF
enable-ssh-support
grab
default-cache-ttl 600
default-cache-ttl-ssh 600
pinentry-program $pinentry_bin
EOF
    chmod 600 "$HOME/.gnupg/gpg-agent.conf"

    if command -v gpg &>/dev/null; then
        curl -fsSL https://github.com/mmilani1.gpg | gpg --import
    fi
    if command -v gpgconf &>/dev/null; then
        gpgconf --kill gpg-agent || true
    fi
}

run_mise() {
    echo "==> Installing global language runtimes with mise..."
    ensure_brew_in_path
    if command -v mise &>/dev/null; then
        mise install
    else
        echo "Warning: mise is not installed yet. Run --brew first." >&2
        return 1
    fi
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
DO_GPG=false
DO_MISE=false
DO_MACOS=false

if [[ $# -eq 0 ]]; then
    DO_BREW=true
    DO_STOW=true
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
                DO_MISE=true
                DO_MACOS=true
                ;;
            --brew)
                DO_BREW=true
                ;;
            --stow)
                DO_STOW=true
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

if [[ "$DO_BREW" == true ]]; then
    run_brew
fi
if [[ "$DO_STOW" == true ]]; then
    run_stow
fi
if [[ "$DO_GPG" == true ]]; then
    run_gpg
fi
if [[ "$DO_MISE" == true ]]; then
    run_mise
fi
if [[ "$DO_MACOS" == true ]]; then
    run_macos
fi

echo "==> Dotfiles setup complete!"
