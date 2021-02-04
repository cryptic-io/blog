
+++
title = "Ginger"
originalLink = "https://blog.mediocregopher.com/2021/01/09/ginger.html"
date = 2021-01-09T00:00:00.000Z
template = "html_content/raw.html"
summary = """
This post is about a programming language that’s been bouncing around in my head
for a long time. I’..."""

[extra]
author = "Brian Picciano"
raw = """
<p>This post is about a programming language that’s been bouncing around in my head
for a <em>long</em> time. I’ve tried to actually implement the language three or more
times now, but everytime I get stuck or run out of steam. It doesn’t help that
everytime I try again the form of the language changes significantly. But all
throughout the name of the language has always been “Ginger”. It’s a good name.</p>

<p>In the last few years the form of the language has somewhat solidified in my
head, so in lieu of actually working on it I’m going to talk about what it
currently looks like.</p>

<h2 id="abstract-syntax-lists">Abstract Syntax Lists</h2>

<p><em>In the beginning</em> there was assembly. Well, really in the beginning there were
punchcards, and probably something even more esoteric before that, but it was
all effectively the same thing: a list of commands the computer would execute
sequentially, with the ability to jump to odd places in the sequence depending
on conditions at runtime. For the purpose of this post, we’ll call this class of
languages “abstract syntax list” (ASL) languages.</p>

<p>Here’s a hello world program in my favorite ASL language, brainfuck:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>\u002B\u002B\u002B\u002B\u002B\u002B++[&gt;\u002B\u002B\u002B+[&gt;++&gt;\u002B\u002B\u002B&gt;\u002B\u002B\u002B&gt;+&lt;&lt;&lt;&lt;-]&gt;+&gt;+&gt;-&gt;&gt;+[&lt;]&lt;-]&gt;&gt;.&gt;---.\u002B\u002B\u002B\u002B\u002B\u002B+..\u002B\u002B\u002B.&gt;&gt;.&lt;-.&lt;.++
+.------.--------.&gt;&gt;+.&gt;++.
</code></pre></div></div>

<p>(If you’ve never seen brainfuck, it’s deliberately unintelligible. But it <em>is</em>
an ASL, each character representing a single command, executed by the brainfuck
runtime from left to right.)</p>

<p>ASLs did the job at the time, but luckily we’ve mostly moved on past them.</p>

<h2 id="abstract-syntax-trees">Abstract Syntax Trees</h2>

<p>Eventually programmers upgraded to C-like languages. Rather than a sequence of
commands, these languages were syntactically represented by an “abstract syntax
tree” (AST). Rather than executing commands in essentially the same order they
are written, an AST language compiler reads the syntax into a tree of syntax
nodes. What it then does with the tree is language dependent.</p>

<p>Here’s a program which outputs all numbers from 0 to 9 to stdout, written in
(slightly non-idiomatic) Go:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">i</span> <span class="o">:=</span> <span class="m">0</span>
<span class="k">for</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">i</span> <span class="o">==</span> <span class="m">10</span> <span class="p">{</span>
        <span class="k">break</span>
    <span class="p">}</span>
    <span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">i</span><span class="p">)</span>
    <span class="n">i</span><span class="o">++</span>
<span class="p">}</span>
</code></pre></div></div>

<p>When the Go compiler sees this, it’s going to first parse the syntax into an
AST. The AST might look something like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(root)
   |-(:=)
   |   |-(i)
   |   |-(0)
   |
   |-(for)
       |-(if)
       |  |-(==)
       |  |  |-(i)
       |  |  |-(10)
       |  |
       |  |-(break)
       |
       |-(fmt.Println)
       |       |-(i)
       |
       |-(++)
           |-(i)
</code></pre></div></div>

<p>Each of the non-leaf nodes in the tree represents an operation, and the children
of the node represent the arguments to that operation, if any. From here the
compiler traverses the tree depth-first in order to turn each operation it finds
into the appropriate machine code.</p>

<p>There’s a sub-class of AST languages called the LISP (“LISt Processor”)
languages. In a LISP language the AST is represented using lists of elements,
where the first element in each list denotes the operation and the rest of the
elements in the list (if any) represent the arguments. Traditionally each list
is represented using parenthesis. For example <code class="language-plaintext highlighter-rouge">(+ 1 1)</code> represents adding 1 and
1 together.</p>

<p>As a more complex example, here’s how to print numbers 0 through 9 to stdout
using my favorite (and, honestly, only) LISP, Clojure:</p>

<div class="language-clj highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="p">(</span><span class="nb">doseq</span><span class="w">
    </span><span class="p">[</span><span class="n">n</span><span class="w"> </span><span class="p">(</span><span class="nb">range</span><span class="w"> </span><span class="mi">10</span><span class="p">)]</span><span class="w">
    </span><span class="p">(</span><span class="nb">println</span><span class="w"> </span><span class="n">n</span><span class="p">))</span><span class="w">
</span></code></pre></div></div>

<p>Much smaller, but the idea is there. In LISPs there is no differentiation
between the syntax, the AST, and the language’s data structures; they are all
one and the same. For this reason LISPs generally have very powerful macro
support, wherein one uses code written in the language to transform code written
in that same language. With macros users can extend a language’s functionality
to support nearly anything they need to, but because macro generation happens
<em>before</em> compilation they can still reap the benefits of compiler optimizations.</p>

<h3 id="ast-pitfalls">AST Pitfalls</h3>

<p>The ASL (assembly) is essentially just a thin layer of human readability on top
of raw CPU instructions. It does nothing in the way of representing code in the
way that humans actually think about it (relationships of types, flow of data,
encapsulation of behavior). The AST is a step towards expressing code in human
terms, but it isn’t quite there in my opinion. Let me show why by revisiting the
Go example above:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">i</span> <span class="o">:=</span> <span class="m">0</span>
<span class="k">for</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">i</span> <span class="o">&gt;</span> <span class="m">9</span> <span class="p">{</span>
        <span class="k">break</span>
    <span class="p">}</span>
    <span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">i</span><span class="p">)</span>
    <span class="n">i</span><span class="o">++</span>
<span class="p">}</span>
</code></pre></div></div>

<p>When I understand this code I don’t understand it in terms of its syntax. I
understand it in terms of what it <em>does</em>. And what it does is this:</p>

<ul>
  <li>with a number starting at 0, start a loop.</li>
  <li>if the number is greater than 9, stop the loop.</li>
  <li>otherwise, print the number.</li>
  <li>add one to the number.</li>
  <li>go to start of loop.</li>
</ul>

<p>This behavior could be further abstracted into the original problem statement,
“it prints numbers 0 through 9 to stdout”, but that’s too general, as there
are different ways for that to be accomplished. The Clojure example first
defines a list of numbers 0 through 9 and then iterates over that, rather than
looping over a single number. These differences are important when understanding
what code is doing.</p>

<p>So what’s the problem? My problem with ASTs is that the syntax I’ve written down
does <em>not</em> reflect the structure of the code or the flow of data which is in my
head. In the AST representation if you want to follow the flow of data (a single
number) you <em>have</em> to understand the semantic meaning of <code class="language-plaintext highlighter-rouge">i</code> and <code class="language-plaintext highlighter-rouge">:=</code>; the AST
structure itself does not convey how data is being moved or modified.
Essentially, there’s an extra implicit transformation that must be done to
understand the code in human terms.</p>

<h2 id="ginger-an-abstract-syntax-graph-language">Ginger: An Abstract Syntax Graph Language</h2>

<p>In my view the next step is towards using graphs rather than trees for
representing our code. A graph has the benefit of being able to reference
“backwards” into itself, where a tree cannot, and so can represent the flow of
data much more directly.</p>

<p>I would like Ginger to be an ASG language where the language is the graph,
similar to a LISP. But what does this look like exactly? Well, I have a good
idea about what the graph <em>structure</em> will be like and how it will function, but
the syntax is something I haven’t bothered much with yet. Representing graph
structures in a text file is a problem to be tackled all on its own. For this
post we’ll use a made-up, overly verbose, and probably non-usable syntax, but
hopefully it will convey the graph structure well enough.</p>

<h3 id="nodes-edges-and-tuples">Nodes, Edges, and Tuples</h3>

<p>All graphs have nodes, where each node contains a value. A single unique value
can only have a single node in a graph. Nodes are connected by edges, where
edges have a direction and can contain a value themselves.</p>

<p>In the context of Ginger, a node represents a value as expected, and the value
on an edge represents an operation to take on that value. For example:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>5 -incr-&gt; n
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">5</code> and <code class="language-plaintext highlighter-rouge">n</code> are both nodes in the graph, with an edge going from <code class="language-plaintext highlighter-rouge">5</code> to <code class="language-plaintext highlighter-rouge">n</code> that
has the value <code class="language-plaintext highlighter-rouge">incr</code>. When it comes time to interpret the graph we say that the
value of <code class="language-plaintext highlighter-rouge">n</code> can be calculated by giving <code class="language-plaintext highlighter-rouge">5</code> as the input to the operation
<code class="language-plaintext highlighter-rouge">incr</code> (increment). In other words, the value of <code class="language-plaintext highlighter-rouge">n</code> is <code class="language-plaintext highlighter-rouge">6</code>.</p>

<p>What about operations which have more than one input value? For this Ginger
introduces the tuple to its graph type. A tuple is like a node, except that it’s
anonymous, which allows more than one to exist within the same graph, as they do
not share the same value. For the purposes of this blog post we’ll represent
tuples like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -add-&gt; t
2 -&gt; }
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">t</code>’s value is the result of passing a tuple of two values, <code class="language-plaintext highlighter-rouge">1</code> and <code class="language-plaintext highlighter-rouge">2</code>, as
inputs to the operation <code class="language-plaintext highlighter-rouge">add</code>. In other words, the value of <code class="language-plaintext highlighter-rouge">t</code> is <code class="language-plaintext highlighter-rouge">3</code>.</p>

<p>For the syntax being described in this post we allow that a single contiguous
graph can be represented as multiple related sections. This can be done because
each node’s value is unique, so when the same value is used in disparate
sections we can merge the two sections on that value. For example, the following
two graphs are exactly equivalent (note the parenthesis wrapping the graph which
has been split):</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -add-&gt; t -incr-&gt; tt
2 -&gt; }
</code></pre></div></div>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(
    1 -&gt; } -add-&gt; t
    2 -&gt; }

    t -incr-&gt; tt
)
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">tt</code> is <code class="language-plaintext highlighter-rouge">4</code> in both cases.)</p>

<p>A tuple with only one input edge, a 1-tuple, is a no-op, semantically, but can
be useful structurally to chain multiple operations together without defining
new value names. In the above example the <code class="language-plaintext highlighter-rouge">t</code> value can be eliminated using a
1-tuple.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -add-&gt; } -incr-&gt; tt
2 -&gt; }
</code></pre></div></div>

<p>When an integer is used as an operation on a tuple value then the effect is to
output the value in the tuple at that index. For example:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -0-&gt; } -incr-&gt; t
2 -&gt; }
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">t</code> is <code class="language-plaintext highlighter-rouge">2</code>.)</p>

<h3 id="operations">Operations</h3>

<p>When a value sits on an edge it is used as an operation on the input of that
edge. Some operations will no doubt be builtin, like <code class="language-plaintext highlighter-rouge">add</code>, but users should be
able to define their own operations. This can be done using the <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code>
special values. When a graph is used as an operation it is scanned for both <code class="language-plaintext highlighter-rouge">in</code>
and <code class="language-plaintext highlighter-rouge">out</code> values. <code class="language-plaintext highlighter-rouge">in</code> is set to the input value of the operation, and the value
of <code class="language-plaintext highlighter-rouge">out</code> is used as the output of the operation.</p>

<p>Here we will define the <code class="language-plaintext highlighter-rouge">incr</code> operation and then use it. Note that we set the
<code class="language-plaintext highlighter-rouge">incr</code> value to be an entire sub-graph which represents the operation’s body.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>( in -&gt; } -add-&gt; out
   1 -&gt; }            ) -&gt; incr

5 -incr-&gt; n
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">n</code> is <code class="language-plaintext highlighter-rouge">6</code>.)</p>

<p>The output of an operation may itself be a tuple. Here’s an implementation and
usage of <code class="language-plaintext highlighter-rouge">double-incr</code>, which increments two values at once.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>( in -0-&gt; } -incr-&gt; } -&gt; out
                    }
  in -1-&gt; } -incr-&gt; }        ) -&gt; double-incr

1 -&gt; } -double-incr-&gt; t -add-&gt; tt
2 -&gt; }
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">t</code> is a 2-tuple with values <code class="language-plaintext highlighter-rouge">2</code>, and <code class="language-plaintext highlighter-rouge">3</code>, <code class="language-plaintext highlighter-rouge">tt</code> is `5.)</p>

<h3 id="conditionals">Conditionals</h3>

<p>The conditional is a bit weird, and I’m not totally settled on it yet. For now
we’ll use this. The <code class="language-plaintext highlighter-rouge">if</code> operation expects as an input a 2-tuple whose first
value is a boolean and whose second value will be passed along. The <code class="language-plaintext highlighter-rouge">if</code>
operation is special in that it has <em>two</em> output edges. The first will be taken
if the boolean is true, the second if the boolean is false. The second value in
the input tuple, the one to be passed along, is used as the input to whichever
branch is taken.</p>

<p>Here is an implementation and usage of <code class="language-plaintext highlighter-rouge">max</code>, which takes two numbers and
outputs the greater of the two. Note that the <code class="language-plaintext highlighter-rouge">if</code> operation has two output
edges, but our syntax doesn’t represent that very cleanly.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>( in -gt-&gt; } -if-&gt; } -0-&gt; out
     in -&gt; }    -&gt; } -1-&gt; out ) -&gt; max

1 -&gt; } -max-&gt; t
2 -&gt; }
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">t</code> is <code class="language-plaintext highlighter-rouge">2</code>.)</p>

<p>It would be simple enough to create a <code class="language-plaintext highlighter-rouge">switch</code> macro on top of <code class="language-plaintext highlighter-rouge">if</code>, to allow
for multiple conditionals to be tested at once.</p>

<h3 id="loops">Loops</h3>

<p>Loops are tricky, and I have two thoughts about how they might be accomplished.
One is to literally draw an edge from the right end of the graph back to the
left, at the point where the loop should occur, as that’s conceptually what’s
happening. But representing that in a text file is difficult. For now I’ll
introduce the special <code class="language-plaintext highlighter-rouge">recur</code> value, and leave this whole section as TBD.</p>

<p><code class="language-plaintext highlighter-rouge">recur</code> is cousin of <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code>, in that it’s a special value and not an
operation.  It takes whatever value it’s set to and calls the current operation
with that as input. As an example, here is our now classic 0 through 9 printer
(assume <code class="language-plaintext highlighter-rouge">println</code> outputs whatever it was input):</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>// incr-1 is an operation which takes a 2-tuple and returns the same 2-tuple
// with the first element incremented.
( in -0-&gt; } -incr-&gt; } -&gt; out
            in -1-&gt; }        ) -&gt; incr-1

( in -eq-&gt; } -if-&gt; out
     in -&gt; }    -&gt; } -0-&gt; } -println-&gt; } -incr-1-&gt; } -&gt; recur ) -&gt; print-range

0  -&gt; } -print-range-&gt; }
10 -&gt; }
</code></pre></div></div>

<h2 id="next-steps">Next Steps</h2>

<p>This post is long enough, and I think gives at least a basic idea of what I’m
going for. The syntax presented here is <em>extremely</em> rudimentary, and is almost
definitely not what any final version of the syntax would look like. But the
general idea behind the structure is sound, I think.</p>

<p>I have a lot of further ideas for Ginger I haven’t presented here. Hopefully as
time goes on and I work on the language more some of those ideas can start
taking a more concrete shape and I can write about them.</p>

<p>The next thing I need to do for Ginger is to implement (again) the graph type
for it, since the last one I implemented didn’t include tuples. Maybe I can
extend it instead of re-writing it. After that it will be time to really buckle
down and figure out a syntax. Once a syntax is established then it’s time to
start on the compiler!</p>"""

+++
<p>This post is about a programming language that’s been bouncing around in my head
for a <em>long</em> time. I’ve tried to actually implement the language three or more
times now, but everytime I get stuck or run out of steam. It doesn’t help that
everytime I try again the form of the language changes significantly. But all
throughout the name of the language has always been “Ginger”. It’s a good name.</p>

<p>In the last few years the form of the language has somewhat solidified in my
head, so in lieu of actually working on it I’m going to talk about what it
currently looks like.</p>

<h2 id="abstract-syntax-lists">Abstract Syntax Lists</h2>

<p><em>In the beginning</em> there was assembly. Well, really in the beginning there were
punchcards, and probably something even more esoteric before that, but it was
all effectively the same thing: a list of commands the computer would execute
sequentially, with the ability to jump to odd places in the sequence depending
on conditions at runtime. For the purpose of this post, we’ll call this class of
languages “abstract syntax list” (ASL) languages.</p>

<p>Here’s a hello world program in my favorite ASL language, brainfuck:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>\u002B\u002B\u002B\u002B\u002B\u002B++[&gt;\u002B\u002B\u002B+[&gt;++&gt;\u002B\u002B\u002B&gt;\u002B\u002B\u002B&gt;+&lt;&lt;&lt;&lt;-]&gt;+&gt;+&gt;-&gt;&gt;+[&lt;]&lt;-]&gt;&gt;.&gt;---.\u002B\u002B\u002B\u002B\u002B\u002B+..\u002B\u002B\u002B.&gt;&gt;.&lt;-.&lt;.++
+.------.--------.&gt;&gt;+.&gt;++.
</code></pre></div></div>

<p>(If you’ve never seen brainfuck, it’s deliberately unintelligible. But it <em>is</em>
an ASL, each character representing a single command, executed by the brainfuck
runtime from left to right.)</p>

<p>ASLs did the job at the time, but luckily we’ve mostly moved on past them.</p>

<h2 id="abstract-syntax-trees">Abstract Syntax Trees</h2>

<p>Eventually programmers upgraded to C-like languages. Rather than a sequence of
commands, these languages were syntactically represented by an “abstract syntax
tree” (AST). Rather than executing commands in essentially the same order they
are written, an AST language compiler reads the syntax into a tree of syntax
nodes. What it then does with the tree is language dependent.</p>

<p>Here’s a program which outputs all numbers from 0 to 9 to stdout, written in
(slightly non-idiomatic) Go:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">i</span> <span class="o">:=</span> <span class="m">0</span>
<span class="k">for</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">i</span> <span class="o">==</span> <span class="m">10</span> <span class="p">{</span>
        <span class="k">break</span>
    <span class="p">}</span>
    <span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">i</span><span class="p">)</span>
    <span class="n">i</span><span class="o">++</span>
<span class="p">}</span>
</code></pre></div></div>

<p>When the Go compiler sees this, it’s going to first parse the syntax into an
AST. The AST might look something like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(root)
   |-(:=)
   |   |-(i)
   |   |-(0)
   |
   |-(for)
       |-(if)
       |  |-(==)
       |  |  |-(i)
       |  |  |-(10)
       |  |
       |  |-(break)
       |
       |-(fmt.Println)
       |       |-(i)
       |
       |-(++)
           |-(i)
</code></pre></div></div>

<p>Each of the non-leaf nodes in the tree represents an operation, and the children
of the node represent the arguments to that operation, if any. From here the
compiler traverses the tree depth-first in order to turn each operation it finds
into the appropriate machine code.</p>

<p>There’s a sub-class of AST languages called the LISP (“LISt Processor”)
languages. In a LISP language the AST is represented using lists of elements,
where the first element in each list denotes the operation and the rest of the
elements in the list (if any) represent the arguments. Traditionally each list
is represented using parenthesis. For example <code class="language-plaintext highlighter-rouge">(+ 1 1)</code> represents adding 1 and
1 together.</p>

<p>As a more complex example, here’s how to print numbers 0 through 9 to stdout
using my favorite (and, honestly, only) LISP, Clojure:</p>

<div class="language-clj highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="p">(</span><span class="nb">doseq</span><span class="w">
    </span><span class="p">[</span><span class="n">n</span><span class="w"> </span><span class="p">(</span><span class="nb">range</span><span class="w"> </span><span class="mi">10</span><span class="p">)]</span><span class="w">
    </span><span class="p">(</span><span class="nb">println</span><span class="w"> </span><span class="n">n</span><span class="p">))</span><span class="w">
</span></code></pre></div></div>

<p>Much smaller, but the idea is there. In LISPs there is no differentiation
between the syntax, the AST, and the language’s data structures; they are all
one and the same. For this reason LISPs generally have very powerful macro
support, wherein one uses code written in the language to transform code written
in that same language. With macros users can extend a language’s functionality
to support nearly anything they need to, but because macro generation happens
<em>before</em> compilation they can still reap the benefits of compiler optimizations.</p>

<h3 id="ast-pitfalls">AST Pitfalls</h3>

<p>The ASL (assembly) is essentially just a thin layer of human readability on top
of raw CPU instructions. It does nothing in the way of representing code in the
way that humans actually think about it (relationships of types, flow of data,
encapsulation of behavior). The AST is a step towards expressing code in human
terms, but it isn’t quite there in my opinion. Let me show why by revisiting the
Go example above:</p>

<div class="language-go highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="n">i</span> <span class="o">:=</span> <span class="m">0</span>
<span class="k">for</span> <span class="p">{</span>
    <span class="k">if</span> <span class="n">i</span> <span class="o">&gt;</span> <span class="m">9</span> <span class="p">{</span>
        <span class="k">break</span>
    <span class="p">}</span>
    <span class="n">fmt</span><span class="o">.</span><span class="n">Println</span><span class="p">(</span><span class="n">i</span><span class="p">)</span>
    <span class="n">i</span><span class="o">++</span>
<span class="p">}</span>
</code></pre></div></div>

<p>When I understand this code I don’t understand it in terms of its syntax. I
understand it in terms of what it <em>does</em>. And what it does is this:</p>

<ul>
  <li>with a number starting at 0, start a loop.</li>
  <li>if the number is greater than 9, stop the loop.</li>
  <li>otherwise, print the number.</li>
  <li>add one to the number.</li>
  <li>go to start of loop.</li>
</ul>

<p>This behavior could be further abstracted into the original problem statement,
“it prints numbers 0 through 9 to stdout”, but that’s too general, as there
are different ways for that to be accomplished. The Clojure example first
defines a list of numbers 0 through 9 and then iterates over that, rather than
looping over a single number. These differences are important when understanding
what code is doing.</p>

<p>So what’s the problem? My problem with ASTs is that the syntax I’ve written down
does <em>not</em> reflect the structure of the code or the flow of data which is in my
head. In the AST representation if you want to follow the flow of data (a single
number) you <em>have</em> to understand the semantic meaning of <code class="language-plaintext highlighter-rouge">i</code> and <code class="language-plaintext highlighter-rouge">:=</code>; the AST
structure itself does not convey how data is being moved or modified.
Essentially, there’s an extra implicit transformation that must be done to
understand the code in human terms.</p>

<h2 id="ginger-an-abstract-syntax-graph-language">Ginger: An Abstract Syntax Graph Language</h2>

<p>In my view the next step is towards using graphs rather than trees for
representing our code. A graph has the benefit of being able to reference
“backwards” into itself, where a tree cannot, and so can represent the flow of
data much more directly.</p>

<p>I would like Ginger to be an ASG language where the language is the graph,
similar to a LISP. But what does this look like exactly? Well, I have a good
idea about what the graph <em>structure</em> will be like and how it will function, but
the syntax is something I haven’t bothered much with yet. Representing graph
structures in a text file is a problem to be tackled all on its own. For this
post we’ll use a made-up, overly verbose, and probably non-usable syntax, but
hopefully it will convey the graph structure well enough.</p>

<h3 id="nodes-edges-and-tuples">Nodes, Edges, and Tuples</h3>

<p>All graphs have nodes, where each node contains a value. A single unique value
can only have a single node in a graph. Nodes are connected by edges, where
edges have a direction and can contain a value themselves.</p>

<p>In the context of Ginger, a node represents a value as expected, and the value
on an edge represents an operation to take on that value. For example:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>5 -incr-&gt; n
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">5</code> and <code class="language-plaintext highlighter-rouge">n</code> are both nodes in the graph, with an edge going from <code class="language-plaintext highlighter-rouge">5</code> to <code class="language-plaintext highlighter-rouge">n</code> that
has the value <code class="language-plaintext highlighter-rouge">incr</code>. When it comes time to interpret the graph we say that the
value of <code class="language-plaintext highlighter-rouge">n</code> can be calculated by giving <code class="language-plaintext highlighter-rouge">5</code> as the input to the operation
<code class="language-plaintext highlighter-rouge">incr</code> (increment). In other words, the value of <code class="language-plaintext highlighter-rouge">n</code> is <code class="language-plaintext highlighter-rouge">6</code>.</p>

<p>What about operations which have more than one input value? For this Ginger
introduces the tuple to its graph type. A tuple is like a node, except that it’s
anonymous, which allows more than one to exist within the same graph, as they do
not share the same value. For the purposes of this blog post we’ll represent
tuples like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -add-&gt; t
2 -&gt; }
</code></pre></div></div>

<p><code class="language-plaintext highlighter-rouge">t</code>’s value is the result of passing a tuple of two values, <code class="language-plaintext highlighter-rouge">1</code> and <code class="language-plaintext highlighter-rouge">2</code>, as
inputs to the operation <code class="language-plaintext highlighter-rouge">add</code>. In other words, the value of <code class="language-plaintext highlighter-rouge">t</code> is <code class="language-plaintext highlighter-rouge">3</code>.</p>

<p>For the syntax being described in this post we allow that a single contiguous
graph can be represented as multiple related sections. This can be done because
each node’s value is unique, so when the same value is used in disparate
sections we can merge the two sections on that value. For example, the following
two graphs are exactly equivalent (note the parenthesis wrapping the graph which
has been split):</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -add-&gt; t -incr-&gt; tt
2 -&gt; }
</code></pre></div></div>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>(
    1 -&gt; } -add-&gt; t
    2 -&gt; }

    t -incr-&gt; tt
)
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">tt</code> is <code class="language-plaintext highlighter-rouge">4</code> in both cases.)</p>

<p>A tuple with only one input edge, a 1-tuple, is a no-op, semantically, but can
be useful structurally to chain multiple operations together without defining
new value names. In the above example the <code class="language-plaintext highlighter-rouge">t</code> value can be eliminated using a
1-tuple.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -add-&gt; } -incr-&gt; tt
2 -&gt; }
</code></pre></div></div>

<p>When an integer is used as an operation on a tuple value then the effect is to
output the value in the tuple at that index. For example:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>1 -&gt; } -0-&gt; } -incr-&gt; t
2 -&gt; }
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">t</code> is <code class="language-plaintext highlighter-rouge">2</code>.)</p>

<h3 id="operations">Operations</h3>

<p>When a value sits on an edge it is used as an operation on the input of that
edge. Some operations will no doubt be builtin, like <code class="language-plaintext highlighter-rouge">add</code>, but users should be
able to define their own operations. This can be done using the <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code>
special values. When a graph is used as an operation it is scanned for both <code class="language-plaintext highlighter-rouge">in</code>
and <code class="language-plaintext highlighter-rouge">out</code> values. <code class="language-plaintext highlighter-rouge">in</code> is set to the input value of the operation, and the value
of <code class="language-plaintext highlighter-rouge">out</code> is used as the output of the operation.</p>

<p>Here we will define the <code class="language-plaintext highlighter-rouge">incr</code> operation and then use it. Note that we set the
<code class="language-plaintext highlighter-rouge">incr</code> value to be an entire sub-graph which represents the operation’s body.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>( in -&gt; } -add-&gt; out
   1 -&gt; }            ) -&gt; incr

5 -incr-&gt; n
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">n</code> is <code class="language-plaintext highlighter-rouge">6</code>.)</p>

<p>The output of an operation may itself be a tuple. Here’s an implementation and
usage of <code class="language-plaintext highlighter-rouge">double-incr</code>, which increments two values at once.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>( in -0-&gt; } -incr-&gt; } -&gt; out
                    }
  in -1-&gt; } -incr-&gt; }        ) -&gt; double-incr

1 -&gt; } -double-incr-&gt; t -add-&gt; tt
2 -&gt; }
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">t</code> is a 2-tuple with values <code class="language-plaintext highlighter-rouge">2</code>, and <code class="language-plaintext highlighter-rouge">3</code>, <code class="language-plaintext highlighter-rouge">tt</code> is `5.)</p>

<h3 id="conditionals">Conditionals</h3>

<p>The conditional is a bit weird, and I’m not totally settled on it yet. For now
we’ll use this. The <code class="language-plaintext highlighter-rouge">if</code> operation expects as an input a 2-tuple whose first
value is a boolean and whose second value will be passed along. The <code class="language-plaintext highlighter-rouge">if</code>
operation is special in that it has <em>two</em> output edges. The first will be taken
if the boolean is true, the second if the boolean is false. The second value in
the input tuple, the one to be passed along, is used as the input to whichever
branch is taken.</p>

<p>Here is an implementation and usage of <code class="language-plaintext highlighter-rouge">max</code>, which takes two numbers and
outputs the greater of the two. Note that the <code class="language-plaintext highlighter-rouge">if</code> operation has two output
edges, but our syntax doesn’t represent that very cleanly.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>( in -gt-&gt; } -if-&gt; } -0-&gt; out
     in -&gt; }    -&gt; } -1-&gt; out ) -&gt; max

1 -&gt; } -max-&gt; t
2 -&gt; }
</code></pre></div></div>

<p>(<code class="language-plaintext highlighter-rouge">t</code> is <code class="language-plaintext highlighter-rouge">2</code>.)</p>

<p>It would be simple enough to create a <code class="language-plaintext highlighter-rouge">switch</code> macro on top of <code class="language-plaintext highlighter-rouge">if</code>, to allow
for multiple conditionals to be tested at once.</p>

<h3 id="loops">Loops</h3>

<p>Loops are tricky, and I have two thoughts about how they might be accomplished.
One is to literally draw an edge from the right end of the graph back to the
left, at the point where the loop should occur, as that’s conceptually what’s
happening. But representing that in a text file is difficult. For now I’ll
introduce the special <code class="language-plaintext highlighter-rouge">recur</code> value, and leave this whole section as TBD.</p>

<p><code class="language-plaintext highlighter-rouge">recur</code> is cousin of <code class="language-plaintext highlighter-rouge">in</code> and <code class="language-plaintext highlighter-rouge">out</code>, in that it’s a special value and not an
operation.  It takes whatever value it’s set to and calls the current operation
with that as input. As an example, here is our now classic 0 through 9 printer
(assume <code class="language-plaintext highlighter-rouge">println</code> outputs whatever it was input):</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>// incr-1 is an operation which takes a 2-tuple and returns the same 2-tuple
// with the first element incremented.
( in -0-&gt; } -incr-&gt; } -&gt; out
            in -1-&gt; }        ) -&gt; incr-1

( in -eq-&gt; } -if-&gt; out
     in -&gt; }    -&gt; } -0-&gt; } -println-&gt; } -incr-1-&gt; } -&gt; recur ) -&gt; print-range

0  -&gt; } -print-range-&gt; }
10 -&gt; }
</code></pre></div></div>

<h2 id="next-steps">Next Steps</h2>

<p>This post is long enough, and I think gives at least a basic idea of what I’m
going for. The syntax presented here is <em>extremely</em> rudimentary, and is almost
definitely not what any final version of the syntax would look like. But the
general idea behind the structure is sound, I think.</p>

<p>I have a lot of further ideas for Ginger I haven’t presented here. Hopefully as
time goes on and I work on the language more some of those ideas can start
taking a more concrete shape and I can write about them.</p>

<p>The next thing I need to do for Ginger is to implement (again) the graph type
for it, since the last one I implemented didn’t include tuples. Maybe I can
extend it instead of re-writing it. After that it will be time to really buckle
down and figure out a syntax. Once a syntax is established then it’s time to
start on the compiler!</p>
