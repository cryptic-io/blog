
+++
title = "Visualization 2"
originalLink = "https://blog.mediocregopher.com/2018/11/12/viz-2.html"
date = 2018-11-12T00:00:00.000Z
template = "html_content/raw.html"
summary = """
goog.require("viz.core");


This visualization builds on the previous. Structurally the cartesian gr..."""

[extra]
author = "Brian Picciano"
raw = """
<script src="/assets/viz/2/goog/base.js"></script>

<script src="/assets/viz/2/cljs_deps.js"></script>

<script>goog.require("viz.core");</script>

<p align="center"><canvas id="viz"></canvas></p>

<p>This visualization builds on the previous. Structurally the cartesian grid has
been turned into an isometric one, but this is more of an environmental change
than a behavioral one.</p>

<p>Behavioral changes which were made:</p>

<ul>
  <li>
    <p>When a live point is deciding its next spawn points, it first sorts the set of
empty adjacent points from closest-to-the-center to farthest. It then chooses
a number <code class="language-plaintext highlighter-rouge">n</code> between <code class="language-plaintext highlighter-rouge">0</code> to <code class="language-plaintext highlighter-rouge">N</code> (where <code class="language-plaintext highlighter-rouge">N</code> is the sorted set’s size) and
spawns new points from the first <code class="language-plaintext highlighter-rouge">n</code> points of the sorted set. <code class="language-plaintext highlighter-rouge">n</code> is chosen
based on:</p>

    <ul>
      <li>
        <p>The live point’s linear distance from the center.</p>
      </li>
      <li>
        <p>A random multiplier.</p>
      </li>
    </ul>
  </li>
  <li>
    <p>Each point is spawned with an attached color, where the color chosen is a
slightly different hue than its parent. The change is deterministic, so all
child points of the same generation have the same color.</p>
  </li>
</ul>

<p>The second change is purely cosmetic, but does create a mesmerizing effect. The
first change alters the behavior dramatically. Only the points which compete for
the center are able to reproduce, but by the same token are more likely to be
starved out by other points doing the same.</p>

<p>In the previous visualization the points moved around in groups aimlessly. Now
the groups are all competing for the same thing, the center. As a result they
congregate and are able to be viewed as a larger whole.</p>

<p>The constant churn of the whole takes many forms, from a spiral in the center,
to waves crashing against each other, to outright chaos, to random purges of
nearly all points. Each form lasts for only a few seconds before giving way to
another.</p>"""

+++
<script src="/assets/viz/2/goog/base.js"></script>

<script src="/assets/viz/2/cljs_deps.js"></script>

<script>goog.require("viz.core");</script>

<p align="center"><canvas id="viz"></canvas></p>

<p>This visualization builds on the previous. Structurally the cartesian grid has
been turned into an isometric one, but this is more of an environmental change
than a behavioral one.</p>

<p>Behavioral changes which were made:</p>

<ul>
  <li>
    <p>When a live point is deciding its next spawn points, it first sorts the set of
empty adjacent points from closest-to-the-center to farthest. It then chooses
a number <code class="language-plaintext highlighter-rouge">n</code> between <code class="language-plaintext highlighter-rouge">0</code> to <code class="language-plaintext highlighter-rouge">N</code> (where <code class="language-plaintext highlighter-rouge">N</code> is the sorted set’s size) and
spawns new points from the first <code class="language-plaintext highlighter-rouge">n</code> points of the sorted set. <code class="language-plaintext highlighter-rouge">n</code> is chosen
based on:</p>

    <ul>
      <li>
        <p>The live point’s linear distance from the center.</p>
      </li>
      <li>
        <p>A random multiplier.</p>
      </li>
    </ul>
  </li>
  <li>
    <p>Each point is spawned with an attached color, where the color chosen is a
slightly different hue than its parent. The change is deterministic, so all
child points of the same generation have the same color.</p>
  </li>
</ul>

<p>The second change is purely cosmetic, but does create a mesmerizing effect. The
first change alters the behavior dramatically. Only the points which compete for
the center are able to reproduce, but by the same token are more likely to be
starved out by other points doing the same.</p>

<p>In the previous visualization the points moved around in groups aimlessly. Now
the groups are all competing for the same thing, the center. As a result they
congregate and are able to be viewed as a larger whole.</p>

<p>The constant churn of the whole takes many forms, from a spiral in the center,
to waves crashing against each other, to outright chaos, to random purges of
nearly all points. Each form lasts for only a few seconds before giving way to
another.</p>
