{lib}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) lines;
in
  configLocation:
    mkOption {
      type = lines;
      default = "";
      description = ''
        Commands that will be added verbatim to ${configLocation}.;
      '';
    }
