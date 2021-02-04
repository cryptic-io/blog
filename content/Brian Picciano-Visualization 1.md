
+++
title = "Visualization 1"
originalLink = "https://blog.mediocregopher.com/2018/11/12/viz-1.html"
date = 2018-11-12T00:00:00.000Z
template = "html_content/raw.html"
summary = """
First I want to appologize if you’ve seen this already, I originally had this up
on my normal websit..."""

[extra]
author = "Brian Picciano"
raw = """
<p>First I want to appologize if you’ve seen this already, I originally had this up
on my normal website, but I’ve decided to instead consolidate all my work to my
blog.</p>

<p>This is the first of a series of visualization posts I intend to work on, each
building from the previous one.</p>

<script src="/assets/viz/1/goog/base.js"></script>

<script src="/assets/viz/1/cljs_deps.js"></script>

<script>goog.require("viz.core");</script>

<p align="center"><canvas id="viz"></canvas></p>

<p>This visualization follows a few simple rules:</p>

<ul>
  <li>
    <p>Any point can only be occupied by a single node. A point may be alive (filled)
or dead (empty).</p>
  </li>
  <li>
    <p>On every tick each live point picks from 0 to N new points to spawn, where N is
the number of empty adjacent points to it. If it picks 0, it becomes dead.</p>
  </li>
  <li>
    <p>Each line indicates the parent of a point. Lines have an arbitrary lifetime of
a few ticks, and occupy the points they connect (so new points may not spawn
on top of a line).</p>
  </li>
  <li>
    <p>When a dead point has no lines it is cleaned up, and its point is no longer
occupied.</p>
  </li>
</ul>

<p>The resulting behavior is somewhere between <a href="https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life">Conway’s Game of
Life</a> and white noise.
Though each point operates independently, they tend to move together in groups.
When two groups collide head on they tend to cancel each other out, killing most
of both. When they meet while both heading in a common direction they tend to
peacefully merge towards that direction.</p>

<p>Sometimes their world becomes so cluttered there’s hardly room to move.
Sometimes a major coincidence of events leads to multiple groups canceling each
other at once, opening up the world and allowing for an explosion of new growth.</p>

<p>Some groups spiral about a single point, sustaining themselves and defending
from outside groups in the same movement. This doesn’t last for very long.</p>

<p>The performance of this visualization is not very optimized, and will probably
eat up your CPU like nothing else. Most of the slowness comes from drawing the
lines; since there’s so many individual small ones it’s quite cumbersome to do.</p>"""

+++
<p>First I want to appologize if you’ve seen this already, I originally had this up
on my normal website, but I’ve decided to instead consolidate all my work to my
blog.</p>

<p>This is the first of a series of visualization posts I intend to work on, each
building from the previous one.</p>

<script src="/assets/viz/1/goog/base.js"></script>

<script src="/assets/viz/1/cljs_deps.js"></script>

<script>goog.require("viz.core");</script>

<p align="center"><canvas id="viz"></canvas></p>

<p>This visualization follows a few simple rules:</p>

<ul>
  <li>
    <p>Any point can only be occupied by a single node. A point may be alive (filled)
or dead (empty).</p>
  </li>
  <li>
    <p>On every tick each live point picks from 0 to N new points to spawn, where N is
the number of empty adjacent points to it. If it picks 0, it becomes dead.</p>
  </li>
  <li>
    <p>Each line indicates the parent of a point. Lines have an arbitrary lifetime of
a few ticks, and occupy the points they connect (so new points may not spawn
on top of a line).</p>
  </li>
  <li>
    <p>When a dead point has no lines it is cleaned up, and its point is no longer
occupied.</p>
  </li>
</ul>

<p>The resulting behavior is somewhere between <a href="https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life">Conway’s Game of
Life</a> and white noise.
Though each point operates independently, they tend to move together in groups.
When two groups collide head on they tend to cancel each other out, killing most
of both. When they meet while both heading in a common direction they tend to
peacefully merge towards that direction.</p>

<p>Sometimes their world becomes so cluttered there’s hardly room to move.
Sometimes a major coincidence of events leads to multiple groups canceling each
other at once, opening up the world and allowing for an explosion of new growth.</p>

<p>Some groups spiral about a single point, sustaining themselves and defending
from outside groups in the same movement. This doesn’t last for very long.</p>

<p>The performance of this visualization is not very optimized, and will probably
eat up your CPU like nothing else. Most of the slowness comes from drawing the
lines; since there’s so many individual small ones it’s quite cumbersome to do.</p>
