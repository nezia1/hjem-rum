{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum lines;

  gitIni = pkgs.formats.gitIni {};
  cfg = config.rum.programs.git;
in {
  options.rum.programs.git = {
    enable = mkEnableOption "git";

    package = mkPackageOption pkgs "git" {nullable = true;};

    settings = mkOption {
      type = gitIni.type;
      default = {};
      example = {
        user = {
          email = "alice@example.com";
          name = "alice";
        };
        init = {
          defaultBranch = "main";
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
      description = ''
        Settings that will be written to your configuration file.
      '';
    };

    ignore = mkOption {
      type = lines;
      default = "";
      example = ''
        .direnv
      '';
      description = ''
        Global user-level version of .gitignore written to
        {file}`$HOME/.config/git/ignore`.
      '';
    };

    attributes = mkOption {
      type = lines;
      default = "";
      example = ''
        # Auto detect text files and perform LF normalization
        * text=auto

        # Detect Markdown files
        *.md linguist-detectable=true
      '';
      description = ''
        Global user-level version of .gitattributes written to
        {file}`$HOME/.config/git/attributes`.
      '';
    };

    destination = mkOption {
      type = enum [
        ".gitconfig"
        ".config/git/config"
      ];
      default = ".gitconfig";
      description = ''
        Select your preferred git config location. Do note that options set in
        {file}`$HOME/.gitconfig` will shadow anything set in `.config/git/config`.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    files = {
      ${cfg.destination}.source = mkIf (cfg.settings != {}) (
        gitIni.generate ".gitconfig" cfg.settings
      );
      ".config/git/ignore".text = mkIf (cfg.ignore != {}) cfg.ignore;
      ".config/git/attributes".text = mkIf (cfg.attributes != {}) cfg.attributes;
    };
  };
}
