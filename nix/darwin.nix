{
  pkgs,
  user,
  system,
  inputs,
  ...
}:
{
  nix.enable = false; # Using Determinate Nix
  system.stateVersion = 6;
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  nixpkgs.hostPlatform = system;

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = user;
  system.defaults.dock.autohide = true;
  system.defaults.dock.show-recents = false;
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder.AppleShowAllFiles = true;
  system.defaults.finder.FXPreferredViewStyle = "Nlsv";
  system.defaults.finder.QuitMenuItem = true;
  system.defaults.finder.ShowPathbar = true;
  system.defaults.finder._FXSortFoldersFirst = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.finder.FXDefaultSearchScope = "SCcf";
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
  system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.defaults.dock.persistent-apps = [
    {
      app = "/Applications/Zen.app";
    }
    {
      app = "/Applications/Visual Studio Code.app";
    }
    {
      app = "/Applications/Ghostty.app";
    }
  ];
}
