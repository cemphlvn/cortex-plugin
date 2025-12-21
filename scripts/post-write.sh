#!/bin/bash
TARGET="$1"
[[ -f "$TARGET" ]] && DIR="$(dirname "$TARGET")" || DIR="$TARGET"
STATE="$DIR/state.jsonl"
[[ -f "$STATE" ]] && echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"modified\",\"actor\":\"claude\",\"data\":{\"file\":\"$TARGET\"}}" >> "$STATE"
