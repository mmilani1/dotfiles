#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting dotfiles setup..."

# 1. Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Run Brewfile
echo "Installing dependencies from Brewfile..."
cd "$DOTFILES_DIR"
brew bundle --file=Brewfile --no-lock

# 3. Stow dotfiles
echo "Stowing configurations..."
# Remove existing .zshrc if it's the default one so stow doesn't fail
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "Removing existing ~/.zshrc to allow stow to link it..."
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi

stow -R -t "$HOME" git zsh aerospace

# 4. macOS defaults
echo "Applying macOS defaults..."
bash "$DOTFILES_DIR/macos_defaults.sh"

echo "Setup complete! You may need to restart your terminal or log out/in for some changes to take effect."
