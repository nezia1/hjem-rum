{lib}: let
  inherit (builtins) map isList toString;
  inherit (lib.strings) concatStringsSep;
in {inherit toEnv;}
