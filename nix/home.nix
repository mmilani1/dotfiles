{
  pkgs,
  user,
  lib,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;

  home = {
    stateVersion = "25.05";
    packages = with pkgs; [
      coreutils
      direnv
      docker
      fzf
      gh
      gh-dash
      git
      gnupg
      jujutsu
      nixfmt-rfc-style
      ripgrep
      starship
      tmux
      zoxide
      zsh
      zsh-abbr
      zsh-autosuggestions-abbreviations-strategy
    ];
  };

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };
    gh = {
      enable = true;
      extensions = [ pkgs.gh-dash ];
      settings = {
        git_protocol = "ssh";
      };
    };
    gh-dash.enable = true;
    git = {
      enable = true;
      userName = "Matheus Milani";
      userEmail = "32438065+mmilani1@users.noreply.github.com";
      ignores = [ ".DS_Store" ];
      signing = {
        key = "Matheus Milani";
        signByDefault = true;
        format = "openpgp";
      };
      delta = {
        enable = true;
      };
      extraConfig = {
        push = {
          default = "current";
          autoSetupRemote = true;
        };
        pull = {
          rebase = true;
        };
        merge = {
          conflictstyle = "zdiff3";
        };
        rebase = {
          autosquash = true;
          autostash = true;
          updateRefs = true;
        };
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        diff = {
          algorithm = "histogram";
        };
        stash.showIncludeUntracked = true;
      };
    };
    gpg = {
      enable = true;
      publicKeys = [
        {
          source = "${pkgs.fetchurl {
            url = "https://github.com/mmilani1.gpg";
            sha256 = "sha256-BKhg+EvwkS9Ov77Dqa3ihFJepY4Ktjm2/QjELIHfGFc=";
          }}";
          trust = 5;
        }
      ];
    };
    home-manager.enable = true;
    jujutsu = {
        enable = true;
        settings = {
            user = {
                name = "Matheus Milani";
                email = "32438065+mmilani1@users.noreply.github.com";
            };
        };
    };
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    ripgrep.enable = true;
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    tmux = {
      enable = true;
      mouse = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      autocd = true;
      antidote = {
        enable = true;
        plugins = [
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-syntax-highlighting"
          "zsh-users/zsh-completions"
          "zsh-users/zsh-history-substring-search"
          "Aloxaf/fzf-tab"
          "olets/zsh-autosuggestions-abbreviations-strategy"
        ];
      };
      zsh-abbr = {
        enable = true;
        abbreviations = {
          gco = "git checkout";
        };
      };
      syntaxHighlighting = {
        enable = true;
      };
      autosuggestion = {
        enable = true;
      };
      initContent =
        let
          gpg-config = lib.mkOrder 800 ''export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) '';
          abbr-highlight = lib.mkOrder 1000 ''(( ''${#ABBR_REGULAR_USER_ABBREVIATIONS} )) && { ZSH_HIGHLIGHT_HIGHLIGHTERS+=(regexp) ZSH_HIGHLIGHT_REGEXP+=("^[[:blank:][:space:]]*("''${(j:|:)''${(Qk)ABBR_REGULAR_USER_ABBREVIATIONS}}")$" fg=magenta,bold) ZSH_HIGHLIGHT_REGEXP+=("\<("''${(j:|:)''${(Qk)ABBR_GLOBAL_USER_ABBREVIATIONS}}")$" fg=magenta,bold) } '';
          abbr-autosuggestion = lib.mkOrder 1000 ''ZSH_AUTOSUGGEST_STRATEGY=( abbreviations $ZSH_AUTOSUGGEST_STRATEGY ) '';
        in
        lib.mkMerge [
          gpg-config
          abbr-highlight
          abbr-autosuggestion
        ];
      historySubstringSearch.enable = true;
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;
    };
  };

  imports = [
    ./home/darwin.nix
    ./home/linux.nix
  ];
}
