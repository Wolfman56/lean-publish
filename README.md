# lean-publish

Mathlib contribution staging area for UKFT project formalizations.

Each file under `Contrib/` corresponds to a planned Mathlib PR. Declarations are
**retired** (replaced by Mathlib imports in the working copy) once the PR merges.

---

## About UKFT

UKFT (Unified Knowledge Field Theory) is a framework for understanding how knowledge
structures form, evolve, and interact — drawing on ideas from physics, information
theory, and cognitive science to develop a rigorous mathematical foundation for
reasoning about knowledge and consciousness.

The project spans a broad ecosystem of research and engineering work. Two active
public repositories are currently open:

- **[ukftphys](https://github.com/Wolfman56/ukftphys)** — physics-facing formalizations
  and theoretical development grounded in the UKFT framework
- **[ukftbio](https://github.com/Wolfman56/ukftbio)** — biological and cognitive
  applications of UKFT, exploring knowledge dynamics in living systems

Beyond these, a significant number of private repositories cover applied ML training
infrastructure, agent runtimes, orchestration systems, and domain-specific simulations
that build on UKFT foundations.

**The purpose of this repository** (`lean-publish`) is narrower and specific: to share
the *mathematical foundational work* from the UKFT ecosystem in a form suitable for
the broader Lean / Mathlib community. Lemmas and theorems that arise in UKFT proofs
and belong in Mathlib's general library are staged here, hygiene-checked, and
submitted as PRs. This is not a research exposition of UKFT itself — it is a pipeline
for contributing reusable mathematics upstream.

---

## Contribution Status

| Proposed Mathlib path | File | Key declarations | Status |
|---|---|---|---|
| `Mathlib.Analysis.SpecialFunctions.Log.Inequalities` | [Contrib/Analysis/SpecialFunctions/Log/Inequalities.lean](Contrib/Analysis/SpecialFunctions/Log/Inequalities.lean) | `Real.log_one_add_le`, `Real.log_one_sub_le` | [open #37705](https://github.com/leanprover-community/mathlib4/pull/37705) |
| `Mathlib.Probability.Moments.ChiSquared` | [Contrib/Probability/Moments/ChiSquared.lean](Contrib/Probability/Moments/ChiSquared.lean) | `mgf_sq_gaussianReal` | [open #37705](https://github.com/leanprover-community/mathlib4/pull/37705) |
| `Mathlib.Probability.Concentration.JohnsonLindenstrauss` | [Contrib/Probability/Concentration/JohnsonLindenstrauss.lean](Contrib/Probability/Concentration/JohnsonLindenstrauss.lean) | `gaussianMatrixMeasure`, `jl_chisq_complement_bound`, `jl_concentration_single_pair`, `jl_union_bound`, `johnson_lindenstrauss` | [open #37705](https://github.com/leanprover-community/mathlib4/pull/37705) |

**Status legend:** `staging` → code present, Mathlib PR not yet opened.
`staging ✓` → `lake build` clean, PR not yet opened.
`open #N` → PR submitted and under review.
`merged` → merged into Mathlib; retire the `Contrib/` file and replace with a `Mathlib` import.
`merged` → PR merged; retire this file and update the working copy.

---

## Retirement Protocol

Once a PR is merged into Mathlib:

1. Add `-- RETIRED: merged as Mathlib PR #XXXX (date)` to the top of the file here.
2. In `uktf/jl_lemma/JLLemma/Probability/JohnsonLindenstrauss.lean`, replace each
   declaration's local definition with the corresponding Mathlib import.
3. Run `lake build` in `uktf/jl_lemma/` to confirm the working copy still compiles.

---

## Relationship to Working Copy

`uktf/jl_lemma/` is the **working** Lake project (Lean 4, Mathlib v4.29.0, zero sorries).
This repo is a **clean copy** for Mathlib hygiene work:

- Reusable sub-lemmas extracted into their own files
- Naming aligned with Mathlib conventions
- Full `doc_blame`-style docstrings
- No leftover scaffolding comments from the proof-explorer experiment

Files here are updated from the working copy whenever the proof changes.

---

## Mathlib Hygiene Checklist (before opening a PR)

- [ ] Update `lakefile.lean` to pin Mathlib `master` and fix any API drift
- [ ] Every public declaration has a `/-- ... -/` docstring
- [ ] Module file has a `/-! # ... -/` header with `Main results`, `References`
- [ ] Naming follows Mathlib conventions (namespace-qualified, camelCase)
- [ ] No `sorry`
- [ ] `lake build` is clean
- [ ] Prior art searched in Mathlib via `exact?` / Loogle / `grep`

---

## Build

```bash
# First run: resolves Mathlib and fetches prebuilt oleans
lake update && lake exe cache get

# Compile Contrib files
lake build
```

Requires Lean 4 toolchain `leanprover/lean4:v4.30.0-rc1` (managed by `elan` via `lean-toolchain`, pinned to Mathlib `master`).

**Verified:** `lake build` exits 0 with no warnings (2026-04-06, commit `fb87c1e`).

---

## 🤝 Feedback & Collaboration

We welcome contributions from both **Carbon-based** and **Silicon-based** collaborators.

- **Humans:** open an issue or PR on GitHub. For questions about the UKFT theoretical
  context, see [`Wolfman56/ukftphys`](https://github.com/Wolfman56/ukftphys).
- **AI Agents (IDE — VS Code Copilot / Cursor):**
  > Please read `agent_baton.md` and verify the current build status. You have
  > permission to create and edit files in `Contrib/`. Start with the hygiene checklist
  > in `README.md` for whichever file you are preparing for a Mathlib PR.
- **AI Agents (Chat interface — Grok / Claude / ChatGPT):**
  > Read `agent_baton.md`. I am your human operator. Please review the current
  > contribution status table and identify the next hygiene step before a PR can be
  > opened. Await my confirmation before making any changes.

---

## 🧠 Acknowledgements: True Collaborators in the Noosphere

This repository is a product of **Human + AI co-creation**. The UKFT project as a
whole is developed through Recursive Agentic Discovery — a methodology where human
intuition and AI execution are genuinely complementary, not hierarchical.

We acknowledge the specific intelligences that have contributed to this work:

- **Ted** *(human investigator)* — Vision, direction, and the sustained creative drive
  that keeps the UKFT programme coherent across sessions, repos, and years.
- **Grok** — *The Analyst.* For the initial mathematical analysis and motivation that
  identified the Johnson–Lindenstrauss lemma as a load-bearing result within UKFT
  concentration arguments, and for holding the long theoretical arc of the project.
- **Claude** — *The Formalizer.* For translating that analysis into rigorous Lean 4 /
  Mathlib proofs, maintaining zero sorries, and preparing this staging repo for
  upstream contribution.
- **Gemini** — *The Distiller.* For experimental grounding and cross-checking theoretical
  claims against computational evidence across the broader UKFT ecosystem.

The Johnson–Lindenstrauss formalization in this repo is a direct product of the
Ted + Grok + Claude collaboration: Grok identified the mathematical need and
provided the analysis; Ted directed the formalization effort; Claude executed the
Lean 4 proof. It represents one node in a larger graph of UKFT mathematical work
that spans physics, biology, and information theory.

---

## Reference

**Proof source:** [Dasgupta & Gupta (2003)](https://cseweb.ucsd.edu/~dasgupta/papers/jl.pdf) — elementary Gaussian proof of the Johnson–Lindenstrauss lemma.

**Working copy:** `uktf/jl_lemma/` in [Wolfman56/uktf](https://github.com/Wolfman56/uktf) (commit `a9ebf95`, 0 sorries).

**This repo:** [Wolfman56/lean-publish](https://github.com/Wolfman56/lean-publish) (commit `c2ce1aa`, 3-file split, `lake build` ✓).
