{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      mkPkgs = system: { pkgs = import nixpkgs { inherit system; }; };
      mkOutput = func: nixpkgs.lib.genAttrs systems (system: func (mkPkgs system));
    in
    {
      overlays.default = final: prev: { duckdb = final.callPackage ./default.nix { }; };

      packages = mkOutput (
        { pkgs }:
        let
          duckdb = pkgs.callPackage ./default.nix { };
        in
        {
          # pplanel/ghola's build: no JDBC, only the extensions it loads.
          # The only package here, because pplanel/nixcache's publish
          # workflow builds every package of the flake into the GHCR cache,
          # and upstream's default (JDBC, httpfs, gcs) is a long build
          # nothing here uses.
          ghola = duckdb.mkDuckdb {
            extensions = with duckdb.extensions; [
              core_functions
              icu
              json
              parquet
              fts
            ];
            withJdbc = false;
          };
        }
      );
    };
}
