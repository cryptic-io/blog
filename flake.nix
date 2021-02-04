{
  description = "blog.cryptic.io";
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-20.09";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.syndicate-rss.url = "github:marcopolo/syndicate-rss";
  # Devving
  # inputs.syndicate-rss.url = "/Users/marcomunizaga/code/syndicate-rss";

  outputs = { self, nixpkgs, flake-utils, syndicate-rss }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          syn-rss-bin = "${syndicate-rss.defaultPackage.${system}}/bin/syndicate-rss";
          syndicateBlogPosts = pkgs.writeScriptBin "syndicateBlogPosts" ''
            # Fetch from Marco's Blog
            ${syn-rss-bin} --in https://marcopolo.io/code/atom.xml --out ./content --lastN 10

            # Fetch from Brian's Blog
            ${syn-rss-bin} --in https://blog.mediocregopher.com/feed/by_tag/tech.xml --out ./content --lastN 10
          '';
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.zola syndicate-rss.defaultPackage.${system} syndicateBlogPosts ];
          };
          defaultPackage = pkgs.stdenv.mkDerivation {
            name = "blog-1.0.0";
            buildInputs = [ pkgs.zola ];
            src = ./.;
            installPhase = ''
              mkdir $out
              zola build
              cp -r public/* $out/
            '';
          };
        }
      );
}
