
+++
title = "Loops in Ginger"
date = 2021-04-27T00:00:00.000Z
template = "html_content/raw.html"
summary = """
In previous posts in this series I went over the general idea of the ginger
programming language, an..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/04/27/loops-in-ginger.html"
raw = """
<p>In previous posts in this series I went over the general idea of the ginger
programming language, and some of its properties. To recap:</p>

<ul>
  <li>
    <p>Ginger is a programming language whose syntax defines a directed graph, in the
same way that a LISP language’s syntax defines nested lists.</p>
  </li>
  <li>
    <p>Graph edges indicate an operation, while nodes indicate a value.</p>
  </li>
  <li>
    <p>The special values <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code> are used when interpreting a graph as a
function.</p>
  </li>
  <li>
    <p>A special node type, the tuple, is defined as being a node whose value is an
ordered set of input edges.</p>
  </li>
  <li>
    <p>Another special node type, the fork, is the complement to the tuple. A fork is
defined as being a node whose value is an ordered set of output edges.</p>
  </li>
  <li>
    <p>The special <code class="language-plaintext highlighter-rouge">if</code> operation accepts a 2-tuple, the first value being some state
value and the second being a tuple. The <code class="language-plaintext highlighter-rouge">if</code> operation expects to be directed
towards a 2-fork. If the boolean is true then the top output edge of the fork
is taken, otherwise the bottom is taken. The state value is what’s passed to
the taken edge.</p>
  </li>
</ul>

<p>There were some other detail rules but I don’t remember them off the top of my
head.</p>

<h2 id="loops">Loops</h2>

<p>Today I’d like to go over my ideas for how loops would work in ginger. With
loops established ginger would officially be a Turing complete language and,
given time and energy, real work could actually begin on it.</p>

<p>As with conditionals I’ll start by establishing a base example. Let’s say we’d
like to define an operation which prints out numbers from 0 up to <code class="language-plaintext highlighter-rouge">n</code>, where <code class="language-plaintext highlighter-rouge">n</code>
is given as an argument. In go this would look like:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">printRange</span><span class="p">(</span><span class="n">n</span> <span class="kt">int</span><span class="p">)</span> <span class="kt">int</span> <span class="p">{</span>
    <span class="k">for</span> <span class="n">i</span> <span class="o">:=</span> <span class="m">0</span><span class="p">;</span> <span class="n">i</span> <span class="o">&lt;</span> <span class="n">n</span><span class="p">;</span> <span class="n">i</span><span class="o">++</span> <span class="p">{</span>
        <span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">i</span><span class="p">)</span>
    <span class="p">}</span>
<span class="p">}</span>
</code></pre></div></div>

<p>With that established, let’s start looking at different patterns.</p>

<h2 id="goto">Goto</h2>

<p>In the olden days the primary looping construct was <code class="language-plaintext highlighter-rouge">goto</code>, which essentially
teleports the program counter (aka instruction pointer) to another place in the
execution stack. Pretty much any other looping construct can be derived from
<code class="language-plaintext highlighter-rouge">goto</code> and some kind of conditional, so it’s a good starting place when
considering loops in ginger.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(in -println-&gt; } -incr-&gt; out) -&gt; println-incr

0  -&gt; }    -&gt; } -if-&gt; { -&gt; out
in -&gt; } -eq-&gt; }       { -&gt; } -upd-&gt; } -+
      ^               0 -&gt; }           |
      |    println-incr -&gt; }           |
      |                                |
      +--------------------------------+
</code></pre></div></div>

<p>(Note: the <code class="language-plaintext highlighter-rouge">upd</code> operation is used here for convenience. It takes in three
arguments: A tuple, an index, and an operation. It applies the operation to the
tuple element at the given index, and returns a new tuple with that index set to
the value returned.)</p>

<p>Here <code class="language-plaintext highlighter-rouge">goto</code> is performed using a literal arrow going from the right to left.
it’s ugly and hard to write, and would only be moreso the more possible gotos an
operation has.</p>

<p>It also complicates our graphs in a significant way: up till now ginger graphs
have have always been directed <em>acyclic</em> graphs (DAGs), but by introducing this
construct we allow that graphs might be cyclic. It’s not immediately clear to me
what the consequences of this will be, but I’m sure they will be great. If
nothign else it will make the compiler much more complex, as each value can no
longer be defined in terms of its input edge, as that edge might resolve back to
the value itself.</p>

<p>While conceptually sound, I think this strategy fails the practability test. We
can do better.</p>

<h2 id="while">While</h2>

<p>The <code class="language-plaintext highlighter-rouge">while</code> construct is the basic looping primitive of iterative languages
(some call it <code class="language-plaintext highlighter-rouge">for</code>, but they’re just lying to themselves).</p>

<p>Try as I might, I can’t come up with a way to make <code class="language-plaintext highlighter-rouge">while</code> work with ginger.
<code class="language-plaintext highlighter-rouge">while</code> ultimately relies on scoped variables being updated in place to
function, while ginger is based on the concept of pipelining a set of values
through a series of operations. From the point of view of the programmer these
operations are essentially immutable, so the requirement of a variable which can
be updated in place cannot be met.</p>

<h2 id="recur">Recur</h2>

<p>This pattern is based on how many functional languages, for example erlang,
handle looping. Rather than introducing new primitives around looping, these
language instead ensure that tail calls are properly optimized and uses those
instead. So loops are implemented as recursive function calls.</p>

<p>For ginger to do this it would make sense to introduce a new special value,
<code class="language-plaintext highlighter-rouge">recur</code>, which could be used alongside <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code> within operations. When
the execution path hits a <code class="language-plaintext highlighter-rouge">recur</code> then it gets teleported back to the <code class="language-plaintext highlighter-rouge">in</code>
value, with the input to <code class="language-plaintext highlighter-rouge">recur</code> now being the output from <code class="language-plaintext highlighter-rouge">in</code>. Usage of it
would look like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(

    (in -println-&gt; } -incr-&gt; out) -&gt; println-incr

    in    -&gt; } -if-&gt; { -&gt; out
    in -eq-&gt; }       { -&gt; } -upd-&gt; } -&gt; recur
                     0 -&gt; }
          println-incr -&gt; }

) -&gt; inner-op

0  -&gt; } -inner-op-&gt; out
in -&gt; }
</code></pre></div></div>

<p>This looks pretty similar to the <code class="language-plaintext highlighter-rouge">goto</code> example overall, but with the major
difference that the looping body had to be wrapped into an inner operation. The
reason for this is that the outer operation only takes in one argument, <code class="language-plaintext highlighter-rouge">n</code>, but
the loop actually needs two pieces of state to function: <code class="language-plaintext highlighter-rouge">n</code> and the current
value. So the inner operation loops over these two pieces of state, and the
outer operation supplies <code class="language-plaintext highlighter-rouge">n</code> and an initial iteration value (<code class="language-plaintext highlighter-rouge">0</code>) to that inner
operation.</p>

<p>This seems cumbersome on the surface, but what other languages do (such as
erlang, which is the one I’m most familiar with) is to provide built-in macros
on top of this primitive which make it more pleasant to use. These include
function polymorphism and a more familiar <code class="language-plaintext highlighter-rouge">for</code> construct. With a decent macro
capability ginger could do the same.</p>

<p>The benefits here are that the graphs remain acyclic, and the syntax has not
been made more cumbersome. It follows conventions established by other
languages, and ensures the language will be capable of tail-recursion.</p>

<h2 id="mapreduce">Map/Reduce</h2>

<p>Another functional strategy which is useful is that of the map/reduce power
couple. The <code class="language-plaintext highlighter-rouge">map</code> operation takes a sequence of values and an operation, and
returns a sequence of the same length where the operation has been applied to
each value in the original sequence individually. The <code class="language-plaintext highlighter-rouge">reduce</code> operation is more
complicated (and not necessary for out example), but it’s essentially a
mechanism to turn a sequence of values into a single value.</p>

<p>For our example we only need <code class="language-plaintext highlighter-rouge">map</code>, plus one more helper operation: <code class="language-plaintext highlighter-rouge">range</code>.
<code class="language-plaintext highlighter-rouge">range</code> takes a number <code class="language-plaintext highlighter-rouge">n</code> and returns a sequence of numbers starting at <code class="language-plaintext highlighter-rouge">0</code> and
ending at <code class="language-plaintext highlighter-rouge">n-1</code>. Our print example now looks like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>in -range-&gt; } -map-&gt; out
 println -&gt; }
</code></pre></div></div>

<p>Very simple! Map/reduce is a well established pattern and is probably the
best way to construct functional programs. However, the question remains whether
these are the best <em>primitives</em> for looping, and I don’t believe they are. Both
<code class="language-plaintext highlighter-rouge">map</code> and <code class="language-plaintext highlighter-rouge">reduce</code> can be derived from conditional and looping primitives like
<code class="language-plaintext highlighter-rouge">if</code> and <code class="language-plaintext highlighter-rouge">recur</code>, and they can’t do some things that those primitives can. While</p>

<p>I expect one of the first things which will be done in ginger is to define <code class="language-plaintext highlighter-rouge">map</code>
and <code class="language-plaintext highlighter-rouge">reduce</code> in terms of <code class="language-plaintext highlighter-rouge">if</code> and a looping primitive, and use them generously
throughout the code, I think the fact that they can be defined in terms of
lower-level primitives indicates that they aren’t the right looping primitives
for ginger.</p>

<h2 id="conclusion">Conclusion</h2>

<p>Unlike with the conditionals posts, where I started out not really knowing what
I wanted to do with conditionals, I more or less knew where this post was going
from the beginning. <code class="language-plaintext highlighter-rouge">recur</code> is, in my mind, the best primitive for looping in
ginger. It provides the flexibility to be extended to any use-case, while not
complicating the structure of the language. While possibly cumbersome to
implement directly, <code class="language-plaintext highlighter-rouge">recur</code> can be used as a primitive to construct more
convenient looping operations like <code class="language-plaintext highlighter-rouge">map</code> and <code class="language-plaintext highlighter-rouge">reduce</code>.</p>

<p>As a final treat (lucky you!), here’s <code class="language-plaintext highlighter-rouge">map</code> defined using <code class="language-plaintext highlighter-rouge">if</code> and <code class="language-plaintext highlighter-rouge">recur</code>:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(
    in -0-&gt; mapped-seq
    in -1-&gt; orig-seq
    in -2-&gt; op

    mapped-seq -len-&gt; i

              mapped-seq -&gt; } -if-&gt; { -&gt; out
    orig-seq -len-&gt; } -eq-&gt; }       { -&gt; } -append-&gt; } -&gt; recur
               i -&gt; }                    }           }
                                         }           }
                   orig-seq -i-&gt; } -op-&gt; }           }
                                                     }
                                         orig-seq -&gt; }
                                               op -&gt; }
) -&gt; inner-map

  () -&gt; } -inner-map-&gt; out
in -0-&gt; }
in -1-&gt; }
</code></pre></div></div>

<p>The next step for ginger is going to be writing an actual implementation of the
graph structure in some other language (let’s be honest, it’ll be in go). After
that we’ll need a syntax definition which can be used to encode/decode that
structure, and from there we can start actually implementing the language!</p>"""

+++
<p>In previous posts in this series I went over the general idea of the ginger
programming language, and some of its properties. To recap:</p>

<ul>
  <li>
    <p>Ginger is a programming language whose syntax defines a directed graph, in the
same way that a LISP language’s syntax defines nested lists.</p>
  </li>
  <li>
    <p>Graph edges indicate an operation, while nodes indicate a value.</p>
  </li>
  <li>
    <p>The special values <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code> are used when interpreting a graph as a
function.</p>
  </li>
  <li>
    <p>A special node type, the tuple, is defined as being a node whose value is an
ordered set of input edges.</p>
  </li>
  <li>
    <p>Another special node type, the fork, is the complement to the tuple. A fork is
defined as being a node whose value is an ordered set of output edges.</p>
  </li>
  <li>
    <p>The special <code class="language-plaintext highlighter-rouge">if</code> operation accepts a 2-tuple, the first value being some state
value and the second being a tuple. The <code class="language-plaintext highlighter-rouge">if</code> operation expects to be directed
towards a 2-fork. If the boolean is true then the top output edge of the fork
is taken, otherwise the bottom is taken. The state value is what’s passed to
the taken edge.</p>
  </li>
</ul>

<p>There were some other detail rules but I don’t remember them off the top of my
head.</p>

<h2 id="loops">Loops</h2>

<p>Today I’d like to go over my ideas for how loops would work in ginger. With
loops established ginger would officially be a Turing complete language and,
given time and energy, real work could actually begin on it.</p>

<p>As with conditionals I’ll start by establishing a base example. Let’s say we’d
like to define an operation which prints out numbers from 0 up to <code class="language-plaintext highlighter-rouge">n</code>, where <code class="language-plaintext highlighter-rouge">n</code>
is given as an argument. In go this would look like:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">printRange</span><span class="p">(</span><span class="n">n</span> <span class="kt">int</span><span class="p">)</span> <span class="kt">int</span> <span class="p">{</span>
    <span class="k">for</span> <span class="n">i</span> <span class="o">:=</span> <span class="m">0</span><span class="p">;</span> <span class="n">i</span> <span class="o">&lt;</span> <span class="n">n</span><span class="p">;</span> <span class="n">i</span><span class="o">++</span> <span class="p">{</span>
        <span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">i</span><span class="p">)</span>
    <span class="p">}</span>
<span class="p">}</span>
</code></pre></div></div>

<p>With that established, let’s start looking at different patterns.</p>

<h2 id="goto">Goto</h2>

<p>In the olden days the primary looping construct was <code class="language-plaintext highlighter-rouge">goto</code>, which essentially
teleports the program counter (aka instruction pointer) to another place in the
execution stack. Pretty much any other looping construct can be derived from
<code class="language-plaintext highlighter-rouge">goto</code> and some kind of conditional, so it’s a good starting place when
considering loops in ginger.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(in -println-&gt; } -incr-&gt; out) -&gt; println-incr

0  -&gt; }    -&gt; } -if-&gt; { -&gt; out
in -&gt; } -eq-&gt; }       { -&gt; } -upd-&gt; } -+
      ^               0 -&gt; }           |
      |    println-incr -&gt; }           |
      |                                |
      +--------------------------------+
</code></pre></div></div>

<p>(Note: the <code class="language-plaintext highlighter-rouge">upd</code> operation is used here for convenience. It takes in three
arguments: A tuple, an index, and an operation. It applies the operation to the
tuple element at the given index, and returns a new tuple with that index set to
the value returned.)</p>

<p>Here <code class="language-plaintext highlighter-rouge">goto</code> is performed using a literal arrow going from the right to left.
it’s ugly and hard to write, and would only be moreso the more possible gotos an
operation has.</p>

<p>It also complicates our graphs in a significant way: up till now ginger graphs
have have always been directed <em>acyclic</em> graphs (DAGs), but by introducing this
construct we allow that graphs might be cyclic. It’s not immediately clear to me
what the consequences of this will be, but I’m sure they will be great. If
nothign else it will make the compiler much more complex, as each value can no
longer be defined in terms of its input edge, as that edge might resolve back to
the value itself.</p>

<p>While conceptually sound, I think this strategy fails the practability test. We
can do better.</p>

<h2 id="while">While</h2>

<p>The <code class="language-plaintext highlighter-rouge">while</code> construct is the basic looping primitive of iterative languages
(some call it <code class="language-plaintext highlighter-rouge">for</code>, but they’re just lying to themselves).</p>

<p>Try as I might, I can’t come up with a way to make <code class="language-plaintext highlighter-rouge">while</code> work with ginger.
<code class="language-plaintext highlighter-rouge">while</code> ultimately relies on scoped variables being updated in place to
function, while ginger is based on the concept of pipelining a set of values
through a series of operations. From the point of view of the programmer these
operations are essentially immutable, so the requirement of a variable which can
be updated in place cannot be met.</p>

<h2 id="recur">Recur</h2>

<p>This pattern is based on how many functional languages, for example erlang,
handle looping. Rather than introducing new primitives around looping, these
language instead ensure that tail calls are properly optimized and uses those
instead. So loops are implemented as recursive function calls.</p>

<p>For ginger to do this it would make sense to introduce a new special value,
<code class="language-plaintext highlighter-rouge">recur</code>, which could be used alongside <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code> within operations. When
the execution path hits a <code class="language-plaintext highlighter-rouge">recur</code> then it gets teleported back to the <code class="language-plaintext highlighter-rouge">in</code>
value, with the input to <code class="language-plaintext highlighter-rouge">recur</code> now being the output from <code class="language-plaintext highlighter-rouge">in</code>. Usage of it
would look like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(

    (in -println-&gt; } -incr-&gt; out) -&gt; println-incr

    in    -&gt; } -if-&gt; { -&gt; out
    in -eq-&gt; }       { -&gt; } -upd-&gt; } -&gt; recur
                     0 -&gt; }
          println-incr -&gt; }

) -&gt; inner-op

0  -&gt; } -inner-op-&gt; out
in -&gt; }
</code></pre></div></div>

<p>This looks pretty similar to the <code class="language-plaintext highlighter-rouge">goto</code> example overall, but with the major
difference that the looping body had to be wrapped into an inner operation. The
reason for this is that the outer operation only takes in one argument, <code class="language-plaintext highlighter-rouge">n</code>, but
the loop actually needs two pieces of state to function: <code class="language-plaintext highlighter-rouge">n</code> and the current
value. So the inner operation loops over these two pieces of state, and the
outer operation supplies <code class="language-plaintext highlighter-rouge">n</code> and an initial iteration value (<code class="language-plaintext highlighter-rouge">0</code>) to that inner
operation.</p>

<p>This seems cumbersome on the surface, but what other languages do (such as
erlang, which is the one I’m most familiar with) is to provide built-in macros
on top of this primitive which make it more pleasant to use. These include
function polymorphism and a more familiar <code class="language-plaintext highlighter-rouge">for</code> construct. With a decent macro
capability ginger could do the same.</p>

<p>The benefits here are that the graphs remain acyclic, and the syntax has not
been made more cumbersome. It follows conventions established by other
languages, and ensures the language will be capable of tail-recursion.</p>

<h2 id="mapreduce">Map/Reduce</h2>

<p>Another functional strategy which is useful is that of the map/reduce power
couple. The <code class="language-plaintext highlighter-rouge">map</code> operation takes a sequence of values and an operation, and
returns a sequence of the same length where the operation has been applied to
each value in the original sequence individually. The <code class="language-plaintext highlighter-rouge">reduce</code> operation is more
complicated (and not necessary for out example), but it’s essentially a
mechanism to turn a sequence of values into a single value.</p>

<p>For our example we only need <code class="language-plaintext highlighter-rouge">map</code>, plus one more helper operation: <code class="language-plaintext highlighter-rouge">range</code>.
<code class="language-plaintext highlighter-rouge">range</code> takes a number <code class="language-plaintext highlighter-rouge">n</code> and returns a sequence of numbers starting at <code class="language-plaintext highlighter-rouge">0</code> and
ending at <code class="language-plaintext highlighter-rouge">n-1</code>. Our print example now looks like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>in -range-&gt; } -map-&gt; out
 println -&gt; }
</code></pre></div></div>

<p>Very simple! Map/reduce is a well established pattern and is probably the
best way to construct functional programs. However, the question remains whether
these are the best <em>primitives</em> for looping, and I don’t believe they are. Both
<code class="language-plaintext highlighter-rouge">map</code> and <code class="language-plaintext highlighter-rouge">reduce</code> can be derived from conditional and looping primitives like
<code class="language-plaintext highlighter-rouge">if</code> and <code class="language-plaintext highlighter-rouge">recur</code>, and they can’t do some things that those primitives can. While</p>

<p>I expect one of the first things which will be done in ginger is to define <code class="language-plaintext highlighter-rouge">map</code>
and <code class="language-plaintext highlighter-rouge">reduce</code> in terms of <code class="language-plaintext highlighter-rouge">if</code> and a looping primitive, and use them generously
throughout the code, I think the fact that they can be defined in terms of
lower-level primitives indicates that they aren’t the right looping primitives
for ginger.</p>

<h2 id="conclusion">Conclusion</h2>

<p>Unlike with the conditionals posts, where I started out not really knowing what
I wanted to do with conditionals, I more or less knew where this post was going
from the beginning. <code class="language-plaintext highlighter-rouge">recur</code> is, in my mind, the best primitive for looping in
ginger. It provides the flexibility to be extended to any use-case, while not
complicating the structure of the language. While possibly cumbersome to
implement directly, <code class="language-plaintext highlighter-rouge">recur</code> can be used as a primitive to construct more
convenient looping operations like <code class="language-plaintext highlighter-rouge">map</code> and <code class="language-plaintext highlighter-rouge">reduce</code>.</p>

<p>As a final treat (lucky you!), here’s <code class="language-plaintext highlighter-rouge">map</code> defined using <code class="language-plaintext highlighter-rouge">if</code> and <code class="language-plaintext highlighter-rouge">recur</code>:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(
    in -0-&gt; mapped-seq
    in -1-&gt; orig-seq
    in -2-&gt; op

    mapped-seq -len-&gt; i

              mapped-seq -&gt; } -if-&gt; { -&gt; out
    orig-seq -len-&gt; } -eq-&gt; }       { -&gt; } -append-&gt; } -&gt; recur
               i -&gt; }                    }           }
                                         }           }
                   orig-seq -i-&gt; } -op-&gt; }           }
                                                     }
                                         orig-seq -&gt; }
                                               op -&gt; }
) -&gt; inner-map

  () -&gt; } -inner-map-&gt; out
in -0-&gt; }
in -1-&gt; }
</code></pre></div></div>

<p>The next step for ginger is going to be writing an actual implementation of the
graph structure in some other language (let’s be honest, it’ll be in go). After
that we’ll need a syntax definition which can be used to encode/decode that
structure, and from there we can start actually implementing the language!</p>
