{-# LANGUAGE CPP #-}

module Main where

import           Control.Monad      (when)
import           System.Environment (getArgs)
import           System.Exit        (exitFailure)

import           AbsCppGrammar
import           ErrM
import           LexCppGrammar      (Token, mkPosToken)
import           ParCppGrammar      (myLexer, pProgram)
import           PrintCppGrammar    (Print, printTree)
import           TypeChecker

type ParseFun a = [Token] -> Err a

-- | Parse and type check a program from a string
testTypeChecker :: String -> IO ()
testTypeChecker s =
  case pProgram (myLexer s) of
    Bad err -> do
      putStrLn "PARSE ERROR:"
      putStrLn err
      exitFailure
    Ok tree -> do
      putStrLn "PARSE OK"
      putStrLn $ "Abstract Syntax Tree:\n" ++ show tree
      putStrLn $ "Linearized:\n" ++ printTree tree
      putStrLn "\nTYPE CHECKING:"
      case typecheck tree of
        Bad err -> do
          putStrLn "TYPE ERROR:"
          putStrLn err
          exitFailure
        Ok _ -> do
          putStrLn "TYPE CHECK OK"
          putStrLn "Program is well-typed!"

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> do
      putStrLn "Reading from stdin..."
      getContents >>= testTypeChecker
    [file] -> do
      putStrLn $ "Reading from file: " ++ file
      readFile file >>= testTypeChecker
    _ -> do
      putStrLn "Usage: TestTypeChecker [file]"
      exitFailure
