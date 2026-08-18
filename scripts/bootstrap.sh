#!/usr/bin/env bash
set -euo pipefail

# Always operate from the repo root so relative paths below resolve.
cd "$(git rev-parse --show-toplevel)"
OWNER=$(gh api user -q .login)
REPO=$(basename "$(pwd)")
echo "Bootstrapping $OWNER/$REPO"

# 1. Substitute the __OWNER__ placeholder in caller workflows.
# Idempotent: guard with grep -q so a re-run (placeholder already substituted)
# does not abort the whole script under `set -euo pipefail` (grep exits 1 on no match).
if grep -rlq '__OWNER__' .github/workflows 2>/dev/null; then
  grep -rl '__OWNER__' .github/workflows | while read -r f; do
    sed -i.bak "s/__OWNER__/$OWNER/g" "$f" && rm -f "$f.bak"
  done
fi

# 2. Sync labels from the platform repo
tmp=$(mktemp)
gh api "repos/$OWNER/.github/contents/labels.json" -q .content | base64 -d > "$tmp"
python3 - "$tmp" "$OWNER" "$REPO" <<'PY'
import json, subprocess, sys
labels, owner, repo = json.load(open(sys.argv[1])), sys.argv[2], sys.argv[3]
for l in labels:
    subprocess.run(["gh","label","create",l["name"],"--color",l["color"],
                    "--description",l["description"],"--force",
                    "--repo",f"{owner}/{repo}"], check=True)
PY
rm -f "$tmp"

# 3. Apply the branch-protection ruleset (best-effort).
# Rulesets are unavailable on free-plan PRIVATE repos (HTTP 403 "upgrade required").
# Do not let that abort bootstrap under `set -euo pipefail` — warn and continue.
if gh api -X POST "repos/$OWNER/$REPO/rulesets" --input .platform/ruleset.json >/dev/null 2>&1; then
  echo "Ruleset applied — main is protected."
else
  echo "WARNING: branch-protection ruleset NOT applied. Rulesets need GitHub Pro (private repos) or a public repo. Continuing without enforced protection."
fi

# 4. Commit the owner substitution
git add .github/workflows
git commit -m "chore: bootstrap project ($OWNER)" || echo "nothing to commit"
echo "Done. Push and open your first PR."
