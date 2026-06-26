# TTS Pipeline Visualizer — local & offline (Kokoro-82M)

Type text and watch it become speech: **normalization → grapheme-to-phoneme → acoustic model + vocoder → mel-spectrogram → waveform**. Synthesis runs **entirely on your machine** (Kokoro-82M) — no API key, no cloud, no internet. This is the offline replacement for the ElevenLabs cloud call in the original Session 3 pipeline.

- **`index.html`** — single-file web app; runs Kokoro **in the browser** via kokoro.js / transformers.js (ONNX + WASM), with eSpeak-NG (WASM) for phonemes. Fully air-gapped: library, WASM, model and voices are all vendored.
- **`session_03_tts_pipeline_colab.ipynb`** — the same pipeline in Python, Kokoro running **locally** via `kokoro`.

## Bundled assets (two formats, like the ASR module)

| folder | format | used by | size |
|---|---|---|---|
| `models/Kokoro-82M/` | PyTorch (`.pth`) + 54 voices | notebook (`kokoro`) | ~339 MB |
| `web-models/.../Kokoro-82M-v1.0-ONNX/` | ONNX q8 + 55 voices | web app (kokoro.js) | ~116 MB |
| `vendor/kokoro/kokoro.bundle.mjs` | kokoro.js + transformers.js + eSpeak-NG, bundled | web app | 6.6 MB |
| `vendor/transformers/ort-wasm-*` | ONNX-Runtime WASM | web app | ~21 MB |

All tracked with **Git LFS**. `git lfs install` once before your first commit.

## Run the web app (offline)

**Don't open `index.html` via `file://`** — serve over `http://localhost` (still offline; just a local file server):

- macOS: double-click **`start.command`**  ·  Linux/other: **`./start.sh`**
- open **http://localhost:8788**, type text, pick a voice, click **Speak**.

First synthesis loads the bundled model (a few seconds); after that it's fast. 54 preset voices (US/UK English, plus Spanish/French/Hindi/Italian/Japanese/Portuguese/Chinese — for non-English voices, type text in that language).

## Run the notebook

```bash
git lfs install && git clone <repo> && cd <repo>/tts && git lfs pull
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/jupyter lab session_03_tts_pipeline_colab.ipynb
```
Set `VOICE` / `TEXT` in the config cell. Runs with `HF_HUB_OFFLINE=1` (verified) — no network.

## Notes
- Preset voices only (no voice *cloning*) — cloning needs large GPU models that can't run in a browser. See the analysis: Kokoro is the right offline-in-browser choice.
- The web runtime is rebuilt with esbuild: `npm i --ignore-scripts kokoro-js && npx esbuild <(echo 'export {KokoroTTS,env,phonemize} from "kokoro-js/dist/kokoro.web.js"') --bundle --format=esm --platform=browser` (plus the matching `ort-wasm-*` from transformers' dist).
- **Important patches for offline** (re-apply to `vendor/kokoro/kokoro.bundle.mjs` after any rebuild — kokoro-js's exported `env` only exposes a `wasmPaths` setter, so these can't be set from the page):
  1. **Voices** — kokoro-js fetches voices from a *hardcoded* `https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/voices/${name}.bin` URL. Replaced with `new URL('web-models/onnx-community/Kokoro-82M-v1.0-ONNX/voices/${name}.bin', location.href).href`.
  2. **Model** — the internal transformers env defaults to remote HF (`allowRemoteModels: true`, `allowLocalModels: !(s||i)`, `localModelPath: "/models/"`). Patched to `allowRemoteModels: false`, `allowLocalModels: true`, and `localModelPath: new URL("web-models/", location.href).href`.
  3. **WASM** — ONNX-Runtime's wasm dir defaults to a jsDelivr CDN, and the threaded-worker fallback resolves it against the bundle's own dir (`vendor/kokoro/`). Both patched to the vendored `vendor/transformers/` (`new URL("vendor/transformers/", location.href).href` and `"../transformers/ort-wasm-simd-threaded.jsep.wasm"`).
