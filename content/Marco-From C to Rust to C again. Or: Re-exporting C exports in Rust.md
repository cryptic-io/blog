
+++
title = "From C to Rust to C again. Or: Re-exporting C exports in Rust"
date = 2019-12-12T00:00:00.000Z
template = "html_content/raw.html"
summary = "The only difference between being a grown up and being a kid, in my experience, is as a grown up, yo..."

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/from-c-to-rust-to-c/"
raw = """
<p>The only difference between being a grown up and being a kid, in my experience, is as a grown up, you have much fewer people who are willing to play the game <em>telephone</em> with you. Luckily for me, I have access to a computer, a C compiler, and a Rust compiler. Let me show you how I played telephone with Rust &amp; C.</p>
<p>tl;dr:</p>
<ul>
<li>Rust can't re-export from a linked C library (unless you rename) when compiled as a cdylib.</li>
<li>Look at this <a href="https://github.com/rust-lang/rfcs/issues/2771">issue</a></li>
</ul>
<p>Imagine you have some C code that provides <code>add_two</code>. It looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">int </span><span style="color:#8fa1b3;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">int </span><span style="color:#bf616a;">n</span><span style="color:#c0c5ce;">)
{
    </span><span style="color:#b48ead;">return</span><span style="color:#c0c5ce;"> n + </span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">;
}
</span></code></pre>
<p>And you can even let Cargo deal with building your C library by making a build.rs with <code>cc</code>. Like so:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">use</span><span style="color:#c0c5ce;"> cc;

</span><span style="color:#b48ead;">fn </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">() {
    cc::Build::new().</span><span style="color:#96b5b4;">file</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">src/c/foo.c</span><span style="color:#c0c5ce;">&quot;).</span><span style="color:#96b5b4;">compile</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">foo</span><span style="color:#c0c5ce;">&quot;);
}
</span></code></pre>
<p>Now you want to be able to call <code>add_two</code> from Rust. Easy! You look at the <a href="https://doc.rust-lang.org/nomicon/ffi.html">FFI</a> section in the Nomicon. And follow it like so:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">#[</span><span style="color:#bf616a;">link</span><span style="color:#c0c5ce;">(name = &quot;</span><span style="color:#a3be8c;">foo</span><span style="color:#c0c5ce;">&quot;, kind = &quot;</span><span style="color:#a3be8c;">static</span><span style="color:#c0c5ce;">&quot;)]
#[</span><span style="color:#bf616a;">no_mangle</span><span style="color:#c0c5ce;">]
</span><span style="color:#b48ead;">extern </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot; {
    </span><span style="color:#b48ead;">pub fn </span><span style="color:#8fa1b3;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">x</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">u32</span><span style="color:#c0c5ce;">) -&gt; </span><span style="color:#b48ead;">u32</span><span style="color:#c0c5ce;">;
}

#[</span><span style="color:#bf616a;">no_mangle</span><span style="color:#c0c5ce;">]
</span><span style="color:#b48ead;">pub extern </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot; </span><span style="color:#b48ead;">fn </span><span style="color:#8fa1b3;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">x</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">u32</span><span style="color:#c0c5ce;">) -&gt; </span><span style="color:#b48ead;">u32 </span><span style="color:#c0c5ce;">{
    </span><span style="color:#b48ead;">let</span><span style="color:#c0c5ce;"> a = </span><span style="color:#b48ead;">unsafe </span><span style="color:#c0c5ce;">{ </span><span style="color:#96b5b4;">add_two</span><span style="color:#c0c5ce;">(x) };
    a - </span><span style="color:#d08770;">1
</span><span style="color:#c0c5ce;">}

#[</span><span style="color:#bf616a;">cfg</span><span style="color:#c0c5ce;">(test)]
</span><span style="color:#b48ead;">mod </span><span style="color:#c0c5ce;">tests {
    </span><span style="color:#b48ead;">use super</span><span style="color:#c0c5ce;">::*;
    #[</span><span style="color:#bf616a;">test</span><span style="color:#c0c5ce;">]
    </span><span style="color:#b48ead;">fn </span><span style="color:#8fa1b3;">it_works</span><span style="color:#c0c5ce;">() {
        assert_eq!(</span><span style="color:#96b5b4;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">), </span><span style="color:#d08770;">3</span><span style="color:#c0c5ce;">);
        assert_eq!(</span><span style="color:#b48ead;">unsafe </span><span style="color:#c0c5ce;">{ </span><span style="color:#96b5b4;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">) }, </span><span style="color:#d08770;">4</span><span style="color:#c0c5ce;">);
    }
}
</span></code></pre>
<p>Now for the last chain in our telephone. We'll make a new C file that will call our Rust defined <code>add_one</code> and our C defined <code>add_two</code>.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">extern int </span><span style="color:#8fa1b3;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">int </span><span style="color:#bf616a;">n</span><span style="color:#c0c5ce;">);
</span><span style="color:#b48ead;">extern int </span><span style="color:#8fa1b3;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">int </span><span style="color:#bf616a;">n</span><span style="color:#c0c5ce;">);

</span><span style="color:#b48ead;">int </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">()
{
    </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">39</span><span style="color:#c0c5ce;">));
}
</span></code></pre>
<p>We use Clang to build this file:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">clang call_rust.c -lrust_c_playground -L./target/debug -o call_rust
</span></code></pre>
<p>Now we have an executable called <code>call_rust</code> which calls a Rust defined function and calls a C defined function that it pulled in from a single Rust Library (called <code>librust_c_playground.dylib</code> on macOS). The flags in the clang command mean: <code>-l</code> link this library; <code>-L</code> look here for the library.</p>
<p>We've built the code, now we can even run it!</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">./call_rust
echo $? # Print the return code of our program, hopefully 42
</span></code></pre>
<p>Great! We've called C from a Rust Library from a C program. But there's a catch. This won't work if you are building a <code>cdylib</code>. There isn't an RFC yet on how to re-export C externs. In the mean time you'll either have to: re-export under a different name, or build a <code>dylib</code>. See this issue: <a href="https://github.com/rust-lang/rfcs/issues/2771">Re-exporting C symbols for cdylib</a>.</p>
<p>Hope this helps.</p>
"""

+++
<p>The only difference between being a grown up and being a kid, in my experience, is as a grown up, you have much fewer people who are willing to play the game <em>telephone</em> with you. Luckily for me, I have access to a computer, a C compiler, and a Rust compiler. Let me show you how I played telephone with Rust &amp; C.</p>
<p>tl;dr:</p>
<ul>
<li>Rust can't re-export from a linked C library (unless you rename) when compiled as a cdylib.</li>
<li>Look at this <a href="https://github.com/rust-lang/rfcs/issues/2771">issue</a></li>
</ul>
<p>Imagine you have some C code that provides <code>add_two</code>. It looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">int </span><span style="color:#8fa1b3;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">int </span><span style="color:#bf616a;">n</span><span style="color:#c0c5ce;">)
{
    </span><span style="color:#b48ead;">return</span><span style="color:#c0c5ce;"> n + </span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">;
}
</span></code></pre>
<p>And you can even let Cargo deal with building your C library by making a build.rs with <code>cc</code>. Like so:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">use</span><span style="color:#c0c5ce;"> cc;

</span><span style="color:#b48ead;">fn </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">() {
    cc::Build::new().</span><span style="color:#96b5b4;">file</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">src/c/foo.c</span><span style="color:#c0c5ce;">&quot;).</span><span style="color:#96b5b4;">compile</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">foo</span><span style="color:#c0c5ce;">&quot;);
}
</span></code></pre>
<p>Now you want to be able to call <code>add_two</code> from Rust. Easy! You look at the <a href="https://doc.rust-lang.org/nomicon/ffi.html">FFI</a> section in the Nomicon. And follow it like so:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">#[</span><span style="color:#bf616a;">link</span><span style="color:#c0c5ce;">(name = &quot;</span><span style="color:#a3be8c;">foo</span><span style="color:#c0c5ce;">&quot;, kind = &quot;</span><span style="color:#a3be8c;">static</span><span style="color:#c0c5ce;">&quot;)]
#[</span><span style="color:#bf616a;">no_mangle</span><span style="color:#c0c5ce;">]
</span><span style="color:#b48ead;">extern </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot; {
    </span><span style="color:#b48ead;">pub fn </span><span style="color:#8fa1b3;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">x</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">u32</span><span style="color:#c0c5ce;">) -&gt; </span><span style="color:#b48ead;">u32</span><span style="color:#c0c5ce;">;
}

#[</span><span style="color:#bf616a;">no_mangle</span><span style="color:#c0c5ce;">]
</span><span style="color:#b48ead;">pub extern </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot; </span><span style="color:#b48ead;">fn </span><span style="color:#8fa1b3;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">x</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">u32</span><span style="color:#c0c5ce;">) -&gt; </span><span style="color:#b48ead;">u32 </span><span style="color:#c0c5ce;">{
    </span><span style="color:#b48ead;">let</span><span style="color:#c0c5ce;"> a = </span><span style="color:#b48ead;">unsafe </span><span style="color:#c0c5ce;">{ </span><span style="color:#96b5b4;">add_two</span><span style="color:#c0c5ce;">(x) };
    a - </span><span style="color:#d08770;">1
</span><span style="color:#c0c5ce;">}

#[</span><span style="color:#bf616a;">cfg</span><span style="color:#c0c5ce;">(test)]
</span><span style="color:#b48ead;">mod </span><span style="color:#c0c5ce;">tests {
    </span><span style="color:#b48ead;">use super</span><span style="color:#c0c5ce;">::*;
    #[</span><span style="color:#bf616a;">test</span><span style="color:#c0c5ce;">]
    </span><span style="color:#b48ead;">fn </span><span style="color:#8fa1b3;">it_works</span><span style="color:#c0c5ce;">() {
        assert_eq!(</span><span style="color:#96b5b4;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">), </span><span style="color:#d08770;">3</span><span style="color:#c0c5ce;">);
        assert_eq!(</span><span style="color:#b48ead;">unsafe </span><span style="color:#c0c5ce;">{ </span><span style="color:#96b5b4;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">) }, </span><span style="color:#d08770;">4</span><span style="color:#c0c5ce;">);
    }
}
</span></code></pre>
<p>Now for the last chain in our telephone. We'll make a new C file that will call our Rust defined <code>add_one</code> and our C defined <code>add_two</code>.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">extern int </span><span style="color:#8fa1b3;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">int </span><span style="color:#bf616a;">n</span><span style="color:#c0c5ce;">);
</span><span style="color:#b48ead;">extern int </span><span style="color:#8fa1b3;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">int </span><span style="color:#bf616a;">n</span><span style="color:#c0c5ce;">);

</span><span style="color:#b48ead;">int </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">()
{
    </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">add_one</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">add_two</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">39</span><span style="color:#c0c5ce;">));
}
</span></code></pre>
<p>We use Clang to build this file:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">clang call_rust.c -lrust_c_playground -L./target/debug -o call_rust
</span></code></pre>
<p>Now we have an executable called <code>call_rust</code> which calls a Rust defined function and calls a C defined function that it pulled in from a single Rust Library (called <code>librust_c_playground.dylib</code> on macOS). The flags in the clang command mean: <code>-l</code> link this library; <code>-L</code> look here for the library.</p>
<p>We've built the code, now we can even run it!</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">./call_rust
echo $? # Print the return code of our program, hopefully 42
</span></code></pre>
<p>Great! We've called C from a Rust Library from a C program. But there's a catch. This won't work if you are building a <code>cdylib</code>. There isn't an RFC yet on how to re-export C externs. In the mean time you'll either have to: re-export under a different name, or build a <code>dylib</code>. See this issue: <a href="https://github.com/rust-lang/rfcs/issues/2771">Re-exporting C symbols for cdylib</a>.</p>
<p>Hope this helps.</p>

