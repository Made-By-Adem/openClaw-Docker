#!/usr/bin/env python3
"""Speech-to-Text using faster-whisper (local, no external API needed).

Usage:
    python3 stt.py <audio_file> [--language nl] [--model base]

Output:
    Prints transcribed text to stdout.
    On error, prints error message to stderr and exits with code 1.
"""

import argparse
import sys
import os


def transcribe(audio_path: str, model_size: str = "base", language: str = "nl") -> str:
    from faster_whisper import WhisperModel

    cache_dir = os.environ.get("WHISPER_CACHE_DIR", "/home/node/.cache/whisper")
    model = WhisperModel(
        model_size,
        device="cpu",
        compute_type="int8",
        download_root=cache_dir,
    )

    segments, info = model.transcribe(
        audio_path,
        language=language,
        vad_filter=True,
        vad_parameters={"min_silence_duration_ms": 500},
    )

    text = " ".join(segment.text.strip() for segment in segments)
    return text.strip()


def main():
    parser = argparse.ArgumentParser(description="Transcribe audio using faster-whisper")
    parser.add_argument("audio_file", help="Path to audio file")
    parser.add_argument("--language", default="nl", help="Language code (default: nl)")
    parser.add_argument("--model", default="base", help="Whisper model size (default: base)")
    args = parser.parse_args()

    if not os.path.isfile(args.audio_file):
        print(f"Error: file not found: {args.audio_file}", file=sys.stderr)
        sys.exit(1)

    try:
        text = transcribe(args.audio_file, model_size=args.model, language=args.language)
        if text:
            print(text)
        else:
            print("(no speech detected)", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
