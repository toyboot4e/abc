-- toy-lib: https://github.com/toyboot4e/toy-lib
{- ORMOLU_DISABLE -}
{-# OPTIONS_GHC -Wno-unused-imports -Wno-unused-top-binds -Wno-orphans #-}
{-# LANGUAGE BlockArguments, CPP, DataKinds, DefaultSignatures, DerivingVia, LambdaCase, MagicHash, MultiWayIf, NumDecimals, PatternSynonyms, QuantifiedConstraints, RecordWildCards, StandaloneDeriving, StrictData, TypeFamilies, ViewPatterns #-}
import Control.Applicative;import Control.DeepSeq;import Control.Exception (assert);import Control.Monad;import Control.Monad.Fix;import Control.Monad.IO.Class;import Control.Monad.Primitive;import Control.Monad.ST;import Control.Monad.State.Class;import Control.Monad.Trans (MonadTrans, lift);import Control.Monad.Trans.Cont;import Control.Monad.Trans.Maybe;import Control.Monad.Trans.State.Strict (State, StateT(..), evalState, evalStateT, execState, execStateT, runState, runStateT);import Data.Bifunctor;import Data.Bits;import Data.Bool (bool);import Data.Char;import Data.Coerce;import Data.Either;import Data.Foldable;import Data.Function (on);import Data.Functor;import Data.Functor.Identity;import Data.IORef;import Data.Kind;import Data.List.Extra hiding (nubOn);import Data.Maybe;import Data.Ord;import Data.Primitive.MutVar;import Data.Proxy;import Data.STRef;import Data.Semigroup;import Data.Word;import Debug.Trace;import GHC.Exts (proxy#);import GHC.Float (int2Float);import GHC.Ix (unsafeIndex);import GHC.Stack (HasCallStack);import GHC.TypeLits;import System.Exit (exitSuccess);import System.IO;import System.Random;import System.Random.Stateful;import Text.Printf;import Data.Ratio;import Data.Array.IArray;import Data.Array.IO;import Data.Array.MArray;import Data.Array.ST;import Data.Array.Unboxed (UArray);import Data.Array.Unsafe;import qualified Data.Array as A;import Data.Bit;import qualified Data.ByteString.Builder as BSB;import qualified Data.ByteString.Char8 as BS;import qualified Data.ByteString.Unsafe as BSU;import Control.Monad.Extra hiding (loop);import Data.IORef.Extra;import Data.List.Extra hiding (merge);import Data.Tuple.Extra hiding (first, second);import Numeric.Extra;import Data.Bool.HT;import qualified Data.Ix.Enum as HT;import qualified Data.List.HT as HT;import qualified Data.Vector.Fusion.Bundle as FB;import qualified Data.Vector.Generic as G;import qualified Data.Vector.Generic.Mutable as GM;import qualified Data.Vector.Primitive as P;import qualified Data.Vector.Unboxed as U;import qualified Data.Vector.Unboxed.Base as U;import qualified Data.Vector.Unboxed.Mutable as UM;import qualified Data.Vector as V;import qualified Data.Vector.Mutable as VM;import qualified Data.Vector.Fusion.Bundle.Monadic as MB;import qualified Data.Vector.Fusion.Bundle.Size as MB;import qualified Data.Vector.Fusion.Stream.Monadic as MS;import qualified Data.Vector.Algorithms.Merge as VAM;import qualified Data.Vector.Algorithms.Intro as VAI;import qualified Data.Vector.Algorithms.Radix as VAR;import qualified Data.Vector.Algorithms.Search as VAS;import qualified Data.IntMap.Strict as IM;import qualified Data.Map.Strict as M;import qualified Data.IntSet as IS;import qualified Data.Set as S;import qualified Data.Sequence as Seq;import qualified Data.Heap as H;import Data.Hashable;import qualified Data.HashMap.Strict as HM;import qualified Data.HashSet as HS;import qualified Test.QuickCheck as QC;import Unsafe.Coerce;
-- {{{ toy-lib import
import ToyLib.Contest.Prelude
-- import ToyLib.Contest.Bisect
-- import ToyLib.Contest.Graph
-- import ToyLib.Contest.Grid
-- import ToyLib.Contest.Tree

-- import Data.BitSet
-- import Data.Core.SemigroupAction
-- import Data.ModInt
-- import Data.PowMod
-- import Data.Primes

-- }}} toy-lib import
{-# RULES "Force inline VAI.sort" VAI.sort = VAI.sortBy compare #-}
#ifdef DEBUG
debug :: Bool ; debug = True
#else
debug :: Bool ; debug = False
#endif
{- ORMOLU_ENABLE -}

dir :: Char -> Int -> (Int, Int)
-- y axis.. why, atcoder
dir 'U' !d = (d, 0)
dir 'D' !d = (-d, 0)
dir 'L' !d = (0, -d)
dir 'R' !d = (0, d)
dir _ _ = error "unreachable"

-- splitIn :: Int -> Int -> IM.IntMap a -> IM.IntMap a
-- splitIn l r im =
--   let (!_, !im') = IM.split (l - 1) im
--       (!im'', !_) = IM.split (r + 1) im'
--    in im''

deleteIn :: Int -> Int -> IS.IntSet -> IS.IntSet
deleteIn l__ r__ im0 = inner im0
  where
    !l = min l__ r__
    !r = max l__ r__
    inner im = case IS.lookupGE l im of
      Just i | i <= r -> inner $! IS.delete i im
      _ -> im

solve :: StateT BS.ByteString IO ()
solve = do
  (!n, !m, !x0, !y0) <- dbgId <$> ints4'
  -- (y, x) !!!!
  !pts <- U.replicateM n (swap <$> ints2')
  !moves <- U.replicateM m (dir <$> char' <*> int')

  let toLine :: ((Int, Int), (Int, Int)) -> Either (Int, (Int, Int)) (Int, (Int, Int))
      toLine ((!y1, !x1), (!y2, !x2))
        -- row
        | y1 == y2 = Left (y1, (x1, x2))
        -- column
        | x1 == x2 = Right (x1, (y1, y2))
        | otherwise = error "unreachable"

  let !rs0 :: IM.IntMap IS.IntSet = note "rs0" . IM.map IS.fromList . IM.fromListWith (++) . V.toList $ V.map (\(!y, !x) -> (y, [x])) $ U.convert pts
  let !cs0 :: IM.IntMap IS.IntSet = note "cs0" . IM.map IS.fromList . IM.fromListWith (++) . V.toList $ V.map (\(!y, !x) -> (x, [y])) $ U.convert pts

  let toLine' :: (Int, Int) -> (Int, Int) -> (Bool, Int, (Int, Int))
      toLine' (!y1, !x1) (!y2, !x2)
        -- row
        | y1 == y2 = (True, y1, (x1, x2))
        -- column
        | x1 == x2 = (False, x1, (y1, y2))
        | otherwise = error "unreachable"

  let points = dbgId $ U.scanl' add2 (y0, x0) moves
  let lines = U.zipWith toLine' points $ U.tail points
  let (!rs_, !cs_) = U.foldl' step s0 lines
        where
          s0 = (rs0, cs0)
          step :: (IM.IntMap IS.IntSet, IM.IntMap IS.IntSet) -> (Bool, Int, (Int, Int)) -> (IM.IntMap IS.IntSet, IM.IntMap IS.IntSet)
          step (!rs, !cs) (True, !y, (!x1, !x2)) = (rs', cs)
            where
              !rs' = IM.adjust (deleteIn x1 x2) y rs
              !_ = dbg ("delete r", y, (x1, x2))
          step (!rs, !cs) (False, !x, (!y1, !y2)) = (rs, cs')
            where
              !cs' = IM.adjust (deleteIn y1 y2) x cs
              !_ = dbg ("delete c", x, (y1, y2))

  let concatIM_row :: IM.IntMap IS.IntSet -> [(Int, Int)]
      concatIM_row im = concatMap (\(!k, !line) -> map (k,) $ IS.elems line) $ IM.assocs im
  let concatIM_col :: IM.IntMap IS.IntSet -> [(Int, Int)]
      concatIM_col im = concatMap (\(!k, !line) -> map (,k) $ IS.elems line) $ IM.assocs im

  let !_ = note "rs" rs_
  let !_ = note "cs" cs_
  let cnts = dbgId . M.fromListWith (+) . map (, 1 :: Int) $ concatIM_row rs_ ++ concatIM_col cs_
  let (!yEnd, !xEnd) = U.last points
  printBSB . (xEnd, yEnd,) . (n -) . length . filter (== 2) $ M.elems cnts

-- verification-helper: PROBLEM https://atcoder.jp/contests/abc385/tasks/abc385_d
main :: IO ()
main = runIO solve
