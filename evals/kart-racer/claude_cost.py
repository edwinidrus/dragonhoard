#!/usr/bin/env python3
"""Claude usage of the orchestrating session, deduplicated by API message id.

    python3 claude_cost.py <transcript.jsonl> [--since <ISO timestamp>]

Prints calls, token totals and a list-price estimate (Opus 5.5: $5/M input, $25/M output,
cache read 10 %, 1 h cache write 2x). The prices are an assumption, used only to compare phases.
"""

import json
import sys

PRICE = {"input_tokens": 5e-6, "cache_read_input_tokens": 0.5e-6, "cache_creation_input_tokens": 10e-6, "output_tokens": 25e-6}


def usage(path: str, since: str = "") -> dict:
    seen, totals = set(), dict.fromkeys(PRICE, 0)
    for line in open(path):
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        message = entry.get("message") or {}
        if entry.get("type") != "assistant" or not message.get("usage") or message.get("id") in seen:
            continue
        if since and entry.get("timestamp", "") < since:
            continue
        seen.add(message.get("id"))
        for key in PRICE:
            totals[key] += message["usage"].get(key) or 0
    return {"calls": len(seen), **totals, "usd": round(sum(totals[k] * p for k, p in PRICE.items()), 2)}


if __name__ == "__main__":
    since = sys.argv[sys.argv.index("--since") + 1] if "--since" in sys.argv else ""
    print(json.dumps(usage(sys.argv[1], since)))
