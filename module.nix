self:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.pgf;
in
{
  options.programs.pgf = {
    enable = lib.mkEnableOption "pgf, an fzf picker for psql services and saved queries";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The pgf package.";
    };

    connections = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      example = lib.literalExpression ''{ work = ./pg/work.conf; }'';
      description = "Service files placed in ~/.config/pgf/connections, keyed by name. They land in the Nix store, so keep passwords out of them.";
    };

    queries = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      example = lib.literalExpression ''{ slow-queries = ./sql/slow-queries.sql; }'';
      description = "Extra queries placed in ~/.config/pgf/queries, keyed by name.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile =
      lib.mapAttrs' (name: source: lib.nameValuePair "pgf/connections/${name}.conf" { inherit source; }) cfg.connections
      // lib.mapAttrs' (name: source: lib.nameValuePair "pgf/queries/${name}.sql" { inherit source; }) cfg.queries;
  };
}
