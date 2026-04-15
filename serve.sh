#!/usr/bin/env bash
# Linux/WSL helper to serve ntsc.html for testing before shipping to Windows.
PORT="${PORT:-9395}"
cd "$(dirname "$0")"
echo "NTSC Cam at http://localhost:${PORT}/ntsc.html"
exec python3 -m http.server "$PORT"
