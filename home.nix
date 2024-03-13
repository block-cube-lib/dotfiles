{ config, pkg, ... }:
let inherit = (builtins) getEnv;
in {
  home = {
    username = "block";
    homeDirectory = "/home/block";
    stateVersion = "23.11";
  };
  nix = {
    package = pkgs.nixFlakes;
    settings {
      experimental-features = "nix-command flakes";
    };
  };
  programs.home-manager.enable = true;
}
