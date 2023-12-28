{
  inputs = {
    cope.url = "path:..";
    cope.inputs.addons = {
      url = "path:./addons.json";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    cope,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];
    eachSystem = fn: lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});
  in {
    inherit (cope) packages;
  };
}
