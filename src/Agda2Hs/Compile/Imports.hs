
module Agda2Hs.Compile.Imports ( compileImports, makeManualDecl ) where

import Data.Char ( isUpper )
import Data.List ( isPrefixOf )
import Data.Map ( Map )
import qualified Data.Map as Map
import Data.Set ( Set )
import qualified Data.Set as Set

import qualified Language.Haskell.Exts as Hs

import Agda.Compiler.Backend
import Agda.TypeChecking.Pretty ( text )
import Agda.Utils.Pretty ( prettyShow )

import Agda2Hs.AgdaUtils
import Agda2Hs.Compile.Name
import Agda2Hs.Compile.Types
import Agda2Hs.Compile.Utils
import Agda2Hs.HsUtils

type ImportSpecMap = Map (Hs.Name (), Hs.Namespace ()) (Set (Hs.Name (), Hs.Namespace ()))
type ImportDeclMap = Map (Hs.ModuleName (), Qualifier) ImportSpecMap

compileImports :: String -> Imports -> TCM [Hs.ImportDecl ()]
compileImports top is0 = do
  let is = filter (not . (top `isPrefixOf`) . Hs.prettyPrint . importModule) is0
  checkClashingImports is
  let imps = Map.toList $ groupModules is
  return $ map (uncurry $ uncurry makeImportDecl) imps
  where
    mergeChildren :: ImportSpecMap -> ImportSpecMap -> ImportSpecMap
    mergeChildren = Map.unionWith Set.union

    makeSingle :: Maybe (Hs.Name (), Hs.Namespace ()) -> (Hs.Name (), Hs.Namespace ()) -> ImportSpecMap
    makeSingle Nothing  q = Map.singleton q Set.empty
    makeSingle (Just p) q = Map.singleton p $ Set.singleton q

    groupModules :: [Import] -> ImportDeclMap
    groupModules = foldr
      (\(Import mod as p q ns) -> Map.insertWith mergeChildren (mod,as)
                                                                (makeSingle (parentTuple p) (q, ns)))
      Map.empty
        where
          parentTuple :: Maybe (Hs.Name ()) -> Maybe (Hs.Name (), Hs.Namespace ())
          parentTuple (Just name@(Hs.Symbol _ _)) = Just (name, Hs.TypeNamespace ())
                                                             -- ^ for parents, if they are operators, we assume they are type operators
                                                             -- but actually, this will get lost anyway because of the structure of ImportSpec
                                                             -- the point is that there should not be two tuples with the same name and diffenrent namespaces
          parentTuple (Just name)                 = Just (name, Hs.NoNamespace ())
          parentTuple Nothing     = Nothing

    -- TODO: avoid having to do this by having a CName instead of a
    -- Name in the Import datatype
    makeCName :: Hs.Name () -> Hs.CName ()
    makeCName n@(Hs.Ident _ s)
      | isUpper (head s) = Hs.ConName () n
      | otherwise        = Hs.VarName () n
    makeCName n@(Hs.Symbol _ s)
      | head s == ':' = Hs.ConName () n
      | otherwise     = Hs.VarName () n

    makeImportSpec :: (Hs.Name (), Hs.Namespace ()) -> Set (Hs.Name (), Hs.Namespace ()) -> Hs.ImportSpec ()
    makeImportSpec (q, namespace) qs
      | Set.null qs = Hs.IAbs () namespace q
      | otherwise   = Hs.IThingWith () q $ map (makeCName . fst) $ Set.toList qs

    makeImportDecl :: Hs.ModuleName () -> Qualifier -> ImportSpecMap -> Hs.ImportDecl ()
    makeImportDecl mod qual specs = Hs.ImportDecl ()
      mod (isQualified qual) False False Nothing (qualifiedAs qual)
      (Just $ Hs.ImportSpecList ()
            False                                             -- whether the list should be a list of hidden identifiers ('hiding')
            $ map (uncurry makeImportSpec) $ Map.toList specs)

    checkClashingImports :: Imports -> TCM ()
    checkClashingImports [] = return ()
    checkClashingImports (Import mod as p q _ : is) =
      case filter isClashing is of
        (i : _) -> genericDocError =<< text (mkErrorMsg i)
        []      -> checkClashingImports is
     where
        isClashing (Import _ as' p' q' _) = (as' == as) && (p' /= p) && (q' == q)
        mkErrorMsg (Import _ _ p' q' _) =
             "Clashing import: " ++ pp q ++ " (both from "
          ++ prettyShow (pp <$> p) ++ " and "
          ++ prettyShow (pp <$> p') ++ ")"
        -- TODO: no range information as we only have Haskell names at this point

-- if the user has provided a "using" or "hiding" list in the config file
-- used for Prelude
makeManualDecl :: Hs.ModuleName () -> Qualifier -> Bool -> [String] -> Hs.ImportDecl ()
makeManualDecl mod qual isImplicit namesToHide = Hs.ImportDecl ()
       mod (isQualified qual) False False Nothing (qualifiedAs qual)
      (Just $ Hs.ImportSpecList ()
            isImplicit        -- whether the list should be a list of hidden identifiers ('hiding')
            $ map (Hs.IVar() . (\str -> if validVarId str || validConId str then Hs.Ident() str else Hs.Symbol() str))    -- since we can only read strings from the config file, we have to do this
            namesToHide) -- map (uncurry makeImportSpec) $ Map.toList specs)
