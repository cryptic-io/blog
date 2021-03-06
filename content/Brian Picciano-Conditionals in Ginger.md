
+++
title = "Conditionals in Ginger"
date = 2021-03-01T00:00:00.000Z
template = "html_content/raw.html"
summary = """
In the last ginger post I covered a broad overview of how I envisioned
ginger would work as a langua..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/03/01/conditionals-in-ginger.html"
raw = """
<p>In the <a href="/2021/01/09/ginger.html">last ginger post</a> I covered a broad overview of how I envisioned
ginger would work as a language, but there were two areas where I felt there was
some uncertainty: conditionals and loops. In this post I will be focusing on
conditionals, and going over a couple of options for how they could work.</p>

<h2 id="preface">Preface</h2>

<p>By “conditional” I’m referring to what programmers generally know as the “if”
statement; some mechanism by which code can do one thing or another based on
circumstances at runtime. Without some form of a conditional a programming
language is not Turing-complete and can’t be used for anything interesting.</p>

<p>Given that it’s uncommon to have a loop without some kind of a conditional
inside of it (usually to exit the loop), but it’s quite common to have a
conditional with no loop in sight, it makes more sense to cover conditionals
before loops. Whatever decision is reached regarding conditionals will impact
how loops work, but not necessarily the other way around.</p>

<p>For the duration of this post I will be attempting to construct a simple
operation which takes two integers as arguments. If the first is less than
the second then the operation returns the addition of the two, otherwise the
operation returns the second subtracted from the first. In <code class="language-plaintext highlighter-rouge">go</code> this operation
would look like:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">op</span><span class="p">(</span><span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="kt">int</span><span class="p">)</span> <span class="kt">int</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">a</span> <span class="o">&lt;</span> <span class="n">b</span> <span class="p">{</span>
        <span class="k">return</span> <span class="n">a</span> <span class="o">+</span> <span class="n">b</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="n">b</span> <span class="o">-</span> <span class="n">a</span>
<span class="p">}</span>
</code></pre></div></div>

<h2 id="pattern-1-branches-as-inputs">Pattern 1: Branches As Inputs</h2>

<p>The pattern I’ll lay out here is simultaneously the first pattern which came to
me when trying to figure this problem out, the pattern which is most like
existing mainstream programming languages, and (in my opinion) the worst pattern
of the bunch. Here is what it looks like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>        in -lt-&gt; } -if-&gt; out
                 }
       in -add-&gt; }
                 }
in -1-&gt; }        }
in -0-&gt; } -sub-&gt; }

</code></pre></div></div>

<p>The idea here is that the operation <code class="language-plaintext highlighter-rouge">if</code> could take a 3-tuple whose elements
are, respectively: a boolean, and two other edges which won’t be evaluated until
<code class="language-plaintext highlighter-rouge">if</code> is evaluated. If the boolean is true then <code class="language-plaintext highlighter-rouge">if</code> outputs the output of the
first edge (the second element in the tuple), and otherwise it will output the
value of the second edge.</p>

<p>This idea doesn’t work for a couple reasons. The biggest is that, if there were
multiple levels of <code class="language-plaintext highlighter-rouge">if</code> statements, the structure of the graph grows out
<em>leftward</em>, whereas the flow of data is rightwards. For someone reading the code
to know what <code class="language-plaintext highlighter-rouge">if</code> will produce in either case they must first backtrack through
the graph, find the origin of that branch, then track that leftward once again
to the <code class="language-plaintext highlighter-rouge">if</code>.</p>

<p>The other reason this doesn’t work is because it doesn’t jive with any pattern
for loops I’ve come up with. This isn’t evident from this particular example,
but consider what this would look like if either branch of the <code class="language-plaintext highlighter-rouge">if</code> needed to
loop back to a previous point in the codepath. If that’s a difficult or
confusing task for you, you’re not alone.</p>

<h2 id="pattern-2-pattern-matching">Pattern 2: Pattern Matching</h2>

<p>There’s quite a few languages with pattern matching, and even one which I know
of (erlang) where pattern matching is the primary form of conditionals, and the
more common <code class="language-plaintext highlighter-rouge">if</code> statement is just some syntactic sugar on top of the pattern
matching.</p>

<p>I’ve considered pattern matching for ginger. It might look something like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -switch-&gt; } -&gt; {{{A, B}, _}, ({A,B}-lt-&gt;out)} -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }           } -1-&gt; } -sub-&gt; out
in -0-&gt; }
</code></pre></div></div>

<p>The <code class="language-plaintext highlighter-rouge">switch</code> operation posits that a node can have multiple output edges. In a
graph this is fine, but it’s worth noting. Graphs tend to be implemented such
that edges to and from a node are unordered, but in ginger it seems unlikely
that that will be the case.</p>

<p>The last output edge from the switch is the easiest to explain: it outputs the
input value to <code class="language-plaintext highlighter-rouge">switch</code> when no other branches are able to be taken. But the
input to <code class="language-plaintext highlighter-rouge">switch</code> is a bit complex in this example: It’s a 2-tuple whose first
element is <code class="language-plaintext highlighter-rouge">in</code>, and whose second element is <code class="language-plaintext highlighter-rouge">in</code> but with reversed elements.
In the last output edge we immediately pipe into a <code class="language-plaintext highlighter-rouge">1</code> operation to retrieve
that second element and call <code class="language-plaintext highlighter-rouge">sub</code> on that, since that’s the required behavior
of the example.</p>

<p>All other branches (in this switch there is only one, the first branch) output
to a value. The form of this value is a tuple (denoted by enclosed curly braces
here) of two values. The first value is the pattern itself, and the second is an
optional predicate. The pattern in this example will match a 2-tuple, ignoring
the second element in that tuple. The first element will itself be matched
against a 2-tuple, and assign each element to the variables <code class="language-plaintext highlighter-rouge">A</code> and <code class="language-plaintext highlighter-rouge">B</code>,
respectively. The second element in the tuple, the predicate, is a sub-graph
which returns a boolean, and can be used for further specificity which can’t be
covered by the pattern matching (in this case, comparing the two values to each
other).</p>

<p>The output from any of <code class="language-plaintext highlighter-rouge">switch</code>’s branches is the same as its input value, the
only question is which branch is taken. This means that there’s no backtracking
when reading a program using this pattern; no matter where you’re looking you
will only have to keep reading rightward to come to an <code class="language-plaintext highlighter-rouge">out</code>.</p>

<p>There’s a few drawbacks with this approach. The first is that it’s not actually
very easy to read. While pattern matching can be a really nice feature in
languages that design around it, I’ve never seen it used in a LISP-style
language where the syntax denotes actual datastructures, and I feel that in such
a context it’s a bit unwieldy. I could be wrong.</p>

<p>The second drawback is that pattern matching is not simple to implement, and I’m
not even sure what it would look like in a language where graphs are the primary
datastructure. In the above example we’re only matching into a tuple, but how
would you format the pattern for a multi-node, multi-edge graph? Perhaps it’s
possible. But given that any such system could be implemented as a macro on top
of normal <code class="language-plaintext highlighter-rouge">if</code> statements, rather than doing it the other way around, it seems
better to start with the simpler option.</p>

<p>(I haven’t talked about it yet, but I’d like for ginger to be portable to
multiple backends (i.e. different processor architectures, vms, etc). If the
builtins of the language are complex, then doing this will be a difficult task,
whereas if I’m conscious of that goal during design I think it can be made to be
very simple. In that light I’d prefer to not require pattern matching to be a
builtin.)</p>

<p>The third drawback is that the input to the <code class="language-plaintext highlighter-rouge">switch</code> requires careful ordering,
especially in cases like this one where a different value is needed depending on
which branch is taken. I don’t consider this to be a huge drawback, as
encourages good data design and is a common consideration in other functional
languages.</p>

<h2 id="pattern-3-branches-as-outputs">Pattern 3: Branches As Outputs</h2>

<p>Taking a cue from the pattern matching example, we can go back to <code class="language-plaintext highlighter-rouge">if</code> and take
advantage of multiple output edges being a possibility:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -if-&gt; } -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }       } -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>It’s not perfect, but I’d say this is the nicest of the three options so far.
<code class="language-plaintext highlighter-rouge">if</code> is an operation which takes a 2-tuple. The second element of the tuple is a
boolean, if the boolean is true then <code class="language-plaintext highlighter-rouge">if</code> passes the first element of its tuple
to the first branch, otherwise it passes it to the second. In this way <code class="language-plaintext highlighter-rouge">if</code>
becomes kind of like a fork in a train track: it accepts some payload (the first
element of its input tuple) and depending on conditions (the second element) it
directs the payload one way or the other.</p>

<p>This pattern retains the benefits of the pattern matching example, where one
never needs to backtrack in order to understand what is about to happen next,
while also being much more readable and simpler to implement. It also retains
one of the drawbacks of the pattern matching example, in that the inputs to <code class="language-plaintext highlighter-rouge">if</code>
must be carefully organized based on the needs of the output branches. As
before, I don’t consider this to be a huge drawback.</p>

<p>There’s other modifications which might be made to this <code class="language-plaintext highlighter-rouge">if</code> to make it even
cleaner, e.g. one could make it accept a 3-tuple, rather than a 2-tuple, in
order to supply differing values to be used depending on which branch is taken.
To me these sorts of small niceties are better left to be implemented as macros,
built on top of a simpler but less pleasant builtin.</p>

<h2 id="fin">Fin</h2>

<p>If you have other ideas around how conditionals might be done in a graph-based
language please <a href="mailto:mediocregopher@gmail.com">email me</a>; any and all contributions are welcome! One
day I’ll get around to actually implementing some of ginger, but today is not
that day.</p>"""

+++
<p>In the <a href="/2021/01/09/ginger.html">last ginger post</a> I covered a broad overview of how I envisioned
ginger would work as a language, but there were two areas where I felt there was
some uncertainty: conditionals and loops. In this post I will be focusing on
conditionals, and going over a couple of options for how they could work.</p>

<h2 id="preface">Preface</h2>

<p>By “conditional” I’m referring to what programmers generally know as the “if”
statement; some mechanism by which code can do one thing or another based on
circumstances at runtime. Without some form of a conditional a programming
language is not Turing-complete and can’t be used for anything interesting.</p>

<p>Given that it’s uncommon to have a loop without some kind of a conditional
inside of it (usually to exit the loop), but it’s quite common to have a
conditional with no loop in sight, it makes more sense to cover conditionals
before loops. Whatever decision is reached regarding conditionals will impact
how loops work, but not necessarily the other way around.</p>

<p>For the duration of this post I will be attempting to construct a simple
operation which takes two integers as arguments. If the first is less than
the second then the operation returns the addition of the two, otherwise the
operation returns the second subtracted from the first. In <code class="language-plaintext highlighter-rouge">go</code> this operation
would look like:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">func</span> <span class="n">op</span><span class="p">(</span><span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="kt">int</span><span class="p">)</span> <span class="kt">int</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">a</span> <span class="o">&lt;</span> <span class="n">b</span> <span class="p">{</span>
        <span class="k">return</span> <span class="n">a</span> <span class="o">+</span> <span class="n">b</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="n">b</span> <span class="o">-</span> <span class="n">a</span>
<span class="p">}</span>
</code></pre></div></div>

<h2 id="pattern-1-branches-as-inputs">Pattern 1: Branches As Inputs</h2>

<p>The pattern I’ll lay out here is simultaneously the first pattern which came to
me when trying to figure this problem out, the pattern which is most like
existing mainstream programming languages, and (in my opinion) the worst pattern
of the bunch. Here is what it looks like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>        in -lt-&gt; } -if-&gt; out
                 }
       in -add-&gt; }
                 }
in -1-&gt; }        }
in -0-&gt; } -sub-&gt; }

</code></pre></div></div>

<p>The idea here is that the operation <code class="language-plaintext highlighter-rouge">if</code> could take a 3-tuple whose elements
are, respectively: a boolean, and two other edges which won’t be evaluated until
<code class="language-plaintext highlighter-rouge">if</code> is evaluated. If the boolean is true then <code class="language-plaintext highlighter-rouge">if</code> outputs the output of the
first edge (the second element in the tuple), and otherwise it will output the
value of the second edge.</p>

<p>This idea doesn’t work for a couple reasons. The biggest is that, if there were
multiple levels of <code class="language-plaintext highlighter-rouge">if</code> statements, the structure of the graph grows out
<em>leftward</em>, whereas the flow of data is rightwards. For someone reading the code
to know what <code class="language-plaintext highlighter-rouge">if</code> will produce in either case they must first backtrack through
the graph, find the origin of that branch, then track that leftward once again
to the <code class="language-plaintext highlighter-rouge">if</code>.</p>

<p>The other reason this doesn’t work is because it doesn’t jive with any pattern
for loops I’ve come up with. This isn’t evident from this particular example,
but consider what this would look like if either branch of the <code class="language-plaintext highlighter-rouge">if</code> needed to
loop back to a previous point in the codepath. If that’s a difficult or
confusing task for you, you’re not alone.</p>

<h2 id="pattern-2-pattern-matching">Pattern 2: Pattern Matching</h2>

<p>There’s quite a few languages with pattern matching, and even one which I know
of (erlang) where pattern matching is the primary form of conditionals, and the
more common <code class="language-plaintext highlighter-rouge">if</code> statement is just some syntactic sugar on top of the pattern
matching.</p>

<p>I’ve considered pattern matching for ginger. It might look something like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -switch-&gt; } -&gt; {{{A, B}, _}, ({A,B}-lt-&gt;out)} -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }           } -1-&gt; } -sub-&gt; out
in -0-&gt; }
</code></pre></div></div>

<p>The <code class="language-plaintext highlighter-rouge">switch</code> operation posits that a node can have multiple output edges. In a
graph this is fine, but it’s worth noting. Graphs tend to be implemented such
that edges to and from a node are unordered, but in ginger it seems unlikely
that that will be the case.</p>

<p>The last output edge from the switch is the easiest to explain: it outputs the
input value to <code class="language-plaintext highlighter-rouge">switch</code> when no other branches are able to be taken. But the
input to <code class="language-plaintext highlighter-rouge">switch</code> is a bit complex in this example: It’s a 2-tuple whose first
element is <code class="language-plaintext highlighter-rouge">in</code>, and whose second element is <code class="language-plaintext highlighter-rouge">in</code> but with reversed elements.
In the last output edge we immediately pipe into a <code class="language-plaintext highlighter-rouge">1</code> operation to retrieve
that second element and call <code class="language-plaintext highlighter-rouge">sub</code> on that, since that’s the required behavior
of the example.</p>

<p>All other branches (in this switch there is only one, the first branch) output
to a value. The form of this value is a tuple (denoted by enclosed curly braces
here) of two values. The first value is the pattern itself, and the second is an
optional predicate. The pattern in this example will match a 2-tuple, ignoring
the second element in that tuple. The first element will itself be matched
against a 2-tuple, and assign each element to the variables <code class="language-plaintext highlighter-rouge">A</code> and <code class="language-plaintext highlighter-rouge">B</code>,
respectively. The second element in the tuple, the predicate, is a sub-graph
which returns a boolean, and can be used for further specificity which can’t be
covered by the pattern matching (in this case, comparing the two values to each
other).</p>

<p>The output from any of <code class="language-plaintext highlighter-rouge">switch</code>’s branches is the same as its input value, the
only question is which branch is taken. This means that there’s no backtracking
when reading a program using this pattern; no matter where you’re looking you
will only have to keep reading rightward to come to an <code class="language-plaintext highlighter-rouge">out</code>.</p>

<p>There’s a few drawbacks with this approach. The first is that it’s not actually
very easy to read. While pattern matching can be a really nice feature in
languages that design around it, I’ve never seen it used in a LISP-style
language where the syntax denotes actual datastructures, and I feel that in such
a context it’s a bit unwieldy. I could be wrong.</p>

<p>The second drawback is that pattern matching is not simple to implement, and I’m
not even sure what it would look like in a language where graphs are the primary
datastructure. In the above example we’re only matching into a tuple, but how
would you format the pattern for a multi-node, multi-edge graph? Perhaps it’s
possible. But given that any such system could be implemented as a macro on top
of normal <code class="language-plaintext highlighter-rouge">if</code> statements, rather than doing it the other way around, it seems
better to start with the simpler option.</p>

<p>(I haven’t talked about it yet, but I’d like for ginger to be portable to
multiple backends (i.e. different processor architectures, vms, etc). If the
builtins of the language are complex, then doing this will be a difficult task,
whereas if I’m conscious of that goal during design I think it can be made to be
very simple. In that light I’d prefer to not require pattern matching to be a
builtin.)</p>

<p>The third drawback is that the input to the <code class="language-plaintext highlighter-rouge">switch</code> requires careful ordering,
especially in cases like this one where a different value is needed depending on
which branch is taken. I don’t consider this to be a huge drawback, as
encourages good data design and is a common consideration in other functional
languages.</p>

<h2 id="pattern-3-branches-as-outputs">Pattern 3: Branches As Outputs</h2>

<p>Taking a cue from the pattern matching example, we can go back to <code class="language-plaintext highlighter-rouge">if</code> and take
advantage of multiple output edges being a possibility:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -if-&gt; } -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }       } -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>It’s not perfect, but I’d say this is the nicest of the three options so far.
<code class="language-plaintext highlighter-rouge">if</code> is an operation which takes a 2-tuple. The second element of the tuple is a
boolean, if the boolean is true then <code class="language-plaintext highlighter-rouge">if</code> passes the first element of its tuple
to the first branch, otherwise it passes it to the second. In this way <code class="language-plaintext highlighter-rouge">if</code>
becomes kind of like a fork in a train track: it accepts some payload (the first
element of its input tuple) and depending on conditions (the second element) it
directs the payload one way or the other.</p>

<p>This pattern retains the benefits of the pattern matching example, where one
never needs to backtrack in order to understand what is about to happen next,
while also being much more readable and simpler to implement. It also retains
one of the drawbacks of the pattern matching example, in that the inputs to <code class="language-plaintext highlighter-rouge">if</code>
must be carefully organized based on the needs of the output branches. As
before, I don’t consider this to be a huge drawback.</p>

<p>There’s other modifications which might be made to this <code class="language-plaintext highlighter-rouge">if</code> to make it even
cleaner, e.g. one could make it accept a 3-tuple, rather than a 2-tuple, in
order to supply differing values to be used depending on which branch is taken.
To me these sorts of small niceties are better left to be implemented as macros,
built on top of a simpler but less pleasant builtin.</p>

<h2 id="fin">Fin</h2>

<p>If you have other ideas around how conditionals might be done in a graph-based
language please <a href="mailto:mediocregopher@gmail.com">email me</a>; any and all contributions are welcome! One
day I’ll get around to actually implementing some of ginger, but today is not
that day.</p>
