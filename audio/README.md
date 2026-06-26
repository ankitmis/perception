# ASR Pipeline Visualizer + Model Comparison

Explore the speech-recognition pipeline (waveform → frames → windows → FFT → mel-spectrogram → tokens) and compare ASR models on **latency** and **WER** (substitution / insertion / deletion) against a ground-truth reference.

**Fully self-contained and offline — no API keys, no HuggingFace downloads.** Clone the repo (with Git LFS) and everything runs from bundled model weights, including on a locked-down machine that blocks model downloads.

- **`index.html`** — single-file web app. Record/upload audio, watch the full pipeline, and transcribe with HuggingFace models running **locally in the browser** (transformers.js). Includes a per-chunk listen-and-inspect panel.
- **`asr_pipeline_comparison.ipynb`** — the same pipeline + comparison in Python, with the models running **locally** via `transformers`.

## Bundled models — two formats, two folders

The notebook (PyTorch) and the browser (ONNX) need **different weight formats**, so the weights are bundled twice:

| folder | format | used by | size |
|---|---|---|---|
| **`models/`** | PyTorch (`*.safetensors`) | the notebook (`transformers`) | ~2.8 GB |
| **`web-models/`** | ONNX, q8-quantized | the web app (`transformers.js`) | ~0.5 GB |

**`models/`** (notebook): whisper-tiny.en / base / small (OpenAI) · distil-small.en (HuggingFace) · moonshine-base (Useful Sensors) · wav2vec2-base-960h (Meta).

**`web-models/`** (browser): moonshine-tiny / base (Useful Sensors) · whisper-tiny.en / base.en (OpenAI) · distil-small.en (HuggingFace) · wav2vec2-base-960h (Meta).

Everything in both folders is tracked with **Git LFS** (the weight files exceed GitHub's 100 MB per-file limit).

## One-time: enable Git LFS before your first commit

```bash
git lfs install           # so the model weights are stored as LFS, not rejected by GitHub
```
The `.gitattributes` already routes `models/**`, `web-models/**/*.onnx`, `*.safetensors`, and `*.wav` through LFS.

## Run the web app

**Don't open `index.html` directly (`file://`)** — the browser blocks local `fetch()` (model + WASM loading) and the microphone there. Serve it over `http://localhost` instead (still fully offline — this is a local file server, not the internet):

- **macOS:** double-click **`start.command`**
- **Linux/other:** run **`./start.sh`** (or `python3 -m http.server 8777`)
- then open **http://localhost:8777**

**Fully air-gapped — zero network.** The transformers.js library and its ONNX-Runtime WASM are vendored in `vendor/transformers/`, and model weights load from `web-models/`. Nothing is fetched from any CDN or from HuggingFace.

## Run the notebook

```bash
# clone with the weights
git lfs install && git clone <your-repo-url> && cd asr-pipeline-visualizer && git lfs pull

# create the environment (Python 3.10+; 3.12/3.13 tested)
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# launch
.venv/bin/jupyter lab asr_pipeline_comparison.ipynb
```
Set `AUDIO_PATH` and `GROUND_TRUTH` in the config cell. All models run locally from `models/` — no keys, no network. Verified to run with `HF_HUB_OFFLINE=1`.

## Optional — NVIDIA NeMo

NVIDIA's ASR (Parakeet / Canary) uses the **NeMo** toolkit, not `transformers`. The notebook has an optional *"NVIDIA NeMo models"* cell (`pip install "nemo_toolkit[asr]"`); those weights download from NVIDIA/HF on first use, so that cell is **not** offline.

## Notes

- `.venv/` and the `asr/` venv are git-ignored — recreate from `requirements.txt`.
- **Why no Google/xAI local models?** Google's ASR is API-only; xAI has no open ASR model. Both are out of scope for an offline, weights-bundled app.
- **Air-gapping:** the web app is fully self-contained — `vendor/transformers/` holds the transformers.js library bundled into one self-contained ESM (`transformers.bundle.mjs`) plus the ONNX-Runtime WASM (`ort-wasm-simd-threaded.jsep.{wasm,mjs}`), pinned to transformers.js 3.8.1. The page sets `env.allowRemoteModels=false`, `env.backends.onnx.wasm.wasmPaths='vendor/transformers/'`, and `numThreads=1`, so it never contacts a CDN or HuggingFace. The bundle was produced with esbuild (the raw `dist/transformers.web.min.js` can't be used directly in a browser — it has bare `import "onnxruntime-web"` specifiers). To rebuild/upgrade: `npm i --ignore-scripts @huggingface/transformers@<ver>` then `npx esbuild <(echo 'export {pipeline,env} from "@huggingface/transformers"') --bundle --format=esm --platform=browser --outfile=transformers.bundle.mjs`, and copy the matching `ort-wasm-*.{wasm,mjs}` from that version's `dist/`.
