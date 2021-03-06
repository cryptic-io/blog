
+++
title = "Conditionals in Ginger, Errata"
date = 2021-03-04T00:00:00.000Z
template = "html_content/raw.html"
summary = """
After publishing the last post in the series I walked away from my computer
feeling that I was very ..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/03/04/conditionals-in-ginger-errata.html"
raw = """
<p>After publishing the last post in the series I walked away from my computer
feeling that I was very clever and had made a good post. This was incorrect.</p>

<p>To summarize <a href="/2021/03/01/conditionals-in-ginger.html">the previous post</a>, it’s not obvious which is the best way
to structure conditionals in a graphical programming language. My favorite
solution looked something like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -if-&gt; } -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }       } -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>Essentially an <code class="language-plaintext highlighter-rouge">if</code> operator which accepts a value and a boolean, and which has
two output edges. If the boolean is true then the input value is sent along the
first output edge, and if it’s false it’s sent along the second.</p>

<p>This structure is not possible, given the properties of ginger graphs that have
been laid out in <a href="/2021/01/09/ginger.html">other posts in the series</a>.</p>

<h2 id="nodes-tuples-and-edges">Nodes, Tuples, and Edges</h2>

<p>A ginger graph, as it has been presented so far, is composed of these three
elements. A node has a value, and its value is unique to the graph; if two nodes
have the same value then they are the same node. Edges connect two nodes or
tuples together, and have a value and direction. Tuples are, in essence, a node
whose value is its input edges.</p>

<p>The <code class="language-plaintext highlighter-rouge">if</code> operation above lies on an edge, not a node or tuple. It cannot have
multiple output edges, since it cannot have any edges at all. It <em>is</em> an edge.</p>

<p>So it’s back to the drawing board, to some extent. But luckily I’ve got some
more ideas in my back pocket.</p>

<h2 id="forks-and-junctions">Forks and Junctions</h2>

<p>In an older conception of ginger there was no tuple, but instead there were
forks and junctions. A junction was essentially the same as a tuple, just named
differently: a node whose value is its input edges. A fork was just the
opposite, a node whose value is its output edges. Junctions and forks naturally
complimented each other, but ultimately I didn’t find forks to be useful for
much because there weren’t cases where it was necessary to have a single edge be
split across multiple output edges directly; any case which appeared to require
a fork could be satisfied by directing the edge into a 1-tuple and using the
output edges of the 1-tuple.</p>

<p>But now we have such a case. The 1-tuple won’t work, because the <code class="language-plaintext highlighter-rouge">if</code> operator
would only see the 1-tuple, not its edges. It could be supposed that the graph
interpreter could say that an <code class="language-plaintext highlighter-rouge">if</code> operation must be followed by a 1-tuple, and
that the 1-tuple’s output edges have a special meaning in that circumstance. But
making the output edges of a 1-tuple have different meaning in different
circumstances isn’t very elegant.</p>

<p>So a fork might be just the thing here. For the example I will represent a
fork as the opposite of a tuple: a vertical column of <code class="language-plaintext highlighter-rouge">{</code> characters.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -if-&gt; { -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }       { -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>It <em>looks</em> elegant, which is nice. I am curious though if there’s any other
possible use-case where a fork might be useful… if there’s not then it seems
odd to introduce an entire new element just to support a single operation. Why
not just make that operation itself the new element?</p>

<h2 id="switch-it-up">Switch it Up</h2>

<p>In most conceptions of a flowchart that I’ve seen a conditional is usually
represented as a node with a different shape than the other nodes (often a
diamond). Ginger could borrow this idea for itself, and declare a new graph
element, alongside nodes, tuples, and edges, called a switch.</p>

<p>Let’s say a switch is simply represented by a <code class="language-plaintext highlighter-rouge">-&lt;&gt;</code>, and acts like a node in all
aspects except that it has no value and is not unique to the graph.</p>

<p>The example presented in the <a href="/2021/03/01/conditionals-in-ginger.html">previous post</a> would look something like
this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -&lt;&gt; -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }     -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>This isn’t the <em>worst</em>. Like the fork it’s adding a new element, but that
element’s existence is required and its usage is very specific to that
requirement, whereas the fork’s existence is required but ambiguously useful
outside of that requirement.</p>

<p>On the other hand, there are macros to consider…</p>

<h2 id="macrophillic">Macrophillic</h2>

<p>Ginger will certainly support macros, and as alluded to in the last post I’d
like even conditional operations to be fair game for those who want to construct
their own more complex operators. In the context of the switch <code class="language-plaintext highlighter-rouge">-&lt;&gt;</code> element,
would someone be able to create something like a pattern matching conditional?
If the builtin conditional is implemented as a new graph element then it seems
that the primary way to implement a custom conditional macro will also involve a
new graph element.</p>

<p>While I’m not flat out opposed to allowing for custom graph elements, I’m
extremely skeptical that it’s necessary, and would like it to be proven
necessary before considering it. So if we can have a basic conditional, <em>and</em>
custom conditional macros built on top of the same broadly useful element, that
seems like the better strategy.</p>

<p>So all of that said, it seems I’m leaning towards forks as the better strategy
in this. But I’d like a different name. “Fork” was nice as being the compliment
of a “junction”, but I like “tuple” way more than “junction” because the term
applies well both to the structural element <em>and</em> to the transformation that
element performs (i.e. a tuple element combines its input edges’ values into a
tuple value). But “tuple” and “fork” seem weird together…</p>

<h2 id="many-minutes-later">Many Minutes Later…</h2>

<p>A brief search of the internet reveals no better word than “fork”. A place
where a tree’s trunk splits into two separate trunks is called a “fork”. A
place where a river splits into two separate rivers is called a “fork”.
Similarly with roads. And that <em>is</em> what’s happening, from the point of view of
the graph’s structure: it is an element whose only purpose is to denote multiple
outward edges.</p>

<p>So “fork” it is.</p>

<h2 id="other-considerations">Other considerations</h2>

<p>A 1-tuple is interesting in that it acts essentially as a concatenation of two
edges. A 1-fork could, theoretically, do the same thing:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>a -foo-&gt; } -bar-&gt; b

c -far-&gt; { -boo-&gt; d
</code></pre></div></div>

<p>The top uses a tuple, the bottom a fork. Each is, conceptually, valid, but I
don’t like that two different elements can be used for the exact same use-case.</p>

<p>A 1-tuple is an established concept in data structures, so I am loath to give it
up.  A 1-fork, on the other hand, doesn’t make sense structurally (would you
point to any random point on a river and call it a “1-fork”?), and fork as a
whole doesn’t really have any analog in the realm of data structures. So I’m
prepared to declare 1-forks invalid from the viewpoint of the language
interpreter.</p>

<p>Another consideration: I already expect that there’s going to be confusion as to
when to use a fork and when to use multiple outputs from a node. For example,
here’s a graph which uses a fork:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>a -&gt; { -op1-&gt; foo
     { -op2-&gt; bar
</code></pre></div></div>

<p>and here’s a graph which has multiple outputs from the same node:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>a -op1-&gt; foo
  -op2-&gt; bar
</code></pre></div></div>

<p>Each could be interpreted to mean the same thing: “set <code class="language-plaintext highlighter-rouge">foo</code> to the result of
passing <code class="language-plaintext highlighter-rouge">a</code> into <code class="language-plaintext highlighter-rouge">op1</code>, and set <code class="language-plaintext highlighter-rouge">bar</code> to the result of passing <code class="language-plaintext highlighter-rouge">a</code> into <code class="language-plaintext highlighter-rouge">op2</code>.”
As with the 1-tuple vs 1-fork issue, we have another case where the same
task might be accomplished with two different patterns. This case is trickier
though, and I don’t have as confident an answer.</p>

<p>I think an interim rule which could be put in place, subject to review later, is
that multiple edges from a node or tuple indicate that that same value is being
used for multiple operations, while a fork indicates something specific to the
operation on its input edge. It’s not a pretty rule, but I think it will do.</p>

<p>Stay tuned for next week when I realize that actually all of this is wrong and
we start over again!</p>"""

+++
<p>After publishing the last post in the series I walked away from my computer
feeling that I was very clever and had made a good post. This was incorrect.</p>

<p>To summarize <a href="/2021/03/01/conditionals-in-ginger.html">the previous post</a>, it’s not obvious which is the best way
to structure conditionals in a graphical programming language. My favorite
solution looked something like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -if-&gt; } -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }       } -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>Essentially an <code class="language-plaintext highlighter-rouge">if</code> operator which accepts a value and a boolean, and which has
two output edges. If the boolean is true then the input value is sent along the
first output edge, and if it’s false it’s sent along the second.</p>

<p>This structure is not possible, given the properties of ginger graphs that have
been laid out in <a href="/2021/01/09/ginger.html">other posts in the series</a>.</p>

<h2 id="nodes-tuples-and-edges">Nodes, Tuples, and Edges</h2>

<p>A ginger graph, as it has been presented so far, is composed of these three
elements. A node has a value, and its value is unique to the graph; if two nodes
have the same value then they are the same node. Edges connect two nodes or
tuples together, and have a value and direction. Tuples are, in essence, a node
whose value is its input edges.</p>

<p>The <code class="language-plaintext highlighter-rouge">if</code> operation above lies on an edge, not a node or tuple. It cannot have
multiple output edges, since it cannot have any edges at all. It <em>is</em> an edge.</p>

<p>So it’s back to the drawing board, to some extent. But luckily I’ve got some
more ideas in my back pocket.</p>

<h2 id="forks-and-junctions">Forks and Junctions</h2>

<p>In an older conception of ginger there was no tuple, but instead there were
forks and junctions. A junction was essentially the same as a tuple, just named
differently: a node whose value is its input edges. A fork was just the
opposite, a node whose value is its output edges. Junctions and forks naturally
complimented each other, but ultimately I didn’t find forks to be useful for
much because there weren’t cases where it was necessary to have a single edge be
split across multiple output edges directly; any case which appeared to require
a fork could be satisfied by directing the edge into a 1-tuple and using the
output edges of the 1-tuple.</p>

<p>But now we have such a case. The 1-tuple won’t work, because the <code class="language-plaintext highlighter-rouge">if</code> operator
would only see the 1-tuple, not its edges. It could be supposed that the graph
interpreter could say that an <code class="language-plaintext highlighter-rouge">if</code> operation must be followed by a 1-tuple, and
that the 1-tuple’s output edges have a special meaning in that circumstance. But
making the output edges of a 1-tuple have different meaning in different
circumstances isn’t very elegant.</p>

<p>So a fork might be just the thing here. For the example I will represent a
fork as the opposite of a tuple: a vertical column of <code class="language-plaintext highlighter-rouge">{</code> characters.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -if-&gt; { -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }       { -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>It <em>looks</em> elegant, which is nice. I am curious though if there’s any other
possible use-case where a fork might be useful… if there’s not then it seems
odd to introduce an entire new element just to support a single operation. Why
not just make that operation itself the new element?</p>

<h2 id="switch-it-up">Switch it Up</h2>

<p>In most conceptions of a flowchart that I’ve seen a conditional is usually
represented as a node with a different shape than the other nodes (often a
diamond). Ginger could borrow this idea for itself, and declare a new graph
element, alongside nodes, tuples, and edges, called a switch.</p>

<p>Let’s say a switch is simply represented by a <code class="language-plaintext highlighter-rouge">-&lt;&gt;</code>, and acts like a node in all
aspects except that it has no value and is not unique to the graph.</p>

<p>The example presented in the <a href="/2021/03/01/conditionals-in-ginger.html">previous post</a> would look something like
this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>       in -&gt; } -&gt; } -&lt;&gt; -0-&gt; } -add-&gt; out
in -1-&gt; } -&gt; }    }     -1-&gt; } -sub-&gt; out
in -0-&gt; }         }
                  }
         in -lt-&gt; }
</code></pre></div></div>

<p>This isn’t the <em>worst</em>. Like the fork it’s adding a new element, but that
element’s existence is required and its usage is very specific to that
requirement, whereas the fork’s existence is required but ambiguously useful
outside of that requirement.</p>

<p>On the other hand, there are macros to consider…</p>

<h2 id="macrophillic">Macrophillic</h2>

<p>Ginger will certainly support macros, and as alluded to in the last post I’d
like even conditional operations to be fair game for those who want to construct
their own more complex operators. In the context of the switch <code class="language-plaintext highlighter-rouge">-&lt;&gt;</code> element,
would someone be able to create something like a pattern matching conditional?
If the builtin conditional is implemented as a new graph element then it seems
that the primary way to implement a custom conditional macro will also involve a
new graph element.</p>

<p>While I’m not flat out opposed to allowing for custom graph elements, I’m
extremely skeptical that it’s necessary, and would like it to be proven
necessary before considering it. So if we can have a basic conditional, <em>and</em>
custom conditional macros built on top of the same broadly useful element, that
seems like the better strategy.</p>

<p>So all of that said, it seems I’m leaning towards forks as the better strategy
in this. But I’d like a different name. “Fork” was nice as being the compliment
of a “junction”, but I like “tuple” way more than “junction” because the term
applies well both to the structural element <em>and</em> to the transformation that
element performs (i.e. a tuple element combines its input edges’ values into a
tuple value). But “tuple” and “fork” seem weird together…</p>

<h2 id="many-minutes-later">Many Minutes Later…</h2>

<p>A brief search of the internet reveals no better word than “fork”. A place
where a tree’s trunk splits into two separate trunks is called a “fork”. A
place where a river splits into two separate rivers is called a “fork”.
Similarly with roads. And that <em>is</em> what’s happening, from the point of view of
the graph’s structure: it is an element whose only purpose is to denote multiple
outward edges.</p>

<p>So “fork” it is.</p>

<h2 id="other-considerations">Other considerations</h2>

<p>A 1-tuple is interesting in that it acts essentially as a concatenation of two
edges. A 1-fork could, theoretically, do the same thing:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>a -foo-&gt; } -bar-&gt; b

c -far-&gt; { -boo-&gt; d
</code></pre></div></div>

<p>The top uses a tuple, the bottom a fork. Each is, conceptually, valid, but I
don’t like that two different elements can be used for the exact same use-case.</p>

<p>A 1-tuple is an established concept in data structures, so I am loath to give it
up.  A 1-fork, on the other hand, doesn’t make sense structurally (would you
point to any random point on a river and call it a “1-fork”?), and fork as a
whole doesn’t really have any analog in the realm of data structures. So I’m
prepared to declare 1-forks invalid from the viewpoint of the language
interpreter.</p>

<p>Another consideration: I already expect that there’s going to be confusion as to
when to use a fork and when to use multiple outputs from a node. For example,
here’s a graph which uses a fork:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>a -&gt; { -op1-&gt; foo
     { -op2-&gt; bar
</code></pre></div></div>

<p>and here’s a graph which has multiple outputs from the same node:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>a -op1-&gt; foo
  -op2-&gt; bar
</code></pre></div></div>

<p>Each could be interpreted to mean the same thing: “set <code class="language-plaintext highlighter-rouge">foo</code> to the result of
passing <code class="language-plaintext highlighter-rouge">a</code> into <code class="language-plaintext highlighter-rouge">op1</code>, and set <code class="language-plaintext highlighter-rouge">bar</code> to the result of passing <code class="language-plaintext highlighter-rouge">a</code> into <code class="language-plaintext highlighter-rouge">op2</code>.”
As with the 1-tuple vs 1-fork issue, we have another case where the same
task might be accomplished with two different patterns. This case is trickier
though, and I don’t have as confident an answer.</p>

<p>I think an interim rule which could be put in place, subject to review later, is
that multiple edges from a node or tuple indicate that that same value is being
used for multiple operations, while a fork indicates something specific to the
operation on its input edge. It’s not a pretty rule, but I think it will do.</p>

<p>Stay tuned for next week when I realize that actually all of this is wrong and
we start over again!</p>
