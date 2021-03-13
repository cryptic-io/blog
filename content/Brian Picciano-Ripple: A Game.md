
+++
title = "Ripple: A Game"
date = 2021-03-12T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Movement: Arrow keys or WASD
Jump: Space
Goal: Jump as many times as possible without touching a rip..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/03/12/ripple-a-game.html"
raw = """
<p>
    <b>Movement:</b> Arrow keys or WASD<br />
    <b>Jump:</b> Space<br />
    <b>Goal:</b> Jump as many times as possible without touching a ripple!<br />
    <br />
    <b>Press Jump To Begin!</b>
</p>

<canvas id="canvas" style="border:1px dashed #AAA" tabindex="0">
Your browser doesn't support canvas. At this point in the world that's actually
pretty cool, well done!
</canvas>
<p><button onclick="resetGame()">(R)eset</button>
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

let score = document.getElementById("score");

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

let ctx = canvas.getContext("2d");

let currTick;
let drops;

class Drop {
    constructor(x, y, bounces, color) {
        this.tick = currTick;
        this.x = x;
        this.y = y;
        this.thickness = (bounces+1) * 0.25;
        this.color = color ? color : palette[Math.floor(Math.random() * palette.length)];
        this.winner = false;

        this.maxRadius = hypotenuse(x, y);
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(x, height-y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, height-y));

        drops.push(this);

        if (bounces > 0) {
            new Drop(x, -y, bounces-1, this.color);
            new Drop(-x, y, bounces-1, this.color);
            new Drop((2*width)-x, y, bounces-1, this.color);
            new Drop(x, (2*height)-y, bounces-1, this.color);
        }
    }

    radius() { return currTick - this.tick; }

    draw() {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius(), 0, Math.PI * 2, false);
        ctx.closePath();
        ctx.lineWidth = this.thickness;
        ctx.strokeStyle = this.winner ? "#FF0000" : this.color;
        ctx.stroke();
    }

    canGC() {
        return this.radius() > this.maxRadius;
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
        this.y = Math.max(0+playerRadius, this.y);
        this.y = Math.min(height-playerRadius, this.y);

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
        this.x = Math.max(0+playerRadius, this.x);
        this.x = Math.min(width-playerRadius, this.x);

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

    draw() {
        let y = this.y - (this.z * 40);
        let radius = playerRadius * (this.z+1)

        // draw main
        ctx.beginPath();
        ctx.arc(this.x, y, radius, 0, Math.PI * 2, false);
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
            ctx.arc(this.x, this.y, radius, 0, Math.PI * 2, false);
            ctx.closePath();
            ctx.lineWidth = 0;
            ctx.fillStyle = this.color+"33";
            ctx.fill();
        }
    }
}

let player;
let gameState;
let numJumps;

function resetGame() {
    currTick = 0;
    drops = [];
    player = new Player(width/2, height/2, palette[0]);
    gameState = 'play';
    numJumps = 0;
    canvas.focus();
}
resetGame();

let requestAnimationFrame =
    window.requestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.msRequestAnimationFrame;

function doTick() {
    if (keyboard['KeyR']) {
        resetGame();
    }

    if (gameState == 'play') {
        let playerPrevZ = player.z;
        player.act();
        if (playerPrevZ > 0 && player.z == 0) {
            let bounces = Math.floor((player.lastJumpHeight*1.8)+1);
            console.log("spawning drop with bounces:", bounces);
            new Drop(player.x, player.y, bounces);
        } else if (playerPrevZ == 0 && player.z > 0) {
            numJumps++;
        }
        score.innerHTML = numJumps;

        if (player.z == 0) {
            for (let i in drops) {
                let drop = drops[i];
                let dropRadius = drop.radius();
                if (dropRadius < playerRadius * 1.5) continue;
                let hs = Math.pow(drop.x-player.x, 2) + Math.pow(drop.y-player.y, 2);
                if (hs > Math.pow(playerRadius + dropRadius, 2)) {
                    continue;
                } else if (Math.sqrt(hs) <= Math.abs(dropRadius-playerRadius)) {
                    continue;
                } else {
                    console.log("game over");
                    drop.winner = true;
                    player.loser = true;
                    gameState = 'gameOver';
                }
            }
        }
    }

    drops = drops.filter(drop => !drop.canGC());

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drops.forEach(drop => drop.draw());
    player.draw()

    if (gameState == 'play') currTick++;
    requestAnimationFrame(doTick);
}
requestAnimationFrame(doTick);

</script>

<p><em>Do you have the patience to wait<br />
till your mud settles and the water is clear?</em></p>

<h2 id="backstory">Backstory</h2>

<p>This is a game I originally implemented in lua, which you can find <a href="https://github.com/mediocregopher/ripple">here</a>.
It’s a fun concept that I wanted to show off again, as well as to see if I could
whip it up in an evening in javascript (I can!)</p>

<p>Send me your high scores! I top out around 17.</p>"""

+++
<p>
    <b>Movement:</b> Arrow keys or WASD<br />
    <b>Jump:</b> Space<br />
    <b>Goal:</b> Jump as many times as possible without touching a ripple!<br />
    <br />
    <b>Press Jump To Begin!</b>
</p>

<canvas id="canvas" style="border:1px dashed #AAA" tabindex="0">
Your browser doesn't support canvas. At this point in the world that's actually
pretty cool, well done!
</canvas>
<p><button onclick="resetGame()">(R)eset</button>
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

let score = document.getElementById("score");

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

let ctx = canvas.getContext("2d");

let currTick;
let drops;

class Drop {
    constructor(x, y, bounces, color) {
        this.tick = currTick;
        this.x = x;
        this.y = y;
        this.thickness = (bounces+1) * 0.25;
        this.color = color ? color : palette[Math.floor(Math.random() * palette.length)];
        this.winner = false;

        this.maxRadius = hypotenuse(x, y);
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(x, height-y));
        this.maxRadius = Math.max(this.maxRadius, hypotenuse(width-x, height-y));

        drops.push(this);

        if (bounces > 0) {
            new Drop(x, -y, bounces-1, this.color);
            new Drop(-x, y, bounces-1, this.color);
            new Drop((2*width)-x, y, bounces-1, this.color);
            new Drop(x, (2*height)-y, bounces-1, this.color);
        }
    }

    radius() { return currTick - this.tick; }

    draw() {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius(), 0, Math.PI * 2, false);
        ctx.closePath();
        ctx.lineWidth = this.thickness;
        ctx.strokeStyle = this.winner ? "#FF0000" : this.color;
        ctx.stroke();
    }

    canGC() {
        return this.radius() > this.maxRadius;
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
        this.y = Math.max(0+playerRadius, this.y);
        this.y = Math.min(height-playerRadius, this.y);

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
        this.x = Math.max(0+playerRadius, this.x);
        this.x = Math.min(width-playerRadius, this.x);

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

    draw() {
        let y = this.y - (this.z * 40);
        let radius = playerRadius * (this.z+1)

        // draw main
        ctx.beginPath();
        ctx.arc(this.x, y, radius, 0, Math.PI * 2, false);
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
            ctx.arc(this.x, this.y, radius, 0, Math.PI * 2, false);
            ctx.closePath();
            ctx.lineWidth = 0;
            ctx.fillStyle = this.color+"33";
            ctx.fill();
        }
    }
}

let player;
let gameState;
let numJumps;

function resetGame() {
    currTick = 0;
    drops = [];
    player = new Player(width/2, height/2, palette[0]);
    gameState = 'play';
    numJumps = 0;
    canvas.focus();
}
resetGame();

let requestAnimationFrame =
    window.requestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.msRequestAnimationFrame;

function doTick() {
    if (keyboard['KeyR']) {
        resetGame();
    }

    if (gameState == 'play') {
        let playerPrevZ = player.z;
        player.act();
        if (playerPrevZ > 0 && player.z == 0) {
            let bounces = Math.floor((player.lastJumpHeight*1.8)+1);
            console.log("spawning drop with bounces:", bounces);
            new Drop(player.x, player.y, bounces);
        } else if (playerPrevZ == 0 && player.z > 0) {
            numJumps++;
        }
        score.innerHTML = numJumps;

        if (player.z == 0) {
            for (let i in drops) {
                let drop = drops[i];
                let dropRadius = drop.radius();
                if (dropRadius < playerRadius * 1.5) continue;
                let hs = Math.pow(drop.x-player.x, 2) + Math.pow(drop.y-player.y, 2);
                if (hs > Math.pow(playerRadius + dropRadius, 2)) {
                    continue;
                } else if (Math.sqrt(hs) <= Math.abs(dropRadius-playerRadius)) {
                    continue;
                } else {
                    console.log("game over");
                    drop.winner = true;
                    player.loser = true;
                    gameState = 'gameOver';
                }
            }
        }
    }

    drops = drops.filter(drop => !drop.canGC());

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drops.forEach(drop => drop.draw());
    player.draw()

    if (gameState == 'play') currTick++;
    requestAnimationFrame(doTick);
}
requestAnimationFrame(doTick);

</script>

<p><em>Do you have the patience to wait<br />
till your mud settles and the water is clear?</em></p>

<h2 id="backstory">Backstory</h2>

<p>This is a game I originally implemented in lua, which you can find <a href="https://github.com/mediocregopher/ripple">here</a>.
It’s a fun concept that I wanted to show off again, as well as to see if I could
whip it up in an evening in javascript (I can!)</p>

<p>Send me your high scores! I top out around 17.</p>
