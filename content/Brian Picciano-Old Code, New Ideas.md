
+++
title = "Old Code, New Ideas"
date = 2021-02-06T00:00:00.000Z
template = "html_content/raw.html"
summary = """
About 3 years ago I put a lot of effort into a set of golang packages called
mediocre-go-lib. The id..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/02/06/old-code-new-ideas.html"
raw = """
<p>About 3 years ago I put a lot of effort into a set of golang packages called
<a href="https://github.com/mediocregopher/mediocre-go-lib">mediocre-go-lib</a>. The idea was to create a framework around
the ideas I had laid out in <a href="/2019/08/02/program-structure-and-composability.html">this blog post</a> around the
structure and composability of programs. What I found in using the framework was
that it was quite bulky, not fully thought out, and ultimately difficult for
anyone but me to use. So…. a typical framework then.</p>

<p>My ideas about program structure haven’t changed a ton since then, but my ideas
around the patterns which enable that structure have simplified dramatically
(see <a href="/2020/11/16/component-oriented-programming.html">my more recent post</a> for more on that). So in that
spirit I’ve decided to cut a <code class="language-plaintext highlighter-rouge">v2</code> branch of <code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> and start trimming
the fat.</p>

<p>This is going to be an exercise both in deleting old code (very fun) and
re-examining old code which I used to think was good but now know is bad (even
more fun), and I’ve been looking forward to it for some time.</p>

<h2 id="mcmp-mctx">mcmp, mctx</h2>

<p>The two foundational pieces of <code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> are the <code class="language-plaintext highlighter-rouge">mcmp</code> and <code class="language-plaintext highlighter-rouge">mctx</code>
packages. <code class="language-plaintext highlighter-rouge">mcmp</code> primarily deals with its <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mcmp#Component">mcmp.Component</a> type,
which is a key/value store which can be used by other packages to store and
retrieve component-level information. Each <code class="language-plaintext highlighter-rouge">mcmp.Component</code> exists as a node in
a tree of <code class="language-plaintext highlighter-rouge">mcmp.Component</code>s, and these form the structure of a program.
<code class="language-plaintext highlighter-rouge">mcmp.Component</code> is able to provide information about its place in that tree as
well (i.e. its path, parents, children, etc…).</p>

<p>If this sounds cumbersome and of questionable utility that’s because it is. It’s
also not even correct, because a component in a program exists in a DAG, not a
tree. Moreover, each component can keep track of whatever data it needs for
itself using typed fields on a struct. Pretty much all other packages in
<code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> depend on <code class="language-plaintext highlighter-rouge">mcmp</code> to function, but they don’t <em>need</em> to, I just
designed it that way.</p>

<p>So my plan of attack is going to be to delete <code class="language-plaintext highlighter-rouge">mcmp</code> completely, and repair all
the other packages.</p>

<p>The other foundational piece of <code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> is <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mctx">mctx</a>. Where <code class="language-plaintext highlighter-rouge">mcmp</code>
dealt with arbitrary key/value storage on the component level, <code class="language-plaintext highlighter-rouge">mctx</code> deals with
it on the contextual level, where each go-routine (i.e. thread) corresponds to a
<code class="language-plaintext highlighter-rouge">context.Context</code>. The primary function of <code class="language-plaintext highlighter-rouge">mctx</code> is this one:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Annotate takes in one or more key/value pairs (kvs' length must be even) and</span>
<span class="c">// returns a Context carrying them.</span>
<span class="k">func</span> <span class="n">Annotate</span><span class="p">(</span><span class="n">ctx</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">,</span> <span class="n">kvs</span> <span class="o">...</span><span class="k">interface</span><span class="p">{})</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span>
</code></pre></div></div>

<p>I’m inclined to keep this around for now because it will be useful for logging,
but there’s one change I’d like to make to it. In its current form the value of
every key/value pair must already exist before being used to annotate the
<code class="language-plaintext highlighter-rouge">context.Context</code>, but this can be cumbersome in cases where the data you’d want
to annotate is quite hefty to generate but also not necessarily going to be
used. I’d like to have the option to make annotating occur lazily.  For this I
add an <code class="language-plaintext highlighter-rouge">Annotator</code> interface and a <code class="language-plaintext highlighter-rouge">WithAnnotator</code> function which takes it as an
argument, as well as some internal refactoring to make it all work right:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Annotations is a set of key/value pairs representing a set of annotations. It</span>
<span class="c">// implements the Annotator interface along with other useful post-processing</span>
<span class="c">// methods.</span>
<span class="k">type</span> <span class="n">Annotations</span> <span class="k">map</span><span class="p">[</span><span class="k">interface</span><span class="p">{}]</span><span class="k">interface</span><span class="p">{}</span>

<span class="c">// Annotator is a type which can add annotation data to an existing set of</span>
<span class="c">// annotations. The Annotate method should be expected to be called in a</span>
<span class="c">// non-thread-safe manner.</span>
<span class="k">type</span> <span class="n">Annotator</span> <span class="k">interface</span> <span class="p">{</span>
\t<span class="n">Annotate</span><span class="p">(</span><span class="n">Annotations</span><span class="p">)</span>
<span class="p">}</span>

<span class="c">// WithAnnotator takes in an Annotator and returns a Context which will produce</span>
<span class="c">// that Annotator's annotations when the Annotations function is called. The</span>
<span class="c">// Annotator will be not be evaluated until the first call to Annotations.</span>
<span class="k">func</span> <span class="n">WithAnnotator</span><span class="p">(</span><span class="n">ctx</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">,</span> <span class="n">annotator</span> <span class="n">Annotator</span><span class="p">)</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">Annotator</code> is designed like it is for two reasons. The more obvious design,
where the method has no arguments and returns a map, would cause a memory
allocation on every invocation, which could be a drag for long chains of
contexts whose annotations are being evaluated frequently. The obvious design
also leaves open questions about whether the returned map can be modified by
whoever receives it. The design given here dodges these problems without any
obvious drawbacks.</p>

<p>The original implementation also had this unnecessary <code class="language-plaintext highlighter-rouge">Annotation</code> type:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Annotation describes the annotation of a key/value pair made on a Context via</span>
<span class="c">// the Annotate call.</span>
<span class="k">type</span> <span class="n">Annotation</span> <span class="k">struct</span> <span class="p">{</span>
       <span class="n">Key</span><span class="p">,</span> <span class="n">Value</span> <span class="k">interface</span><span class="p">{}</span>
<span class="p">}</span>
</code></pre></div></div>

<p>I don’t know why this was ever needed, as an <code class="language-plaintext highlighter-rouge">Annotation</code> was never passed into
nor returned from any function. It was part of the type <code class="language-plaintext highlighter-rouge">AnnotationSet</code>, but
that could easily be refactored into a <code class="language-plaintext highlighter-rouge">map[interface{}]interface{}</code> instead. So
I factored <code class="language-plaintext highlighter-rouge">Annotation</code> out completely.</p>

<h2 id="mcfg-mrun">mcfg, mrun</h2>

<p>The next package to tackle is <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mcfg">mcfg</a>, which deals with configuration via
command line arguments and environment variables. The package is set up to use
the old <code class="language-plaintext highlighter-rouge">mcmp.Component</code> type such that each component could declare its own
configuration parameters in the global configuration. In this way the
configuration would have a hierarchy of its own which matches the component
tree.</p>

<p>Given that I now think <code class="language-plaintext highlighter-rouge">mcmp.Component</code> isn’t the right course of action it
would be the natural step to take that aspect out of <code class="language-plaintext highlighter-rouge">mcfg</code>, leaving only a
basic command-line and environment variable parser. There are many other basic
parsers of this sort out there, including <a href="https://github.com/mediocregopher/flagconfig">one</a> or <a href="https://github.com/mediocregopher/lever">two</a> I
wrote myself, and frankly I don’t think the world needs another. So <code class="language-plaintext highlighter-rouge">mcfg</code> is
going away.</p>

<p>The <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mrun">mrun</a> package is the corresponding package to <code class="language-plaintext highlighter-rouge">mcfg</code>; where <code class="language-plaintext highlighter-rouge">mcfg</code>
dealt with configuration of components <code class="language-plaintext highlighter-rouge">mrun</code> deals with the initialization and
shutdown of those same components. Like <code class="language-plaintext highlighter-rouge">mcfg</code>, <code class="language-plaintext highlighter-rouge">mrun</code> relies heavily on
<code class="language-plaintext highlighter-rouge">mcmp.Component</code>, and doesn’t really have any function with that type gone. So
<code class="language-plaintext highlighter-rouge">mrun</code> is a gonner too.</p>

<h2 id="mlog">mlog</h2>

<p>The <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mlog">mlog</a> package is primarily concerned with, as you might guess,
logging.  While there are many useful logging packages out there none of them
integrate with <code class="language-plaintext highlighter-rouge">mctx</code>’s annotations, so it is useful to have a custom logging
package here. <code class="language-plaintext highlighter-rouge">mlog</code> also has the nice property of not being extremely coupled
to <code class="language-plaintext highlighter-rouge">mcmp.Component</code> like other packages; it’s only necessary to delete a handful
of global functions which aren’t a direct part of the <code class="language-plaintext highlighter-rouge">mlog.Logger</code> type in
order to free the package from that burden.</p>

<p>With that said, the <code class="language-plaintext highlighter-rouge">mlog.Logger</code> type could still use some work. It’s primary
pattern looks like this:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Message describes a message to be logged.</span>
<span class="k">type</span> <span class="n">Message</span> <span class="k">struct</span> <span class="p">{</span>
\t<span class="n">Level</span>
\t<span class="n">Description</span> <span class="kt">string</span>
\t<span class="n">Contexts</span> <span class="p">[]</span><span class="n">context</span><span class="o">.</span><span class="n">Context</span>
<span class="p">}</span>

<span class="c">// Info logs an InfoLevel message.</span>
<span class="k">func</span> <span class="p">(</span><span class="n">l</span> <span class="o">*</span><span class="n">Logger</span><span class="p">)</span> <span class="n">Info</span><span class="p">(</span><span class="n">descr</span> <span class="kt">string</span><span class="p">,</span> <span class="n">ctxs</span> <span class="o">...</span><span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">)</span> <span class="p">{</span>
\t<span class="n">l</span><span class="o">.</span><span class="n">Log</span><span class="p">(</span><span class="n">mkMsg</span><span class="p">(</span><span class="n">InfoLevel</span><span class="p">,</span> <span class="n">descr</span><span class="p">,</span> <span class="n">ctxs</span><span class="o">...</span><span class="p">))</span>
<span class="p">}</span>
</code></pre></div></div>

<p>The idea was that if the user has multiple <code class="language-plaintext highlighter-rouge">Contexts</code> in hand, each one possibly
having some relevant annotations, all of those <code class="language-plaintext highlighter-rouge">Context</code>s’ annotations could be
merged together for the log entry.</p>

<p>Looking back it seems to me that the only thing <code class="language-plaintext highlighter-rouge">mlog</code> should care about is the
annotations, and not <em>where</em> those annotations came from. So the new pattern
looks like this:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Message describes a message to be logged.</span>
<span class="k">type</span> <span class="n">Message</span> <span class="k">struct</span> <span class="p">{</span>
\t<span class="n">Context</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span>
\t<span class="n">Level</span>
\t<span class="n">Description</span> <span class="kt">string</span>
\t<span class="n">Annotators</span>  <span class="p">[]</span><span class="n">Annotators</span>
<span class="p">}</span>

<span class="c">// Info logs a LevelInfo message.</span>
<span class="k">func</span> <span class="p">(</span><span class="n">l</span> <span class="o">*</span><span class="n">Logger</span><span class="p">)</span> <span class="n">Info</span><span class="p">(</span><span class="n">ctx</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">,</span> <span class="n">descr</span> <span class="kt">string</span><span class="p">,</span> <span class="n">annotators</span> <span class="o">...</span><span class="n">mctx</span><span class="o">.</span><span class="n">Annotator</span><span class="p">)</span>
</code></pre></div></div>

<p>The annotations on the given <code class="language-plaintext highlighter-rouge">Context</code> will be included, and then any further
<code class="language-plaintext highlighter-rouge">Annotator</code>s can be added on. This will leave room for <code class="language-plaintext highlighter-rouge">merr</code> later.</p>

<p>There’s some other warts in <code class="language-plaintext highlighter-rouge">mlog.Logger</code> that should be dealt with as well,
including some extraneous methods which were only used due to <code class="language-plaintext highlighter-rouge">mcmp.Component</code>,
some poorly named types, a message handler which didn’t properly clean itself
up, and making <code class="language-plaintext highlighter-rouge">NewLogger</code> take in parameters with which it can be customized as
needed (previously it only allowed for a single configuration). I’ve also
extended <code class="language-plaintext highlighter-rouge">Message</code> to include a timestamp, a namespace field, and some other
useful information.</p>

<h2 id="future-work">Future Work</h2>

<p>I’ve run out of time for today, but future work on this package includes:</p>

<ul>
  <li>Updating <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/merr">merr</a> with support for <code class="language-plaintext highlighter-rouge">mctx.Annotations</code>.</li>
  <li>Auditing the <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mnet">mnet</a>, <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mhttp">mhttp</a>, and <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mrpc">mrpc</a> packages to see if
they contain anything worth keeping.</li>
  <li>Probably deleting the <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/m">m</a> package entirely; I don’t even really remember
what it does.</li>
  <li>Probably deleting the <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mdb">mdb</a> package entirely; it only makes sense in the
context of <code class="language-plaintext highlighter-rouge">mcmp.Component</code>.</li>
  <li>Making a difficult decision about <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mtest">mtest</a>; I put a lot of work into it,
but is it really any better than <a href="https://github.com/stretchr/testify">testify</a>?</li>
</ul>"""

+++
<p>About 3 years ago I put a lot of effort into a set of golang packages called
<a href="https://github.com/mediocregopher/mediocre-go-lib">mediocre-go-lib</a>. The idea was to create a framework around
the ideas I had laid out in <a href="/2019/08/02/program-structure-and-composability.html">this blog post</a> around the
structure and composability of programs. What I found in using the framework was
that it was quite bulky, not fully thought out, and ultimately difficult for
anyone but me to use. So…. a typical framework then.</p>

<p>My ideas about program structure haven’t changed a ton since then, but my ideas
around the patterns which enable that structure have simplified dramatically
(see <a href="/2020/11/16/component-oriented-programming.html">my more recent post</a> for more on that). So in that
spirit I’ve decided to cut a <code class="language-plaintext highlighter-rouge">v2</code> branch of <code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> and start trimming
the fat.</p>

<p>This is going to be an exercise both in deleting old code (very fun) and
re-examining old code which I used to think was good but now know is bad (even
more fun), and I’ve been looking forward to it for some time.</p>

<h2 id="mcmp-mctx">mcmp, mctx</h2>

<p>The two foundational pieces of <code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> are the <code class="language-plaintext highlighter-rouge">mcmp</code> and <code class="language-plaintext highlighter-rouge">mctx</code>
packages. <code class="language-plaintext highlighter-rouge">mcmp</code> primarily deals with its <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mcmp#Component">mcmp.Component</a> type,
which is a key/value store which can be used by other packages to store and
retrieve component-level information. Each <code class="language-plaintext highlighter-rouge">mcmp.Component</code> exists as a node in
a tree of <code class="language-plaintext highlighter-rouge">mcmp.Component</code>s, and these form the structure of a program.
<code class="language-plaintext highlighter-rouge">mcmp.Component</code> is able to provide information about its place in that tree as
well (i.e. its path, parents, children, etc…).</p>

<p>If this sounds cumbersome and of questionable utility that’s because it is. It’s
also not even correct, because a component in a program exists in a DAG, not a
tree. Moreover, each component can keep track of whatever data it needs for
itself using typed fields on a struct. Pretty much all other packages in
<code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> depend on <code class="language-plaintext highlighter-rouge">mcmp</code> to function, but they don’t <em>need</em> to, I just
designed it that way.</p>

<p>So my plan of attack is going to be to delete <code class="language-plaintext highlighter-rouge">mcmp</code> completely, and repair all
the other packages.</p>

<p>The other foundational piece of <code class="language-plaintext highlighter-rouge">mediocre-go-lib</code> is <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mctx">mctx</a>. Where <code class="language-plaintext highlighter-rouge">mcmp</code>
dealt with arbitrary key/value storage on the component level, <code class="language-plaintext highlighter-rouge">mctx</code> deals with
it on the contextual level, where each go-routine (i.e. thread) corresponds to a
<code class="language-plaintext highlighter-rouge">context.Context</code>. The primary function of <code class="language-plaintext highlighter-rouge">mctx</code> is this one:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Annotate takes in one or more key/value pairs (kvs' length must be even) and</span>
<span class="c">// returns a Context carrying them.</span>
<span class="k">func</span> <span class="n">Annotate</span><span class="p">(</span><span class="n">ctx</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">,</span> <span class="n">kvs</span> <span class="o">...</span><span class="k">interface</span><span class="p">{})</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span>
</code></pre></div></div>

<p>I’m inclined to keep this around for now because it will be useful for logging,
but there’s one change I’d like to make to it. In its current form the value of
every key/value pair must already exist before being used to annotate the
<code class="language-plaintext highlighter-rouge">context.Context</code>, but this can be cumbersome in cases where the data you’d want
to annotate is quite hefty to generate but also not necessarily going to be
used. I’d like to have the option to make annotating occur lazily.  For this I
add an <code class="language-plaintext highlighter-rouge">Annotator</code> interface and a <code class="language-plaintext highlighter-rouge">WithAnnotator</code> function which takes it as an
argument, as well as some internal refactoring to make it all work right:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Annotations is a set of key/value pairs representing a set of annotations. It</span>
<span class="c">// implements the Annotator interface along with other useful post-processing</span>
<span class="c">// methods.</span>
<span class="k">type</span> <span class="n">Annotations</span> <span class="k">map</span><span class="p">[</span><span class="k">interface</span><span class="p">{}]</span><span class="k">interface</span><span class="p">{}</span>

<span class="c">// Annotator is a type which can add annotation data to an existing set of</span>
<span class="c">// annotations. The Annotate method should be expected to be called in a</span>
<span class="c">// non-thread-safe manner.</span>
<span class="k">type</span> <span class="n">Annotator</span> <span class="k">interface</span> <span class="p">{</span>
	<span class="n">Annotate</span><span class="p">(</span><span class="n">Annotations</span><span class="p">)</span>
<span class="p">}</span>

<span class="c">// WithAnnotator takes in an Annotator and returns a Context which will produce</span>
<span class="c">// that Annotator's annotations when the Annotations function is called. The</span>
<span class="c">// Annotator will be not be evaluated until the first call to Annotations.</span>
<span class="k">func</span> <span class="n">WithAnnotator</span><span class="p">(</span><span class="n">ctx</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">,</span> <span class="n">annotator</span> <span class="n">Annotator</span><span class="p">)</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">Annotator</code> is designed like it is for two reasons. The more obvious design,
where the method has no arguments and returns a map, would cause a memory
allocation on every invocation, which could be a drag for long chains of
contexts whose annotations are being evaluated frequently. The obvious design
also leaves open questions about whether the returned map can be modified by
whoever receives it. The design given here dodges these problems without any
obvious drawbacks.</p>

<p>The original implementation also had this unnecessary <code class="language-plaintext highlighter-rouge">Annotation</code> type:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Annotation describes the annotation of a key/value pair made on a Context via</span>
<span class="c">// the Annotate call.</span>
<span class="k">type</span> <span class="n">Annotation</span> <span class="k">struct</span> <span class="p">{</span>
       <span class="n">Key</span><span class="p">,</span> <span class="n">Value</span> <span class="k">interface</span><span class="p">{}</span>
<span class="p">}</span>
</code></pre></div></div>

<p>I don’t know why this was ever needed, as an <code class="language-plaintext highlighter-rouge">Annotation</code> was never passed into
nor returned from any function. It was part of the type <code class="language-plaintext highlighter-rouge">AnnotationSet</code>, but
that could easily be refactored into a <code class="language-plaintext highlighter-rouge">map[interface{}]interface{}</code> instead. So
I factored <code class="language-plaintext highlighter-rouge">Annotation</code> out completely.</p>

<h2 id="mcfg-mrun">mcfg, mrun</h2>

<p>The next package to tackle is <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mcfg">mcfg</a>, which deals with configuration via
command line arguments and environment variables. The package is set up to use
the old <code class="language-plaintext highlighter-rouge">mcmp.Component</code> type such that each component could declare its own
configuration parameters in the global configuration. In this way the
configuration would have a hierarchy of its own which matches the component
tree.</p>

<p>Given that I now think <code class="language-plaintext highlighter-rouge">mcmp.Component</code> isn’t the right course of action it
would be the natural step to take that aspect out of <code class="language-plaintext highlighter-rouge">mcfg</code>, leaving only a
basic command-line and environment variable parser. There are many other basic
parsers of this sort out there, including <a href="https://github.com/mediocregopher/flagconfig">one</a> or <a href="https://github.com/mediocregopher/lever">two</a> I
wrote myself, and frankly I don’t think the world needs another. So <code class="language-plaintext highlighter-rouge">mcfg</code> is
going away.</p>

<p>The <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mrun">mrun</a> package is the corresponding package to <code class="language-plaintext highlighter-rouge">mcfg</code>; where <code class="language-plaintext highlighter-rouge">mcfg</code>
dealt with configuration of components <code class="language-plaintext highlighter-rouge">mrun</code> deals with the initialization and
shutdown of those same components. Like <code class="language-plaintext highlighter-rouge">mcfg</code>, <code class="language-plaintext highlighter-rouge">mrun</code> relies heavily on
<code class="language-plaintext highlighter-rouge">mcmp.Component</code>, and doesn’t really have any function with that type gone. So
<code class="language-plaintext highlighter-rouge">mrun</code> is a gonner too.</p>

<h2 id="mlog">mlog</h2>

<p>The <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mlog">mlog</a> package is primarily concerned with, as you might guess,
logging.  While there are many useful logging packages out there none of them
integrate with <code class="language-plaintext highlighter-rouge">mctx</code>’s annotations, so it is useful to have a custom logging
package here. <code class="language-plaintext highlighter-rouge">mlog</code> also has the nice property of not being extremely coupled
to <code class="language-plaintext highlighter-rouge">mcmp.Component</code> like other packages; it’s only necessary to delete a handful
of global functions which aren’t a direct part of the <code class="language-plaintext highlighter-rouge">mlog.Logger</code> type in
order to free the package from that burden.</p>

<p>With that said, the <code class="language-plaintext highlighter-rouge">mlog.Logger</code> type could still use some work. It’s primary
pattern looks like this:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Message describes a message to be logged.</span>
<span class="k">type</span> <span class="n">Message</span> <span class="k">struct</span> <span class="p">{</span>
	<span class="n">Level</span>
	<span class="n">Description</span> <span class="kt">string</span>
	<span class="n">Contexts</span> <span class="p">[]</span><span class="n">context</span><span class="o">.</span><span class="n">Context</span>
<span class="p">}</span>

<span class="c">// Info logs an InfoLevel message.</span>
<span class="k">func</span> <span class="p">(</span><span class="n">l</span> <span class="o">*</span><span class="n">Logger</span><span class="p">)</span> <span class="n">Info</span><span class="p">(</span><span class="n">descr</span> <span class="kt">string</span><span class="p">,</span> <span class="n">ctxs</span> <span class="o">...</span><span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">)</span> <span class="p">{</span>
	<span class="n">l</span><span class="o">.</span><span class="n">Log</span><span class="p">(</span><span class="n">mkMsg</span><span class="p">(</span><span class="n">InfoLevel</span><span class="p">,</span> <span class="n">descr</span><span class="p">,</span> <span class="n">ctxs</span><span class="o">...</span><span class="p">))</span>
<span class="p">}</span>
</code></pre></div></div>

<p>The idea was that if the user has multiple <code class="language-plaintext highlighter-rouge">Contexts</code> in hand, each one possibly
having some relevant annotations, all of those <code class="language-plaintext highlighter-rouge">Context</code>s’ annotations could be
merged together for the log entry.</p>

<p>Looking back it seems to me that the only thing <code class="language-plaintext highlighter-rouge">mlog</code> should care about is the
annotations, and not <em>where</em> those annotations came from. So the new pattern
looks like this:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Message describes a message to be logged.</span>
<span class="k">type</span> <span class="n">Message</span> <span class="k">struct</span> <span class="p">{</span>
	<span class="n">Context</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span>
	<span class="n">Level</span>
	<span class="n">Description</span> <span class="kt">string</span>
	<span class="n">Annotators</span>  <span class="p">[]</span><span class="n">Annotators</span>
<span class="p">}</span>

<span class="c">// Info logs a LevelInfo message.</span>
<span class="k">func</span> <span class="p">(</span><span class="n">l</span> <span class="o">*</span><span class="n">Logger</span><span class="p">)</span> <span class="n">Info</span><span class="p">(</span><span class="n">ctx</span> <span class="n">context</span><span class="o">.</span><span class="n">Context</span><span class="p">,</span> <span class="n">descr</span> <span class="kt">string</span><span class="p">,</span> <span class="n">annotators</span> <span class="o">...</span><span class="n">mctx</span><span class="o">.</span><span class="n">Annotator</span><span class="p">)</span>
</code></pre></div></div>

<p>The annotations on the given <code class="language-plaintext highlighter-rouge">Context</code> will be included, and then any further
<code class="language-plaintext highlighter-rouge">Annotator</code>s can be added on. This will leave room for <code class="language-plaintext highlighter-rouge">merr</code> later.</p>

<p>There’s some other warts in <code class="language-plaintext highlighter-rouge">mlog.Logger</code> that should be dealt with as well,
including some extraneous methods which were only used due to <code class="language-plaintext highlighter-rouge">mcmp.Component</code>,
some poorly named types, a message handler which didn’t properly clean itself
up, and making <code class="language-plaintext highlighter-rouge">NewLogger</code> take in parameters with which it can be customized as
needed (previously it only allowed for a single configuration). I’ve also
extended <code class="language-plaintext highlighter-rouge">Message</code> to include a timestamp, a namespace field, and some other
useful information.</p>

<h2 id="future-work">Future Work</h2>

<p>I’ve run out of time for today, but future work on this package includes:</p>

<ul>
  <li>Updating <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/merr">merr</a> with support for <code class="language-plaintext highlighter-rouge">mctx.Annotations</code>.</li>
  <li>Auditing the <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mnet">mnet</a>, <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mhttp">mhttp</a>, and <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mrpc">mrpc</a> packages to see if
they contain anything worth keeping.</li>
  <li>Probably deleting the <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/m">m</a> package entirely; I don’t even really remember
what it does.</li>
  <li>Probably deleting the <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mdb">mdb</a> package entirely; it only makes sense in the
context of <code class="language-plaintext highlighter-rouge">mcmp.Component</code>.</li>
  <li>Making a difficult decision about <a href="https://pkg.go.dev/github.com/mediocregopher/mediocre-go-lib/mtest">mtest</a>; I put a lot of work into it,
but is it really any better than <a href="https://github.com/stretchr/testify">testify</a>?</li>
</ul>
