#!/usr/bin/env stack
-- stack script --resolver lts-16.31 --package bytestring --package vector

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE MultiWayIf #-}

module Main (main) where

import Control.Applicative
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
-- import GHC.Exts (sortWith)
import System.IO
import Text.Printf

-- Option - Maybe cheatsheet
-- https://notes.iveselov.info/programming/cheatsheet-rust-option-vs-haskell-maybe

-- - filter_map = mapMaybe

safeHead :: [a] -> Maybe a
safeHead []     = Nothing
safeHead (a:as) = Just a

safeTail :: [a] -> Maybe [a]
safeTail []     = Nothing
safeTail (a:as) = Just as

sortWith :: Ord o => (a -> o) -> [a] -> [a]
-- sortWith = sortBy . comparing
sortWith = sortOn . comparing

sortWithDesc :: Ord o => (a -> o) -> [a] -> [a]
sortWithDesc = sortBy . flip . comparing

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
  xs <- getLineInts
  print $ solve xs

solve :: [Int] -> Int
solve xs = undefined
