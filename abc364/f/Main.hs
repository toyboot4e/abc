-- toy-lib: https://github.com/toyboot4e/toy-lib
{- ORMOLU_DISABLE -}
{-# OPTIONS_GHC -Wno-unused-imports -Wno-unused-top-binds -Wno-orphans #-}
{-# LANGUAGE BlockArguments, CPP, DataKinds, DefaultSignatures, DerivingVia, LambdaCase, MagicHash, MultiWayIf, NumDecimals, PatternSynonyms, QuantifiedConstraints, RecordWildCards, StandaloneDeriving, StrictData, TypeFamilies, ViewPatterns #-}
import Control.Applicative;import Control.DeepSeq;import Control.Exception (assert);import Control.Monad;import Control.Monad.Fix;import Control.Monad.IO.Class;import Control.Monad.Primitive;import Control.Monad.ST;import Control.Monad.State.Class;import Control.Monad.Trans (MonadTrans, lift);import Control.Monad.Trans.Cont;import Control.Monad.Trans.Maybe;import Control.Monad.Trans.State.Strict (State, StateT(..), evalState, evalStateT, execState, execStateT, runState, runStateT);import Data.Bifunctor;import Data.Bits;import Data.Bool (bool);import Data.Char;import Data.Coerce;import Data.Either;import Data.Foldable;import Data.Function (on);import Data.Functor;import Data.Functor.Identity;import Data.IORef;import Data.Kind;import Data.List.Extra hiding (nubOn);import Data.Maybe;import Data.Ord;import Data.Primitive.MutVar;import Data.Proxy;import Data.STRef;import Data.Semigroup;import Data.Word;import Debug.Trace;import GHC.Exts (proxy#);import GHC.Float (int2Float);import GHC.Ix (unsafeIndex);import GHC.Stack (HasCallStack);import GHC.TypeLits;import System.Exit (exitSuccess);import System.IO;import System.Random;import System.Random.Stateful;import Text.Printf;import Data.Ratio;import Data.Array.IArray;import Data.Array.IO;import Data.Array.MArray;import Data.Array.ST;import Data.Array.Unboxed (UArray);import Data.Array.Unsafe;import qualified Data.Array as A;import Data.Bit;import qualified Data.ByteString.Builder as BSB;import qualified Data.ByteString.Char8 as BS;import qualified Data.ByteString.Unsafe as BSU;import Control.Monad.Extra hiding (loop);import Data.IORef.Extra;import Data.List.Extra hiding (merge);import Data.Tuple.Extra hiding (first, second);import Numeric.Extra;import Data.Bool.HT;import qualified Data.Ix.Enum as HT;import qualified Data.List.HT as HT;import qualified Data.Vector.Fusion.Bundle as FB;import qualified Data.Vector.Generic as G;import qualified Data.Vector.Generic.Mutable as GM;import qualified Data.Vector.Primitive as P;import qualified Data.Vector.Unboxed as U;import qualified Data.Vector.Unboxed.Base as U;import qualified Data.Vector.Unboxed.Mutable as UM;import qualified Data.Vector as V;import qualified Data.Vector.Mutable as VM;import qualified Data.Vector.Fusion.Bundle.Monadic as MB;import qualified Data.Vector.Fusion.Bundle.Size as MB;import qualified Data.Vector.Fusion.Stream.Monadic as MS;import qualified Data.Vector.Algorithms.Merge as VAM;import qualified Data.Vector.Algorithms.Intro as VAI;import qualified Data.Vector.Algorithms.Search as VAS;import qualified Data.IntMap.Strict as IM;import qualified Data.Map.Strict as M;import qualified Data.IntSet as IS;import qualified Data.Set as S;import qualified Data.Sequence as Seq;import qualified Data.Heap as H;import Data.Hashable;import qualified Data.HashMap.Strict as HM;import qualified Data.HashSet as HS;import qualified Test.QuickCheck as QC
-- {{{ toy-lib import
import ToyLib.Contest.Prelude
-- import ToyLib.Contest.Bisect
-- import ToyLib.Contest.Graph
-- import ToyLib.Contest.Grid
-- import ToyLib.Contest.Tree
-- import Data.BitSet
import Data.Core.SemigroupAction
import Data.SegmentTree.Lazy
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

-- | Set
type OpRepr = Int

undef = -1 :: Int

instance Semigroup Op where
  -- @new <> old@ on segment tree
  {-# INLINE (<>) #-}
  x1 <> x2
    | x1 == mempty = x2
    | x2 == mempty = x1
    | otherwise = x1

instance Monoid Op where
  {-# INLINE mempty #-}
  mempty = Op undef

instance SemigroupAction Op Acc where
  {-# INLINE sact #-}
  sact (Op !dx) a@(Acc (!_, !len))
    | dx == undef = a
    | otherwise = Acc (dx * len, len)

-- (Sum, Len)
type AccRepr = (Int, Int)

instance Semigroup Acc where
  {-# INLINE (<>) #-}
  (Acc !x1) <> (Acc !x2) = Acc (x1 `add2` x2)

instance Monoid Acc where
  {-# INLINE mempty #-}
  mempty = Acc (0, 0)

{- ORMOLU_DISABLE -}
newtype Acc = Acc AccRepr deriving newtype (Eq, Ord, Show) ; unAcc :: Acc -> AccRepr ; unAcc (Acc x) = x ; newtype instance U.MVector s Acc = MV_Acc (U.MVector s AccRepr) ; newtype instance U.Vector Acc = V_Acc (U.Vector AccRepr) ; deriving instance GM.MVector UM.MVector Acc ; deriving instance G.Vector U.Vector Acc ; instance U.Unbox Acc ;
newtype Op = Op OpRepr deriving newtype (Eq, Ord, Show) ; unOp :: Op -> OpRepr ; unOp (Op x) = x; newtype instance U.MVector s Op = MV_Op (U.MVector s OpRepr) ; newtype instance U.Vector Op = V_Op (U.Vector OpRepr) ; deriving instance GM.MVector UM.MVector Op ; deriving instance G.Vector U.Vector Op ; instance U.Unbox Op ;
{- ORMOLU_ENABLE -}

solve :: StateT BS.ByteString IO ()
solve = do
  (!n, !q) <- ints2'
  !lrcs <- U.modify (VAI.sortBy (comparing (Down . thd3))) <$> U.replicateM q ints110'

  stree <- buildLSTree $ U.replicate n (Acc (0, 1))
  U.forM_ lrcs $ \(!l, !r, !c) -> do
    sactLSTree stree l r $ Op c

  -- TODO: freeze method
  xs <- U.generateM n $ fmap (fst . unAcc) . readLSTree stree
  if U.any (== undef) xs
    then printBSB "-1"
    else printBSB . fst . unAcc =<< foldLSTree stree 0 (n - 1)

-- verification-helper: PROBLEM https://atcoder.jp/contests/abc364/tasks/abc364_f
main :: IO ()
main = runIO solve
