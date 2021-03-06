
+++
title = "Visualization 6"
date = 2021-06-23T00:00:00.000Z
template = "html_content/raw.html"
summary = """
function randn(n) {
    return Math.floor(Math.random() * n);
}

const w = 100;
const h = 50;

class..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/06/23/viz-6.html"
raw = """
<script type="text/javascript">

function randn(n) {
    return Math.floor(Math.random() * n);
}

const w = 100;
const h = 50;

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
  constructor(className, newEl, {
    maxNewElsPerTick = 10,
    ageOfDeath = 60,
    neighborBonusScalar = 1,
    layerBonusScalar = 1,
    chaos = 0,
  } = {}) {
    this.className = className;
    this.els = {};
    this.diff = {};

    this.newEl = newEl;
    this.maxNewElsPerTick = maxNewElsPerTick;
    this.ageOfDeath = ageOfDeath;
    this.neighborBonusScalar = neighborBonusScalar;
    this.layerBonusScalar = layerBonusScalar;
    this.chaos = chaos;
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

  update(state, prevLayer) {
    // Apply diff from previous update first. The diff can't be applied last
    // because it needs to be present during the draw phase.
    this.applyDiff();

    const allEls = this.getAll().sort(() => Math.random() - 0.5);

    if (allEls.length == 0) {
      const nEl = this.newEl([])
      nEl.tick = state.tick;
      this.set([w/2, h/2], nEl);
      return;
    }

    let newEls = 0;
    for (const el of allEls) {
      const nCoord = randEmptyNeighboringCoord(this, el.coord);
      if (!nCoord) continue; // el has no empty neighboring spots

      const nEl = this.newEl(neighboringElsOf(this, nCoord))
      nEl.tick = state.tick;
      this.set(nCoord, nEl);

      newEls++;
      if (newEls >= this.maxNewElsPerTick) break;
    }

    for (const el of allEls) {
      const age = state.tick - el.tick;
      const neighborBonus = neighboringElsOf(this, el.coord).length * this.neighborBonusScalar;

      const layerBonus = prevLayer
        ? neighboringElsOf(prevLayer, el.coord, true).length * this.layerBonusScalar
        : 0;

      const chaos = (this.chaos > 0) ? randn(this.chaos) : 0;

      if (age - neighborBonus - layerBonus + chaos >= this.ageOfDeath) {
        this.unset(el.coord);
      }
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

function neighboringElsOf(layer, coord, includeCoord = false) {
  const neighboringEls = [];

  const neighboringCoords = neighborsOf(coord);
  if (includeCoord) neighboringCoords.push(coord);

  for (const nCoord of neighboringCoords) {
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
  constructor(canvasesByClass, layers) {
    this.canvasesByClass = canvasesByClass;
    this.state = {
      tick: 0,
      layers: layers,
    };
  }

  update() {
    this.state.tick++;
    let prevLayer;
    this.state.layers.forEach((layer) => {
        layer.update(this.state, prevLayer);
        prevLayer = layer;
    });
  }

  draw() {
    this.state.layers.forEach((layer) => {
      if (!this.canvasesByClass[layer.className]) return;
      this.canvasesByClass[layer.className].forEach((canvas) => {
        layer.draw(canvas);
      });
    });
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
    <h3>Bottom Layer</h3>
    <div class="canvasContainer"><canvas class="layer1"></canvas></div>
    <div class="layer1 layerParams">
        <label>Max New Elements Per Tick</label><input type="text" param="maxNewElsPerTick" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Bonus Scalar</label><input type="text" param="neighborBonusScalar" />
    </div>
  </div>

  <div class="columns six">
    <h3>Top Layer</h3>
    <div class="canvasContainer"><canvas class="layer2"></canvas></div>
    <div class="layer2 layerParams">
        <label>Max New Elements Per Tick</label><input type="text" param="maxNewElsPerTick" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Bonus Scalar</label><input type="text" param="neighborBonusScalar" />
        <label>Layer Bonus Scalar</label><input type="text" param="layerBonusScalar" />
    </div>
  </div>

</div>

<p>This visualization is essentially the same as the previous, except that each
layer now operates with different parameters than the other, allowing each to
exhibit different behavior.</p>

<p>Additionally, the top layer has been made to be responsive to the bottom, via a
new mechanism where the age of an element on the top layer can be extended based
on the number of bottom layer elements it neighbors.</p>

<p>Finally, the UI now exposes the actual parameters which are used to tweak the
behavior of each layer. Modifying any parameter will change the behavior of the
associated layer in real-time. The default parameters have been chosen such that
the top layer is now rather dependent on the bottom for sustenance, although it
can venture away to some extent. However, by playing the parameters yourself you
can find other behaviors and interesting cause-and-effects that aren’t
immediately obvious. Try it!</p>

<p>An explanation of the parameters is as follows:</p>

<p>On each tick, up to <code class="language-plaintext highlighter-rouge">maxNewElements</code> are created in each layer, where each new
element neighbors an existing one.</p>

<p>Additionally, on each tick, <em>all</em> elements in a layer are iterated through. Each
one’s age is determined as follows:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>age = (currentTick - birthTick)
age -= (numNeighbors * neighborBonusScalar)
age -= (numBottomLayerNeighbors * layerBonusScalar) // only for top layer
</code></pre></div></div>

<p>If an element’s age is greater than or equal to the <code class="language-plaintext highlighter-rouge">ageOfDeath</code> for that layer,
then the element is removed.</p>

<script>

const canvasesByClass = {};
[...document.getElementsByTagName("canvas")].forEach((canvasDOM) => {

  const canvas = new Canvas(canvasDOM);
  canvasDOM.classList.forEach((name) => {
    if (!canvasesByClass[name]) canvasesByClass[name] = [];
    canvasesByClass[name].push(canvas);
  })
});

const layers = [

  new Layer("layer1", mkNewEl("90%"), {
    maxNewElsPerTick: 2,
    ageOfDeath: 30,
    neighborBonusScalar: 50,
  }),

  new Layer("layer2", mkNewEl("50%", ), {
    maxNewElsPerTick: 10,
    ageOfDeath: 1,
    neighborBonusScalar: 15,
    layerBonusScalar: 5,
  }),

];

for (const layer of layers) {
    document.querySelectorAll(`.${layer.className}.layerParams > input`).forEach((input) => {
        const param = input.getAttribute("param");

        // pre-fill input values
        input.value = layer[param];

        input.onchange = () => {
            console.log(`setting ${layer.className}.${param} to ${input.value}`);
            layer[param] = input.value;
        };
    });
}

const universe = new Universe(canvasesByClass, layers);

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
  constructor(className, newEl, {
    maxNewElsPerTick = 10,
    ageOfDeath = 60,
    neighborBonusScalar = 1,
    layerBonusScalar = 1,
    chaos = 0,
  } = {}) {
    this.className = className;
    this.els = {};
    this.diff = {};

    this.newEl = newEl;
    this.maxNewElsPerTick = maxNewElsPerTick;
    this.ageOfDeath = ageOfDeath;
    this.neighborBonusScalar = neighborBonusScalar;
    this.layerBonusScalar = layerBonusScalar;
    this.chaos = chaos;
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

  update(state, prevLayer) {
    // Apply diff from previous update first. The diff can't be applied last
    // because it needs to be present during the draw phase.
    this.applyDiff();

    const allEls = this.getAll().sort(() => Math.random() - 0.5);

    if (allEls.length == 0) {
      const nEl = this.newEl([])
      nEl.tick = state.tick;
      this.set([w/2, h/2], nEl);
      return;
    }

    let newEls = 0;
    for (const el of allEls) {
      const nCoord = randEmptyNeighboringCoord(this, el.coord);
      if (!nCoord) continue; // el has no empty neighboring spots

      const nEl = this.newEl(neighboringElsOf(this, nCoord))
      nEl.tick = state.tick;
      this.set(nCoord, nEl);

      newEls++;
      if (newEls >= this.maxNewElsPerTick) break;
    }

    for (const el of allEls) {
      const age = state.tick - el.tick;
      const neighborBonus = neighboringElsOf(this, el.coord).length * this.neighborBonusScalar;

      const layerBonus = prevLayer
        ? neighboringElsOf(prevLayer, el.coord, true).length * this.layerBonusScalar
        : 0;

      const chaos = (this.chaos > 0) ? randn(this.chaos) : 0;

      if (age - neighborBonus - layerBonus + chaos >= this.ageOfDeath) {
        this.unset(el.coord);
      }
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

function neighboringElsOf(layer, coord, includeCoord = false) {
  const neighboringEls = [];

  const neighboringCoords = neighborsOf(coord);
  if (includeCoord) neighboringCoords.push(coord);

  for (const nCoord of neighboringCoords) {
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
  constructor(canvasesByClass, layers) {
    this.canvasesByClass = canvasesByClass;
    this.state = {
      tick: 0,
      layers: layers,
    };
  }

  update() {
    this.state.tick++;
    let prevLayer;
    this.state.layers.forEach((layer) => {
        layer.update(this.state, prevLayer);
        prevLayer = layer;
    });
  }

  draw() {
    this.state.layers.forEach((layer) => {
      if (!this.canvasesByClass[layer.className]) return;
      this.canvasesByClass[layer.className].forEach((canvas) => {
        layer.draw(canvas);
      });
    });
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
    <h3>Bottom Layer</h3>
    <div class="canvasContainer"><canvas class="layer1"></canvas></div>
    <div class="layer1 layerParams">
        <label>Max New Elements Per Tick</label><input type="text" param="maxNewElsPerTick" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Bonus Scalar</label><input type="text" param="neighborBonusScalar" />
    </div>
  </div>

  <div class="columns six">
    <h3>Top Layer</h3>
    <div class="canvasContainer"><canvas class="layer2"></canvas></div>
    <div class="layer2 layerParams">
        <label>Max New Elements Per Tick</label><input type="text" param="maxNewElsPerTick" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Bonus Scalar</label><input type="text" param="neighborBonusScalar" />
        <label>Layer Bonus Scalar</label><input type="text" param="layerBonusScalar" />
    </div>
  </div>

</div>

<p>This visualization is essentially the same as the previous, except that each
layer now operates with different parameters than the other, allowing each to
exhibit different behavior.</p>

<p>Additionally, the top layer has been made to be responsive to the bottom, via a
new mechanism where the age of an element on the top layer can be extended based
on the number of bottom layer elements it neighbors.</p>

<p>Finally, the UI now exposes the actual parameters which are used to tweak the
behavior of each layer. Modifying any parameter will change the behavior of the
associated layer in real-time. The default parameters have been chosen such that
the top layer is now rather dependent on the bottom for sustenance, although it
can venture away to some extent. However, by playing the parameters yourself you
can find other behaviors and interesting cause-and-effects that aren’t
immediately obvious. Try it!</p>

<p>An explanation of the parameters is as follows:</p>

<p>On each tick, up to <code class="language-plaintext highlighter-rouge">maxNewElements</code> are created in each layer, where each new
element neighbors an existing one.</p>

<p>Additionally, on each tick, <em>all</em> elements in a layer are iterated through. Each
one’s age is determined as follows:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>age = (currentTick - birthTick)
age -= (numNeighbors * neighborBonusScalar)
age -= (numBottomLayerNeighbors * layerBonusScalar) // only for top layer
</code></pre></div></div>

<p>If an element’s age is greater than or equal to the <code class="language-plaintext highlighter-rouge">ageOfDeath</code> for that layer,
then the element is removed.</p>

<script>

const canvasesByClass = {};
[...document.getElementsByTagName("canvas")].forEach((canvasDOM) => {

  const canvas = new Canvas(canvasDOM);
  canvasDOM.classList.forEach((name) => {
    if (!canvasesByClass[name]) canvasesByClass[name] = [];
    canvasesByClass[name].push(canvas);
  })
});

const layers = [

  new Layer("layer1", mkNewEl("90%"), {
    maxNewElsPerTick: 2,
    ageOfDeath: 30,
    neighborBonusScalar: 50,
  }),

  new Layer("layer2", mkNewEl("50%", ), {
    maxNewElsPerTick: 10,
    ageOfDeath: 1,
    neighborBonusScalar: 15,
    layerBonusScalar: 5,
  }),

];

for (const layer of layers) {
    document.querySelectorAll(`.${layer.className}.layerParams > input`).forEach((input) => {
        const param = input.getAttribute("param");

        // pre-fill input values
        input.value = layer[param];

        input.onchange = () => {
            console.log(`setting ${layer.className}.${param} to ${input.value}`);
            layer[param] = input.value;
        };
    });
}

const universe = new Universe(canvasesByClass, layers);

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
