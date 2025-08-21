{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  home.packages = with pkgs; [
    gcr
    pinentry-all
  ];

  services = {
    gpg-agent = {
      pinentry.package = [ pkgs.pinentry-all ];
    };
  };
}
