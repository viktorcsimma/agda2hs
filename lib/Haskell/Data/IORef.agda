-- Mimicking the interface of Haskell IORefs
-- with postulates.
-- See https://hackage.haskell.org/package/base-4.20.0.1/docs/Data-IORef.html.

module Haskell.Data.IORef where

open import Agda.Builtin.Unit
open import Haskell.Prim.IO
open import Haskell.Prim.Tuple

postulate
  IORef : ∀{i} -> Set i → Set i

  newIORef : ∀{i}{a : Set i} → a → IO (IORef a)
  readIORef : ∀{i}{a : Set i} → IORef a → IO a
  writeIORef : ∀{i}{a : Set i} → IORef a → a → IO ⊤
  modifyIORef modifyIORef' : ∀{i}{a : Set i} → IORef a → (a → a) → IO ⊤
  atomicModifyIORef atomicModifyIORef' : {a b : Set} → IORef a → (a → (a × b)) → IO b
  atomicWriteIORef : ∀{i}{a : Set i} → IORef a → a → IO ⊤
