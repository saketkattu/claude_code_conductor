#!/bin/bash
# codex_json_wrapper.sh
# Usage: codex_json_wrapper.sh "Your prompt" "optional_file_path"

PROMPT="$1"
FILE_PATH="$2"
MAX_RETRIES=2
ATTEMPT=1

# Core instruction to force JSON
SYS_MSG="You are a strict data processor. Return ONLY raw, valid JSON. Do not include markdown formatting, backticks, or any conversational text."

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    # 1. Build full prompt
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        FULL_PROMPT="$SYS_MSG $PROMPT

File contents:
$(cat "$FILE_PATH")"
    else
        FULL_PROMPT="$SYS_MSG $PROMPT"
    fi

    # 2. Call Codex CLI — exec mode with safety flags
    TMPFILE=$(mktemp /tmp/codex_out_XXXXXX.txt)
    codex exec "$FULL_PROMPT" \
        --sandbox read-only \
        --skip-git-repo-check \
        --ephemeral \
        -o "$TMPFILE" 2>/dev/null
    RAW_OUTPUT=$(cat "$TMPFILE")
    rm -f "$TMPFILE"

    # 3. Strip potential markdown code blocks (e.g., ```json ... ```)
    CLEAN_OUTPUT=$(echo "$RAW_OUTPUT" | sed '/^```/d')

    # 4. Validate with jq
    if echo "$CLEAN_OUTPUT" | jq -e '.' >/dev/null 2>&1; then
        echo "$CLEAN_OUTPUT" | jq -c '.'
        exit 0
    else
        ATTEMPT=$((ATTEMPT + 1))
        SYS_MSG="CRITICAL ERROR: Your previous response was not valid JSON. You MUST return ONLY raw, parseable JSON without any markdown or text wrappers."
    fi
done

# 5. Fallback Error Output
echo "{\"error\": \"Codex failed to return valid JSON after $MAX_RETRIES attempts.\", \"raw_output\": $(echo "$RAW_OUTPUT" | jq -R -s '.')}"
exit 1
