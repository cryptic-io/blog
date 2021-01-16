# Setup
Install [Nix](https://nixos.org/) and optionally [direnv](https://direnv.net/).

# Serve the blog

```
nix develop --command zola serve
```

Or remotely!

```
nix develop github:cryptic-io/blog --command zola serve
```

# Build the blog