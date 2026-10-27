// Synthesizes the film's sound effects (no music) into sfx.wav.
// Every cue is placed from the same timings index.html animates with.
const fs = require('fs');
const path = require('path');

const SR = 48000, DUR = 32, N = SR * DUR;
const dryL = new Float32Array(N), dryR = new Float32Array(N), send = new Float32Array(N);

// ---- helpers ------------------------------------------------------------------
function rng(seed) {
  return () => {
    seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const R = rng(42);
const noise = () => R() * 2 - 1;
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const p = (t, a, b) => clamp((t - a) / (b - a));
const eIO3 = (x) => (x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2);
const dB = (d) => Math.pow(10, d / 20);

// RBJ biquad with settable coefficients.
class Biquad {
  constructor() { this.x1 = this.x2 = this.y1 = this.y2 = 0; }
  set(type, f, q) {
    const w = 2 * Math.PI * Math.min(f, SR * 0.45) / SR, c = Math.cos(w), al = Math.sin(w) / (2 * q);
    let b0, b1, b2;
    if (type === 'lp') { b0 = (1 - c) / 2; b1 = 1 - c; b2 = b0; }
    else if (type === 'hp') { b0 = (1 + c) / 2; b1 = -(1 + c); b2 = b0; }
    else { b0 = al; b1 = 0; b2 = -al; }
    const a0 = 1 + al;
    this.b0 = b0 / a0; this.b1 = b1 / a0; this.b2 = b2 / a0; this.a1 = -2 * c / a0; this.a2 = (1 - al) / a0;
    return this;
  }
  run(x) {
    const y = this.b0 * x + this.b1 * this.x1 + this.b2 * this.x2 - this.a1 * this.y1 - this.a2 * this.y2;
    this.x2 = this.x1; this.x1 = x; this.y2 = this.y1; this.y1 = y; return y;
  }
}

// Place a mono buffer at time t0. pan -1..1 (or a function of progress), send = reverb amount.
function place(t0, buf, gain, pan = 0, sendAmt = 0.25) {
  const s0 = Math.round(t0 * SR);
  for (let i = 0; i < buf.length; i++) {
    const j = s0 + i; if (j < 0 || j >= N) continue;
    const pp = typeof pan === 'function' ? pan(i / buf.length) : pan;
    const a = (pp + 1) * Math.PI / 4;
    const v = buf[i] * gain;
    dryL[j] += v * Math.cos(a); dryR[j] += v * Math.sin(a); send[j] += v * sendAmt;
  }
}

// ---- generators ---------------------------------------------------------------
// Filtered-noise sweep with a swell: transitions.
function whoosh(dur, f0, f1, peak = 0.6, q = 1.1) {
  const n = Math.round(dur * SR), out = new Float32Array(n);
  const bp = new Biquad(), lp = new Biquad().set('lp', 900, 0.7);
  for (let i = 0; i < n; i++) {
    const x = i / n;
    if (i % 32 === 0) bp.set('bp', f0 * Math.pow(f1 / f0, x), q);
    const env = x < peak ? Math.pow(x / peak, 2.2) : Math.pow((1 - x) / (1 - peak), 1.6);
    const w = noise();
    out[i] = (bp.run(w) * 1.6 + lp.run(w) * 0.35) * env;
  }
  return out;
}
// Soft low bloom: a deep sine that falls in pitch, with a felt thump.
function boom(dur = 2.8, f0 = 74, f1 = 38) {
  const n = Math.round(dur * SR), out = new Float32Array(n), lp = new Biquad().set('lp', 220, 0.7);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const f = f1 + (f0 - f1) * Math.exp(-t * 3.5);
    ph += 2 * Math.PI * f / SR;
    const env = Math.min(1, t / 0.012) * Math.exp(-t * 1.6);
    const thump = lp.run(noise()) * Math.exp(-t * 18) * 1.4;
    out[i] = Math.tanh((Math.sin(ph) * 0.9 + thump) * env * 1.3);
  }
  return out;
}
// A soft glow tone: harmonic partials only, swelled in rather than struck,
// lifting slightly into pitch like a lamp coming up. Nothing metallic or tolling.
function glow(f, dur = 1.2, attack = 0.02, decay = 3) {
  const n = Math.round(dur * SR), out = new Float32Array(n);
  const bp = new Biquad().set('bp', f * 2, 4);
  const parts = [[1, 1], [2, 0.16], [3, 0.04]];
  for (let i = 0; i < n; i++) {
    const t = i / SR, x = i / n;
    const lift = 1 - 0.025 * Math.exp(-t * 40);
    const env = (1 - Math.exp(-t / attack)) * Math.exp(-t * decay) * Math.min(1, (1 - x) * 12);
    let v = 0;
    for (const [m, a] of parts) v += a * Math.sin(2 * Math.PI * f * m * lift * t);
    out[i] = (v / 1.2 + bp.run(noise()) * 0.15 * Math.exp(-t * 25)) * env;
  }
  return out;
}
// Scattered high pings: glints of light.
function shimmer(dur, count, seed = 1, lo = 2600, hi = 6800) {
  const r = rng(seed), n = Math.round((dur + 0.6) * SR), out = new Float32Array(n);
  for (let k = 0; k < count; k++) {
    const st = Math.round(r() * dur * SR), f = lo + r() * (hi - lo), d = 6 + r() * 14, a = 0.25 + r() * 0.75;
    for (let i = 0; st + i < n; i++) {
      const t = i / SR, env = Math.min(1, t / 0.002) * Math.exp(-t * d);
      if (env < 1e-4) break;
      out[st + i] += a * env * Math.sin(2 * Math.PI * f * t);
    }
  }
  return out;
}
// Interface tap: a short, rounded click.
function tap(f = 1900, dur = 0.07) {
  const n = Math.round(dur * SR), out = new Float32Array(n), bp = new Biquad().set('bp', f * 1.6, 3);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    out[i] = Math.sin(2 * Math.PI * f * t * (1 - t * 2)) * Math.exp(-t * 70) * 0.8 + bp.run(noise()) * Math.exp(-t * 260) * 1.2;
  }
  return out;
}
// Wooden bead clack for the tasbih.
function bead(f = 2300) {
  const n = Math.round(0.09 * SR), out = new Float32Array(n);
  const b1 = new Biquad().set('bp', f, 7), b2 = new Biquad().set('bp', f * 0.42, 5);
  for (let i = 0; i < n; i++) {
    const t = i / SR, ex = noise() * Math.exp(-t * 900);
    out[i] = b1.run(ex) * 3.2 + b2.run(ex) * 2.2 + Math.sin(2 * Math.PI * 610 * t) * Math.exp(-t * 90) * 0.25;
  }
  return out;
}
// Tiny tick: clock and compass detents.
function tick(f = 3200, decay = 400) {
  const n = Math.round(0.03 * SR), out = new Float32Array(n), hp = new Biquad().set('hp', 1800, 0.7);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    out[i] = (hp.run(noise()) * 0.7 + Math.sin(2 * Math.PI * f * t) * 0.6) * Math.exp(-t * decay);
  }
  return out;
}
// Soft bubble pop for chips and pills.
function pop(f0 = 820, f1 = 420, dur = 0.12) {
  const n = Math.round(dur * SR), out = new Float32Array(n);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const x = i / n, t = i / SR;
    ph += 2 * Math.PI * (f1 + (f0 - f1) * Math.exp(-x * 6)) / SR;
    out[i] = Math.sin(ph) * Math.min(1, t / 0.002) * Math.exp(-t * 38);
  }
  return out;
}
// Paper turning: band-limited noise with a flutter.
function rustle(dur = 0.75, seed = 5) {
  const r = rng(seed), n = Math.round(dur * SR), out = new Float32Array(n);
  const bp = new Biquad().set('bp', 3600, 0.7), lp = new Biquad().set('lp', 1400, 0.7);
  let flut = 0, target = 0;
  for (let i = 0; i < n; i++) {
    const x = i / n;
    if (i % 480 === 0) target = 0.3 + r() * 0.7;
    flut += (target - flut) * 0.004;
    const env = Math.sin(Math.PI * Math.pow(x, 0.7)) * flut;
    const w = noise();
    out[i] = (bp.run(w) * 1.2 + lp.run(w) * 0.5) * env;
  }
  return out;
}
// Rising air: builds tension into a hit.
function riser(dur, f0, f1) {
  const n = Math.round(dur * SR), out = new Float32Array(n), bp = new Biquad();
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const x = i / n;
    if (i % 32 === 0) bp.set('bp', f0 * Math.pow(f1 / f0, x), 2.5);
    ph += 2 * Math.PI * (f0 * 0.25 * Math.pow(f1 / f0, x)) / SR;
    const env = Math.pow(x, 2.4) * (x > 0.97 ? (1 - x) / 0.03 : 1);
    out[i] = (bp.run(noise()) * 1.4 + Math.sin(ph) * 0.12) * env;
  }
  return out;
}
// Room air under everything, so the hall never falls to digital silence.
function room() {
  const lp = new Biquad().set('lp', 380, 0.6), hp = new Biquad().set('hp', 60, 0.7);
  for (let i = 0; i < N; i++) {
    const t = i / SR;
    const fadeIn = Math.min(1, t / 1.5), fadeOut = Math.min(1, (DUR - t) / 1.2);
    const v = hp.run(lp.run(noise())) * dB(-31) * fadeIn * fadeOut;
    dryL[i] += v; dryR[i] += v * 0.97;
  }
}

// ---- timing replicas from index.html -----------------------------------------------
const ANIM = {
  countdownTicks() { // scenePrayer: k = (u-1)*3 + (u-1)^2*2.4, scene starts at 9.3
    const out = []; let last = 0;
    for (let u = 1.0; u < 5.2; u += 0.0005) {
      const k = Math.floor((u - 1) * 3 + Math.pow(u - 1, 2) * 2.4);
      if (k > last) { out.push([9.3 + u, k]); last = k; }
    }
    return out;
  },
  beads() { // sceneTasbih: kk = 33 * eIO3(p(u, 0.9, 3.0)), scene starts at 21.5
    const out = []; let last = 0;
    for (let u = 0.9; u <= 3.0001; u += 0.0005) {
      const n = Math.floor(33 * eIO3(p(u, 0.9, 3.0)) + 1e-6);
      if (n > last) { out.push([21.5 + u, n]); last = n; }
    }
    return out;
  },
  compassDetents() { // sceneQibla heading, scene starts at 14.0
    const out = []; let last = null;
    for (let u = 0.4; u < 3.4; u += 0.0005) {
      const sw = p(u, 0.4, 3.4);
      const h = 118 + 150 * Math.exp(-4.2 * sw) * Math.cos(sw * 2 * Math.PI * 1.25);
      const step = Math.floor(h / 6);
      if (last !== null && step !== last) out.push([14.0 + u, h]);
      last = step;
    }
    return out;
  },
};

// ---- cue sheet ----------------------------------------------------------------------
room();

// Intro: the lamp kindles, light traces the arch, the lattice wakes, the mark arrives.
place(0.12, boom(3.2, 52, 34), dB(-14), 0, 0.2);
place(0.15, glow(880, 1.8, 0.12, 2.2), dB(-29), 0, 0.25); // the lamp kindles
place(0.15, shimmer(0.7, 7, 3), dB(-31), 0, 0.6);
place(0.55, riser(1.3, 400, 3200), dB(-24), (x) => (x - 0.5) * 0.2, 0.4);
place(0.6, shimmer(1.4, 10, 4, 3000, 7500), dB(-34), (x) => Math.sin(x * 12) * 0.6, 0.6);
place(0.95, whoosh(2.0, 2200, 600, 0.35, 0.9), dB(-30), 0, 0.5); // lattice wave front
place(1.0, shimmer(1.9, 26, 5, 3500, 8000), dB(-36), (x) => Math.sin(x * 7) * 0.8, 0.7);
place(1.82, boom(3.4, 82, 36), dB(-9), 0, 0.35); // the mark lands
place(1.8, whoosh(0.9, 6000, 1200, 0.15, 0.8), dB(-24), (x) => 0.6 - x * 1.2, 0.3); // written right to left
place(1.82, glow(392, 1.8, 0.05, 2.4), dB(-25), 0, 0.2);
place(1.82, shimmer(1.2, 14, 6), dB(-30), 0, 0.7);
place(2.45, whoosh(0.5, 900, 2600, 0.5), dB(-28), 0, 0.2);
place(2.95, pop(900, 600, 0.1), dB(-34), 0, 0.2);
place(3.75, riser(1.1, 300, 2400), dB(-22), 0, 0.3);
place(3.95, whoosh(1.1, 350, 4200, 0.62, 0.8), dB(-14), 0, 0.3); // arch opens past the frame
place(4.78, boom(1.6, 60, 40), dB(-15), 0, 0.2);

// Adhkar
place(4.4, pop(760, 480), dB(-30), 0, 0.15);
place(4.5, whoosh(0.7, 1200, 3000, 0.4), dB(-30), 0, 0.15);
place(4.85, whoosh(0.7, 500, 1800, 0.5), dB(-22), 0, 0.2); // card rises
place(5.25, boom(0.8, 110, 70), dB(-24), 0, 0.1);
place(5.4, shimmer(1.4, 16, 8, 2400, 5200), dB(-29), (x) => 0.6 - x * 1.2, 0.5); // words appear, right to left
place(7.05, whoosh(0.5, 2000, 5000, 0.4, 1.4), dB(-32), (x) => -0.5 + x, 0.15); // source highlighted
[7.6, 8.05, 8.5].forEach((t, i) => place(t, tap(1700 + i * 140), dB(-17), 0.15, 0.12));
place(8.55, glow(1046.5, 0.9, 0.008, 4.5), dB(-18), 0.2, 0.2); // done: the lamp is lit
place(8.63, glow(1568, 0.8, 0.008, 5), dB(-23), 0.25, 0.2);
place(8.55, shimmer(0.9, 16, 9, 3000, 8000), dB(-28), 0.3, 0.6);

// Prayer times
place(9.2, whoosh(0.85, 280, 2600, 0.7, 0.8), dB(-15), 0, 0.25); // sheet pushes up
place(9.95, riser(1.4, 600, 2600), dB(-26), (x) => -0.6 + x * 1.0, 0.4); // sun travels the arc
[10.5, 10.65].forEach((t) => place(t, pop(1200, 800, 0.08), dB(-27), 0.3, 0.2));
for (let i = 0; i < 6; i++) place(10.15 + i * 0.07, tick(2400 - i * 120, 300), dB(-25), 0.4, 0.1); // rows slide in
ANIM.countdownTicks().forEach(([t, k]) => place(t, tick(3400, 520), dB(-18 - Math.min(7, k * 0.2)), -0.1, 0.05));
place(11.6, glow(1318.5, 0.35, 0.004, 10), dB(-22), 0.45, 0.15); // the Asr reminder
place(11.72, glow(1318.5, 0.35, 0.004, 10), dB(-24), 0.45, 0.15);

// Qibla
place(13.95, whoosh(0.8, 3500, 500, 0.3, 0.9), dB(-17), 0, 0.3); // iris opens
place(14.0, shimmer(0.6, 8, 11), dB(-32), 0, 0.5);
ANIM.compassDetents().forEach(([t]) => place(t, tick(2100, 650), dB(-17), 0, 0.05));
place(16.55, glow(880, 1.0, 0.01, 3.5), dB(-17), 0, 0.2); // locked on the qibla
place(16.55, boom(1.4, 70, 45), dB(-19), 0, 0.2);
for (let i = 0; i < 3; i++) place(16.6 + i * 1.25 / 3, whoosh(0.9, 400, 1400, 0.2, 2), dB(-30), 0, 0.5);

// Mushaf
place(17.65, rustle(0.8, 5), dB(-14), (x) => -0.7 + x * 1.4, 0.2); // the page turns in
place(17.7, whoosh(0.7, 1800, 600, 0.4), dB(-26), (x) => -0.6 + x * 1.2, 0.2);
place(19.2, shimmer(0.6, 6, 13, 2500, 4500), dB(-27), 0, 0.5); // verse lights
place(19.55, whoosh(0.75, 300, 1600, 0.55), dB(-21), 0, 0.2); // meaning sheet rises
[20.5, 20.6, 20.7, 20.8].forEach((t, i) => place(t, pop(700 + i * 90, 420 + i * 60), dB(-22), -0.4 + i * 0.25, 0.15));

// Tasbih
place(21.45, whoosh(0.8, 600, 3200, 0.55), dB(-17), 0, 0.3); // zoom through
place(22.0, shimmer(0.6, 6, 14, 2200, 4200), dB(-33), 0, 0.5);
ANIM.beads().forEach(([t, n]) => place(t, bead(2200 + (n % 2) * 140), dB(-11 - (n % 3)), (n % 2 ? 0.08 : -0.08), 0.12));
place(24.5, glow(784, 1.4, 0.015, 2.6), dB(-13), 0, 0.25); // set complete
place(24.57, glow(1174.7, 1.1, 0.015, 3.2), dB(-20), 0.1, 0.25);
place(24.5, boom(2.5, 76, 38), dB(-15), 0, 0.3);
place(24.5, shimmer(1.2, 30, 15, 2800, 8500), dB(-26), (x) => Math.sin(x * 9) * 0.7, 0.7);

// Promises, in daylight
place(24.6, whoosh(1.0, 400, 6000, 0.55, 0.7), dB(-15), 0, 0.35); // daylight floods out
[24.95, 25.27, 25.59, 25.91, 26.03].forEach((t, i) => {
  place(t - 0.05, whoosh(0.35, 700, 2400, 0.7, 1.2), dB(-27), 0, 0.1);
  place(t + 0.14, boom(0.5, 120, 80), dB(-24), 0, 0.05);
});
[0, 1, 2].forEach((i) => place(24.7 + 0.55 + i * 0.32 + 0.08, tap(2300, 0.05), dB(-27), 0.35, 0.1));
for (let i = 0; i < 8; i++) place(26.5 + i * 0.06, pop(900 + (i % 4) * 70, 560, 0.09), dB(-27), -0.6 + i * 0.17, 0.12);
place(27.4, whoosh(0.7, 2400, 500, 0.4), dB(-22), 0, 0.2);

// Outro
place(27.8, whoosh(0.95, 250, 2200, 0.55, 0.8), dB(-15), 0, 0.3); // arch rises
place(28.35, boom(3.6, 70, 34), dB(-11), 0, 0.4); // the mark, once more
place(28.38, whoosh(1.0, 6000, 1200, 0.15, 0.8), dB(-25), (x) => 0.5 - x, 0.3);
place(28.38, glow(523.25, 1.8, 0.04, 2.0), dB(-21), 0, 0.3);
place(28.4, shimmer(1.3, 16, 17), dB(-30), 0, 0.7);
place(28.75, whoosh(0.5, 900, 2600, 0.5), dB(-29), 0, 0.2);
place(29.45, pop(640, 380, 0.16), dB(-18), 0, 0.2); // the button
place(30.15, shimmer(0.8, 10, 19, 3500, 8000), dB(-31), (x) => -0.4 + x * 0.8, 0.7); // sheen

// ---- reverb (Freeverb-style), a stone hall -------------------------------------------
function reverb(input) {
  const sc = SR / 44100;
  const combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];
  const aps = [556, 441, 341, 225];
  const chan = (spread) => {
    const cb = combs.map((d) => ({ buf: new Float32Array(Math.round((d + spread) * sc)), i: 0, store: 0 }));
    const ab = aps.map((d) => ({ buf: new Float32Array(Math.round((d + spread) * sc)), i: 0 }));
    const out = new Float32Array(N);
    const fb = 0.86, damp = 0.28;
    for (let n = 0; n < N; n++) {
      const x = input[n] * 0.015;
      let y = 0;
      for (const c of cb) {
        const o = c.buf[c.i];
        c.store = o * (1 - damp) + c.store * damp;
        c.buf[c.i] = x + c.store * fb;
        c.i = (c.i + 1) % c.buf.length; y += o;
      }
      for (const a of ab) {
        const o = a.buf[a.i];
        a.buf[a.i] = y + o * 0.5;
        a.i = (a.i + 1) % a.buf.length; y = o - y;
      }
      out[n] = y;
    }
    return out;
  };
  return [chan(0), chan(23)];
}
const [wetL, wetR] = reverb(send);

// ---- master ---------------------------------------------------------------------------
const outL = new Float32Array(N), outR = new Float32Array(N);
const hpL = new Biquad().set('hp', 28, 0.7), hpR = new Biquad().set('hp', 28, 0.7);
let peak = 0;
for (let i = 0; i < N; i++) {
  outL[i] = hpL.run(dryL[i] + wetL[i] * 2.2);
  outR[i] = hpR.run(dryR[i] + wetR[i] * 2.2);
  peak = Math.max(peak, Math.abs(outL[i]), Math.abs(outR[i]));
}
// Gentle saturation, then normalise to -1 dBFS.
const drive = 1.4 / peak;
let peak2 = 0;
for (let i = 0; i < N; i++) {
  outL[i] = Math.tanh(outL[i] * drive); outR[i] = Math.tanh(outR[i] * drive);
  peak2 = Math.max(peak2, Math.abs(outL[i]), Math.abs(outR[i]));
}
const g = dB(-1) / peak2;
const pcm = Buffer.alloc(44 + N * 4);
pcm.write('RIFF', 0); pcm.writeUInt32LE(36 + N * 4, 4); pcm.write('WAVE', 8);
pcm.write('fmt ', 12); pcm.writeUInt32LE(16, 16); pcm.writeUInt16LE(1, 20); pcm.writeUInt16LE(2, 22);
pcm.writeUInt32LE(SR, 24); pcm.writeUInt32LE(SR * 4, 28); pcm.writeUInt16LE(4, 32); pcm.writeUInt16LE(16, 34);
pcm.write('data', 36); pcm.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  pcm.writeInt16LE(Math.round(clamp(outL[i] * g, -1, 1) * 32767), 44 + i * 4);
  pcm.writeInt16LE(Math.round(clamp(outR[i] * g, -1, 1) * 32767), 46 + i * 4);
}
fs.writeFileSync(path.join(__dirname, 'sfx.wav'), pcm);
console.log('sfx.wav written; cues:', ANIM.countdownTicks().length, 'clock ticks,', ANIM.beads().length, 'beads,', ANIM.compassDetents().length, 'detents');
