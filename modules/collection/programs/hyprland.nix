{
  lib,
  osConfig,
  config,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.rum.utils) filterKeysPrefix;
  inherit (lib.rum.generators.hypr) toHyprconf pluginsToHyprconf;
  inherit (lib.strings) optionalString stringLength;
  inherit (lib.types) attrs either lines listOf package path str;

  cfg = config.rum.programs.hyprland;
in {
  options.rum.programs.hyprland = {
    enable = mkEnableOption "Hyprland";

    settings = mkOption {
      type = attrs;
      example = {
        "$mod" = "SUPER";
        decoration = {
          rounding = "3";
        };
      };
      default = {};
      description = ''
        Hyprland configuration written in Nix. Entries with the same key
        should be written as lists. Variables' and colors' names should be
        quoted. See <https://wiki.hyprland.org> for more examples.
      '';
    };

    plugins = mkOption {
      type = listOf (either package path);
      default = [];
      description = ''
        List of Hyprland plugins to use. Can either be packages or
        absolute plugin paths.
      '';
    };

    importantPrefixes = mkOption {
      type = listOf str;
      default = ["$" "bezier" "name"];
      example = ["$" "bezier"];
      description = ''
        List of prefix of attributes to source at the top of the config.
      '';
    };

    extraConfig = mkOption {
      type = lines;
      default = "";
      description = ''
        Extra configuration that will be appended verbatim at the end of your `hyprland.conf`.
      '';
    };
  };

  config = mkIf cfg.enable {
    files = let
      check = {
        plugins = cfg.plugins != [];
        settings = cfg.settings != {};
        variables = {
          noUWSM = config.environment.sessionVariables != {} && !osConfig.programs.hyprland.withUWSM;
          withUWSM = config.environment.sessionVariables != {} && osConfig.programs.hyprland.withUWSM;
        };
      };
    in {
      ".config/hypr/hyprland.conf".text = mkIf (check.plugins || check.settings || check.variables.noUWSM) (
        optionalString check.plugins (pluginsToHyprconf cfg.plugins)
        + optionalString check.settings (toHyprconf {
          attrs = cfg.settings;
          inherit (cfg) importantPrefixes;
        })
        + optionalString check.variables.noUWSM (toHyprconf {
          attrs.env =
            # https://wiki.hyprland.org/Configuring/Environment-variables/#xdg-specifications
            [
              "XDG_CURRENT_DESKTOP,Hyprland"
              "XDG_SESSION_TYPE,wayland"
              "XDG_SESSION_DESKTOP,Hyprland"
            ]
            ++ mapAttrsToList (key: value: "${key},${value}") config.environment.sessionVariables;
        })
        + cfg.extraConfig
      );

      /*
      uwsm environment variables are advised to be separated
      (see https://wiki.hyprland.org/Configuring/Environment-variables/)
      */
      ".config/uwsm/env".text = mkIf check.variables.withUWSM (
        filterKeysPrefix [] config.environment.sessionVariables
      );

      ".config/uwsm/env-hyprland".text = let
        /*
        this is needed as we're using a predicate so we don't create an empty file
        (improvements are welcome)
        */
        filteredVars =
          filterKeysPrefix ["HYPRLAND_" "AQ_"] config.environment.sessionVariables;
      in
        mkIf (check.variables.withUWSM && stringLength filteredVars != 0) filteredVars;
    };
  };
}
