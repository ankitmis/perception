#!/bin/bash
cd "$(dirname "$0")"
echo "Serving TTS app at http://localhost:8788  (Ctrl+C to stop)"
python3 -m http.server 8788
