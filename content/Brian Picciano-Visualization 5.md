
+++
title = "Visualization 5"
date = 2021-05-28T00:00:00.000Z
template = "html_content/raw.html"
summary = """
function randn(n) {
    return Math.floor(Math.random() * n);
}

const w = 100;
const h = 50;

const..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/05/28/viz-5.html"
raw = """
<script type="text/javascript">

function randn(n) {
    return Math.floor(Math.random() * n);
}

const w = 100;
const h = 50;

const maxNewElsPerTick = 10;
const deathThresh = 10;

class Canvas {
  constructor(canvasDOM) {
    this.dom = canvasDOM;
    this.ctx = canvasDOM.getContext("2d");

    // expand canvas element's width to match parent.
    this.dom.width = this.dom.parentElement.offsetWidth;

    // rectSize must be an even number or the pixels don't display nicely.
    this.rectSize = Math.floor(this.dom.width / w /2) * 2;

    this.dom.width = w * this.rectSize;
    this.dom.height = h * this.rectSize;
  }

  rectSize() {
    return Math.floor(this.dom.width / w);
  }
}

class Layer {
  constructor(newEl) {
    this.els = {};
    this.diff = {};
    this.newEl = newEl;
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

  update(state) {
    // Apply diff from previous update first. The diff can't be applied last
    // because it needs to be present during the draw phase.
    this.applyDiff();

    const allEls = this.getAll().sort(() => Math.random() - 0.5);

    if (allEls.length == 0) {
      this.set([w/2, h/2], this.newEl([]));
    }

    let newEls = 0;
    for (const el of allEls) {
      const nCoord = randEmptyNeighboringCoord(this, el.coord);
      if (!nCoord) continue; // el has no empty neighboring spots

      const nEl = this.newEl(neighboringElsOf(this, nCoord))
      nEl.tick = state.tick;
      this.set(nCoord, nEl);

      newEls++;
      if (newEls >= maxNewElsPerTick) break;
    }

    for (const el of allEls) {
      const nEls = neighboringElsOf(this, el.coord);
      if (state.tick - el.tick - (nEls.length * deathThresh) >= deathThresh) this.unset(el.coord);
    }
}

  draw(canvas) {
    for (const coordStr in this.diff) {
      const el = this.diff[coordStr];
      const coord = JSON.parse(coordStr);

      if (el.action == "set") {
        canvas.ctx.fillStyle = `hsl(${el.h}, ${el.s}, ${el.l})`;
        canvas.ctx.fillRect(
          coord[0]*canvas.rectSize, coord[1]*canvas.rectSize,
          canvas.rectSize, canvas.rectSize,
        );

      } else {
        canvas.ctx.clearRect(
          coord[0]*canvas.rectSize, coord[1]*canvas.rectSize,
          canvas.rectSize, canvas.rectSize,
        );
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

function randEmptyNeighboringCoord(layer, coord) {
  const neighbors = neighborsOf(coord).sort(() => Math.random() - 0.5);
  for (const nCoord of neighbors) {
    if (!layer.get(nCoord)) return nCoord;
  }
  return null;
}

function neighboringElsOf(layer, coord) {
  const neighboringEls = [];
  for (const nCoord of neighborsOf(coord)) {
    const el = layer.get(nCoord);
    if (el) neighboringEls.push(el);
  }
  return neighboringEls;
}

const drift = 30;
function mkNewEl(l) {
  return (nEls) => {
    const s = "100%";
    if (nEls.length == 0) {
      return {
        h: randn(360),
        s: s,
        l: l,
      };
    }

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
      s: s,
      l: l,
    };
  }
}

class Universe {
  constructor(canvasesByClass, layersByClass) {
    this.canvasesByClass = canvasesByClass;
    this.state = {
      tick: 0,
      layers: layersByClass,
    };
  }

  update() {
    this.state.tick++;
    Object.values(this.state.layers).forEach((layer) => layer.update(this.state));
  }

  draw() {
    for (const layerName in this.state.layers) {
      if (!this.canvasesByClass[layerName]) return;
      this.canvasesByClass[layerName].forEach((canvas) => {
        this.state.layers[layerName].draw(canvas);
      });
    }
  }
}

</script>

<style>

.canvasContainer {
  display: grid;
  margin-bottom: 2rem;
  text-align: center;
}

canvas {
  border: 1px dashed #AAA;
  width: 100%;
  grid-area: 1/1/2/2;
}

</style>

<div class="canvasContainer">
  <canvas class="layer1"></canvas>
  <canvas class="layer2"></canvas>
</div>

<div class="row">
  <div class="columns six">
    <div class="canvasContainer"><canvas class="layer1"></canvas></div>
  </div>
  <div class="columns six">
    <div class="canvasContainer"><canvas class="layer2"></canvas></div>
  </div>
</div>

<p>This visualization combines two distinct layers, each of them borrowing their
behavior from <a href="/2021/05/26/viz-4.html">Visualization 4</a>. Neither layer has any effect on the
other, one is merely super-imposed on top of the other in the top canvas. You
can see each layer individually in the two lower canvases.</p>

<p>Despite their not affecting each other, the code is set up so that each layer
<em>could</em> be affected by the other. This will likely be explored more in a future
post.</p>

<script>

const canvasesByClass = {};
[...document.getElementsByTagName("canvas")].forEach((canvasDOM) => {

  const canvas = new Canvas(canvasDOM);
  canvasDOM.classList.forEach((name) => {
    if (!canvasesByClass[name]) canvasesByClass[name] = [];
    canvasesByClass[name].push(canvas);
  })
});


const universe = new Universe(canvasesByClass, {
  "layer1": new Layer(mkNewEl("90%")),
  "layer2": new Layer(mkNewEl("50%")),
});

const requestAnimationFrame =
  window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.msRequestAnimationFrame;

function doTick() {
  universe.update();
  universe.draw();
  requestAnimationFrame(doTick);
}

doTick();

</script>"""

+++
<script type="text/javascript">

function randn(n) {
    return Math.floor(Math.random() * n);
}

const w = 100;
const h = 50;

const maxNewElsPerTick = 10;
const deathThresh = 10;

class Canvas {
  constructor(canvasDOM) {
    this.dom = canvasDOM;
    this.ctx = canvasDOM.getContext("2d");

    // expand canvas element's width to match parent.
    this.dom.width = this.dom.parentElement.offsetWidth;

    // rectSize must be an even number or the pixels don't display nicely.
    this.rectSize = Math.floor(this.dom.width / w /2) * 2;

    this.dom.width = w * this.rectSize;
    this.dom.height = h * this.rectSize;
  }

  rectSize() {
    return Math.floor(this.dom.width / w);
  }
}

class Layer {
  constructor(newEl) {
    this.els = {};
    this.diff = {};
    this.newEl = newEl;
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

  update(state) {
    // Apply diff from previous update first. The diff can't be applied last
    // because it needs to be present during the draw phase.
    this.applyDiff();

    const allEls = this.getAll().sort(() => Math.random() - 0.5);

    if (allEls.length == 0) {
      this.set([w/2, h/2], this.newEl([]));
    }

    let newEls = 0;
    for (const el of allEls) {
      const nCoord = randEmptyNeighboringCoord(this, el.coord);
      if (!nCoord) continue; // el has no empty neighboring spots

      const nEl = this.newEl(neighboringElsOf(this, nCoord))
      nEl.tick = state.tick;
      this.set(nCoord, nEl);

      newEls++;
      if (newEls >= maxNewElsPerTick) break;
    }

    for (const el of allEls) {
      const nEls = neighboringElsOf(this, el.coord);
      if (state.tick - el.tick - (nEls.length * deathThresh) >= deathThresh) this.unset(el.coord);
    }
}

  draw(canvas) {
    for (const coordStr in this.diff) {
      const el = this.diff[coordStr];
      const coord = JSON.parse(coordStr);

      if (el.action == "set") {
        canvas.ctx.fillStyle = `hsl(${el.h}, ${el.s}, ${el.l})`;
        canvas.ctx.fillRect(
          coord[0]*canvas.rectSize, coord[1]*canvas.rectSize,
          canvas.rectSize, canvas.rectSize,
        );

      } else {
        canvas.ctx.clearRect(
          coord[0]*canvas.rectSize, coord[1]*canvas.rectSize,
          canvas.rectSize, canvas.rectSize,
        );
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

function randEmptyNeighboringCoord(layer, coord) {
  const neighbors = neighborsOf(coord).sort(() => Math.random() - 0.5);
  for (const nCoord of neighbors) {
    if (!layer.get(nCoord)) return nCoord;
  }
  return null;
}

function neighboringElsOf(layer, coord) {
  const neighboringEls = [];
  for (const nCoord of neighborsOf(coord)) {
    const el = layer.get(nCoord);
    if (el) neighboringEls.push(el);
  }
  return neighboringEls;
}

const drift = 30;
function mkNewEl(l) {
  return (nEls) => {
    const s = "100%";
    if (nEls.length == 0) {
      return {
        h: randn(360),
        s: s,
        l: l,
      };
    }

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
      s: s,
      l: l,
    };
  }
}

class Universe {
  constructor(canvasesByClass, layersByClass) {
    this.canvasesByClass = canvasesByClass;
    this.state = {
      tick: 0,
      layers: layersByClass,
    };
  }

  update() {
    this.state.tick++;
    Object.values(this.state.layers).forEach((layer) => layer.update(this.state));
  }

  draw() {
    for (const layerName in this.state.layers) {
      if (!this.canvasesByClass[layerName]) return;
      this.canvasesByClass[layerName].forEach((canvas) => {
        this.state.layers[layerName].draw(canvas);
      });
    }
  }
}

</script>

<style>

.canvasContainer {
  display: grid;
  margin-bottom: 2rem;
  text-align: center;
}

canvas {
  border: 1px dashed #AAA;
  width: 100%;
  grid-area: 1/1/2/2;
}

</style>

<div class="canvasContainer">
  <canvas class="layer1"></canvas>
  <canvas class="layer2"></canvas>
</div>

<div class="row">
  <div class="columns six">
    <div class="canvasContainer"><canvas class="layer1"></canvas></div>
  </div>
  <div class="columns six">
    <div class="canvasContainer"><canvas class="layer2"></canvas></div>
  </div>
</div>

<p>This visualization combines two distinct layers, each of them borrowing their
behavior from <a href="/2021/05/26/viz-4.html">Visualization 4</a>. Neither layer has any effect on the
other, one is merely super-imposed on top of the other in the top canvas. You
can see each layer individually in the two lower canvases.</p>

<p>Despite their not affecting each other, the code is set up so that each layer
<em>could</em> be affected by the other. This will likely be explored more in a future
post.</p>

<script>

const canvasesByClass = {};
[...document.getElementsByTagName("canvas")].forEach((canvasDOM) => {

  const canvas = new Canvas(canvasDOM);
  canvasDOM.classList.forEach((name) => {
    if (!canvasesByClass[name]) canvasesByClass[name] = [];
    canvasesByClass[name].push(canvas);
  })
});


const universe = new Universe(canvasesByClass, {
  "layer1": new Layer(mkNewEl("90%")),
  "layer2": new Layer(mkNewEl("50%")),
});

const requestAnimationFrame =
  window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.msRequestAnimationFrame;

function doTick() {
  universe.update();
  universe.draw();
  requestAnimationFrame(doTick);
}

doTick();

</script>
