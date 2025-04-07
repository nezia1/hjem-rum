{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (builtins) any attrValues filter;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkEnableOption mkPackageOption mkOption;
  inherit (lib.strings) concatStringsSep optionalString;
  inherit (lib.trivial) id;
  inherit (lib.types) attrsOf listOf bool lines nullOr path submodule;

  mkPlugins = plugins:
    concatStringsSep "\n"
    (mapAttrsToList (name: value:
      # this is to avoid writing empty strings into .zshrc
        concatStringsSep "\n" (filter (s: s != "") [
          "# ${name}"
          (optionalString (value.source != null) ''source "${value.source}"'')
          (optionalString (value.completions != [])
            (concatStringsSep "\n" (map (completion: "fpath+=(${completion})") value.completions)))
          (optionalString (value.config != "") value.config)
        ]))
    plugins);

  mkShellConfigOption = configLocation:
    mkOption {
      type = lines;
      default = "";
      description = ''
        Commands that will be added verbatim to ${configLocation}.;
      '';
    };

  cfg = config.rum.programs.zsh;
in {
  options.rum.programs.zsh = {
    enable = mkEnableOption "zsh module.";
    package = mkPackageOption pkgs "zsh" {};
    plugins = mkOption {
      type = attrsOf (submodule {
        options = {
          source = mkOption {
            type = nullOr path;
            default = null;
            example = literalExpression ''"\${pkgs.nix-zsh-completions}/share/zsh/plugins/nix/nix-zsh-completions-plugin.zsh\"'';
            description = "Path to the plugin file to load.";
          };
          completions = mkOption {
            type = listOf path;
            default = [];
            example = literalExpression ''["\${pkgs.nix-zsh-completions}/share/zsh/site-functions"]'';
            description = ''
              A list of completions that will be loaded into `fpath`.
            '';
          };
          config = mkShellConfigOption "{file}`.zshrc` right after the plugin import.";
        };
      });
      default = {};
      description = ''
        An attrset of plugins to load into zsh. Configuration of the former can be done and is advised to be
        done at this level, for the sake of organization.
      '';
    };
    integrations = {
      starship.enable = mkOption {
        type = bool;
        default = config.rum.programs.starship.enable;
        example = true;
        description = "Whether to enable starship integration.";
      };
    };
    initConfig = mkShellConfigOption "{file}`.zshrc`";
    loginConfig = mkShellConfigOption "{file}`.zlogin`";
    logoutConfig = mkShellConfigOption "{file}`.zlogout`";
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files = let
      check = {
        environment = config.environment.sessionVariables != {};
        plugins = cfg.plugins != [];
        initConfig = cfg.initConfig != "";
      };
    in {
      ".zshenv".source = mkIf check.environment config.environment.loadEnv;
      ".zshrc".text =
        # this makes it less verbose to check if any boolean in `check` is true
        mkIf (any id (attrValues check))
        (
          optionalString check.plugins (mkPlugins cfg.plugins)
          + optionalString check.initConfig cfg.initConfig
          + optionalString cfg.integrations.starship.enable
          ''eval "$(${getExe config.rum.programs.starship.package} init zsh)"''
        );
    };
  };
}
