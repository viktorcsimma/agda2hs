{-# OPTIONS --no-auto-inline #-}

-- A module containing Haskell's Data.Ratio and the Rational type.
module Haskell.Data.Ratio where

open import Agda.Builtin.Bool
open import Agda.Builtin.Unit
open import Agda.Builtin.Int renaming (Int to Integer)
open import Haskell.Prim
open import Haskell.Prim.Integer

-- Let's assure that there is no zero in the denominator
-- (unlike in Haskell, there will be no infinity and notANumber).

infixl 7 _:%_

data Ratio (a : Set) (@0 notNull : a -> Set) : Set where
  -- Can strict parameters be solved somehow?
  _:%_ : (x y : a) -> @0 {notNull y} -> Ratio a notNull
-- In everyday life, _%_ will be used
-- because it normalises.

@0 boolToSet : Bool -> Set
boolToSet true = ⊤
boolToSet _    = ⊥

Rational : Set
Rational = Ratio Integer (λ x -> boolToSet (eqInteger (pos 0) x))

numerator denominator : {a : Set} {@0 notNull : a -> Set} -> Ratio a notNull -> a
numerator   (x :% _) = x
denominator (_ :% y) = y
