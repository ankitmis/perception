#!/bin/bash
# Double-click to launch the ASR app offline (serves the folder over http://localhost, no internet).
cd "$(dirname "$0")"
PORT=8777
python3 -m http.server $PORT >/dev/null 2>&1 &
SRV=$!
sleep 1
( command -v open >/dev/null && open "http://localhost:$PORT" ) || echo "Open http://localhost:$PORT in your browser"
echo "Serving on http://localhost:$PORT  —  press Ctrl+C (or close this window) to stop."
trap "kill $SRV 2>/dev/null" EXIT
wait $SRV
