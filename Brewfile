tap "can1357/tap"
tap "nikitabobko/tap" if OS.mac?

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
brew "ssh-to-age"
brew "starship"
brew "stow"
brew "syncthing"
brew "zoxide"
brew "zsh"

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
  cask "font-jetbrains-mono-nerd-font"
  # Linux GUI Flatpaks
  flatpak "app.zen_browser.zen"
  flatpak "com.bitwarden.desktop"
  flatpak "com.stremio.Stremio"
  flatpak "com.valvesoftware.Steam"
  flatpak "com.visualstudio.code"
  flatpak "dev.vencord.Vesktop"
end
