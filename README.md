<div align="center">

# 🤖 Claude Code Conductor 

**Run Gemini, Codex, and Qwen inside Claude Code — and get back clean JSON every time.**

Plug-and-play subagent definitions + bash wrappers that let Claude delegate tasks to any AI CLI. No stream parsing. No interactive prompts. No hallucinated formatting. Just structured data.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Subagents-blueviolet)](https://docs.anthropic.com/claude-code)
[![Works with](https://img.shields.io/badge/Works%20with-Gemini%20%7C%20Codex%20%7C%20Qwen-blue)](#workers)

</div>

---

## Why This Exists

Claude Code supports custom subagents — specialized AI workers you can delegate tasks to mid-conversation. But wiring up external AI CLIs (Gemini, Codex, Qwen) to return **reliable, parseable JSON** requires solving three annoying problems:

| Problem | What breaks | How this fixes it |
|---|---|---|
| Models wrap output in markdown fences | `jq` fails to parse | `sed` strips fences before validation |
| CLIs prompt for input/approval | Scripts hang | Non-interactive flags per CLI (`--yolo`, `--sandbox read-only`, etc.) |
| Models occasionally return prose | Silent pipeline failure | Retry loop with a stricter prompt on first failure |

Each worker is **one install away** from showing up in your `/agents` panel.

---

## Workers

| Agent | Backed By | Color | Best For |
|---|---|---|---|
| `gemini-worker` | Google Gemini | 🟢 Green | Secondary analysis, large context tasks |
| `codex-worker` | OpenAI Codex | 🟣 Purple | Code analysis, reasoning, structured extraction |
| `qwen-worker` | Alibaba Qwen | 🟠 Orange | Parallel analysis, multilingual tasks |

All three follow the same interface: **prompt in → JSON out**.

---

## Quickstart

### 1. Prerequisites

You need **Claude Code** installed, plus any CLIs you want to use:

```bash
# Google Gemini CLI
npm install -g @google/generative-ai-cli
gemini auth login

# OpenAI Codex CLI
npm install -g @openai/codex
codex auth

# Alibaba Qwen CLI
# See: https://github.com/QwenLM/qwen-cli
qwen auth

# jq (required for JSON validation)
brew install jq        # macOS
apt install jq         # Ubuntu/Debian
scoop install jq       # Windows
```

### 2. Install

```bash
git clone https://github.com/saketkattu/claude-ai-workers.git
cd claude-ai-workers
bash install.sh
```

That's it. The script copies agents to `~/.claude/agents/` and scripts to `~/.claude/scripts/` with the execute bit set.

### 3. Verify

```bash
ls ~/.claude/agents/
# gemini-worker.md  codex-worker.md  qwen-worker.md

ls ~/.claude/scripts/
# gemini_json_wrapper.sh  codex_json_wrapper.sh  qwen_json_wrapper.sh
```

Then open Claude Code and type `/agents` — all three workers should appear.

---

## Usage

### Inside Claude Code (recommended)

Just ask Claude to delegate:

```
Use codex-worker to review this function and return:
{"complexity": "low|medium|high", "issues": [...], "suggested_fix": "..."}
```

```
Use gemini-worker to compare these two API designs and return:
{"winner": "A|B", "reasons": [...], "trade_offs": {...}}
```

```
Use qwen-worker to extract all action items from this transcript and return:
{"action_items": [{"owner": "...", "task": "...", "due": "..."}]}
```

### Direct bash (for testing or scripting)

```bash
# Basic call
~/.claude/scripts/codex_json_wrapper.sh "Return {\"status\": \"ok\"}"

# With file context
~/.claude/scripts/codex_json_wrapper.sh \
  "Extract all function names as a JSON array" \
  "/path/to/your/file.py"

# Pipe into jq for field extraction
~/.claude/scripts/gemini_json_wrapper.sh "List 3 risks as JSON" \
  | jq -r '.risks[]'
```

---

## How It Works

Each wrapper script follows the same 5-step pattern:

```
Your prompt
    │
    ▼
┌─────────────────────────────────────┐
│  1. Prepend JSON-forcing system msg │
│  2. Call CLI (non-interactive mode) │
│  3. Strip markdown fences (sed)     │
│  4. Validate with jq                │
│     ├─ ✅ Valid → output compact JSON│
│     └─ ❌ Invalid → retry with      │
│            stricter prompt (once)   │
└─────────────────────────────────────┘
    │
    ▼
{"your": "clean json"}
  — or —
{"error": "...", "raw_output": "..."}
```

**CLI flags used (non-interactive guarantees):**

| CLI | Flags | What they do |
|---|---|---|
| `gemini` | `-p` | Direct prompt mode, no shell |
| `codex` | `--sandbox read-only --skip-git-repo-check --ephemeral -o <file>` | Exec mode, no approval prompts, no session state |
| `qwen` | `--output-format json --yolo` | Buffered JSON output, auto-approves all actions |

---

## Agent Definition Format

Each `.md` file in `agents/` is a Claude Code subagent definition with this shape:

```markdown
---
name: codex-worker
description: ...   ← what Claude reads to decide when to use this worker
tools: Bash, Read, Write
model: haiku       ← cheap model for the orchestration layer
color: purple
---

# Role + Execution Instructions
```

The `description` field is the most important for discoverability — Claude uses it to route tasks to the right worker automatically.

---

## Repo Structure

```
claude-ai-workers/
├── README.md
├── install.sh              ← one-command setup
├── agents/
│   ├── gemini-worker.md
│   ├── codex-worker.md
│   └── qwen-worker.md
└── scripts/
    ├── gemini_json_wrapper.sh
    ├── codex_json_wrapper.sh
    └── qwen_json_wrapper.sh
```

---

## Contributing

Want to add a worker for another CLI (Mistral, Llama, Grok...)?

1. Copy `agents/gemini-worker.md` → `agents/yourmodel-worker.md`
2. Copy `scripts/gemini_json_wrapper.sh` → `scripts/yourmodel_json_wrapper.sh`
3. Update the CLI call and extraction logic in the wrapper
4. Open a PR — include a note on how to install/auth the CLI

The only requirements: non-interactive execution and JSON output validation.

---

## License

MIT — use freely, attribution appreciated.

---

<div align="center">
Built for <a href="https://docs.anthropic.com/claude-code">Claude Code</a> · Works with Gemini · Codex · Qwen
</div>
