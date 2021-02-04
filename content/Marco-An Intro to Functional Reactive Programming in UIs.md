
+++
title = "An Intro to Functional Reactive Programming in UIs"
date = 2014-11-16T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Maybe you've heard of React, Om,
or Elm, and wondering: what's the deal with
functional reactive pro..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/frp/"
raw = """
<p>Maybe you've heard of <a href="https://facebook.github.io/react/">React</a>, <a href="https://github.com/swannodette/om">Om</a>,
or <a href="http://elm-lang.org/">Elm</a>, and wondering: what's the deal with
functional reactive programming (FRP)?</p>
<p>This post will act as primer on FRP using vanilla JS, but the ideas presented
here translate pretty easily in any language and UI system.</p>
<p>So let's start with an informal, pragmatic definition of FRP:</p>
<blockquote>
<p>Use streams of data to create the application state (data)</p>
</blockquote>
<p>And</p>
<blockquote>
<p>Build a UI given only the application state with pure functions (view)</p>
</blockquote>
<h2 id="streams-and-arrays">Streams and arrays</h2>
<p>You can imagine streams of data as a set of values over time.</p>
<p>A stream of numbers representing a counter would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[0,1,2,3,4,5,6,...]
</span></code></pre>
<p>Each number is essentially a snapshot of the value at that time.</p>
<p>Streams are similar to arrays, but the main difference is time.
An immutable array has all the values it will ever have when it is created, while a stream represents all the values that have happened and will
happen.</p>
<p>Here's a concrete example: You are an owner of an exclusive restaurant.
It's so exclusive that people have to make reservations months in advance.
Every night you have a list of people at your restaurant (because they've
already made reservations). Imagine the list being <code>[amy, sally, bob]</code>.
To count the number of guests, we would just reduce over the list
adding 1 for every guest. If we wanted to know how much each guest spent
we would map against a function that tells us the guest's bill.</p>
<p>This is just a normal array with normal map/reduce construct.
For completeness here's the equivalent code.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">guests </span><span style="color:#c0c5ce;">= [&quot;</span><span style="color:#a3be8c;">amy</span><span style="color:#c0c5ce;">&quot;, &quot;</span><span style="color:#a3be8c;">sally</span><span style="color:#c0c5ce;">&quot;, &quot;</span><span style="color:#a3be8c;">bob</span><span style="color:#c0c5ce;">&quot;];
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">bills </span><span style="color:#c0c5ce;">= { amy: </span><span style="color:#d08770;">22.5</span><span style="color:#c0c5ce;">, sally: </span><span style="color:#d08770;">67.0</span><span style="color:#c0c5ce;">, bob: </span><span style="color:#d08770;">6.0 </span><span style="color:#c0c5ce;">};

</span><span style="color:#65737e;">// Count the guests
</span><span style="color:#bf616a;">guests</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">reduce</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(sum, guest) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">sum </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
}, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">);
</span><span style="color:#65737e;">// =&gt; 3
// Get the bills
</span><span style="color:#bf616a;">guests</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">map</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(guest) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">bills</span><span style="color:#c0c5ce;">[</span><span style="color:#bf616a;">guest</span><span style="color:#c0c5ce;">];
});
</span><span style="color:#65737e;">// =&gt; [22.5, 67, 6]
</span></code></pre>
<p>Unfortunately Sally had some bad fish and died after eating at your
restaurant, so everyone has cancelled their reservations and you are
now a fast food place. In this case you don't have a list of guests,
instead you have a <em>stream</em> of people who come in and order food.
<code>Frank</code> might come in at 10 am, followed by <code>Jack</code> at 2 pm. To get
similar data as before we would again map/reduce over the stream,
but since we are operating over a stream that never ends, the values
from map/reduce themselves become streams that never end.</p>
<p>Here is some equivalent pseudo code for streams that calculates
the <code>guestCounts</code> and the <code>guestBills</code>.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#bf616a;">guests      </span><span style="color:#c0c5ce;">= [... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#bf616a;">Frank</span><span style="color:#c0c5ce;">, ... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#bf616a;">Jack</span><span style="color:#c0c5ce;">, ... ]

</span><span style="color:#bf616a;">guestCounts </span><span style="color:#c0c5ce;">= [... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">,     ... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">, ... ]
</span><span style="color:#bf616a;">guestBills </span><span style="color:#c0c5ce;">=  [... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">5.50</span><span style="color:#c0c5ce;">,  ... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">6.50</span><span style="color:#c0c5ce;">, ... ]
</span></code></pre>
<p>So a stream is just like an array that never ends, and represents
snapshots of time.</p>
<p>Now that we have an intuitive idea what streams are, we can actually
implement them.</p>
<h2 id="streams-of-data">Streams of data</h2>
<p>A stream of numbers representing a counter would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[0,1,2,3,4,5,6,...]
</span></code></pre>
<p>If we wanted to keep track of how long someone was on our page,
we could just display the latest value of the counter stream
in our UI and that would be enough.</p>
<p>A more involved example: Imagine we had a stream of data
that represents the keys pressed on the keyboard.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[&quot;p&quot;,&quot;w&quot;,&quot;n&quot;,&quot;2&quot;,&quot;o&quot;,&quot;w&quot;,&quot;n&quot;,...]
</span></code></pre>
<p>Now we want to have a stream that represents the state of the system,
say the amount of keys pressed.</p>
<p>Our key count stream would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[&quot;p&quot;,&quot;w&quot;,&quot;n&quot;,&quot;2&quot;,&quot;o&quot;,&quot;w&quot;,&quot;n&quot;,...]
=&gt;
[ 1,  2,  3,  4,  5,  6,  7, ...]
</span></code></pre>
<p>This transformation would happen with a reducing function.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keyCountReducer </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(reducedValue, streamSnapshot) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
};
</span></code></pre>
<p>This function takes in the stream value, and a reduced value so far, and
returns a new reduced value. In this case a simple increment.</p>
<p>We've talked about streams for a while now, let's implement them.</p>
<p>In the following code, we create a function that will return an object with two
methods: <code>observe</code> for registering event listeners and <code>update</code> for adding a value
to the stream.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// A function to make streams for us
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">streamMaker </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">registeredListeners </span><span style="color:#c0c5ce;">= [];
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{
    </span><span style="color:#65737e;">// Have an observe function, so
    // people who are interested can
    // get notified when there is an update
    </span><span style="color:#8fa1b3;">observe</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(callback) {
      </span><span style="color:#bf616a;">registeredListeners</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">push</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">callback</span><span style="color:#c0c5ce;">);
    },

    </span><span style="color:#65737e;">// Add a value to this stream
    // Once added, will notify all
    // interested parties
    </span><span style="color:#8fa1b3;">update</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
      </span><span style="color:#bf616a;">registeredListeners</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">forEach</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(cb) {
        </span><span style="color:#bf616a;">cb</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
      });
    }
  };
};
</span></code></pre>
<p>We also want to make a helper function that will create a new reduced stream
given an existing <code>stream</code>, a <code>reducingFunction</code>, and an <code>initialReducedValue</code>:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// A function to make a new stream from an existing stream
// a reducing function, and an initial reduced value
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">reducedStream </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(stream, reducingFunction, initialReducedValue) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">newStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">initialReducedValue</span><span style="color:#c0c5ce;">;

  </span><span style="color:#bf616a;">stream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(streamSnapshotValue) {
    </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">reducingFunction</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">reducedValue</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">streamSnapshotValue</span><span style="color:#c0c5ce;">);
    </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">reducedValue</span><span style="color:#c0c5ce;">);
  });
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">;
};
</span></code></pre>
<p>Now to implement the keypress stream and count stream.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Our reducer from before
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keyCountReducer </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(reducedValue, streamSnapshot) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
};

</span><span style="color:#65737e;">// Create the keypress stream
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keypressStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();
</span><span style="color:#65737e;">// an observer will have that side effect of printing out to the console
</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(v) {
  console.</span><span style="color:#96b5b4;">log</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">key: </span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">v</span><span style="color:#c0c5ce;">);
});

</span><span style="color:#65737e;">// Whenever we press a key, we&#39;ll update the stream to be the char code.
</span><span style="color:#ebcb8b;">document</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">onkeypress </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(e) {
  </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#ebcb8b;">String</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">fromCharCode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">e</span><span style="color:#c0c5ce;">.charCode));
};

</span><span style="color:#65737e;">// Using our reducedStream helper function we can make a new stream
// That reduces the keypresses into a stream of key counts
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">countStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">reducedStream</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">keyCountReducer</span><span style="color:#c0c5ce;">, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">);
</span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(v) {
  console.</span><span style="color:#96b5b4;">log</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">Count: </span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">v</span><span style="color:#c0c5ce;">);
});
</span></code></pre>
<p>Now with the new stream we can display it like we did before.</p>
<p>Which leads us into our next point...</p>
<h2 id="rendering-uis-given-data">Rendering UIs given data</h2>
<p>Now that we have a system for generating state through streams,
let's actually show something off.</p>
<p>This is where React.js shines, but for the purpose of this post we'll
build our own system.</p>
<p>Let's say at one point in time our data looks like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{&quot;</span><span style="color:#a3be8c;">Count</span><span style="color:#c0c5ce;">&quot;:</span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">}
</span></code></pre>
<p>And we want to render a UI that represents this information.
So we'll write a simple piece of JS that renders html directly from the map.
To keep it easy, we'll use the keys as div ids.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">//Pure Function to create the dom nodes
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">createDOMNode </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(key, dataMapOrValue) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">div </span><span style="color:#c0c5ce;">= document.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">div</span><span style="color:#c0c5ce;">&quot;);
  </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setAttribute</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">id</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">key</span><span style="color:#c0c5ce;">);

  </span><span style="color:#65737e;">// Recurse for children
  </span><span style="color:#b48ead;">if </span><span style="color:#c0c5ce;">(typeof </span><span style="color:#bf616a;">dataMapOrValue </span><span style="color:#c0c5ce;">=== &quot;</span><span style="color:#a3be8c;">object</span><span style="color:#c0c5ce;">&quot; &amp;&amp; </span><span style="color:#bf616a;">dataMapOrValue </span><span style="color:#c0c5ce;">!== </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">) {
    </span><span style="color:#ebcb8b;">Object</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">keys</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">dataMapOrValue</span><span style="color:#c0c5ce;">).</span><span style="color:#bf616a;">forEach</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(childKey) {
      </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">child </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">createDOMNode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">childKey</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">dataMapOrValue</span><span style="color:#c0c5ce;">[</span><span style="color:#bf616a;">childKey</span><span style="color:#c0c5ce;">]);
      </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">appendChild</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">child</span><span style="color:#c0c5ce;">);
    });
  } </span><span style="color:#b48ead;">else </span><span style="color:#c0c5ce;">{
    </span><span style="color:#65737e;">// There are no children just a value.
    // We set the data to be the content of the node
    // Note this does not protect against XSS
    </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">.innerHTML = </span><span style="color:#bf616a;">dataMapOrValue</span><span style="color:#c0c5ce;">;
  }
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">;
};

</span><span style="color:#65737e;">// Render Data

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">render </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(rootID, appState) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">;
  </span><span style="color:#65737e;">// Check if the root id is even defined
  </span><span style="color:#b48ead;">if </span><span style="color:#c0c5ce;">(document.</span><span style="color:#bf616a;">getElementById</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">) === </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">) {
    </span><span style="color:#65737e;">// We need to add this root id so we can use it later
    </span><span style="color:#bf616a;">root </span><span style="color:#c0c5ce;">= document.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">div</span><span style="color:#c0c5ce;">&quot;);
    </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setAttribute</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">id</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">);
    document.body.</span><span style="color:#bf616a;">appendChild</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">);
  }

  </span><span style="color:#bf616a;">root </span><span style="color:#c0c5ce;">= document.</span><span style="color:#bf616a;">getElementById</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">);
  </span><span style="color:#65737e;">// Clear all the existing content in the page
  </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">.innerHTML = &quot;&quot;;
  </span><span style="color:#65737e;">// render the appState back in
  </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">appendChild</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">createDOMNode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">appState</span><span style="color:#c0c5ce;">));
};

</span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">counter</span><span style="color:#c0c5ce;">&quot;, { Count: </span><span style="color:#d08770;">1 </span><span style="color:#c0c5ce;">});
</span></code></pre>
<p>After running this code on a <a href="about:blank">blank page</a> we have a page
that says <code>1</code>, it worked!</p>
<p>A bit boring though, how about we make it a bit more interesting by updating
on the stream.</p>
<h2 id="rendering-streams-of-data">Rendering Streams of data</h2>
<p>We've figured out how streams work, how to work with streams, and how to
render a page given some data. Now we'll tie all the parts together; render
the stream as it changes over time.</p>
<p>It really is simple. All we have to do is re-render whenever we receive
a new value on the stream.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Let&#39;s observe the countstream and render when we get an update
</span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">counter</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});

</span><span style="color:#65737e;">// And if we wanted to render what the keypress stream tells us, we can do so
// just as easily
</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">keypress</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});
</span></code></pre><h2 id="single-app-state">Single App State</h2>
<p>A single app state means that there is only one object that encapsulates the
state of your application.</p>
<p>Benefits:</p>
<ul>
<li>All changes to the frontend happen from this app state.</li>
<li>You can snapshot this state and be able to recreate the
frontend at any point in time (facilitates undo/redo).</li>
</ul>
<p>Downsides:</p>
<ul>
<li>You may conflate things that shouldn't be together.</li>
</ul>
<p>Having a single place that reflects the whole state is pretty amazing,
how often have you had your app get messed up because of some rogue event?
or hidden state affecting the application, or an ever growing state
scattered around the application.</p>
<p>No more.</p>
<p>A single app state is a natural end to the directed acyclic graph that
we've created with streams.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">stream1 -&gt; mappedStream
                        \\
                         mergedStream -&gt; appStateStream
                        /
stream2 -&gt; reducedStream
</span></code></pre><h2 id="implementing-single-app-state">Implementing Single App State</h2>
<p>In our previous example we had two pieces of state,
the counter and the keypress. We could merge these together into one stream, and
then form a single app state from that stream.</p>
<p>First let's make a helper function that will merge streams for us. To keep it
general and simple we'll take only two streams and a merging function.
It will return a new stream which is the merge of both streams with the mergeFn.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// A merge streams helper function
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">mergeStreams </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(streamA, streamB, mergeFn) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">streamData </span><span style="color:#c0c5ce;">= [</span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">];
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">newStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();

  </span><span style="color:#bf616a;">streamA</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
    </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">[</span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">] = </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">;
    </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">mergeFn</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">apply</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">));
  });
  </span><span style="color:#bf616a;">streamB</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
    </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">[</span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">] = </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">;
    </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">mergeFn</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">apply</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">));
  });

  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">;
};
</span></code></pre>
<p>This implementation will call the merge function with the latest value from the
streams or null if the stream hasn't emitted anything yet. This means the output
can return duplicate values of one of the streams.</p>
<p>(As a side note, the performance impact of duplicate values can be mitigated
with immutable datastructures)</p>
<p>We want to put both the keypress and the counter in one object, so our
merge function will do just that.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">mergeIntoObject </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(keypress, counter) {
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{ counter: </span><span style="color:#bf616a;">counter</span><span style="color:#c0c5ce;">, keypress: </span><span style="color:#bf616a;">keypress </span><span style="color:#c0c5ce;">};
};
</span></code></pre>
<p>Now to create the single app state stream, and render that single app state.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">appStateStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">mergeStreams</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">mergeIntoObject</span><span style="color:#c0c5ce;">);

</span><span style="color:#bf616a;">appStateStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">app</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});
</span></code></pre><h2 id="final-code">Final Code</h2>
<p>Most of these functions are library functions that you wouldn't need to implement
yourself. The final application specific code would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Create the keypress stream
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keypressStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();

</span><span style="color:#65737e;">// Whenever we press a key, we&#39;ll update the stream to be the char code.
</span><span style="color:#ebcb8b;">document</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">onkeypress </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(e) {
  </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#ebcb8b;">String</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">fromCharCode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">e</span><span style="color:#c0c5ce;">.charCode));
};

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keyCountReducer </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(reducedValue, streamSnapshot) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
};
</span><span style="color:#65737e;">// Using our reducedStream helper function we can make a new stream
// That reduces the keypresses into a stream of key counts
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">countStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">reducedStream</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">keyCountReducer</span><span style="color:#c0c5ce;">, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">);

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">mergeIntoObject </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(keypress, counter) {
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{ counter: </span><span style="color:#bf616a;">counter</span><span style="color:#c0c5ce;">, keypress: </span><span style="color:#bf616a;">keypress </span><span style="color:#c0c5ce;">};
};

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">appStateStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">mergeStreams</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">mergeIntoObject</span><span style="color:#c0c5ce;">);

</span><span style="color:#bf616a;">appStateStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">app</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});
</span></code></pre>
<p>You can see a running version of this code <a href="http://jsfiddle.net/Ld3o1Lm5/2/">here</a></p>
<h2 id="the-render-a-closer-look">The render, a closer look</h2>
<p>So what does the render actually do?</p>
<p>Well, it clears the inner html of a containing div and adds an element inside of it.
But that's pretty standard, how are we defining what element is created?
Why yes, it's the createDOMNode function. In fact, if you wanted your data displayed
differently (e.g. in color, or upside down) all you'd have to do is write your own
createDOMNode function that adds the necessary styles or elements.</p>
<p>Essentially, the <code>createDOMNode</code> function controls what your UI will look like.
createDOMNode is a pure function, meaning for the same set of inputs, you'll
always get the same set of outputs, and has no side effects (like an api call).
This wasn't a happy accident, FRP leads to a
design where the functions which build your UI are pure functions!
This means UI components are significantly easier to reason about.</p>
<h2 id="time-travel">Time travel</h2>
<p>Often when people talk about FRP, time travel is bound to get brought up.
Specifically the ability to undo and redo the state of your UI. Hopefully, if
you've gotten this far, you can see how trivial it would be to store the data
used to render the UIs in an array and just move forward and backward to
implement redo and undo.</p>
<h2 id="performance">Performance</h2>
<p>If you care about performance in the slightest, you probably shuddered when
I nuked the containing element and recreated all the children nodes. I don't
blame you; however, that is an implementation detail. While my implementation
is slow, there are implementations (e.g. React) that only update the items and
attributes that have changed, thus reaping performance benefits with no cost
to the programmer! You are getting a better system for modeling UIs and
the performance boosts for free! Furthermore a lot of smart people are working
on React, and as it gets faster, so will your app. Without any effort on your
part.</p>
<h2 id="now-with-actual-libraries">Now with actual libraries</h2>
<p>A lot of what we wrote was the library to get streams up and running,
however those already exists (e.g. <a href="http://baconjs.github.io/">Bacon.js</a> and <a href="https://facebook.github.io/react/">React.js</a>)</p>
<p>A couple quick notes if this is your first time looking at React.js or Bacon.js.</p>
<p><code>getInitialState</code> defines the initial local state of the component.
<code>componentWillMount</code> is a function that gets called before the component
is placed on the DOM.</p>
<p><code>&lt;stream&gt;.scan</code> is our reducing function in Bacon.js parlance.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Our streams just like before
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keypressStream </span><span style="color:#c0c5ce;">= </span><span style="color:#ebcb8b;">Bacon</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">fromEventTarget</span><span style="color:#c0c5ce;">(document.body, &quot;</span><span style="color:#a3be8c;">keypress</span><span style="color:#c0c5ce;">&quot;).</span><span style="color:#bf616a;">map</span><span style="color:#c0c5ce;">(
  </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(e) {
    </span><span style="color:#b48ead;">return </span><span style="color:#ebcb8b;">String</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">fromCharCode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">e</span><span style="color:#c0c5ce;">.charCode);
  }
);

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">countStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">scan</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">, </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(count, key) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">count </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
});

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">KeyPressComponent </span><span style="color:#c0c5ce;">= </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createClass</span><span style="color:#c0c5ce;">({
  </span><span style="color:#8fa1b3;">getInitialState</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
    </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{ count: </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">, keypress: &quot;</span><span style="color:#a3be8c;">&lt;press a key&gt;</span><span style="color:#c0c5ce;">&quot;, totalWords: &quot;&quot; };
  },
  </span><span style="color:#8fa1b3;">componentWillMount</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
    </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.props.countStream.</span><span style="color:#bf616a;">onValue</span><span style="color:#c0c5ce;">(
      </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(count) {
        </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setState</span><span style="color:#c0c5ce;">({ count: </span><span style="color:#bf616a;">count </span><span style="color:#c0c5ce;">});
      }.</span><span style="color:#bf616a;">bind</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">)
    );

    </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.props.keypressStream.</span><span style="color:#bf616a;">onValue</span><span style="color:#c0c5ce;">(
      </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(key) {
        </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setState</span><span style="color:#c0c5ce;">({ keypress: </span><span style="color:#bf616a;">key </span><span style="color:#c0c5ce;">});
      }.</span><span style="color:#bf616a;">bind</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">)
    );

    </span><span style="color:#65737e;">// Add something extra because why not
    </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.props.keypressStream
      .</span><span style="color:#bf616a;">scan</span><span style="color:#c0c5ce;">(&quot;&quot;, </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(totalWords, key) {
        </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">totalWords </span><span style="color:#c0c5ce;">+ </span><span style="color:#bf616a;">key</span><span style="color:#c0c5ce;">;
      })
      .</span><span style="color:#bf616a;">onValue</span><span style="color:#c0c5ce;">(
        </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(totalWords) {
          </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setState</span><span style="color:#c0c5ce;">({ totalWords: </span><span style="color:#bf616a;">totalWords </span><span style="color:#c0c5ce;">});
        }.</span><span style="color:#bf616a;">bind</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">)
      );
  },
  </span><span style="color:#8fa1b3;">render</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
    </span><span style="color:#b48ead;">return </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.DOM.</span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">(
      </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">,
      </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">h1</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, &quot;</span><span style="color:#a3be8c;">Count: </span><span style="color:#c0c5ce;">&quot; + </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.state.count),
      </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">h1</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, &quot;</span><span style="color:#a3be8c;">Keypress: </span><span style="color:#c0c5ce;">&quot; + </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.state.keypress),
      </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">h1</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, &quot;</span><span style="color:#a3be8c;">Total words: </span><span style="color:#c0c5ce;">&quot; + </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.state.totalWords)
    );
  }
});

</span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(
  </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">KeyPressComponent</span><span style="color:#c0c5ce;">, {
    keypressStream: </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">,
    countStream: </span><span style="color:#bf616a;">countStream
  </span><span style="color:#c0c5ce;">}),
  document.body
);
</span></code></pre>
<p>jsfiddle for this code <a href="http://jsfiddle.net/jf2j62wj/10/">here</a>.</p>
<h2 id="closing-notes">Closing Notes</h2>
<p><a href="https://facebook.github.io/react/">React</a> is great for reactively rendering the ui.
<a href="http://baconjs.github.io/">Bacon.js</a> is a great library that implements these streams.</p>
<p>If you're looking to really delve into FRP:
<a href="http://elm-lang.org/">Elm</a> has a well thought out FRP system in a haskell like language.</p>
<p>If you're feeling adventurous give Om &amp; Clojurescript a shot.
<a href="https://github.com/swannodette/om">Om</a> is a great tool that adds immutability
to React, and brings React to Clojurescript</p>
<p>Finally, Evan Czaplicki (Elm creator) did a <a href="https://www.youtube.com/watch?v=Agu6jipKfYw">great talk on FRP</a></p>
"""

+++
<p>Maybe you've heard of <a href="https://facebook.github.io/react/">React</a>, <a href="https://github.com/swannodette/om">Om</a>,
or <a href="http://elm-lang.org/">Elm</a>, and wondering: what's the deal with
functional reactive programming (FRP)?</p>
<p>This post will act as primer on FRP using vanilla JS, but the ideas presented
here translate pretty easily in any language and UI system.</p>
<p>So let's start with an informal, pragmatic definition of FRP:</p>
<blockquote>
<p>Use streams of data to create the application state (data)</p>
</blockquote>
<p>And</p>
<blockquote>
<p>Build a UI given only the application state with pure functions (view)</p>
</blockquote>
<h2 id="streams-and-arrays">Streams and arrays</h2>
<p>You can imagine streams of data as a set of values over time.</p>
<p>A stream of numbers representing a counter would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[0,1,2,3,4,5,6,...]
</span></code></pre>
<p>Each number is essentially a snapshot of the value at that time.</p>
<p>Streams are similar to arrays, but the main difference is time.
An immutable array has all the values it will ever have when it is created, while a stream represents all the values that have happened and will
happen.</p>
<p>Here's a concrete example: You are an owner of an exclusive restaurant.
It's so exclusive that people have to make reservations months in advance.
Every night you have a list of people at your restaurant (because they've
already made reservations). Imagine the list being <code>[amy, sally, bob]</code>.
To count the number of guests, we would just reduce over the list
adding 1 for every guest. If we wanted to know how much each guest spent
we would map against a function that tells us the guest's bill.</p>
<p>This is just a normal array with normal map/reduce construct.
For completeness here's the equivalent code.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">guests </span><span style="color:#c0c5ce;">= [&quot;</span><span style="color:#a3be8c;">amy</span><span style="color:#c0c5ce;">&quot;, &quot;</span><span style="color:#a3be8c;">sally</span><span style="color:#c0c5ce;">&quot;, &quot;</span><span style="color:#a3be8c;">bob</span><span style="color:#c0c5ce;">&quot;];
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">bills </span><span style="color:#c0c5ce;">= { amy: </span><span style="color:#d08770;">22.5</span><span style="color:#c0c5ce;">, sally: </span><span style="color:#d08770;">67.0</span><span style="color:#c0c5ce;">, bob: </span><span style="color:#d08770;">6.0 </span><span style="color:#c0c5ce;">};

</span><span style="color:#65737e;">// Count the guests
</span><span style="color:#bf616a;">guests</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">reduce</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(sum, guest) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">sum </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
}, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">);
</span><span style="color:#65737e;">// =&gt; 3
// Get the bills
</span><span style="color:#bf616a;">guests</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">map</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(guest) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">bills</span><span style="color:#c0c5ce;">[</span><span style="color:#bf616a;">guest</span><span style="color:#c0c5ce;">];
});
</span><span style="color:#65737e;">// =&gt; [22.5, 67, 6]
</span></code></pre>
<p>Unfortunately Sally had some bad fish and died after eating at your
restaurant, so everyone has cancelled their reservations and you are
now a fast food place. In this case you don't have a list of guests,
instead you have a <em>stream</em> of people who come in and order food.
<code>Frank</code> might come in at 10 am, followed by <code>Jack</code> at 2 pm. To get
similar data as before we would again map/reduce over the stream,
but since we are operating over a stream that never ends, the values
from map/reduce themselves become streams that never end.</p>
<p>Here is some equivalent pseudo code for streams that calculates
the <code>guestCounts</code> and the <code>guestBills</code>.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#bf616a;">guests      </span><span style="color:#c0c5ce;">= [... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#bf616a;">Frank</span><span style="color:#c0c5ce;">, ... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#bf616a;">Jack</span><span style="color:#c0c5ce;">, ... ]

</span><span style="color:#bf616a;">guestCounts </span><span style="color:#c0c5ce;">= [... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">,     ... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">2</span><span style="color:#c0c5ce;">, ... ]
</span><span style="color:#bf616a;">guestBills </span><span style="color:#c0c5ce;">=  [... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">5.50</span><span style="color:#c0c5ce;">,  ... </span><span style="color:#bf616a;">time passes </span><span style="color:#c0c5ce;">..., </span><span style="color:#d08770;">6.50</span><span style="color:#c0c5ce;">, ... ]
</span></code></pre>
<p>So a stream is just like an array that never ends, and represents
snapshots of time.</p>
<p>Now that we have an intuitive idea what streams are, we can actually
implement them.</p>
<h2 id="streams-of-data">Streams of data</h2>
<p>A stream of numbers representing a counter would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[0,1,2,3,4,5,6,...]
</span></code></pre>
<p>If we wanted to keep track of how long someone was on our page,
we could just display the latest value of the counter stream
in our UI and that would be enough.</p>
<p>A more involved example: Imagine we had a stream of data
that represents the keys pressed on the keyboard.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[&quot;p&quot;,&quot;w&quot;,&quot;n&quot;,&quot;2&quot;,&quot;o&quot;,&quot;w&quot;,&quot;n&quot;,...]
</span></code></pre>
<p>Now we want to have a stream that represents the state of the system,
say the amount of keys pressed.</p>
<p>Our key count stream would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">[&quot;p&quot;,&quot;w&quot;,&quot;n&quot;,&quot;2&quot;,&quot;o&quot;,&quot;w&quot;,&quot;n&quot;,...]
=&gt;
[ 1,  2,  3,  4,  5,  6,  7, ...]
</span></code></pre>
<p>This transformation would happen with a reducing function.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keyCountReducer </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(reducedValue, streamSnapshot) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
};
</span></code></pre>
<p>This function takes in the stream value, and a reduced value so far, and
returns a new reduced value. In this case a simple increment.</p>
<p>We've talked about streams for a while now, let's implement them.</p>
<p>In the following code, we create a function that will return an object with two
methods: <code>observe</code> for registering event listeners and <code>update</code> for adding a value
to the stream.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// A function to make streams for us
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">streamMaker </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">registeredListeners </span><span style="color:#c0c5ce;">= [];
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{
    </span><span style="color:#65737e;">// Have an observe function, so
    // people who are interested can
    // get notified when there is an update
    </span><span style="color:#8fa1b3;">observe</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(callback) {
      </span><span style="color:#bf616a;">registeredListeners</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">push</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">callback</span><span style="color:#c0c5ce;">);
    },

    </span><span style="color:#65737e;">// Add a value to this stream
    // Once added, will notify all
    // interested parties
    </span><span style="color:#8fa1b3;">update</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
      </span><span style="color:#bf616a;">registeredListeners</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">forEach</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(cb) {
        </span><span style="color:#bf616a;">cb</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
      });
    }
  };
};
</span></code></pre>
<p>We also want to make a helper function that will create a new reduced stream
given an existing <code>stream</code>, a <code>reducingFunction</code>, and an <code>initialReducedValue</code>:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// A function to make a new stream from an existing stream
// a reducing function, and an initial reduced value
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">reducedStream </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(stream, reducingFunction, initialReducedValue) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">newStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">initialReducedValue</span><span style="color:#c0c5ce;">;

  </span><span style="color:#bf616a;">stream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(streamSnapshotValue) {
    </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">reducingFunction</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">reducedValue</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">streamSnapshotValue</span><span style="color:#c0c5ce;">);
    </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">reducedValue</span><span style="color:#c0c5ce;">);
  });
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">;
};
</span></code></pre>
<p>Now to implement the keypress stream and count stream.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Our reducer from before
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keyCountReducer </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(reducedValue, streamSnapshot) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
};

</span><span style="color:#65737e;">// Create the keypress stream
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keypressStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();
</span><span style="color:#65737e;">// an observer will have that side effect of printing out to the console
</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(v) {
  console.</span><span style="color:#96b5b4;">log</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">key: </span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">v</span><span style="color:#c0c5ce;">);
});

</span><span style="color:#65737e;">// Whenever we press a key, we&#39;ll update the stream to be the char code.
</span><span style="color:#ebcb8b;">document</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">onkeypress </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(e) {
  </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#ebcb8b;">String</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">fromCharCode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">e</span><span style="color:#c0c5ce;">.charCode));
};

</span><span style="color:#65737e;">// Using our reducedStream helper function we can make a new stream
// That reduces the keypresses into a stream of key counts
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">countStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">reducedStream</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">keyCountReducer</span><span style="color:#c0c5ce;">, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">);
</span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(v) {
  console.</span><span style="color:#96b5b4;">log</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">Count: </span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">v</span><span style="color:#c0c5ce;">);
});
</span></code></pre>
<p>Now with the new stream we can display it like we did before.</p>
<p>Which leads us into our next point...</p>
<h2 id="rendering-uis-given-data">Rendering UIs given data</h2>
<p>Now that we have a system for generating state through streams,
let's actually show something off.</p>
<p>This is where React.js shines, but for the purpose of this post we'll
build our own system.</p>
<p>Let's say at one point in time our data looks like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{&quot;</span><span style="color:#a3be8c;">Count</span><span style="color:#c0c5ce;">&quot;:</span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">}
</span></code></pre>
<p>And we want to render a UI that represents this information.
So we'll write a simple piece of JS that renders html directly from the map.
To keep it easy, we'll use the keys as div ids.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">//Pure Function to create the dom nodes
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">createDOMNode </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(key, dataMapOrValue) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">div </span><span style="color:#c0c5ce;">= document.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">div</span><span style="color:#c0c5ce;">&quot;);
  </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setAttribute</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">id</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">key</span><span style="color:#c0c5ce;">);

  </span><span style="color:#65737e;">// Recurse for children
  </span><span style="color:#b48ead;">if </span><span style="color:#c0c5ce;">(typeof </span><span style="color:#bf616a;">dataMapOrValue </span><span style="color:#c0c5ce;">=== &quot;</span><span style="color:#a3be8c;">object</span><span style="color:#c0c5ce;">&quot; &amp;&amp; </span><span style="color:#bf616a;">dataMapOrValue </span><span style="color:#c0c5ce;">!== </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">) {
    </span><span style="color:#ebcb8b;">Object</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">keys</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">dataMapOrValue</span><span style="color:#c0c5ce;">).</span><span style="color:#bf616a;">forEach</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(childKey) {
      </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">child </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">createDOMNode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">childKey</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">dataMapOrValue</span><span style="color:#c0c5ce;">[</span><span style="color:#bf616a;">childKey</span><span style="color:#c0c5ce;">]);
      </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">appendChild</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">child</span><span style="color:#c0c5ce;">);
    });
  } </span><span style="color:#b48ead;">else </span><span style="color:#c0c5ce;">{
    </span><span style="color:#65737e;">// There are no children just a value.
    // We set the data to be the content of the node
    // Note this does not protect against XSS
    </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">.innerHTML = </span><span style="color:#bf616a;">dataMapOrValue</span><span style="color:#c0c5ce;">;
  }
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">;
};

</span><span style="color:#65737e;">// Render Data

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">render </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(rootID, appState) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">;
  </span><span style="color:#65737e;">// Check if the root id is even defined
  </span><span style="color:#b48ead;">if </span><span style="color:#c0c5ce;">(document.</span><span style="color:#bf616a;">getElementById</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">) === </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">) {
    </span><span style="color:#65737e;">// We need to add this root id so we can use it later
    </span><span style="color:#bf616a;">root </span><span style="color:#c0c5ce;">= document.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">div</span><span style="color:#c0c5ce;">&quot;);
    </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setAttribute</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">id</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">);
    document.body.</span><span style="color:#bf616a;">appendChild</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">);
  }

  </span><span style="color:#bf616a;">root </span><span style="color:#c0c5ce;">= document.</span><span style="color:#bf616a;">getElementById</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">);
  </span><span style="color:#65737e;">// Clear all the existing content in the page
  </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">.innerHTML = &quot;&quot;;
  </span><span style="color:#65737e;">// render the appState back in
  </span><span style="color:#bf616a;">root</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">appendChild</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">createDOMNode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">rootID</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">appState</span><span style="color:#c0c5ce;">));
};

</span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">counter</span><span style="color:#c0c5ce;">&quot;, { Count: </span><span style="color:#d08770;">1 </span><span style="color:#c0c5ce;">});
</span></code></pre>
<p>After running this code on a <a href="about:blank">blank page</a> we have a page
that says <code>1</code>, it worked!</p>
<p>A bit boring though, how about we make it a bit more interesting by updating
on the stream.</p>
<h2 id="rendering-streams-of-data">Rendering Streams of data</h2>
<p>We've figured out how streams work, how to work with streams, and how to
render a page given some data. Now we'll tie all the parts together; render
the stream as it changes over time.</p>
<p>It really is simple. All we have to do is re-render whenever we receive
a new value on the stream.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Let&#39;s observe the countstream and render when we get an update
</span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">counter</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});

</span><span style="color:#65737e;">// And if we wanted to render what the keypress stream tells us, we can do so
// just as easily
</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">keypress</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});
</span></code></pre><h2 id="single-app-state">Single App State</h2>
<p>A single app state means that there is only one object that encapsulates the
state of your application.</p>
<p>Benefits:</p>
<ul>
<li>All changes to the frontend happen from this app state.</li>
<li>You can snapshot this state and be able to recreate the
frontend at any point in time (facilitates undo/redo).</li>
</ul>
<p>Downsides:</p>
<ul>
<li>You may conflate things that shouldn't be together.</li>
</ul>
<p>Having a single place that reflects the whole state is pretty amazing,
how often have you had your app get messed up because of some rogue event?
or hidden state affecting the application, or an ever growing state
scattered around the application.</p>
<p>No more.</p>
<p>A single app state is a natural end to the directed acyclic graph that
we've created with streams.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">stream1 -&gt; mappedStream
                        \
                         mergedStream -&gt; appStateStream
                        /
stream2 -&gt; reducedStream
</span></code></pre><h2 id="implementing-single-app-state">Implementing Single App State</h2>
<p>In our previous example we had two pieces of state,
the counter and the keypress. We could merge these together into one stream, and
then form a single app state from that stream.</p>
<p>First let's make a helper function that will merge streams for us. To keep it
general and simple we'll take only two streams and a merging function.
It will return a new stream which is the merge of both streams with the mergeFn.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// A merge streams helper function
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">mergeStreams </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(streamA, streamB, mergeFn) {
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">streamData </span><span style="color:#c0c5ce;">= [</span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">];
  </span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">newStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();

  </span><span style="color:#bf616a;">streamA</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
    </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">[</span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">] = </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">;
    </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">mergeFn</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">apply</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">));
  });
  </span><span style="color:#bf616a;">streamB</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
    </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">[</span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">] = </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">;
    </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">mergeFn</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">apply</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">streamData</span><span style="color:#c0c5ce;">));
  });

  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">newStream</span><span style="color:#c0c5ce;">;
};
</span></code></pre>
<p>This implementation will call the merge function with the latest value from the
streams or null if the stream hasn't emitted anything yet. This means the output
can return duplicate values of one of the streams.</p>
<p>(As a side note, the performance impact of duplicate values can be mitigated
with immutable datastructures)</p>
<p>We want to put both the keypress and the counter in one object, so our
merge function will do just that.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">mergeIntoObject </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(keypress, counter) {
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{ counter: </span><span style="color:#bf616a;">counter</span><span style="color:#c0c5ce;">, keypress: </span><span style="color:#bf616a;">keypress </span><span style="color:#c0c5ce;">};
};
</span></code></pre>
<p>Now to create the single app state stream, and render that single app state.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">var </span><span style="color:#bf616a;">appStateStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">mergeStreams</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">mergeIntoObject</span><span style="color:#c0c5ce;">);

</span><span style="color:#bf616a;">appStateStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">app</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});
</span></code></pre><h2 id="final-code">Final Code</h2>
<p>Most of these functions are library functions that you wouldn't need to implement
yourself. The final application specific code would look like:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Create the keypress stream
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keypressStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">streamMaker</span><span style="color:#c0c5ce;">();

</span><span style="color:#65737e;">// Whenever we press a key, we&#39;ll update the stream to be the char code.
</span><span style="color:#ebcb8b;">document</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">onkeypress </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(e) {
  </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">update</span><span style="color:#c0c5ce;">(</span><span style="color:#ebcb8b;">String</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">fromCharCode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">e</span><span style="color:#c0c5ce;">.charCode));
};

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keyCountReducer </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(reducedValue, streamSnapshot) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">reducedValue </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
};
</span><span style="color:#65737e;">// Using our reducedStream helper function we can make a new stream
// That reduces the keypresses into a stream of key counts
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">countStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">reducedStream</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">keyCountReducer</span><span style="color:#c0c5ce;">, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">);

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">mergeIntoObject </span><span style="color:#c0c5ce;">= </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(keypress, counter) {
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{ counter: </span><span style="color:#bf616a;">counter</span><span style="color:#c0c5ce;">, keypress: </span><span style="color:#bf616a;">keypress </span><span style="color:#c0c5ce;">};
};

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">appStateStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">mergeStreams</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">countStream</span><span style="color:#c0c5ce;">, </span><span style="color:#bf616a;">mergeIntoObject</span><span style="color:#c0c5ce;">);

</span><span style="color:#bf616a;">appStateStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">observe</span><span style="color:#c0c5ce;">(</span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(value) {
  </span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">app</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#bf616a;">value</span><span style="color:#c0c5ce;">);
});
</span></code></pre>
<p>You can see a running version of this code <a href="http://jsfiddle.net/Ld3o1Lm5/2/">here</a></p>
<h2 id="the-render-a-closer-look">The render, a closer look</h2>
<p>So what does the render actually do?</p>
<p>Well, it clears the inner html of a containing div and adds an element inside of it.
But that's pretty standard, how are we defining what element is created?
Why yes, it's the createDOMNode function. In fact, if you wanted your data displayed
differently (e.g. in color, or upside down) all you'd have to do is write your own
createDOMNode function that adds the necessary styles or elements.</p>
<p>Essentially, the <code>createDOMNode</code> function controls what your UI will look like.
createDOMNode is a pure function, meaning for the same set of inputs, you'll
always get the same set of outputs, and has no side effects (like an api call).
This wasn't a happy accident, FRP leads to a
design where the functions which build your UI are pure functions!
This means UI components are significantly easier to reason about.</p>
<h2 id="time-travel">Time travel</h2>
<p>Often when people talk about FRP, time travel is bound to get brought up.
Specifically the ability to undo and redo the state of your UI. Hopefully, if
you've gotten this far, you can see how trivial it would be to store the data
used to render the UIs in an array and just move forward and backward to
implement redo and undo.</p>
<h2 id="performance">Performance</h2>
<p>If you care about performance in the slightest, you probably shuddered when
I nuked the containing element and recreated all the children nodes. I don't
blame you; however, that is an implementation detail. While my implementation
is slow, there are implementations (e.g. React) that only update the items and
attributes that have changed, thus reaping performance benefits with no cost
to the programmer! You are getting a better system for modeling UIs and
the performance boosts for free! Furthermore a lot of smart people are working
on React, and as it gets faster, so will your app. Without any effort on your
part.</p>
<h2 id="now-with-actual-libraries">Now with actual libraries</h2>
<p>A lot of what we wrote was the library to get streams up and running,
however those already exists (e.g. <a href="http://baconjs.github.io/">Bacon.js</a> and <a href="https://facebook.github.io/react/">React.js</a>)</p>
<p>A couple quick notes if this is your first time looking at React.js or Bacon.js.</p>
<p><code>getInitialState</code> defines the initial local state of the component.
<code>componentWillMount</code> is a function that gets called before the component
is placed on the DOM.</p>
<p><code>&lt;stream&gt;.scan</code> is our reducing function in Bacon.js parlance.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// Our streams just like before
</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">keypressStream </span><span style="color:#c0c5ce;">= </span><span style="color:#ebcb8b;">Bacon</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">fromEventTarget</span><span style="color:#c0c5ce;">(document.body, &quot;</span><span style="color:#a3be8c;">keypress</span><span style="color:#c0c5ce;">&quot;).</span><span style="color:#bf616a;">map</span><span style="color:#c0c5ce;">(
  </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(e) {
    </span><span style="color:#b48ead;">return </span><span style="color:#ebcb8b;">String</span><span style="color:#c0c5ce;">.</span><span style="color:#96b5b4;">fromCharCode</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">e</span><span style="color:#c0c5ce;">.charCode);
  }
);

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">countStream </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">scan</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">, </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(count, key) {
  </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">count </span><span style="color:#c0c5ce;">+ </span><span style="color:#d08770;">1</span><span style="color:#c0c5ce;">;
});

</span><span style="color:#b48ead;">var </span><span style="color:#bf616a;">KeyPressComponent </span><span style="color:#c0c5ce;">= </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createClass</span><span style="color:#c0c5ce;">({
  </span><span style="color:#8fa1b3;">getInitialState</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
    </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">{ count: </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">, keypress: &quot;</span><span style="color:#a3be8c;">&lt;press a key&gt;</span><span style="color:#c0c5ce;">&quot;, totalWords: &quot;&quot; };
  },
  </span><span style="color:#8fa1b3;">componentWillMount</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
    </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.props.countStream.</span><span style="color:#bf616a;">onValue</span><span style="color:#c0c5ce;">(
      </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(count) {
        </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setState</span><span style="color:#c0c5ce;">({ count: </span><span style="color:#bf616a;">count </span><span style="color:#c0c5ce;">});
      }.</span><span style="color:#bf616a;">bind</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">)
    );

    </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.props.keypressStream.</span><span style="color:#bf616a;">onValue</span><span style="color:#c0c5ce;">(
      </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(key) {
        </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setState</span><span style="color:#c0c5ce;">({ keypress: </span><span style="color:#bf616a;">key </span><span style="color:#c0c5ce;">});
      }.</span><span style="color:#bf616a;">bind</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">)
    );

    </span><span style="color:#65737e;">// Add something extra because why not
    </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.props.keypressStream
      .</span><span style="color:#bf616a;">scan</span><span style="color:#c0c5ce;">(&quot;&quot;, </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(totalWords, key) {
        </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">totalWords </span><span style="color:#c0c5ce;">+ </span><span style="color:#bf616a;">key</span><span style="color:#c0c5ce;">;
      })
      .</span><span style="color:#bf616a;">onValue</span><span style="color:#c0c5ce;">(
        </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">(totalWords) {
          </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">setState</span><span style="color:#c0c5ce;">({ totalWords: </span><span style="color:#bf616a;">totalWords </span><span style="color:#c0c5ce;">});
        }.</span><span style="color:#bf616a;">bind</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">)
      );
  },
  </span><span style="color:#8fa1b3;">render</span><span style="color:#c0c5ce;">: </span><span style="color:#b48ead;">function</span><span style="color:#c0c5ce;">() {
    </span><span style="color:#b48ead;">return </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.DOM.</span><span style="color:#bf616a;">div</span><span style="color:#c0c5ce;">(
      </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">,
      </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">h1</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, &quot;</span><span style="color:#a3be8c;">Count: </span><span style="color:#c0c5ce;">&quot; + </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.state.count),
      </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">h1</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, &quot;</span><span style="color:#a3be8c;">Keypress: </span><span style="color:#c0c5ce;">&quot; + </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.state.keypress),
      </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(&quot;</span><span style="color:#a3be8c;">h1</span><span style="color:#c0c5ce;">&quot;, </span><span style="color:#d08770;">null</span><span style="color:#c0c5ce;">, &quot;</span><span style="color:#a3be8c;">Total words: </span><span style="color:#c0c5ce;">&quot; + </span><span style="color:#bf616a;">this</span><span style="color:#c0c5ce;">.state.totalWords)
    );
  }
});

</span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">render</span><span style="color:#c0c5ce;">(
  </span><span style="color:#ebcb8b;">React</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">createElement</span><span style="color:#c0c5ce;">(</span><span style="color:#bf616a;">KeyPressComponent</span><span style="color:#c0c5ce;">, {
    keypressStream: </span><span style="color:#bf616a;">keypressStream</span><span style="color:#c0c5ce;">,
    countStream: </span><span style="color:#bf616a;">countStream
  </span><span style="color:#c0c5ce;">}),
  document.body
);
</span></code></pre>
<p>jsfiddle for this code <a href="http://jsfiddle.net/jf2j62wj/10/">here</a>.</p>
<h2 id="closing-notes">Closing Notes</h2>
<p><a href="https://facebook.github.io/react/">React</a> is great for reactively rendering the ui.
<a href="http://baconjs.github.io/">Bacon.js</a> is a great library that implements these streams.</p>
<p>If you're looking to really delve into FRP:
<a href="http://elm-lang.org/">Elm</a> has a well thought out FRP system in a haskell like language.</p>
<p>If you're feeling adventurous give Om &amp; Clojurescript a shot.
<a href="https://github.com/swannodette/om">Om</a> is a great tool that adds immutability
to React, and brings React to Clojurescript</p>
<p>Finally, Evan Czaplicki (Elm creator) did a <a href="https://www.youtube.com/watch?v=Agu6jipKfYw">great talk on FRP</a></p>

