
+++
title = "Visualization 7"
date = 2021-07-01T00:00:00.000Z
template = "html_content/raw.html"
summary = """
function randn(n) {
    return Math.floor(Math.random() * n);
}

const w = 100;
const h = 60;

class..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/07/01/viz-7.html"
raw = """
<script type="text/javascript">

function randn(n) {
    return Math.floor(Math.random() * n);
}

const w = 100;
const h = 60;

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

class UniverseState {
  constructor(layers) {
    this.tick = 0;
    this.layers = layers;
  }

  neighboringLayers(layerIndex) {
    const prevIndex = layerIndex-1;
    const prev = prevIndex < 0 ? null : this.layers[prevIndex];

    const nextIndex = layerIndex+1;
    const next = nextIndex >= this.layers.length ? null : this.layers[nextIndex];

    return [prev, next];
  }
}

const defaultKnobs = {
  maxNewElsPerTick: 10,
  ageOfDeath: 30,
  drift: 30,
  neighborScalar: 0,
  prevLayerScalar: 0,
  prevLayerLikenessScalar: 0,
  nextLayerScalar: 0,
  nextLayerLikenessScalar: 0,
  chaos: 0,
};

class Layer {
  constructor(className, newEl, knobs = {}) {
    this.className = className;
    this.els = {};
    this.diff = {};
    this.newEl = newEl;
    this.knobs = { ...defaultKnobs, ...knobs };
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

  update(state, thisLayerIndex) {
    // Apply diff from previous update first. The diff can't be applied last
    // because it needs to be present during the draw phase.
    this.applyDiff();

    const allEls = this.getAll().sort(() => Math.random() - 0.5);

    if (allEls.length == 0) {
      const newEl = this.newEl(this, [])
      newEl.tick = state.tick;
      this.set([w/2, h/2], newEl);
      return;
    }

    let newEls = 0;
    for (const el of allEls) {
      const nCoord = randEmptyNeighboringCoord(this, el.coord);
      if (!nCoord) continue; // el has no empty neighboring spots

      const newEl = this.newEl(this, neighboringElsOf(this, nCoord))
      newEl.tick = state.tick;
      this.set(nCoord, newEl);

      newEls++;
      if (newEls >= this.knobs.maxNewElsPerTick) break;
    }

    const calcLayerBonus = (el, layer, scalar, likenessScalar) => {
        if (!layer) return 0;
        const nEls = neighboringElsOf(layer, el.coord, true)

        const likeness = nEls.reduce((likeness, nEl) => {
            const diff = Math.abs(nEl.c - el.c);
            return likeness + Math.max(diff, Math.abs(1 - diff));
        }, 0);

        return (nEls.length * scalar) + (likeness * likenessScalar);
    };

    const [prevLayer, nextLayer] = state.neighboringLayers(thisLayerIndex);

    for (const el of allEls) {
      const age = state.tick - el.tick;
      const neighborBonus = neighboringElsOf(this, el.coord).length * this.knobs.neighborScalar;
      const prevLayerBonus = calcLayerBonus(el, prevLayer, this.knobs.prevLayerScalar, this.knobs.prevLayerLikenessScalar);
      const nextLayerBonus = calcLayerBonus(el, nextLayer, this.knobs.nextLayerScalar, this.knobs.nextLayerLikenessScalar);
      const chaos = (this.chaos > 0) ? randn(this.knobs.chaos) : 0;

      if (age - neighborBonus - prevLayerBonus - nextLayerBonus + chaos >= this.knobs.ageOfDeath) {
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

function newEl(h, l) {
  return {
    h: h,
    s: "100%",
    l: l,
    c: h / 360, // c is used to compare the element to others
  };
}

function mkNewEl(l) {
  return (layer, nEls) => {
    const s = "100%";
    if (nEls.length == 0) {
      const h = randn(360);
      return newEl(h, l);
    }

    // for each h (which can be considered as degrees around a circle) break the
    // h down into x and y vectors, and add those up separately. Then find the
    // angle between those two resulting vectors, and that's the "average" h
    // value.
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
    h += (Math.random() * layer.knobs.drift * 2) - layer.knobs.drift;
    h = (h + 360) % 360;

    return newEl(h, l);
  }
}

class Universe {
  constructor(canvasesByClass, layers) {
    this.canvasesByClass = canvasesByClass;
    this.state = new UniverseState(layers);
  }

  update() {
    this.state.tick++;
    let prevLayer;
    this.state.layers.forEach((layer, i) => {
        layer.update(this.state, i);
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
        <label>Color Drift</label><input type="text" param="drift" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Scalar</label><input type="text" param="neighborScalar" />
        <label>Top Layer Neighbor Scalar</label><input type="text" param="nextLayerScalar" />
        <label>Top Layer Neighbor Likeness Scalar</label><input type="text" param="nextLayerLikenessScalar" />
    </div>
  </div>

  <div class="columns six">
    <h3>Top Layer</h3>
    <div class="canvasContainer"><canvas class="layer2"></canvas></div>
    <div class="layer2 layerParams">
        <label>Max New Elements Per Tick</label><input type="text" param="maxNewElsPerTick" />
        <label>Color Drift</label><input type="text" param="drift" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Scalar</label><input type="text" param="neighborScalar" />
        <label>Bottom Layer Neighbor Scalar</label><input type="text" param="prevLayerScalar" />
        <label>Bottom Layer Neighbor Likeness Scalar</label><input type="text" param="prevLayerLikenessScalar" />
    </div>
  </div>

</div>

<p>Once again, this visualization iterates upon the previous. In the last one the
top layer was able to “see” the bottom, and was therefore able to bolster or
penalize its own elements which were on or near bottom layer elements, but not
vice-versa. This time both layers can see each other, and the “Layer Neighbor
Scalar” can be used to adjust lifetime of elements which are on/near elements of
the neighboring layer.</p>

<p>By default, the bottom layer has a high affinity to the top, and the top layer
has a some (but not as much) affinity in return.</p>

<p>Another addition is the “likeness” scalar. Likeness is defined as the degree to
which one element is like another. In this visualization likeness is determined
by color. The “Layer Neighbor Likeness Scalar” adjusts the lifetime of elements
based on how like they are to nearby elements on the neighboring layer.</p>

<p>By default, the top layer has a high affinity for the bottom’s color, but the
bottom doesn’t care about the top’s color at all (and so its color will drift
aimlessly).</p>

<p>And finally “Color Drift” can be used to adjust the degree to which the color of
new elements can diverge from its parents. This has always been hardcoded, but
can now be adjusted separately across the different layers.</p>

<p>In the default configuration the top layer will (eventually) converge to roughly
match the bottom both in shape and color. When I first implemented the likeness
scaling I thought it was broken, because the top would never converge to the
bottom’s color.</p>

<p>What I eventually realized was that the top must have a higher color drift than
the bottom in order for it to do so, otherwise the top would always be playing
catchup. However, if the drift difference is <em>too</em> high then the top layer
becomes chaos and also doesn’t really follow the color of the bottom. A
difference of 10 (degrees out of 360) is seemingly enough.</p>

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
    drift: 40,
    neighborScalar: 50,
    nextLayerScalar: 20,
  }),

  new Layer("layer2", mkNewEl("50%", ), {
    maxNewElsPerTick: 15,
    ageOfDeath: 1,
    drift: 50,
    neighborScalar: 5,
    prevLayerScalar: 5,
    prevLayerLikenessScalar: 20,
  }),

];

for (const layer of layers) {
    document.querySelectorAll(`.${layer.className}.layerParams > input`).forEach((input) => {
        const param = input.getAttribute("param");

        // pre-fill input values
        input.value = layer.knobs[param];

        input.onchange = () => {
            console.log(`setting ${layer.className}.${param} to ${input.value}`);
            layer.knobs[param] = input.value;
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
const h = 60;

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

class UniverseState {
  constructor(layers) {
    this.tick = 0;
    this.layers = layers;
  }

  neighboringLayers(layerIndex) {
    const prevIndex = layerIndex-1;
    const prev = prevIndex < 0 ? null : this.layers[prevIndex];

    const nextIndex = layerIndex+1;
    const next = nextIndex >= this.layers.length ? null : this.layers[nextIndex];

    return [prev, next];
  }
}

const defaultKnobs = {
  maxNewElsPerTick: 10,
  ageOfDeath: 30,
  drift: 30,
  neighborScalar: 0,
  prevLayerScalar: 0,
  prevLayerLikenessScalar: 0,
  nextLayerScalar: 0,
  nextLayerLikenessScalar: 0,
  chaos: 0,
};

class Layer {
  constructor(className, newEl, knobs = {}) {
    this.className = className;
    this.els = {};
    this.diff = {};
    this.newEl = newEl;
    this.knobs = { ...defaultKnobs, ...knobs };
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

  update(state, thisLayerIndex) {
    // Apply diff from previous update first. The diff can't be applied last
    // because it needs to be present during the draw phase.
    this.applyDiff();

    const allEls = this.getAll().sort(() => Math.random() - 0.5);

    if (allEls.length == 0) {
      const newEl = this.newEl(this, [])
      newEl.tick = state.tick;
      this.set([w/2, h/2], newEl);
      return;
    }

    let newEls = 0;
    for (const el of allEls) {
      const nCoord = randEmptyNeighboringCoord(this, el.coord);
      if (!nCoord) continue; // el has no empty neighboring spots

      const newEl = this.newEl(this, neighboringElsOf(this, nCoord))
      newEl.tick = state.tick;
      this.set(nCoord, newEl);

      newEls++;
      if (newEls >= this.knobs.maxNewElsPerTick) break;
    }

    const calcLayerBonus = (el, layer, scalar, likenessScalar) => {
        if (!layer) return 0;
        const nEls = neighboringElsOf(layer, el.coord, true)

        const likeness = nEls.reduce((likeness, nEl) => {
            const diff = Math.abs(nEl.c - el.c);
            return likeness + Math.max(diff, Math.abs(1 - diff));
        }, 0);

        return (nEls.length * scalar) + (likeness * likenessScalar);
    };

    const [prevLayer, nextLayer] = state.neighboringLayers(thisLayerIndex);

    for (const el of allEls) {
      const age = state.tick - el.tick;
      const neighborBonus = neighboringElsOf(this, el.coord).length * this.knobs.neighborScalar;
      const prevLayerBonus = calcLayerBonus(el, prevLayer, this.knobs.prevLayerScalar, this.knobs.prevLayerLikenessScalar);
      const nextLayerBonus = calcLayerBonus(el, nextLayer, this.knobs.nextLayerScalar, this.knobs.nextLayerLikenessScalar);
      const chaos = (this.chaos > 0) ? randn(this.knobs.chaos) : 0;

      if (age - neighborBonus - prevLayerBonus - nextLayerBonus + chaos >= this.knobs.ageOfDeath) {
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

function newEl(h, l) {
  return {
    h: h,
    s: "100%",
    l: l,
    c: h / 360, // c is used to compare the element to others
  };
}

function mkNewEl(l) {
  return (layer, nEls) => {
    const s = "100%";
    if (nEls.length == 0) {
      const h = randn(360);
      return newEl(h, l);
    }

    // for each h (which can be considered as degrees around a circle) break the
    // h down into x and y vectors, and add those up separately. Then find the
    // angle between those two resulting vectors, and that's the "average" h
    // value.
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
    h += (Math.random() * layer.knobs.drift * 2) - layer.knobs.drift;
    h = (h + 360) % 360;

    return newEl(h, l);
  }
}

class Universe {
  constructor(canvasesByClass, layers) {
    this.canvasesByClass = canvasesByClass;
    this.state = new UniverseState(layers);
  }

  update() {
    this.state.tick++;
    let prevLayer;
    this.state.layers.forEach((layer, i) => {
        layer.update(this.state, i);
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
        <label>Color Drift</label><input type="text" param="drift" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Scalar</label><input type="text" param="neighborScalar" />
        <label>Top Layer Neighbor Scalar</label><input type="text" param="nextLayerScalar" />
        <label>Top Layer Neighbor Likeness Scalar</label><input type="text" param="nextLayerLikenessScalar" />
    </div>
  </div>

  <div class="columns six">
    <h3>Top Layer</h3>
    <div class="canvasContainer"><canvas class="layer2"></canvas></div>
    <div class="layer2 layerParams">
        <label>Max New Elements Per Tick</label><input type="text" param="maxNewElsPerTick" />
        <label>Color Drift</label><input type="text" param="drift" />
        <label>Age of Death</label><input type="text" param="ageOfDeath" />
        <label>Neighbor Scalar</label><input type="text" param="neighborScalar" />
        <label>Bottom Layer Neighbor Scalar</label><input type="text" param="prevLayerScalar" />
        <label>Bottom Layer Neighbor Likeness Scalar</label><input type="text" param="prevLayerLikenessScalar" />
    </div>
  </div>

</div>

<p>Once again, this visualization iterates upon the previous. In the last one the
top layer was able to “see” the bottom, and was therefore able to bolster or
penalize its own elements which were on or near bottom layer elements, but not
vice-versa. This time both layers can see each other, and the “Layer Neighbor
Scalar” can be used to adjust lifetime of elements which are on/near elements of
the neighboring layer.</p>

<p>By default, the bottom layer has a high affinity to the top, and the top layer
has a some (but not as much) affinity in return.</p>

<p>Another addition is the “likeness” scalar. Likeness is defined as the degree to
which one element is like another. In this visualization likeness is determined
by color. The “Layer Neighbor Likeness Scalar” adjusts the lifetime of elements
based on how like they are to nearby elements on the neighboring layer.</p>

<p>By default, the top layer has a high affinity for the bottom’s color, but the
bottom doesn’t care about the top’s color at all (and so its color will drift
aimlessly).</p>

<p>And finally “Color Drift” can be used to adjust the degree to which the color of
new elements can diverge from its parents. This has always been hardcoded, but
can now be adjusted separately across the different layers.</p>

<p>In the default configuration the top layer will (eventually) converge to roughly
match the bottom both in shape and color. When I first implemented the likeness
scaling I thought it was broken, because the top would never converge to the
bottom’s color.</p>

<p>What I eventually realized was that the top must have a higher color drift than
the bottom in order for it to do so, otherwise the top would always be playing
catchup. However, if the drift difference is <em>too</em> high then the top layer
becomes chaos and also doesn’t really follow the color of the bottom. A
difference of 10 (degrees out of 360) is seemingly enough.</p>

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
    drift: 40,
    neighborScalar: 50,
    nextLayerScalar: 20,
  }),

  new Layer("layer2", mkNewEl("50%", ), {
    maxNewElsPerTick: 15,
    ageOfDeath: 1,
    drift: 50,
    neighborScalar: 5,
    prevLayerScalar: 5,
    prevLayerLikenessScalar: 20,
  }),

];

for (const layer of layers) {
    document.querySelectorAll(`.${layer.className}.layerParams > input`).forEach((input) => {
        const param = input.getAttribute("param");

        // pre-fill input values
        input.value = layer.knobs[param];

        input.onchange = () => {
            console.log(`setting ${layer.className}.${param} to ${input.value}`);
            layer.knobs[param] = input.value;
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
