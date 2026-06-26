#!/bin/bash
# Double-click to launch the TTS app offline (serves over http://localhost — not the internet).
cd "$(dirname "$0")"; PORT=8788
python3 -m http.server $PORT >/dev/null 2>&1 & SRV=$!
sleep 1; ( command -v open >/dev/null && open "http://localhost:$PORT" ) || echo "Open http://localhost:$PORT"
echo "Serving on http://localhost:$PORT — Ctrl+C / close window to stop."
trap "kill $SRV 2>/dev/null" EXIT; wait $SRV
