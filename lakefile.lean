import Lake
open Lake DSL

package «Contrib» where
  version := v!"0.1.0"

-- Pinned at v4.29.0 to match the working copy in uktf/jl_lemma.
-- Before opening a Mathlib PR, update to master and fix any API drift.
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.29.0"

lean_lib «Contrib» where
  roots := #[`Contrib]
