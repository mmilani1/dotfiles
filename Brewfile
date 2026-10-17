tap "can1357/tap", trusted: true
tap "nikitabobko/tap", trusted: true if OS.mac?

# Core CLI Tools
brew "age"
brew "antidote"
brew "bitwarden-cli"
brew "can1357/tap/omp"
brew "coreutils"
brew "direnv"
brew "fzf"
brew "gh"
brew "git"
brew "git-delta"
brew "gnupg"
brew "mise"
brew "neovim"
brew "ripgrep"
brew "sops"
brew "tree-sitter-cli"
brew "starship"
brew "stow"
brew "syncthing"
brew "zoxide"

if OS.mac?
  brew "pinentry-mac"

  # Fonts
  cask "font-jetbrains-mono-nerd-font"

  # Developer & Productivity Apps
  cask "bitwarden"
  cask "ghostty"
  cask "nikitabobko/tap/aerospace"
  cask "raycast"
  cask "tailscale-app"
  cask "visual-studio-code"
  cask "zen"

  # Media, Social & Gaming Apps
  cask "steam"
  cask "stremio"
  cask "vesktop"
end

if OS.linux?
  brew "pinentry"
  brew "tailscale"
  # Linux GUI Flatpaks (requires flatpak CLI and system flathub remote)
  if Kernel.system("flatpak remotes --system --columns=name 2>/dev/null | grep -qx flathub")
    flatpak "app.zen_browser.zen"
    flatpak "com.bitwarden.desktop"
    flatpak "com.stremio.Stremio"
    flatpak "com.visualstudio.code"
    flatpak "dev.vencord.Vesktop"
  end
end
