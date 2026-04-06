# lean-publish

Mathlib contribution staging area for UKFT project formalizations.

Each file under `Contrib/` corresponds to a planned Mathlib PR. Declarations are
**retired** (replaced by Mathlib imports in the working copy) once the PR merges.

---

## Contribution Status

| Proposed Mathlib path | File | Key declarations | Status |
|---|---|---|---|
| `Mathlib.Analysis.SpecialFunctions.Log.Inequalities` | [Contrib/Analysis/SpecialFunctions/Log/Inequalities.lean](Contrib/Analysis/SpecialFunctions/Log/Inequalities.lean) | `log_one_add_le`, `log_one_sub_le` | staging |
| `Mathlib.Probability.Moments.ChiSquared` | [Contrib/Probability/Moments/ChiSquared.lean](Contrib/Probability/Moments/ChiSquared.lean) | `mgf_sq_gaussianReal` | staging |
| `Mathlib.Probability.Concentration.JohnsonLindenstrauss` | [Contrib/Probability/Concentration/JohnsonLindenstrauss.lean](Contrib/Probability/Concentration/JohnsonLindenstrauss.lean) | `gaussianMatrixMeasure`, `jl_chisq_complement_bound`, `jl_concentration_single_pair`, `jl_union_bound`, `johnson_lindenstrauss` | staging |

**Status legend:** `staging` → code present, Mathlib PR not yet opened.
`open` → PR submitted, link in the table.
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
# First run: downloads Mathlib (large, ~several minutes)
lake update

# Subsequent runs
lake build
```

Requires Lean 4 toolchain `leanprover/lean4:v4.29.0` (managed by `elan` via `lean-toolchain`).

---

## Reference

**Proof source:** [Dasgupta & Gupta (2003)](https://cseweb.ucsd.edu/~dasgupta/papers/jl.pdf) — elementary Gaussian proof of the Johnson–Lindenstrauss lemma.

**Working copy:** `uktf/jl_lemma/` in [Wolfman56/uktf](https://github.com/Wolfman56/uktf) (commit `a9ebf95`).
