
+++
title = 'Thoughts on "Why is React doing this?"'
date = 2019-09-06T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Response to Why React?
Some quick thoughts I had after reading the Why React? gist.
Disclaimer: I wa..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/why-react-response/"
raw = """
<h1 id="response-to-why-react">Response to <a href="https://gist.github.com/sebmarkbage/a5ef436427437a98408672108df01919">Why React?</a></h1>
<p>Some quick thoughts I had after reading the <a href="https://gist.github.com/sebmarkbage/a5ef436427437a98408672108df01919">Why React?</a> gist.</p>
<p>Disclaimer: <em>I want to be critical with React. I don't disagree that it has done some amazing things</em></p>
<h2 id="compiled-output-results-in-smaller-apps">&quot;Compiled output results in smaller apps&quot;</h2>
<blockquote>
<p>E.g. Svelte apps start smaller but the compiler output is 3-4x larger per component than the equivalent VDOM approach.</p>
</blockquote>
<p>This may be true currently, but that doesn't mean it will always be true of compiled-to frameworks. A theoretical compiler can produce a component that uses a shared library for all components. If a user doesn't use all the features of a framework, then a compiler could remove the unused features from the output. Which is something that could not happen with a framework that relies on a full runtime.</p>
<p>Note: I'm not advocating for a compiled-to approach, I just think this point was misleading</p>
<h2 id="dom-is-stateful-imperative-so-we-should-embrace-it">&quot;DOM is stateful/imperative, so we should embrace it&quot;</h2>
<p>I agree with OP here. Most use-cases would not benefit from an imperative UI api.</p>
<h2 id="react-leaks-implementation-details-through-usememo">&quot;React leaks implementation details through useMemo&quot;</h2>
<p>A common problem to bite new comers is when they pass a closure to a component, and that closure gets changed every time which causes their component to re-render every time. <code>useMemo</code> can fix this issue, but it offloads a bit of work to the developer.</p>
<p>In the above context, it's an implementation detail. I'm not saying it's the wrong or right trade off, I'm only saying that the reason you have to reach for <code>useMemo</code> when passing around closures is because of how React is implemented. So the quote is accurate.</p>
<p>Is that a bad thing? That's where it gets more subjective. I think it is, because these types of things happen very often and, in a big app, you quickly succumb to death by a thousand cuts (one closure causing a component to re-render isn't a big deal, but when you have hundreds of components with various closures it gets hairy).</p>
<p>The next example OP posts is about setting users in a list.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#bf616a;">setUsers</span><span style="color:#c0c5ce;">([
  ...</span><span style="color:#bf616a;">users</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">filter</span><span style="color:#c0c5ce;">(user </span><span style="color:#b48ead;">=&gt; </span><span style="color:#bf616a;">user</span><span style="color:#c0c5ce;">.name !== &quot;</span><span style="color:#a3be8c;">Sebastian</span><span style="color:#c0c5ce;">&quot;),
  { name: &quot;</span><span style="color:#a3be8c;">Sebastian</span><span style="color:#c0c5ce;">&quot; }
]);
</span></code></pre>
<p>If you are happy with that syntax, and the tradeoff of having to use <code>key</code> props whenever you display lists, and relying on React's heuristics to efficiently update the views corresponding to the list, then React is fine. If, however, you are okay with a different syntax you may be interested in another idea I've seen. The basic idea is you keep track of the diffs themselves instead of the old version vs. the new version. Knowing the diffs directly let you know exactly how to update the views directly so you don't have to rely on the <code>key</code> prop, heuristics, and you can efficiently/quickly update the View list. This is similar to how <a href="https://github.com/immerjs/immer">Immer</a> works. <a href="https://docs.rs/futures-signals/0.3.8/futures_signals/tutorial/index.html">Futures Signals</a> also does this to efficiently send updates of a list to consumers (look at <code>SignalVec</code>).</p>
<h2 id="stale-closures-in-hooks-are-confusing">&quot;Stale closures in Hooks are confusing&quot;</h2>
<p>I agree with OP's points here. It's important to know where your data is coming from. In the old hook-less style of React, your data was what you got from your props/state and nothing else. With hooks, it's easier to work with stale data that comes in from outside your props. It's a learning curve, but not necessarily bad.</p>
<p>One thing I find interesting is that the use of hooks moves functional components into becoming more stateful components. I think this is fine, but it loses the pure functional guarantees you had before.</p>
<p>I haven't yet made up my mind about hooks that interact with the context. (i.e. <code>useSelector</code> or <code>useDispatch</code>) since the context is less structured. i.e. This component's selector function for <code>useSelector</code> relies on the state being <code>X</code>, but <code>X</code> isn't passed in, it's set as the store in redux configuration file somewhere else. Now that the component relies on the shape of the store being <code>X</code> it makes it harder to move out. This may not actually matter in practice, and it may be much more useful to be able to pull arbitrary things out of your store. Hence why I'm currently undecided about it.</p>
"""

+++
<h1 id="response-to-why-react">Response to <a href="https://gist.github.com/sebmarkbage/a5ef436427437a98408672108df01919">Why React?</a></h1>
<p>Some quick thoughts I had after reading the <a href="https://gist.github.com/sebmarkbage/a5ef436427437a98408672108df01919">Why React?</a> gist.</p>
<p>Disclaimer: <em>I want to be critical with React. I don't disagree that it has done some amazing things</em></p>
<h2 id="compiled-output-results-in-smaller-apps">&quot;Compiled output results in smaller apps&quot;</h2>
<blockquote>
<p>E.g. Svelte apps start smaller but the compiler output is 3-4x larger per component than the equivalent VDOM approach.</p>
</blockquote>
<p>This may be true currently, but that doesn't mean it will always be true of compiled-to frameworks. A theoretical compiler can produce a component that uses a shared library for all components. If a user doesn't use all the features of a framework, then a compiler could remove the unused features from the output. Which is something that could not happen with a framework that relies on a full runtime.</p>
<p>Note: I'm not advocating for a compiled-to approach, I just think this point was misleading</p>
<h2 id="dom-is-stateful-imperative-so-we-should-embrace-it">&quot;DOM is stateful/imperative, so we should embrace it&quot;</h2>
<p>I agree with OP here. Most use-cases would not benefit from an imperative UI api.</p>
<h2 id="react-leaks-implementation-details-through-usememo">&quot;React leaks implementation details through useMemo&quot;</h2>
<p>A common problem to bite new comers is when they pass a closure to a component, and that closure gets changed every time which causes their component to re-render every time. <code>useMemo</code> can fix this issue, but it offloads a bit of work to the developer.</p>
<p>In the above context, it's an implementation detail. I'm not saying it's the wrong or right trade off, I'm only saying that the reason you have to reach for <code>useMemo</code> when passing around closures is because of how React is implemented. So the quote is accurate.</p>
<p>Is that a bad thing? That's where it gets more subjective. I think it is, because these types of things happen very often and, in a big app, you quickly succumb to death by a thousand cuts (one closure causing a component to re-render isn't a big deal, but when you have hundreds of components with various closures it gets hairy).</p>
<p>The next example OP posts is about setting users in a list.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#bf616a;">setUsers</span><span style="color:#c0c5ce;">([
  ...</span><span style="color:#bf616a;">users</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">filter</span><span style="color:#c0c5ce;">(user </span><span style="color:#b48ead;">=&gt; </span><span style="color:#bf616a;">user</span><span style="color:#c0c5ce;">.name !== &quot;</span><span style="color:#a3be8c;">Sebastian</span><span style="color:#c0c5ce;">&quot;),
  { name: &quot;</span><span style="color:#a3be8c;">Sebastian</span><span style="color:#c0c5ce;">&quot; }
]);
</span></code></pre>
<p>If you are happy with that syntax, and the tradeoff of having to use <code>key</code> props whenever you display lists, and relying on React's heuristics to efficiently update the views corresponding to the list, then React is fine. If, however, you are okay with a different syntax you may be interested in another idea I've seen. The basic idea is you keep track of the diffs themselves instead of the old version vs. the new version. Knowing the diffs directly let you know exactly how to update the views directly so you don't have to rely on the <code>key</code> prop, heuristics, and you can efficiently/quickly update the View list. This is similar to how <a href="https://github.com/immerjs/immer">Immer</a> works. <a href="https://docs.rs/futures-signals/0.3.8/futures_signals/tutorial/index.html">Futures Signals</a> also does this to efficiently send updates of a list to consumers (look at <code>SignalVec</code>).</p>
<h2 id="stale-closures-in-hooks-are-confusing">&quot;Stale closures in Hooks are confusing&quot;</h2>
<p>I agree with OP's points here. It's important to know where your data is coming from. In the old hook-less style of React, your data was what you got from your props/state and nothing else. With hooks, it's easier to work with stale data that comes in from outside your props. It's a learning curve, but not necessarily bad.</p>
<p>One thing I find interesting is that the use of hooks moves functional components into becoming more stateful components. I think this is fine, but it loses the pure functional guarantees you had before.</p>
<p>I haven't yet made up my mind about hooks that interact with the context. (i.e. <code>useSelector</code> or <code>useDispatch</code>) since the context is less structured. i.e. This component's selector function for <code>useSelector</code> relies on the state being <code>X</code>, but <code>X</code> isn't passed in, it's set as the store in redux configuration file somewhere else. Now that the component relies on the shape of the store being <code>X</code> it makes it harder to move out. This may not actually matter in practice, and it may be much more useful to be able to pull arbitrary things out of your store. Hence why I'm currently undecided about it.</p>

