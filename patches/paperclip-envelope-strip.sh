#!/usr/bin/env bash
# Strips the `paperclip` envelope key from gateway RPC params before
# AJV validation in the OpenClaw gateway bundles.
#
# Why this patch exists
# ---------------------
# The OpenClaw gateway validates `agent` and `chat.send` RPC params with
# AJV-generated validators that have `additionalProperties: false`.
# The Paperclip cloud adapter wraps each RPC payload with a top-level
# `paperclip` envelope (runId, agentId, companyId, etc.). AJV rejects
# the envelope and the run fails with:
#
#   invalid agent params: at root: unexpected property 'paperclip'
#
# The clean fix lives upstream (in openclaw/openclaw — relax
# `additionalProperties` or whitelist `paperclip` in the agent and
# chat.send schemas). Until that ships, this build-time patch deletes
# the envelope key just before each validator is called, so the
# validators see only the params they expect.
#
# Idempotent and bundle-hash-agnostic: the OpenClaw npm release ships
# the validators inside content-hashed bundles like `gateway-cli-*.js`,
# so we scan every `*.js` in `/app/dist` and patch wherever the call
# site appears.

set -uo pipefail

DIST_DIR="${OPENCLAW_DIST_DIR:-/app/dist}"

if [ ! -d "$DIST_DIR" ]; then
  echo "[paperclip-envelope-strip] dist dir not found: $DIST_DIR" >&2
  exit 1
fi

shopt -s nullglob
patched=0
skipped=0
untouched=0

for f in "$DIST_DIR"/*.js; do
  has_agent=0
  has_chat=0
  grep -qF 'validateAgentParams(p)' "$f" && has_agent=1
  grep -qF 'validateChatSendParams(params)' "$f" && has_chat=1

  if [ "$has_agent" = 0 ] && [ "$has_chat" = 0 ]; then
    untouched=$((untouched + 1))
    continue
  fi

  needs_agent=0
  needs_chat=0
  if [ "$has_agent" = 1 ] && ! grep -qF 'delete p.paperclip' "$f"; then needs_agent=1; fi
  if [ "$has_chat" = 1 ] && ! grep -qF 'delete params.paperclip' "$f"; then needs_chat=1; fi

  if [ "$needs_agent" = 0 ] && [ "$needs_chat" = 0 ]; then
    echo "[paperclip-envelope-strip] $(basename "$f"): already patched"
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$needs_agent" = 1 ]; then
    perl -i -pe 's{^(\s*)(if \(!validateAgentParams\(p\)\))}{${1}if (p && typeof p === "object") { delete p.paperclip; }\n${1}${2}}' "$f"
  fi
  if [ "$needs_chat" = 1 ]; then
    perl -i -pe 's{^(\s*)(if \(!validateChatSendParams\(params\)\))}{${1}if (params && typeof params === "object") { delete params.paperclip; }\n${1}${2}}' "$f"
  fi

  ok=1
  if [ "$has_agent" = 1 ] && ! grep -qF 'delete p.paperclip' "$f"; then ok=0; fi
  if [ "$has_chat" = 1 ] && ! grep -qF 'delete params.paperclip' "$f"; then ok=0; fi
  if [ "$ok" = 0 ]; then
    echo "[paperclip-envelope-strip] $(basename "$f"): patch verification failed" >&2
    exit 2
  fi

  echo "[paperclip-envelope-strip] $(basename "$f"): patched"
  patched=$((patched + 1))
done

echo "[paperclip-envelope-strip] done. patched=$patched already_patched=$skipped scanned_other=$untouched"

if [ "$patched" = 0 ] && [ "$skipped" = 0 ]; then
  echo "[paperclip-envelope-strip] WARNING: no validators matched in $DIST_DIR — upstream bundle layout may have changed" >&2
fi
