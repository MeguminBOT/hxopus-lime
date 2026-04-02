# hxopus-lime

This haxelib is work in progress and may undergo drastic changes, not ready for production usage.

## Platform support

| Target | Backend              | Stream (file) | Stream (bytes) | Decode (file) | Decode (bytes) |
| ------ | -------------------- | :-----------: | :------------: | :-----------: | :------------: |
| CPP    | libopusfile + OpenAL |      Yes      |      Yes       |      Yes      |      Yes       |

## Installation

```bash
haxelib git hxopus-lime https://github.com/MeguminBOT/hxopus-lime.git
```

Add to your `project.xml`:

```xml
<haxelib name="hxopus-lime"/>
```

## Submodule setup

```bash
git submodule add https://github.com/xiph/opus project/lib/opus
git submodule add https://github.com/xiph/opusfile project/lib/opusfile
git submodule add https://github.com/gcp/libogg project/lib/ogg
git submodule update --init --recursive
```

## Chunk size tuning

The default `CHUNK_BYTES = 4096` in `OpusAudioSource` gives ~21ms of audio
per buffer at 48kHz stereo. Increase to `8192` if you hear dropouts.
