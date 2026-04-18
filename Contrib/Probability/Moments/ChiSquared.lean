/-
Copyright (c) 2026 Ted Vucurevich. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ted Vucurevich
-/
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Exp

/-!
# MGF of the Square of a Standard Normal

The moment generating function of `X²` when `X ∼ N(0,1)` is `(1 − 2t)^(-1/2)`,
valid for `t < 1/2`. This identity is the key ingredient in the chi-squared
Chernoff bound used in the Johnson–Lindenstrauss proof.

## Main results

* `mgf_sq_gaussianReal` : `mgf (· ^ 2) (gaussianReal 0 1) t = (1 − 2t)^(-1/2)` for `t < 1/2`

## References

Dasgupta, S. and Gupta, A. (2003). An elementary proof of a theorem of Johnson
and Lindenstrauss. *Random Structures & Algorithms* 22(1), 60–65.
-/

namespace ProbabilityTheory

open Real MeasureTheory

/-- The MGF of `X²` for `X ∼ N(0,1)` equals `(1 − 2t)^(-1/2)`, valid for `t < 1/2`.

Combines the Gaussian density with `exp(t x²)` into `exp(−((1−2t)/2) · x²)`,
applies the Gaussian integral formula, and simplifies the resulting square root
expression to `rpow` form. -/
lemma mgf_sq_gaussianReal {t : ℝ} (ht : t < 1 / 2) :
    mgf (· ^ 2) (gaussianReal 0 1) t = (1 - 2 * t) ^ (-(1 / 2 : ℝ)) := by
  rw [mgf, integral_gaussianReal_eq_integral_smul one_ne_zero]
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero, smul_eq_mul]
  have h_comb (x : ℝ) :
      (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) * exp (t * x ^ 2) =
      (√(2 * π))⁻¹ * exp (-((1 - 2 * t) / 2) * x ^ 2) := by
    rw [mul_assoc, ← exp_add]; ring_nf
  simp_rw [h_comb, integral_const_mul, integral_gaussian]
  suffices h : √(π / ((1 - 2 * t) / 2)) = √(2 * π) * (1 - 2 * t) ^ (-(1 / 2 : ℝ)) by
    rw [h]; field_simp
  have h_simpl : π / ((1 - 2 * t) / 2) = √(2 * π) ^ 2 / (1 - 2 * t) := by
    rw [sq_sqrt (by positivity)]; field_simp
  rw [h_simpl, sqrt_div', sqrt_sq, sqrt_eq_rpow, sqrt_eq_rpow,
      div_eq_mul_inv, ← rpow_neg]
  · linarith
  · positivity
  · linarith

end ProbabilityTheory
