
+++
title = "Component-Oriented Programming"
originalLink = "https://blog.mediocregopher.com/2020/11/16/component-oriented-programming.html"
date = 2020-11-16T00:00:00.000Z
template = "html_content/raw.html"
summary = """
A previous post in this
blog focused on a
framework developed to make designing component-based prog..."""

[extra]
author = "Brian Picciano"
raw = """
<p><a href="/2019/08/02/program-structure-and-composability.html">A previous post in this
blog</a> focused on a
framework developed to make designing component-based programs easier. In
retrospect, the proposed pattern/framework was over-engineered. This post
attempts to present the same ideas in a more distilled form, as a simple
programming pattern and without the unnecessary framework.</p>

<h2 id="components">Components</h2>

<p>Many languages, libraries, and patterns make use of a concept called a
“component,” but in each case the meaning of “component” might be slightly
different. Therefore, to begin talking about components, it is necessary to first
describe what is meant by “component” in this post.</p>

<p>For the purposes of this post, the properties of components include the
following.</p>

<p> 1… <strong>Abstract</strong>: A component is an interface consisting of one or more
methods.</p>

<p>   1a… A function might be considered a single-method component
<em>if</em> the language supports first-class functions.</p>

<p>   1b… A component, being an interface, may have one or more
implementations. Generally, there will be a primary implementation, which is
used during a program’s runtime, and secondary “mock” implementations, which are
only used when testing other components.</p>

<p> 2… <strong>Instantiatable</strong>: An instance of a component, given some set of
parameters, can be instantiated as a standalone entity. More than one of the
same component can be instantiated, as needed.</p>

<p> 3… <strong>Composable</strong>: A component may be used as a parameter of another
component’s instantiation. This would make it a child component of the one being
instantiated (the parent).</p>

<p> 4… <strong>Pure</strong>: A component may not use mutable global variables (i.e.,
singletons) or impure global functions (e.g., system calls). It may only use
constants and variables/components given to it during instantiation.</p>

<p> 5… <strong>Ephemeral</strong>: A component may have a specific method used to clean
up all resources that it’s holding (e.g., network connections, file handles,
language-specific lightweight threads, etc.).</p>

<p>   5a… This cleanup method should <em>not</em> clean up any child
components given as instantiation parameters.</p>

<p>   5b… This cleanup method should not return until the
component’s cleanup is complete.</p>

<p>   5c… A component should not be cleaned up until all its
parent components are cleaned up.</p>

<p>Components are composed together to create component-oriented programs. This is
done by passing components as parameters to other components during
instantiation. The <code class="language-plaintext highlighter-rouge">main</code> procedure of the program is responsible for
instantiating and composing the components of the program.</p>

<h2 id="example">Example</h2>

<p>It’s easier to show than to tell. This section posits a simple program and then
describes how it would be implemented in a component-oriented way. The program
chooses a random number and exposes an HTTP interface that allows users to try
and guess that number. The following are requirements of the program:</p>

<ul>
  <li>
    <p>A guess consists of a name that identifies the user performing the guess and
the number that is being guessed;</p>
  </li>
  <li>
    <p>A score is kept for each user who has performed a guess;</p>
  </li>
  <li>
    <p>Upon an incorrect guess, the user should be informed of whether they guessed
too high or too low, and 1 point should be deducted from their score;</p>
  </li>
  <li>
    <p>Upon a correct guess, the program should pick a new random number against
which to check subsequent guesses, and 1000 points should be added to the
user’s score;</p>
  </li>
  <li>
    <p>The HTTP interface should have two endpoints: one for users to submit guesses,
and another that lists out user scores from highest to lowest;</p>
  </li>
  <li>
    <p>Scores should be saved to disk so they survive program restarts.</p>
  </li>
</ul>

<p>It seems clear that there will be two major areas of functionality for our
program: score-keeping and user interaction via HTTP. Each of these can be
encapsulated into components called <code class="language-plaintext highlighter-rouge">scoreboard</code> and <code class="language-plaintext highlighter-rouge">httpHandlers</code>,
respectively.</p>

<p><code class="language-plaintext highlighter-rouge">scoreboard</code> will need to interact with a filesystem component to save/restore
scores (because it can’t use system calls directly; see property 4). It would be
wasteful for <code class="language-plaintext highlighter-rouge">scoreboard</code> to save the scores to disk on every score update, so
instead it will do so every 5 seconds. A time component will be required to
support this.</p>

<p><code class="language-plaintext highlighter-rouge">httpHandlers</code> will be choosing the random number which is being guessed, and
will therefore need a component that produces random numbers. <code class="language-plaintext highlighter-rouge">httpHandlers</code>
will also be recording score changes to <code class="language-plaintext highlighter-rouge">scoreboard</code>, so it will need access to
<code class="language-plaintext highlighter-rouge">scoreboard</code>.</p>

<p>The example implementation will be written in go, which makes differentiating
HTTP handler functionality from the actual HTTP server quite easy; thus, there
will be an <code class="language-plaintext highlighter-rouge">httpServer</code> component that uses <code class="language-plaintext highlighter-rouge">httpHandlers</code>.</p>

<p>Finally, a <code class="language-plaintext highlighter-rouge">logger</code> component will be used in various places to log useful
information during runtime.</p>

<p><a href="/assets/component-oriented-design/v1/main.html">The example implementation can be found
here.</a> While most of it can be
skimmed, it is recommended to at least read through the <code class="language-plaintext highlighter-rouge">main</code> function to see
how components are composed together. Note that <code class="language-plaintext highlighter-rouge">main</code> is where all components
are instantiated, and that all components’ take in their child components as
part of their instantiation.</p>

<h2 id="dag">DAG</h2>

<p>One way to look at a component-oriented program is as a directed acyclic graph
(DAG), where each node in the graph represents a component, and each edge
indicates that one component depends upon another component for instantiation.
For the previous program, it’s quite easy to construct such a DAG just by
looking at <code class="language-plaintext highlighter-rouge">main</code>, as in the following:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>net.Listener     rand.Rand        os.File
     ^               ^               ^
     |               |               |
 httpServer --&gt; httpHandlers --&gt; scoreboard --&gt; time.Ticker
     |               |               |
     +---------------+---------------+--&gt; log.Logger
</code></pre></div></div>

<p>Note that all the leaves of the DAG (i.e., nodes with no children) describe the
points where the program meets the operating system via system calls. The leaves
are, in essence, the program’s interface with the outside world.</p>

<p>While it’s not necessary to actually draw out the DAG for every program one
writes, it can be helpful to at least think about the program’s structure in
these terms.</p>

<h2 id="benefits">Benefits</h2>

<p>Looking at the previous example implementation, one would be forgiven for having
the immediate reaction of “This seems like a lot of extra work for little gain.
Why can’t I just make the system calls where I need to, and not bother with
wrapping them in interfaces and all these other rules?”</p>

<p>The following sections will answer that concern by showing the benefits gained
by following a component-oriented pattern.</p>

<h3 id="testing">Testing</h3>

<p>Testing is important, that much is being assumed.</p>

<p>A distinction to be made with testing is between unit and non-unit tests. Unit
tests are those for which there are no requirements for the environment outside
the test, such as the existence of global variables, running databases,
filesystems, or network services. Unit tests do not interact with the world
outside the testing procedure, but instead use mocks in place of the
functionality that would be expected by that world.</p>

<p>Unit tests are important because they are faster to run and more consistent than
non-unit tests. Unit tests also force the programmer to consider different
possible states of a component’s dependencies during the mocking process.</p>

<p>Unit tests are often not employed by programmers, because they are difficult to
implement for code that does not expose any way to swap out dependencies for
mocks of those dependencies. The primary culprit of this difficulty is the
direct usage of singletons and impure global functions. For component-oriented
programs, all components inherently allow for the swapping out of any
dependencies via their instantiation parameters, so there’s no extra effort
needed to support unit tests.</p>

<p><a href="/assets/component-oriented-design/v1/main_test.html">Tests for the example implementation can be found
here.</a> Note that all
dependencies of each component being tested are mocked/stubbed next to them.</p>

<h3 id="configuration">Configuration</h3>

<p>Practically all programs require some level of runtime configuration. This may
take the form of command-line arguments, environment variables, configuration
files, etc.</p>

<p>For a component-oriented program, all components are instantiated in the same
place, <code class="language-plaintext highlighter-rouge">main</code>, so it’s very easy to expose any arbitrary parameter to the user
via configuration. For any component that is affected by a configurable
parameter, that component merely needs to take an instantiation parameter for
that configurable parameter; <code class="language-plaintext highlighter-rouge">main</code> can connect the two together. This accounts
for the unit testing of a component with different configurations, while still
allowing for the configuration of any arbitrary internal functionality.</p>

<p>For more complex configuration systems, it is also possible to implement a
<code class="language-plaintext highlighter-rouge">configuration</code> component that wraps whatever configuration-related
functionality is needed, which other components use as a sub-component. The
effect is the same.</p>

<p>To demonstrate how configuration works in a component-oriented program, the
example program’s requirements will be augmented to include the following:</p>

<ul>
  <li>
    <p>The point change values for both correct and incorrect guesses (currently
hardcoded at 1000 and 1, respectively) should be configurable on the
command-line;</p>
  </li>
  <li>
    <p>The save file’s path, HTTP listen address, and save interval should all be
configurable on the command-line.</p>
  </li>
</ul>

<p><a href="/assets/component-oriented-design/v2/main.html">The new implementation, with newly configurable parameters, can be found
here.</a> Most of the program has
remained the same, and all unit tests from before remain valid. The primary
difference is that <code class="language-plaintext highlighter-rouge">scoreboard</code> takes in two new parameters for the point change
values, and configuration is set up inside <code class="language-plaintext highlighter-rouge">main</code> using the <code class="language-plaintext highlighter-rouge">flags</code> package.</p>

<h3 id="setupruntimecleanup">Setup/Runtime/Cleanup</h3>

<p>A program can be split into three stages: setup, runtime, and cleanup. Setup is
the stage during which the internal state is assembled to make runtime possible.
Runtime is the stage during which a program’s actual function is being
performed. Cleanup is the stage during which the runtime stops and internal
state is disassembled.</p>

<p>A graceful (i.e., reliably correct) setup is quite natural to accomplish for
most. On the other hand, a graceful cleanup is, unfortunately, not a programmer’s
first concern (if it is a concern at all).</p>

<p>When building reliable and correct programs, a graceful cleanup is as important
as a graceful setup and runtime. A program is still running while it is being
cleaned up, and it’s possibly still acting on the outside world. Shouldn’t
it behave correctly during that time?</p>

<p>Achieving a graceful setup and cleanup with components is quite simple.</p>

<p>During setup, a single-threaded procedure (<code class="language-plaintext highlighter-rouge">main</code>) first constructs the leaf
components, then the components that take those leaves as parameters, then the
components that take <em>those</em> as parameters, and so on, until the component DAG
is fully constructed.</p>

<p>At this point, the program’s runtime has begun.</p>

<p>Once the runtime is over, signified by a process signal or some other mechanism,
it’s only necessary to call each component’s cleanup method (if any; see
property 5) in the reverse of the order in which the components were
instantiated.  This order is inherently deterministic, as the components were
instantiated by a single-threaded procedure.</p>

<p>Inherent to this pattern is the fact that each component will certainly be
cleaned up before any of its child components, as its child components must have
been instantiated first, and a component will not clean up child components
given as parameters (properties 5a and 5c). Therefore, the pattern avoids
use-after-cleanup situations.</p>

<p>To demonstrate a graceful cleanup in a component-oriented program, the example
program’s requirements will be augmented to include the following:</p>

<ul>
  <li>
    <p>The program will terminate itself upon an interrupt signal;</p>
  </li>
  <li>
    <p>During termination (cleanup), the program will save the latest set of scores
to disk one final time.</p>
  </li>
</ul>

<p><a href="/assets/component-oriented-design/v3/main.html">The new implementation that accounts for these new requirements can be found
here.</a> For this example, go’s
<code class="language-plaintext highlighter-rouge">defer</code> feature could have been used instead, which would have been even
cleaner, but was omitted for the sake of those using other languages.</p>

<h2 id="conclusion">Conclusion</h2>

<p>The component pattern helps make programs more reliable with only a small amount
of extra effort incurred. In fact, most of the pattern has to do with
establishing sensible abstractions around global functionality and remembering
certain idioms for how those abstractions should be composed together, something
most of us already do to some extent anyway.</p>

<p>While beneficial in many ways, component-oriented programming is merely a tool
that can be applied in many cases. It is certain that there are cases where it
is not the right tool for the job, so apply it deliberately and intelligently.</p>

<h2 id="criticismsquestions">Criticisms/Questions</h2>

<p>In lieu of a FAQ, I will attempt to premeditate questions and criticisms of the
component-oriented programming pattern laid out in this post.</p>

<p><strong>This seems like a lot of extra work.</strong></p>

<p>Building reliable programs is a lot of work, just as building a
reliable <em>anything</em> is a lot of work. Many of us work in an industry that likes
to balance reliability (sometimes referred to by the more specious “quality”)
with malleability and deliverability, which naturally leads to skepticism of any
suggestions requiring more time spent on reliability. This is not necessarily a
bad thing, it’s just how the industry functions.</p>

<p>All that said, a pattern need not be followed perfectly to be worthwhile, and
the amount of extra work incurred by it can be decided based on practical
considerations. I merely maintain that code which is (mostly) component-oriented
is easier to maintain in the long run, even if it might be harder to get off the
ground initially.</p>

<p><strong>My language makes this difficult.</strong></p>

<p>I don’t know of any language which makes this pattern particularly easier than
others, so, unfortunately, we’re all in the same boat to some extent (though I
recognize that some languages, or their ecosystems, make it more difficult than
others). It seems to me that this pattern shouldn’t be unbearably difficult for
anyone to implement in any language either, however, as the only language
feature required is abstract typing.</p>

<p>It would be nice to one day see a language that explicitly supports this
pattern by baking the component properties in as compiler-checked rules.</p>

<p><strong>My <code class="language-plaintext highlighter-rouge">main</code> is too big</strong></p>

<p>There’s no law saying all component construction needs to happen in <code class="language-plaintext highlighter-rouge">main</code>,
that’s just the most sensible place for it. If there are large sections of your
program that are independent of each other, then they could each have their own
construction functions that <code class="language-plaintext highlighter-rouge">main</code> then calls.</p>

<p>Other questions that are worth asking include: Can my program be split up
into multiple programs? Can the responsibilities of any of my components be
refactored to reduce the overall complexity of the component DAG? Can the
instantiation of any components be moved within their parent’s
instantiation function?</p>

<p>(This last suggestion may seem to be disallowed, but is fine as long as the
parent’s instantiation function remains pure.)</p>

<p><strong>Won’t this will result in over-abstraction?</strong></p>

<p>Abstraction is a necessary tool in a programmer’s toolkit, there is simply no
way around it. The only questions are “how much?” and “where?”</p>

<p>The use of this pattern does not affect how those questions are answered, in my
opinion, but instead aims to more clearly delineate the relationships and
interactions between the different abstracted types once they’ve been
established using other methods. Over-abstraction is possible and avoidable
regardless of which language, pattern, or framework is being used.</p>

<p><strong>Does CoP conflict with object-oriented or functional programming?</strong></p>

<p>I don’t think so. OoP languages will have abstract types as part of their core
feature-set; most difficulties are going to be with deliberately <em>not</em> using
other features of an OoP language, and with imported libraries in the language
perhaps making life inconvenient by not following CoP (specifically regarding
cleanup and the use of singletons).</p>

<p>For functional programming, it may well be that, depending on the language, CoP
is technically being used, as functional languages are already generally
antagonistic toward globals and impure functions, which is most of the battle.
If anything, the transition from functional to component-oriented programming
will generally be an organizational task.</p>"""

+++
<p><a href="/2019/08/02/program-structure-and-composability.html">A previous post in this
blog</a> focused on a
framework developed to make designing component-based programs easier. In
retrospect, the proposed pattern/framework was over-engineered. This post
attempts to present the same ideas in a more distilled form, as a simple
programming pattern and without the unnecessary framework.</p>

<h2 id="components">Components</h2>

<p>Many languages, libraries, and patterns make use of a concept called a
“component,” but in each case the meaning of “component” might be slightly
different. Therefore, to begin talking about components, it is necessary to first
describe what is meant by “component” in this post.</p>

<p>For the purposes of this post, the properties of components include the
following.</p>

<p> 1… <strong>Abstract</strong>: A component is an interface consisting of one or more
methods.</p>

<p>   1a… A function might be considered a single-method component
<em>if</em> the language supports first-class functions.</p>

<p>   1b… A component, being an interface, may have one or more
implementations. Generally, there will be a primary implementation, which is
used during a program’s runtime, and secondary “mock” implementations, which are
only used when testing other components.</p>

<p> 2… <strong>Instantiatable</strong>: An instance of a component, given some set of
parameters, can be instantiated as a standalone entity. More than one of the
same component can be instantiated, as needed.</p>

<p> 3… <strong>Composable</strong>: A component may be used as a parameter of another
component’s instantiation. This would make it a child component of the one being
instantiated (the parent).</p>

<p> 4… <strong>Pure</strong>: A component may not use mutable global variables (i.e.,
singletons) or impure global functions (e.g., system calls). It may only use
constants and variables/components given to it during instantiation.</p>

<p> 5… <strong>Ephemeral</strong>: A component may have a specific method used to clean
up all resources that it’s holding (e.g., network connections, file handles,
language-specific lightweight threads, etc.).</p>

<p>   5a… This cleanup method should <em>not</em> clean up any child
components given as instantiation parameters.</p>

<p>   5b… This cleanup method should not return until the
component’s cleanup is complete.</p>

<p>   5c… A component should not be cleaned up until all its
parent components are cleaned up.</p>

<p>Components are composed together to create component-oriented programs. This is
done by passing components as parameters to other components during
instantiation. The <code class="language-plaintext highlighter-rouge">main</code> procedure of the program is responsible for
instantiating and composing the components of the program.</p>

<h2 id="example">Example</h2>

<p>It’s easier to show than to tell. This section posits a simple program and then
describes how it would be implemented in a component-oriented way. The program
chooses a random number and exposes an HTTP interface that allows users to try
and guess that number. The following are requirements of the program:</p>

<ul>
  <li>
    <p>A guess consists of a name that identifies the user performing the guess and
the number that is being guessed;</p>
  </li>
  <li>
    <p>A score is kept for each user who has performed a guess;</p>
  </li>
  <li>
    <p>Upon an incorrect guess, the user should be informed of whether they guessed
too high or too low, and 1 point should be deducted from their score;</p>
  </li>
  <li>
    <p>Upon a correct guess, the program should pick a new random number against
which to check subsequent guesses, and 1000 points should be added to the
user’s score;</p>
  </li>
  <li>
    <p>The HTTP interface should have two endpoints: one for users to submit guesses,
and another that lists out user scores from highest to lowest;</p>
  </li>
  <li>
    <p>Scores should be saved to disk so they survive program restarts.</p>
  </li>
</ul>

<p>It seems clear that there will be two major areas of functionality for our
program: score-keeping and user interaction via HTTP. Each of these can be
encapsulated into components called <code class="language-plaintext highlighter-rouge">scoreboard</code> and <code class="language-plaintext highlighter-rouge">httpHandlers</code>,
respectively.</p>

<p><code class="language-plaintext highlighter-rouge">scoreboard</code> will need to interact with a filesystem component to save/restore
scores (because it can’t use system calls directly; see property 4). It would be
wasteful for <code class="language-plaintext highlighter-rouge">scoreboard</code> to save the scores to disk on every score update, so
instead it will do so every 5 seconds. A time component will be required to
support this.</p>

<p><code class="language-plaintext highlighter-rouge">httpHandlers</code> will be choosing the random number which is being guessed, and
will therefore need a component that produces random numbers. <code class="language-plaintext highlighter-rouge">httpHandlers</code>
will also be recording score changes to <code class="language-plaintext highlighter-rouge">scoreboard</code>, so it will need access to
<code class="language-plaintext highlighter-rouge">scoreboard</code>.</p>

<p>The example implementation will be written in go, which makes differentiating
HTTP handler functionality from the actual HTTP server quite easy; thus, there
will be an <code class="language-plaintext highlighter-rouge">httpServer</code> component that uses <code class="language-plaintext highlighter-rouge">httpHandlers</code>.</p>

<p>Finally, a <code class="language-plaintext highlighter-rouge">logger</code> component will be used in various places to log useful
information during runtime.</p>

<p><a href="/assets/component-oriented-design/v1/main.html">The example implementation can be found
here.</a> While most of it can be
skimmed, it is recommended to at least read through the <code class="language-plaintext highlighter-rouge">main</code> function to see
how components are composed together. Note that <code class="language-plaintext highlighter-rouge">main</code> is where all components
are instantiated, and that all components’ take in their child components as
part of their instantiation.</p>

<h2 id="dag">DAG</h2>

<p>One way to look at a component-oriented program is as a directed acyclic graph
(DAG), where each node in the graph represents a component, and each edge
indicates that one component depends upon another component for instantiation.
For the previous program, it’s quite easy to construct such a DAG just by
looking at <code class="language-plaintext highlighter-rouge">main</code>, as in the following:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>net.Listener     rand.Rand        os.File
     ^               ^               ^
     |               |               |
 httpServer --&gt; httpHandlers --&gt; scoreboard --&gt; time.Ticker
     |               |               |
     +---------------+---------------+--&gt; log.Logger
</code></pre></div></div>

<p>Note that all the leaves of the DAG (i.e., nodes with no children) describe the
points where the program meets the operating system via system calls. The leaves
are, in essence, the program’s interface with the outside world.</p>

<p>While it’s not necessary to actually draw out the DAG for every program one
writes, it can be helpful to at least think about the program’s structure in
these terms.</p>

<h2 id="benefits">Benefits</h2>

<p>Looking at the previous example implementation, one would be forgiven for having
the immediate reaction of “This seems like a lot of extra work for little gain.
Why can’t I just make the system calls where I need to, and not bother with
wrapping them in interfaces and all these other rules?”</p>

<p>The following sections will answer that concern by showing the benefits gained
by following a component-oriented pattern.</p>

<h3 id="testing">Testing</h3>

<p>Testing is important, that much is being assumed.</p>

<p>A distinction to be made with testing is between unit and non-unit tests. Unit
tests are those for which there are no requirements for the environment outside
the test, such as the existence of global variables, running databases,
filesystems, or network services. Unit tests do not interact with the world
outside the testing procedure, but instead use mocks in place of the
functionality that would be expected by that world.</p>

<p>Unit tests are important because they are faster to run and more consistent than
non-unit tests. Unit tests also force the programmer to consider different
possible states of a component’s dependencies during the mocking process.</p>

<p>Unit tests are often not employed by programmers, because they are difficult to
implement for code that does not expose any way to swap out dependencies for
mocks of those dependencies. The primary culprit of this difficulty is the
direct usage of singletons and impure global functions. For component-oriented
programs, all components inherently allow for the swapping out of any
dependencies via their instantiation parameters, so there’s no extra effort
needed to support unit tests.</p>

<p><a href="/assets/component-oriented-design/v1/main_test.html">Tests for the example implementation can be found
here.</a> Note that all
dependencies of each component being tested are mocked/stubbed next to them.</p>

<h3 id="configuration">Configuration</h3>

<p>Practically all programs require some level of runtime configuration. This may
take the form of command-line arguments, environment variables, configuration
files, etc.</p>

<p>For a component-oriented program, all components are instantiated in the same
place, <code class="language-plaintext highlighter-rouge">main</code>, so it’s very easy to expose any arbitrary parameter to the user
via configuration. For any component that is affected by a configurable
parameter, that component merely needs to take an instantiation parameter for
that configurable parameter; <code class="language-plaintext highlighter-rouge">main</code> can connect the two together. This accounts
for the unit testing of a component with different configurations, while still
allowing for the configuration of any arbitrary internal functionality.</p>

<p>For more complex configuration systems, it is also possible to implement a
<code class="language-plaintext highlighter-rouge">configuration</code> component that wraps whatever configuration-related
functionality is needed, which other components use as a sub-component. The
effect is the same.</p>

<p>To demonstrate how configuration works in a component-oriented program, the
example program’s requirements will be augmented to include the following:</p>

<ul>
  <li>
    <p>The point change values for both correct and incorrect guesses (currently
hardcoded at 1000 and 1, respectively) should be configurable on the
command-line;</p>
  </li>
  <li>
    <p>The save file’s path, HTTP listen address, and save interval should all be
configurable on the command-line.</p>
  </li>
</ul>

<p><a href="/assets/component-oriented-design/v2/main.html">The new implementation, with newly configurable parameters, can be found
here.</a> Most of the program has
remained the same, and all unit tests from before remain valid. The primary
difference is that <code class="language-plaintext highlighter-rouge">scoreboard</code> takes in two new parameters for the point change
values, and configuration is set up inside <code class="language-plaintext highlighter-rouge">main</code> using the <code class="language-plaintext highlighter-rouge">flags</code> package.</p>

<h3 id="setupruntimecleanup">Setup/Runtime/Cleanup</h3>

<p>A program can be split into three stages: setup, runtime, and cleanup. Setup is
the stage during which the internal state is assembled to make runtime possible.
Runtime is the stage during which a program’s actual function is being
performed. Cleanup is the stage during which the runtime stops and internal
state is disassembled.</p>

<p>A graceful (i.e., reliably correct) setup is quite natural to accomplish for
most. On the other hand, a graceful cleanup is, unfortunately, not a programmer’s
first concern (if it is a concern at all).</p>

<p>When building reliable and correct programs, a graceful cleanup is as important
as a graceful setup and runtime. A program is still running while it is being
cleaned up, and it’s possibly still acting on the outside world. Shouldn’t
it behave correctly during that time?</p>

<p>Achieving a graceful setup and cleanup with components is quite simple.</p>

<p>During setup, a single-threaded procedure (<code class="language-plaintext highlighter-rouge">main</code>) first constructs the leaf
components, then the components that take those leaves as parameters, then the
components that take <em>those</em> as parameters, and so on, until the component DAG
is fully constructed.</p>

<p>At this point, the program’s runtime has begun.</p>

<p>Once the runtime is over, signified by a process signal or some other mechanism,
it’s only necessary to call each component’s cleanup method (if any; see
property 5) in the reverse of the order in which the components were
instantiated.  This order is inherently deterministic, as the components were
instantiated by a single-threaded procedure.</p>

<p>Inherent to this pattern is the fact that each component will certainly be
cleaned up before any of its child components, as its child components must have
been instantiated first, and a component will not clean up child components
given as parameters (properties 5a and 5c). Therefore, the pattern avoids
use-after-cleanup situations.</p>

<p>To demonstrate a graceful cleanup in a component-oriented program, the example
program’s requirements will be augmented to include the following:</p>

<ul>
  <li>
    <p>The program will terminate itself upon an interrupt signal;</p>
  </li>
  <li>
    <p>During termination (cleanup), the program will save the latest set of scores
to disk one final time.</p>
  </li>
</ul>

<p><a href="/assets/component-oriented-design/v3/main.html">The new implementation that accounts for these new requirements can be found
here.</a> For this example, go’s
<code class="language-plaintext highlighter-rouge">defer</code> feature could have been used instead, which would have been even
cleaner, but was omitted for the sake of those using other languages.</p>

<h2 id="conclusion">Conclusion</h2>

<p>The component pattern helps make programs more reliable with only a small amount
of extra effort incurred. In fact, most of the pattern has to do with
establishing sensible abstractions around global functionality and remembering
certain idioms for how those abstractions should be composed together, something
most of us already do to some extent anyway.</p>

<p>While beneficial in many ways, component-oriented programming is merely a tool
that can be applied in many cases. It is certain that there are cases where it
is not the right tool for the job, so apply it deliberately and intelligently.</p>

<h2 id="criticismsquestions">Criticisms/Questions</h2>

<p>In lieu of a FAQ, I will attempt to premeditate questions and criticisms of the
component-oriented programming pattern laid out in this post.</p>

<p><strong>This seems like a lot of extra work.</strong></p>

<p>Building reliable programs is a lot of work, just as building a
reliable <em>anything</em> is a lot of work. Many of us work in an industry that likes
to balance reliability (sometimes referred to by the more specious “quality”)
with malleability and deliverability, which naturally leads to skepticism of any
suggestions requiring more time spent on reliability. This is not necessarily a
bad thing, it’s just how the industry functions.</p>

<p>All that said, a pattern need not be followed perfectly to be worthwhile, and
the amount of extra work incurred by it can be decided based on practical
considerations. I merely maintain that code which is (mostly) component-oriented
is easier to maintain in the long run, even if it might be harder to get off the
ground initially.</p>

<p><strong>My language makes this difficult.</strong></p>

<p>I don’t know of any language which makes this pattern particularly easier than
others, so, unfortunately, we’re all in the same boat to some extent (though I
recognize that some languages, or their ecosystems, make it more difficult than
others). It seems to me that this pattern shouldn’t be unbearably difficult for
anyone to implement in any language either, however, as the only language
feature required is abstract typing.</p>

<p>It would be nice to one day see a language that explicitly supports this
pattern by baking the component properties in as compiler-checked rules.</p>

<p><strong>My <code class="language-plaintext highlighter-rouge">main</code> is too big</strong></p>

<p>There’s no law saying all component construction needs to happen in <code class="language-plaintext highlighter-rouge">main</code>,
that’s just the most sensible place for it. If there are large sections of your
program that are independent of each other, then they could each have their own
construction functions that <code class="language-plaintext highlighter-rouge">main</code> then calls.</p>

<p>Other questions that are worth asking include: Can my program be split up
into multiple programs? Can the responsibilities of any of my components be
refactored to reduce the overall complexity of the component DAG? Can the
instantiation of any components be moved within their parent’s
instantiation function?</p>

<p>(This last suggestion may seem to be disallowed, but is fine as long as the
parent’s instantiation function remains pure.)</p>

<p><strong>Won’t this will result in over-abstraction?</strong></p>

<p>Abstraction is a necessary tool in a programmer’s toolkit, there is simply no
way around it. The only questions are “how much?” and “where?”</p>

<p>The use of this pattern does not affect how those questions are answered, in my
opinion, but instead aims to more clearly delineate the relationships and
interactions between the different abstracted types once they’ve been
established using other methods. Over-abstraction is possible and avoidable
regardless of which language, pattern, or framework is being used.</p>

<p><strong>Does CoP conflict with object-oriented or functional programming?</strong></p>

<p>I don’t think so. OoP languages will have abstract types as part of their core
feature-set; most difficulties are going to be with deliberately <em>not</em> using
other features of an OoP language, and with imported libraries in the language
perhaps making life inconvenient by not following CoP (specifically regarding
cleanup and the use of singletons).</p>

<p>For functional programming, it may well be that, depending on the language, CoP
is technically being used, as functional languages are already generally
antagonistic toward globals and impure functions, which is most of the battle.
If anything, the transition from functional to component-oriented programming
will generally be an organizational task.</p>
