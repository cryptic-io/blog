
+++
title = "Building gomobile Using Nix"
date = 2021-02-13T00:00:00.000Z
template = "html_content/raw.html"
summary = """
When I last left off with the nebula project I wanted to nix-ify the
build process for Cryptic’s mob..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/02/13/building-gomobile-using-nix.html"
raw = """
<p>When I last left off with the nebula project I wanted to <a href="https://nixos.org/manual/nix/stable/">nix</a>-ify the
build process for Cryptic’s <a href="https://github.com/cryptic-io/mobile_nebula">mobile_nebula</a> fork. While I’ve made
progress on the overall build, one particular bit of it really held me up, so
I’m writing about that part here. I’ll finish the full build at a later time.</p>

<h2 id="gomobile">gomobile</h2>

<p><a href="https://github.com/golang/mobile">gomobile</a> is a toolkit for the go programming language to allow for
running go code on Android and iOS devices. <code class="language-plaintext highlighter-rouge">mobile_nebula</code> uses <code class="language-plaintext highlighter-rouge">gomobile</code> to
build a simple wrapper around the nebula client that the mobile app can then
hook into.</p>

<p>This means that in order to nix-ify the entire <code class="language-plaintext highlighter-rouge">mobile_nebula</code> project I first
need to nix-ify <code class="language-plaintext highlighter-rouge">gomobile</code>, and since there isn’t (at time of writing) an
existing package for <code class="language-plaintext highlighter-rouge">gomobile</code> in the nixpkgs repo, I had to roll my own.</p>

<p>I started with a simple <code class="language-plaintext highlighter-rouge">buildGoModule</code> nix expression:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";
}
</code></pre></div></div>

<p>The basic idea here is that <code class="language-plaintext highlighter-rouge">buildGoModule</code> will acquire a specific revision of
the <code class="language-plaintext highlighter-rouge">gomobile</code> source code from github, then attempt to build it. However,
<code class="language-plaintext highlighter-rouge">gomobile</code> is a special beast in that it requires a number of C/C++ libraries in
order to be built. I discovered this upon running this expression, when I
received this error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>./work.h:12:10: fatal error: GLES3/gl3.h: No such file or directory
   12 | #include &lt;GLES3/gl3.h&gt; // install on Ubuntu with: sudo apt-get install libegl1-mesa-dev libgles2-mesa-dev libx11-dev
</code></pre></div></div>

<p>This stumped me for a bit, as I couldn’t figure out a) the “right” place to
source the <code class="language-plaintext highlighter-rouge">GLES3</code> header file from, and b) how to properly hook that into the
<code class="language-plaintext highlighter-rouge">buildGoModule</code> expression. My initial attempts involved trying to include
versions of the header file from my <code class="language-plaintext highlighter-rouge">androidsdk</code> nix package which I had already
gotten (mostly) working, but the version which ships there appears to expect to
be using clang. <code class="language-plaintext highlighter-rouge">cgo</code> (go’s compiler which is used for C/C++ interop) only
supports gcc, so that strategy failed.</p>

<p>I didn’t like having to import the header file from <code class="language-plaintext highlighter-rouge">androidsdk</code> anyway, as it
meant that my <code class="language-plaintext highlighter-rouge">gomobile</code> would only work within the context of the
<code class="language-plaintext highlighter-rouge">mobile_nebula</code> project, rather than being a standalone utility.</p>

<h2 id="nix-index">nix-index</h2>

<p>At this point I flailed around some more trying to figure out where to get this
header file from. Eventually I stumbled on the <a href="https://github.com/bennofs/nix-index">nix-index</a> project,
which implements something similar to the <code class="language-plaintext highlighter-rouge">locate</code> utility on linux: you give it
a file pattern, and it searches your active nix channels for any packages which
provide a file matching that pattern.</p>

<p>Since nix is amazing it’s not actually necessary to install <code class="language-plaintext highlighter-rouge">nix-index</code>, I
simply start up a shell with the package available using <code class="language-plaintext highlighter-rouge">nix-shell -p
nix-index</code>. On first run I needed to populate the index by running the
<code class="language-plaintext highlighter-rouge">nix-index</code> command, which took some time, but after that finding packages which
provide the file I need is as easy as:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; nix-shell -p nix-index
[nix-shell:/tmp]$ nix-locate GLES3/gl3.h
(zulip.out)                                      82,674 r /nix/store/wbfw7w2ixdp317wip77d4ji834v1k1b9-libglvnd-1.3.2-dev/include/GLES3/gl3.h
libglvnd.dev                                     82,674 r /nix/store/pghxzmnmxdcarg5bj3js9csz0h85g08m-libglvnd-1.3.2-dev/include/GLES3/gl3.h
emscripten.out                                   82,666 r /nix/store/x3c4y2h5rn1jawybk48r6glzs1jl029s-emscripten-2.0.1/share/emscripten/system/include/GLES3/gl3.h
</code></pre></div></div>

<p>So my mystery file is provided by a few packages, but <code class="language-plaintext highlighter-rouge">libglvnd.dev</code> stood out
to me as it’s also the pacman package which provides the same file in my real
operating system:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; yay -Qo /usr/include/GLES3/gl3.h
/usr/include/GLES3/gl3.h is owned by libglvnd 1.3.2-1
</code></pre></div></div>

<p>This gave me some confidence that this was the right track.</p>

<h2 id="cgo">cgo</h2>

<p>My next fight was with <code class="language-plaintext highlighter-rouge">cgo</code> itself. Go’s build process provides a few different
entry points for C/C++ compiler/linker flags, including both environment
variables and command-line arguments. But I wasn’t using <code class="language-plaintext highlighter-rouge">go build</code> directly,
instead I was working through nix’s <code class="language-plaintext highlighter-rouge">buildGoModule</code> wrapper. This added a huge
layer of confusion as all of nixpkgs is pretty terribly documented, so you
really have to just divine behavior from the <a href="https://github.com/NixOS/nixpkgs/blob/26117ed4b78020252e49fe75f562378063471f71/pkgs/development/go-modules/generic/default.nix">source</a>
(good luck).</p>

<p>After lots of debugging (hint: <code class="language-plaintext highlighter-rouge">NIX_DEBUG=1</code>) I determined that all which is
actually needed is to set the <code class="language-plaintext highlighter-rouge">CGO_CFLAGS</code> variable within the <code class="language-plaintext highlighter-rouge">buildGoModule</code>
arguments. This would translate to the <code class="language-plaintext highlighter-rouge">CGO_CFLAGS</code> environment variable being
set during all internal commands, and whatever <code class="language-plaintext highlighter-rouge">go build</code> commands get used
would pick up my compiler flags from that.</p>

<p>My new nix expression looked like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";

    CGO_CFLAGS = [
        "-I ${pkgs.libglvnd.dev}/include"
    ];
}
</code></pre></div></div>

<p>Running this produced a new error. Progress! The new error was:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>/nix/store/p792j5f44l3f0xi7ai5jllwnxqwnka88-binutils-2.31.1/bin/ld: cannot find -lGLESv2
collect2: error: ld returned 1 exit status
</code></pre></div></div>

<p>So pretty similar to the previous issue, but this time the linker wasn’t finding
a library file rather than the compiler not finding a header file. Once again I
used <code class="language-plaintext highlighter-rouge">nix-index</code>’s <code class="language-plaintext highlighter-rouge">nix-locate</code> command to find that this library file is
provided by the <code class="language-plaintext highlighter-rouge">libglvnd</code> package (as opposed to <code class="language-plaintext highlighter-rouge">libglvnd.dev</code>, which provided
the header file).</p>

<p>Adding <code class="language-plaintext highlighter-rouge">libglvnd</code> to the <code class="language-plaintext highlighter-rouge">CGO_CFLAGS</code> did not work, as it turns out that flags
for the linker <code class="language-plaintext highlighter-rouge">cgo</code> uses get passed in via <code class="language-plaintext highlighter-rouge">CGO_LDFLAGS</code> (makes sense). After
adding this new variable I got yet another error; this time <code class="language-plaintext highlighter-rouge">X11/Xlib.h</code> was not
able to be found. I repeated the process of <code class="language-plaintext highlighter-rouge">nix-locate</code>/add to <code class="language-plaintext highlighter-rouge">CGO_*FLAGS</code> a
few more times until all dependencies were accounted for. The new nix expression
looked like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";

    CGO_CFLAGS = [
        "-I ${pkgs.libglvnd.dev}/include"
        "-I ${pkgs.xlibs.libX11.dev}/include"
        "-I ${pkgs.xlibs.xorgproto}/include"
        "-I ${pkgs.openal}/include"
    ];

    CGO_LDFLAGS = [
        "-L ${pkgs.libglvnd}/lib"
        "-L ${pkgs.xlibs.libX11}/lib"
        "-L ${pkgs.openal}/lib"
    ];
}
</code></pre></div></div>

<h2 id="tests">Tests</h2>

<p>The <code class="language-plaintext highlighter-rouge">CGO_*FLAGS</code> variables took care of all compiler/linker errors, but there
was one issue left: <code class="language-plaintext highlighter-rouge">buildGoModule</code> apparently runs the project’s tests after
the build phase. <code class="language-plaintext highlighter-rouge">gomobile</code>’s tests were actually mostly passing, but some
failed due to trying to copy files around, which nix was having none of. After
some more <a href="https://github.com/NixOS/nixpkgs/blob/26117ed4b78020252e49fe75f562378063471f71/pkgs/development/go-modules/generic/default.nix">buildGoModule source</a> divination I found that
if I passed an empty <code class="language-plaintext highlighter-rouge">checkPhase</code> argument it would skip the check phase, and
therefore skip running these tests.</p>

<h2 id="fin">Fin!</h2>

<p>The final nix expression looks like so:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";

    CGO_CFLAGS = [
        "-I ${pkgs.libglvnd.dev}/include"
        "-I ${pkgs.xlibs.libX11.dev}/include"
        "-I ${pkgs.xlibs.xorgproto}/include"
        "-I ${pkgs.openal}/include"
    ];

    CGO_LDFLAGS = [
        "-L ${pkgs.libglvnd}/lib"
        "-L ${pkgs.xlibs.libX11}/lib"
        "-L ${pkgs.openal}/lib"
    ];

    checkPhase = "";
}
</code></pre></div></div>

<p>Once I complete the nix-ification of <code class="language-plaintext highlighter-rouge">mobile_nebula</code> I’ll submit a PR to the
nixpkgs upstream with this, so that others can have <code class="language-plaintext highlighter-rouge">gomobile</code> available as
well!</p>"""

+++
<p>When I last left off with the nebula project I wanted to <a href="https://nixos.org/manual/nix/stable/">nix</a>-ify the
build process for Cryptic’s <a href="https://github.com/cryptic-io/mobile_nebula">mobile_nebula</a> fork. While I’ve made
progress on the overall build, one particular bit of it really held me up, so
I’m writing about that part here. I’ll finish the full build at a later time.</p>

<h2 id="gomobile">gomobile</h2>

<p><a href="https://github.com/golang/mobile">gomobile</a> is a toolkit for the go programming language to allow for
running go code on Android and iOS devices. <code class="language-plaintext highlighter-rouge">mobile_nebula</code> uses <code class="language-plaintext highlighter-rouge">gomobile</code> to
build a simple wrapper around the nebula client that the mobile app can then
hook into.</p>

<p>This means that in order to nix-ify the entire <code class="language-plaintext highlighter-rouge">mobile_nebula</code> project I first
need to nix-ify <code class="language-plaintext highlighter-rouge">gomobile</code>, and since there isn’t (at time of writing) an
existing package for <code class="language-plaintext highlighter-rouge">gomobile</code> in the nixpkgs repo, I had to roll my own.</p>

<p>I started with a simple <code class="language-plaintext highlighter-rouge">buildGoModule</code> nix expression:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";
}
</code></pre></div></div>

<p>The basic idea here is that <code class="language-plaintext highlighter-rouge">buildGoModule</code> will acquire a specific revision of
the <code class="language-plaintext highlighter-rouge">gomobile</code> source code from github, then attempt to build it. However,
<code class="language-plaintext highlighter-rouge">gomobile</code> is a special beast in that it requires a number of C/C++ libraries in
order to be built. I discovered this upon running this expression, when I
received this error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>./work.h:12:10: fatal error: GLES3/gl3.h: No such file or directory
   12 | #include &lt;GLES3/gl3.h&gt; // install on Ubuntu with: sudo apt-get install libegl1-mesa-dev libgles2-mesa-dev libx11-dev
</code></pre></div></div>

<p>This stumped me for a bit, as I couldn’t figure out a) the “right” place to
source the <code class="language-plaintext highlighter-rouge">GLES3</code> header file from, and b) how to properly hook that into the
<code class="language-plaintext highlighter-rouge">buildGoModule</code> expression. My initial attempts involved trying to include
versions of the header file from my <code class="language-plaintext highlighter-rouge">androidsdk</code> nix package which I had already
gotten (mostly) working, but the version which ships there appears to expect to
be using clang. <code class="language-plaintext highlighter-rouge">cgo</code> (go’s compiler which is used for C/C++ interop) only
supports gcc, so that strategy failed.</p>

<p>I didn’t like having to import the header file from <code class="language-plaintext highlighter-rouge">androidsdk</code> anyway, as it
meant that my <code class="language-plaintext highlighter-rouge">gomobile</code> would only work within the context of the
<code class="language-plaintext highlighter-rouge">mobile_nebula</code> project, rather than being a standalone utility.</p>

<h2 id="nix-index">nix-index</h2>

<p>At this point I flailed around some more trying to figure out where to get this
header file from. Eventually I stumbled on the <a href="https://github.com/bennofs/nix-index">nix-index</a> project,
which implements something similar to the <code class="language-plaintext highlighter-rouge">locate</code> utility on linux: you give it
a file pattern, and it searches your active nix channels for any packages which
provide a file matching that pattern.</p>

<p>Since nix is amazing it’s not actually necessary to install <code class="language-plaintext highlighter-rouge">nix-index</code>, I
simply start up a shell with the package available using <code class="language-plaintext highlighter-rouge">nix-shell -p
nix-index</code>. On first run I needed to populate the index by running the
<code class="language-plaintext highlighter-rouge">nix-index</code> command, which took some time, but after that finding packages which
provide the file I need is as easy as:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; nix-shell -p nix-index
[nix-shell:/tmp]$ nix-locate GLES3/gl3.h
(zulip.out)                                      82,674 r /nix/store/wbfw7w2ixdp317wip77d4ji834v1k1b9-libglvnd-1.3.2-dev/include/GLES3/gl3.h
libglvnd.dev                                     82,674 r /nix/store/pghxzmnmxdcarg5bj3js9csz0h85g08m-libglvnd-1.3.2-dev/include/GLES3/gl3.h
emscripten.out                                   82,666 r /nix/store/x3c4y2h5rn1jawybk48r6glzs1jl029s-emscripten-2.0.1/share/emscripten/system/include/GLES3/gl3.h
</code></pre></div></div>

<p>So my mystery file is provided by a few packages, but <code class="language-plaintext highlighter-rouge">libglvnd.dev</code> stood out
to me as it’s also the pacman package which provides the same file in my real
operating system:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; yay -Qo /usr/include/GLES3/gl3.h
/usr/include/GLES3/gl3.h is owned by libglvnd 1.3.2-1
</code></pre></div></div>

<p>This gave me some confidence that this was the right track.</p>

<h2 id="cgo">cgo</h2>

<p>My next fight was with <code class="language-plaintext highlighter-rouge">cgo</code> itself. Go’s build process provides a few different
entry points for C/C++ compiler/linker flags, including both environment
variables and command-line arguments. But I wasn’t using <code class="language-plaintext highlighter-rouge">go build</code> directly,
instead I was working through nix’s <code class="language-plaintext highlighter-rouge">buildGoModule</code> wrapper. This added a huge
layer of confusion as all of nixpkgs is pretty terribly documented, so you
really have to just divine behavior from the <a href="https://github.com/NixOS/nixpkgs/blob/26117ed4b78020252e49fe75f562378063471f71/pkgs/development/go-modules/generic/default.nix">source</a>
(good luck).</p>

<p>After lots of debugging (hint: <code class="language-plaintext highlighter-rouge">NIX_DEBUG=1</code>) I determined that all which is
actually needed is to set the <code class="language-plaintext highlighter-rouge">CGO_CFLAGS</code> variable within the <code class="language-plaintext highlighter-rouge">buildGoModule</code>
arguments. This would translate to the <code class="language-plaintext highlighter-rouge">CGO_CFLAGS</code> environment variable being
set during all internal commands, and whatever <code class="language-plaintext highlighter-rouge">go build</code> commands get used
would pick up my compiler flags from that.</p>

<p>My new nix expression looked like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";

    CGO_CFLAGS = [
        "-I ${pkgs.libglvnd.dev}/include"
    ];
}
</code></pre></div></div>

<p>Running this produced a new error. Progress! The new error was:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>/nix/store/p792j5f44l3f0xi7ai5jllwnxqwnka88-binutils-2.31.1/bin/ld: cannot find -lGLESv2
collect2: error: ld returned 1 exit status
</code></pre></div></div>

<p>So pretty similar to the previous issue, but this time the linker wasn’t finding
a library file rather than the compiler not finding a header file. Once again I
used <code class="language-plaintext highlighter-rouge">nix-index</code>’s <code class="language-plaintext highlighter-rouge">nix-locate</code> command to find that this library file is
provided by the <code class="language-plaintext highlighter-rouge">libglvnd</code> package (as opposed to <code class="language-plaintext highlighter-rouge">libglvnd.dev</code>, which provided
the header file).</p>

<p>Adding <code class="language-plaintext highlighter-rouge">libglvnd</code> to the <code class="language-plaintext highlighter-rouge">CGO_CFLAGS</code> did not work, as it turns out that flags
for the linker <code class="language-plaintext highlighter-rouge">cgo</code> uses get passed in via <code class="language-plaintext highlighter-rouge">CGO_LDFLAGS</code> (makes sense). After
adding this new variable I got yet another error; this time <code class="language-plaintext highlighter-rouge">X11/Xlib.h</code> was not
able to be found. I repeated the process of <code class="language-plaintext highlighter-rouge">nix-locate</code>/add to <code class="language-plaintext highlighter-rouge">CGO_*FLAGS</code> a
few more times until all dependencies were accounted for. The new nix expression
looked like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";

    CGO_CFLAGS = [
        "-I ${pkgs.libglvnd.dev}/include"
        "-I ${pkgs.xlibs.libX11.dev}/include"
        "-I ${pkgs.xlibs.xorgproto}/include"
        "-I ${pkgs.openal}/include"
    ];

    CGO_LDFLAGS = [
        "-L ${pkgs.libglvnd}/lib"
        "-L ${pkgs.xlibs.libX11}/lib"
        "-L ${pkgs.openal}/lib"
    ];
}
</code></pre></div></div>

<h2 id="tests">Tests</h2>

<p>The <code class="language-plaintext highlighter-rouge">CGO_*FLAGS</code> variables took care of all compiler/linker errors, but there
was one issue left: <code class="language-plaintext highlighter-rouge">buildGoModule</code> apparently runs the project’s tests after
the build phase. <code class="language-plaintext highlighter-rouge">gomobile</code>’s tests were actually mostly passing, but some
failed due to trying to copy files around, which nix was having none of. After
some more <a href="https://github.com/NixOS/nixpkgs/blob/26117ed4b78020252e49fe75f562378063471f71/pkgs/development/go-modules/generic/default.nix">buildGoModule source</a> divination I found that
if I passed an empty <code class="language-plaintext highlighter-rouge">checkPhase</code> argument it would skip the check phase, and
therefore skip running these tests.</p>

<h2 id="fin">Fin!</h2>

<p>The final nix expression looks like so:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.buildGoModule {
    pname = "gomobile";
    version = "unstable-2020-12-17";
    src = pkgs.fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "e6ae53a27f4fd7cfa2943f2ae47b96cba8eb01c9";
        sha256 = "03dzis3xkj0abcm4k95w2zd4l9ygn0rhkj56bzxbcpwa7idqhd62";
    };
    vendorSha256 = "1n1338vqkc1n8cy94501n7jn3qbr28q9d9zxnq2b4rxsqjfc9l94";

    CGO_CFLAGS = [
        "-I ${pkgs.libglvnd.dev}/include"
        "-I ${pkgs.xlibs.libX11.dev}/include"
        "-I ${pkgs.xlibs.xorgproto}/include"
        "-I ${pkgs.openal}/include"
    ];

    CGO_LDFLAGS = [
        "-L ${pkgs.libglvnd}/lib"
        "-L ${pkgs.xlibs.libX11}/lib"
        "-L ${pkgs.openal}/lib"
    ];

    checkPhase = "";
}
</code></pre></div></div>

<p>Once I complete the nix-ification of <code class="language-plaintext highlighter-rouge">mobile_nebula</code> I’ll submit a PR to the
nixpkgs upstream with this, so that others can have <code class="language-plaintext highlighter-rouge">gomobile</code> available as
well!</p>
