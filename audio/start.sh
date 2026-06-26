#!/bin/bash
cd "$(dirname "$0")"
echo "Serving ASR app at http://localhost:8777  (Ctrl+C to stop)"
python3 -m http.server 8777
