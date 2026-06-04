/-
Copyright (c) 2026 Ted Vucurevich. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ted Vucurevich
-/

/-!
# Johnson–Lindenstrauss Lemma -- STARTING OUTLINE FOR AUTONOMOUS RE-PROVE PIPECLEANER

This is a skeletonized version of the final form (the full proof is in the sibling JohnsonLindenstrauss.lean).
The 4 core lemmas have their proof bodies replaced with ":= by sorry" (the parts that were the original 3-sorry stub work).
All imports, scaffolding, private helpers and the gaussianMatrixMeasure construction are kept.

For the pipecleaner experiment: start here, use the full nootex pipeline (distill sleep on exp_JL* corpus, BBB, redemption with Skillbrain, real lean_eval, ExperimentWorkspace apply/record, fine-tune) to autonomously fill the bodies to match the publishable final form.

See the jl_reprove/ dir and the harness block in distill-lib/tests/policy_tests.rs .
-/
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.Distributions.Gaussian.Multivariate
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Measure.MeasureSpace
import Contrib.Analysis.SpecialFunctions.Log.Inequalities
import Contrib.Probability.Moments.ChiSquared

/-!
# Johnson–Lindenstrauss Lemma (Dasgupta–Gupta 2003)

A Lean 4 formalization of the elementary Gaussian proof of the Johnson–Lindenstrauss
lemma: for any finite set of `n` points in ℝᵈ there exists a linear map into ℝᵐ
with `m = O(ε⁻² log n)` that is an ε-isometry on the set.

## Main results

* `gaussianMatrixMeasure` : i.i.d. N(0,1) product measure on `Fin m → Fin d → ℝ`
* `jl_chisq_complement_bound` : chi-squared Chernoff tail bound for a unit vector
* `jl_concentration_single_pair` : probability that a single pair is ε-preserved
* `jl_union_bound` : existence of a good matrix via union bound over all pairs
* `johnson_lindenstrauss` : the main theorem (linear map formulation)

## References

Dasgupta, S. and Gupta, A. (2003). An elementary proof of a theorem of Johnson
and Lindenstrauss. *Random Structures & Algorithms* 22(1), 60–65.
<https://cseweb.ucsd.edu/~dasgupta/papers/jl.pdf>
-/

open Real MeasureTheory

private lemma smul_mulVec_real {m d : ℕ} (c : ℝ) (M : Fin m → Fin d → ℝ) (x : Fin d → ℝ) :
    Matrix.mulVec (c • M) x = c • Matrix.mulVec M x := by
  funext i
  show (∑ j : Fin d, (c • M) i j * x j : ℝ) = c * ∑ j : Fin d, M i j * x j
  simp only [Pi.smul_apply, smul_eq_mul, ← Finset.mul_sum, mul_assoc]


/-- Bridge: `Matrix (Fin m) (Fin d) ℝ` is definitionally equal to `Fin m → Fin d → ℝ`
(`def Matrix m n α := m → n → α`), but Lean won't find Pi instances automatically
through the opaque `def`. This instance makes `MeasurableSpace` available. -/
instance Matrix.instMeasurableSpace {m n : Type*} {α : Type*} [MeasurableSpace α] :
    MeasurableSpace (Matrix m n α) :=
  inferInstanceAs (MeasurableSpace (m → n → α))

/-- Bridge: `TopologicalSpace` for `Matrix m n α` via Pi topology. -/
instance Matrix.instTopologicalSpace {m n : Type*} {α : Type*} [TopologicalSpace α] :
    TopologicalSpace (Matrix m n α) :=
  inferInstanceAs (TopologicalSpace (m → n → α))

/-- Bridge: `BorelSpace` for `Matrix m n α` via Pi (requires `Fintype` for `Pi.borelSpace`). -/
instance Matrix.instBorelSpace {m n : Type*} {α : Type*} [Fintype m] [Fintype n]
    [TopologicalSpace α] [SecondCountableTopology α] [MeasurableSpace α] [BorelSpace α] :
    BorelSpace (Matrix m n α) := by
  haveI : BorelSpace (n → α) := Pi.borelSpace
  exact inferInstanceAs (BorelSpace (m → n → α))

namespace ProbabilityTheory

/-- Gaussian i.i.d. product measure over `m × d` real matrices (each entry ~ N(0,1)).

**Construction**: nested product of `gaussianReal 0 1` measures,
one per entry, using `Measure.pi` twice (over rows, then columns). -/
noncomputable def gaussianMatrixMeasure (m d : ℕ) :
    Measure (Matrix (Fin m) (Fin d) ℝ) :=
  Measure.pi (fun _ : Fin m =>
    Measure.pi (fun _ : Fin d => gaussianReal 0 1))

/-- Bridge: `IsProbabilityMeasure` for `gaussianMatrixMeasure`, routed through the
Pi instance since `Matrix` is an opaque `def`. -/
instance (m d : ℕ) :
    IsProbabilityMeasure (gaussianMatrixMeasure m d) := by
  show IsProbabilityMeasure
    (Measure.pi (fun _ : Fin m =>
      Measure.pi (fun _ : Fin d => gaussianReal 0 1)))
  infer_instance

/-- The marginal of `gaussianMatrixMeasure` along row `i` is the i.i.d. N(0,1)
product measure on the `d` entries of that row. -/
lemma gaussianMatrixMeasure_row_map (m d : ℕ) (i : Fin m) :
    (gaussianMatrixMeasure m d).map (Function.eval i) =
    Measure.pi (fun _ : Fin d => gaussianReal 0 1) := by
  simp only [gaussianMatrixMeasure]
  exact (measurePreserving_eval
    (μ := fun _ : Fin m =>
      Measure.pi (fun _ : Fin d => gaussianReal 0 1)) i).map_eq

/-- Each individual entry `(i, j)` of a Gaussian matrix has marginal N(0,1). -/
lemma gaussianMatrixMeasure_entry_map (m d : ℕ) (i : Fin m) (j : Fin d) :
    (gaussianMatrixMeasure m d).map (fun A : Fin m → Fin d → ℝ => A i j) =
    gaussianReal 0 1 := by
  have h : (gaussianMatrixMeasure m d).map (fun A : Fin m → Fin d → ℝ => A i j) =
      ((gaussianMatrixMeasure m d).map (fun A : Fin m → Fin d → ℝ => A i)).map
      (fun v : Fin d → ℝ => v j) := by
    have hc : (fun A : Fin m → Fin d → ℝ => A i j) =
        (fun v : Fin d → ℝ => v j) ∘ (fun A : Fin m → Fin d → ℝ => A i) := by funext; rfl
    rw [hc, Measure.map_map (measurable_pi_apply j) (measurable_pi_apply i)]
  rw [h, gaussianMatrixMeasure_row_map]
  exact (measurePreserving_eval
    (μ := fun _ : Fin d => gaussianReal 0 1) j).map_eq

private lemma gaussianMatrix_iIndepFun_rows {m d : ℕ} :
    iIndepFun (fun i (A : Fin m → Fin d → ℝ) => A i)
      (gaussianMatrixMeasure m d) := by
  simp only [gaussianMatrixMeasure]
  exact iIndepFun_pi (fun _ => aemeasurable_id)

private lemma gaussianRow_dotProduct_map {d : ℕ} (x : Fin d → ℝ)
    (hx : ∑ j, x j ^ 2 = 1) :
    (Measure.pi (fun _ : Fin d => gaussianReal 0 1)).map
      (fun v : Fin d → ℝ => ∑ j : Fin d, v j * x j) =
    gaussianReal 0 1 := by
  apply Measure.ext_of_charFun (E := ℝ)
  ext t
  rw [charFun_apply_real,
      integral_map
        ((Finset.measurable_sum Finset.univ (fun j _ =>
          (measurable_pi_apply j).mul measurable_const)).aemeasurable)
        (by apply Measurable.aestronglyMeasurable; measurability)]
  rw [show charFun (gaussianReal 0 1) t =
      Complex.exp (-(↑t ^ 2 / 2)) from by
    rw [charFun_gaussianReal]; congr 1; push_cast; ring]
  simp_rw [show ∀ v : Fin d → ℝ,
      Complex.exp (↑t * ↑(∑ j : Fin d, v j * x j) * Complex.I) =
      ∏ j : Fin d, Complex.exp (↑(t * x j * v j) * Complex.I) from fun v => by
    have heq : (↑t : ℂ) * ↑(∑ j : Fin d, v j * x j) * Complex.I =
               ∑ j : Fin d, ↑(t * x j * v j) * Complex.I := by
      push_cast [Finset.mul_sum, Finset.sum_mul]
      congr 1; funext j; ring
    rw [heq, Complex.exp_sum]]
  have hFubini : ∫ (v : Fin d → ℝ),
      ∏ j : Fin d, Complex.exp (↑(t * x j * v j) * Complex.I)
      ∂Measure.pi (fun _ => gaussianReal 0 1) =
      ∏ j : Fin d,
        ∫ (y : ℝ), Complex.exp (↑(t * x j * y) * Complex.I)
        ∂gaussianReal 0 1 :=
    integral_fintype_prod_eq_prod
      (μ := fun _ => gaussianReal 0 1)
      (fun j (y : ℝ) => Complex.exp (↑(t * x j * y) * Complex.I))
  rw [hFubini]
  simp_rw [show ∀ (j : Fin d) (vj : ℝ),
      Complex.exp (↑(t * x j * vj) * Complex.I) =
      Complex.exp (↑(t * x j) * ↑vj * Complex.I) from
    fun j vj => by push_cast; ring_nf]
  simp_rw [← charFun_apply_real, charFun_gaussianReal]
  rw [← Complex.exp_sum]
  congr 1
  push_cast
  simp only [mul_zero, zero_mul, zero_sub, one_mul]
  rw [Finset.sum_neg_distrib]
  congr 1
  rw [← Finset.sum_div]
  congr 1
  simp_rw [mul_pow]
  rw [← Finset.mul_sum,
      show (∑ j : Fin d, (x j : ℂ) ^ 2) = 1 from by exact_mod_cast hx]
  ring


/-- Chi-squared concentration complement bound (Dasgupta–Gupta 2003, Lemma 2.2).

For a Gaussian matrix `A` drawn from `gaussianMatrixMeasure m d` and a unit
vector `x`, the probability that `(1/√m)² · ‖Ax‖²` falls **outside** `[1−ε, 1+ε]`
is at most `2 · exp(−mε²/8)`.

**Proof sketch:**
Each row dot-product `⟨Aᵢ, x⟩` is N(0,1) (unit-vector rotation), so
`∑ᵢ ⟨Aᵢ, x⟩²` is chi-squared with `m` degrees of freedom.
Upper and lower Chernoff bounds via `measure_ge_le_exp_mul_mgf` /
`measure_le_le_exp_mul_mgf`, optimised at `t_u = ε/(2(1+ε))` and
`t_l = −ε/(2(1−ε))` respectively, yield the stated bound. -/
lemma jl_chisq_complement_bound
    {m d : ℕ} (hm : 0 < m)
    (ε : ℝ) (hε : 0 < ε) (hε' : ε < 1)
    (x : EuclideanSpace ℝ (Fin d)) (hx : ‖x‖ = 1) :
    (gaussianMatrixMeasure m d)
        {A : Matrix (Fin m) (Fin d) ℝ |
          (1 / sqrt ↑m) ^ 2 *
            ‖(WithLp.equiv 2 (Fin m → ℝ)).symm (Matrix.mulVec A x)‖ ^ 2
            ∉ Set.Icc (1 - ε) (1 + ε)} ≤
    ENNReal.ofReal (2 * exp (-(↑m * ε ^ 2 / 8))) := by
  sorry



end ProbabilityTheory
