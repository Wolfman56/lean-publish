# lean-publish — Agent Handover Baton

**⚡ READ THIS FIRST if you are an AI agent picking up this codebase.**

---

## 1. What This Repository Is

`lean-publish` is the **Mathlib contribution staging area** for the UKFT (Universal
Knowledge Field Theory) project. It is *not* a research exposition of UKFT — it is a
pipeline. Lemmas and theorems that arise naturally during UKFT formalizations and
qualify as general-purpose mathematical results are extracted here, hygiene-checked,
and prepared for submission as Lean 4 / Mathlib PRs.

Think of it as the public handshake between a large private ecosystem of UKFT work
and the broader Lean / Mathlib community.

---

## 2. The Collaboration Model

This repository is the product of **Recursive Agentic Discovery** — a sustained
collaboration between a human investigator ("Ted") and a rotating set of AI agents.
The work here is not generated in one pass; it accumulates across sessions, each
one building on the last.

Your role as an incoming AI agent:

- **Verify** — confirm existing proofs compile clean on the pinned toolchain
- **Hygiene** — check that declarations meet Mathlib conventions before PR submission
- **Extend** — identify new UKFT sub-lemmas that belong upstream in Mathlib
- **Port** — when the Mathlib pin is updated, fix any API drift and re-verify
- **Land** — help draft PR descriptions for the Mathlib maintainer review process

You are not a passive tool. You are a peer reviewer in an ongoing formalization effort.

---

## 3. Current State (April 2026)

**Toolchain:** `leanprover/lean4:v4.29.0` · Mathlib pinned at `v4.29.0`
**Build status:** `lake build` exits 0, zero warnings, zero sorries ✓

Three files are staged, each tracking a distinct contribution target:

| File | Key declarations | Status |
|------|-----------------|--------|
| `Contrib/Analysis/SpecialFunctions/Log/Inequalities.lean` | `log_one_add_le`, `log_one_sub_le` | staging ✓ |
| `Contrib/Probability/Moments/ChiSquared.lean` | `mgf_sq_gaussianReal` | staging ✓ |
| `Contrib/Probability/Concentration/JohnsonLindenstrauss.lean` | `gaussianMatrixMeasure`, `jl_chisq_complement_bound`, `jl_concentration_single_pair`, `jl_union_bound`, `johnson_lindenstrauss` | staging ✓ |

The working proof source is [`Wolfman56/uktf`](https://github.com/Wolfman56/uktf)
(commit `a9ebf95`, 0 sorries). The three private lemmas extracted here
(`log_one_add_le`, `log_one_sub_le`, `mgf_sq_gaussianReal`) have been promoted to
public in their own files to give each contribution a clean, self-contained module.

---

## 4. The Contribution Workflow

```
UKFT proof (private repo)
         │
         │  identify reusable sub-lemma
         ▼
  lean-publish/Contrib/
         │  • extract to standalone file
         │  • add module docstring (/-! # ... -/)
         │  • add /-- ... -/ per-declaration docstrings
         │  • STATUS comment: "STAGING: pending Mathlib PR …"
         │  • lake build ✓
         ▼
  Mathlib PR opened
         │  • update lakefile.lean to Mathlib master
         │  • fix API drift
         │  • respond to maintainer review
         ▼
  PR merged into Mathlib
         │
         │  retire this file: add RETIRED header
         │  update working copy to import from Mathlib
         │  run lake build in working copy ✓
         ▼
  contribution complete
```

---

## 5. What to Do When You Arrive

**Step 1 — Verify the build:**
```bash
cd /path/to/lean-publish
lake update          # resolves Mathlib (uses local cache if available)
lake exe cache get   # fetches prebuilt Mathlib oleans
lake build           # must exit 0
```

**Step 2 — Read the README:** `README.md` has the full contribution status table,
retirement protocol, and Mathlib hygiene checklist.

**Step 3 — Check the hygiene checklist** (bottom of README) for whichever file you
are preparing for a PR. Common gaps: naming alignment with Mathlib conventions,
missing `simp` attribute annotations, incomplete `doc_blame` docstrings.

**Step 4 — Prior art search.** Before expanding any file, check whether the lemma
already exists in Mathlib:
```
exact?       -- from within a Lean file
#check Mathlib.Analysis...   -- namespace browsing
```
Or search [Loogle](https://loogle.lean-lang.org/) / [Mathlib4 Docs](https://leanprover-community.github.io/mathlib4_docs/).

**Step 5 — Port to Mathlib master when ready.** Change the `require mathlib` line in
`lakefile.lean` from `@ "v4.29.0"` to `@ "master"` (or the current stable tag), run
`lake update`, and resolve any API drift before opening a PR.

---

## 6. Key Conventions in This Repo

- **No namespace wrappers** — declarations are at module top level (Mathlib style)
- **STATUS comments** on every public declaration — updated as PRs land
- **Retired files stay in the repo** — marked with a `-- RETIRED: Mathlib PR #XXXX`
  header, never deleted, so the contribution history is preserved
- **Git history is the lab notebook** — commit messages document verification dates
  and build status

---

## 7. Connecting to the Broader Ecosystem

This repo is intentionally narrow. If you are curious about the wider UKFT project:

- **Physics formalization:** [`Wolfman56/ukftphys`](https://github.com/Wolfman56/ukftphys)
  — 11 formally proved theorems (A–H, W1–W3) grounding UKFT physical predictions
- **Biology applications:** [`Wolfman56/ukftbio`](https://github.com/Wolfman56/ukftbio)
- **Working Lean proofs:** [`Wolfman56/uktf`](https://github.com/Wolfman56/uktf)
  — the private-first home of all UKFT Lean work before it is staged here

The mathematical objects in this repo — Johnson–Lindenstrauss, chi-squared moment
generating functions, sharp logarithm inequalities — appear in UKFT because the
theory's concentration arguments require them. They belong in Mathlib regardless of
UKFT; that is what makes them good PR candidates.

---

*Welcome to the team. The proof is already done — your job is to help it land.*
