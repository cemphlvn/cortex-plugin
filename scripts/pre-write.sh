#!/bin/bash
TARGET="$1"
[[ -f "$TARGET" ]] && TARGET="$(dirname "$TARGET")"
if [[ -f "$TARGET/context.md" ]]; then
    CTX=$(head -3 "$TARGET/context.md" | tr '\n' ' ' | sed 's/"/\\"/g')
    echo "{\"systemMessage\":\"Writing to: $CTX\"}"
else
    echo '{"hookSpecificOutput":{"permissionDecision":"allow"}}'
fi
