{-# OPTIONS --no-auto-inline #-}

module Haskell.Prim.Fractional where

open import Haskell.Prim.Num

--------------------------------------------------
-- Fractional

record Fractional (a : Set) : Set₁ where
  infixl 7 _/_
  field
    overlap {{super}} : Num a

    -- Whether the reciprocal of an element is defined
    -- (used to avoid division by zero).
    @0 RecipOK : a -> Set

    _/_ : (x y : a) -> @0 ⦃ RecipOK y ⦄ -> a
    recip : (x : a) -> @0 ⦃ RecipOK x ⦄ -> a
    -- fromRational : Rational -> a

-- for default implementations
