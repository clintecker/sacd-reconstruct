# sacd-reconstruct — staging branch

**This is the staging branch**, a private working mirror — not the public face
of this repository.

- **You probably want the `public` branch** — that is the published tree:
  source-only, identifiers scrubbed, with the real README, docs and evidence.
- The README you may have seen at this root before (385/390 status, Nov 2) was
  a stale leftover from before the sync pipeline existed and has been retired;
  current, evidence-backed status lives in the public tree
  (`README.md` + `docs/EVIDENCE.md` there).
- Canonical source lives in the private `aftermath` repository
  (`experiments/sacd_reconstruct/`); this branch tracks it via
  `make sacd-sync-standalone`, and `make sacd-public-publish` assembles and
  audits the `public` branch from here.
