# Project conventions (inherited from the platform template)

This repo was created from `akhiljayaraj/template-app` and rides on a shared
dev platform. Follow these conventions.

## First-time setup
Run once, right after creating the repo from the template:

```bash
./scripts/bootstrap.sh
```

It substitutes the workflow owner, syncs the standard labels, applies branch
protection (best-effort — needs GitHub Pro or a public repo), and links the
shared project board (best-effort — needs the `project` gh scope).

## CI / pipeline
- CI is defined once in the platform repo and called from `.github/workflows/ci.yml`
  here, pinned at `@v1`. Do NOT copy pipeline logic into this repo — change it in
  `akhiljayaraj/.github` and move the `v1` tag.
- On every PR it runs, in order: **lint → typecheck → unit → integration → build**,
  plus CodeQL. Check names appear as `ci / lint`, `ci / typecheck`, `ci / unit`,
  `ci / integration`, `ci / build`.
- These npm scripts are the contract the pipeline calls — keep them working:
  `lint`, `typecheck`, `test:unit`, `test:integration`, `build`, `test`.

## Local development
```bash
npm ci        # or: just install
npm test      # run tests   (just test)
npm run lint  # lint        (just lint)
npm run build # build       (just build)
```

## Workflow
- `main` is the trunk. Branch as `feat/<slug>`, `fix/<slug>`, `chore/<slug>`.
- Open a PR, fill the template, link the issue with `Closes #NNN`.
- Keep CI green; squash-merge.
- `CODEOWNERS` auto-requests review; approvals reset on new commits.

## Known platform caveats (not bugs)
The account is on GitHub's free plan with private repos, so **enforced** branch
protection and CodeQL code scanning are deferred (they need Pro or public repos).
CI, reviews, Dependabot, and the board work today; merges just aren't hard-blocked
yet. Enabling protection later is a clean toggle — the ruleset in
`.platform/ruleset.json` is already correct.

## Adding real dependencies / deploy
- The deploy/preview step is intentionally per-project. Wire it up when this app
  is actually deployable; it's the one swappable part of the pipeline.
