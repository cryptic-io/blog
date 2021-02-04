
+++
title = "Program Structure and Composability"
date = 2019-08-02T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Part 0: Introduction
This post is focused on a concept I call “program structure,” which I will try
..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2019/08/02/program-structure-and-composability.html"
raw = """
<h2 id="part-0-introduction">Part 0: Introduction</h2>

<p>This post is focused on a concept I call “program structure,” which I will try
to shed some light on before discussing complex program structures. I will then
discuss why complex structures can be problematic to deal with, and will finally
discuss a pattern for dealing with those problems.</p>

<p>My background is as a backend engineer working on large projects that have had
many moving parts; most had multiple programs interacting with each other, used
many different databases in various contexts, and faced large amounts of load
from millions of users. Most of this post will be framed from my perspective,
and will present problems in the way I have experienced them. I believe,
however, that the concepts and problems I discuss here are applicable to many
other domains, and I hope those with a foot in both backend systems and a second
domain can help to translate the ideas between the two.</p>

<p>Also note that I will be using Go as my example language, but none of the
concepts discussed here are specific to Go. To that end, I’ve decided to favor
readable code over “correct” code, and so have elided things that most gophers
hold near-and-dear, such as error checking and proper documentation, in order to
make the code as accessible as possible to non-gophers as well. As with before,
I trust that someone with a foot in Go and another language can help me
translate between the two.</p>

<h2 id="part-1-program-structure">Part 1: Program Structure</h2>

<p>In this section I will discuss the difference between directory and program
structure, show how global state is antithetical to compartmentalization (and
therefore good program structure), and finally discuss a more effective way to
think about program structure.</p>

<h3 id="directory-structure">Directory Structure</h3>

<p>For a long time, I thought about program structure in terms of the hierarchy
present in the filesystem. In my mind, a program’s structure looked like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>// The directory structure of a project called gobdns.
src/
    config/
    dns/
    http/
    ips/
    persist/
    repl/
    snapshot/
    main.go
</code></pre></div></div>

<p>What I grew to learn was that this conflation of “program structure” with
“directory structure” is ultimately unhelpful. While it can’t be denied that
every program has a directory structure (and if not, it ought to), this does not
mean that the way the program looks in a filesystem in any way corresponds to
how it looks in our mind’s eye.</p>

<p>The most notable way to show this is to consider a library package. Here is the
structure of a simple web-app which uses redis (my favorite database) as a
backend:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>src/
    redis/
    http/
    main.go
</code></pre></div></div>

<p>If I were to ask you, based on that directory structure, what the program does
in the most abstract terms, you might say something like: “The program
establishes an http server that listens for requests. It also establishes a
connection to the redis server. The program then interacts with redis in
different ways based on the http requests that are received on the server.”</p>

<p>And that would be a good guess. Here’s a diagram that depicts the program
structure, wherein the root node, <code class="language-plaintext highlighter-rouge">main.go</code>, takes in requests from <code class="language-plaintext highlighter-rouge">http</code> and
processes them using <code class="language-plaintext highlighter-rouge">redis</code>.</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/program-structure/diag1.jpg" target="_blank">
    <picture>
      <source srcset="/img/program-structure/500px/diag1.jpg" />
      <img style="max-height: 60vh;" src="/img/program-structure/diag1.jpg" alt="Example 1" />
    </picture>
  </a><br /><em>Example 1</em>
</div>

<p>This is certainly a viable guess for how a program with that directory
structure operates, but consider another answer: “A component of the program
called <code class="language-plaintext highlighter-rouge">server</code> establishes an http server that listens for requests. <code class="language-plaintext highlighter-rouge">server</code>
also establishes a connection to a redis server. <code class="language-plaintext highlighter-rouge">server</code> then interacts with
that redis connection in different ways based on the http requests that are
received on the http server. Additionally, <code class="language-plaintext highlighter-rouge">server</code> tracks statistics about
these interactions and makes them available to other components. The root
component of the program establishes a connection to a second redis server, and
stores those statistics in that redis server.” Here’s another diagram to depict
<em>that</em> program.</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/program-structure/diag2.jpg" target="_blank">
    <picture>
      <source srcset="/img/program-structure/500px/diag2.jpg" />
      <img style="max-height: 60vh;" src="/img/program-structure/diag2.jpg" alt="Example 2" />
    </picture>
  </a><br /><em>Example 2</em>
</div>

<p>The directory structure could apply to either description; <code class="language-plaintext highlighter-rouge">redis</code> is just a
library which allows for interaction with a redis server, but it doesn’t
specify <em>which</em> or <em>how many</em> servers. However, those are extremely important
factors that are definitely reflected in our concept of the program’s
structure, and not in the directory structure. <strong>What the directory structure
reflects are the different <em>kinds</em> of components available to use, but it does
not reflect how a program will use those components.</strong></p>

<h3 id="global-state-vs-compartmentalization">Global State vs Compartmentalization</h3>

<p>The directory-centric view of structure often leads to the use of global
singletons to manage access to external resources like RPC servers and
databases. In examples 1 and 2 the <code class="language-plaintext highlighter-rouge">redis</code> library might contain code which
looks something like this:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// A mapping of connection names to redis connections.</span>
<span class="k">var</span> <span class="n">globalConns</span> <span class="o">=</span> <span class="k">map</span><span class="p">[</span><span class="kt">string</span><span class="p">]</span><span class="o">*</span><span class="n">RedisConn</span><span class="p">{}</span>

<span class="k">func</span> <span class="n">Get</span><span class="p">(</span><span class="n">name</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">globalConns</span><span class="p">[</span><span class="n">name</span><span class="p">]</span> <span class="o">==</span> <span class="no">nil</span> <span class="p">{</span>
        <span class="n">globalConns</span><span class="p">[</span><span class="n">name</span><span class="p">]</span> <span class="o">=</span> <span class="n">makeRedisConnection</span><span class="p">(</span><span class="n">name</span><span class="p">)</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="n">globalConns</span><span class="p">[</span><span class="n">name</span><span class="p">]</span>
<span class="p">}</span>
</code></pre></div></div>

<p>Even though this pattern would work, it breaks with our conception of the
program structure in more complex cases like example 2. Rather than the <code class="language-plaintext highlighter-rouge">redis</code>
component being owned by the <code class="language-plaintext highlighter-rouge">server</code> component, which actually uses it, it
would be practically owned by <em>all</em> components, since all are able to use it.
Compartmentalization has been broken, and can only be held together through
sheer human discipline.</p>

<p><strong>This is the problem with all global state. It is shareable among all
components of a program, and so is accountable to none of them.</strong> One must look
at an entire codebase to understand how a globally held component is used,
which might not even be possible for a large codebase. Therefore, the
maintainers of these shared components rely entirely on the discipline of their
fellow coders when making changes, usually discovering where that discipline
broke down once the changes have been pushed live.</p>

<p>Global state also makes it easier for disparate programs/components to share
datastores for completely unrelated tasks. In example 2, rather than creating a
new redis instance for the root component’s statistics storage, the coder might
have instead said, “well, there’s already a redis instance available, I’ll just
use that.” And so, compartmentalization would have been broken further. Perhaps
the two instances <em>could</em> be coalesced into the same instance for the sake of
resource efficiency, but that decision would be better made at runtime via the
configuration of the program, rather than being hardcoded into the code.</p>

<p>From the perspective of team management, global state-based patterns do nothing
except slow teams down. The person/team responsible for maintaining the central
library in which shared components live (<code class="language-plaintext highlighter-rouge">redis</code>, in the above examples)
becomes the bottleneck for creating new instances for new components, which
will further lead to re-using existing instances rather than creating new ones,
further breaking compartmentalization. Additionally the person/team responsible
for the central library, rather than the team using it, often finds themselves
as the maintainers of the shared resource.</p>

<h3 id="component-structure">Component Structure</h3>

<p>So what does proper program structure look like? In my mind the structure of a
program is a hierarchy of components, or, in other words, a tree. The leaf
nodes of the tree are almost <em>always</em> IO related components, e.g., database
connections, RPC server frameworks or clients, message queue consumers, etc.
The non-leaf nodes will <em>generally</em> be components that bring together the
functionalities of their children in some useful way, though they may also have
some IO functionality of their own.</p>

<p>Let’s look at an even more complex structure, still only using the <code class="language-plaintext highlighter-rouge">redis</code> and
<code class="language-plaintext highlighter-rouge">http</code> component types:</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/program-structure/diag3.jpg" target="_blank">
    <picture>
      <source srcset="/img/program-structure/500px/diag3.jpg" />
      <img style="max-height: 60vh;" src="/img/program-structure/diag3.jpg" alt="Example 3" />
    </picture>
  </a><br /><em>Example 3</em>
</div>

<p>This component structure contains the addition of the <code class="language-plaintext highlighter-rouge">debug</code> component.
Clearly the <code class="language-plaintext highlighter-rouge">http</code> and <code class="language-plaintext highlighter-rouge">redis</code> components are reusable in different contexts,
but for this example the <code class="language-plaintext highlighter-rouge">debug</code> endpoint is as well. It creates a separate
http server that can be queried to perform runtime debugging of the program,
and can be tacked onto virtually any program. The <code class="language-plaintext highlighter-rouge">rest-api</code> component is
specific to this program and is therefore not reusable. Let’s dive into it a
bit to see how it might be implemented:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// RestAPI is very much not thread-safe, hopefully it doesn't have to handle</span>
<span class="c">// more than one request at once.</span>
<span class="k">type</span> <span class="n">RestAPI</span> <span class="k">struct</span> <span class="p">{</span>
    <span class="n">redisConn</span> <span class="o">*</span><span class="n">redis</span><span class="o">.</span><span class="n">RedisConn</span>
    <span class="n">httpSrv</span>   <span class="o">*</span><span class="n">http</span><span class="o">.</span><span class="n">Server</span>

    <span class="c">// Statistics exported for other components to see</span>
    <span class="n">RequestCount</span> <span class="kt">int</span>
    <span class="n">FooRequestCount</span> <span class="kt">int</span>
    <span class="n">BarRequestCount</span> <span class="kt">int</span>
<span class="p">}</span>

<span class="k">func</span> <span class="n">NewRestAPI</span><span class="p">()</span> <span class="o">*</span><span class="n">RestAPI</span> <span class="p">{</span>
    <span class="n">r</span> <span class="o">:=</span> <span class="nb">new</span><span class="p">(</span><span class="n">RestAPI</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">redisConn</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// mux will route requests to different handlers based on their URL path.</span>
    <span class="n">mux</span> <span class="o">:=</span> <span class="n">http</span><span class="o">.</span><span class="n">NewServeMux</span><span class="p">()</span>
    <span class="n">mux</span><span class="o">.</span><span class="n">HandleFunc</span><span class="p">(</span><span class="s">"/foo"</span><span class="p">,</span> <span class="n">r</span><span class="o">.</span><span class="n">fooHandler</span><span class="p">)</span>
    <span class="n">mux</span><span class="o">.</span><span class="n">HandleFunc</span><span class="p">(</span><span class="s">"/bar"</span><span class="p">,</span> <span class="n">r</span><span class="o">.</span><span class="n">barHandler</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">httpSrv</span> <span class="o">:=</span> <span class="n">http</span><span class="o">.</span><span class="n">NewServer</span><span class="p">(</span><span class="n">mux</span><span class="p">)</span>

    <span class="c">// Listen for requests and serve them in the background.</span>
    <span class="k">go</span> <span class="n">r</span><span class="o">.</span><span class="n">httpSrv</span><span class="o">.</span><span class="n">Listen</span><span class="p">(</span><span class="s">":8000"</span><span class="p">)</span>

    <span class="k">return</span> <span class="n">r</span>
<span class="p">}</span>

<span class="k">func</span> <span class="p">(</span><span class="n">r</span> <span class="o">*</span><span class="n">RestAPI</span><span class="p">)</span> <span class="n">fooHandler</span><span class="p">(</span><span class="n">rw</span> <span class="n">http</span><span class="o">.</span><span class="n">ResponseWriter</span><span class="p">,</span> <span class="n">r</span> <span class="o">*</span><span class="n">http</span><span class="o">.</span><span class="n">Request</span><span class="p">)</span> <span class="p">{</span>
    <span class="n">r</span><span class="o">.</span><span class="n">redisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"INCR"</span><span class="p">,</span> <span class="s">"fooKey"</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">RequestCount</span><span class="o">++</span>
    <span class="n">r</span><span class="o">.</span><span class="n">FooRequestCount</span><span class="o">++</span>
<span class="p">}</span>

<span class="k">func</span> <span class="p">(</span><span class="n">r</span> <span class="o">*</span><span class="n">RestAPI</span><span class="p">)</span> <span class="n">barHandler</span><span class="p">(</span><span class="n">rw</span> <span class="n">http</span><span class="o">.</span><span class="n">ResponseWriter</span><span class="p">,</span> <span class="n">r</span> <span class="o">*</span><span class="n">http</span><span class="o">.</span><span class="n">Request</span><span class="p">)</span> <span class="p">{</span>
    <span class="n">r</span><span class="o">.</span><span class="n">redisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"INCR"</span><span class="p">,</span> <span class="s">"barKey"</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">RequestCount</span><span class="o">++</span>
    <span class="n">r</span><span class="o">.</span><span class="n">BarRequestCount</span><span class="o">++</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In that snippet <code class="language-plaintext highlighter-rouge">rest-api</code> coalesced <code class="language-plaintext highlighter-rouge">http</code> and <code class="language-plaintext highlighter-rouge">redis</code> into a simple REST-like
api using pre-made library components. <code class="language-plaintext highlighter-rouge">main.go</code>, the root component, does much
the same:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">main</span><span class="p">()</span> <span class="p">{</span>
    <span class="c">// Create debug server and start listening in the background</span>
    <span class="n">debugSrv</span> <span class="o">:=</span> <span class="n">debug</span><span class="o">.</span><span class="n">NewServer</span><span class="p">()</span>

    <span class="c">// Set up the RestAPI, this will automatically start listening</span>
    <span class="n">restAPI</span> <span class="o">:=</span> <span class="n">NewRestAPI</span><span class="p">()</span>

    <span class="c">// Create another redis connection and use it to store statistics</span>
    <span class="n">statsRedisConn</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="s">"127.0.0.1:6380"</span><span class="p">)</span>
    <span class="k">for</span> <span class="p">{</span>
        <span class="n">time</span><span class="o">.</span><span class="n">Sleep</span><span class="p">(</span><span class="m">1</span> <span class="o">*</span> <span class="n">time</span><span class="o">.</span><span class="n">Second</span><span class="p">)</span>
        <span class="n">statsRedisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="s">"numReqs"</span><span class="p">,</span> <span class="n">restAPI</span><span class="o">.</span><span class="n">RequestCount</span><span class="p">)</span>
        <span class="n">statsRedisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="s">"numFooReqs"</span><span class="p">,</span> <span class="n">restAPI</span><span class="o">.</span><span class="n">FooRequestCount</span><span class="p">)</span>
        <span class="n">statsRedisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="s">"numBarReqs"</span><span class="p">,</span> <span class="n">restAPI</span><span class="o">.</span><span class="n">BarRequestCount</span><span class="p">)</span>
    <span class="p">}</span>
<span class="p">}</span>
</code></pre></div></div>

<p>One thing that is clearly missing in this program is proper configuration,
whether from command-line or environment variables, etc. As it stands, all
configuration parameters, such as the redis addresses and http listen
addresses, are hardcoded. Proper configuration actually ends up being somewhat
difficult, as the ideal case would be for each component to set up its own
configuration variables without its parent needing to be aware. For example,
<code class="language-plaintext highlighter-rouge">redis</code> could set up <code class="language-plaintext highlighter-rouge">addr</code> and <code class="language-plaintext highlighter-rouge">pool-size</code> parameters. The problem is that there
are two <code class="language-plaintext highlighter-rouge">redis</code> components in the program, and their parameters would therefore
conflict with each other. An elegant solution to this problem is discussed in
the next section.</p>

<h2 id="part-2-components-configuration-and-runtime">Part 2: Components, Configuration, and Runtime</h2>

<p>The key to the configuration problem is to recognize that, even if there are
two of the same component in a program, they can’t occupy the same place in the
program’s structure. In the above example, there are two <code class="language-plaintext highlighter-rouge">http</code> components: one
under <code class="language-plaintext highlighter-rouge">rest-api</code> and the other under <code class="language-plaintext highlighter-rouge">debug</code>. Because the structure is
represented as a tree of components, the “path” of any node in the tree
uniquely represents it in the structure. For example, the two <code class="language-plaintext highlighter-rouge">http</code> components
in the previous example have these paths:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>root -&gt; rest-api -&gt; http
root -&gt; debug -&gt; http
</code></pre></div></div>

<p>If each component were to know its place in the component tree, then it would
easily be able to ensure that its configuration and initialization didn’t
conflict with other components of the same type. If the <code class="language-plaintext highlighter-rouge">http</code> component sets
up a command-line parameter to know what address to listen on, the two <code class="language-plaintext highlighter-rouge">http</code>
components in that program would set up:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>--rest-api-listen-addr
--debug-listen-addr
</code></pre></div></div>

<p>So how can we enable each component to know its path in the component structure?
To answer this, we’ll have to take a detour through a type, called <code class="language-plaintext highlighter-rouge">Component</code>.</p>

<h3 id="component-and-configuration">Component and Configuration</h3>

<p>The <code class="language-plaintext highlighter-rouge">Component</code> type is a made-up type (though you’ll be able to find an
implementation of it at the end of this post). It has a single primary purpose,
and that is to convey the program’s structure to new components.</p>

<p>To see how this is done, let’s look at a couple of <code class="language-plaintext highlighter-rouge">Component</code>’s methods:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package mcmp</span>

<span class="c">// New returns a new Component which has no parents or children. It is therefore</span>
<span class="c">// the root component of a component hierarchy.</span>
<span class="k">func</span> <span class="n">New</span><span class="p">()</span> <span class="o">*</span><span class="n">Component</span>

<span class="c">// Child returns a new child of the called upon Component.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Child</span><span class="p">(</span><span class="n">name</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">Component</span>

<span class="c">// Path returns the Component's path in the component hierarchy. It will return</span>
<span class="c">// an empty slice if the Component is the root component.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Path</span><span class="p">()</span> <span class="p">[]</span><span class="kt">string</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">Child</code> is used to create a new <code class="language-plaintext highlighter-rouge">Component</code>, corresponding to a new child node
in the component structure, and <code class="language-plaintext highlighter-rouge">Path</code> is used retrieve the path of any
<code class="language-plaintext highlighter-rouge">Component</code> within that structure. For the sake of keeping the examples simple,
let’s pretend these functions have been implemented in a package called <code class="language-plaintext highlighter-rouge">mcmp</code>.
Here’s an example of how <code class="language-plaintext highlighter-rouge">Component</code> might be used in the <code class="language-plaintext highlighter-rouge">redis</code> component’s
code:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package redis</span>

<span class="k">func</span> <span class="n">NewConn</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">defaultAddr</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="n">cmp</span> <span class="o">=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"redis"</span><span class="p">)</span>
    <span class="n">paramPrefix</span> <span class="o">:=</span> <span class="n">strings</span><span class="o">.</span><span class="n">Join</span><span class="p">(</span><span class="n">cmp</span><span class="o">.</span><span class="n">Path</span><span class="p">(),</span> <span class="s">"-"</span><span class="p">)</span>

    <span class="n">addrParam</span> <span class="o">:=</span> <span class="n">flag</span><span class="o">.</span><span class="n">String</span><span class="p">(</span><span class="n">paramPrefix</span><span class="o">+</span><span class="s">"-addr"</span><span class="p">,</span> <span class="n">defaultAddr</span><span class="p">,</span> <span class="s">"Address of redis instance to connect to"</span><span class="p">)</span>
    <span class="c">// finish setup</span>

    <span class="k">return</span> <span class="n">redisConn</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In our above example, the two <code class="language-plaintext highlighter-rouge">redis</code> components’ parameters would be:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>// This first parameter is for the stats redis, whose parent is the root and
// therefore doesn't have a prefix. Perhaps stats should be broken into its own
// component in order to fix this.
--redis-addr
--rest-api-redis-addr
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">Component</code> definitely makes it easier to instantiate multiple redis components
in our program, since it allows them to know their place in the component
structure.</p>

<p>Having to construct the prefix for the parameters ourselves is pretty annoying,
so let’s introduce a new package, <code class="language-plaintext highlighter-rouge">mcfg</code>, which acts like <code class="language-plaintext highlighter-rouge">flag</code> but is aware
of <code class="language-plaintext highlighter-rouge">Component</code>. Then <code class="language-plaintext highlighter-rouge">redis.NewConn</code> is reduced to:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package redis</span>

<span class="k">func</span> <span class="n">NewConn</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">defaultAddr</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="n">cmp</span> <span class="o">=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"redis"</span><span class="p">)</span>
    <span class="n">addrParam</span> <span class="o">:=</span> <span class="n">mcfg</span><span class="o">.</span><span class="n">String</span><span class="p">(</span><span class="n">cmp</span><span class="p">,</span> <span class="s">"addr"</span><span class="p">,</span> <span class="n">defaultAddr</span><span class="p">,</span> <span class="s">"Address of redis instance to connect to"</span><span class="p">)</span>
    <span class="c">// finish setup</span>

    <span class="k">return</span> <span class="n">redisConn</span>
<span class="p">}</span>
</code></pre></div></div>

<p>Easy-peasy.</p>

<h4 id="but-what-about-parse">But What About Parse?</h4>

<p>Sharp-eyed gophers will notice that there is a key piece missing: When is
<code class="language-plaintext highlighter-rouge">flag.Parse</code>, or its <code class="language-plaintext highlighter-rouge">mcfg</code> counterpart, called? When does <code class="language-plaintext highlighter-rouge">addrParam</code> actually
get populated? It can’t happen inside <code class="language-plaintext highlighter-rouge">redis.NewConn</code> because there might be
other components after <code class="language-plaintext highlighter-rouge">redis.NewConn</code> that want to set up parameters. To
illustrate the problem, let’s look at a simple program that wants to set up two
<code class="language-plaintext highlighter-rouge">redis</code> components:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">main</span><span class="p">()</span> <span class="p">{</span>
    <span class="c">// Create the root Component, an empty Component.</span>
    <span class="n">cmp</span> <span class="o">:=</span> <span class="n">mcmp</span><span class="o">.</span><span class="n">New</span><span class="p">()</span>

    <span class="c">// Create the Components for two sub-components, foo and bar.</span>
    <span class="n">cmpFoo</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"foo"</span><span class="p">)</span>
    <span class="n">cmpBar</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"bar"</span><span class="p">)</span>

    <span class="c">// Now we want to try to create a redis sub-component for each component.</span>

    <span class="c">// This will set up the parameter "--foo-redis-addr", but bar hasn't had a</span>
    <span class="c">// chance to set up its corresponding parameter, so the command-line can't</span>
    <span class="c">// be parsed yet.</span>
    <span class="n">fooRedis</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="n">cmpFoo</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// This will set up the parameter "--bar-redis-addr", but, as mentioned</span>
    <span class="c">// before, redis.NewConn can't parse command-line.</span>
    <span class="n">barRedis</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="n">cmpBar</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// It is only after all components have been instantiated that the</span>
    <span class="c">// command-line arguments can be parsed</span>
    <span class="n">mcfg</span><span class="o">.</span><span class="n">Parse</span><span class="p">()</span>
<span class="p">}</span>
</code></pre></div></div>

<p>While this solves our argument parsing problem, fooRedis and barRedis are not
usable yet because the actual connections have not been made. This is a classic
chicken and the egg problem. The func <code class="language-plaintext highlighter-rouge">redis.NewConn</code> needs to make a connection
which it cannot do until <em>after</em> <code class="language-plaintext highlighter-rouge">mcfg.Parse</code> is called, but <code class="language-plaintext highlighter-rouge">mcfg.Parse</code> cannot
be called until after <code class="language-plaintext highlighter-rouge">redis.NewConn</code> has returned. We will solve this problem
in the next section.</p>

<h3 id="instantiation-vs-initialization">Instantiation vs Initialization</h3>

<p>Let’s break down <code class="language-plaintext highlighter-rouge">redis.NewConn</code> into two phases: instantiation and
initialization. Instantiation refers to creating the component on the component
structure and having it declare what it needs in order to initialize (e.g.,
configuration parameters). During instantiation, nothing external to the
program is performed; no IO, no reading of the command-line, no logging, etc.
All that’s happened is that the empty template of a <code class="language-plaintext highlighter-rouge">redis</code> component has been
created.</p>

<p>Initialization is the phase during which the template is filled in.
Configuration parameters are read, startup actions like the creation of database
connections are performed, and logging is output for informational and debugging
purposes.</p>

<p>The key to making effective use of this dichotomy is to allow <em>all</em> components
to instantiate themselves before they initialize themselves. By doing this we
can ensure, for example, that all components have had the chance to declare
their configuration parameters before configuration parsing is done.</p>

<p>So let’s modify <code class="language-plaintext highlighter-rouge">redis.NewConn</code> so that it follows this dichotomy. It makes
sense to leave instantiation-related code where it is, but we need a mechanism
by which we can declare initialization code before actually calling it. For
this, I will introduce the idea of a “hook.”</p>

<h4 id="but-first-augment-component">But First: Augment Component</h4>

<p>In order to support hooks, however, <code class="language-plaintext highlighter-rouge">Component</code> will need to be augmented with
a few new methods. Right now, it can only carry with it information about the
component structure, but here we will add the ability to carry arbitrary
key/value information as well:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package mcmp</span>

<span class="c">// SetValue sets the given key to the given value on the Component, overwriting</span>
<span class="c">// any previous value for that key.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">SetValue</span><span class="p">(</span><span class="n">key</span><span class="p">,</span> <span class="n">value</span> <span class="k">interface</span><span class="p">{})</span>

<span class="c">// Value returns the value which has been set for the given key, or nil if the</span>
<span class="c">// key was never set.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Value</span><span class="p">(</span><span class="n">key</span> <span class="k">interface</span><span class="p">{})</span> <span class="k">interface</span><span class="p">{}</span>

<span class="c">// Children returns the Component's children in the order they were created.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Children</span><span class="p">()</span> <span class="p">[]</span><span class="o">*</span><span class="n">Component</span>
</code></pre></div></div>

<p>The final method allows us to, starting at the root <code class="language-plaintext highlighter-rouge">Component</code>, traverse the
component structure and interact with each <code class="language-plaintext highlighter-rouge">Component</code>’s key/value store. This
will be useful for implementing hooks.</p>

<h4 id="hooks">Hooks</h4>

<p>A hook is simply a function that will run later. We will declare a new package,
calling it <code class="language-plaintext highlighter-rouge">mrun</code>, and say that it has two new functions:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package mrun</span>

<span class="c">// InitHook registers the given hook to the given Component.</span>
<span class="k">func</span> <span class="n">InitHook</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">hook</span> <span class="k">func</span><span class="p">())</span>

<span class="c">// Init runs all hooks registered using InitHook. Hooks are run in the order</span>
<span class="c">// they were registered.</span>
<span class="k">func</span> <span class="n">Init</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">)</span>
</code></pre></div></div>

<p>With these two functions, we are able to defer the initialization phase of
startup by using the same <code class="language-plaintext highlighter-rouge">Components</code> we were passing around for the purpose
of denoting component structure.</p>

<p>Now, with these few extra pieces of functionality in place, let’s reconsider the
most recent example, and make a program that creates two redis components which
exist independently of each other:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package redis</span>

<span class="c">// NOTE that NewConn has been renamed to InstConn, to reflect that the returned</span>
<span class="c">// *RedisConn is merely instantiated, not initialized.</span>

<span class="k">func</span> <span class="n">InstConn</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">defaultAddr</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="n">cmp</span> <span class="o">=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"redis"</span><span class="p">)</span>

    <span class="c">// we instantiate an empty RedisConn instance and parameters for it. Neither</span>
    <span class="c">// has been initialized yet. They will remain empty until initialization has</span>
    <span class="c">// occurred.</span>
    <span class="n">redisConn</span> <span class="o">:=</span> <span class="nb">new</span><span class="p">(</span><span class="n">RedisConn</span><span class="p">)</span>
    <span class="n">addrParam</span> <span class="o">:=</span> <span class="n">mcfg</span><span class="o">.</span><span class="n">String</span><span class="p">(</span><span class="n">cmp</span><span class="p">,</span> <span class="s">"addr"</span><span class="p">,</span> <span class="n">defaultAddr</span><span class="p">,</span> <span class="s">"Address of redis instance to connect to"</span><span class="p">)</span>

    <span class="n">mrun</span><span class="o">.</span><span class="n">InitHook</span><span class="p">(</span><span class="n">cmp</span><span class="p">,</span> <span class="k">func</span><span class="p">()</span> <span class="p">{</span>
        <span class="c">// This hook will run after parameter initialization has happened, and</span>
        <span class="c">// so addrParam will be usable. Once this hook as run, redisConn will be</span>
        <span class="c">// usable as well.</span>
        <span class="o">*</span><span class="n">redisConn</span> <span class="o">=</span> <span class="n">makeRedisConnection</span><span class="p">(</span><span class="o">*</span><span class="n">addrParam</span><span class="p">)</span>
    <span class="p">})</span>

    <span class="c">// Now that cmp has had configuration parameters and intialization hooks</span>
    <span class="c">// set into it, return the empty redisConn instance back to the parent.</span>
    <span class="k">return</span> <span class="n">redisConn</span>
<span class="p">}</span>
</code></pre></div></div>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package main</span>

<span class="k">func</span> <span class="n">main</span><span class="p">()</span> <span class="p">{</span>
    <span class="c">// Create the root Component, an empty Component.</span>
    <span class="n">cmp</span> <span class="o">:=</span> <span class="n">mcmp</span><span class="o">.</span><span class="n">New</span><span class="p">()</span>

    <span class="c">// Create the Components for two sub-components, foo and bar.</span>
    <span class="n">cmpFoo</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"foo"</span><span class="p">)</span>
    <span class="n">cmpBar</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"bar"</span><span class="p">)</span>

    <span class="c">// Add redis components to each of the foo and bar sub-components.</span>
    <span class="n">redisFoo</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">InstConn</span><span class="p">(</span><span class="n">cmpFoo</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>
    <span class="n">redisBar</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">InstConn</span><span class="p">(</span><span class="n">cmpBar</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// Parse will descend into the Component and all of its children,</span>
    <span class="c">// discovering all registered configuration parameters and filling them from</span>
    <span class="c">// the command-line.</span>
    <span class="n">mcfg</span><span class="o">.</span><span class="n">Parse</span><span class="p">(</span><span class="n">cmp</span><span class="p">)</span>

    <span class="c">// Now that configuration parameters have been initialized, run the Init</span>
    <span class="c">// hooks for all Components.</span>
    <span class="n">mrun</span><span class="o">.</span><span class="n">Init</span><span class="p">(</span><span class="n">cmp</span><span class="p">)</span>

    <span class="c">// At this point the redis components have been fully initialized and may be</span>
    <span class="c">// used. For this example we'll copy all keys from one to the other.</span>
    <span class="n">keys</span> <span class="o">:=</span> <span class="n">redisFoo</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"KEYS"</span><span class="p">,</span> <span class="s">"*"</span><span class="p">)</span>
    <span class="k">for</span> <span class="n">i</span> <span class="o">:=</span> <span class="k">range</span> <span class="n">keys</span> <span class="p">{</span>
        <span class="n">val</span> <span class="o">:=</span> <span class="n">redisFoo</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"GET"</span><span class="p">,</span> <span class="n">keys</span><span class="p">[</span><span class="n">i</span><span class="p">])</span>
        <span class="n">redisBar</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="n">keys</span><span class="p">[</span><span class="n">i</span><span class="p">],</span> <span class="n">val</span><span class="p">)</span>
    <span class="p">}</span>
<span class="p">}</span>
</code></pre></div></div>

<h2 id="conclusion">Conclusion</h2>

<p>While the examples given here are fairly simplistic, the pattern itself is quite
powerful. Codebases naturally accumulate small, domain-specific behaviors and
optimizations over time, especially around the IO components of the program.
Databases are used with specific options that an organization finds useful,
logging is performed in particular places, metrics are counted around certain
pieces of code, etc.</p>

<p>By programming with component structure in mind, we are able to keep these
optimizations while also keeping the clarity and compartmentalization of the
code intact. We can keep our code flexible and configurable, while also
re-usable and testable. Also, the simplicity of the tools involved means they
can be extended and retrofitted for nearly any situation or use-case.</p>

<p>Overall, this is a powerful pattern that I’ve found myself unable to do without
once I began using it.</p>

<h3 id="implementation">Implementation</h3>

<p>As a final note, you can find an example implementation of the packages
described in this post here:</p>

<ul>
  <li><a href="https://godoc.org/github.com/mediocregopher/mediocre-go-lib/mcmp">mcmp</a></li>
  <li><a href="https://godoc.org/github.com/mediocregopher/mediocre-go-lib/mcfg">mcfg</a></li>
  <li><a href="https://godoc.org/github.com/mediocregopher/mediocre-go-lib/mrun">mrun</a></li>
</ul>

<p>The packages are not stable and are likely to change frequently. You’ll also
find that they have been extended quite a bit from the simple descriptions found
here, based on what I’ve found useful as I’ve implemented programs using
component structures. With these two points in mind, I would encourage you to
look and take whatever functionality you find useful for yourself, and not use
the packages directly. The core pieces are not different from what has been
described in this post.</p>"""

+++
<h2 id="part-0-introduction">Part 0: Introduction</h2>

<p>This post is focused on a concept I call “program structure,” which I will try
to shed some light on before discussing complex program structures. I will then
discuss why complex structures can be problematic to deal with, and will finally
discuss a pattern for dealing with those problems.</p>

<p>My background is as a backend engineer working on large projects that have had
many moving parts; most had multiple programs interacting with each other, used
many different databases in various contexts, and faced large amounts of load
from millions of users. Most of this post will be framed from my perspective,
and will present problems in the way I have experienced them. I believe,
however, that the concepts and problems I discuss here are applicable to many
other domains, and I hope those with a foot in both backend systems and a second
domain can help to translate the ideas between the two.</p>

<p>Also note that I will be using Go as my example language, but none of the
concepts discussed here are specific to Go. To that end, I’ve decided to favor
readable code over “correct” code, and so have elided things that most gophers
hold near-and-dear, such as error checking and proper documentation, in order to
make the code as accessible as possible to non-gophers as well. As with before,
I trust that someone with a foot in Go and another language can help me
translate between the two.</p>

<h2 id="part-1-program-structure">Part 1: Program Structure</h2>

<p>In this section I will discuss the difference between directory and program
structure, show how global state is antithetical to compartmentalization (and
therefore good program structure), and finally discuss a more effective way to
think about program structure.</p>

<h3 id="directory-structure">Directory Structure</h3>

<p>For a long time, I thought about program structure in terms of the hierarchy
present in the filesystem. In my mind, a program’s structure looked like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>// The directory structure of a project called gobdns.
src/
    config/
    dns/
    http/
    ips/
    persist/
    repl/
    snapshot/
    main.go
</code></pre></div></div>

<p>What I grew to learn was that this conflation of “program structure” with
“directory structure” is ultimately unhelpful. While it can’t be denied that
every program has a directory structure (and if not, it ought to), this does not
mean that the way the program looks in a filesystem in any way corresponds to
how it looks in our mind’s eye.</p>

<p>The most notable way to show this is to consider a library package. Here is the
structure of a simple web-app which uses redis (my favorite database) as a
backend:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>src/
    redis/
    http/
    main.go
</code></pre></div></div>

<p>If I were to ask you, based on that directory structure, what the program does
in the most abstract terms, you might say something like: “The program
establishes an http server that listens for requests. It also establishes a
connection to the redis server. The program then interacts with redis in
different ways based on the http requests that are received on the server.”</p>

<p>And that would be a good guess. Here’s a diagram that depicts the program
structure, wherein the root node, <code class="language-plaintext highlighter-rouge">main.go</code>, takes in requests from <code class="language-plaintext highlighter-rouge">http</code> and
processes them using <code class="language-plaintext highlighter-rouge">redis</code>.</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/program-structure/diag1.jpg" target="_blank">
    <picture>
      <source srcset="/img/program-structure/500px/diag1.jpg" />
      <img style="max-height: 60vh;" src="/img/program-structure/diag1.jpg" alt="Example 1" />
    </picture>
  </a><br /><em>Example 1</em>
</div>

<p>This is certainly a viable guess for how a program with that directory
structure operates, but consider another answer: “A component of the program
called <code class="language-plaintext highlighter-rouge">server</code> establishes an http server that listens for requests. <code class="language-plaintext highlighter-rouge">server</code>
also establishes a connection to a redis server. <code class="language-plaintext highlighter-rouge">server</code> then interacts with
that redis connection in different ways based on the http requests that are
received on the http server. Additionally, <code class="language-plaintext highlighter-rouge">server</code> tracks statistics about
these interactions and makes them available to other components. The root
component of the program establishes a connection to a second redis server, and
stores those statistics in that redis server.” Here’s another diagram to depict
<em>that</em> program.</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/program-structure/diag2.jpg" target="_blank">
    <picture>
      <source srcset="/img/program-structure/500px/diag2.jpg" />
      <img style="max-height: 60vh;" src="/img/program-structure/diag2.jpg" alt="Example 2" />
    </picture>
  </a><br /><em>Example 2</em>
</div>

<p>The directory structure could apply to either description; <code class="language-plaintext highlighter-rouge">redis</code> is just a
library which allows for interaction with a redis server, but it doesn’t
specify <em>which</em> or <em>how many</em> servers. However, those are extremely important
factors that are definitely reflected in our concept of the program’s
structure, and not in the directory structure. <strong>What the directory structure
reflects are the different <em>kinds</em> of components available to use, but it does
not reflect how a program will use those components.</strong></p>

<h3 id="global-state-vs-compartmentalization">Global State vs Compartmentalization</h3>

<p>The directory-centric view of structure often leads to the use of global
singletons to manage access to external resources like RPC servers and
databases. In examples 1 and 2 the <code class="language-plaintext highlighter-rouge">redis</code> library might contain code which
looks something like this:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// A mapping of connection names to redis connections.</span>
<span class="k">var</span> <span class="n">globalConns</span> <span class="o">=</span> <span class="k">map</span><span class="p">[</span><span class="kt">string</span><span class="p">]</span><span class="o">*</span><span class="n">RedisConn</span><span class="p">{}</span>

<span class="k">func</span> <span class="n">Get</span><span class="p">(</span><span class="n">name</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">globalConns</span><span class="p">[</span><span class="n">name</span><span class="p">]</span> <span class="o">==</span> <span class="no">nil</span> <span class="p">{</span>
        <span class="n">globalConns</span><span class="p">[</span><span class="n">name</span><span class="p">]</span> <span class="o">=</span> <span class="n">makeRedisConnection</span><span class="p">(</span><span class="n">name</span><span class="p">)</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="n">globalConns</span><span class="p">[</span><span class="n">name</span><span class="p">]</span>
<span class="p">}</span>
</code></pre></div></div>

<p>Even though this pattern would work, it breaks with our conception of the
program structure in more complex cases like example 2. Rather than the <code class="language-plaintext highlighter-rouge">redis</code>
component being owned by the <code class="language-plaintext highlighter-rouge">server</code> component, which actually uses it, it
would be practically owned by <em>all</em> components, since all are able to use it.
Compartmentalization has been broken, and can only be held together through
sheer human discipline.</p>

<p><strong>This is the problem with all global state. It is shareable among all
components of a program, and so is accountable to none of them.</strong> One must look
at an entire codebase to understand how a globally held component is used,
which might not even be possible for a large codebase. Therefore, the
maintainers of these shared components rely entirely on the discipline of their
fellow coders when making changes, usually discovering where that discipline
broke down once the changes have been pushed live.</p>

<p>Global state also makes it easier for disparate programs/components to share
datastores for completely unrelated tasks. In example 2, rather than creating a
new redis instance for the root component’s statistics storage, the coder might
have instead said, “well, there’s already a redis instance available, I’ll just
use that.” And so, compartmentalization would have been broken further. Perhaps
the two instances <em>could</em> be coalesced into the same instance for the sake of
resource efficiency, but that decision would be better made at runtime via the
configuration of the program, rather than being hardcoded into the code.</p>

<p>From the perspective of team management, global state-based patterns do nothing
except slow teams down. The person/team responsible for maintaining the central
library in which shared components live (<code class="language-plaintext highlighter-rouge">redis</code>, in the above examples)
becomes the bottleneck for creating new instances for new components, which
will further lead to re-using existing instances rather than creating new ones,
further breaking compartmentalization. Additionally the person/team responsible
for the central library, rather than the team using it, often finds themselves
as the maintainers of the shared resource.</p>

<h3 id="component-structure">Component Structure</h3>

<p>So what does proper program structure look like? In my mind the structure of a
program is a hierarchy of components, or, in other words, a tree. The leaf
nodes of the tree are almost <em>always</em> IO related components, e.g., database
connections, RPC server frameworks or clients, message queue consumers, etc.
The non-leaf nodes will <em>generally</em> be components that bring together the
functionalities of their children in some useful way, though they may also have
some IO functionality of their own.</p>

<p>Let’s look at an even more complex structure, still only using the <code class="language-plaintext highlighter-rouge">redis</code> and
<code class="language-plaintext highlighter-rouge">http</code> component types:</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/program-structure/diag3.jpg" target="_blank">
    <picture>
      <source srcset="/img/program-structure/500px/diag3.jpg" />
      <img style="max-height: 60vh;" src="/img/program-structure/diag3.jpg" alt="Example 3" />
    </picture>
  </a><br /><em>Example 3</em>
</div>

<p>This component structure contains the addition of the <code class="language-plaintext highlighter-rouge">debug</code> component.
Clearly the <code class="language-plaintext highlighter-rouge">http</code> and <code class="language-plaintext highlighter-rouge">redis</code> components are reusable in different contexts,
but for this example the <code class="language-plaintext highlighter-rouge">debug</code> endpoint is as well. It creates a separate
http server that can be queried to perform runtime debugging of the program,
and can be tacked onto virtually any program. The <code class="language-plaintext highlighter-rouge">rest-api</code> component is
specific to this program and is therefore not reusable. Let’s dive into it a
bit to see how it might be implemented:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// RestAPI is very much not thread-safe, hopefully it doesn't have to handle</span>
<span class="c">// more than one request at once.</span>
<span class="k">type</span> <span class="n">RestAPI</span> <span class="k">struct</span> <span class="p">{</span>
    <span class="n">redisConn</span> <span class="o">*</span><span class="n">redis</span><span class="o">.</span><span class="n">RedisConn</span>
    <span class="n">httpSrv</span>   <span class="o">*</span><span class="n">http</span><span class="o">.</span><span class="n">Server</span>

    <span class="c">// Statistics exported for other components to see</span>
    <span class="n">RequestCount</span> <span class="kt">int</span>
    <span class="n">FooRequestCount</span> <span class="kt">int</span>
    <span class="n">BarRequestCount</span> <span class="kt">int</span>
<span class="p">}</span>

<span class="k">func</span> <span class="n">NewRestAPI</span><span class="p">()</span> <span class="o">*</span><span class="n">RestAPI</span> <span class="p">{</span>
    <span class="n">r</span> <span class="o">:=</span> <span class="nb">new</span><span class="p">(</span><span class="n">RestAPI</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">redisConn</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// mux will route requests to different handlers based on their URL path.</span>
    <span class="n">mux</span> <span class="o">:=</span> <span class="n">http</span><span class="o">.</span><span class="n">NewServeMux</span><span class="p">()</span>
    <span class="n">mux</span><span class="o">.</span><span class="n">HandleFunc</span><span class="p">(</span><span class="s">"/foo"</span><span class="p">,</span> <span class="n">r</span><span class="o">.</span><span class="n">fooHandler</span><span class="p">)</span>
    <span class="n">mux</span><span class="o">.</span><span class="n">HandleFunc</span><span class="p">(</span><span class="s">"/bar"</span><span class="p">,</span> <span class="n">r</span><span class="o">.</span><span class="n">barHandler</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">httpSrv</span> <span class="o">:=</span> <span class="n">http</span><span class="o">.</span><span class="n">NewServer</span><span class="p">(</span><span class="n">mux</span><span class="p">)</span>

    <span class="c">// Listen for requests and serve them in the background.</span>
    <span class="k">go</span> <span class="n">r</span><span class="o">.</span><span class="n">httpSrv</span><span class="o">.</span><span class="n">Listen</span><span class="p">(</span><span class="s">":8000"</span><span class="p">)</span>

    <span class="k">return</span> <span class="n">r</span>
<span class="p">}</span>

<span class="k">func</span> <span class="p">(</span><span class="n">r</span> <span class="o">*</span><span class="n">RestAPI</span><span class="p">)</span> <span class="n">fooHandler</span><span class="p">(</span><span class="n">rw</span> <span class="n">http</span><span class="o">.</span><span class="n">ResponseWriter</span><span class="p">,</span> <span class="n">r</span> <span class="o">*</span><span class="n">http</span><span class="o">.</span><span class="n">Request</span><span class="p">)</span> <span class="p">{</span>
    <span class="n">r</span><span class="o">.</span><span class="n">redisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"INCR"</span><span class="p">,</span> <span class="s">"fooKey"</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">RequestCount</span><span class="o">++</span>
    <span class="n">r</span><span class="o">.</span><span class="n">FooRequestCount</span><span class="o">++</span>
<span class="p">}</span>

<span class="k">func</span> <span class="p">(</span><span class="n">r</span> <span class="o">*</span><span class="n">RestAPI</span><span class="p">)</span> <span class="n">barHandler</span><span class="p">(</span><span class="n">rw</span> <span class="n">http</span><span class="o">.</span><span class="n">ResponseWriter</span><span class="p">,</span> <span class="n">r</span> <span class="o">*</span><span class="n">http</span><span class="o">.</span><span class="n">Request</span><span class="p">)</span> <span class="p">{</span>
    <span class="n">r</span><span class="o">.</span><span class="n">redisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"INCR"</span><span class="p">,</span> <span class="s">"barKey"</span><span class="p">)</span>
    <span class="n">r</span><span class="o">.</span><span class="n">RequestCount</span><span class="o">++</span>
    <span class="n">r</span><span class="o">.</span><span class="n">BarRequestCount</span><span class="o">++</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In that snippet <code class="language-plaintext highlighter-rouge">rest-api</code> coalesced <code class="language-plaintext highlighter-rouge">http</code> and <code class="language-plaintext highlighter-rouge">redis</code> into a simple REST-like
api using pre-made library components. <code class="language-plaintext highlighter-rouge">main.go</code>, the root component, does much
the same:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">main</span><span class="p">()</span> <span class="p">{</span>
    <span class="c">// Create debug server and start listening in the background</span>
    <span class="n">debugSrv</span> <span class="o">:=</span> <span class="n">debug</span><span class="o">.</span><span class="n">NewServer</span><span class="p">()</span>

    <span class="c">// Set up the RestAPI, this will automatically start listening</span>
    <span class="n">restAPI</span> <span class="o">:=</span> <span class="n">NewRestAPI</span><span class="p">()</span>

    <span class="c">// Create another redis connection and use it to store statistics</span>
    <span class="n">statsRedisConn</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="s">"127.0.0.1:6380"</span><span class="p">)</span>
    <span class="k">for</span> <span class="p">{</span>
        <span class="n">time</span><span class="o">.</span><span class="n">Sleep</span><span class="p">(</span><span class="m">1</span> <span class="o">*</span> <span class="n">time</span><span class="o">.</span><span class="n">Second</span><span class="p">)</span>
        <span class="n">statsRedisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="s">"numReqs"</span><span class="p">,</span> <span class="n">restAPI</span><span class="o">.</span><span class="n">RequestCount</span><span class="p">)</span>
        <span class="n">statsRedisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="s">"numFooReqs"</span><span class="p">,</span> <span class="n">restAPI</span><span class="o">.</span><span class="n">FooRequestCount</span><span class="p">)</span>
        <span class="n">statsRedisConn</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="s">"numBarReqs"</span><span class="p">,</span> <span class="n">restAPI</span><span class="o">.</span><span class="n">BarRequestCount</span><span class="p">)</span>
    <span class="p">}</span>
<span class="p">}</span>
</code></pre></div></div>

<p>One thing that is clearly missing in this program is proper configuration,
whether from command-line or environment variables, etc. As it stands, all
configuration parameters, such as the redis addresses and http listen
addresses, are hardcoded. Proper configuration actually ends up being somewhat
difficult, as the ideal case would be for each component to set up its own
configuration variables without its parent needing to be aware. For example,
<code class="language-plaintext highlighter-rouge">redis</code> could set up <code class="language-plaintext highlighter-rouge">addr</code> and <code class="language-plaintext highlighter-rouge">pool-size</code> parameters. The problem is that there
are two <code class="language-plaintext highlighter-rouge">redis</code> components in the program, and their parameters would therefore
conflict with each other. An elegant solution to this problem is discussed in
the next section.</p>

<h2 id="part-2-components-configuration-and-runtime">Part 2: Components, Configuration, and Runtime</h2>

<p>The key to the configuration problem is to recognize that, even if there are
two of the same component in a program, they can’t occupy the same place in the
program’s structure. In the above example, there are two <code class="language-plaintext highlighter-rouge">http</code> components: one
under <code class="language-plaintext highlighter-rouge">rest-api</code> and the other under <code class="language-plaintext highlighter-rouge">debug</code>. Because the structure is
represented as a tree of components, the “path” of any node in the tree
uniquely represents it in the structure. For example, the two <code class="language-plaintext highlighter-rouge">http</code> components
in the previous example have these paths:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>root -&gt; rest-api -&gt; http
root -&gt; debug -&gt; http
</code></pre></div></div>

<p>If each component were to know its place in the component tree, then it would
easily be able to ensure that its configuration and initialization didn’t
conflict with other components of the same type. If the <code class="language-plaintext highlighter-rouge">http</code> component sets
up a command-line parameter to know what address to listen on, the two <code class="language-plaintext highlighter-rouge">http</code>
components in that program would set up:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>--rest-api-listen-addr
--debug-listen-addr
</code></pre></div></div>

<p>So how can we enable each component to know its path in the component structure?
To answer this, we’ll have to take a detour through a type, called <code class="language-plaintext highlighter-rouge">Component</code>.</p>

<h3 id="component-and-configuration">Component and Configuration</h3>

<p>The <code class="language-plaintext highlighter-rouge">Component</code> type is a made-up type (though you’ll be able to find an
implementation of it at the end of this post). It has a single primary purpose,
and that is to convey the program’s structure to new components.</p>

<p>To see how this is done, let’s look at a couple of <code class="language-plaintext highlighter-rouge">Component</code>’s methods:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package mcmp</span>

<span class="c">// New returns a new Component which has no parents or children. It is therefore</span>
<span class="c">// the root component of a component hierarchy.</span>
<span class="k">func</span> <span class="n">New</span><span class="p">()</span> <span class="o">*</span><span class="n">Component</span>

<span class="c">// Child returns a new child of the called upon Component.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Child</span><span class="p">(</span><span class="n">name</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">Component</span>

<span class="c">// Path returns the Component's path in the component hierarchy. It will return</span>
<span class="c">// an empty slice if the Component is the root component.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Path</span><span class="p">()</span> <span class="p">[]</span><span class="kt">string</span>
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">Child</code> is used to create a new <code class="language-plaintext highlighter-rouge">Component</code>, corresponding to a new child node
in the component structure, and <code class="language-plaintext highlighter-rouge">Path</code> is used retrieve the path of any
<code class="language-plaintext highlighter-rouge">Component</code> within that structure. For the sake of keeping the examples simple,
let’s pretend these functions have been implemented in a package called <code class="language-plaintext highlighter-rouge">mcmp</code>.
Here’s an example of how <code class="language-plaintext highlighter-rouge">Component</code> might be used in the <code class="language-plaintext highlighter-rouge">redis</code> component’s
code:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package redis</span>

<span class="k">func</span> <span class="n">NewConn</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">defaultAddr</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="n">cmp</span> <span class="o">=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"redis"</span><span class="p">)</span>
    <span class="n">paramPrefix</span> <span class="o">:=</span> <span class="n">strings</span><span class="o">.</span><span class="n">Join</span><span class="p">(</span><span class="n">cmp</span><span class="o">.</span><span class="n">Path</span><span class="p">(),</span> <span class="s">"-"</span><span class="p">)</span>

    <span class="n">addrParam</span> <span class="o">:=</span> <span class="n">flag</span><span class="o">.</span><span class="n">String</span><span class="p">(</span><span class="n">paramPrefix</span><span class="o">+</span><span class="s">"-addr"</span><span class="p">,</span> <span class="n">defaultAddr</span><span class="p">,</span> <span class="s">"Address of redis instance to connect to"</span><span class="p">)</span>
    <span class="c">// finish setup</span>

    <span class="k">return</span> <span class="n">redisConn</span>
<span class="p">}</span>
</code></pre></div></div>

<p>In our above example, the two <code class="language-plaintext highlighter-rouge">redis</code> components’ parameters would be:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>// This first parameter is for the stats redis, whose parent is the root and
// therefore doesn't have a prefix. Perhaps stats should be broken into its own
// component in order to fix this.
--redis-addr
--rest-api-redis-addr
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">Component</code> definitely makes it easier to instantiate multiple redis components
in our program, since it allows them to know their place in the component
structure.</p>

<p>Having to construct the prefix for the parameters ourselves is pretty annoying,
so let’s introduce a new package, <code class="language-plaintext highlighter-rouge">mcfg</code>, which acts like <code class="language-plaintext highlighter-rouge">flag</code> but is aware
of <code class="language-plaintext highlighter-rouge">Component</code>. Then <code class="language-plaintext highlighter-rouge">redis.NewConn</code> is reduced to:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package redis</span>

<span class="k">func</span> <span class="n">NewConn</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">defaultAddr</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="n">cmp</span> <span class="o">=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"redis"</span><span class="p">)</span>
    <span class="n">addrParam</span> <span class="o">:=</span> <span class="n">mcfg</span><span class="o">.</span><span class="n">String</span><span class="p">(</span><span class="n">cmp</span><span class="p">,</span> <span class="s">"addr"</span><span class="p">,</span> <span class="n">defaultAddr</span><span class="p">,</span> <span class="s">"Address of redis instance to connect to"</span><span class="p">)</span>
    <span class="c">// finish setup</span>

    <span class="k">return</span> <span class="n">redisConn</span>
<span class="p">}</span>
</code></pre></div></div>

<p>Easy-peasy.</p>

<h4 id="but-what-about-parse">But What About Parse?</h4>

<p>Sharp-eyed gophers will notice that there is a key piece missing: When is
<code class="language-plaintext highlighter-rouge">flag.Parse</code>, or its <code class="language-plaintext highlighter-rouge">mcfg</code> counterpart, called? When does <code class="language-plaintext highlighter-rouge">addrParam</code> actually
get populated? It can’t happen inside <code class="language-plaintext highlighter-rouge">redis.NewConn</code> because there might be
other components after <code class="language-plaintext highlighter-rouge">redis.NewConn</code> that want to set up parameters. To
illustrate the problem, let’s look at a simple program that wants to set up two
<code class="language-plaintext highlighter-rouge">redis</code> components:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">main</span><span class="p">()</span> <span class="p">{</span>
    <span class="c">// Create the root Component, an empty Component.</span>
    <span class="n">cmp</span> <span class="o">:=</span> <span class="n">mcmp</span><span class="o">.</span><span class="n">New</span><span class="p">()</span>

    <span class="c">// Create the Components for two sub-components, foo and bar.</span>
    <span class="n">cmpFoo</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"foo"</span><span class="p">)</span>
    <span class="n">cmpBar</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"bar"</span><span class="p">)</span>

    <span class="c">// Now we want to try to create a redis sub-component for each component.</span>

    <span class="c">// This will set up the parameter "--foo-redis-addr", but bar hasn't had a</span>
    <span class="c">// chance to set up its corresponding parameter, so the command-line can't</span>
    <span class="c">// be parsed yet.</span>
    <span class="n">fooRedis</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="n">cmpFoo</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// This will set up the parameter "--bar-redis-addr", but, as mentioned</span>
    <span class="c">// before, redis.NewConn can't parse command-line.</span>
    <span class="n">barRedis</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">NewConn</span><span class="p">(</span><span class="n">cmpBar</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// It is only after all components have been instantiated that the</span>
    <span class="c">// command-line arguments can be parsed</span>
    <span class="n">mcfg</span><span class="o">.</span><span class="n">Parse</span><span class="p">()</span>
<span class="p">}</span>
</code></pre></div></div>

<p>While this solves our argument parsing problem, fooRedis and barRedis are not
usable yet because the actual connections have not been made. This is a classic
chicken and the egg problem. The func <code class="language-plaintext highlighter-rouge">redis.NewConn</code> needs to make a connection
which it cannot do until <em>after</em> <code class="language-plaintext highlighter-rouge">mcfg.Parse</code> is called, but <code class="language-plaintext highlighter-rouge">mcfg.Parse</code> cannot
be called until after <code class="language-plaintext highlighter-rouge">redis.NewConn</code> has returned. We will solve this problem
in the next section.</p>

<h3 id="instantiation-vs-initialization">Instantiation vs Initialization</h3>

<p>Let’s break down <code class="language-plaintext highlighter-rouge">redis.NewConn</code> into two phases: instantiation and
initialization. Instantiation refers to creating the component on the component
structure and having it declare what it needs in order to initialize (e.g.,
configuration parameters). During instantiation, nothing external to the
program is performed; no IO, no reading of the command-line, no logging, etc.
All that’s happened is that the empty template of a <code class="language-plaintext highlighter-rouge">redis</code> component has been
created.</p>

<p>Initialization is the phase during which the template is filled in.
Configuration parameters are read, startup actions like the creation of database
connections are performed, and logging is output for informational and debugging
purposes.</p>

<p>The key to making effective use of this dichotomy is to allow <em>all</em> components
to instantiate themselves before they initialize themselves. By doing this we
can ensure, for example, that all components have had the chance to declare
their configuration parameters before configuration parsing is done.</p>

<p>So let’s modify <code class="language-plaintext highlighter-rouge">redis.NewConn</code> so that it follows this dichotomy. It makes
sense to leave instantiation-related code where it is, but we need a mechanism
by which we can declare initialization code before actually calling it. For
this, I will introduce the idea of a “hook.”</p>

<h4 id="but-first-augment-component">But First: Augment Component</h4>

<p>In order to support hooks, however, <code class="language-plaintext highlighter-rouge">Component</code> will need to be augmented with
a few new methods. Right now, it can only carry with it information about the
component structure, but here we will add the ability to carry arbitrary
key/value information as well:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package mcmp</span>

<span class="c">// SetValue sets the given key to the given value on the Component, overwriting</span>
<span class="c">// any previous value for that key.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">SetValue</span><span class="p">(</span><span class="n">key</span><span class="p">,</span> <span class="n">value</span> <span class="k">interface</span><span class="p">{})</span>

<span class="c">// Value returns the value which has been set for the given key, or nil if the</span>
<span class="c">// key was never set.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Value</span><span class="p">(</span><span class="n">key</span> <span class="k">interface</span><span class="p">{})</span> <span class="k">interface</span><span class="p">{}</span>

<span class="c">// Children returns the Component's children in the order they were created.</span>
<span class="k">func</span> <span class="p">(</span><span class="o">*</span><span class="n">Component</span><span class="p">)</span> <span class="n">Children</span><span class="p">()</span> <span class="p">[]</span><span class="o">*</span><span class="n">Component</span>
</code></pre></div></div>

<p>The final method allows us to, starting at the root <code class="language-plaintext highlighter-rouge">Component</code>, traverse the
component structure and interact with each <code class="language-plaintext highlighter-rouge">Component</code>’s key/value store. This
will be useful for implementing hooks.</p>

<h4 id="hooks">Hooks</h4>

<p>A hook is simply a function that will run later. We will declare a new package,
calling it <code class="language-plaintext highlighter-rouge">mrun</code>, and say that it has two new functions:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package mrun</span>

<span class="c">// InitHook registers the given hook to the given Component.</span>
<span class="k">func</span> <span class="n">InitHook</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">hook</span> <span class="k">func</span><span class="p">())</span>

<span class="c">// Init runs all hooks registered using InitHook. Hooks are run in the order</span>
<span class="c">// they were registered.</span>
<span class="k">func</span> <span class="n">Init</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">)</span>
</code></pre></div></div>

<p>With these two functions, we are able to defer the initialization phase of
startup by using the same <code class="language-plaintext highlighter-rouge">Components</code> we were passing around for the purpose
of denoting component structure.</p>

<p>Now, with these few extra pieces of functionality in place, let’s reconsider the
most recent example, and make a program that creates two redis components which
exist independently of each other:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package redis</span>

<span class="c">// NOTE that NewConn has been renamed to InstConn, to reflect that the returned</span>
<span class="c">// *RedisConn is merely instantiated, not initialized.</span>

<span class="k">func</span> <span class="n">InstConn</span><span class="p">(</span><span class="n">cmp</span> <span class="o">*</span><span class="n">mcmp</span><span class="o">.</span><span class="n">Component</span><span class="p">,</span> <span class="n">defaultAddr</span> <span class="kt">string</span><span class="p">)</span> <span class="o">*</span><span class="n">RedisConn</span> <span class="p">{</span>
    <span class="n">cmp</span> <span class="o">=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"redis"</span><span class="p">)</span>

    <span class="c">// we instantiate an empty RedisConn instance and parameters for it. Neither</span>
    <span class="c">// has been initialized yet. They will remain empty until initialization has</span>
    <span class="c">// occurred.</span>
    <span class="n">redisConn</span> <span class="o">:=</span> <span class="nb">new</span><span class="p">(</span><span class="n">RedisConn</span><span class="p">)</span>
    <span class="n">addrParam</span> <span class="o">:=</span> <span class="n">mcfg</span><span class="o">.</span><span class="n">String</span><span class="p">(</span><span class="n">cmp</span><span class="p">,</span> <span class="s">"addr"</span><span class="p">,</span> <span class="n">defaultAddr</span><span class="p">,</span> <span class="s">"Address of redis instance to connect to"</span><span class="p">)</span>

    <span class="n">mrun</span><span class="o">.</span><span class="n">InitHook</span><span class="p">(</span><span class="n">cmp</span><span class="p">,</span> <span class="k">func</span><span class="p">()</span> <span class="p">{</span>
        <span class="c">// This hook will run after parameter initialization has happened, and</span>
        <span class="c">// so addrParam will be usable. Once this hook as run, redisConn will be</span>
        <span class="c">// usable as well.</span>
        <span class="o">*</span><span class="n">redisConn</span> <span class="o">=</span> <span class="n">makeRedisConnection</span><span class="p">(</span><span class="o">*</span><span class="n">addrParam</span><span class="p">)</span>
    <span class="p">})</span>

    <span class="c">// Now that cmp has had configuration parameters and intialization hooks</span>
    <span class="c">// set into it, return the empty redisConn instance back to the parent.</span>
    <span class="k">return</span> <span class="n">redisConn</span>
<span class="p">}</span>
</code></pre></div></div>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">// Package main</span>

<span class="k">func</span> <span class="n">main</span><span class="p">()</span> <span class="p">{</span>
    <span class="c">// Create the root Component, an empty Component.</span>
    <span class="n">cmp</span> <span class="o">:=</span> <span class="n">mcmp</span><span class="o">.</span><span class="n">New</span><span class="p">()</span>

    <span class="c">// Create the Components for two sub-components, foo and bar.</span>
    <span class="n">cmpFoo</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"foo"</span><span class="p">)</span>
    <span class="n">cmpBar</span> <span class="o">:=</span> <span class="n">cmp</span><span class="o">.</span><span class="n">Child</span><span class="p">(</span><span class="s">"bar"</span><span class="p">)</span>

    <span class="c">// Add redis components to each of the foo and bar sub-components.</span>
    <span class="n">redisFoo</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">InstConn</span><span class="p">(</span><span class="n">cmpFoo</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>
    <span class="n">redisBar</span> <span class="o">:=</span> <span class="n">redis</span><span class="o">.</span><span class="n">InstConn</span><span class="p">(</span><span class="n">cmpBar</span><span class="p">,</span> <span class="s">"127.0.0.1:6379"</span><span class="p">)</span>

    <span class="c">// Parse will descend into the Component and all of its children,</span>
    <span class="c">// discovering all registered configuration parameters and filling them from</span>
    <span class="c">// the command-line.</span>
    <span class="n">mcfg</span><span class="o">.</span><span class="n">Parse</span><span class="p">(</span><span class="n">cmp</span><span class="p">)</span>

    <span class="c">// Now that configuration parameters have been initialized, run the Init</span>
    <span class="c">// hooks for all Components.</span>
    <span class="n">mrun</span><span class="o">.</span><span class="n">Init</span><span class="p">(</span><span class="n">cmp</span><span class="p">)</span>

    <span class="c">// At this point the redis components have been fully initialized and may be</span>
    <span class="c">// used. For this example we'll copy all keys from one to the other.</span>
    <span class="n">keys</span> <span class="o">:=</span> <span class="n">redisFoo</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"KEYS"</span><span class="p">,</span> <span class="s">"*"</span><span class="p">)</span>
    <span class="k">for</span> <span class="n">i</span> <span class="o">:=</span> <span class="k">range</span> <span class="n">keys</span> <span class="p">{</span>
        <span class="n">val</span> <span class="o">:=</span> <span class="n">redisFoo</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"GET"</span><span class="p">,</span> <span class="n">keys</span><span class="p">[</span><span class="n">i</span><span class="p">])</span>
        <span class="n">redisBar</span><span class="o">.</span><span class="n">Command</span><span class="p">(</span><span class="s">"SET"</span><span class="p">,</span> <span class="n">keys</span><span class="p">[</span><span class="n">i</span><span class="p">],</span> <span class="n">val</span><span class="p">)</span>
    <span class="p">}</span>
<span class="p">}</span>
</code></pre></div></div>

<h2 id="conclusion">Conclusion</h2>

<p>While the examples given here are fairly simplistic, the pattern itself is quite
powerful. Codebases naturally accumulate small, domain-specific behaviors and
optimizations over time, especially around the IO components of the program.
Databases are used with specific options that an organization finds useful,
logging is performed in particular places, metrics are counted around certain
pieces of code, etc.</p>

<p>By programming with component structure in mind, we are able to keep these
optimizations while also keeping the clarity and compartmentalization of the
code intact. We can keep our code flexible and configurable, while also
re-usable and testable. Also, the simplicity of the tools involved means they
can be extended and retrofitted for nearly any situation or use-case.</p>

<p>Overall, this is a powerful pattern that I’ve found myself unable to do without
once I began using it.</p>

<h3 id="implementation">Implementation</h3>

<p>As a final note, you can find an example implementation of the packages
described in this post here:</p>

<ul>
  <li><a href="https://godoc.org/github.com/mediocregopher/mediocre-go-lib/mcmp">mcmp</a></li>
  <li><a href="https://godoc.org/github.com/mediocregopher/mediocre-go-lib/mcfg">mcfg</a></li>
  <li><a href="https://godoc.org/github.com/mediocregopher/mediocre-go-lib/mrun">mrun</a></li>
</ul>

<p>The packages are not stable and are likely to change frequently. You’ll also
find that they have been extended quite a bit from the simple descriptions found
here, based on what I’ve found useful as I’ve implemented programs using
component structures. With these two points in mind, I would encourage you to
look and take whatever functionality you find useful for yourself, and not use
the packages directly. The core pieces are not different from what has been
described in this post.</p>
