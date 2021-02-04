
+++
title = "Wasm is the future of serverless. Terrafirma, serverless wasm functions."
date = 2019-11-06T00:00:00.000Z
template = "html_content/raw.html"
summary = "When I ran into Fastly's Terrarium, the appeal of Webassembly (wasm) finally clicked for me. We coul..."

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/terrafirma/"
raw = """
<p>When I ran into Fastly's <a href="https://wasm.fastlylabs.com/">Terrarium</a>, the appeal of Webassembly (wasm) finally clicked for me. We could have lightweight sandboxes and bring in my own language and libraries without the overhead of a full OS VM or <a href="https://blog.iron.io/the-overhead-of-docker-run/">Docker</a>. That's great for the serverless provider, but it's also great for the end user. Less overhead means faster startup time and less total cost.</p>
<h2 id="how-much-faster">How much faster?</h2>
<p>On my machine™, a hello world shell script takes 3ms, a docker equivalent takes 700ms, and a wasm equivalent takes 15ms.</p>
<p>Following <a href="https://blog.iron.io/the-overhead-of-docker-run/">this experiment</a> I get these results:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">Running: ./hello.sh
avg: 3.516431ms
Running: docker run treeder/hello:sh
avg: 692.306769ms
Running: docker run --rm treeder/hello:sh
avg: 725.912422ms
Running: docker start -a reuse
avg: 655.059021ms
Running: node hello.js
avg: 79.233337ms
Running: wasmer run wasi-hello-world.wasm
avg: 15.155896ms
</span></code></pre>
<p>When I think about how WASM, Docker, and OS VMs (compute instances) play together, I picture this graph below.</p>
<p><img src="/code/wasm-graph.png" alt="Safety versus overhead – Raw binary is fast unsafe; was is fast and safe; docker is safe." title="Safety vs Overhead" /></p>
<p>The trend is that if you want safety and isolation, you must pay for it with overhead. WASM's exception to that rule is what I think makes it so promising and interesting. Wasm provides the fastest way to run arbitrary user code in a sandboxed environment.</p>
<h2 id="what-is-webassembly">What is Webassembly?</h2>
<p>Webassembly is a spec for a lightweight and sandboxed VM. Webassembly is run by a host, and can't do any side effects, unless it calls a function provided by the host. For example, if your WASM code wanted to make a GET request to a website, it could only do that by asking the host to help. The host exposes these helper function to the WASM guest. In Terrafirma, these are the <code>hostcall_*</code> functions in <a href="https://github.com/MarcoPolo/go-wasm-terrafirma/blob/master/imports.go"><code>imports.go</code></a>. It's called <code>imports.go</code> because it is what your WASM code is importing from the host.</p>
<h2 id="bring-your-own-tools">Bring your own tools</h2>
<p>As long as you can compile everything to a .wasm file, you can use whatever tools and language you want. All I have to do is provide a runtime, and all you have to do is provide a wasm file. However, there is a subtle caveat here. The only way you can run side effects is with the host cooperation. So you (or some library you use) must understand the environment you're running in in order to do anything interesting.</p>
<h2 id="what-about-a-standard-wasm-environment">What about a standard WASM Environment?</h2>
<p>There isn't a mature industry standard for what imports a host should provide to the WASM code running outside the browser. The closest thing we have is <a href="https://wasi.dev/">WASI</a>, which defines a POSIX inspired set of syscalls that a host should implement. It's useful because it allows code would otherwise require a real syscall to work in a WASM environment. For example, In Rust you can build with the <code>--target wasm32-wasi</code> flag and your code will just work in any <a href="https://wasmer.io/">wasi environment</a>.</p>
<h2 id="terrafirma">Terrafirma</h2>
<p>Phew! Finally at TerraFirma. TerraFirma is a WASM runtime environment I wrote to let you run wasm code in the cloud. You upload your wasm file by copying it into a shared <a href="https://keybase.io/docs/kbfs">KBFS folder</a> with the keybase user <a href="https://keybase.io/kbwasm">kbwasm</a>. Then you setup some DNS records to point your domain to TerraFirma's servers. And that's it! You can update the wasm code at any time by overwriting the old .wasm file with the new one.</p>
<h2 id="code-examples">Code Examples</h2>
<ul>
<li><a href="https://github.com/MarcoPolo/terrafirma-hello-world">Hello World</a></li>
<li><a href="https://github.com/MarcoPolo/terrafirma-scraper">Scraper Endpoint</a> – A web scraper that uses Servo – a new browser engine from Mozilla.</li>
</ul>
<h3 id="terrafirma-hello-world-tutorial">Terrafirma – Hello World Tutorial</h3>
<p>This example uses Rust, so if you don't have that setup <a href="https://rustup.rs/">go here first</a>.</p>
<ol>
<li>Point your domain to TerraFirma servers (<code>terrafirma.marcopolo.io</code> or <code>52.53.126.109</code>) with an A record, and set a <code>TXT</code> record to point to your shared folder (e.g. <code>&quot;kbp=/keybase/private/&lt;my_keybase_username&gt;,kbwasm/&quot;</code>)</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
example.com 300 A terrafirma.marcopolo.io

_keybase_pages.example.com 300 TXT &quot;kbp=/keybase/private/&lt;my_keybase_username&gt;,kbwasm/&quot;

</span></code></pre>
<ol start="2">
<li>Verify the DNS records are correct</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
$ dig example.com A
...
;; ANSWER SECTION:
wasm.marcopolo.io.      300     IN      A       52.53.126.109
...

</span></code></pre><br/>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
$ dig _keybase_pages.example.com TXT
...
;; ANSWER SECTION:
_keybase_pages.example.com &lt;number&gt; IN TXT &quot;kbp=/keybase/private/&lt;my_keybase_username&gt;,kbpbot/&quot;
...

</span></code></pre>
<ol start="3">
<li>Clone the Hello World Repo</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">git clone git@github.com:MarcoPolo/terrafirma-hello-world.git
</span></code></pre>
<ol start="4">
<li>Build it</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">cd terrafirma-hello-world
cargo build --release
</span></code></pre>
<ol start="5">
<li>Deploy it</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
cp target/wasm32-unknown-unknown/release/terrafirma_helloworld.wasm /keybase/private/&lt;your_kb_username&gt;,kbwasm/hello.wasm

</span></code></pre>
<ol start="6">
<li>Test it</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">curl https://example.com/hello.wasm
</span></code></pre>"""

+++
<p>When I ran into Fastly's <a href="https://wasm.fastlylabs.com/">Terrarium</a>, the appeal of Webassembly (wasm) finally clicked for me. We could have lightweight sandboxes and bring in my own language and libraries without the overhead of a full OS VM or <a href="https://blog.iron.io/the-overhead-of-docker-run/">Docker</a>. That's great for the serverless provider, but it's also great for the end user. Less overhead means faster startup time and less total cost.</p>
<h2 id="how-much-faster">How much faster?</h2>
<p>On my machine™, a hello world shell script takes 3ms, a docker equivalent takes 700ms, and a wasm equivalent takes 15ms.</p>
<p>Following <a href="https://blog.iron.io/the-overhead-of-docker-run/">this experiment</a> I get these results:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">Running: ./hello.sh
avg: 3.516431ms
Running: docker run treeder/hello:sh
avg: 692.306769ms
Running: docker run --rm treeder/hello:sh
avg: 725.912422ms
Running: docker start -a reuse
avg: 655.059021ms
Running: node hello.js
avg: 79.233337ms
Running: wasmer run wasi-hello-world.wasm
avg: 15.155896ms
</span></code></pre>
<p>When I think about how WASM, Docker, and OS VMs (compute instances) play together, I picture this graph below.</p>
<p><img src="/code/wasm-graph.png" alt="Safety versus overhead – Raw binary is fast unsafe; was is fast and safe; docker is safe." title="Safety vs Overhead" /></p>
<p>The trend is that if you want safety and isolation, you must pay for it with overhead. WASM's exception to that rule is what I think makes it so promising and interesting. Wasm provides the fastest way to run arbitrary user code in a sandboxed environment.</p>
<h2 id="what-is-webassembly">What is Webassembly?</h2>
<p>Webassembly is a spec for a lightweight and sandboxed VM. Webassembly is run by a host, and can't do any side effects, unless it calls a function provided by the host. For example, if your WASM code wanted to make a GET request to a website, it could only do that by asking the host to help. The host exposes these helper function to the WASM guest. In Terrafirma, these are the <code>hostcall_*</code> functions in <a href="https://github.com/MarcoPolo/go-wasm-terrafirma/blob/master/imports.go"><code>imports.go</code></a>. It's called <code>imports.go</code> because it is what your WASM code is importing from the host.</p>
<h2 id="bring-your-own-tools">Bring your own tools</h2>
<p>As long as you can compile everything to a .wasm file, you can use whatever tools and language you want. All I have to do is provide a runtime, and all you have to do is provide a wasm file. However, there is a subtle caveat here. The only way you can run side effects is with the host cooperation. So you (or some library you use) must understand the environment you're running in in order to do anything interesting.</p>
<h2 id="what-about-a-standard-wasm-environment">What about a standard WASM Environment?</h2>
<p>There isn't a mature industry standard for what imports a host should provide to the WASM code running outside the browser. The closest thing we have is <a href="https://wasi.dev/">WASI</a>, which defines a POSIX inspired set of syscalls that a host should implement. It's useful because it allows code would otherwise require a real syscall to work in a WASM environment. For example, In Rust you can build with the <code>--target wasm32-wasi</code> flag and your code will just work in any <a href="https://wasmer.io/">wasi environment</a>.</p>
<h2 id="terrafirma">Terrafirma</h2>
<p>Phew! Finally at TerraFirma. TerraFirma is a WASM runtime environment I wrote to let you run wasm code in the cloud. You upload your wasm file by copying it into a shared <a href="https://keybase.io/docs/kbfs">KBFS folder</a> with the keybase user <a href="https://keybase.io/kbwasm">kbwasm</a>. Then you setup some DNS records to point your domain to TerraFirma's servers. And that's it! You can update the wasm code at any time by overwriting the old .wasm file with the new one.</p>
<h2 id="code-examples">Code Examples</h2>
<ul>
<li><a href="https://github.com/MarcoPolo/terrafirma-hello-world">Hello World</a></li>
<li><a href="https://github.com/MarcoPolo/terrafirma-scraper">Scraper Endpoint</a> – A web scraper that uses Servo – a new browser engine from Mozilla.</li>
</ul>
<h3 id="terrafirma-hello-world-tutorial">Terrafirma – Hello World Tutorial</h3>
<p>This example uses Rust, so if you don't have that setup <a href="https://rustup.rs/">go here first</a>.</p>
<ol>
<li>Point your domain to TerraFirma servers (<code>terrafirma.marcopolo.io</code> or <code>52.53.126.109</code>) with an A record, and set a <code>TXT</code> record to point to your shared folder (e.g. <code>&quot;kbp=/keybase/private/&lt;my_keybase_username&gt;,kbwasm/&quot;</code>)</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
example.com 300 A terrafirma.marcopolo.io

_keybase_pages.example.com 300 TXT &quot;kbp=/keybase/private/&lt;my_keybase_username&gt;,kbwasm/&quot;

</span></code></pre>
<ol start="2">
<li>Verify the DNS records are correct</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
$ dig example.com A
...
;; ANSWER SECTION:
wasm.marcopolo.io.      300     IN      A       52.53.126.109
...

</span></code></pre><br/>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
$ dig _keybase_pages.example.com TXT
...
;; ANSWER SECTION:
_keybase_pages.example.com &lt;number&gt; IN TXT &quot;kbp=/keybase/private/&lt;my_keybase_username&gt;,kbpbot/&quot;
...

</span></code></pre>
<ol start="3">
<li>Clone the Hello World Repo</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">git clone git@github.com:MarcoPolo/terrafirma-hello-world.git
</span></code></pre>
<ol start="4">
<li>Build it</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">cd terrafirma-hello-world
cargo build --release
</span></code></pre>
<ol start="5">
<li>Deploy it</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">
cp target/wasm32-unknown-unknown/release/terrafirma_helloworld.wasm /keybase/private/&lt;your_kb_username&gt;,kbwasm/hello.wasm

</span></code></pre>
<ol start="6">
<li>Test it</li>
</ol>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">curl https://example.com/hello.wasm
</span></code></pre>
