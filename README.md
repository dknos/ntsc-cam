# ntsc-cam

**Live: https://dknos.github.io/ntsc-cam/**

A signal-accurate NTSC encode→decode pipeline in a single HTML page. Not a filter stack — it generates an honest composite signal from your video source using real NTSC-M timing (f_sc = 315/88 MHz = 3.579545 MHz, 227.5 cycles/line, 52.656 µs active, 4-field cycle, 33° I-axis rotation) and demodulates it back to RGB, so dot crawl, chroma bleed, ringing, hue drift, differential phase/gain, cross-color and head-switching emerge from the physics rather than luma-curve hacks.

Point it at your webcam, phone camera (via Phone Link / DroidCam / Camo), a display capture, a file, or a URL. Use it as an **OBS Browser Source** for vertical 1080×1920 shorts, or run it fullscreen.

## Quick start (Windows)

Double-click `start.bat`. It serves the page on `http://localhost:9395/ntsc.html` and opens the browser at the VHS preset, phone-link source, 1080×1920 vertical.

Requires Python 3 (Microsoft Store → "Python" → install).

## Quick start (Linux/WSL/Mac)

```
./serve.sh
```

Then open `http://localhost:9395/ntsc.html`.

## URL parameters

| Param      | Values                                                         | Default     |
| ---------- | -------------------------------------------------------------- | ----------- |
| `src`      | `phonelink`, `cam`, `display`, `file`, `url`, `none`           | `cam`       |
| `cam`      | partial label match of a `MediaDeviceInfo`                     | —           |
| `size`     | `WxH` (e.g. `1080x1920`, `1920x1080`, `match`)                 | `1920x1080` |
| `preset`   | `vhs`, `broadcast`, `cable`, `dirty`, `clean`, `off`           | `vhs`       |
| `mode`     | `composite`, `svideo`, `rgb`                                   | `composite` |
| `decoder`  | `0` notch, `1` 2-line comb, `2` 3-line comb                    | `1`         |
| `video`    | URL to an mp4/webm                                             | —           |
| `hud`      | `on`, `off`                                                    | `on`        |

Example:
```
http://localhost:9395/ntsc.html?src=phonelink&size=1080x1920&preset=vhs&hud=off
```

## OBS setup

1. Start the server (`start.bat`).
2. In OBS, add a **Browser Source**.
3. URL: `http://localhost:9395/ntsc.html?src=phonelink&size=1080x1920&preset=vhs&hud=off`
4. Width 1080, Height 1920, FPS 30 or 60.
5. Set the scene canvas to 1080×1920 for vertical Shorts.

## Knobs

### Signal path
- **Signal mode** — Composite (full artifacts), S-Video (Y+C split, no dot crawl), or RGB (bypass everything).
- **Decoder** — Notch filter (cheap, classic dot crawl), 2-line comb (exploits 227.5 cyc/line phase inversion, clean luma), or 3-line comb (softer, best cross-color rejection).
- **Color-under** — Heterodyne chroma to ~629 kHz VHS-style recording carrier before the channel. Narrow-band, hue-shifted, beat artifacts.
- **Interlace** — Alternate field phase each frame (odd/even field offset).

### Encoder bandwidth (IRE-domain Gaussian LPF)
- **Y bandwidth** 1.5–6.0 MHz (broadcast is 4.2).
- **I bandwidth** 0.3–3.0 MHz (broadcast is 1.3, wider-axis chroma).
- **Q bandwidth** 0.1–2.0 MHz (broadcast is 0.4, narrow-axis chroma).
- **Filter quality** tap count multiplier (σ×quality half-width).

### Channel impairments
- **Noise** additive Gaussian on composite (Box-Muller).
- **Ringing** causal IIR overshoot (simulates VSB).
- **Scan jitter** per-line horizontal offset.
- **Diff phase (°)** and **Diff gain** — chroma phase/amplitude modulated by luma level. Hallmark of cheap NTSC gear.
- **Hue drift (°)** global rotation of I-axis.
- **Tape skew**, **head switch (px)**, **dropout rate** — VHS transport artifacts.
- **Generation** 1–4 re-record passes for dub-of-a-dub degradation.

### Color / brightness
- **Saturation** chroma gain before encode.
- **Brightness** luma gain on decoded RGB.

### CRT post
- **Mask type** — none, aperture grille, shadow mask, slot mask.
- **Scanline** sin² modulation at line pitch.
- **Mask strength / pitch** phosphor triad strength and spacing.
- **Bloom** horizontal halation (bright-scanline blooming).
- **Glow** upward phosphor glow (electron beam rise).
- **Vignette** radial darkening.
- **Barrel** geometric lens distortion.

## How it works

Four WebGL2 fragment shader passes, RGBA16F framebuffer when `EXT_color_buffer_half_float` is available so composite signal preserves sub-black and super-white headroom (falls back to RGBA8 via (signal + 0.6) / 2.2 normalization):

1. **Encode** — Gamma-precorrected RGB → Y′IQ (NTSC coefficients), Gaussian LPF on I/Q at independent bandwidths, 33° NTSC I-axis rotation, optional differential phase/gain coupling to Y, subcarrier modulation at true `f_sc/f_s` cycles-per-pixel plus `227.5 × lineIdx` (yields natural 180° line-to-line chroma inversion) plus 4-field (π/2) rotation. Packs composite in R, raw Y/I/Q in G/B/A for S-Video bypass.
2. **Distort** — Gaussian composite noise (Box-Muller), causal VSB overshoot, tape skew, line dropouts, head-switch tear at bottom N pixels with chroma-lock collapse.
3. **Decode** — Luma via notch / 2-line comb / 3-line comb; synchronous chroma demod against burst-locked subcarrier reference with Gaussian LPF at I (1.3 MHz) and Q (0.4 MHz); un-rotate 33° back to YIQ → RGB.
4. **CRT** — Barrel warp, horizontal bloom, upward glow, scanline sin², phosphor triad masks (aperture/shadow/slot), radial vignette.

Ping-pong framebuffers feed the generation loop when `gen > 1`, so you can stack VHS degradation like a dub-of-a-dub.

Derived parameters: horizontal sample rate `f_s = canvasW / 52.656 µs`, subcarrier cycles per pixel `f_sc / f_s`, bandwidth → σ via `σ_px = 0.187 · f_s / bw_MHz` (Gaussian ~−3 dB at requested cutoff).

## Presets

- **VHS** — heavy color-under, narrow Q, severe noise, head switch, gen=2, heavy CRT.
- **Broadcast** — 4.2/1.3/0.4 MHz, minimal impairment, 2-line comb, subtle CRT.
- **Cable** — clean, flat, modern mask, 2-line comb.
- **Dirty tape** — nth-generation dub, heavy noise/jitter/dropouts, gen=3.
- **Clean NTSC** — S-Video direct feed to a studio monitor, minimal CRT.
- **Bypass** — RGB mode, CRT off.

## License

MIT.
