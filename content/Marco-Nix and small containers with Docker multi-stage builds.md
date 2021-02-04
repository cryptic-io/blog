
+++
title = "Nix and small containers with Docker multi-stage builds"
date = 2020-05-15T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Multi Stage builds are great for minimizing the size of your container. The
general idea is you have..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/nix-and-small-containers/"
raw = """
<p>Multi Stage builds are great for minimizing the size of your container. The
general idea is you have a stage as your builder and another stage as your
product. This allows you to have a full development and build container while
still having a lean production container. The production container only carries
its runtime dependencies.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> golang:1.7.3
</span><span style="color:#b48ead;">WORKDIR </span><span style="color:#c0c5ce;">/go/src/github.com/alexellis/href-counter/
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">go get -d -v golang.org/x/net/html
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> app.go .
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

</span><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> alpine:latest
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">apk --no-cache add ca-certificates
</span><span style="color:#b48ead;">WORKDIR </span><span style="color:#c0c5ce;">/root/
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> --from=</span><span style="color:#bf616a;">0</span><span style="color:#c0c5ce;"> /go/src/github.com/alexellis/href-counter/app .
CMD [&quot;</span><span style="color:#a3be8c;">./app</span><span style="color:#c0c5ce;">&quot;]
</span></code></pre>
<p>(from Docker's <a href="https://docs.docker.com/develop/develop-images/multistage-build/">docs on multi-stage</a>)</p>
<p>Sounds great, right? What's the catch? Well, it's not always easy to know what the
runtime dependencies are. For example you may have installed something in /lib
that was needed in the build process. But it turned out to be a shared library
and now it needs to be included in the production container. Tricky! Is there
some automated way to know all your runtime dependencies?</p>
<h2 id="enter-nix">Enter Nix</h2>
<p><a href="https://nixos.org/">Nix</a> is a functional and immutable package manager. It works great for
reproducible builds. It keeps track of packages and their dependencies via their
content hashes. And, relevant for this exercise, it also keeps track of the
dependencies of a built package. That means we can use Nix to build our project
and then ask Nix what our runtime dependencies are. With that information we can
copy just those files to the product stage of our multi-stage build and end up
with the smallest possible docker container.</p>
<p>Our general strategy will be to use a Nix builder to build our code. Ask the Nix
builder to tell us all the runtime dependencies of our built executable. Then
copy the executable with all it's runtime dependencies to a fresh container. Our
expectation is that this will result in a minimal production container.</p>
<h2 id="example">Example</h2>
<p>As a simple example let's package a &quot;Hello World&quot; program in Rust. The code is
what you'd expect:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">pub fn </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">() {
    println!(&quot;</span><span style="color:#a3be8c;">Hello, world!</span><span style="color:#c0c5ce;">&quot;);
}
</span></code></pre><h3 id="nix-build-expression">Nix build expression</h3>
<p>If we were just building this locally, we'd just run <code>cargo build --release</code>.
But we are going to have Nix build this for us so that it can track the runtime
dependencies. Therefore we need a <code>default.nix</code> file to describe the build
process. Our <code>default.nix</code> build file looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">with </span><span style="color:#c0c5ce;">(</span><span style="color:#96b5b4;">import </span><span style="color:#a3be8c;">&lt;nixpkgs&gt; </span><span style="color:#c0c5ce;">{});
</span><span style="color:#bf616a;">rustPlatform</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">buildRustPackage </span><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">name </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">hello-rust</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#d08770;">buildInputs </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">cargo rustc </span><span style="color:#c0c5ce;">];
  </span><span style="color:#d08770;">src </span><span style="color:#c0c5ce;">= </span><span style="color:#a3be8c;">./.</span><span style="color:#c0c5ce;">;
  </span><span style="color:#65737e;"># This is a shasum over our crate dependencies
  </span><span style="color:#d08770;">cargoSha256 </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">1s4vg081ci6hskb3kk965nxnx384w8xb7n7yc4g93hj55qsk4vw5</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#65737e;"># Use this to figure out the correct Sha256
  # cargoSha256 = lib.fakeSha256;
  </span><span style="color:#d08770;">buildPhase </span><span style="color:#c0c5ce;">= &#39;&#39;</span><span style="color:#a3be8c;">
    cargo build --release
  </span><span style="color:#c0c5ce;">&#39;&#39;;
  </span><span style="color:#d08770;">checkPhase </span><span style="color:#c0c5ce;">= &quot;&quot;;
  </span><span style="color:#d08770;">installPhase </span><span style="color:#c0c5ce;">= &#39;&#39;</span><span style="color:#a3be8c;">
    mkdir -p $out/bin
    cp target/release/hello $out/bin
  </span><span style="color:#c0c5ce;">&#39;&#39;;
}
</span></code></pre>
<p>Breaking down the Nix expression: we specify what our inputs our to our
build: <code>cargo</code> and <code>rustc</code>; we figure out what the sha256sum is of our crate
dependencies; and we define some commands to build and install the executable.</p>
<p>We can verify this works locally on our machine by running <code>nix-build .</code>
(assuming you have Nix installed locally). You'll end up with a symlink named
result that points the compiled executable residing in /nix/store. Running
<code>./result/bin/hello</code> should print &quot;Hello, world!&quot;.</p>
<h3 id="docker-file">Docker file</h3>
<p>Now that we've built our Nix expression that defines how the code is built, we
can add Docker to the mix. The goal is to have a builder stage that runs the
nix-build command, then have a production stage that copies the executable and
its runtime dependencies from builder. The production stage container will
therefore have only the minimal amount of stuff needed to run.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># Use nix as the builder
</span><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> nixos/nix:latest </span><span style="color:#b48ead;">AS </span><span style="color:#bf616a;">builder

</span><span style="color:#65737e;"># Update the channel so we can get the latest packages
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">nix-channel --update nixpkgs
</span><span style="color:#b48ead;">
WORKDIR </span><span style="color:#c0c5ce;">/app

</span><span style="color:#65737e;"># Run the builder first without our code to fetch build dependencies.
# This will fail, but that&#39;s okay. We just want to have the build dependencies
# cached as a layer. This is just a caching optimization that can be removed.
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> default.nix .
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">nix-build . || true

</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> . .

</span><span style="color:#65737e;"># Now that our code is here we actually build it
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">nix-build .

</span><span style="color:#65737e;"># Copy all the run time dependencies into /tmp/nix-store-closure
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">mkdir /tmp/nix-store-closure
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">echo &quot;</span><span style="color:#a3be8c;">Output references (Runtime dependencies):</span><span style="color:#c0c5ce;">&quot; $(nix-store -qR result/)
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">cp -R $(nix-store -qR result/) /tmp/nix-store-closure

ENTRYPOINT [ &quot;</span><span style="color:#a3be8c;">/bin/sh</span><span style="color:#c0c5ce;">&quot; ]

</span><span style="color:#65737e;"># Our production stage
</span><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> scratch
</span><span style="color:#b48ead;">WORKDIR </span><span style="color:#c0c5ce;">/app
</span><span style="color:#65737e;"># Copy the runtime dependencies into /nix/store
# Note we don&#39;t actually have nix installed on this container. But that&#39;s fine,
# we don&#39;t need it, the built code only relies on the given files existing, not
# Nix.
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> --from=</span><span style="color:#bf616a;">builder</span><span style="color:#c0c5ce;"> /tmp/nix-store-closure /nix/store
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> --from=</span><span style="color:#bf616a;">builder</span><span style="color:#c0c5ce;"> /app/result /app
CMD [&quot;</span><span style="color:#a3be8c;">/app/bin/hello</span><span style="color:#c0c5ce;">&quot;]
</span></code></pre>
<p>If we build this <code>Dockerfile</code> with <code>docker build .</code>, we'll end up with an 33MB
container. Compare this to a naive
<a href="https://gist.github.com/MarcoPolo/7953f1ca2691405b5b04659027967336">Dockerfile</a>
where we end up with a 624 MB container! That's an order of magnitude smaller
for a relatively simple change.</p>
<p>Note that our executable has a shared library dependency on libc. Alpine
linux doesn't include libc, but this still works. How? When we build our code we
reference the libc shared library stored inside <code>/nix/store</code>. Then when we copy
the executable nix tells us that the libc shared library is also a dependency so
we copy that too. Our executable uses only the libc inside <code>/nix/store</code> and
doesn't rely on any system provided libraries in <code>/lib</code> or elsewhere.</p>
<h2 id="conclusion">Conclusion</h2>
<p>With a simple Nix build expression and the use of Docker's multi stage builds we
can use Docker's strength of providing a consistent and portable environment
with Nix's fine grained dependency resolution to create a minimal production
container.</p>
<h2 id="a-note-on-statically-linked-executables">A note on statically linked executables</h2>
<p>Yes, you could build the hello world example as a statically linked musl-backed
binary. But that's not the point. Sometimes code relies on a shared library, and
it's just not worth or impossible to convert it. The beauty of this system is
that it doesn't matter if the output executable is fully statically linked or
not. It will work just the same and copy over the minimum amount of code needed
for the production container to work.</p>
<h2 id="a-note-on-nix-s-dockertools">A note on Nix's dockerTools</h2>
<p>Nix proves a set of functions for creating Docker images:
<a href="https://nixos.org/nixpkgs/manual/#sec-pkgs-dockerTools">pkgs.dockerTools</a>. It's
very cool, and I recommend checking it. Unlike docker it produces
deterministic images. Note, for all but the simplest examples, KVM is required.</p>
<h2 id="a-note-on-bazel-s-rules-docker">A note on Bazel's rules_docker</h2>
<p>I don't know much about this, but I'd assume this would be similar to what I've
described. If you know more about this, please let me know!</p>
"""

+++
<p>Multi Stage builds are great for minimizing the size of your container. The
general idea is you have a stage as your builder and another stage as your
product. This allows you to have a full development and build container while
still having a lean production container. The production container only carries
its runtime dependencies.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> golang:1.7.3
</span><span style="color:#b48ead;">WORKDIR </span><span style="color:#c0c5ce;">/go/src/github.com/alexellis/href-counter/
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">go get -d -v golang.org/x/net/html
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> app.go .
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

</span><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> alpine:latest
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">apk --no-cache add ca-certificates
</span><span style="color:#b48ead;">WORKDIR </span><span style="color:#c0c5ce;">/root/
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> --from=</span><span style="color:#bf616a;">0</span><span style="color:#c0c5ce;"> /go/src/github.com/alexellis/href-counter/app .
CMD [&quot;</span><span style="color:#a3be8c;">./app</span><span style="color:#c0c5ce;">&quot;]
</span></code></pre>
<p>(from Docker's <a href="https://docs.docker.com/develop/develop-images/multistage-build/">docs on multi-stage</a>)</p>
<p>Sounds great, right? What's the catch? Well, it's not always easy to know what the
runtime dependencies are. For example you may have installed something in /lib
that was needed in the build process. But it turned out to be a shared library
and now it needs to be included in the production container. Tricky! Is there
some automated way to know all your runtime dependencies?</p>
<h2 id="enter-nix">Enter Nix</h2>
<p><a href="https://nixos.org/">Nix</a> is a functional and immutable package manager. It works great for
reproducible builds. It keeps track of packages and their dependencies via their
content hashes. And, relevant for this exercise, it also keeps track of the
dependencies of a built package. That means we can use Nix to build our project
and then ask Nix what our runtime dependencies are. With that information we can
copy just those files to the product stage of our multi-stage build and end up
with the smallest possible docker container.</p>
<p>Our general strategy will be to use a Nix builder to build our code. Ask the Nix
builder to tell us all the runtime dependencies of our built executable. Then
copy the executable with all it's runtime dependencies to a fresh container. Our
expectation is that this will result in a minimal production container.</p>
<h2 id="example">Example</h2>
<p>As a simple example let's package a &quot;Hello World&quot; program in Rust. The code is
what you'd expect:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">pub fn </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">() {
    println!(&quot;</span><span style="color:#a3be8c;">Hello, world!</span><span style="color:#c0c5ce;">&quot;);
}
</span></code></pre><h3 id="nix-build-expression">Nix build expression</h3>
<p>If we were just building this locally, we'd just run <code>cargo build --release</code>.
But we are going to have Nix build this for us so that it can track the runtime
dependencies. Therefore we need a <code>default.nix</code> file to describe the build
process. Our <code>default.nix</code> build file looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">with </span><span style="color:#c0c5ce;">(</span><span style="color:#96b5b4;">import </span><span style="color:#a3be8c;">&lt;nixpkgs&gt; </span><span style="color:#c0c5ce;">{});
</span><span style="color:#bf616a;">rustPlatform</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">buildRustPackage </span><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">name </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">hello-rust</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#d08770;">buildInputs </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">cargo rustc </span><span style="color:#c0c5ce;">];
  </span><span style="color:#d08770;">src </span><span style="color:#c0c5ce;">= </span><span style="color:#a3be8c;">./.</span><span style="color:#c0c5ce;">;
  </span><span style="color:#65737e;"># This is a shasum over our crate dependencies
  </span><span style="color:#d08770;">cargoSha256 </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">1s4vg081ci6hskb3kk965nxnx384w8xb7n7yc4g93hj55qsk4vw5</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#65737e;"># Use this to figure out the correct Sha256
  # cargoSha256 = lib.fakeSha256;
  </span><span style="color:#d08770;">buildPhase </span><span style="color:#c0c5ce;">= &#39;&#39;</span><span style="color:#a3be8c;">
    cargo build --release
  </span><span style="color:#c0c5ce;">&#39;&#39;;
  </span><span style="color:#d08770;">checkPhase </span><span style="color:#c0c5ce;">= &quot;&quot;;
  </span><span style="color:#d08770;">installPhase </span><span style="color:#c0c5ce;">= &#39;&#39;</span><span style="color:#a3be8c;">
    mkdir -p $out/bin
    cp target/release/hello $out/bin
  </span><span style="color:#c0c5ce;">&#39;&#39;;
}
</span></code></pre>
<p>Breaking down the Nix expression: we specify what our inputs our to our
build: <code>cargo</code> and <code>rustc</code>; we figure out what the sha256sum is of our crate
dependencies; and we define some commands to build and install the executable.</p>
<p>We can verify this works locally on our machine by running <code>nix-build .</code>
(assuming you have Nix installed locally). You'll end up with a symlink named
result that points the compiled executable residing in /nix/store. Running
<code>./result/bin/hello</code> should print &quot;Hello, world!&quot;.</p>
<h3 id="docker-file">Docker file</h3>
<p>Now that we've built our Nix expression that defines how the code is built, we
can add Docker to the mix. The goal is to have a builder stage that runs the
nix-build command, then have a production stage that copies the executable and
its runtime dependencies from builder. The production stage container will
therefore have only the minimal amount of stuff needed to run.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;"># Use nix as the builder
</span><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> nixos/nix:latest </span><span style="color:#b48ead;">AS </span><span style="color:#bf616a;">builder

</span><span style="color:#65737e;"># Update the channel so we can get the latest packages
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">nix-channel --update nixpkgs
</span><span style="color:#b48ead;">
WORKDIR </span><span style="color:#c0c5ce;">/app

</span><span style="color:#65737e;"># Run the builder first without our code to fetch build dependencies.
# This will fail, but that&#39;s okay. We just want to have the build dependencies
# cached as a layer. This is just a caching optimization that can be removed.
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> default.nix .
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">nix-build . || true

</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> . .

</span><span style="color:#65737e;"># Now that our code is here we actually build it
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">nix-build .

</span><span style="color:#65737e;"># Copy all the run time dependencies into /tmp/nix-store-closure
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">mkdir /tmp/nix-store-closure
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">echo &quot;</span><span style="color:#a3be8c;">Output references (Runtime dependencies):</span><span style="color:#c0c5ce;">&quot; $(nix-store -qR result/)
</span><span style="color:#b48ead;">RUN </span><span style="color:#c0c5ce;">cp -R $(nix-store -qR result/) /tmp/nix-store-closure

ENTRYPOINT [ &quot;</span><span style="color:#a3be8c;">/bin/sh</span><span style="color:#c0c5ce;">&quot; ]

</span><span style="color:#65737e;"># Our production stage
</span><span style="color:#b48ead;">FROM</span><span style="color:#c0c5ce;"> scratch
</span><span style="color:#b48ead;">WORKDIR </span><span style="color:#c0c5ce;">/app
</span><span style="color:#65737e;"># Copy the runtime dependencies into /nix/store
# Note we don&#39;t actually have nix installed on this container. But that&#39;s fine,
# we don&#39;t need it, the built code only relies on the given files existing, not
# Nix.
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> --from=</span><span style="color:#bf616a;">builder</span><span style="color:#c0c5ce;"> /tmp/nix-store-closure /nix/store
</span><span style="color:#b48ead;">COPY</span><span style="color:#c0c5ce;"> --from=</span><span style="color:#bf616a;">builder</span><span style="color:#c0c5ce;"> /app/result /app
CMD [&quot;</span><span style="color:#a3be8c;">/app/bin/hello</span><span style="color:#c0c5ce;">&quot;]
</span></code></pre>
<p>If we build this <code>Dockerfile</code> with <code>docker build .</code>, we'll end up with an 33MB
container. Compare this to a naive
<a href="https://gist.github.com/MarcoPolo/7953f1ca2691405b5b04659027967336">Dockerfile</a>
where we end up with a 624 MB container! That's an order of magnitude smaller
for a relatively simple change.</p>
<p>Note that our executable has a shared library dependency on libc. Alpine
linux doesn't include libc, but this still works. How? When we build our code we
reference the libc shared library stored inside <code>/nix/store</code>. Then when we copy
the executable nix tells us that the libc shared library is also a dependency so
we copy that too. Our executable uses only the libc inside <code>/nix/store</code> and
doesn't rely on any system provided libraries in <code>/lib</code> or elsewhere.</p>
<h2 id="conclusion">Conclusion</h2>
<p>With a simple Nix build expression and the use of Docker's multi stage builds we
can use Docker's strength of providing a consistent and portable environment
with Nix's fine grained dependency resolution to create a minimal production
container.</p>
<h2 id="a-note-on-statically-linked-executables">A note on statically linked executables</h2>
<p>Yes, you could build the hello world example as a statically linked musl-backed
binary. But that's not the point. Sometimes code relies on a shared library, and
it's just not worth or impossible to convert it. The beauty of this system is
that it doesn't matter if the output executable is fully statically linked or
not. It will work just the same and copy over the minimum amount of code needed
for the production container to work.</p>
<h2 id="a-note-on-nix-s-dockertools">A note on Nix's dockerTools</h2>
<p>Nix proves a set of functions for creating Docker images:
<a href="https://nixos.org/nixpkgs/manual/#sec-pkgs-dockerTools">pkgs.dockerTools</a>. It's
very cool, and I recommend checking it. Unlike docker it produces
deterministic images. Note, for all but the simplest examples, KVM is required.</p>
<h2 id="a-note-on-bazel-s-rules-docker">A note on Bazel's rules_docker</h2>
<p>I don't know much about this, but I'd assume this would be similar to what I've
described. If you know more about this, please let me know!</p>

