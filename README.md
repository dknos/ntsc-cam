# ntsc-cam

A real NTSC encode→decode pipeline in a single HTML page. Not a filter stack — it generates a composite signal from your video source and demodulates it back to RGB, so the artifacts (dot crawl, chroma bleed, ringing, hue drift, head-switching) come from the physics, not from luma-curve hacks.

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

| Param     | Values                                            | Default     |
| --------- | ------------------------------------------------- | ----------- |
| `src`     | `phonelink`, `cam`, `display`, `file`, `url`, `none` | `cam`       |
| `cam`     | partial label match of a `MediaDeviceInfo`        | —           |
| `size`    | `WxH` (e.g. `1080x1920`, `1920x1080`)             | `1920x1080` |
| `preset`  | `vhs`, `cable`, `dirty`, `clean`, `off`           | `vhs`       |
| `video`   | URL to an mp4/webm                                | —           |
| `hud`     | `on`, `off`                                       | `on`        |

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

Noise, chroma gain, dot crawl, ringing, jitter, hue drift, head-switching, saturation, luma bias, filter taps, generation loss (1–4 re-record passes). Composite / S-Video / RGB decode modes. All live.

## How it works

Three WebGL2 fragment shader passes:

1. **Encode** — RGB → YIQ, chroma low-pass, subcarrier modulation at 3.58 MHz.
2. **Distort** — noise, head-switching glitches, ringing in the signal domain.
3. **Decode** — 7-tap weighted luma average, subcarrier-locked I/Q demod back to RGB.

Ping-pong framebuffers feed the generation loop when `gen > 1`, so you can stack VHS degradation like a dub-of-a-dub.

## License

MIT.
