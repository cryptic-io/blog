
+++
title = "Goodbye, bit rot"
date = 2021-02-01T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Take a look at this picture:

That's a photo of Smalltalk 76 running the prototypical desktop UI. It..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/goodbye-bit-rot/"
raw = """
<p>Take a look at this picture:</p>
<p><img src="https://marcopolo.io/code/goodbye-bit-rot/smalltalk-76.png" alt="Smalltalk 76" /></p>
<p>That's a photo of Smalltalk 76 running the prototypical desktop UI. It's
taken for granted that this photo will be viewable for the indefinite future
(or as long as we keep a PNG viewer around). But when we think about code,
maybe the very same Smalltalk code we took this photo of, it's assumed that
eventually that code will stop running. It'll stop working because of a
mysterious force known as <a href="https://en.wikipedia.org/wiki/Software_rot">bit
rot</a>. Why? It's this truly
inevitable? Or can we do better?</p>
<h2 id="we-can-do-better">We can do better</h2>
<p>Bit rot often manifests in the case where some software <em>A</em> relies on a certain
configured environment. Imagine <em>A</em> relies on a shared library <em>B</em>. As time
progresses, the shared library <em>B</em> can (and probably will) be updated
independently of <em>A</em>. Thus breaking <em>A</em>. But what if <em>A</em> could say it
explicitly depends on version <em>X.Y.Z</em> of <em>B</em>, or even better yet, the version
of the library that hashes to the value <code>0xBADCOFFEE</code>. Then you break the
implicit dependency of a correctly configured environment. <em>A</em> stops
depending on the world being in a certain state. Instead, <em>A</em>
<em>explicitly defines</em> what the world it needs should look like.</p>
<h2 id="enter-nix">Enter Nix</h2>
<p>This is what <a href="https://nixos.org/">Nix</a> gives you. A way to explicitly define
what a piece of software needs to build and run. Here's an example of the
definition on how to build the <a href="https://www.gnu.org/software/hello/">GNU
Hello</a> program:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">with </span><span style="color:#c0c5ce;">(</span><span style="color:#96b5b4;">import </span><span style="color:#a3be8c;">&lt;nixpkgs&gt; </span><span style="color:#c0c5ce;">{});
</span><span style="color:#96b5b4;">derivation </span><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">name </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">hello</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#d08770;">builder </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">bash</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/bash</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#d08770;">args </span><span style="color:#c0c5ce;">= [ </span><span style="color:#a3be8c;">./builder.sh </span><span style="color:#c0c5ce;">];
  </span><span style="color:#d08770;">buildInputs </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">gnutar gzip gnumake gcc binutils-unwrapped coreutils gawk gnused gnugrep </span><span style="color:#c0c5ce;">];
  </span><span style="color:#d08770;">src </span><span style="color:#c0c5ce;">= </span><span style="color:#a3be8c;">./hello-2.10.tar.gz</span><span style="color:#c0c5ce;">;
  </span><span style="color:#d08770;">system </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">builtins</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">currentSystem</span><span style="color:#c0c5ce;">;
}
</span></code></pre>
<p>It's not necessary to explain this <a href="https://nixos.org/guides/nix-pills/generic-builders.html#idm140737320275008">code in
detail</a>.
It's enough to point out that <code>buildInputs</code> defines what the environment should
contain (i.e. it should contain <code>gnutar</code>, <code>gzip</code>, <code>gnumake</code>, etc.). And the
versions of these dependencies are defined by the current version of
<code>&lt;nixpkgs&gt;</code>. These dependencies can be further pinned (or <em>locked</em> in the
terminology of some languages like Javascript and Rust) to ensure that this
program will always be built with the same exact versions of its dependencies.
This extends to the runtime as well. This means you can run two different
programs that each rely on a different <code>glibc</code>. Or to bring it back to our
initial example, software <em>A</em> will always run because it will always use the
same exact shared library <em>B</em>.</p>
<h2 id="a-concrete-example-this-will-never-bit-rot">A concrete example. This will never bit rot.</h2>
<p>To continue our Smalltalk theme, here's a &quot;Hello World&quot; program that, barring a
fundamental change in how Nix Flakes works, will work forever<sup class="footnote-reference"><a href="#1">1</a></sup> on an x86_64
linux machine.</p>
<p>The definition of our program, <code>flake.nix</code></p>
<pre style="background-color:#2b303b;">
<code><span style="color:#8fa1b3;">{
  </span><span style="color:#c0c5ce;">inputs</span><span style="background-color:#bf616a;color:#2b303b;">.</span><span style="color:#bf616a;">nixpkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">url </span><span style="background-color:#bf616a;color:#2b303b;">=</span><span style="color:#c0c5ce;"> &quot;</span><span style="color:#a3be8c;">github:NixOS/nixpkgs/nixos-20.09</span><span style="color:#c0c5ce;">&quot;</span><span style="background-color:#bf616a;color:#2b303b;">;</span><span style="color:#c0c5ce;">
  </span><span style="color:#bf616a;">outputs </span><span style="background-color:#bf616a;color:#2b303b;">=</span><span style="color:#c0c5ce;">
    </span><span style="color:#8fa1b3;">{ </span><span style="color:#c0c5ce;">self, nixpkgs </span><span style="color:#8fa1b3;">}</span><span style="color:#c0c5ce;">:
    </span><span style="color:#b48ead;">let
      </span><span style="color:#d08770;">pkgs </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">nixpkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">legacyPackages</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">x86_64-linux</span><span style="color:#c0c5ce;">;
    </span><span style="color:#b48ead;">in
    </span><span style="color:#c0c5ce;">{
      </span><span style="color:#d08770;">defaultPackage</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">x86_64-linux </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">writeScriptBin </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">hello-smalltalk</span><span style="color:#c0c5ce;">&quot; &#39;&#39;
        </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">gnu-smalltalk</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/gst &lt;&lt;&lt; &quot;Transcript show: &#39;Hello World!&#39;.&quot;
      </span><span style="color:#c0c5ce;">&#39;&#39;;
    }</span><span style="background-color:#bf616a;color:#2b303b;">;</span><span style="color:#c0c5ce;">
</span><span style="color:#8fa1b3;">}
</span></code></pre>
<p>The pinned version of all our dependencies, <code>flake.lock</code></p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  &quot;</span><span style="color:#a3be8c;">nodes</span><span style="color:#c0c5ce;">&quot;: {
    &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;: {
      &quot;</span><span style="color:#a3be8c;">locked</span><span style="color:#c0c5ce;">&quot;: {
        &quot;</span><span style="color:#a3be8c;">lastModified</span><span style="color:#c0c5ce;">&quot;: </span><span style="color:#d08770;">1606669556</span><span style="color:#c0c5ce;">,
        &quot;</span><span style="color:#a3be8c;">narHash</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">sha256-9rlqZ5JwnA6nK04vKhV0s5ndepnWL5hpkaTV1b4ASvk=</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">owner</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">NixOS</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">repo</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">rev</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">ae47c79479a086e96e2977c61e538881913c0c08</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">type</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">github</span><span style="color:#c0c5ce;">&quot;
      },
      &quot;</span><span style="color:#a3be8c;">original</span><span style="color:#c0c5ce;">&quot;: {
        &quot;</span><span style="color:#a3be8c;">owner</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">NixOS</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">ref</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixos-20.09</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">repo</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">type</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">github</span><span style="color:#c0c5ce;">&quot;
      }
    },
    &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;: {
      &quot;</span><span style="color:#a3be8c;">inputs</span><span style="color:#c0c5ce;">&quot;: {
        &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;
      }
    }
  },
  &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;,
  &quot;</span><span style="color:#a3be8c;">version</span><span style="color:#c0c5ce;">&quot;: </span><span style="color:#d08770;">7
</span><span style="color:#c0c5ce;">}
</span></code></pre>
<p>copy those files into a directory and run it:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#bf616a;">❯</span><span style="color:#c0c5ce;"> nix run
</span><span style="color:#bf616a;">Hello</span><span style="color:#c0c5ce;"> World!
</span></code></pre><h2 id="solid-foundations">Solid Foundations</h2>
<p>With Nix, we can make steady forward progress. Without fear that our foundations
will collapse under us like sand castles. Once we've built something in Nix we
can be pretty sure it will work for our colleague or ourselves in 10 years. Nix
is building a solid foundation that I can no longer live without.</p>
<p>If you haven't used Nix before, here's your call to action:</p>
<ul>
<li>Nix's homepage: <a href="https://nixos.org/">https://nixos.org/</a></li>
<li>Nix's Learning page: <a href="https://nixos.org/learn">https://nixos.org/learn</a></li>
<li>Learn Nix in little bite-sized pills: <a href="https://nixos.org/guides/nix-pills/">https://nixos.org/guides/nix-pills/</a></li>
</ul>
<hr />
<h2 id="disclaimer">Disclaimer</h2>
<p>There are various factors that lead to bit rot. Some are easier to solve than
others. For the purpose of this post I'm only considering programs that are
roughly self contained. For example, if a program relies on hitting a specific
Google endpoint, the only way to use this program would be to emulate the whole
Google stack or rely on that <a href="https://gcemetery.co/">endpoint existing</a>.
Sometimes it's doable to emulate the external API, and sometimes it isn't. This
post is specifically about cases where it is feasible to emulate the external API.</p>
<h3 id="footnotes">Footnotes</h3>
<div class="footnote-definition" id="1"><sup class="footnote-definition-label">1</sup>
<p>Okay forever is a really long time. And this will likely not run forever. But why? The easy reasons are: &quot;Github is down&quot;, &quot;A source tarball you need can't be fetched from the internet&quot;, &quot;x86_64 processors can't be found or emulated&quot;. But what's a weird reason that this may fail in the future? It'll probably be hard to predict, but maybe something like: SHA256 has been broken and criminals and/or pranksters have published malicious packages that match a certain SHA256. So build tools that rely on a deterministic and hard to break hash algorithm like SHA256 (like what Nix does) will no longer be reliable. That would be a funny future. Send me your weird reasons: <code>&quot;marco+forever&quot; ++ &quot;@marcopolo.io&quot;</code></p>
</div>
"""

+++
<p>Take a look at this picture:</p>
<p><img src="https://marcopolo.io/code/goodbye-bit-rot/smalltalk-76.png" alt="Smalltalk 76" /></p>
<p>That's a photo of Smalltalk 76 running the prototypical desktop UI. It's
taken for granted that this photo will be viewable for the indefinite future
(or as long as we keep a PNG viewer around). But when we think about code,
maybe the very same Smalltalk code we took this photo of, it's assumed that
eventually that code will stop running. It'll stop working because of a
mysterious force known as <a href="https://en.wikipedia.org/wiki/Software_rot">bit
rot</a>. Why? It's this truly
inevitable? Or can we do better?</p>
<h2 id="we-can-do-better">We can do better</h2>
<p>Bit rot often manifests in the case where some software <em>A</em> relies on a certain
configured environment. Imagine <em>A</em> relies on a shared library <em>B</em>. As time
progresses, the shared library <em>B</em> can (and probably will) be updated
independently of <em>A</em>. Thus breaking <em>A</em>. But what if <em>A</em> could say it
explicitly depends on version <em>X.Y.Z</em> of <em>B</em>, or even better yet, the version
of the library that hashes to the value <code>0xBADCOFFEE</code>. Then you break the
implicit dependency of a correctly configured environment. <em>A</em> stops
depending on the world being in a certain state. Instead, <em>A</em>
<em>explicitly defines</em> what the world it needs should look like.</p>
<h2 id="enter-nix">Enter Nix</h2>
<p>This is what <a href="https://nixos.org/">Nix</a> gives you. A way to explicitly define
what a piece of software needs to build and run. Here's an example of the
definition on how to build the <a href="https://www.gnu.org/software/hello/">GNU
Hello</a> program:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">with </span><span style="color:#c0c5ce;">(</span><span style="color:#96b5b4;">import </span><span style="color:#a3be8c;">&lt;nixpkgs&gt; </span><span style="color:#c0c5ce;">{});
</span><span style="color:#96b5b4;">derivation </span><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">name </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">hello</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#d08770;">builder </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">bash</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/bash</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#d08770;">args </span><span style="color:#c0c5ce;">= [ </span><span style="color:#a3be8c;">./builder.sh </span><span style="color:#c0c5ce;">];
  </span><span style="color:#d08770;">buildInputs </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">gnutar gzip gnumake gcc binutils-unwrapped coreutils gawk gnused gnugrep </span><span style="color:#c0c5ce;">];
  </span><span style="color:#d08770;">src </span><span style="color:#c0c5ce;">= </span><span style="color:#a3be8c;">./hello-2.10.tar.gz</span><span style="color:#c0c5ce;">;
  </span><span style="color:#d08770;">system </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">builtins</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">currentSystem</span><span style="color:#c0c5ce;">;
}
</span></code></pre>
<p>It's not necessary to explain this <a href="https://nixos.org/guides/nix-pills/generic-builders.html#idm140737320275008">code in
detail</a>.
It's enough to point out that <code>buildInputs</code> defines what the environment should
contain (i.e. it should contain <code>gnutar</code>, <code>gzip</code>, <code>gnumake</code>, etc.). And the
versions of these dependencies are defined by the current version of
<code>&lt;nixpkgs&gt;</code>. These dependencies can be further pinned (or <em>locked</em> in the
terminology of some languages like Javascript and Rust) to ensure that this
program will always be built with the same exact versions of its dependencies.
This extends to the runtime as well. This means you can run two different
programs that each rely on a different <code>glibc</code>. Or to bring it back to our
initial example, software <em>A</em> will always run because it will always use the
same exact shared library <em>B</em>.</p>
<h2 id="a-concrete-example-this-will-never-bit-rot">A concrete example. This will never bit rot.</h2>
<p>To continue our Smalltalk theme, here's a &quot;Hello World&quot; program that, barring a
fundamental change in how Nix Flakes works, will work forever<sup class="footnote-reference"><a href="#1">1</a></sup> on an x86_64
linux machine.</p>
<p>The definition of our program, <code>flake.nix</code></p>
<pre style="background-color:#2b303b;">
<code><span style="color:#8fa1b3;">{
  </span><span style="color:#c0c5ce;">inputs</span><span style="background-color:#bf616a;color:#2b303b;">.</span><span style="color:#bf616a;">nixpkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">url </span><span style="background-color:#bf616a;color:#2b303b;">=</span><span style="color:#c0c5ce;"> &quot;</span><span style="color:#a3be8c;">github:NixOS/nixpkgs/nixos-20.09</span><span style="color:#c0c5ce;">&quot;</span><span style="background-color:#bf616a;color:#2b303b;">;</span><span style="color:#c0c5ce;">
  </span><span style="color:#bf616a;">outputs </span><span style="background-color:#bf616a;color:#2b303b;">=</span><span style="color:#c0c5ce;">
    </span><span style="color:#8fa1b3;">{ </span><span style="color:#c0c5ce;">self, nixpkgs </span><span style="color:#8fa1b3;">}</span><span style="color:#c0c5ce;">:
    </span><span style="color:#b48ead;">let
      </span><span style="color:#d08770;">pkgs </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">nixpkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">legacyPackages</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">x86_64-linux</span><span style="color:#c0c5ce;">;
    </span><span style="color:#b48ead;">in
    </span><span style="color:#c0c5ce;">{
      </span><span style="color:#d08770;">defaultPackage</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">x86_64-linux </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">writeScriptBin </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">hello-smalltalk</span><span style="color:#c0c5ce;">&quot; &#39;&#39;
        </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">gnu-smalltalk</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/gst &lt;&lt;&lt; &quot;Transcript show: &#39;Hello World!&#39;.&quot;
      </span><span style="color:#c0c5ce;">&#39;&#39;;
    }</span><span style="background-color:#bf616a;color:#2b303b;">;</span><span style="color:#c0c5ce;">
</span><span style="color:#8fa1b3;">}
</span></code></pre>
<p>The pinned version of all our dependencies, <code>flake.lock</code></p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  &quot;</span><span style="color:#a3be8c;">nodes</span><span style="color:#c0c5ce;">&quot;: {
    &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;: {
      &quot;</span><span style="color:#a3be8c;">locked</span><span style="color:#c0c5ce;">&quot;: {
        &quot;</span><span style="color:#a3be8c;">lastModified</span><span style="color:#c0c5ce;">&quot;: </span><span style="color:#d08770;">1606669556</span><span style="color:#c0c5ce;">,
        &quot;</span><span style="color:#a3be8c;">narHash</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">sha256-9rlqZ5JwnA6nK04vKhV0s5ndepnWL5hpkaTV1b4ASvk=</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">owner</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">NixOS</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">repo</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">rev</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">ae47c79479a086e96e2977c61e538881913c0c08</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">type</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">github</span><span style="color:#c0c5ce;">&quot;
      },
      &quot;</span><span style="color:#a3be8c;">original</span><span style="color:#c0c5ce;">&quot;: {
        &quot;</span><span style="color:#a3be8c;">owner</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">NixOS</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">ref</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixos-20.09</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">repo</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;,
        &quot;</span><span style="color:#a3be8c;">type</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">github</span><span style="color:#c0c5ce;">&quot;
      }
    },
    &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;: {
      &quot;</span><span style="color:#a3be8c;">inputs</span><span style="color:#c0c5ce;">&quot;: {
        &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">nixpkgs</span><span style="color:#c0c5ce;">&quot;
      }
    }
  },
  &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;: &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;,
  &quot;</span><span style="color:#a3be8c;">version</span><span style="color:#c0c5ce;">&quot;: </span><span style="color:#d08770;">7
</span><span style="color:#c0c5ce;">}
</span></code></pre>
<p>copy those files into a directory and run it:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#bf616a;">❯</span><span style="color:#c0c5ce;"> nix run
</span><span style="color:#bf616a;">Hello</span><span style="color:#c0c5ce;"> World!
</span></code></pre><h2 id="solid-foundations">Solid Foundations</h2>
<p>With Nix, we can make steady forward progress. Without fear that our foundations
will collapse under us like sand castles. Once we've built something in Nix we
can be pretty sure it will work for our colleague or ourselves in 10 years. Nix
is building a solid foundation that I can no longer live without.</p>
<p>If you haven't used Nix before, here's your call to action:</p>
<ul>
<li>Nix's homepage: <a href="https://nixos.org/">https://nixos.org/</a></li>
<li>Nix's Learning page: <a href="https://nixos.org/learn">https://nixos.org/learn</a></li>
<li>Learn Nix in little bite-sized pills: <a href="https://nixos.org/guides/nix-pills/">https://nixos.org/guides/nix-pills/</a></li>
</ul>
<hr />
<h2 id="disclaimer">Disclaimer</h2>
<p>There are various factors that lead to bit rot. Some are easier to solve than
others. For the purpose of this post I'm only considering programs that are
roughly self contained. For example, if a program relies on hitting a specific
Google endpoint, the only way to use this program would be to emulate the whole
Google stack or rely on that <a href="https://gcemetery.co/">endpoint existing</a>.
Sometimes it's doable to emulate the external API, and sometimes it isn't. This
post is specifically about cases where it is feasible to emulate the external API.</p>
<h3 id="footnotes">Footnotes</h3>
<div class="footnote-definition" id="1"><sup class="footnote-definition-label">1</sup>
<p>Okay forever is a really long time. And this will likely not run forever. But why? The easy reasons are: &quot;Github is down&quot;, &quot;A source tarball you need can't be fetched from the internet&quot;, &quot;x86_64 processors can't be found or emulated&quot;. But what's a weird reason that this may fail in the future? It'll probably be hard to predict, but maybe something like: SHA256 has been broken and criminals and/or pranksters have published malicious packages that match a certain SHA256. So build tools that rely on a deterministic and hard to break hash algorithm like SHA256 (like what Nix does) will no longer be reliable. That would be a funny future. Send me your weird reasons: <code>&quot;marco+forever&quot; ++ &quot;@marcopolo.io&quot;</code></p>
</div>

