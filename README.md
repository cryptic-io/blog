# Setup

Install [Nix](https://nixos.org/) and optionally [direnv](https://direnv.net/).

# Add a blog for syndication

Any blog with a compatible RSS or Atom feed can be added to the `feeds.nix`
file. The full set of steps are:

1. Create or find an atom RSS feed for a specific category of posts that you
   want to syndicate. I syndicate everything from my
   [code](https://marcopolo.io/code/atom.xml) section, and Brian syndicates
   everything from his
   [tech](https://blog.mediocregopher.com/feed/by_tag/tech.xml) section.

2. Validate this feed by going to https://validator.w3.org/feed/. Warnings are
   ok.

3. Add your blog to the `feeds.nix` file. You may have to manually set the
   `author` field here if the feed doesn't set it itself. Other fields are
   required.

4. Create a PR, and we'll maybe merge it. After that all updates will happen
   automatically every hour.

# Serve the blog

```
nix develop --command zola serve
```

Or remotely!

# Build the blog

```
nix build
```

The result will be in the `result/` directory.

# Manually syndicate RSS

This is helpful if you want to test that syndication is working. This happens
automatically every hour.

```
nix develop --command syndicateBlogPosts
```
