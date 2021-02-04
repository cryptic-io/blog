# Setup
Install [Nix](https://nixos.org/) and optionally [direnv](https://direnv.net/).

# I want to contribute

Nice! there are two ways: you can add a blog post here to this repo, or you
can have your own blog syndicated here.

## Post just for Cryptic
If you want to just make a blog post for cryptic:

1. Create a Markdown file inside `content/` of the form
   `content/YOUR_NAME-TITLE.md`.
2. Add some frontmatter metadata to the start of the markdown file, like so:
```
+++
title = "Your title"
# Your publish date
date = 2021-02-01T00:00:00.000Z
[extra]
author = "Your name"
+++

Your post content
```
3. Write your post after the closing `+++` marker.

## Syndicate my blog

This is nice if you already have a blog and would like it to cross post to the
cryptic blog.

1. Create an atom RSS feed for a specific category of posts that you want to
   syndicate. I syndicate everything from my
   [code](https://marcopolo.io/code/atom.xml) section, and Brian syndicates
   everything from his
   [tech](https://blog.mediocregopher.com/feed/by_tag/tech.xml) section.
2. Validate this feed by going to https://validator.w3.org/feed/. Warnings are
   ok.
3. Add your blog to the `syndicateBlogPosts` section in `flake.nix`. Follow the
   examples of Brian and I.
4. Create a PR, and we'll merge it. After that all updates will happen
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