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

**Status**: Complete — see findings below.

### Experiment 1 Findings

**Step 1a — return-type-only change (body unchanged)**

Changed `gaussianMatrixMeasure` return type from `Measure (Fin m → Fin d → ℝ)` to
`Measure (Matrix (Fin m) (Fin d) ℝ)`, body unchanged. Build result:

```
error: failed to synthesize instance of type class
  MeasurableSpace (Matrix (Fin m) (Fin d) ℝ)
```

Hypothesis **disproved** — the elaborator cannot find the `MeasurableSpace` instance
because `Matrix` is an opaque `def`. The Pi instance `MeasurableSpace.pi` does not
fire.

**Step 1b — add `MeasurableSpace` bridge instance**

Added one instance before the definition:
```lean
instance {m n : Type*} {α : Type*} [MeasurableSpace α] :
    MeasurableSpace (Matrix m n α) :=
  inferInstanceAs (MeasurableSpace (m → n → α))
```

Build result: **13+ errors → 8 errors**. The `simp only [gaussianMatrixMeasure]`
failures all disappeared. Remaining 8 errors collapse to 3 patterns:

| Pattern | Count | Root cause |
|---------|-------|------------|
| **P1** `IsProbabilityMeasure` synthesis | 3 sites | Pi instance won't fire; needs its own bridge |
| **P2** `rewrite` pattern not found | 2 sites | `S : Set (Fin m → Fin d → ℝ)` vs measure over `Matrix` — set types diverge |
| **P3** `compl_compl` simp fails | 2 sites | Same set-type mismatch as P2 |

**P1** can be fixed with a second bridge instance:
```lean
instance (m d : ℕ) : IsProbabilityMeasure (gaussianMatrixMeasure m d) := by
  show IsProbabilityMeasure
    (Measure.pi (fun _ : Fin m => Measure.pi (fun _ : Fin d => gaussianReal 0 1)))
  infer_instance
```

**P2 and P3 reveal the actual O(n) work**: every internal set comprehension in the
proof body spells `A : Fin m → Fin d → ℝ` explicitly (e.g.,
`{A : Fin m → Fin d → ℝ | ...}`, `have hset : Sᶜ = {A : Fin m → Fin d → ℝ | ...}`).
Once the measure's universe type is `Matrix ...`, these sets are of type
`Set (Fin m → Fin d → ℝ)`, but the measure expects `Set (Matrix ...)`. The types
are definitionally equal but tactics (`rw`, `simp`) require syntactic matching, not
just definitional equality.

**Conclusion**: With 2 bridge instances the error count drops to 5, all of which
require touching specific proof-internal set definitions — roughly 5–8 targeted edits
of the form "change `{A : Fin m → Fin d → ℝ | ...}` to `{A : Matrix (Fin m) (Fin d) ℝ | ...}`
and update the corresponding `Yi`/`Xi` lambda types". This is Option A at reduced
scope: a ~45-minute targeted edit, not a 2-hour full reconstruction.

**JL.lean reverted** to clean state after experiments. All experiment changes
discarded from Lean source; findings documented here only.

---

### Experiment 2 — Step 1 + Step 2: full Matrix type at all set sites (2026-04-07)

**Status: COMPLETE — clean build achieved** (`c22a0f7`, on `d5-matrix-type-refactor`).

#### Step 1 (committed `b747507`)
- Add three bridge instances:
  - `MeasurableSpace (Matrix m n α)` via `inferInstanceAs (MeasurableSpace (m → n → α))`
  - `TopologicalSpace (Matrix m n α)` via `inferInstanceAs (TopologicalSpace (m → n → α))`
  - `BorelSpace (Matrix m n α) [Fintype m] [Fintype n]` via `Pi.borelSpace` (needed by
    `measurability` tactic; `OpensMeasurableSpace` follows from `BorelSpace`)
- Change `gaussianMatrixMeasure` return type to `Measure (Matrix (Fin m) (Fin d) ℝ)`.
- Add `IsProbabilityMeasure` bridge via `show` cast to Pi form + `infer_instance`.

#### Step 2 (committed `c22a0f7`)
Changed every `{A : Fin m → Fin d → ℝ | …}` annotation and local `Yi`/`Xi` definition
to `Matrix (Fin m) (Fin d) ℝ`. Non-trivial engineering challenges encountered:

| Challenge | Resolution |
|-----------|-----------|
| `rw [hrow]` fails: `fun A : Matrix … => A i` vs `Function.eval i : Pi → …` | Use `h_meas_i : Measurable (fun A : Matrix … => A i) := measurable_pi_apply i` (kernel accepts via `def`-eq); then `rw [← map_map h_sum h_meas_i, show map … from hrow]` |
| `rw [show Yi i = … from rfl]` fails | `Yi` is a `let`-binding; `rw` cannot find the pattern in the reduced goal. Fix: `simp only [Yi]` first to unfold the binding, exposing the explicit lambda |
| `BorelSpace (m → n → α)` synthesis fails with `[Countable m]` | Requires `[Fintype m] [Fintype n] [SecondCountableTopology α]` to chain through `Pi.borelSpace` twice; one `haveI` pre-step needed |
| `rw [map_map]` direction wrong | After `simp only [Yi]` the goal has `map (g ∘ f) μ` form; need `← map_map` not `map_map` |
| `hmgf_u` type annotation `fun A : Pi =>` | Must remove explicit annotation and let Lean infer `A : Matrix` from `Xi i : Matrix → ℝ`; then `rw [hmgf_u] at hChern` succeeds |
| `hfin`/`key` set-type mismatch with `IsFiniteMeasure` | Removing Pi annotation from `{A : Pi | …}` lets Lean infer `A : Matrix` (from `Xi i`) so the measure application type-matches |

#### Key Lessons for D5-style refactors in Lean 4

1. **`rw` uses reducible transparency**: `def Matrix ≡ Fin m → Fin d → ℝ` at the kernel level
   but `rw` cannot match across that boundary. All patterns must *syntactically* use the
   same spelling. The fix is consistent typing — not `show`/coercing inside `rw`.

2. **`exact e` can bridge where `rw [show … from e]` fails**: The Lean 4 kernel unfolds
   `def`s for elaboration of `exact`, while `rw` performs `kabstract` at reducible
   transparency. If a hypothesis `h` is definitionally equal (but not syntactically equal)
   to the goal, `exact h` often works; `rw [show goal from h]` often doesn't.

3. **`let`-bindings reduce in goals**: `let Yi := …` means the tactic goal may show the
   reduced form. `rw [show Yi i = …]` fails because `Yi i` is not a subterm of the
   reduced goal. Use `simp only [Yi]` to unfold explicitly first.

4. **`BorelSpace` beats `OpensMeasurableSpace` for Pi synthesis**: `Pi.borelSpace`
   requires `[Fintype ι]`; `Pi.opensMeasurableSpace` (if it exists) requires
   `[Countable ι]`. But in practice `inferInstanceAs (OpensMeasurableSpace (m → n → α))`
   fails even with `[Countable m] [Countable n]` — the synthesis chain bottlenecks on
   intermediate types. Going through `BorelSpace` with explicit `haveI` steps is reliable.

