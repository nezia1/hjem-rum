{lib}: {
  gtk = import ./gtk.nix {inherit lib;};
  hypr = import ./hypr.nix {inherit lib;};
  environment = import ./environment.nix {inherit lib;};
}
