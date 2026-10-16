{
  config,
  pkgs,
  lib,
  user,
  ...
}:
let
  dotfilesDir = "/home/${user}/dotfiles";
  symlink = relPath: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${relPath}";
in
{
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "25.05";
    packages = with pkgs; [
      coreutils
      delta
      direnv
      fzf
      gh
      gh-dash
      git
      gnupg
      neovim
      ripgrep
      starship
      zoxide
      zsh
      zsh-abbr
      zsh-autosuggestions-abbreviations-strategy
    ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  # Directly source shared headless dotfiles from the monorepo Stow packages
  xdg.configFile = {
    "git/config".source = symlink "git/.config/git/config";
    "git/ignore".source = symlink "git/.config/git/ignore";
    "nvim/init.lua".source = symlink "nvim/.config/nvim/init.lua";
    "starship.toml".source = symlink "starship/.config/starship.toml";
    "gh/config.yml".source = symlink "gh/.config/gh/config.yml";
    "gh-dash/config.yml".source = symlink "gh/.config/gh-dash/config.yml";
    "zsh-abbr/user-abbreviations".source = symlink "zsh/.config/zsh-abbr/user-abbreviations";
  };

  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      autocd = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;
      antidote = {
        enable = true;
        plugins = [
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-syntax-highlighting"
          "zsh-users/zsh-completions"
          "zsh-users/zsh-history-substring-search"
          "Aloxaf/fzf-tab"
          "olets/zsh-abbr"
          "olets/zsh-autosuggestions-abbreviations-strategy"
        ];
      };
      initContent = ''
        if (( ''${#ABBR_REGULAR_USER_ABBREVIATIONS} )); then
          ZSH_HIGHLIGHT_HIGHLIGHTERS+=(regexp)
          ZSH_HIGHLIGHT_REGEXP+=("^[[:blank:][:space:]]*("''${(j:|:)''${(Qk)ABBR_REGULAR_USER_ABBREVIATIONS}}")$" fg=magenta,bold)
          ZSH_HIGHLIGHT_REGEXP+=("\<("''${(j:|:)''${(Qk)ABBR_GLOBAL_USER_ABBREVIATIONS}}")$" fg=magenta,bold)
        fi
        ZSH_AUTOSUGGEST_STRATEGY=( abbreviations $ZSH_AUTOSUGGEST_STRATEGY )
      '';
    };
  };
}
