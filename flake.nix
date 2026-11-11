{
  description = "fzf picker for psql services and saved queries";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in
  {
    packages = forAll (pkgs: {
      default = pkgs.callPackage ./package.nix { };
    });

    checks = forAll (pkgs: {
      shellcheck = pkgs.runCommand "pgf-shellcheck" { } ''
        ${pkgs.shellcheck}/bin/shellcheck ${./bin/pgf}
        touch $out
      '';
    });

    formatter = forAll (pkgs: pkgs.nixfmt);

    homeManagerModules.default = import ./module.nix self;
  };
}
