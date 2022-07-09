#!/usr/bin/env stack
-- stack script --resolver lts-16.11 --package bytestring --package vector

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE MultiWayIf #-}

module Main (main) where

import Control.Monad
import qualified Data.ByteString.Builder as BSB
import qualified Data.ByteString.Char8 as BS
import Data.Char
import Data.List
import Data.Maybe
import Data.Ord
import qualified Data.Vector.Fusion.Bundle as VFB
import qualified Data.Vector.Generic as VG
import qualified Data.Vector.Unboxed as VU
import GHC.Event (IOCallback)
import GHC.Float (int2Float)
import System.IO

sortWith :: Ord o => (a -> o) -> [a] -> [a]
sortWith = sortBy . comparing

getLineInt :: IO Int
getLineInt = fst . fromJust . BS.readInt <$> BS.getLine

bsToInts :: BS.ByteString -> [Int]
bsToInts = unfoldr (BS.readInt . BS.dropWhile isSpace)

getLineInts :: IO [Int]
getLineInts = bsToInts <$> BS.getLine

{-# INLINE vLength #-}
vLength :: (VG.Vector v e) => v e -> Int
vLength = VFB.length . VG.stream

main :: IO ()
main = do
  s <- getLine
  t <- getLine

  if solve s t == True
    then putStrLn "Yes"
    else putStrLn "No"

solve :: String -> String -> Bool
solve s t = norm s == norm t
  where
    norm xs = normalize (head xs, 1) (tail xs) []

normalize :: (Char, Int) -> [Char] -> [(Char, Int)] -> [(Char, Int)]
normalize cur [] res = res ++ [cur]
normalize (c, len) (n : ns) res
  | c == n = normalize (c, (len + 1) `min` 2) ns res
  | otherwise = normalize (n, 1) ns (res ++ [(c, len)])
