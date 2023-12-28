{
  inputs.mozilla-addons-to-nix.url = "sourcehut:~rycee/mozilla-addons-to-nix";
  outputs = {
    self,
    nixpkgs,
    mozilla-addons-to-nix,
  }: let
    systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];
    eachSystem = fn: nixpkgs.lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});
    addons = ["simplediscordcrypt" "discord-container" "catppuccin-macchiato-lavender2"];
  in {
    packages = eachSystem (pkgs: let
      addon-list = pkgs.runCommand "build-addons" {
        buildInputs = [mozilla-addons-to-nix.packages.${pkgs.system}.default];
        addonJSON = builtins.toJSON (builtins.map (slug: {slug = slug;}) addons);
        passAsFile = ["addonJSON"];
      } "mozilla-addons-to-nix $addonListPath $out";
      buildFirefoxXpiAddon = pkgs.lib.makeOverridable ({
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
      addonListIFD = import addon-list {
        inherit (pkgs) fetchurl lib stdenv;
        inherit buildFirefoxXpiAddon;
      };
    in
      pkgs.lib.attrsets.genAttrs addons (addon: addonListIFD.${addon}));
  };
}
