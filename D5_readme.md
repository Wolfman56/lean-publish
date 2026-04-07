# D5 — Matrix Type Refactor

Replace all `Fin m → Fin d → ℝ` spellings in `JohnsonLindenstrauss.lean` with the
Mathlib-canonical `Matrix (Fin m) (Fin d) ℝ` type.

---

## Problem Statement

Mathlib reviewers expect random-matrix proofs to use `Matrix (Fin m) (Fin d) ℝ`
rather than the equivalent-but-non-idiomatic Pi type `Fin m → Fin d → ℝ`.
The JL file currently uses the Pi spelling throughout:

- `gaussianMatrixMeasure (m d : ℕ) : Measure (Fin m → Fin d → ℝ)`
- `jl_union_bound`: hypothesis and conclusion over `Fin m → Fin d → ℝ`
- `johnson_lindenstrauss`: same
- `Matrix.mulVec` is already used in the statement, creating a visible inconsistency
  (the matrix is spelled as a Pi type but operated on via `Matrix` API)

---

## Attempt

Commit `1c77b74` (subsequently reverted as `6967d6d`) replaced every occurrence of
`Fin m → Fin d → ℝ` with `Matrix (Fin m) (Fin d) ℝ` and updated all `fun A =>`,
`fun i j =>`, and `A i j` sites accordingly.

The build was re-run after the global substitution.

---

## Failures

13+ cascaded elaboration and simp failures, grouped by category:

### 1. Pi typeclass instances do not fire on `Matrix`
`Matrix` is defined in Mathlib as:
```lean
def Matrix (m n : Type*) (α : Type*) := m → n → α
```
It is a **`def`**, not an **`abbrev`**. Lean 4 does not unfold `def`s during typeclass
search or simp. Consequently, every instance that holds by `Pi.instAdd`,
`Pi.instSMul`, `Pi.instNorm`, etc. on `Fin m → Fin d → ℝ` must be re-routed through
the dedicated `Matrix.*` instances — which require explicit `Matrix`-typed expressions
the elaborator does not produce automatically.

Failing sites (representative):
- `Pi.smul_apply` — fired on Pi type, not recognized for `Matrix`
- `Pi.add_apply` — same
- `Pi.norm_def` — same; `‖A‖` on a `Matrix` type requires `Matrix.norm_entry_le_iff`

### 2. `gaussianMatrixMeasure` definition mismatch
`gaussianMatrixMeasure` was defined over the Pi type and used `MeasureTheory.Measure.pi`
(the product measure over `Fin m → ·`). Changing the return type to
`Measure (Matrix (Fin m) (Fin d) ℝ)` requires either:
- a transport along the definitional equality `Matrix (Fin m) (Fin d) ℝ = Fin m → Fin d → ℝ`
  (which Lean won't do automatically for a `def`), or
- rewriting the measure construction using `MeasureTheory.Measure.pi` applied to the
  `Matrix`-typed funext form.

### 3. `attribute [local reducible] Matrix` is disallowed
The attempted workaround `attribute [local reducible] Matrix` was rejected by Lean:
```
error: 'reducible' attribute is not allowed for definitions, only for abbreviations
```
There is no lightweight way to ask Lean to treat `Matrix` as transparent locally.

### 4. Explicit coercions needed at `Matrix.mulVec` call sites
`Matrix.mulVec` expects a `Matrix (Fin m) (Fin d) ℝ` on the left. Under the Pi
spelling the elaborator inferred the correct coercion silently; under the `Matrix`
spelling the same expression type-checks but simp goals downstream diverge.

---

## Root Cause

`Matrix` in Lean 4 Mathlib is an **opaque `def`**, not a transparent abbreviation.
The definitional equality `Matrix (Fin m) (Fin d) ℝ ≅ Fin m → Fin d → ℝ` exists at
the kernel level but is invisible to the elaborator's typeclass search and simp
engine. There is no supported way to make `Matrix` reducible locally. Every lemma
that holds for Pi types must be re-proved (or re-routed) for the `Matrix` type using
the Mathlib `Matrix.*` API.

---

## Proposed Solution Options

### Option A — Full `Matrix` refactor (correct, ~2h)
1. Change `gaussianMatrixMeasure` to return `Measure (Matrix (Fin m) (Fin d) ℝ)`,
   rebuilding the measure construction via `MeasureTheory.Measure.pi` on the
   `Matrix`-typed space (using `Matrix.measurableEquivPiLp` or direct equivs).
2. Audit every simp goal that previously fired via `Pi.*` instances and replace with
   the corresponding `Matrix.*` lemma (`Matrix.add_apply`, `Matrix.smul_apply`,
   `Matrix.norm_entry_le_iff`, etc.).
3. At each of the 13 typeclass discharge sites add explicit `show` casts or
   `conv` rewrites to guide elaboration.
4. Outcome: fully Mathlib-idiomatic, strongest review posture.

### Option B — `Equiv`-bridge lemma (medium effort, ~45 min)
Define a measurable equivalence:
```lean
noncomputable def matrixEquivPi :
    Matrix (Fin m) (Fin d) ℝ ≃ᵐ (Fin m → Fin d → ℝ) :=
  MeasurableEquiv.refl _  -- or Matrix.measurableEquivPiLp composed properly
```
State `gaussianMatrixMeasure` in terms of `Matrix`, define it as the pushforward
of the Pi product measure along `matrixEquivPi.symm`, then use `matrixEquivPi`
to transport all existing Pi-type proofs. Avoids rewriting 13 simp sites but adds
an equiv overhead to every goal.

### Option C — Defer to reviewer request (0 effort now)
Submit the PR with the current Pi-type spelling. In the PR body note:
> "The matrix type is spelled `Fin m → Fin d → ℝ` for compatibility with the current
> `gaussianMatrixMeasure` measure construction. We are prepared to refactor to
> `Matrix (Fin m) (Fin d) ℝ` per reviewer guidance."

Mathlib reviewers frequently request this change as part of the review cycle; waiting
for their explicit ask avoids speculative churn.

### Option D — `abbrev` wrapper (workaround, not recommended)
Define `abbrev GaussianMatrix (m d : ℕ) := Fin m → Fin d → ℝ` and spell the type as
`GaussianMatrix m d` throughout. This preserves Pi-instance firing (because `abbrev`
is transparent) while giving a readable name. However, Mathlib reviewers will reject
a private abbreviation that doesn't match the library's `Matrix` type — so this
delays rather than solves the problem.

---

## Recommended Path

**Option A** if D5 is targeted for the current PR submission.  
**Option C** if timeline pressure is high — the Pi-type spelling is mathematically
correct and the proof is complete; the refactor is purely stylistic.

---

## Experiment Log

### Experiment 1 — Return-type-only change for `gaussianMatrixMeasure` (2026-04-07)

**Hypothesis**: `Matrix (Fin m) (Fin d) ℝ` and `Fin m → Fin d → ℝ` are definitionally
equal (`def Matrix m n α := m → n → α`). Therefore, changing only the declared return
type of `gaussianMatrixMeasure` to `Measure (Matrix (Fin m) (Fin d) ℝ)` — while
leaving the body identical — may compile without proof, because the elaborator can
accept the kernel-level equality.

If this compiles, Problem 1 (the `gaussianMatrixMeasure` mismatch) turns out to cost
exactly one line, reducing D5 to a `Pi.*`→`Matrix.*` simp-set audit at the call sites.

**Plan**:
1. On `d5-matrix-type-refactor` branch, change only the return type annotation of
   `gaussianMatrixMeasure` from `Measure (Fin m → Fin d → ℝ)` to
   `Measure (Matrix (Fin m) (Fin d) ℝ)`.
2. Run `lake build Contrib` and capture the full error list.
3. If it compiles: proceed to spell the variable type as `Matrix` in `jl_union_bound`
   and `johnson_lindenstrauss`, then run again and categorize remaining failures.
4. If it does not compile: record the exact elaboration error — it will tell us whether
   the body needs an explicit `show` cast or a genuine proof of measure transport.

**Status**: In progress — see commits following this entry.
