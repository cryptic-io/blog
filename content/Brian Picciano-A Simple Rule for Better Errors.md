
+++
title = "A Simple Rule for Better Errors"
date = 2021-03-20T00:00:00.000Z
template = "html_content/raw.html"
summary = """
This post will describe a simple rule for writing error messages that I’ve
been using for some time ..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/03/20/a-simple-rule-for-better-errors.html"
raw = """
<p>This post will describe a simple rule for writing error messages that I’ve
been using for some time and have found to be worthwhile. Using this rule I can
be sure that my errors are propagated upwards with everything needed to debug
problems, while not containing tons of extraneous or duplicate information.</p>

<p>This rule is not specific to any particular language, pattern of error
propagation (e.g. exceptions, signals, simple strings), or method of embedding
information in errors (e.g. key/value pairs, formatted strings).</p>

<p>I do not claim to have invented this system, I’m just describing it.</p>

<h2 id="the-rule">The Rule</h2>

<p>Without more ado, here’s the rule:</p>

<blockquote>
  <p>A function sending back an error should not include information the caller
could already know.</p>
</blockquote>

<p>Pretty simple, really, but the best rules are. Keeping to this rule will result
in error messages which, once propagated up to their final destination (usually
some kind of logger), will contain only the information relevant to the error
itself, with minimal duplication.</p>

<p>The reason this rule works in tandem with good encapsulation of function
behavior. The caller of a function knows only the inputs to the function and, in
general terms, what the function is going to do with those inputs. If the
returned error only includes information outside of those two things then the
caller knows everything it needs to know about the error, and can continue on to
propagate that error up the stack (with more information tacked on if necessary)
or handle it in some other way.</p>

<h2 id="examples">Examples</h2>

<p>(For examples I’ll use Go, but as previously mentioned this rule will be useful
in any other language as well.)</p>

<p>Let’s go through a few examples, to show the various ways that this rule can
manifest in actual code.</p>

<p><strong>Example 1: Nothing to add</strong></p>

<p>In this example we have a function which merely wraps a call to <code class="language-plaintext highlighter-rouge">io.Copy</code> for
two files:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">copyFile</span><span class="p">(</span><span class="n">dst</span><span class="p">,</span> <span class="n">src</span> <span class="o">*</span><span class="n">os</span><span class="o">.</span><span class="n">File</span><span class="p">)</span> <span class="kt">error</span> <span class="p">{</span>
\t<span class="n">_</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">io</span><span class="o">.</span><span class="n">Copy</span><span class="p">(</span><span class="n">dst</span><span class="p">,</span> <span class="n">src</span><span class="p">)</span>
\t<span class="k">return</span> <span class="n">err</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In this example there’s no need to modify the error from <code class="language-plaintext highlighter-rouge">io.Copy</code> before
returning it to the caller. What would we even add? The caller already knows
which files were involved in the error, and that the error was encountered
during some kind of copy operation (since that’s what the function says it
does), so there’s nothing more to say about it.</p>

<p><strong>Example 2: Annotating which step an error occurs at</strong></p>

<p>In this example we will open a file, read its contents, and return them as a
string:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">readFile</span><span class="p">(</span><span class="n">path</span> <span class="kt">string</span><span class="p">)</span> <span class="p">(</span><span class="kt">string</span><span class="p">,</span> <span class="kt">error</span><span class="p">)</span> <span class="p">{</span>
\t<span class="n">f</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">os</span><span class="o">.</span><span class="n">Open</span><span class="p">(</span><span class="n">path</span><span class="p">)</span>
\t<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
\t\t<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"opening file: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
\t<span class="p">}</span>
\t<span class="k">defer</span> <span class="n">f</span><span class="o">.</span><span class="n">Close</span><span class="p">()</span>

\t<span class="n">contents</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">io</span><span class="o">.</span><span class="n">ReadAll</span><span class="p">(</span><span class="n">f</span><span class="p">)</span>
\t<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
\t\t<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
\t<span class="p">}</span>

\t<span class="k">return</span> <span class="kt">string</span><span class="p">(</span><span class="n">contents</span><span class="p">),</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In this example there are two different steps which could result in an error:
opening the file and reading its contents. If an error is returned then our
imaginary caller doesn’t know which step the error occurred at. Using our rule
we can infer that it would be good to annotate at <em>which</em> step the error is
from, so the caller is able to have a fuller picture of what went wrong.</p>

<p>Note that each annotation does <em>not</em> include the file path which was passed into
the function. The caller already knows this path, so an error being returned
back which reiterates the path is unnecessary.</p>

<p><strong>Example 3: Annotating which argument was involved</strong></p>

<p>In this example we will read two files using our function from example 2, and
return the concatenation of their contents as a string.</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">concatFiles</span><span class="p">(</span><span class="n">pathA</span><span class="p">,</span> <span class="n">pathB</span> <span class="kt">string</span><span class="p">)</span> <span class="p">(</span><span class="kt">string</span><span class="p">,</span> <span class="kt">error</span><span class="p">)</span> <span class="p">{</span>
\t<span class="n">contentsA</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">readFile</span><span class="p">(</span><span class="n">pathA</span><span class="p">)</span>
\t<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
\t\t<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents of %q: %w"</span><span class="p">,</span> <span class="n">pathA</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
\t<span class="p">}</span>

\t<span class="n">contentsB</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">readFile</span><span class="p">(</span><span class="n">pathB</span><span class="p">)</span>
\t<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
\t\t<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents of %q: %w"</span><span class="p">,</span> <span class="n">pathB</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
\t<span class="p">}</span>

\t<span class="k">return</span> <span class="n">contentsA</span> <span class="o">+</span> <span class="n">contentsB</span><span class="p">,</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p>Like in example 2 we annotate each error, but instead of annotating the action
we annotate which file path was involved in each error. This is because if we
simply annotated with the string <code class="language-plaintext highlighter-rouge">reading contents</code> like before it wouldn’t be
clear to the caller <em>which</em> file’s contents couldn’t be read. Therefore we
include which path the error is relevant to.</p>

<p><strong>Example 4: Layering</strong></p>

<p>In this example we will show how using this rule habitually results in easy to
read errors which contain all relevant information surrounding the error. Our
example reads one file, the “full” file, using our <code class="language-plaintext highlighter-rouge">readFile</code> function from
example 2. It then reads the concatenation of two files, the “split” files,
using our <code class="language-plaintext highlighter-rouge">concatFiles</code> function from example 3. It finally determines if the
two strings are equal:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">verifySplits</span><span class="p">(</span><span class="n">fullFilePath</span><span class="p">,</span> <span class="n">splitFilePathA</span><span class="p">,</span> <span class="n">splitFilePathB</span> <span class="kt">string</span><span class="p">)</span> <span class="kt">error</span> <span class="p">{</span>
\t<span class="n">fullContents</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">readFile</span><span class="p">(</span><span class="n">fullFilePath</span><span class="p">)</span>
\t<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
\t\t<span class="k">return</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents of full file: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
\t<span class="p">}</span>

\t<span class="n">splitContents</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">concatFiles</span><span class="p">(</span><span class="n">splitFilePathA</span><span class="p">,</span> <span class="n">splitFilePathB</span><span class="p">)</span>
\t<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
\t\t<span class="k">return</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading concatenation of split files: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
\t<span class="p">}</span>

\t<span class="k">if</span> <span class="n">fullContents</span> <span class="o">!=</span> <span class="n">splitContents</span> <span class="p">{</span>
\t\t<span class="k">return</span> <span class="n">errors</span><span class="o">.</span><span class="n">New</span><span class="p">(</span><span class="s">"full file's contents do not match the split files' contents"</span><span class="p">)</span>
\t<span class="p">}</span>

\t<span class="k">return</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p>As previously, we don’t annotate the file paths for the different possible
errors, but instead say <em>which</em> files were involved. The caller already knows
the paths, there’s no need to reiterate them if there’s another way of referring
to them.</p>

<p>Let’s see what our errors actually look like! We run our new function using the
following:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code>\t<span class="n">err</span> <span class="o">:=</span> <span class="n">verifySplits</span><span class="p">(</span><span class="s">"full.txt"</span><span class="p">,</span> <span class="s">"splitA.txt"</span><span class="p">,</span> <span class="s">"splitB.txt"</span><span class="p">)</span>
\t<span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">err</span><span class="p">)</span>
</code></pre></div></div>

<p>Let’s say <code class="language-plaintext highlighter-rouge">full.txt</code> doesn’t exist, we’ll get the following error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>reading contents of full file: opening file: open full.txt: no such file or directory
</code></pre></div></div>

<p>The error is simple, and gives you everything you need to understand what went
wrong: while attempting to read the full file, during the opening of that file,
our code found that there was no such file. In fact, the error returned by
<code class="language-plaintext highlighter-rouge">os.Open</code> contains the name of the file, which goes against our rule, but it’s
the standard library so what can ya do?</p>

<p>Now, let’s say that <code class="language-plaintext highlighter-rouge">splitA.txt</code> doesn’t exist, then we’ll get this error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>reading concatenation of split files: reading contents of "splitA.txt": opening file: open splitA.txt: no such file or directory
</code></pre></div></div>

<p>Now we did include the file path here, and so the standard library’s failure to
follow our rule is causing us some repitition. But overall, within the parts of
the error we have control over, the error is concise and gives you everything
you need to know what happened.</p>

<h2 id="exceptions">Exceptions</h2>

<p>As with all rules, there are certainly exceptions. The primary one I’ve found is
that certain helper functions can benefit from bending this rule a bit. For
example, if there is a helper function which is called to verify some kind of
user input in many places, it can be helpful to include that input value within
the error returned from the helper function:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">verifyInput</span><span class="p">(</span><span class="n">str</span> <span class="kt">string</span><span class="p">)</span> <span class="kt">error</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">check</span><span class="p">(</span><span class="n">str</span><span class="p">);</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
        <span class="k">return</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"input %q was bad: %w"</span><span class="p">,</span> <span class="n">str</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">str</code> is known to the caller so, according to our rule, we don’t need to include
it in the error. But if you’re going to end up wrapping the error returned from
<code class="language-plaintext highlighter-rouge">verifyInput</code> with <code class="language-plaintext highlighter-rouge">str</code> at every call site anyway it can be convenient to save
some energy and break the rule. It’s a trade-off, convenience in exchange for
consistency.</p>

<p>Another exception might be made with regards to stack traces.</p>

<p>In the set of examples given above I tended to annotate each error being
returned with a description of where in the function the error was being
returned from. If your language automatically includes some kind of stack trace
with every error, and if you find that you are generally able to reconcile that
stack trace with actual code, then it may be that annotating each error site is
unnecessary, except when annotating actual runtime values (e.g. an input
string).</p>

<p>As in all things with programming, there are no hard rules; everything is up to
interpretation and the specific use-case being worked on. That said, I hope what
I’ve laid out here will prove generally useful to you, in whatever way you might
try to use it.</p>"""

+++
<p>This post will describe a simple rule for writing error messages that I’ve
been using for some time and have found to be worthwhile. Using this rule I can
be sure that my errors are propagated upwards with everything needed to debug
problems, while not containing tons of extraneous or duplicate information.</p>

<p>This rule is not specific to any particular language, pattern of error
propagation (e.g. exceptions, signals, simple strings), or method of embedding
information in errors (e.g. key/value pairs, formatted strings).</p>

<p>I do not claim to have invented this system, I’m just describing it.</p>

<h2 id="the-rule">The Rule</h2>

<p>Without more ado, here’s the rule:</p>

<blockquote>
  <p>A function sending back an error should not include information the caller
could already know.</p>
</blockquote>

<p>Pretty simple, really, but the best rules are. Keeping to this rule will result
in error messages which, once propagated up to their final destination (usually
some kind of logger), will contain only the information relevant to the error
itself, with minimal duplication.</p>

<p>The reason this rule works in tandem with good encapsulation of function
behavior. The caller of a function knows only the inputs to the function and, in
general terms, what the function is going to do with those inputs. If the
returned error only includes information outside of those two things then the
caller knows everything it needs to know about the error, and can continue on to
propagate that error up the stack (with more information tacked on if necessary)
or handle it in some other way.</p>

<h2 id="examples">Examples</h2>

<p>(For examples I’ll use Go, but as previously mentioned this rule will be useful
in any other language as well.)</p>

<p>Let’s go through a few examples, to show the various ways that this rule can
manifest in actual code.</p>

<p><strong>Example 1: Nothing to add</strong></p>

<p>In this example we have a function which merely wraps a call to <code class="language-plaintext highlighter-rouge">io.Copy</code> for
two files:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">copyFile</span><span class="p">(</span><span class="n">dst</span><span class="p">,</span> <span class="n">src</span> <span class="o">*</span><span class="n">os</span><span class="o">.</span><span class="n">File</span><span class="p">)</span> <span class="kt">error</span> <span class="p">{</span>
	<span class="n">_</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">io</span><span class="o">.</span><span class="n">Copy</span><span class="p">(</span><span class="n">dst</span><span class="p">,</span> <span class="n">src</span><span class="p">)</span>
	<span class="k">return</span> <span class="n">err</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In this example there’s no need to modify the error from <code class="language-plaintext highlighter-rouge">io.Copy</code> before
returning it to the caller. What would we even add? The caller already knows
which files were involved in the error, and that the error was encountered
during some kind of copy operation (since that’s what the function says it
does), so there’s nothing more to say about it.</p>

<p><strong>Example 2: Annotating which step an error occurs at</strong></p>

<p>In this example we will open a file, read its contents, and return them as a
string:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">readFile</span><span class="p">(</span><span class="n">path</span> <span class="kt">string</span><span class="p">)</span> <span class="p">(</span><span class="kt">string</span><span class="p">,</span> <span class="kt">error</span><span class="p">)</span> <span class="p">{</span>
	<span class="n">f</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">os</span><span class="o">.</span><span class="n">Open</span><span class="p">(</span><span class="n">path</span><span class="p">)</span>
	<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
		<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"opening file: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
	<span class="p">}</span>
	<span class="k">defer</span> <span class="n">f</span><span class="o">.</span><span class="n">Close</span><span class="p">()</span>

	<span class="n">contents</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">io</span><span class="o">.</span><span class="n">ReadAll</span><span class="p">(</span><span class="n">f</span><span class="p">)</span>
	<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
		<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
	<span class="p">}</span>

	<span class="k">return</span> <span class="kt">string</span><span class="p">(</span><span class="n">contents</span><span class="p">),</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In this example there are two different steps which could result in an error:
opening the file and reading its contents. If an error is returned then our
imaginary caller doesn’t know which step the error occurred at. Using our rule
we can infer that it would be good to annotate at <em>which</em> step the error is
from, so the caller is able to have a fuller picture of what went wrong.</p>

<p>Note that each annotation does <em>not</em> include the file path which was passed into
the function. The caller already knows this path, so an error being returned
back which reiterates the path is unnecessary.</p>

<p><strong>Example 3: Annotating which argument was involved</strong></p>

<p>In this example we will read two files using our function from example 2, and
return the concatenation of their contents as a string.</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">concatFiles</span><span class="p">(</span><span class="n">pathA</span><span class="p">,</span> <span class="n">pathB</span> <span class="kt">string</span><span class="p">)</span> <span class="p">(</span><span class="kt">string</span><span class="p">,</span> <span class="kt">error</span><span class="p">)</span> <span class="p">{</span>
	<span class="n">contentsA</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">readFile</span><span class="p">(</span><span class="n">pathA</span><span class="p">)</span>
	<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
		<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents of %q: %w"</span><span class="p">,</span> <span class="n">pathA</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
	<span class="p">}</span>

	<span class="n">contentsB</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">readFile</span><span class="p">(</span><span class="n">pathB</span><span class="p">)</span>
	<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
		<span class="k">return</span> <span class="s">""</span><span class="p">,</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents of %q: %w"</span><span class="p">,</span> <span class="n">pathB</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
	<span class="p">}</span>

	<span class="k">return</span> <span class="n">contentsA</span> <span class="o">+</span> <span class="n">contentsB</span><span class="p">,</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p>Like in example 2 we annotate each error, but instead of annotating the action
we annotate which file path was involved in each error. This is because if we
simply annotated with the string <code class="language-plaintext highlighter-rouge">reading contents</code> like before it wouldn’t be
clear to the caller <em>which</em> file’s contents couldn’t be read. Therefore we
include which path the error is relevant to.</p>

<p><strong>Example 4: Layering</strong></p>

<p>In this example we will show how using this rule habitually results in easy to
read errors which contain all relevant information surrounding the error. Our
example reads one file, the “full” file, using our <code class="language-plaintext highlighter-rouge">readFile</code> function from
example 2. It then reads the concatenation of two files, the “split” files,
using our <code class="language-plaintext highlighter-rouge">concatFiles</code> function from example 3. It finally determines if the
two strings are equal:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">verifySplits</span><span class="p">(</span><span class="n">fullFilePath</span><span class="p">,</span> <span class="n">splitFilePathA</span><span class="p">,</span> <span class="n">splitFilePathB</span> <span class="kt">string</span><span class="p">)</span> <span class="kt">error</span> <span class="p">{</span>
	<span class="n">fullContents</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">readFile</span><span class="p">(</span><span class="n">fullFilePath</span><span class="p">)</span>
	<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
		<span class="k">return</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading contents of full file: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
	<span class="p">}</span>

	<span class="n">splitContents</span><span class="p">,</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">concatFiles</span><span class="p">(</span><span class="n">splitFilePathA</span><span class="p">,</span> <span class="n">splitFilePathB</span><span class="p">)</span>
	<span class="k">if</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
		<span class="k">return</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"reading concatenation of split files: %w"</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
	<span class="p">}</span>

	<span class="k">if</span> <span class="n">fullContents</span> <span class="o">!=</span> <span class="n">splitContents</span> <span class="p">{</span>
		<span class="k">return</span> <span class="n">errors</span><span class="o">.</span><span class="n">New</span><span class="p">(</span><span class="s">"full file's contents do not match the split files' contents"</span><span class="p">)</span>
	<span class="p">}</span>

	<span class="k">return</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p>As previously, we don’t annotate the file paths for the different possible
errors, but instead say <em>which</em> files were involved. The caller already knows
the paths, there’s no need to reiterate them if there’s another way of referring
to them.</p>

<p>Let’s see what our errors actually look like! We run our new function using the
following:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code>	<span class="n">err</span> <span class="o">:=</span> <span class="n">verifySplits</span><span class="p">(</span><span class="s">"full.txt"</span><span class="p">,</span> <span class="s">"splitA.txt"</span><span class="p">,</span> <span class="s">"splitB.txt"</span><span class="p">)</span>
	<span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">err</span><span class="p">)</span>
</code></pre></div></div>

<p>Let’s say <code class="language-plaintext highlighter-rouge">full.txt</code> doesn’t exist, we’ll get the following error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>reading contents of full file: opening file: open full.txt: no such file or directory
</code></pre></div></div>

<p>The error is simple, and gives you everything you need to understand what went
wrong: while attempting to read the full file, during the opening of that file,
our code found that there was no such file. In fact, the error returned by
<code class="language-plaintext highlighter-rouge">os.Open</code> contains the name of the file, which goes against our rule, but it’s
the standard library so what can ya do?</p>

<p>Now, let’s say that <code class="language-plaintext highlighter-rouge">splitA.txt</code> doesn’t exist, then we’ll get this error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>reading concatenation of split files: reading contents of "splitA.txt": opening file: open splitA.txt: no such file or directory
</code></pre></div></div>

<p>Now we did include the file path here, and so the standard library’s failure to
follow our rule is causing us some repitition. But overall, within the parts of
the error we have control over, the error is concise and gives you everything
you need to know what happened.</p>

<h2 id="exceptions">Exceptions</h2>

<p>As with all rules, there are certainly exceptions. The primary one I’ve found is
that certain helper functions can benefit from bending this rule a bit. For
example, if there is a helper function which is called to verify some kind of
user input in many places, it can be helpful to include that input value within
the error returned from the helper function:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">verifyInput</span><span class="p">(</span><span class="n">str</span> <span class="kt">string</span><span class="p">)</span> <span class="kt">error</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">err</span> <span class="o">:=</span> <span class="n">check</span><span class="p">(</span><span class="n">str</span><span class="p">);</span> <span class="n">err</span> <span class="o">!=</span> <span class="no">nil</span> <span class="p">{</span>
        <span class="k">return</span> <span class="n">fmt</span><span class="o">.</span><span class="n">Errorf</span><span class="p">(</span><span class="s">"input %q was bad: %w"</span><span class="p">,</span> <span class="n">str</span><span class="p">,</span> <span class="n">err</span><span class="p">)</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="no">nil</span>
<span class="p">}</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">str</code> is known to the caller so, according to our rule, we don’t need to include
it in the error. But if you’re going to end up wrapping the error returned from
<code class="language-plaintext highlighter-rouge">verifyInput</code> with <code class="language-plaintext highlighter-rouge">str</code> at every call site anyway it can be convenient to save
some energy and break the rule. It’s a trade-off, convenience in exchange for
consistency.</p>

<p>Another exception might be made with regards to stack traces.</p>

<p>In the set of examples given above I tended to annotate each error being
returned with a description of where in the function the error was being
returned from. If your language automatically includes some kind of stack trace
with every error, and if you find that you are generally able to reconcile that
stack trace with actual code, then it may be that annotating each error site is
unnecessary, except when annotating actual runtime values (e.g. an input
string).</p>

<p>As in all things with programming, there are no hard rules; everything is up to
interpretation and the specific use-case being worked on. That said, I hope what
I’ve laid out here will prove generally useful to you, in whatever way you might
try to use it.</p>
