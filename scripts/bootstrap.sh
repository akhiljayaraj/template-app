#!/usr/bin/env bash
set -euo pipefail

OWNER=$(gh api user -q .login)
REPO=$(basename "$(git rev-parse --show-toplevel)")
echo "Bootstrapping $OWNER/$REPO"

# 1. Substitute the __OWNER__ placeholder in caller workflows
grep -rl '__OWNER__' .github/workflows | while read -r f; do
  sed -i.bak "s/__OWNER__/$OWNER/g" "$f" && rm -f "$f.bak"
done

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

# 3. Apply the branch-protection ruleset
gh api -X POST "repos/$OWNER/$REPO/rulesets" \
  --input .platform/ruleset.json >/dev/null
echo "Ruleset applied."

# 4. Commit the owner substitution
git add .github/workflows
git commit -m "chore: bootstrap project ($OWNER)" || echo "nothing to commit"
echo "Done. Push and open your first PR."
