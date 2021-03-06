
+++
title = "Declarative Dev Environments"
date = 2021-05-10T00:00:00.000Z
template = "html_content/raw.html"
summary = """
I don't install development tools globally. I don't have node added to my
PATH in my ~/.zshrc file, ..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/declarative-dev-environments/"
raw = """
<p>I don't install development tools globally. I don't have <code>node</code> added to my
<code>PATH</code> in my <code>~/.zshrc</code> file, and running <code>cargo</code> outside a project folder
returns &quot;command not found.&quot; I wipe my computer on every reboot. With the
exception of four folders (<code>/boot</code>, <code>/nix</code>, <code>/home</code>, and <code>/persist</code>), everything
gets <a href="https://grahamc.com/blog/erase-your-darlings">deleted</a>. And it has worked
out great.</p>
<p>Instead of installing development packages globally, I declare them as a
dependency in my project's dev environment. They become available as soon as I
<code>cd</code> into the project folder. If two projects use the same tool then I only keep
one version of that tool on my computer.</p>
<p>I think installing dev tools globally is a bad pattern that leads to nothing but
heartache and woe. If you are running <code>sudo apt-get install</code> or <code>brew install</code>
prior to building a project, you are doing it wrong. By defining your dev tool
dependencies explicitly you allow your projects to easily build on any
machine at any point in time. Whether it's on a friends machine today, or a new
laptop in 10 years. It even makes CI integration a breeze.</p>
<h2 id="what-do-i-mean-by-a-declarative-dev-environment">What do I mean by a declarative dev environment?</h2>
<p>I mean a project that has a special file (or files) that define all the
dependencies required to build and run your project. It doesn't necessarily have
to include the actual binaries you will run in the repo, but it should be
reproducible. If you clone my project you should be running the exact
same tools as me.</p>
<p>Just like you have explicit dependencies on libraries you use in your program, a
declarative dev environment lets you define your tooling dependencies (e.g.
which version of Node, Yarn, or your specific cross compiler toolchain).</p>
<h2 id="how-i-setup-my-declarative-dev-environments">How I setup my declarative dev environments</h2>
<p>To accomplish this I use <a href="https://nixos.org">Nix</a> with <a href="https://www.tweag.io/blog/2020-05-25-flakes/">Nix Flakes</a> and <a href="https://direnv.net/">direnv</a>. There are three
relevant files: <code>flake.nix</code> which defines the build of the project and the tools
I need for development; <code>flake.lock</code> which is similar in spirit to a <code>yarn.lock</code>
or <code>Cargo.lock</code> file, it <em>locks</em> the exact version of any tool used and
generated automatically the first time you introduce dependencies; and finally a
<code>.envrc</code> file which simply tells direnv to ask Nix what the environment should
be, and sets up the environment when you <code>cd</code> into the folder. Here are some
simple examples:
<a href="https://github.com/MarcoPolo/templates/tree/master/trivial">flake.nix</a>,
<a href="https://github.com/MarcoPolo/templates/blob/master/trivial/.envrc">.envrc</a>
(<code>flake.lock</code> omitted since it's automatically generated).</p>
<p>As a shortcut for setting up a <code>flake.nix</code> and <code>.envrc</code>, you can use a template
to provide the boilerplate. When I start a new project I'll run <code>nix flake init -t github:marcopolo/templates</code> which copies the files from this
<a href="https://github.com/MarcoPolo/templates/tree/master/trivial">repo</a> and puts them
in your current working directory. Then running <code>direnv allow</code> will setup your
local environment, installing any missing dependencies through Nix as a side
effect.</p>
<p>This blog itself makes use of <a href="https://github.com/MarcoPolo/marcopolo.github.io/blob/master/flake.nix#L14">declarative dev
environments</a>.
Zola is the static site generator I use. When I <code>cd</code> into my blog my environment
is automatically setup with Zola available for previewing the blog.</p>
<h2 id="how-nix-works-roughly">How Nix works, roughly</h2>
<p>This all works off <a href="https://nixos.org">Nix</a>. Nix is a fantastic package manager and build tool that
provides reproducible versions of packages that don't rely on a specific global
system configuration. Specifically packages installed through Nix don't rely an
a user's <code>/usr/lib</code> or anything outside of <code>/nix/store</code>. You don't even need
glibc installed (as may be the case if you are on <a href="https://www.alpinelinux.org/">Alpine
Linux</a>).</p>
<p>For a deeper dive see <a href="https://nixos.org/guides/how-nix-works.html">How Nix Works</a>.</p>
<h2 id="an-example-how-to-setup-a-yarn-based-js-project">An example, how to setup a Yarn based JS project.</h2>
<p>To be concrete, let me show an example. If I wanted to start a JS project and
use <a href="https://yarnpkg.com/">Yarn</a> as my dependency manager, I would do something
like this: </p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># 1. Create the project folder
</span><span style="color:#bf616a;">mkdir</span><span style="color:#c0c5ce;"> my-project

</span><span style="color:#65737e;"># 2. Add the boilerplate files.
</span><span style="color:#c0c5ce;">nix flake init</span><span style="color:#bf616a;"> -t</span><span style="color:#c0c5ce;"> github:marcopolo/templates

</span><span style="color:#65737e;"># 3. Edit flake.nix file to add yarn and NodeJS.
# With your text editor apply this diff:
# -          buildInputs = [ pkgs.hello ];
# +          buildInputs = [ pkgs.yarn pkgs.nodejs-12_x ];

# 4. Allow direnv to run this environment. This will also fetch yarn with Nix
#    and add it to your path.
</span><span style="color:#c0c5ce;">direnv allow

</span><span style="color:#65737e;"># 5. Yarn is now available, proceed as normal. 
</span><span style="color:#c0c5ce;">yarn init
</span></code></pre>
<p>You can simplify this further by making a Nix Flake template that already has
Yarn and NodeJS included. </p>
<h2 id="another-example-setting-up-a-rust-project">Another example. Setting up a Rust project.</h2>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># 1. Create the project folder
</span><span style="color:#bf616a;">mkdir</span><span style="color:#c0c5ce;"> rust-project

</span><span style="color:#65737e;"># 2. Add the boilerplate files.
</span><span style="color:#c0c5ce;">nix flake init</span><span style="color:#bf616a;"> -t</span><span style="color:#c0c5ce;"> github:marcopolo/templates#rust

</span><span style="color:#65737e;"># 3. Cargo and rust is now available, proceed as normal. 
</span><span style="color:#c0c5ce;">cargo init
</span><span style="color:#bf616a;">cargo</span><span style="color:#c0c5ce;"> run
</span></code></pre>
<p>Here we used a Rust specific template, so no post template init changes were required.</p>
<h2 id="dissecting-the-flake-nix-file">Dissecting the <code>flake.nix</code> file</h2>
<p>Let's break down the <code>flake.nix</code> file so we can understand what it is we are
declaring.</p>
<p>First off, the file is written in <a href="https://nixos.wiki/wiki/Nix_Expression_Language">Nix, the programming
language</a>. At a high level you
can read this as JSON but with functions. Like JSON it can only represent
expressions (you can only have one top level JSON object), unlike JSON you can
have functions and variables. </p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># This is our top level set expression. Equivalent to the top level JSON object.
</span><span style="color:#c0c5ce;">{
  </span><span style="color:#65737e;"># These are comments

  # Here we are defining a set. This is equivalent to a JSON object.
  # The key is description, and the value is the string.
  </span><span style="color:#d08770;">description </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">A very basic flake</span><span style="color:#c0c5ce;">&quot;;

  </span><span style="color:#65737e;"># You can define nested sets by using a `.` between key parts.
  # This is equivalent to the JSON object {inputs: {flake-utils: {url: &quot;github:...&quot;}}}
  </span><span style="color:#d08770;">inputs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">flake-utils</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">url </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">github:numtide/flake-utils</span><span style="color:#c0c5ce;">&quot;;

  </span><span style="color:#65737e;"># Functions are defined with the syntax of `param: functionBodyExpression`.
  # The param can be destructured if it expects a set, like what we are doing here. 
  # This defines the output of this flake. Our dev environment will make use of
  # the devShell attribute, but you can also define the release build of your
  # package here.
  </span><span style="color:#d08770;">outputs </span><span style="color:#c0c5ce;">= </span><span style="color:#8fa1b3;">{ </span><span style="color:#c0c5ce;">self, nixpkgs, flake-utils </span><span style="color:#8fa1b3;">}</span><span style="color:#c0c5ce;">:
    </span><span style="color:#65737e;"># This is a helper to generate these outputs for each system (x86-linux,
    # arm-linux, macOS, ...)
    </span><span style="color:#bf616a;">flake-utils</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">lib</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">eachDefaultSystem </span><span style="color:#c0c5ce;">(system:
      </span><span style="color:#b48ead;">let
        </span><span style="color:#65737e;"># The nixpkgs repo has to know which system we are using.
        </span><span style="color:#d08770;">pkgs </span><span style="color:#c0c5ce;">= </span><span style="color:#96b5b4;">import </span><span style="color:#bf616a;">nixpkgs </span><span style="color:#c0c5ce;">{ </span><span style="color:#d08770;">system </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">system</span><span style="color:#c0c5ce;">; };
      </span><span style="color:#b48ead;">in
      </span><span style="color:#c0c5ce;">{
        </span><span style="color:#65737e;"># This is the environment that direnv will use. You can also enter the
        # shell with `nix shell`. The packages in `buildInputs` are what become
        # available to you in your $PATH. As an example this only has the hello
        # package.
        </span><span style="color:#d08770;">devShell </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">mkShell </span><span style="color:#c0c5ce;">{
          </span><span style="color:#d08770;">buildInputs </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">hello </span><span style="color:#c0c5ce;">];
        };

        </span><span style="color:#65737e;"># You can also define a package that is built by default when you run
        # `nix build`.  The build command creates a new folder, `result`, that
        # is a symlink to the build output.
        </span><span style="color:#d08770;">defaultPackage </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">hello</span><span style="color:#c0c5ce;">;
      });
}

</span></code></pre><h2 id="on-dev-tools-and-a-dev-setup">On Dev Tools and A Dev Setup</h2>
<p>There is a subtle distinction on what constitutes a Dev Tool vs A Dev Setup. I
classify Dev Tools as things that need to be available to build or develop a given
project specifically. Think of <code>gcc</code>, <code>yarn</code>, or <code>cargo</code>. The Dev Setup category
are for things that are useful when developing in general. Vim, Emacs,
<a href="https://geoff.greer.fm/ag/">ag</a> are some examples.</p>
<p>Dev tools are worth defining explicitly in your project's declarative dev environment (in
a <code>flake.nix</code> file). A Dev Setup is highly personal and not worth defining in the
project's declarative dev environment. But that's not to say your dev setup in not
worth defining at all. In fact, if you are (or when you become) familiar with
Nix, you can extend the same ideas of this post to your user account with <a href="https://github.com/nix-community/home-manager">Home
Manager</a>. </p>
<p>With Home Manager You can declaratively define which programs you want available
in your dev setup, what Vim plugins you want installed, what ZSH plugins you
want available and much more. It's the core idea of declarative dev environments
taken to the user account level.</p>
<h2 id="why-not-docker">Why not Docker?</h2>
<p>Many folks use Docker to get something like this, but while it gets close – and
in some cases functionally equivalent – it has some shortcomings:</p>
<p>For one, a Dockerfile is not reproducible out of the box. It is common to use
<code>apt-get install</code> in a Dockerfile to add packages. This part isn't reproducible
and brings you back to the initial problem I outlined. </p>
<p>Docker is less effecient with storage. It uses layers as the base block of
Docker images rather than packages. This means that it's relatively easy to end
up with many similar docker images (for a more thorough analysis check
out <a href="https://grahamc.com/blog/nix-and-layered-docker-images">Optimising Docker Layers for Better Caching with
Nix</a>).</p>
<p>Spinning up a container and doing development inside may not leverage your
existing dev setup. For example you may have Vim setup neatly on your machine,
but resort to <code>vi</code> when developing inside a container.  Or worse, you'll 
rebuild your dev setup inside the container, which does nothing more than
add dead weight to the container since it's an addition solely for you and not
really part of the project. Of course there are some workarounds to this issue,
you can bind mount a folder and VS Code supports opening a project inside a
container.  <a href="https://github.com/zmkfirmware/zmk">ZMK</a> does this and it has
worked great.</p>
<p>If you are on MacOS, developing inside a container is actually slower. Docker
on Mac relies on running a linux VM in the background and running containers in
that VM. By default that VM is underpowered relative to the host MacOS machine.</p>
<p>There are cases where you actually do only want to run the code in an
x86-linux environment and Docker provides a convenient proxy for this. In these
cases I'd suggest using Nix to generate the Docker images. This way you get the
declarative and reproducible properties from Nix and the convenience from Docker.</p>
<p>As a caveat to all of the above, if you already have a reproducible dev environment
with a Docker container that works for you, please don't throw that all out and
redesign your system from scratch. Keep using it until it stops meeting your
needs and come back to this when it happens. Until then, keep building.</p>
<h2 id="on-nix-flakes">On Nix Flakes</h2>
<p>Nix Flakes is still new and in beta, so it's likely that if you install Nix from
their <a href="https://nixos.org/download.html">download page</a> you won't have Nix Flakes
available. If you don't already have Nix installed, you can install a version
with Nix Flakes <a href="https://github.com/numtide/nix-unstable-installer">with the unstable installer</a>,
otherwise read the section on <a href="https://nixos.wiki/wiki/Flakes#Installing_flakes">installing flakes</a>.</p>
<h2 id="closing-thoughts">Closing thoughts</h2>
<p>In modern programming languages we define all our dependencies explicitly and
lock the specific versions used. It's about time we do that for all our tools
too. Let's get rid of the <code>apt-get install</code> and <code>brew install</code> section of READMEs.</p>
"""

+++
<p>I don't install development tools globally. I don't have <code>node</code> added to my
<code>PATH</code> in my <code>~/.zshrc</code> file, and running <code>cargo</code> outside a project folder
returns &quot;command not found.&quot; I wipe my computer on every reboot. With the
exception of four folders (<code>/boot</code>, <code>/nix</code>, <code>/home</code>, and <code>/persist</code>), everything
gets <a href="https://grahamc.com/blog/erase-your-darlings">deleted</a>. And it has worked
out great.</p>
<p>Instead of installing development packages globally, I declare them as a
dependency in my project's dev environment. They become available as soon as I
<code>cd</code> into the project folder. If two projects use the same tool then I only keep
one version of that tool on my computer.</p>
<p>I think installing dev tools globally is a bad pattern that leads to nothing but
heartache and woe. If you are running <code>sudo apt-get install</code> or <code>brew install</code>
prior to building a project, you are doing it wrong. By defining your dev tool
dependencies explicitly you allow your projects to easily build on any
machine at any point in time. Whether it's on a friends machine today, or a new
laptop in 10 years. It even makes CI integration a breeze.</p>
<h2 id="what-do-i-mean-by-a-declarative-dev-environment">What do I mean by a declarative dev environment?</h2>
<p>I mean a project that has a special file (or files) that define all the
dependencies required to build and run your project. It doesn't necessarily have
to include the actual binaries you will run in the repo, but it should be
reproducible. If you clone my project you should be running the exact
same tools as me.</p>
<p>Just like you have explicit dependencies on libraries you use in your program, a
declarative dev environment lets you define your tooling dependencies (e.g.
which version of Node, Yarn, or your specific cross compiler toolchain).</p>
<h2 id="how-i-setup-my-declarative-dev-environments">How I setup my declarative dev environments</h2>
<p>To accomplish this I use <a href="https://nixos.org">Nix</a> with <a href="https://www.tweag.io/blog/2020-05-25-flakes/">Nix Flakes</a> and <a href="https://direnv.net/">direnv</a>. There are three
relevant files: <code>flake.nix</code> which defines the build of the project and the tools
I need for development; <code>flake.lock</code> which is similar in spirit to a <code>yarn.lock</code>
or <code>Cargo.lock</code> file, it <em>locks</em> the exact version of any tool used and
generated automatically the first time you introduce dependencies; and finally a
<code>.envrc</code> file which simply tells direnv to ask Nix what the environment should
be, and sets up the environment when you <code>cd</code> into the folder. Here are some
simple examples:
<a href="https://github.com/MarcoPolo/templates/tree/master/trivial">flake.nix</a>,
<a href="https://github.com/MarcoPolo/templates/blob/master/trivial/.envrc">.envrc</a>
(<code>flake.lock</code> omitted since it's automatically generated).</p>
<p>As a shortcut for setting up a <code>flake.nix</code> and <code>.envrc</code>, you can use a template
to provide the boilerplate. When I start a new project I'll run <code>nix flake init -t github:marcopolo/templates</code> which copies the files from this
<a href="https://github.com/MarcoPolo/templates/tree/master/trivial">repo</a> and puts them
in your current working directory. Then running <code>direnv allow</code> will setup your
local environment, installing any missing dependencies through Nix as a side
effect.</p>
<p>This blog itself makes use of <a href="https://github.com/MarcoPolo/marcopolo.github.io/blob/master/flake.nix#L14">declarative dev
environments</a>.
Zola is the static site generator I use. When I <code>cd</code> into my blog my environment
is automatically setup with Zola available for previewing the blog.</p>
<h2 id="how-nix-works-roughly">How Nix works, roughly</h2>
<p>This all works off <a href="https://nixos.org">Nix</a>. Nix is a fantastic package manager and build tool that
provides reproducible versions of packages that don't rely on a specific global
system configuration. Specifically packages installed through Nix don't rely an
a user's <code>/usr/lib</code> or anything outside of <code>/nix/store</code>. You don't even need
glibc installed (as may be the case if you are on <a href="https://www.alpinelinux.org/">Alpine
Linux</a>).</p>
<p>For a deeper dive see <a href="https://nixos.org/guides/how-nix-works.html">How Nix Works</a>.</p>
<h2 id="an-example-how-to-setup-a-yarn-based-js-project">An example, how to setup a Yarn based JS project.</h2>
<p>To be concrete, let me show an example. If I wanted to start a JS project and
use <a href="https://yarnpkg.com/">Yarn</a> as my dependency manager, I would do something
like this: </p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># 1. Create the project folder
</span><span style="color:#bf616a;">mkdir</span><span style="color:#c0c5ce;"> my-project

</span><span style="color:#65737e;"># 2. Add the boilerplate files.
</span><span style="color:#c0c5ce;">nix flake init</span><span style="color:#bf616a;"> -t</span><span style="color:#c0c5ce;"> github:marcopolo/templates

</span><span style="color:#65737e;"># 3. Edit flake.nix file to add yarn and NodeJS.
# With your text editor apply this diff:
# -          buildInputs = [ pkgs.hello ];
# +          buildInputs = [ pkgs.yarn pkgs.nodejs-12_x ];

# 4. Allow direnv to run this environment. This will also fetch yarn with Nix
#    and add it to your path.
</span><span style="color:#c0c5ce;">direnv allow

</span><span style="color:#65737e;"># 5. Yarn is now available, proceed as normal. 
</span><span style="color:#c0c5ce;">yarn init
</span></code></pre>
<p>You can simplify this further by making a Nix Flake template that already has
Yarn and NodeJS included. </p>
<h2 id="another-example-setting-up-a-rust-project">Another example. Setting up a Rust project.</h2>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># 1. Create the project folder
</span><span style="color:#bf616a;">mkdir</span><span style="color:#c0c5ce;"> rust-project

</span><span style="color:#65737e;"># 2. Add the boilerplate files.
</span><span style="color:#c0c5ce;">nix flake init</span><span style="color:#bf616a;"> -t</span><span style="color:#c0c5ce;"> github:marcopolo/templates#rust

</span><span style="color:#65737e;"># 3. Cargo and rust is now available, proceed as normal. 
</span><span style="color:#c0c5ce;">cargo init
</span><span style="color:#bf616a;">cargo</span><span style="color:#c0c5ce;"> run
</span></code></pre>
<p>Here we used a Rust specific template, so no post template init changes were required.</p>
<h2 id="dissecting-the-flake-nix-file">Dissecting the <code>flake.nix</code> file</h2>
<p>Let's break down the <code>flake.nix</code> file so we can understand what it is we are
declaring.</p>
<p>First off, the file is written in <a href="https://nixos.wiki/wiki/Nix_Expression_Language">Nix, the programming
language</a>. At a high level you
can read this as JSON but with functions. Like JSON it can only represent
expressions (you can only have one top level JSON object), unlike JSON you can
have functions and variables. </p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># This is our top level set expression. Equivalent to the top level JSON object.
</span><span style="color:#c0c5ce;">{
  </span><span style="color:#65737e;"># These are comments

  # Here we are defining a set. This is equivalent to a JSON object.
  # The key is description, and the value is the string.
  </span><span style="color:#d08770;">description </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">A very basic flake</span><span style="color:#c0c5ce;">&quot;;

  </span><span style="color:#65737e;"># You can define nested sets by using a `.` between key parts.
  # This is equivalent to the JSON object {inputs: {flake-utils: {url: &quot;github:...&quot;}}}
  </span><span style="color:#d08770;">inputs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">flake-utils</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">url </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">github:numtide/flake-utils</span><span style="color:#c0c5ce;">&quot;;

  </span><span style="color:#65737e;"># Functions are defined with the syntax of `param: functionBodyExpression`.
  # The param can be destructured if it expects a set, like what we are doing here. 
  # This defines the output of this flake. Our dev environment will make use of
  # the devShell attribute, but you can also define the release build of your
  # package here.
  </span><span style="color:#d08770;">outputs </span><span style="color:#c0c5ce;">= </span><span style="color:#8fa1b3;">{ </span><span style="color:#c0c5ce;">self, nixpkgs, flake-utils </span><span style="color:#8fa1b3;">}</span><span style="color:#c0c5ce;">:
    </span><span style="color:#65737e;"># This is a helper to generate these outputs for each system (x86-linux,
    # arm-linux, macOS, ...)
    </span><span style="color:#bf616a;">flake-utils</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">lib</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">eachDefaultSystem </span><span style="color:#c0c5ce;">(system:
      </span><span style="color:#b48ead;">let
        </span><span style="color:#65737e;"># The nixpkgs repo has to know which system we are using.
        </span><span style="color:#d08770;">pkgs </span><span style="color:#c0c5ce;">= </span><span style="color:#96b5b4;">import </span><span style="color:#bf616a;">nixpkgs </span><span style="color:#c0c5ce;">{ </span><span style="color:#d08770;">system </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">system</span><span style="color:#c0c5ce;">; };
      </span><span style="color:#b48ead;">in
      </span><span style="color:#c0c5ce;">{
        </span><span style="color:#65737e;"># This is the environment that direnv will use. You can also enter the
        # shell with `nix shell`. The packages in `buildInputs` are what become
        # available to you in your $PATH. As an example this only has the hello
        # package.
        </span><span style="color:#d08770;">devShell </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">mkShell </span><span style="color:#c0c5ce;">{
          </span><span style="color:#d08770;">buildInputs </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">hello </span><span style="color:#c0c5ce;">];
        };

        </span><span style="color:#65737e;"># You can also define a package that is built by default when you run
        # `nix build`.  The build command creates a new folder, `result`, that
        # is a symlink to the build output.
        </span><span style="color:#d08770;">defaultPackage </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">hello</span><span style="color:#c0c5ce;">;
      });
}

</span></code></pre><h2 id="on-dev-tools-and-a-dev-setup">On Dev Tools and A Dev Setup</h2>
<p>There is a subtle distinction on what constitutes a Dev Tool vs A Dev Setup. I
classify Dev Tools as things that need to be available to build or develop a given
project specifically. Think of <code>gcc</code>, <code>yarn</code>, or <code>cargo</code>. The Dev Setup category
are for things that are useful when developing in general. Vim, Emacs,
<a href="https://geoff.greer.fm/ag/">ag</a> are some examples.</p>
<p>Dev tools are worth defining explicitly in your project's declarative dev environment (in
a <code>flake.nix</code> file). A Dev Setup is highly personal and not worth defining in the
project's declarative dev environment. But that's not to say your dev setup in not
worth defining at all. In fact, if you are (or when you become) familiar with
Nix, you can extend the same ideas of this post to your user account with <a href="https://github.com/nix-community/home-manager">Home
Manager</a>. </p>
<p>With Home Manager You can declaratively define which programs you want available
in your dev setup, what Vim plugins you want installed, what ZSH plugins you
want available and much more. It's the core idea of declarative dev environments
taken to the user account level.</p>
<h2 id="why-not-docker">Why not Docker?</h2>
<p>Many folks use Docker to get something like this, but while it gets close – and
in some cases functionally equivalent – it has some shortcomings:</p>
<p>For one, a Dockerfile is not reproducible out of the box. It is common to use
<code>apt-get install</code> in a Dockerfile to add packages. This part isn't reproducible
and brings you back to the initial problem I outlined. </p>
<p>Docker is less effecient with storage. It uses layers as the base block of
Docker images rather than packages. This means that it's relatively easy to end
up with many similar docker images (for a more thorough analysis check
out <a href="https://grahamc.com/blog/nix-and-layered-docker-images">Optimising Docker Layers for Better Caching with
Nix</a>).</p>
<p>Spinning up a container and doing development inside may not leverage your
existing dev setup. For example you may have Vim setup neatly on your machine,
but resort to <code>vi</code> when developing inside a container.  Or worse, you'll 
rebuild your dev setup inside the container, which does nothing more than
add dead weight to the container since it's an addition solely for you and not
really part of the project. Of course there are some workarounds to this issue,
you can bind mount a folder and VS Code supports opening a project inside a
container.  <a href="https://github.com/zmkfirmware/zmk">ZMK</a> does this and it has
worked great.</p>
<p>If you are on MacOS, developing inside a container is actually slower. Docker
on Mac relies on running a linux VM in the background and running containers in
that VM. By default that VM is underpowered relative to the host MacOS machine.</p>
<p>There are cases where you actually do only want to run the code in an
x86-linux environment and Docker provides a convenient proxy for this. In these
cases I'd suggest using Nix to generate the Docker images. This way you get the
declarative and reproducible properties from Nix and the convenience from Docker.</p>
<p>As a caveat to all of the above, if you already have a reproducible dev environment
with a Docker container that works for you, please don't throw that all out and
redesign your system from scratch. Keep using it until it stops meeting your
needs and come back to this when it happens. Until then, keep building.</p>
<h2 id="on-nix-flakes">On Nix Flakes</h2>
<p>Nix Flakes is still new and in beta, so it's likely that if you install Nix from
their <a href="https://nixos.org/download.html">download page</a> you won't have Nix Flakes
available. If you don't already have Nix installed, you can install a version
with Nix Flakes <a href="https://github.com/numtide/nix-unstable-installer">with the unstable installer</a>,
otherwise read the section on <a href="https://nixos.wiki/wiki/Flakes#Installing_flakes">installing flakes</a>.</p>
<h2 id="closing-thoughts">Closing thoughts</h2>
<p>In modern programming languages we define all our dependencies explicitly and
lock the specific versions used. It's about time we do that for all our tools
too. Let's get rid of the <code>apt-get install</code> and <code>brew install</code> section of READMEs.</p>

