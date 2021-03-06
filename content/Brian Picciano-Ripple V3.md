
+++
title = "Ripple V3"
date = 2021-05-11T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Movement: Arrow keys or WASD
Jump: Space
Goal: Jump as many times as possible without touching a rip..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/05/11/ripple-v3.html"
raw = """
<p>
    <b>Movement:</b> Arrow keys or WASD<br />
    <b>Jump:</b> Space<br />
    <b>Goal:</b> Jump as many times as possible without touching a ripple!<br />
    <br />
    <b>Press Jump To Begin!</b>
</p>

<p><em>Who can make the muddy water clear?<br />
Let it be still, and it will gradually become clear.</em></p>

<canvas id="canvas" style="border:1px dashed #AAA" tabindex="0">
Your browser doesn't support canvas. At this point in the world that's actually
pretty cool, well done!
</canvas>
<p><button onclick="reset()">(R)eset</button>
<span style="font-size: 2rem; margin-left: 1rem;">Score:
    <span style="font-weight: bold" id="score">0</span>
</span></p>

<script type="text/javascript">

const palette = [
    "#264653",
    "#2A9D8F",
    "#E9C46A",
    "#F4A261",
    "#E76F51",
];

const width = 800;
const height = 600;

function hypotenuse(w, h) {
    return Math.sqrt(Math.pow(w, 2) + Math.pow(h, 2));
}

let canvas = document.getElementById("canvas");
canvas.width = width;
canvas.height = height;

const whitelistedKeys = {
    "ArrowUp": {},
    "KeyW": {map: "ArrowUp"},
    "ArrowLeft": {},
    "KeyA": {map: "ArrowLeft"},
    "ArrowRight": {},
    "KeyD": {map: "ArrowRight"},
    "ArrowDown": {},
    "KeyS": {map: "ArrowDown"},
    "Space": {},
    "KeyR": {},
};

let keyboard = {};

canvas.addEventListener('keydown', (event) => {
    let keyInfo = whitelistedKeys[event.code];
    if (!keyInfo) return;

    let code = event.code;
    if (keyInfo.map) code = keyInfo.map;

    event.preventDefault();
    keyboard[code] = true;
});

canvas.addEventListener('keyup', (event) => {
    let keyInfo = whitelistedKeys[event.code];
    if (!keyInfo) return;

    let code = event.code;
    if (keyInfo.map) code = keyInfo.map;

    event.preventDefault();
    delete keyboard[code];
});


const C = 700; // scales the overall speed of the radius
const T = 500; // on which tick the radius change becomes linear

/*
    f(x) = sqrt(C*x)                        when x < T
           (C/(2*sqrt(CT)))(x-T) + sqrt(CT) when x >= T

    radius(x) = f(x) + playerRadius;
*/

const F1 = (x) => Math.sqrt(C*x);
const F2C1 = C / (2 * Math.sqrt(C*T));
const F2C2 = Math.sqrt(C * T);
const F2 = (x) => (F2C1 * (x - T)) + F2C2;
const F = (x) => {
    if (x < T) return F1(x);
    return F2(x);
};

class Ripple {

    constructor(id, currTick, x, y, bounces, color) {
        this.id = id;
        this.tick = currTick;
        this.x = x;
        this.y = y;
        this.thickness = Math.pow(bounces+1, 1.25);
        this.color = color;
        this.winner = false;

        this.maxRadius = hypotenuse(x, y);
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(x, height-y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, height-y));
    }

    radius(currTick) {
        const x = currTick - this.tick;
        return F(x) + playerRadius;
    }

    draw(ctx, currTick) {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius(currTick), 0, Math.PI * 2, false);
        ctx.closePath();
        ctx.lineWidth = this.thickness;
        ctx.strokeStyle = this.winner ? "#FF0000" : this.color;
        ctx.stroke();
    }

    canGC(currTick) {
        return this.radius(currTick) > this.maxRadius;
    }
}

const playerRadius = 10;
const playerMoveAccel = 0.5;
const playerMoveDecel = 0.7;
const playerMaxMoveSpeed = 4;
const playerJumpSpeed = 0.08;
const playerMaxHeight = 1;
const playerGravity = 0.01;

class Player{

    constructor(x, y, color) {
        this.x = x;
        this.y = y;
        this.z = 0;
        this.xVelocity = 0;
        this.yVelocity = 0;
        this.zVelocity = 0;
        this.color = color;
        this.falling = false;
        this.lastJumpHeight = 0;
        this.loser = false;
    }

    act() {
        if (keyboard["ArrowUp"]) {
            this.yVelocity = Math.max(-playerMaxMoveSpeed, this.yVelocity - playerMoveAccel);
        } else if (keyboard["ArrowDown"]) {
            this.yVelocity = Math.min(playerMaxMoveSpeed, this.yVelocity + playerMoveAccel);
        } else if (this.yVelocity > 0) {
            this.yVelocity = Math.max(0, this.yVelocity - playerMoveDecel);
        } else if (this.yVelocity < 0) {
            this.yVelocity = Math.min(0, this.yVelocity + playerMoveDecel);
        }

        this.y += this.yVelocity;
        if (this.y < 0) this.y += height;
        else if (this.y > height) this.y -= height;

        if (keyboard["ArrowLeft"]) {
            this.xVelocity = Math.max(-playerMaxMoveSpeed, this.xVelocity - playerMoveAccel);
        } else if (keyboard["ArrowRight"]) {
            this.xVelocity = Math.min(playerMaxMoveSpeed, this.xVelocity + playerMoveAccel);
        } else if (this.xVelocity > 0) {
            this.xVelocity = Math.max(0, this.xVelocity - playerMoveDecel);
        } else if (this.xVelocity < 0) {
            this.xVelocity = Math.min(0, this.xVelocity + playerMoveDecel);
        }

        this.x += this.xVelocity;
        if (this.x < 0) this.x += width;
        else if (this.x > width) this.x -= width;

        let jumpHeld = keyboard["Space"];

        if (jumpHeld && !this.falling && this.z < playerMaxHeight) {
            this.lastJumpHeight = 0;
            this.zVelocity = playerJumpSpeed;
        } else {
            this.zVelocity = Math.max(-playerJumpSpeed, this.zVelocity - playerGravity);
            this.falling = this.z > 0;
        }

        let prevZ = this.z;
        this.z = Math.max(0, this.z + this.zVelocity);
        this.lastJumpHeight = Math.max(this.z, this.lastJumpHeight);
    }

    drawAt(ctx, atX, atY) {
        const y = atY - (this.z * 40);
        const radius = playerRadius * (this.z+1)

        // draw main
        ctx.beginPath();
        ctx.arc(atX, y, radius, 0, Math.PI * 2, false);
        ctx.closePath();
        ctx.lineWidth = 0;
        ctx.fillStyle = this.color;
        ctx.fill();
        if (this.loser) {
            ctx.strokeStyle = '#FF0000';
            ctx.lineWidth = 2;
            ctx.stroke();
        }

        // draw shadow, if in the air
        if (this.z > 0) {
            let radius = Math.max(0, playerRadius * (1.2 - this.z));
            ctx.beginPath();
            ctx.arc(atX, atY, radius, 0, Math.PI * 2, false);
            ctx.closePath();
            ctx.lineWidth = 0;
            ctx.fillStyle = this.color+"33";
            ctx.fill();
        }
    }

    draw(ctx) {
        [-1, 0, 1].forEach((wScalar) => {
            const w = width * wScalar;
            [-1, 0, 1].forEach((hScalar) => {
                const h = height * hScalar;
                this.drawAt(ctx, this.x+w, this.y+h);
            })
        })
    }
}

class Game {

    constructor(canvas, scoreEl) {
        this.currTick = 0;
        this.player = new Player(width/2, height/2, palette[0]);
        this.state = 'play';
        this.score = 0;
        this.scoreEl = scoreEl;
        this.canvas = canvas;
        this.ctx = canvas.getContext("2d");
        this.ripples = [];
        this.nextRippleID = 0;
    }

    shouldReset() {
        return keyboard['KeyR'];
    }

    newRippleID() {
        let id = this.nextRippleID;
        this.nextRippleID++;
        return id;
    }

    // newRipple initializes and stores a new ripple at the given coordinates, as
    // well as all sub-ripples which make up the initial ripple's reflections.
    newRipple(x, y, bounces, color) {
        color = color ? color : palette[Math.floor(Math.random() * palette.length)];

        let ripplePos = [];
        let nextRipples = [];

        let addRipple = (x, y) => {
            for (let i in ripplePos) {
                if (ripplePos[i][0] == x && ripplePos[i][1] == y) return;
            }

            let ripple = new Ripple(this.newRippleID(), this.currTick, x, y, bounces, color);
            nextRipples.push(ripple);
            ripplePos.push([x, y]);
            this.ripples.push(ripple);
        };

        // add initial ripple, after this we deal with the sub-ripples.
        addRipple(x, y);

        while (bounces > 0) {
            bounces--;
            let prevRipples = nextRipples;
            nextRipples = [];

            for (let i in prevRipples) {
                let prevX = prevRipples[i].x;
                let prevY = prevRipples[i].y;

                [-1, 0, 1].forEach((wScalar) => {
                    const w = this.canvas.width * wScalar;
                    [-1, 0, 1].forEach((hScalar) => {
                        const h = this.canvas.height * hScalar;
                        addRipple(prevX + w, prevY + h);
                    })
                })
            }
        }
    }

    // playerRipplesState returns a mapping of rippleID -> boolean, where each
    // boolean indicates the ripple's relation to the player at the moment. true
    // indicates the player is outside the ripple, false indicates the player is
    // within the ripple.
    playerRipplesState() {
        let state = {};
        for (let i in this.ripples) {
            let ripple = this.ripples[i];
            let rippleRadius = ripple.radius(this.currTick);
            let hs = Math.pow(ripple.x-this.player.x, 2) + Math.pow(ripple.y-this.player.y, 2);
            state[ripple.id] = hs > Math.pow(rippleRadius + playerRadius, 2);
        }
        return state;
    }

    playerHasJumpedOverRipple(prev, curr) {
        for (const rippleID in prev) {
            if (!curr.hasOwnProperty(rippleID)) continue;
            if (curr[rippleID] != prev[rippleID]) return true;
        }
        return false;
    }

    update() {
        if (this.state != 'play') return;

        let playerPrevZ = this.player.z;
        this.player.act();

        if (playerPrevZ == 0 && this.player.z > 0) {
            // player has jumped
            this.prevPlayerRipplesState = this.playerRipplesState();

        } else if (playerPrevZ > 0 && this.player.z == 0) {

            // player has landed, don't produce a ripple unless there are no
            // existing ripples or the player jumped over an existing one.
            if (
                this.ripples.length == 0 ||
                this.playerHasJumpedOverRipple(
                    this.prevPlayerRipplesState,
                    this.playerRipplesState()
                )
            ) {
                //let bounces = Math.floor((this.player.lastJumpHeight*1.8)+1);
                const bounces = 1;

                console.log("spawning ripple with bounces:", bounces);
                this.newRipple(this.player.x, this.player.y, bounces);
                this.score += bounces;
            }
        }

        if (this.player.z == 0) {
            for (let i in this.ripples) {
                let ripple = this.ripples[i];
                let rippleRadius = ripple.radius(this.currTick);
                if (rippleRadius < playerRadius * 1.5) continue;
                let hs = Math.pow(ripple.x-this.player.x, 2) + Math.pow(ripple.y-this.player.y, 2);
                if (hs > Math.pow(rippleRadius + playerRadius, 2)) {
                    continue;
                } else if (hs <= Math.pow(rippleRadius - playerRadius, 2)) {
                    continue;
                } else {
                    console.log("game over", ripple);
                    ripple.winner = true;
                    this.player.loser = true;
                    this.state = 'gameOver';
                    // deliberately don't break here, in case multiple ripples hit
                    // the player on the same frame
                }
            }
        }

        this.ripples = this.ripples.filter(ripple => !ripple.canGC(this.currTick));

        this.currTick++;
    }

    draw() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.ripples.forEach(ripple => ripple.draw(this.ctx, this.currTick));
        this.player.draw(this.ctx)
        this.scoreEl.innerHTML = this.score;
    }
}


const requestAnimationFrame =
    window.requestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.msRequestAnimationFrame;

let game = new Game(canvas, document.getElementById("score"));

function reset() {
    game = new Game(canvas, document.getElementById("score"));
}

function nextFrame() {
    if (game.shouldReset()) reset();

    game.update()
    game.draw()
    requestAnimationFrame(nextFrame);
}
requestAnimationFrame(nextFrame);

canvas.focus();

</script>

<h2 id="changelog">Changelog</h2>

<p>The previous version was two easy to break, even with the requirement of jumping
over a ripple to generate a new one and increase your score. This led to the
following major changes:</p>

<ul>
  <li>
    <p>The game now incorporates asteroid/pacman mechanics. Rather than bouncing off
walls, the player and ripples will instead come out the opposite wall they
travel through.</p>
  </li>
  <li>
    <p>Jump height no longer affects score or the “strength” of a ripple.</p>
  </li>
</ul>"""

+++
<p>
    <b>Movement:</b> Arrow keys or WASD<br />
    <b>Jump:</b> Space<br />
    <b>Goal:</b> Jump as many times as possible without touching a ripple!<br />
    <br />
    <b>Press Jump To Begin!</b>
</p>

<p><em>Who can make the muddy water clear?<br />
Let it be still, and it will gradually become clear.</em></p>

<canvas id="canvas" style="border:1px dashed #AAA" tabindex="0">
Your browser doesn't support canvas. At this point in the world that's actually
pretty cool, well done!
</canvas>
<p><button onclick="reset()">(R)eset</button>
<span style="font-size: 2rem; margin-left: 1rem;">Score:
    <span style="font-weight: bold" id="score">0</span>
</span></p>

<script type="text/javascript">

const palette = [
    "#264653",
    "#2A9D8F",
    "#E9C46A",
    "#F4A261",
    "#E76F51",
];

const width = 800;
const height = 600;

function hypotenuse(w, h) {
    return Math.sqrt(Math.pow(w, 2) + Math.pow(h, 2));
}

let canvas = document.getElementById("canvas");
canvas.width = width;
canvas.height = height;

const whitelistedKeys = {
    "ArrowUp": {},
    "KeyW": {map: "ArrowUp"},
    "ArrowLeft": {},
    "KeyA": {map: "ArrowLeft"},
    "ArrowRight": {},
    "KeyD": {map: "ArrowRight"},
    "ArrowDown": {},
    "KeyS": {map: "ArrowDown"},
    "Space": {},
    "KeyR": {},
};

let keyboard = {};

canvas.addEventListener('keydown', (event) => {
    let keyInfo = whitelistedKeys[event.code];
    if (!keyInfo) return;

    let code = event.code;
    if (keyInfo.map) code = keyInfo.map;

    event.preventDefault();
    keyboard[code] = true;
});

canvas.addEventListener('keyup', (event) => {
    let keyInfo = whitelistedKeys[event.code];
    if (!keyInfo) return;

    let code = event.code;
    if (keyInfo.map) code = keyInfo.map;

    event.preventDefault();
    delete keyboard[code];
});


const C = 700; // scales the overall speed of the radius
const T = 500; // on which tick the radius change becomes linear

/*
    f(x) = sqrt(C*x)                        when x < T
           (C/(2*sqrt(CT)))(x-T) + sqrt(CT) when x >= T

    radius(x) = f(x) + playerRadius;
*/

const F1 = (x) => Math.sqrt(C*x);
const F2C1 = C / (2 * Math.sqrt(C*T));
const F2C2 = Math.sqrt(C * T);
const F2 = (x) => (F2C1 * (x - T)) + F2C2;
const F = (x) => {
    if (x < T) return F1(x);
    return F2(x);
};

class Ripple {

    constructor(id, currTick, x, y, bounces, color) {
        this.id = id;
        this.tick = currTick;
        this.x = x;
        this.y = y;
        this.thickness = Math.pow(bounces+1, 1.25);
        this.color = color;
        this.winner = false;

        this.maxRadius = hypotenuse(x, y);
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(x, height-y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, height-y));
    }

    radius(currTick) {
        const x = currTick - this.tick;
        return F(x) + playerRadius;
    }

    draw(ctx, currTick) {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius(currTick), 0, Math.PI * 2, false);
        ctx.closePath();
        ctx.lineWidth = this.thickness;
        ctx.strokeStyle = this.winner ? "#FF0000" : this.color;
        ctx.stroke();
    }

    canGC(currTick) {
        return this.radius(currTick) > this.maxRadius;
    }
}

const playerRadius = 10;
const playerMoveAccel = 0.5;
const playerMoveDecel = 0.7;
const playerMaxMoveSpeed = 4;
const playerJumpSpeed = 0.08;
const playerMaxHeight = 1;
const playerGravity = 0.01;

class Player{

    constructor(x, y, color) {
        this.x = x;
        this.y = y;
        this.z = 0;
        this.xVelocity = 0;
        this.yVelocity = 0;
        this.zVelocity = 0;
        this.color = color;
        this.falling = false;
        this.lastJumpHeight = 0;
        this.loser = false;
    }

    act() {
        if (keyboard["ArrowUp"]) {
            this.yVelocity = Math.max(-playerMaxMoveSpeed, this.yVelocity - playerMoveAccel);
        } else if (keyboard["ArrowDown"]) {
            this.yVelocity = Math.min(playerMaxMoveSpeed, this.yVelocity + playerMoveAccel);
        } else if (this.yVelocity > 0) {
            this.yVelocity = Math.max(0, this.yVelocity - playerMoveDecel);
        } else if (this.yVelocity < 0) {
            this.yVelocity = Math.min(0, this.yVelocity + playerMoveDecel);
        }

        this.y += this.yVelocity;
        if (this.y < 0) this.y += height;
        else if (this.y > height) this.y -= height;

        if (keyboard["ArrowLeft"]) {
            this.xVelocity = Math.max(-playerMaxMoveSpeed, this.xVelocity - playerMoveAccel);
        } else if (keyboard["ArrowRight"]) {
            this.xVelocity = Math.min(playerMaxMoveSpeed, this.xVelocity + playerMoveAccel);
        } else if (this.xVelocity > 0) {
            this.xVelocity = Math.max(0, this.xVelocity - playerMoveDecel);
        } else if (this.xVelocity < 0) {
            this.xVelocity = Math.min(0, this.xVelocity + playerMoveDecel);
        }

        this.x += this.xVelocity;
        if (this.x < 0) this.x += width;
        else if (this.x > width) this.x -= width;

        let jumpHeld = keyboard["Space"];

        if (jumpHeld && !this.falling && this.z < playerMaxHeight) {
            this.lastJumpHeight = 0;
            this.zVelocity = playerJumpSpeed;
        } else {
            this.zVelocity = Math.max(-playerJumpSpeed, this.zVelocity - playerGravity);
            this.falling = this.z > 0;
        }

        let prevZ = this.z;
        this.z = Math.max(0, this.z + this.zVelocity);
        this.lastJumpHeight = Math.max(this.z, this.lastJumpHeight);
    }

    drawAt(ctx, atX, atY) {
        const y = atY - (this.z * 40);
        const radius = playerRadius * (this.z+1)

        // draw main
        ctx.beginPath();
        ctx.arc(atX, y, radius, 0, Math.PI * 2, false);
        ctx.closePath();
        ctx.lineWidth = 0;
        ctx.fillStyle = this.color;
        ctx.fill();
        if (this.loser) {
            ctx.strokeStyle = '#FF0000';
            ctx.lineWidth = 2;
            ctx.stroke();
        }

        // draw shadow, if in the air
        if (this.z > 0) {
            let radius = Math.max(0, playerRadius * (1.2 - this.z));
            ctx.beginPath();
            ctx.arc(atX, atY, radius, 0, Math.PI * 2, false);
            ctx.closePath();
            ctx.lineWidth = 0;
            ctx.fillStyle = this.color+"33";
            ctx.fill();
        }
    }

    draw(ctx) {
        [-1, 0, 1].forEach((wScalar) => {
            const w = width * wScalar;
            [-1, 0, 1].forEach((hScalar) => {
                const h = height * hScalar;
                this.drawAt(ctx, this.x+w, this.y+h);
            })
        })
    }
}

class Game {

    constructor(canvas, scoreEl) {
        this.currTick = 0;
        this.player = new Player(width/2, height/2, palette[0]);
        this.state = 'play';
        this.score = 0;
        this.scoreEl = scoreEl;
        this.canvas = canvas;
        this.ctx = canvas.getContext("2d");
        this.ripples = [];
        this.nextRippleID = 0;
    }

    shouldReset() {
        return keyboard['KeyR'];
    }

    newRippleID() {
        let id = this.nextRippleID;
        this.nextRippleID++;
        return id;
    }

    // newRipple initializes and stores a new ripple at the given coordinates, as
    // well as all sub-ripples which make up the initial ripple's reflections.
    newRipple(x, y, bounces, color) {
        color = color ? color : palette[Math.floor(Math.random() * palette.length)];

        let ripplePos = [];
        let nextRipples = [];

        let addRipple = (x, y) => {
            for (let i in ripplePos) {
                if (ripplePos[i][0] == x && ripplePos[i][1] == y) return;
            }

            let ripple = new Ripple(this.newRippleID(), this.currTick, x, y, bounces, color);
            nextRipples.push(ripple);
            ripplePos.push([x, y]);
            this.ripples.push(ripple);
        };

        // add initial ripple, after this we deal with the sub-ripples.
        addRipple(x, y);

        while (bounces > 0) {
            bounces--;
            let prevRipples = nextRipples;
            nextRipples = [];

            for (let i in prevRipples) {
                let prevX = prevRipples[i].x;
                let prevY = prevRipples[i].y;

                [-1, 0, 1].forEach((wScalar) => {
                    const w = this.canvas.width * wScalar;
                    [-1, 0, 1].forEach((hScalar) => {
                        const h = this.canvas.height * hScalar;
                        addRipple(prevX + w, prevY + h);
                    })
                })
            }
        }
    }

    // playerRipplesState returns a mapping of rippleID -> boolean, where each
    // boolean indicates the ripple's relation to the player at the moment. true
    // indicates the player is outside the ripple, false indicates the player is
    // within the ripple.
    playerRipplesState() {
        let state = {};
        for (let i in this.ripples) {
            let ripple = this.ripples[i];
            let rippleRadius = ripple.radius(this.currTick);
            let hs = Math.pow(ripple.x-this.player.x, 2) + Math.pow(ripple.y-this.player.y, 2);
            state[ripple.id] = hs > Math.pow(rippleRadius + playerRadius, 2);
        }
        return state;
    }

    playerHasJumpedOverRipple(prev, curr) {
        for (const rippleID in prev) {
            if (!curr.hasOwnProperty(rippleID)) continue;
            if (curr[rippleID] != prev[rippleID]) return true;
        }
        return false;
    }

    update() {
        if (this.state != 'play') return;

        let playerPrevZ = this.player.z;
        this.player.act();

        if (playerPrevZ == 0 && this.player.z > 0) {
            // player has jumped
            this.prevPlayerRipplesState = this.playerRipplesState();

        } else if (playerPrevZ > 0 && this.player.z == 0) {

            // player has landed, don't produce a ripple unless there are no
            // existing ripples or the player jumped over an existing one.
            if (
                this.ripples.length == 0 ||
                this.playerHasJumpedOverRipple(
                    this.prevPlayerRipplesState,
                    this.playerRipplesState()
                )
            ) {
                //let bounces = Math.floor((this.player.lastJumpHeight*1.8)+1);
                const bounces = 1;

                console.log("spawning ripple with bounces:", bounces);
                this.newRipple(this.player.x, this.player.y, bounces);
                this.score += bounces;
            }
        }

        if (this.player.z == 0) {
            for (let i in this.ripples) {
                let ripple = this.ripples[i];
                let rippleRadius = ripple.radius(this.currTick);
                if (rippleRadius < playerRadius * 1.5) continue;
                let hs = Math.pow(ripple.x-this.player.x, 2) + Math.pow(ripple.y-this.player.y, 2);
                if (hs > Math.pow(rippleRadius + playerRadius, 2)) {
                    continue;
                } else if (hs <= Math.pow(rippleRadius - playerRadius, 2)) {
                    continue;
                } else {
                    console.log("game over", ripple);
                    ripple.winner = true;
                    this.player.loser = true;
                    this.state = 'gameOver';
                    // deliberately don't break here, in case multiple ripples hit
                    // the player on the same frame
                }
            }
        }

        this.ripples = this.ripples.filter(ripple => !ripple.canGC(this.currTick));

        this.currTick++;
    }

    draw() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.ripples.forEach(ripple => ripple.draw(this.ctx, this.currTick));
        this.player.draw(this.ctx)
        this.scoreEl.innerHTML = this.score;
    }
}


const requestAnimationFrame =
    window.requestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.msRequestAnimationFrame;

let game = new Game(canvas, document.getElementById("score"));

function reset() {
    game = new Game(canvas, document.getElementById("score"));
}

function nextFrame() {
    if (game.shouldReset()) reset();

    game.update()
    game.draw()
    requestAnimationFrame(nextFrame);
}
requestAnimationFrame(nextFrame);

canvas.focus();

</script>

<h2 id="changelog">Changelog</h2>

<p>The previous version was two easy to break, even with the requirement of jumping
over a ripple to generate a new one and increase your score. This led to the
following major changes:</p>

<ul>
  <li>
    <p>The game now incorporates asteroid/pacman mechanics. Rather than bouncing off
walls, the player and ripples will instead come out the opposite wall they
travel through.</p>
  </li>
  <li>
    <p>Jump height no longer affects score or the “strength” of a ripple.</p>
  </li>
</ul>
