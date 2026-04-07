# PR #37705 Review Baton
**feat: log inequalities, chi-squared MGF, and Johnson-Lindenstrauss lemma**

Date: 2026-04-06  
PR: https://github.com/leanprover-community/mathlib4/pull/37705  
Status: `awaiting-author`  
Lean: `v4.30.0-rc1` | Mathlib: `master @ 35186be`  
Reviewer models: hand this file to each model and collect feedback verbatim.

---

## What Has Been Done

### Alex Meiburg (Zulip) feedback — fully addressed

All six specific issues raised in the Zulip thread have been applied to the
`lean-publish` staging copies:

| Issue | File | Fix |
|-------|------|-----|
| `ring` → `ring_nf` (lint) | `ChiSquared` | ✅ applied |
| `have ht'` (unused) | `ChiSquared` | ✅ deleted |
| Nested `simp_rw [show ∀ x ...]` | `ChiSquared` | ✅ replaced by named `h_comb` |
| `[hsqrt2pi_pos.ne']` in `field_simp` (unneeded) | `ChiSquared` | ✅ deleted |
| `have ht12 : 0 < 1 - 2*t` only used as `le_of_lt` | `ChiSquared` | ✅ deleted entirely |
| `congr 1` unnecessary before `ring_nf` | `ChiSquared` | ✅ deleted |
| "Many comments don't make sense" | all | ✅ all inline step-narration comments stripped |
| "Apply cleanup to all lemmas" | `Inequalities` | ✅ `simpa` pattern + named `hdeq` |

### Additional cleanup applied

- `## Status -- STAGING` block and `**STATUS:**` inline annotations removed from
  all six declaration docstrings and both module docstrings.
- `## Naming notes (for Mathlib PR)` section removed from `JohnsonLindenstrauss`
  module doc.
- `have hd2` in both `Inequalities` lemmas simplified from a five-line nested
  `have h1 : HasDerivAt ... exact h; exact h1.div_const 4`
  to the one-liner `(simpa [pow_one] using hasDerivAt_pow 2 e).div_const 4`.
- Named `hdeq` extracted from inline `rwa [show ... from by field_simp; ring]`
  in both `Inequalities` lemmas.

### What is NOT yet ported to the PR branch

The `lean-publish` files are the improved staging copies. The mathlib4 fork
(`/Code/grok/mathlib4`, branch `feat/jl-lemma-formalization`) still contains
the **original submission**. Before pushing an update to the PR, three files
need to be copied from `Contrib/` to `Mathlib/` with `Contrib.*` → `Mathlib.*`
import substitutions.

---

## Outstanding Issues for Model Reviewers

Below are grouped concerns, roughly ordered by severity. For each, please give
your verdict: **fix now**, **fix before merge**, **optional improvement**, or
**leave as-is with justification**.

---

### Group A — Correctness / Potential Bugs

**A1. `push Not` tactic (`JohnsonLindenstrauss.lean`, `jl_union_bound`)**

```lean
push Not at hS   -- hS : 1 < S.card
```

Standard Lean 4 Mathlib uses `push_neg`, not `push Not`. Verify whether
`push Not` is a valid alias or silently does nothing. If the goal closes
anyway without the transformation, the comment is lying. Check what
`hS` actually is after this line at elaboration time.

**A2. `integral_gaussian` without explicit argument (`ChiSquared.lean`)**

```lean
rw [MeasureTheory.integral_const_mul, integral_gaussian]
```

The staging file omits the explicit `((1 - 2 * t) / 2)` argument that the
original PR had. Lean should be able to unify it, but if future Mathlib
changes add overloads this may become ambiguous. Consider restoring an
explicit argument or confirming unification is robust.

**A3. `EuclideanSpace.real_norm_sq_eq` existence**

The proof of `jl_chisq_complement_bound` uses:
```lean
rw [EuclideanSpace.real_norm_sq_eq]
```
Verify that this name exists verbatim in the current Mathlib master
(`35186be`). If it was renamed (common in Mathlib 4.28→4.30 cycle), the
PR will fail to build against upstream master.

---

### Group B — Mathlib Naming / Namespace Conventions

**B1. `mgf_sq_gaussianReal` is not in `namespace ProbabilityTheory`**

The declaration uses `open ProbabilityTheory in` at the lemma level, meaning
the lemma itself lives at the *root namespace*. Callers outside the file must
write `mgf_sq_gaussianReal`, not `ProbabilityTheory.mgf_sq_gaussianReal`. This
is consistent with the `open` at lemma level, but Mathlib convention for
probability results is to live inside `namespace ProbabilityTheory`. Either:
- Wrap the lemma in `namespace ProbabilityTheory ... end ProbabilityTheory`, or
- Keep `open ProbabilityTheory in` and accept the root-level name.

Which is preferred? The similar `mgf_gaussianReal` in Mathlib lives in
`namespace ProbabilityTheory`.

**B2. `Real.log` inside `namespace Real` (Inequalities.lean)**

Both lemma *statements* write `Real.log` even though they are inside
`namespace Real`. In the statement this is the user-facing name so it's
correct. In the proof body, `Real.log` is also used explicitly in the
`set g`/`set h` definitions — inside `namespace Real` these could be written
as just `log`. Minor but counts as a lint signal.

**B3. Hypothesis form `ε⁻¹ ^ 2` vs `ε ^ (-2 : ℤ)` or `/ε^2`**

```lean
(hm : (↑m : ℝ) > 8 * ε⁻¹ ^ 2 * Real.log (2 * ↑S.card * (↑S.card - 1)))
```

`ε⁻¹ ^ 2` is a common source of elaboration pain and `simp` mismatches.
The equivalent `8 / ε ^ 2` or `8 * (ε ^ 2)⁻¹` is more Mathlib-idiomatic.
Assess whether this causes `simp` failures downstream.

**B4. Module doc cross-reference still targets `Contrib`**

In `Inequalities.lean` module doc:
```
in the JL chi-squared tail (see `Contrib.Probability.Concentration.JohnsonLindenstrauss`).
```
For the PR this must read `Mathlib.Probability.Concentration.JohnsonLindenstrauss`.

---

### Group C — Proof Simplification Opportunities

**C1. Shared structure between `log_one_add_le` and `log_one_sub_le`**

Both lemmas have essentially the same skeleton:
1. `suffices h : 0 ≤ RHS - log(...) by linarith`
2. `set f := ...`
3. `have f0 : f 0 = 0 := by simp`
4. `have f_drv : ∀ e, HasDerivAt f (...) e`
5. `monotoneOn_of_hasDerivWithinAt_nonneg` / `antitoneOn_of_hasDerivWithinAt_nonpos`
6. Application to the interval

A human Mathlib contributor would factor out a shared helper or at minimum
note the structural similarity in a comment. Consider whether a private
`aux_log_ineq` lemma could unify both.

**C2. `bad_eq` proof in `jl_chisq_complement_bound`**

The bidirectional equivalence between the "bad set" in scaled form and the
chi-squared form is proved by casing `Or.inl/Or.inr` four times. This is
correct but ~40 lines. It is equivalent to: the affine map `x ↦ (1/m) * x`
applied to `ℝ` maps `Icc (m*(1-ε)) (m*(1+ε))` to `Icc (1-ε) (1+ε)`. A
lemma like `Set.image_Icc_of_pos_affineMul` (if it exists) could replace this.
Or the equivalence could be phrased directly as a `Set.preimage` equality.

**C3. `hnorm_eq` proof in `johnson_lindenstrauss`**

The linear map `f` is written out verbatim twice in `hnorm_eq`:

```lean
‖((WithLp.linearEquiv 2 ℝ (Fin m → ℝ)).symm.toLinearMap ∘ₗ
    (Matrix.mulVecLin ((1 / Real.sqrt (↑m : ℝ)) • A) ∘ₗ
     (WithLp.linearEquiv 2 ℝ (Fin d → ℝ)).toLinearMap)) u - ...‖
```

Using `set f := ...` at the top of the `obtain` block would remove this
duplication.

**C4. `gaussianRow_dotProduct_map` — check for existing Mathlib API**

The proof establishes that an inner product of a Gaussian vector with a
unit vector is N(0,1). This is a special case of the rotational invariance
of isotropic Gaussians. Mathlib's multivariate Gaussian library has grown
substantially. Run `exact?` / `apply?` to check if something like
`ProbabilityTheory.gaussianReal_map_linear` or
`gaussianMultivariate_marginal_linear` already covers this.

**C5. `hInt_upper` — integrability by contradiction**

The integrability of `exp(t * ∑ Xᵢ)` for `t < 1/2` is proved by contradiction:
"if it's not integrable, the integral is 0, but we know the MGF is positive."
This works but is logically backwards. A direct proof exists: the random variable
`∑ Xᵢ` is a sum of bounded-below i.i.d. χ²(1) variables, and for `t < 1/2`
the moment generating function converges — by a product argument the integral
is bounded. The backward argument is acceptable as a proof technique, but a
reviewer may ask for a direct proof.

---

### Group D — Mathematical / Generality Concerns

**D1. Log inequality constants: `ε²/4` vs `ε²/2`**

Proved: `log(1+ε) ≤ ε - ε²/4` and `log(1-ε) ≤ -ε - ε²/4`.

The standard Chernoff tail for chi-squared uses `log(1+u) ≤ u - u²/2`, which
is tighter and gives `exp(-mε²/4)` rather than `exp(-mε²/8)`. Dasgupta-Gupta
(2003) use the `ε²/4` bounds to get `exp(-mε²/8)`. This is all internally
consistent and correct for the stated application.

However, `log(1+ε) ≤ ε - ε²/2` (valid for `ε ≥ 0`) and
`log(1-ε) ≤ -ε - ε²/2` (valid for `ε ∈ [0,1)`) are natural companions to
`le_log_one_add_of_nonneg` in Mathlib and would be independently useful.
Are the `ε²/4` lemmas the right ones to propose for Mathlib, or would the
`ε²/2` versions have broader utility?

**D2. `jl_union_bound` hypothesis: `log(n(n-1))` vs `log n`**

The hypothesis uses `Real.log (2 * ↑S.card * (↑S.card - 1))` for the argument.
The classical JL statement uses `log n` where `n = |S|`. For `n ≥ 2`:

`log(2n(n-1)) = log(2) + log(n) + log(n-1) ≤ log(2) + 2·log(n) < 3·log(n)`

So the constant factor in front of `ε⁻²` in `hm` is effectively `8·3 = 24`
vs the classical `8` (or `4` with the tighter `ε²/2` log bound). The
theorem docstring notes this but a reviewer may ask for the cleaner `log n`
form with an explicit `n(n-1) ≤ n²` step absorbed into the hypothesis.

**D3. `smul_mulVec_real` — likely already in Mathlib**

```lean
private lemma smul_mulVec_real {m d : ℕ} (c : ℝ) (M : Fin m → Fin d → ℝ) (x : Fin d → ℝ) :
    Matrix.mulVec (c • M) x = c • Matrix.mulVec M x
```

This follows immediately from `(Matrix.mulVecLin M).map_smul` or
`Matrix.smul_mulVec`. Run `exact?` to check — if it exists, delete this
private lemma and inline the reference.

**D4. `johnson_lindenstrauss` uses squared distances**

The conclusion states:
```lean
(1 - ε) * ‖u - v‖ ^ 2 ≤ ‖f u - f v‖ ^ 2 ∧ ‖f u - f v‖ ^ 2 ≤ (1 + ε) * ‖u - v‖ ^ 2
```

Classical JL is stated for *distances* (not squared), as:
```
(1-ε) * ‖u-v‖ ≤ ‖f(u)-f(v)‖ ≤ (1+ε) * ‖u-v‖
```

The squared form is what jl_union_bound directly produces. The distance form
follows because `√((1-ε) * r²) = √(1-ε) * r ≤ r` and similarly, but the
implication is not automatic when `ε` appears multiplicatively on `‖‖²`.
Specifically: `(1-ε) * ‖u-v‖² ≤ ‖f(u)-f(v)‖²` does NOT imply
`(1-ε) * ‖u-v‖ ≤ ‖f(u)-f(v)‖` — the square root of `(1-ε)` vs `(1-ε)` are
different. So the squared form is a different (weaker for lower bound) result
than the classic statement. A reviewer will likely ask for the distance form
or at least a note explaining the relationship.

**D5. Relationship with `Mathlib.LinearAlgebra.Matrix.DotProduct` API**

The proof uses raw `Fin m → Fin d → ℝ` function types for matrices rather
than `Matrix (Fin m) (Fin d) ℝ`. Mathlib's preferred matrix type is
`Matrix`. `Matrix.mulVec` is called on `A : Fin m → Fin d → ℝ` which coerces
implicitly — confirm this coercion is uniform throughout and no mixup between
`A i j` and `Matrix.transpose A j i` occurs.

---

### Group E — Relative Quality Assessment

**E1. vs comparable Mathlib PRs**

Comparable recent Mathlib PRs (e.g. `MomentGeneratingFunction`, `ChernoffBound`,
`JensenInequality`) tend to:
- Have 2–4 lemmas per file (this file: 5+, bounded by module)
- Avoid private lemmas for substantial results (this file: two private lemmas)
- Prefer dot notation and `calc` chains (this file: uses both well in places)
- Avoid long `by_cases` splits that duplicate proof structure
- Have shorter average proof length per declaration (~15–40 lines for
  intermediate results, ~60–100 for main theorem)

The JL file at 720 lines for 5 public + 2 private declarations is long but
justified by the mathematical content. The `jl_chisq_complement_bound` proof
at ~200 lines is the longest individual proof; a human author might extract
`hUpper` and `hLower` into separate private lemmas.

**E2. vs Lean community proofs of JL**

A search of the Lean4/Mathlib ecosystem (as of 2026-04) shows no prior Lean 4
formalization of the Johnson-Lindenstrauss lemma in Mathlib. The landmark
formalizations are in Isabelle/HOL (Abdulaziz et al.) and Coq/SSReflect
(incomplete). This is a genuinely novel contribution to the Lean 4 ecosystem.

**E3. Proof idiom quality (post-cleanup)**

After cleanup, the three files are materially cleaner. Remaining verbosity
is concentrated in `jl_chisq_complement_bound` (the `bad_eq` equivalence and
`hInt_upper` by-contradiction argument) and `jl_union_bound` (the closed-set
measurability argument for `Good`, which is unavoidably long).

The `gaussianRow_dotProduct_map` proof via characteristic functions is
non-trivial and correct but could be shortened if a Mathlib `gaussianReal`
rotation lemma exists.

---

## Checklist for Model Reviewers

1. **Verify** `push Not` vs `push_neg` (A1) — is `push Not` valid Lean 4 syntax?
2. **Verify** `EuclideanSpace.real_norm_sq_eq` exists at Mathlib `35186be` (A3).
3. **Verify** `smul_mulVec_real` is not already in Mathlib (D3) — run `exact?`.
4. **Assess** B1 (namespace for `mgf_sq_gaussianReal`) — fix or justify.
5. **Assess** D4 (squared vs distance JL statement) — note or convert.
6. **Assess** D2 (log(n(n-1)) vs log(n)) — acceptable or change hypothesis?
7. **Suggest** simplifications for C1, C2, C3 if they can be done concisely.
8. **Check** whether `gaussianRow_dotProduct_map` is derivable from existing
   Mathlib Gaussian multivariate API (C4).
9. **Confirm** all `Contrib.*` references are updated to `Mathlib.*` before push.

---

## Files Under Review (lean-publish staging copies)

| File | Lines | Declarations | Sorries |
|------|-------|-------------|---------|
| `Contrib/Analysis/SpecialFunctions/Log/Inequalities.lean` | 95 | 2 public | 0 |
| `Contrib/Probability/Moments/ChiSquared.lean` | 44 | 1 public | 0 |
| `Contrib/Probability/Concentration/JohnsonLindenstrauss.lean` | 720 | 5 public + 2 private | 0 |

Build: ✅ `lake build Contrib` exits 0, 0 warnings (Lean v4.30.0-rc1,
Mathlib master `35186be`).
