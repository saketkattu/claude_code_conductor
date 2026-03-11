#!/bin/bash
# gemini_json_wrapper.sh
# Usage: gemini_json_wrapper.sh "Your prompt" "optional_file_path"

PROMPT="$1"
FILE_PATH="$2"
MAX_RETRIES=2
ATTEMPT=1

# Core instruction to force JSON
SYS_MSG="You are a strict data processor. Return ONLY raw, valid JSON. Do not include markdown formatting, backticks, or any conversational text."

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    # 1. Call Gemini CLI (with or without file context)
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        RAW_OUTPUT=$(cat "$FILE_PATH" | gemini -p "$SYS_MSG $PROMPT")
    else
        RAW_OUTPUT=$(gemini -p "$SYS_MSG $PROMPT")
    fi

    # 2. Strip potential markdown code blocks (e.g., ```json ... ```)
    # Removes the first and last line if they contain markdown backticks
    CLEAN_OUTPUT=$(echo "$RAW_OUTPUT" | sed '/^```/d')

    # 3. Validate with jq
    # The -e flag checks if the output is valid JSON and sets the exit status
    if echo "$CLEAN_OUTPUT" | jq -e '.' >/dev/null 2>&1; then
        # Success: Output compact JSON and exit cleanly
        echo "$CLEAN_OUTPUT" | jq -c '.'
        exit 0
    else
        # Failure: Increment attempt and modify prompt to scold the model
        ATTEMPT=$((ATTEMPT + 1))
        SYS_MSG="CRITICAL ERROR: Your previous response was not valid JSON. You MUST return ONLY raw, parseable JSON without any markdown or text wrappers."
    fi
done

# 4. Fallback Error Output
# If all retries fail, return a JSON-formatted error so Claude Code can read it without crashing
echo "{\"error\": \"Gemini failed to return valid JSON after $MAX_RETRIES attempts.\", \"raw_output\": $(echo "$RAW_OUTPUT" | jq -R -s '.')}"
exit 1
