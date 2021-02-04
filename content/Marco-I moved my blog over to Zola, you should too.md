
+++
title = "I moved my blog over to Zola, you should too"
originalLink = "https://marcopolo.io/code/migrating-to-zola/"
date = 2019-08-22T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Blogging
I started this blog like many other folks, on GitHub Pages. It was great at
the time. You c..."""

[extra]
author = "Marco"
raw = """
<h1 id="blogging">Blogging</h1>
<p>I started this blog like many other folks, on GitHub Pages. It was great at
the time. You can have a source repo that compiles to a blog. Neat! Over time
though I started really feeling the pain points with it. When I wanted to
write a quick post about something I'd often spend hours just trying to get
the right Ruby environment set up so I can see my blog locally. When I got an
email from GitHub saying that my blog repo has a security vulnerability in
one of its Gems, I took the opportunity to switch over to
<a href="https://www.getzola.org">Zola</a>.</p>
<h1 id="zola">Zola</h1>
<p>Zola make more sense to me than Jekyll. I think about my posts in a
hierarchy. I'd like my source code to match my mental representation. If you
look at the <a href="https://marcopolo.io/code/migrating-to-zola/">source</a> of this blog, you'll see I have 3 folders (code, books,
life). In each folder there are relevant posts. I wanted my blog to show the
contents folder as different sections. For the life of me I couldn't figure
out how to do that in Jekyll. I ended up just using a single folder for all
my posts and using the category metadata in the front-matter to create the
different sections. With Zola, this kind of just worked. I had to create an
<code>_index.md</code> file to provide some metadata, but nothing overly verbose.</p>
<h1 id="i-m-not-a-jekyll-pro">I'm not a Jekyll pro...</h1>
<p>Or even really any level past beginner. I image if you've already heavily
invested yourself in the Jekyll ecosystem this probably wouldn't make sense
for you. I'm sure there are all sorts of tricks and features that Jekyll
can do that Zola cannot. I'm Okay with that. I really don't need that much
from my blogging library.</p>
<p>Zola has 3 commands: <code>build</code>, <code>serve</code>, and <code>init</code>. They do what you'd expect
and nothing more. I really admire this philosophy. Whittle down your feature
set and make those features a <em>joy</em> to use.</p>
<h1 id="fast">Fast</h1>
<p>Changes in Zola propagate quickly. Zola rebuilds my (admittedly very small blog) in less than a millisecond. Zola comes with a livereload script that automatically updates your browser when you are in <code>serve</code> mode. It's feasible to write your post and see how it renders almost instantly.</p>
<h1 id="transition">Transition</h1>
<p>The biggest change was converting Jekyll's front-matter (the stuff at the top
of the md files) format into Zola's front-matter format. Which was changing
this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">---
layout: post
title: Interacting with Go from React Native through JSI
categories: javascript react-native jsi go
---

</span></code></pre>
<p>into this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">\u002B\u002B\u002B
title = &quot;Interacting with Go from React Native through JSI&quot;
[taxonomies]
tags = [&quot;javascript&quot;, &quot;react-native&quot;, &quot;JSI&quot;, &quot;Go&quot;]
\u002B\u002B\u002B
</span></code></pre>
<p>There was also a slight rewrite in the template files that was necessary
since Zola uses the <a href="https://tera.netlify.com">Tera Templating Engine</a></p>
<p>The rest was just moving (I'd argue organizing) files around.</p>
<h1 id="prettier-repo">Prettier Repo</h1>
<p>I think at the end the repo became a little prettier to look at. You could
argue it's a small thing, but I think these small things matter. It's already
hard enough to sit down and write a post. I want every bit of the experience
to be beautiful.</p>
<p>But don't take my word for it! judge yourself: <a href="https://github.com/MarcoPolo/marcopolo.github.io/tree/jekyll_archive">Jekyll</a> vs. <a href="https://github.com/MarcoPolo/marcopolo.github.io">Zola</a></p>
"""

+++
<h1 id="blogging">Blogging</h1>
<p>I started this blog like many other folks, on GitHub Pages. It was great at
the time. You can have a source repo that compiles to a blog. Neat! Over time
though I started really feeling the pain points with it. When I wanted to
write a quick post about something I'd often spend hours just trying to get
the right Ruby environment set up so I can see my blog locally. When I got an
email from GitHub saying that my blog repo has a security vulnerability in
one of its Gems, I took the opportunity to switch over to
<a href="https://www.getzola.org">Zola</a>.</p>
<h1 id="zola">Zola</h1>
<p>Zola make more sense to me than Jekyll. I think about my posts in a
hierarchy. I'd like my source code to match my mental representation. If you
look at the <a href="https://marcopolo.io/code/migrating-to-zola/">source</a> of this blog, you'll see I have 3 folders (code, books,
life). In each folder there are relevant posts. I wanted my blog to show the
contents folder as different sections. For the life of me I couldn't figure
out how to do that in Jekyll. I ended up just using a single folder for all
my posts and using the category metadata in the front-matter to create the
different sections. With Zola, this kind of just worked. I had to create an
<code>_index.md</code> file to provide some metadata, but nothing overly verbose.</p>
<h1 id="i-m-not-a-jekyll-pro">I'm not a Jekyll pro...</h1>
<p>Or even really any level past beginner. I image if you've already heavily
invested yourself in the Jekyll ecosystem this probably wouldn't make sense
for you. I'm sure there are all sorts of tricks and features that Jekyll
can do that Zola cannot. I'm Okay with that. I really don't need that much
from my blogging library.</p>
<p>Zola has 3 commands: <code>build</code>, <code>serve</code>, and <code>init</code>. They do what you'd expect
and nothing more. I really admire this philosophy. Whittle down your feature
set and make those features a <em>joy</em> to use.</p>
<h1 id="fast">Fast</h1>
<p>Changes in Zola propagate quickly. Zola rebuilds my (admittedly very small blog) in less than a millisecond. Zola comes with a livereload script that automatically updates your browser when you are in <code>serve</code> mode. It's feasible to write your post and see how it renders almost instantly.</p>
<h1 id="transition">Transition</h1>
<p>The biggest change was converting Jekyll's front-matter (the stuff at the top
of the md files) format into Zola's front-matter format. Which was changing
this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">---
layout: post
title: Interacting with Go from React Native through JSI
categories: javascript react-native jsi go
---

</span></code></pre>
<p>into this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">\u002B\u002B\u002B
title = &quot;Interacting with Go from React Native through JSI&quot;
[taxonomies]
tags = [&quot;javascript&quot;, &quot;react-native&quot;, &quot;JSI&quot;, &quot;Go&quot;]
\u002B\u002B\u002B
</span></code></pre>
<p>There was also a slight rewrite in the template files that was necessary
since Zola uses the <a href="https://tera.netlify.com">Tera Templating Engine</a></p>
<p>The rest was just moving (I'd argue organizing) files around.</p>
<h1 id="prettier-repo">Prettier Repo</h1>
<p>I think at the end the repo became a little prettier to look at. You could
argue it's a small thing, but I think these small things matter. It's already
hard enough to sit down and write a post. I want every bit of the experience
to be beautiful.</p>
<p>But don't take my word for it! judge yourself: <a href="https://github.com/MarcoPolo/marcopolo.github.io/tree/jekyll_archive">Jekyll</a> vs. <a href="https://github.com/MarcoPolo/marcopolo.github.io">Zola</a></p>

