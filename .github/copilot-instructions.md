# Copilot Instructions — lean-publish

This is **lean-publish**, the canonical home for all Lean 4 formalization work in the
grok/UKFT ecosystem. **All Lean proofs, lemmas, and theorems live here — not in domain
repos** (uktf, noogine, clkos, etc.). Domain repos hold theory, experiments, and
expository notes; Lean source lives here.

## Purpose

`lean-publish` is the Mathlib contribution staging area for the UKFT project. It is a
pipeline: general-purpose mathematical results that arise from UKFT formalizations are
extracted here, hygiene-checked against Mathlib conventions, and submitted upstream as
PRs to `leanprover-community/mathlib4`.

## Toolchain

- **Lean version:** `leanprover/lean4:v4.30.0-rc1`
- **Mathlib:** pinned to `master` (see `lean-toolchain` and `lake-manifest.json`)
- **Build check:** `lake build` must exit 0 before any commit

## Repository Layout

```
Contrib/                    ← All staged lemmas live here
  Analysis/
    SpecialFunctions/
      Log/
        Inequalities.lean   ← Real.log_one_add_le, Real.log_one_sub_le
  Probability/
    Moments/
      ChiSquared.lean       ← mgf_sq_gaussianReal
    Concentration/
      JohnsonLindenstrauss.lean  ← Five JL declarations
Contrib.lean                ← Module index (import every Contrib/* file here)
agent_baton.md              ← Session handover notes (read first each session)
README.md                   ← Public status table and contribution workflow
```

The directory structure under `Contrib/` mirrors the Mathlib namespace hierarchy.
A file at `Contrib/Analysis/SpecialFunctions/Log/Inequalities.lean` will eventually
land at `Mathlib/Analysis/SpecialFunctions/Log/Inequalities.lean`.

## Workflow for New Lemmas

1. **Write** the lemma in the appropriate `Contrib/` file (create new file if needed,
   following the Mathlib directory / namespace convention)
2. **Register** it in `Contrib.lean` (import line)
3. **Hygiene check:**
   - Zero `sorry`s
   - All declarations in the appropriate Mathlib namespace (e.g. `namespace Real` for
     `Real.log_*` lemmas)
   - Doc-string on every new `theorem` / `lemma`
   - `#check` and `#eval` statements removed
   - `lake build` exits 0 with zero warnings
4. **Port imports:** When submitting to Mathlib, change `import Contrib.*` → `import Mathlib.*`
5. **Open PR** against `leanprover-community/mathlib4`. Include the AI disclosure
   section in the PR body (see existing PR #37705 as template)
6. **Update README.md:** Change status column from `staging ✓` → `open #NNNNN` with
   PR link, then to `merged` once the PR lands
7. **Archive in domain repos:** Once a lemma is in lean-publish, remove the Lean source
   from domain repos. Keep only `EXPLAINER.md` and any `results/` artifacts.

## Naming Conventions (Mathlib-style)

- Lemmas on `Real.log` go inside `namespace Real`  → `Real.log_one_add_le`
- Lemmas on `ProbabilityTheory.*` go inside `namespace ProbabilityTheory`
- Use `theorem` for the main result, `lemma` for helper steps
- Lean 4 snake_case for declaration names, CamelCase for type names
- Follow `Mathlib.Analysis.SpecialFunctions.Log.Basic` as style reference

## Session Handover

Before starting any work, read `agent_baton.md`. After completing a session, update
`agent_baton.md` with:
- Current toolchain version (if changed)
- Which files were modified and why
- Any API drift encountered when updating the Mathlib pin
- Outstanding hygiene issues

## Things NOT to Do

- Do not write Lean proofs in `uktf/`, `noogine/`, `clkos/`, or any other domain repo
- Do not leave `sorry` in any committed proof
- Do not commit without `lake build` passing
- Do not bypass the hygiene checklist before opening a Mathlib PR
- Do not modify `lake-manifest.json` manually — use `lake update` to bump the Mathlib pin

## Current PR Status

| PR | File | Status |
|----|------|--------|
| [#37705](https://github.com/leanprover-community/mathlib4/pull/37705) | Log/Inequalities.lean, ChiSquared.lean, JohnsonLindenstrauss.lean | open — under review |
