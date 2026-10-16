#!/usr/bin/env bash
set -euo pipefail

echo "Applying macOS settings..."

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

# Persistent Dock Apps (Zen, Visual Studio Code, Ghostty)
dock_item() {
    local app_path="$1"
    printf '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>' "$app_path"
}

defaults write com.apple.dock persistent-apps -array \
    "$(dock_item "/Applications/Zen.app")" \
    "$(dock_item "/Applications/Visual Studio Code.app")" \
    "$(dock_item "/Applications/Ghostty.app")"

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

# Remap Caps Lock (0x700000039) to Escape (0x700000029)
echo "Remapping Caps Lock to Escape..."
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}' >/dev/null

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
KEY_REMAP_PLIST="$LAUNCH_AGENTS_DIR/com.local.KeyRemapping.plist"
mkdir -p "$LAUNCH_AGENTS_DIR"
cat > "$KEY_REMAP_PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.KeyRemapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

# Restart affected apps
killall Dock || true
killall Finder || true

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
