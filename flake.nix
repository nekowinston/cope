{
  inputs = {
    mozilla-addons-to-nix.url = "sourcehut:~rycee/mozilla-addons-to-nix";
    addons = {
      url = "path:./addons.json";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    mozilla-addons-to-nix,
    addons,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];
    eachSystem = fn: lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});
  in {
    packages = eachSystem (
      pkgs: let
        addonsJSON = builtins.readFile addons;
        addonsList = lib.attrsets.catAttrs "slug" (builtins.fromJSON addonsJSON);
        addonsDrv = pkgs.runCommand "build-addons" {
          buildInputs = [mozilla-addons-to-nix.packages.${pkgs.system}.default];
          passAsFile = ["addonsJSON"];
        } "mozilla-addons-to-nix ${addons} $out";
        addonListIFD = import addonsDrv {
          inherit (pkgs) fetchurl lib stdenv;
          inherit buildFirefoxXpiAddon;
        };
        buildFirefoxXpiAddon = lib.makeOverridable ({
          stdenv ? pkgs.stdenv,
          fetchurl ? pkgs.fetchurl,
          pname,
          version,
          addonId,
          url,
          sha256,
          meta,
          ...
        }:
          stdenv.mkDerivation {
            name = "${pname}-${version}";

            inherit meta;

            src = fetchurl {inherit url sha256;};

            preferLocalBuild = true;
            allowSubstitutes = true;

            buildCommand = ''
              dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
              mkdir -p "$dst"
              install -v -m644 "$src" "$dst/${addonId}.xpi"
            '';
          });
      in
        {
          default = addonsDrv;
        }
        // lib.attrsets.genAttrs addonsList (addon: addonListIFD.${addon})
    );
  };
}
