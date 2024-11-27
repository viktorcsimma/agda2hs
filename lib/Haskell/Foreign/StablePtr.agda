-- Mimicking the functionality of a StablePtr
-- with postulates.
-- Needed for foreign interfaces to C and C++ frontends.

module Haskell.Foreign.StablePtr where

open import Agda.Builtin.Unit
open import Haskell.Prim.IO

postulate
  StablePtr : ∀{i} → Set i → Set i

  newStablePtr : ∀{i}{a : Set i} → a → IO (StablePtr a)
  deRefStablePtr : ∀{i}{a : Set i} → StablePtr a → IO a
  freeStablePtr : ∀{i}{a : Set i} → StablePtr a → IO ⊤

