#!/bin/bash
# qwen_json_wrapper.sh
# Usage: qwen_json_wrapper.sh "Your prompt" "optional_file_path"

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

    # 2. Call Qwen CLI — buffered JSON output, fully non-interactive
    TMPFILE=$(mktemp /tmp/qwen_out_XXXXXX.json)
    qwen "$FULL_PROMPT" --output-format json --yolo > "$TMPFILE" 2>/dev/null
    RAW_JSON=$(cat "$TMPFILE")
    rm -f "$TMPFILE"

    # 3. Extract final assistant text
    # Primary: last element's .result field (type:result is always last)
    RAW_OUTPUT=$(echo "$RAW_JSON" | jq -r '.[-1].result // empty' 2>/dev/null)

    # Fallback: last assistant message content text
    if [ -z "$RAW_OUTPUT" ]; then
        RAW_OUTPUT=$(echo "$RAW_JSON" | jq -r '[.[] | select(.type=="assistant")] | last | .message.content[-1].text // empty' 2>/dev/null)
    fi

    # 4. Strip potential markdown code blocks (e.g., ```json ... ```)
    CLEAN_OUTPUT=$(echo "$RAW_OUTPUT" | sed '/^```/d')

    # 5. Validate with jq
    if echo "$CLEAN_OUTPUT" | jq -e '.' >/dev/null 2>&1; then
        echo "$CLEAN_OUTPUT" | jq -c '.'
        exit 0
    else
        ATTEMPT=$((ATTEMPT + 1))
        SYS_MSG="CRITICAL ERROR: Your previous response was not valid JSON. You MUST return ONLY raw, parseable JSON without any markdown or text wrappers."
    fi
done

# 6. Fallback Error Output
echo "{\"error\": \"Qwen failed to return valid JSON after $MAX_RETRIES attempts.\", \"raw_output\": $(echo "$RAW_OUTPUT" | jq -R -s '.')}"
exit 1
