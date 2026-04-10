---
name: audio
description: |
  Voice message handling — speech-to-text transcription and text-to-speech replies.
  Triggers: voice message, audio file, "transcribe", "speak", "voorlezen", "luister".
user-invocable: true
---

# Audio Skill

## Role Activation

When this skill loads (voice message received or audio requested):

1. If incoming audio → transcribe with stt.py, then process the text
2. If reply should be audio → generate with tts.py, send the file

## Credentials & Auth

No credentials needed. STT and TTS run locally — no external API calls, no costs.

## HTTP Method

Not applicable — this skill uses local Python scripts, not HTTP APIs.

## Commands

### Speech-to-Text (incoming voice messages)

```bash
python3 /opt/ai-tools/bin/stt.py <audio_file> --language nl --model base
```

- Runs locally via faster-whisper (no external API)
- VAD filter enabled (skips silence automatically)
- Default language: Dutch (`nl`). Change `--language` for other languages.
- Available models: `tiny`, `base`, `small`, `medium`, `large` (base = best speed/quality balance)
- Output: plain text to stdout, errors to stderr

### Text-to-Speech (audio replies)

```bash
python3 /opt/ai-tools/bin/tts.py "Je tekst hier" /tmp/reply.mp3
```

Custom voice:
```bash
python3 /opt/ai-tools/bin/tts.py --voice nl-NL-MaartenNeural "Hallo" /tmp/reply.mp3
```

List all voices for a language:
```bash
python3 /opt/ai-tools/bin/tts.py --list-voices nl
```

## Inline Knowledge (needed every call)

### Voice Options

| Shorthand | Voice | Use for |
|-----------|-------|---------|
| _(default)_ | `nl-NL-ColetteNeural` | Dutch (female, warm) |
| nl-male | `nl-NL-MaartenNeural` | Dutch (male) |
| en-female | `en-US-JennyNeural` | English (female) |
| en-male | `en-US-GuyNeural` | English (male) |

### Language Matching

Match the user's language for TTS output:
- User speaks Dutch → `--language nl` for STT, Dutch voice for TTS
- User speaks English → `--language en` for STT, English voice for TTS

## Error Handling

| Error | Meaning | Action |
|-------|---------|--------|
| `FileNotFoundError` | Audio file path invalid | Check the file was downloaded/saved correctly |
| `RuntimeError: model` | Whisper model not cached | Use `base` model (pre-downloaded in container) |
| `edge_tts` timeout | Microsoft TTS service unreachable | Retry once, then reply with text only |
| Empty transcription | Audio was silence or too short | Tell user the audio couldn't be transcribed |

## Common Tasks

| Task | Command |
|------|---------|
| Transcribe voice message | `python3 /opt/ai-tools/bin/stt.py <file> --language nl` |
| Reply with Dutch audio | `python3 /opt/ai-tools/bin/tts.py "tekst" /tmp/reply.mp3` |
| Reply with English audio | `python3 /opt/ai-tools/bin/tts.py --voice en-US-JennyNeural "text" /tmp/reply.mp3` |
| List Dutch voices | `python3 /opt/ai-tools/bin/tts.py --list-voices nl` |

## Safety Rules

1. **Always transcribe voice messages locally** — never send audio to external APIs
2. **Always use edge-tts for audio replies** — no browser-based TTS, no external TTS providers
3. **Audio in → audio out** — voice messages get voice replies, text messages get text replies
4. **Output to /tmp/** — audio files are temporary, don't store permanently
5. **Match the user's language** — if they speak English, reply in English voice
