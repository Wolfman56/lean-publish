import Lake
open Lake DSL

package «Contrib» where
  version := v!"0.1.0"

-- Pinned at v4.29.0 to match the working copy in uktf/jl_lemma.
-- Porting to master for Mathlib PR submission (2026-04-06).
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

lean_lib «Contrib» where
  roots := #[`Contrib]
