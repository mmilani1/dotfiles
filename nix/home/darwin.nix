{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  home.packages = with pkgs; [
    colima
  ];

  programs = {
    zsh = {
      initContent = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '';
    };
  };

  services = {
    gpg-agent = {
      extraConfig = ''
        pinentry-program /opt/homebrew/bin/pinentry-mac
      '';
    };
  };

  home.file.".Brewfile" = {
    text = ''
      brew "pinentry-mac"
      cask "raycast"
      cask "stremio"
      cask "visual-studio-code"
      cask "ghostty"
      cask "zen"
      cask "bitwarden"
      cask "nikitabobko/tap/aerospace"
      cask "discord"
      cask "steam"
      cask "jetbrains-toolbox"
      cask "protonvpn"
    '';
    onChange = ''
      /opt/homebrew/bin/brew bundle install --cleanup --no-upgrade --force --global
    '';
  };

  home.file.".config/aerospace/aerospace.toml" = {
    text = import ./extraConfig/aerospace.nix;
  };
}
