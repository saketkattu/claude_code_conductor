# claude-ai-workers

A collection of Claude Code subagent definitions + bash wrapper scripts for delegating tasks to external AI CLIs. Each worker returns **strictly formatted JSON** for reliable parsing in agentic pipelines.

## Workers

| Agent | CLI | Use Case |
|---|---|---|
| `gemini-worker` | `gemini` (Google) | Secondary analysis, structured extraction |
| `codex-worker` | `codex` (OpenAI) | Code analysis, reasoning, structured extraction |
| `qwen-worker` | `qwen` (Alibaba) | Secondary analysis, structured extraction |

## Prerequisites

Install and authenticate the CLIs you want to use:

```bash
# Google Gemini
npm install -g @google/generative-ai-cli   # or your distro's package
gemini auth login

# OpenAI Codex
npm install -g @openai/codex
codex auth

# Alibaba Qwen
# Follow: https://github.com/QwenLM/qwen-cli
qwen auth
```

`jq` must also be installed: `brew install jq` / `apt install jq` / `scoop install jq`

## Install

```bash
git clone https://github.com/saketkattu/claude-ai-workers.git
cd claude-ai-workers
bash install.sh
```

This copies:
- `agents/*.md` → `~/.claude/agents/`
- `scripts/*.sh` → `~/.claude/scripts/` (with execute bit)

## Usage

### In Claude Code
Workers appear automatically in `/agents`. Invoke them by name:

```
Use codex-worker to analyze this function and return {"complexity": "...", "issues": [...]}
```

### Direct CLI testing
```bash
~/.claude/scripts/gemini_json_wrapper.sh "Return JSON: {\"hello\": \"world\"}"
~/.claude/scripts/codex_json_wrapper.sh "Return JSON: {\"hello\": \"world\"}"
~/.claude/scripts/qwen_json_wrapper.sh "Return JSON: {\"hello\": \"world\"}"
```

### With file context
```bash
~/.claude/scripts/codex_json_wrapper.sh "Extract all function names as a JSON array" "/path/to/file.py"
```

## How It Works

Each wrapper:
1. Prepends a system message forcing raw JSON output
2. Calls the CLI with non-interactive flags
3. Strips markdown fences (`sed '/^```/d'`)
4. Validates output with `jq`
5. Retries once with a stricter prompt on failure
6. Returns `{"error": "...", "raw_output": "..."}` if both attempts fail

## Repo Structure

```
claude-ai-workers/
├── README.md
├── install.sh
├── agents/
│   ├── gemini-worker.md
│   ├── codex-worker.md
│   └── qwen-worker.md
└── scripts/
    ├── gemini_json_wrapper.sh
    ├── codex_json_wrapper.sh
    └── qwen_json_wrapper.sh
```

## License

MIT
