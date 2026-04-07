# PR #37705 Review — Gemini 3.1 Pro — 2026-04-06

**Readiness rating:** 4/5  
**Summary:** The mathematical translation is excellent and successfully handles the typical measure-theory and analysis pitfalls in Lean. The remaining issues are primarily Mathlib-specific idiomatic adjustments (such as matrix typing and namespace organization) rather than fundamental flaws. Addressing the type mismatches and tightening the final theorem statement will ensure a smooth review process from the Mathlib maintainers.

---

### A1 — `push Not` vs `push_neg`

**Verdict:** optional  
**Finding:** `push Not` is indeed a valid macro for `push_neg` in Mathlib 4's `Mathlib.Tactic.Push`. It does not silently fail or do nothing. However, `push_neg` is the universally preferred idiom in Mathlib, so adopting it is recommended for style consistency.

---

### A2 — `integral_gaussian` without explicit argument

**Verdict:** leave as-is  
**Finding:** Lean's unification is robust enough to infer `((1 - 2 * t) / 2)` from the goal state `Real.sqrt (Real.pi / ((1 - 2 * t) / 2))`. Adding explicit arguments where unification succeeds generally goes against Mathlib linting rules.

---

### A3 — `EuclideanSpace.real_norm_sq_eq` existence

**Verdict:** unable to verify  
**Finding:** While standard norm squared lemmas exist, the exact `EuclideanSpace.real_norm_sq_eq` name should be double-checked locally against the `35186be` commit. If it fails, `PiLp.norm_sq_eq` or `EuclideanSpace.norm_eq` are the likely correct targets.

---

### B1 — Namespace for `mgf_sq_gaussianReal`

**Verdict:** fix before merge  
**Finding:** Placing probability lemmas in the root namespace goes against Mathlib conventions. It should be wrapped directly in `namespace ProbabilityTheory`.

```lean
namespace ProbabilityTheory

lemma mgf_sq_gaussianReal {t : ℝ} (ht : t < 1 / 2) :
    mgf (fun x : ℝ => x ^ 2) (gaussianReal 0 1) t = (1 - 2 * t) ^ (-(1 / 2 : ℝ)) := by
  -- proof body remains exactly the same
  sorry

end ProbabilityTheory
```

---

### B2 — `Real.log` inside `namespace Real`

**Verdict:** optional  
**Finding:** Using `Real.log` instead of `log` inside `namespace Real` is slightly redundant but perfectly valid. The `simp` lemmas and elaborator will treat them identically, but omitting `Real.` makes the definitions cleaner.

---

### B3 — `ε⁻¹ ^ 2` vs `8 / ε ^ 2`

**Verdict:** fix before merge  
**Finding:** `ε⁻¹ ^ 2` can cause elaboration friction and `simp` mismatches. `8 / ε ^ 2` is standard Mathlib style for fractional bounds and integrates much better with `linarith` and `positivity`.

```lean
(hm : (↑m : ℝ) > 8 / ε ^ 2 * Real.log (2 * ↑S.card * (↑S.card - 1)))
```

---

### B4 — Module doc `Contrib.*` reference

**Verdict:** fix before merge  
**Finding:** The cross-reference must point to the final Mathlib path to avoid broken documentation links once merged.

```lean
-- ...in the JL chi-squared tail (see `Mathlib.Probability.Concentration.JohnsonLindenstrauss`).
```

---

### C1 — Shared structure between the two log lemmas

**Verdict:** leave as-is  
**Finding:** While the proof skeleton is identical, extracting a custom derivative/monotonicity helper for just two lemmas often introduces more boilerplate than it eliminates. The current proofs are easy to read and self-contained.

---

### C2 — `bad_eq` biconditional verbosity

**Verdict:** optional  
**Finding:** Although long, the manual casing via `Or.inl` / `Or.inr` is explicit and robust against future changes in `Set` simplification lemmas. A `Set.preimage` simplification might be cleaner but is not strictly necessary for merge.

---

### C3 — `hnorm_eq` duplication (`set f`)

**Verdict:** optional  
**Finding:** Defining `set f := ...` would remove the visually dense repetition of the `WithLp.linearEquiv` composition and make the final proof step substantially cleaner to read.

---

### C4 — `gaussianRow_dotProduct_map` — existing Mathlib API

**Verdict:** unable to verify  
**Finding:** Mathlib's multivariate Gaussian API contains general rotational invariance properties, but extracting this exact finite-sum dot-product form might be harder than just keeping your self-contained characteristic function proof.

---

### C5 — `hInt_upper` integrability by contradiction

**Verdict:** leave as-is  
**Finding:** The proof by contradiction is mathematically sound and perfectly acceptable in Lean. Rewriting it to a direct product argument would require unnecessary effort if the current proof already seamlessly closes the goal.

---

### D1 — Log bound constants: `ε²/4` vs `ε²/2`

**Verdict:** add ε²/2 variant  
**Finding:** Since the `ε²/2` bounds are the canonical forms and independently useful for general analysis, they should be added to Mathlib. You can retain the `ε²/4` lemmas (perhaps as private or explicitly named `_weak` lemmas) if the Dasgupta-Gupta approach strictly requires them.

---

### D2 — `log(n(n-1))` vs `log n` in `hm` hypothesis

**Verdict:** change hypothesis form  
**Finding:** The mathematical community expects the classical `log n` bound. The `n(n-1)` term is an artifact of the union bound over pairs, which should be bounded by `n^2` (hence a factor of `2` inside the log) directly within the proof instead of leaking into the public hypothesis.

```lean
(hm : (↑m : ℝ) > 24 / ε ^ 2 * Real.log ↑S.card)
```

---

### D3 — `smul_mulVec_real` already in Mathlib?

**Verdict:** unable to verify  
**Finding:** It is highly likely covered by `Matrix.smul_mulVec` or `LinearMap.map_smul`, but if neither matches the explicit signature cleanly, keeping the 4-line private helper is harmless.

---

### D4 — Squared vs distance form of JL conclusion

**Verdict:** add note  
**Finding:** The squared bounds are structurally weaker on the lower tail. A docstring note clarifying that this is the squared-distance formulation should be added, or the proof extended to take the square root if the strict JL formulation is desired.

---

### D5 — `Fin m → Fin d → ℝ` vs `Matrix (Fin m) (Fin d) ℝ`

**Verdict:** fix before merge  
**Finding:** Using raw functions bypasses Mathlib's extensive matrix API, instances, and notation. The type should explicitly be `Matrix (Fin m) (Fin d) ℝ`.

```lean
(A : Matrix (Fin m) (Fin d) ℝ)
```

---

### Checklist items (quick verdicts)

| Item | Verdict | One-line note |
|------|---------|---------------|
| A1 `push Not` | optional | Valid macro for `push_neg`; `push_neg` is preferred style |
| A2 `integral_gaussian` arg | leave as-is | Unification handles this easily; explicit arg violates lint |
| A3 `real_norm_sq_eq` exists | unable to verify | Double-check against `PiLp.norm_sq_eq` locally |
| B1 `mgf_sq_gaussianReal` namespace | fix before merge | Wrap in `namespace ProbabilityTheory` |
| B4 `Contrib.*` → `Mathlib.*` in module doc | fix before merge | Must point to target Mathlib location |
| D3 `smul_mulVec_real` in Mathlib | unable to verify | Likely `Matrix.smul_mulVec`; keeping helper is fine fallback |
| D4 squared vs distance JL | add note | Bounds are mathematically distinct; add docstring note |

---

### Additional issues not in the baton

- **Combinatorial bounds / edge cases:** Ensure that `ENNReal` coercions (`Nat.cast_sub`) remain robust when moving to the classical `log n` formulation, as `n = 1` or `n = 0` edge cases will need careful handling to avoid silent truncation.

---

### Suggested Zulip reply text

> I've integrated the excellent feedback from the Zulip thread into the staging files — thanks to Alex for catching the `ring_nf` lint and the unused hypotheses. The cleanup makes the chi-squared proof much tighter.
>
> Before pushing the updated branch, I plan to make a few final adjustments: (1) moving `mgf_sq_gaussianReal` into `namespace ProbabilityTheory`, (2) changing the raw `Fin m → Fin d → ℝ` functions to `Matrix (Fin m) (Fin d) ℝ` to play nicely with the matrix API, and (3) swapping the hypothesis to `8 / ε ^ 2` to avoid elaboration issues.
>
> One open question for the maintainers: the proof naturally yields the squared-distance bounds `(1-ε)‖u-v‖² ≤ ‖f(u)-f(v)‖² ≤ (1+ε)‖u-v‖²`. Does Mathlib prefer pushing this through the square root to match the classic JL statement, or is the squared version acceptable with a docstring note?
