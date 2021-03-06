
+++
title = "Visualization 4"
date = 2021-05-26T00:00:00.000Z
template = "html_content/raw.html"
summary = """
This visualization is a conglomeration of ideas from all the previous ones. On
each tick up to 20 ne..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/05/26/viz-4.html"
raw = """
<canvas id="canvas" style="padding-bottom: 2rem;" width="100%" height="100%"></canvas>

<p>This visualization is a conglomeration of ideas from all the previous ones. On
each tick up to 20 new pixels are generated. The color of each new pixel is
based on the average color of its neighbors, plus some random drift.</p>

<p>Each pixel dies after a certain number of ticks, <code class="language-plaintext highlighter-rouge">N</code>. A pixel’s life can be
extended by up to <code class="language-plaintext highlighter-rouge">8N</code> ticks, one for each neighbor it has which is still alive.
This mechanism accounts for the strange behavior which is seen when the
visualization first loads, but also allows for more coherent clusters of pixels
to hold together as time goes on.</p>

<p>The asteroid rule is also in effect in this visualization, so the top row and
bottom row pixels are neighbors of each other, and similarly for the rightmost
and leftmost column pixels.</p>

<script type="text/javascript">

function randn(n) {
    return Math.floor(Math.random() * n);
}

const canvas = document.getElementById("canvas");
const parentWidth = canvas.parentElement.offsetWidth;

const rectSize = Math.floor(parentWidth /100 /2) *2; // must be even number
console.log("rectSize", rectSize);

canvas.width = parentWidth - rectSize - (parentWidth % rectSize);
canvas.height = canvas.width * 0.75;
canvas.height -= canvas.height % rectSize;
const ctx = canvas.getContext("2d");

const w = (canvas.width / rectSize) - 1;
const h = (canvas.height / rectSize) - 1;

class Elements {
  constructor() {
    this.els = {};
    this.diff = {};
  }

  _normCoord(coord) {
    if (typeof coord !== 'string') coord = JSON.stringify(coord);
    return coord;
  }

  get(coord) {
    return this.els[this._normCoord(coord)];
  }

  getAll() {
    return Object.values(this.els);
  }

  set(coord, el) {
    this.diff[this._normCoord(coord)] = {action: "set", coord: coord, ...el};
  }

  unset(coord) {
    this.diff[this._normCoord(coord)] = {action: "unset"};
  }

  drawDiff(ctx) {
    for (const coordStr in this.diff) {
      const el = this.diff[coordStr];
      const coord = JSON.parse(coordStr);

      if (el.action == "set") {
        ctx.fillStyle = `hsl(${el.h}, ${el.s}, ${el.l})`;
      } else {
        ctx.fillStyle = `#FFF`;
      }

      ctx.fillRect(coord[0]*rectSize, coord[1]*rectSize, rectSize, rectSize);
    }
  }

  applyDiff() {
    for (const coordStr in this.diff) {
      const el = this.diff[coordStr];
      delete this.diff[coordStr];

      if (el.action == "set") {
        delete el.action;
        this.els[coordStr] = el;
      } else {
        delete this.els[coordStr];
      }
    }
  }
}

const neighbors = [
    [-1, -1],   [0, -1],   [1, -1],
    [-1, 0], /* [0, 0], */ [1, 0],
    [-1, 1],    [0, 1],    [1, 1],
];

function neighborsOf(coord) {
  return neighbors.map((n) => {
    let nX = coord[0]+n[0];
    let nY = coord[1]+n[1];
    nX = (nX + w) % w;
    nY = (nY + h) % h;
    return [nX, nY];
  });
}

function randEmptyNeighboringCoord(els, coord) {
  const neighbors = neighborsOf(coord).sort(() => Math.random() - 0.5);
  for (const nCoord of neighbors) {
    if (!els.get(nCoord)) return nCoord;
  }
  return null;
}

function neighboringElsOf(els, coord) {
  const neighboringEls = [];
  for (const nCoord of neighborsOf(coord)) {
    const el = els.get(nCoord);
    if (el) neighboringEls.push(el);
  }
  return neighboringEls;
}

const drift = 30;
function newEl(nEls) {

  // for each h (which can be considered as degrees around a circle) break the h
  // down into x and y vectors, and add those up separately. Then find the angle
  // between those two resulting vectors, and that's the "average" h value.
  let x = 0;
  let y = 0;
  nEls.forEach((el) => {
    const hRad = el.h * Math.PI / 180;
    x += Math.cos(hRad);
    y += Math.sin(hRad);
  });

  let h = Math.atan2(y, x);
  h = h / Math.PI * 180;

  // apply some random drift, normalize
  h += (Math.random() * drift * 2) - drift;
  h = (h + 360) % 360;

  return {
    h: h,
    s: "100%",
    l: "50%",
  };
}

const requestAnimationFrame = 
  window.requestAnimationFrame || 
  window.mozRequestAnimationFrame || 
  window.webkitRequestAnimationFrame || 
  window.msRequestAnimationFrame;

const els = new Elements();

const maxNewElsPerTick = 20;
const deathThresh = 20;

let tick = 0;
function doTick() {
  tick++;

  const allEls = els.getAll().sort(() => Math.random() - 0.5);

  if (allEls.length == 0) {
    els.set([w/2, h/2], {
      h: randn(360),
      s: "100%",
      l: "50%",
    });
  }

  let newEls = 0;
  for (const el of allEls) {
    const nCoord = randEmptyNeighboringCoord(els, el.coord);
    if (!nCoord) continue; // el has no empty neighboring spots

    const nEl = newEl(neighboringElsOf(els, nCoord))
    nEl.tick = tick;
    els.set(nCoord, nEl);

    newEls++;
    if (newEls >= maxNewElsPerTick) break;
  }

  for (const el of allEls) {
    const nEls = neighboringElsOf(els, el.coord);
    if (tick - el.tick - (nEls.length * deathThresh) >= deathThresh) els.unset(el.coord);
  }

  els.drawDiff(ctx);
  els.applyDiff();
  requestAnimationFrame(doTick);
}
requestAnimationFrame(doTick);

</script>"""

+++
<canvas id="canvas" style="padding-bottom: 2rem;" width="100%" height="100%"></canvas>

<p>This visualization is a conglomeration of ideas from all the previous ones. On
each tick up to 20 new pixels are generated. The color of each new pixel is
based on the average color of its neighbors, plus some random drift.</p>

<p>Each pixel dies after a certain number of ticks, <code class="language-plaintext highlighter-rouge">N</code>. A pixel’s life can be
extended by up to <code class="language-plaintext highlighter-rouge">8N</code> ticks, one for each neighbor it has which is still alive.
This mechanism accounts for the strange behavior which is seen when the
visualization first loads, but also allows for more coherent clusters of pixels
to hold together as time goes on.</p>

<p>The asteroid rule is also in effect in this visualization, so the top row and
bottom row pixels are neighbors of each other, and similarly for the rightmost
and leftmost column pixels.</p>

<script type="text/javascript">

function randn(n) {
    return Math.floor(Math.random() * n);
}

const canvas = document.getElementById("canvas");
const parentWidth = canvas.parentElement.offsetWidth;

const rectSize = Math.floor(parentWidth /100 /2) *2; // must be even number
console.log("rectSize", rectSize);

canvas.width = parentWidth - rectSize - (parentWidth % rectSize);
canvas.height = canvas.width * 0.75;
canvas.height -= canvas.height % rectSize;
const ctx = canvas.getContext("2d");

const w = (canvas.width / rectSize) - 1;
const h = (canvas.height / rectSize) - 1;

class Elements {
  constructor() {
    this.els = {};
    this.diff = {};
  }

  _normCoord(coord) {
    if (typeof coord !== 'string') coord = JSON.stringify(coord);
    return coord;
  }

  get(coord) {
    return this.els[this._normCoord(coord)];
  }

  getAll() {
    return Object.values(this.els);
  }

  set(coord, el) {
    this.diff[this._normCoord(coord)] = {action: "set", coord: coord, ...el};
  }

  unset(coord) {
    this.diff[this._normCoord(coord)] = {action: "unset"};
  }

  drawDiff(ctx) {
    for (const coordStr in this.diff) {
      const el = this.diff[coordStr];
      const coord = JSON.parse(coordStr);

      if (el.action == "set") {
        ctx.fillStyle = `hsl(${el.h}, ${el.s}, ${el.l})`;
      } else {
        ctx.fillStyle = `#FFF`;
      }

      ctx.fillRect(coord[0]*rectSize, coord[1]*rectSize, rectSize, rectSize);
    }
  }

  applyDiff() {
    for (const coordStr in this.diff) {
      const el = this.diff[coordStr];
      delete this.diff[coordStr];

      if (el.action == "set") {
        delete el.action;
        this.els[coordStr] = el;
      } else {
        delete this.els[coordStr];
      }
    }
  }
}

const neighbors = [
    [-1, -1],   [0, -1],   [1, -1],
    [-1, 0], /* [0, 0], */ [1, 0],
    [-1, 1],    [0, 1],    [1, 1],
];

function neighborsOf(coord) {
  return neighbors.map((n) => {
    let nX = coord[0]+n[0];
    let nY = coord[1]+n[1];
    nX = (nX + w) % w;
    nY = (nY + h) % h;
    return [nX, nY];
  });
}

function randEmptyNeighboringCoord(els, coord) {
  const neighbors = neighborsOf(coord).sort(() => Math.random() - 0.5);
  for (const nCoord of neighbors) {
    if (!els.get(nCoord)) return nCoord;
  }
  return null;
}

function neighboringElsOf(els, coord) {
  const neighboringEls = [];
  for (const nCoord of neighborsOf(coord)) {
    const el = els.get(nCoord);
    if (el) neighboringEls.push(el);
  }
  return neighboringEls;
}

const drift = 30;
function newEl(nEls) {

  // for each h (which can be considered as degrees around a circle) break the h
  // down into x and y vectors, and add those up separately. Then find the angle
  // between those two resulting vectors, and that's the "average" h value.
  let x = 0;
  let y = 0;
  nEls.forEach((el) => {
    const hRad = el.h * Math.PI / 180;
    x += Math.cos(hRad);
    y += Math.sin(hRad);
  });

  let h = Math.atan2(y, x);
  h = h / Math.PI * 180;

  // apply some random drift, normalize
  h += (Math.random() * drift * 2) - drift;
  h = (h + 360) % 360;

  return {
    h: h,
    s: "100%",
    l: "50%",
  };
}

const requestAnimationFrame = 
  window.requestAnimationFrame || 
  window.mozRequestAnimationFrame || 
  window.webkitRequestAnimationFrame || 
  window.msRequestAnimationFrame;

const els = new Elements();

const maxNewElsPerTick = 20;
const deathThresh = 20;

let tick = 0;
function doTick() {
  tick++;

  const allEls = els.getAll().sort(() => Math.random() - 0.5);

  if (allEls.length == 0) {
    els.set([w/2, h/2], {
      h: randn(360),
      s: "100%",
      l: "50%",
    });
  }

  let newEls = 0;
  for (const el of allEls) {
    const nCoord = randEmptyNeighboringCoord(els, el.coord);
    if (!nCoord) continue; // el has no empty neighboring spots

    const nEl = newEl(neighboringElsOf(els, nCoord))
    nEl.tick = tick;
    els.set(nCoord, nEl);

    newEls++;
    if (newEls >= maxNewElsPerTick) break;
  }

  for (const el of allEls) {
    const nEls = neighboringElsOf(els, el.coord);
    if (tick - el.tick - (nEls.length * deathThresh) >= deathThresh) els.unset(el.coord);
  }

  els.drawDiff(ctx);
  els.applyDiff();
  requestAnimationFrame(doTick);
}
requestAnimationFrame(doTick);

</script>
