{
  description = "news.cryptic.io";
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

          syndicateBlogPosts = pkgs.writeScriptBin "syndicateBlogPosts"
            (builtins.concatStringsSep "\n"
              (builtins.map
                (feed:
                  ''${syn-rss-bin} \
                      --in '${feed.url}' \
                      --out ./content \
                      --noContent \
                      --extraFieldValue feedName="${feed.name}" \
                      ${if feed?author
                        then ''--author "${feed.author}"''
                        else ""} \
                      --lastN 10 \
                  ''
                )
                (import "${self}/feeds.nix")));
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
