import           AbsCppGrammar
import           CodeGen
import           Control.Monad.State
import           ParCppGrammar       (myLexer, pProgram)
import           System.Environment  (getArgs)
import           System.Exit         (exitFailure)
import           TypeChecker         (typecheckAndTransform)

testCompiler :: String -> IO ()
testCompiler input = do
  putStrLn "=== Testeando todo el flujo del compilador ==="
  putStrLn $ "Input: " ++ input
  putStrLn ""
  case pProgram (myLexer input) of
    Left err -> do
      putStrLn $ "Parsing Error: " ++ err
      exitFailure
    Right program -> do
      putStrLn "[OK] Parsing exitoso"
      putStrLn $ "AST: " ++ show program
      putStrLn ""
      case typecheckAndTransform program of
        Left typeErr -> do
          putStrLn $ "TypeChecking Error: " ++ typeErr
          exitFailure
        Right typedProgram -> do
          putStrLn "[OK] Type checking exitoso"
          putStrLn $ "Typed AST: " ++ show typedProgram
          putStrLn ""
          let generatedCode = compile "TestClass" typedProgram
          putStrLn "[OK] Code generation exitoso"
          putStrLn "JVM bytecode generado:"
          putStrLn "========================"
          putStrLn (unlines generatedCode)

testCases :: [String]
testCases =
  [ "int main() { return 0; }"
  , "int main() { int x = 5; return x; }"
  , "int factorial(int n) { if (n <= 1) return 1; else return n * factorial(n-1); } int main() { return factorial(5); }"
  ]

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> do
      putStrLn "Running built-in test cases...\n"
      mapM_
        (\(i, test) -> do
           putStrLn $ "=== Test Case " ++ show i ++ " ==="
           testCompiler test
           putStrLn $ "\n" ++ replicate 60 '='
           putStrLn "")
        (zip [1 ..] testCases)
    [filename] -> do
      content <- readFile filename
      testCompiler content
    _ -> putStrLn "Usage: TestCompiler [filename]"
