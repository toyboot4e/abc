-- toy-lib: https://github.com/toyboot4e/toy-lib
{- ORMOLU_DISABLE -}
{-# OPTIONS_GHC -Wno-unused-imports -Wno-unused-top-binds -Wno-orphans #-}
{-# LANGUAGE BlockArguments, CPP, DataKinds, DefaultSignatures, DerivingVia, LambdaCase, MagicHash, MultiWayIf, NumDecimals, PatternSynonyms, QuantifiedConstraints, RecordWildCards, StandaloneDeriving, StrictData, TypeFamilies, ViewPatterns #-}
import Control.Applicative;import Control.DeepSeq;import Control.Exception (assert);import Control.Monad;import Control.Monad.Fix;import Control.Monad.IO.Class;import Control.Monad.Primitive;import Control.Monad.ST;import Control.Monad.State.Class;import Control.Monad.Trans (MonadTrans, lift);import Control.Monad.Trans.Cont;import Control.Monad.Trans.Maybe;import Control.Monad.Trans.State.Strict (State, StateT(..), evalState, evalStateT, execState, execStateT, runState, runStateT);import Data.Bifunctor;import Data.Bits;import Data.Bool (bool);import Data.Char;import Data.Coerce;import Data.Either;import Data.Foldable;import Data.Function (on);import Data.Functor;import Data.Functor.Identity;import Data.IORef;import Data.Kind;import Data.List.Extra hiding (nubOn);import Data.Maybe;import Data.Ord;import Data.Primitive.MutVar;import Data.Proxy;import Data.STRef;import Data.Semigroup;import Data.Word;import Debug.Trace;import GHC.Exts (proxy#);import GHC.Float (int2Float);import GHC.Ix (unsafeIndex);import GHC.Stack (HasCallStack);import GHC.TypeLits;import System.Exit (exitSuccess);import System.IO;import System.Random;import System.Random.Stateful;import Text.Printf;import Data.Ratio;import Data.Array.IArray;import Data.Array.IO;import Data.Array.MArray;import Data.Array.ST;import Data.Array.Unboxed (UArray);import Data.Array.Unsafe;import qualified Data.Array as A;import Data.Bit;import qualified Data.ByteString.Builder as BSB;import qualified Data.ByteString.Char8 as BS;import qualified Data.ByteString.Unsafe as BSU;import Control.Monad.Extra hiding (loop);import Data.IORef.Extra;import Data.List.Extra hiding (merge);import Data.Tuple.Extra hiding (first, second);import Numeric.Extra;import Data.Bool.HT;import qualified Data.Ix.Enum as HT;import qualified Data.List.HT as HT;import qualified Data.Vector.Fusion.Bundle as FB;import qualified Data.Vector.Generic as G;import qualified Data.Vector.Generic.Mutable as GM;import qualified Data.Vector.Primitive as P;import qualified Data.Vector.Unboxed as U;import qualified Data.Vector.Unboxed.Base as U;import qualified Data.Vector.Unboxed.Mutable as UM;import qualified Data.Vector as V;import qualified Data.Vector.Mutable as VM;import qualified Data.Vector.Fusion.Bundle.Monadic as MB;import qualified Data.Vector.Fusion.Bundle.Size as MB;import qualified Data.Vector.Fusion.Stream.Monadic as MS;import qualified Data.Vector.Algorithms.Merge as VAM;import qualified Data.Vector.Algorithms.Intro as VAI;import qualified Data.Vector.Algorithms.Radix as VAR;import qualified Data.Vector.Algorithms.Search as VAS;import qualified Data.IntMap.Strict as IM;import qualified Data.Map.Strict as M;import qualified Data.IntSet as IS;import qualified Data.Set as S;import qualified Data.Sequence as Seq;import qualified Data.Heap as H;import Data.Hashable;import qualified Data.HashMap.Strict as HM;import qualified Data.HashSet as HS;import qualified Test.QuickCheck as QC;import Unsafe.Coerce;
import Data.Time
-- {{{ toy-lib import
import ToyLib.Contest.Prelude
-- import ToyLib.Contest.Bisect
-- import ToyLib.Contest.Graph
-- import ToyLib.Contest.Grid
-- import ToyLib.Contest.Tree

import Data.Buffer
import Data.BinaryHeap
-- import Data.BitSet
-- import Data.Core.SemigroupAction
-- import Data.ModInt
-- import Data.PowMod
-- import Data.Primes
import Data.Vector.Extra

-- }}} toy-lib import
{-# RULES "Force inline VAI.sort" VAI.sort = VAI.sortBy compare #-}
#ifdef DEBUG
debug :: Bool ; debug = True
#else
debug :: Bool ; debug = False
#endif
{- ORMOLU_ENABLE -}

eval :: (PrimMonad m) => Int -> U.Vector Int -> U.Vector (Int, Int) -> m (Int, U.Vector (Int, Int, Int, Int))
eval n xDict xys = do
  buf <- newBuffer @(Int, Int, Int, Int) (G.length xys)
  candidates <- UM.replicate (G.length xDict) (-1 :: Int)
  GM.write candidates 0 0

  -- scan per row
  cost <- (`execStateT` (0 :: Int)) $ U.forM_ xys $ \(!x, !y) -> do
    candidates' <- U.unsafeFreeze candidates
    let (!minCost, (!xf, !yf)) =
          U.foldl'
            ( \sofar@(!cost, !_) (!xFrom, !yFrom) -> do
                let !dx = abs $ x - xFrom
                let !dy = abs $ y - yFrom
                if yFrom /= -1 && xFrom <= x && (dx + dy) < cost
                  then (dx + dy, (xFrom, yFrom))
                  else sofar
            )
            (maxBound @Int, (-1, -1))
            $ U.zip xDict candidates'
    pushBack buf (xf, yf, x, y)
    GM.write candidates (bindex xDict x) y
    modify' (+ minCost)

  buf' <- unsafeFreezeBuffer buf
  return (cost, buf')

withRandomPoints :: Int -> U.Vector Int -> U.Vector Int -> S.Set (Int, Int) -> IO (S.Set (Int, Int))
withRandomPoints n xDict yDict set0 = do
  let inner :: S.Set (Int, Int) -> Int -> Int -> IO (S.Set (Int, Int))
      inner set 0 abort = return set
      inner set _ abort | abort >= 50 = return set
      inner set nRest abort = do
        x <- (xDict G.!) <$> randomRIO (0, G.length xDict - 1)
        y <- (yDict G.!) <$> randomRIO (0, G.length yDict - 1)
        if S.notMember (x, y) set
          then inner (S.insert (x, y) set) (nRest - 1) 0
          else inner set nRest (abort + 1)

  inner set0 (min (4 * n) (G.length xDict * G.length yDict - n)) 0

nStep :: Int
nStep = 10

addPoint :: Int -> U.Vector Int -> U.Vector Int -> S.Set (Int, Int) -> IO (S.Set (Int, Int))
addPoint n xDict yDict set0 = do
  let add :: S.Set (Int, Int) -> Int -> Int -> IO (S.Set (Int, Int))
      add set 0 abort = return set
      add set _ abort | abort >= 200 = return set
      add set nRest abort = do
        x <- (xDict G.!) <$> randomRIO (0, G.length xDict - 1)
        y <- (yDict G.!) <$> randomRIO (0, G.length yDict - 1)
        if S.notMember (x, y) set
          then add (S.insert (x, y) set) (nRest - 1) 0
          else add set nRest (abort + 1)

  add set0 nStep 0

-- withTimeLimit :: (MonadIO m) => a -> (m a -> m a) -> m ()
-- withTimeLimit s0 f = do
--   !time0 <- liftIO getCurrentTime
--   let loop f = do
--         !time <- liftIO getCurrentTime
--         let !diffSecs = nominalDiffTimeToSeconds $ diffUTCTime time time0
--         when (diffSecs < 1800) $ do
--           f loop
--   f loop

addSeqPoint :: Seq.Seq (Int, Int) -> IO ([(Int, Int)], Seq.Seq (Int, Int))
addSeqPoint seq0 = do
  let add !acc !seq 0 = return (acc, seq)
      add !acc !seq !nRest = do
        i <- randomRIO (0, Seq.length seq - 1)
        let (!x, !y) = Seq.index seq i
        let !seq' = Seq.deleteAt i seq
        add ((x, y) : acc) seq' (nRest - 1)

  add [] seq0 nStep

solve :: StateT BS.ByteString IO ()
solve = do
  !time0 <- liftIO getCurrentTime
  !n <- int'
  !xsOrg <- U.replicateM n ints2'

  let !xDict = U.modify VAI.sort $ U.cons 0 $ U.map fst xsOrg
  let !yDict = U.modify VAI.sort $ U.cons 0 $ U.map snd xsOrg
  let !w = G.length xDict
  let !h = G.length yDict

  let !set0 = S.fromList $ U.toList xsOrg
  let !row =
        V.accumulate (flip IS.insert) (V.replicate h IS.empty)
          . U.convert
          $ U.map (\(!x, !y) -> (bindex yDict y, x)) xsOrg
  let !col =
        V.accumulate (flip IS.insert) (V.replicate h IS.empty)
          . U.convert
          $ U.map (\(!x, !y) -> (bindex xDict x, y)) xsOrg

  let p ix iy x y = isJust $ do
        !x' <- IS.lookupGT x (row G.! iy)
        !y' <- IS.lookupGT y (col G.! ix)
        let !dx = x' - x
        let !dy = y' - y
        -- guard $ dx <= 100000 && dy <= 100000
        Just ()

  let !candidates = Seq.fromList
        . U.toList
        . (`U.mapMaybe` U.generate (G.length xDict * G.length yDict) id)
        $ \i ->
          let (!ix, !iy) = i `divMod` G.length yDict
              !x = xDict G.! ix
              !y = yDict G.! iy
           in if S.notMember (x, y) set0 && p ix iy x y
                then Just (x, y)
                else Nothing

  let !_ = dbg ("n cands", Seq.length candidates)

  let !xys = U.modify (VAI.sortBy (comparing swap)) xsOrg
  (!cost0, !commands0) <- eval n xDict xys

  xysBuf <- newBuffer (5 * n)
  pushBacks xysBuf xys

  let run nSofar cost cmd seq = do
        !time <- liftIO getCurrentTime
        let !diffSecs = nominalDiffTimeToSeconds $ diffUTCTime time time0
        if diffSecs > 1.92 || nSofar + nStep > 5 * n || Seq.length seq < nStep
          then return cmd
          else do
            (!adds, !seq') <- liftIO $ addSeqPoint seq
            pushBacks xysBuf $ U.fromList adds
            !xys' <- unsafeFreezeBuffer xysBuf
            (!cost', !cmds') <- eval n xDict $ U.modify (VAI.sortBy (comparing swap)) xys'
            if True || cost' < cost
              then do
                -- let !_ = dbg ("got!!", cost')
                run (nSofar + nStep) cost' cmds' seq'
              else do
                -- let !_ = dbg ("failed", cost')
                popBackN_ xysBuf nStep
                run nSofar cost cmd seq

  commands <- run n cost0 commands0 candidates

  printBSB $ G.length commands
  putBSB $ unlinesBSB commands
  let !_ = dbg ("done", G.length xsOrg, G.length commands)
  return ()

-- verification-helper: PROBLEM https://atcoder.jp/contests/ahc037/tasks/ahc037_a
main :: IO ()
main = runIO solve
