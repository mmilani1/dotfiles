#!/usr/bin/env bash

echo "Applying macOS settings..."

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

# Finder
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Global Domain
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# Restart affected apps
killall Dock
killall Finder

# Enable Touch ID for sudo (macOS Sonoma and later)
if [ -f /etc/pam.d/sudo_local.template ] && [ ! -f /etc/pam.d/sudo_local ]; then
    echo "Enabling Touch ID for sudo..."
    sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
    sudo sed -i '' 's/^#auth/auth/' /etc/pam.d/sudo_local
elif grep -q "pam_tid.so" /etc/pam.d/sudo 2>/dev/null; then
    # Already enabled in older macOS, or hand-edited
    :
elif [ -f /etc/pam.d/sudo ] && [ ! -f /etc/pam.d/sudo_local ]; then
    echo "Enabling Touch ID for sudo (legacy)..."
    sudo sed -i '' '2i\
auth       sufficient     pam_tid.so\
' /etc/pam.d/sudo
fi

echo "macOS settings applied successfully!"
