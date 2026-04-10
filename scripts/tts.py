#!/usr/bin/env python3
"""Text-to-Speech using edge-tts (free, no API key needed).

Usage:
    python3 tts.py "Tekst om voor te lezen" output.mp3
    python3 tts.py --voice nl-NL-ColetteNeural "Hallo!" output.mp3
    python3 tts.py --list-voices nl

Output:
    Writes MP3 audio file to the specified output path.
    Prints the output file path to stdout on success.
"""

import argparse
import asyncio
import sys
import os


# Default Dutch voices (natural-sounding)
DEFAULT_VOICE = "nl-NL-ColetteNeural"  # Female, warm
ALT_VOICES = {
    "nl-female": "nl-NL-ColetteNeural",
    "nl-male": "nl-NL-MaartenNeural",
    "en-female": "en-US-JennyNeural",
    "en-male": "en-US-GuyNeural",
    "de-female": "de-DE-KatjaNeural",
    "fr-female": "fr-FR-DeniseNeural",
    "ar-female": "ar-SA-ZariyahNeural",
    "tr-female": "tr-TR-EmelNeural",
}


async def synthesize(text: str, output_path: str, voice: str = DEFAULT_VOICE, rate: str = "+0%") -> str:
    import edge_tts

    communicate = edge_tts.Communicate(text, voice, rate=rate)
    await communicate.save(output_path)
    return output_path


async def list_voices(language_filter: str = ""):
    import edge_tts

    voices = await edge_tts.list_voices()
    for v in voices:
        locale = v["Locale"]
        if language_filter and not locale.lower().startswith(language_filter.lower()):
            continue
        print(f"{v['ShortName']:40s} {v['Gender']:8s} {locale}")


def main():
    parser = argparse.ArgumentParser(description="Text-to-Speech using edge-tts")
    parser.add_argument("text", nargs="?", help="Text to synthesize")
    parser.add_argument("output", nargs="?", help="Output MP3 file path")
    parser.add_argument("--voice", default=DEFAULT_VOICE, help=f"Voice name (default: {DEFAULT_VOICE})")
    parser.add_argument("--rate", default="+0%", help="Speech rate adjustment (e.g. +10%%, -5%%)")
    parser.add_argument("--list-voices", metavar="LANG", nargs="?", const="", help="List available voices (optionally filter by language code)")
    args = parser.parse_args()

    if args.list_voices is not None:
        asyncio.run(list_voices(args.list_voices))
        return

    if not args.text or not args.output:
        parser.error("Both text and output path are required")

    try:
        result = asyncio.run(synthesize(args.text, args.output, voice=args.voice, rate=args.rate))
        print(result)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
