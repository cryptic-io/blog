
+++
title = "Goodbye, Github Pages"
date = 2021-01-23T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Slowly but surely I’m working on moving my digital life back to being
self-hosted, and this blog was..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/01/23/goodbye-github-pages.html"
raw = """
<p>Slowly but surely I’m working on moving my digital life back to being
self-hosted, and this blog was an easy low-hanging fruit to tackle. Previously
the blog was hosted on Github Pages, which was easy enough but also in many ways
restricting. By self-hosting I’m able to have a lot more control over the
generation, delivery, and functionality of the blog.</p>

<p>For reference you can find the source code for the blog at
<a href="https://github.com/mediocregopher/blog.mediocregopher.com">https://github.com/mediocregopher/blog.mediocregopher.com</a>. Yes, it will one day be hosted
elsewhere as well.</p>

<h2 id="nix">Nix</h2>

<p>Nix is something I’m slowly picking up, but the more I use it the more it grows
on me. Rather than littering my system with ruby versions and packages I’ll
never otherwise use, nix allows me to create a sandboxed build pipeline for the
blog with perfectly reproducible results.</p>

<p>The first step in this process is to take the blog’s existing <code class="language-plaintext highlighter-rouge">Gemfile.lock</code> and
turn it into a <code class="language-plaintext highlighter-rouge">gemset.nix</code> file, which is essentially a translation of the
<code class="language-plaintext highlighter-rouge">Gemfile.lock</code> into a file nix can understand. There’s a tool called
<a href="https://github.com/nix-community/bundix">bundix</a> which does this, and it can be used from a nix shell without
having to actually install anything:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code> nix-shell -p bundix --run 'bundix'
</code></pre></div></div>

<p>The second step of using nix is to set up a nix expression in the file
<code class="language-plaintext highlighter-rouge">default.nix</code>. This will actually build the static files. As a bonus I made my
expression to also allow for serving the site locally with dynamic updating
everytime I change a source file. My <code class="language-plaintext highlighter-rouge">default.nix</code> looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>{
    # pkgs refers to all "builtin" nix pkgs and utilities. By importing from a
    # URL I'm able to always pin this default.nix to a specific version of those
    # packages.
    pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/cd63096d6d887d689543a0b97743d28995bc9bc3.tar.gz") {},
    system ? builtins.currentSystem,
}:

    let
        # bundlerEnv looks for a Gemfile, Gemfile.lock, and gemset.nix inside
        # gemdir, and derives a package containing ruby and all desired gems.
        ruby_env = pkgs.bundlerEnv {
            name = "ruby_env";
            ruby = pkgs.ruby;
            gemdir = ./.;
        };
    in
        {
            # build will derive a package which contains the generated static
            # files of the blog. It uses the build.sh file (provided below) to
            # do this.
            build = derivation {
                name = "mediocre-blog";

                # The build.sh file (source provided below) is executed in order
                # to actually build the site.
                builder = "${pkgs.bash}/bin/bash";
                args = [ ./build.sh ];

                # ruby_env is provided as an input to build.sh so that it can
                # use jekyll, and the src directory is provided so it can access
                # the blog's source files. system is required by the derivation
                # function, and stdenv provides standard utilities to build.sh.
                inherit ruby_env system;
                src = ./src;
                stdenv = pkgs.stdenv;
            };

            # serve will derive an environment specifically tailored for being
            # run in a nix-shell. The resulting shell will have ruby_env
            # provided for it, and will automatically run the `jekyll serve`
            # command to serve the blog locally.
            serve = pkgs.stdenv.mkDerivation {
                name = "mediocre-blog-shell";

                # glibcLocales is required so to fill in LC_ALL and other locale
                # related environment vars. Without those jekyll's scss compiler
                # fails.
                #
                # TODO probably get rid of the scss compiler.
                buildInputs = [ ruby_env pkgs.glibcLocales ];

                shellHook = ''
                    exec ${ruby_env}/bin/jekyll serve -s ./src -d ./_site -w -I -D
                '';
            };
        }
</code></pre></div></div>

<p>(Nix is a bit tricky to learn, but I highly recommend chapters 14 and 15 of <a href="https://nixos.org/manual/nix/stable/#chap-writing-nix-expressions">the
nix manual</a> for an overview of the language itself, if nothing else.)</p>

<p>The <code class="language-plaintext highlighter-rouge">build.sh</code> used by the nix expression to actually generate the static files
looks like this:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c"># stdenv was given a dependency to build.sh, and so build.sh can use it to</span>
<span class="c"># source in utilities like mkdir, which it needs.</span>
<span class="nb">source</span> <span class="nv">$stdenv</span>/setup
<span class="nb">set</span> <span class="nt">-e</span>

<span class="c"># Set up the output directory. nix provides the $out variable which will be the</span>
<span class="c"># root of the derived package's filesystem, but for simplicity later we want to</span>
<span class="c"># output the site within /var/www.</span>
<span class="nv">d</span><span class="o">=</span><span class="s2">"</span><span class="nv">$out</span><span class="s2">/var/www/blog.mediocregopher.com"</span>
<span class="nb">mkdir</span> <span class="nt">-p</span> <span class="s2">"</span><span class="nv">$d</span><span class="s2">"</span>

<span class="c"># Perform the jekyll build command. Like stdenv the ruby_env was given as a</span>
<span class="c"># dependency to build.sh, so it has to explicitly use it to have access to</span>
<span class="c"># jekyll. src is another explicit dependency which was given to build.sh, and</span>
<span class="c"># contains all the actual source files within the src directory of the repo.</span>
<span class="nv">$ruby_env</span>/bin/jekyll build <span class="nt">-s</span> <span class="s2">"</span><span class="nv">$src</span><span class="s2">"</span> <span class="nt">-d</span> <span class="s2">"</span><span class="nv">$d</span><span class="s2">"</span>
</code></pre></div></div>

<p>With these pieces in place I can easily regenerate the site like so:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>nix-build -A build
</code></pre></div></div>

<p>Once run the static files will exist within a symlink called <code class="language-plaintext highlighter-rouge">result</code> in the
project’s root. Within the symlink will be a <code class="language-plaintext highlighter-rouge">var/www/blog.mediocregopher.com</code>
tree of directories, and within that will be the generated static files, all
without ever having to have installed ruby.</p>

<p>The expression also allows me to serve the blog while I’m working on it. Doing
so looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>nix-shell -A serve
</code></pre></div></div>

<p>When run I get a normal jekyll process running in my <code class="language-plaintext highlighter-rouge">src</code> directory, serving
the site in real-time on port 4000, once again all without ever installing ruby.</p>

<p>As a final touch I introduced a simple <code class="language-plaintext highlighter-rouge">Makefile</code> to my repo to wrap these
commands, because even these were too much for me to remember:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>result:
\tnix-build -A build

install: result
\tnix-env -i "$$(readlink result)"

clean:
\trm result
\trm -rf _site

serve:
\tnix-shell -A serve

update:
\tnix-shell -p bundler --run 'bundler update; bundler lock; bundix; rm -rf .bundle vendor'
</code></pre></div></div>

<p>We’ll look at that <code class="language-plaintext highlighter-rouge">install</code> target in the next section.</p>

<h2 id="nginx">nginx</h2>

<p>So now I have the means to build my site quickly, reliably, and without
cluttering up the rest of my system. Time to actually serve the files.</p>

<p>My home server has a docker network which houses most of my services that I run,
including nginx. nginx’s primary job is to listen on ports 80 and 443, accept
HTTP requests, and direct those requests to their appropriate service based on
their <code class="language-plaintext highlighter-rouge">Host</code> header. nginx is also great at serving static content from disk, so
I’ll take advantage of that for the blog.</p>

<p>The one hitch is that nginx is currently running within a docker container,
as are all my other services. Ideally I would:</p>

<ul>
  <li>Get rid of the nginx docker container.</li>
  <li>Build a nix package containing nginx, all my nginx config files, and the blog
files themselves.</li>
  <li>Run that directly.</li>
</ul>

<p>Unfortunately extracting nginx from docker is dependent on doing so for all
other services as well, or at least on running all services on the host network,
which I’m not prepared to do yet. So for now I’ve done something janky.</p>

<p>If you look at the <code class="language-plaintext highlighter-rouge">Makefile</code> above you’ll notice the <code class="language-plaintext highlighter-rouge">install</code> target. What
that target does is to install the static blog files to my nix profile, which
exists at <code class="language-plaintext highlighter-rouge">$HOME/.nix-profile</code>. nix allows any package to be installed to a
profile in this way. All packages within a profile are independent and can be
added, updated, and removed atomically. By installing the built blog package to
my profile I make it available at
<code class="language-plaintext highlighter-rouge">$HOME/.nix-profile/var/www/blog.mediocregopher.com</code>.</p>

<p>So to serve those files via nginx all I need to do is add a read-only volume to
the container…</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>-v $HOME/.nix-profile/var/www/blog.mediocregopher.com:/var/www/blog.mediocregopher.com:ro \\
</code></pre></div></div>

<p>…add a new virtual host to my nginx config…</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>server {
    listen       80;
    server_name  blog.mediocregopher.com;
    root         /var/www/blog.mediocregopher.com;
}
</code></pre></div></div>

<p>…and finally direct the <code class="language-plaintext highlighter-rouge">blog</code> A record for <code class="language-plaintext highlighter-rouge">mediocregopher.com</code> to my home
server’s IP. Cloudflare will handle TLS on port 443 for me in this case, as well
as hide my home IP, which is prudent.</p>

<h2 id="deploying">Deploying</h2>

<p>So now it’s time to publish this new post to the blog, what are the actual
steps? It’s as easy as:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>make clean install
</code></pre></div></div>

<p>This will remove any existing <code class="language-plaintext highlighter-rouge">result</code>, regenerate the site (with the new post)
under a new symlink, and install/update that newer package to my nix profile,
overwriting the previous package which was there.</p>

<p>EDIT: apparently this isn’t quite true. Because <code class="language-plaintext highlighter-rouge">$HOME/.nix-profile</code> is a
symlink docker doesn’t handle the case of that symlink being updated correctly,
so I also have to do <code class="language-plaintext highlighter-rouge">docker restart nginx</code> for changes to be reflected in
nginx.</p>

<p>And that’s it! Nix is a cool tool that I’m still getting the hang of, but
hopefully this post might be useful to anyone else thinking of self-hosting
their site.</p>"""

+++
<p>Slowly but surely I’m working on moving my digital life back to being
self-hosted, and this blog was an easy low-hanging fruit to tackle. Previously
the blog was hosted on Github Pages, which was easy enough but also in many ways
restricting. By self-hosting I’m able to have a lot more control over the
generation, delivery, and functionality of the blog.</p>

<p>For reference you can find the source code for the blog at
<a href="https://github.com/mediocregopher/blog.mediocregopher.com">https://github.com/mediocregopher/blog.mediocregopher.com</a>. Yes, it will one day be hosted
elsewhere as well.</p>

<h2 id="nix">Nix</h2>

<p>Nix is something I’m slowly picking up, but the more I use it the more it grows
on me. Rather than littering my system with ruby versions and packages I’ll
never otherwise use, nix allows me to create a sandboxed build pipeline for the
blog with perfectly reproducible results.</p>

<p>The first step in this process is to take the blog’s existing <code class="language-plaintext highlighter-rouge">Gemfile.lock</code> and
turn it into a <code class="language-plaintext highlighter-rouge">gemset.nix</code> file, which is essentially a translation of the
<code class="language-plaintext highlighter-rouge">Gemfile.lock</code> into a file nix can understand. There’s a tool called
<a href="https://github.com/nix-community/bundix">bundix</a> which does this, and it can be used from a nix shell without
having to actually install anything:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code> nix-shell -p bundix --run 'bundix'
</code></pre></div></div>

<p>The second step of using nix is to set up a nix expression in the file
<code class="language-plaintext highlighter-rouge">default.nix</code>. This will actually build the static files. As a bonus I made my
expression to also allow for serving the site locally with dynamic updating
everytime I change a source file. My <code class="language-plaintext highlighter-rouge">default.nix</code> looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>{
    # pkgs refers to all "builtin" nix pkgs and utilities. By importing from a
    # URL I'm able to always pin this default.nix to a specific version of those
    # packages.
    pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/cd63096d6d887d689543a0b97743d28995bc9bc3.tar.gz") {},
    system ? builtins.currentSystem,
}:

    let
        # bundlerEnv looks for a Gemfile, Gemfile.lock, and gemset.nix inside
        # gemdir, and derives a package containing ruby and all desired gems.
        ruby_env = pkgs.bundlerEnv {
            name = "ruby_env";
            ruby = pkgs.ruby;
            gemdir = ./.;
        };
    in
        {
            # build will derive a package which contains the generated static
            # files of the blog. It uses the build.sh file (provided below) to
            # do this.
            build = derivation {
                name = "mediocre-blog";

                # The build.sh file (source provided below) is executed in order
                # to actually build the site.
                builder = "${pkgs.bash}/bin/bash";
                args = [ ./build.sh ];

                # ruby_env is provided as an input to build.sh so that it can
                # use jekyll, and the src directory is provided so it can access
                # the blog's source files. system is required by the derivation
                # function, and stdenv provides standard utilities to build.sh.
                inherit ruby_env system;
                src = ./src;
                stdenv = pkgs.stdenv;
            };

            # serve will derive an environment specifically tailored for being
            # run in a nix-shell. The resulting shell will have ruby_env
            # provided for it, and will automatically run the `jekyll serve`
            # command to serve the blog locally.
            serve = pkgs.stdenv.mkDerivation {
                name = "mediocre-blog-shell";

                # glibcLocales is required so to fill in LC_ALL and other locale
                # related environment vars. Without those jekyll's scss compiler
                # fails.
                #
                # TODO probably get rid of the scss compiler.
                buildInputs = [ ruby_env pkgs.glibcLocales ];

                shellHook = ''
                    exec ${ruby_env}/bin/jekyll serve -s ./src -d ./_site -w -I -D
                '';
            };
        }
</code></pre></div></div>

<p>(Nix is a bit tricky to learn, but I highly recommend chapters 14 and 15 of <a href="https://nixos.org/manual/nix/stable/#chap-writing-nix-expressions">the
nix manual</a> for an overview of the language itself, if nothing else.)</p>

<p>The <code class="language-plaintext highlighter-rouge">build.sh</code> used by the nix expression to actually generate the static files
looks like this:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c"># stdenv was given a dependency to build.sh, and so build.sh can use it to</span>
<span class="c"># source in utilities like mkdir, which it needs.</span>
<span class="nb">source</span> <span class="nv">$stdenv</span>/setup
<span class="nb">set</span> <span class="nt">-e</span>

<span class="c"># Set up the output directory. nix provides the $out variable which will be the</span>
<span class="c"># root of the derived package's filesystem, but for simplicity later we want to</span>
<span class="c"># output the site within /var/www.</span>
<span class="nv">d</span><span class="o">=</span><span class="s2">"</span><span class="nv">$out</span><span class="s2">/var/www/blog.mediocregopher.com"</span>
<span class="nb">mkdir</span> <span class="nt">-p</span> <span class="s2">"</span><span class="nv">$d</span><span class="s2">"</span>

<span class="c"># Perform the jekyll build command. Like stdenv the ruby_env was given as a</span>
<span class="c"># dependency to build.sh, so it has to explicitly use it to have access to</span>
<span class="c"># jekyll. src is another explicit dependency which was given to build.sh, and</span>
<span class="c"># contains all the actual source files within the src directory of the repo.</span>
<span class="nv">$ruby_env</span>/bin/jekyll build <span class="nt">-s</span> <span class="s2">"</span><span class="nv">$src</span><span class="s2">"</span> <span class="nt">-d</span> <span class="s2">"</span><span class="nv">$d</span><span class="s2">"</span>
</code></pre></div></div>

<p>With these pieces in place I can easily regenerate the site like so:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>nix-build -A build
</code></pre></div></div>

<p>Once run the static files will exist within a symlink called <code class="language-plaintext highlighter-rouge">result</code> in the
project’s root. Within the symlink will be a <code class="language-plaintext highlighter-rouge">var/www/blog.mediocregopher.com</code>
tree of directories, and within that will be the generated static files, all
without ever having to have installed ruby.</p>

<p>The expression also allows me to serve the blog while I’m working on it. Doing
so looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>nix-shell -A serve
</code></pre></div></div>

<p>When run I get a normal jekyll process running in my <code class="language-plaintext highlighter-rouge">src</code> directory, serving
the site in real-time on port 4000, once again all without ever installing ruby.</p>

<p>As a final touch I introduced a simple <code class="language-plaintext highlighter-rouge">Makefile</code> to my repo to wrap these
commands, because even these were too much for me to remember:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>result:
	nix-build -A build

install: result
	nix-env -i "$$(readlink result)"

clean:
	rm result
	rm -rf _site

serve:
	nix-shell -A serve

update:
	nix-shell -p bundler --run 'bundler update; bundler lock; bundix; rm -rf .bundle vendor'
</code></pre></div></div>

<p>We’ll look at that <code class="language-plaintext highlighter-rouge">install</code> target in the next section.</p>

<h2 id="nginx">nginx</h2>

<p>So now I have the means to build my site quickly, reliably, and without
cluttering up the rest of my system. Time to actually serve the files.</p>

<p>My home server has a docker network which houses most of my services that I run,
including nginx. nginx’s primary job is to listen on ports 80 and 443, accept
HTTP requests, and direct those requests to their appropriate service based on
their <code class="language-plaintext highlighter-rouge">Host</code> header. nginx is also great at serving static content from disk, so
I’ll take advantage of that for the blog.</p>

<p>The one hitch is that nginx is currently running within a docker container,
as are all my other services. Ideally I would:</p>

<ul>
  <li>Get rid of the nginx docker container.</li>
  <li>Build a nix package containing nginx, all my nginx config files, and the blog
files themselves.</li>
  <li>Run that directly.</li>
</ul>

<p>Unfortunately extracting nginx from docker is dependent on doing so for all
other services as well, or at least on running all services on the host network,
which I’m not prepared to do yet. So for now I’ve done something janky.</p>

<p>If you look at the <code class="language-plaintext highlighter-rouge">Makefile</code> above you’ll notice the <code class="language-plaintext highlighter-rouge">install</code> target. What
that target does is to install the static blog files to my nix profile, which
exists at <code class="language-plaintext highlighter-rouge">$HOME/.nix-profile</code>. nix allows any package to be installed to a
profile in this way. All packages within a profile are independent and can be
added, updated, and removed atomically. By installing the built blog package to
my profile I make it available at
<code class="language-plaintext highlighter-rouge">$HOME/.nix-profile/var/www/blog.mediocregopher.com</code>.</p>

<p>So to serve those files via nginx all I need to do is add a read-only volume to
the container…</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>-v $HOME/.nix-profile/var/www/blog.mediocregopher.com:/var/www/blog.mediocregopher.com:ro \
</code></pre></div></div>

<p>…add a new virtual host to my nginx config…</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>server {
    listen       80;
    server_name  blog.mediocregopher.com;
    root         /var/www/blog.mediocregopher.com;
}
</code></pre></div></div>

<p>…and finally direct the <code class="language-plaintext highlighter-rouge">blog</code> A record for <code class="language-plaintext highlighter-rouge">mediocregopher.com</code> to my home
server’s IP. Cloudflare will handle TLS on port 443 for me in this case, as well
as hide my home IP, which is prudent.</p>

<h2 id="deploying">Deploying</h2>

<p>So now it’s time to publish this new post to the blog, what are the actual
steps? It’s as easy as:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>make clean install
</code></pre></div></div>

<p>This will remove any existing <code class="language-plaintext highlighter-rouge">result</code>, regenerate the site (with the new post)
under a new symlink, and install/update that newer package to my nix profile,
overwriting the previous package which was there.</p>

<p>EDIT: apparently this isn’t quite true. Because <code class="language-plaintext highlighter-rouge">$HOME/.nix-profile</code> is a
symlink docker doesn’t handle the case of that symlink being updated correctly,
so I also have to do <code class="language-plaintext highlighter-rouge">docker restart nginx</code> for changes to be reflected in
nginx.</p>

<p>And that’s it! Nix is a cool tool that I’m still getting the hang of, but
hopefully this post might be useful to anyone else thinking of self-hosting
their site.</p>
