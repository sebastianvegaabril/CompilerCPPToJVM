module CodeGen where

import           AbsCppGrammar
import           Env
import           ErrM

import           Control.Monad
import           Control.Monad.State.Lazy
import qualified Data.Map                 as Map

type Instruction = String

type FunType = String

type Label = Int

data CodeGenState = CodeGenState
  { cgsVarIndices   :: Map.Map Id Int
  , cgsNextIndex    :: Int
  , cgsLabelCounter :: Int
  , cgsInstructions :: [Instruction]
  , cgsClassName    :: String
  , cgsFunctions    :: Map.Map String ([Type], Type)
  } deriving (Show)

emptyCodeGenState :: CodeGenState
emptyCodeGenState =
  CodeGenState
    { cgsVarIndices = Map.empty
    , cgsNextIndex = 0
    , cgsLabelCounter = 0
    , cgsInstructions = []
    , cgsClassName = ""
    , cgsFunctions = Map.empty
    }

initCodeGenState :: String -> CodeGenState
initCodeGenState className = emptyCodeGenState {cgsClassName = className}

extractFunctionSignature :: Def -> (String, ([Type], Type))
extractFunctionSignature (DFun returnType (Id name) args _) =
  (name, (map (\(ADecl argType _) -> argType) args, returnType))

registerFunction :: String -> ([Type], Type) -> State CodeGenState ()
registerFunction name signature = do
  state <- get
  put state {cgsFunctions = Map.insert name signature (cgsFunctions state)}

emit :: Instruction -> State CodeGenState ()
emit instruction =
  modify $ \state ->
    state {cgsInstructions = cgsInstructions state ++ [instruction]}

typeSize :: Type -> Int
typeSize Type_double = 2
typeSize _           = 1

typeToJVM :: Type -> String
typeToJVM Type_int    = "I"
typeToJVM Type_double = "D"
typeToJVM Type_void   = "V"
typeToJVM Type_bool   = "Z"
typeToJVM Type_string = "Ljava/lang/String;"

methodSignature :: String -> [Type] -> Type -> String
methodSignature name argTypes returnType =
  name ++ "(" ++ concatMap typeToJVM argTypes ++ ")" ++ typeToJVM returnType

invokeStatic :: String -> String -> [Type] -> Type -> String
invokeStatic methodName className argTypes returnType =
  "invokestatic "
    ++ className
    ++ "/"
    ++ methodSignature methodName argTypes returnType

allocateVariable :: Type -> Id -> State CodeGenState Int
allocateVariable varType varId = do
  state <- get
  let currentIndex = cgsNextIndex state
  put
    state
      { cgsVarIndices = Map.insert varId currentIndex (cgsVarIndices state)
      , cgsNextIndex = currentIndex + typeSize varType
      }
  return currentIndex

lookupVariableIndex :: Id -> State CodeGenState Int
lookupVariableIndex varId = do
  state <- get
  case Map.lookup varId (cgsVarIndices state) of
    Just index -> return index
    Nothing -> error $ "Variable not found in code generation: " ++ show varId

newLabel :: State CodeGenState String
newLabel = do
  state <- get
  let counter = cgsLabelCounter state
  put state {cgsLabelCounter = counter + 1}
  return $ "L" ++ show counter

constantNameToId :: ConstantName -> Id
constantNameToId (CNIdentifier i) = i

constantNamesToId :: [ConstantName] -> Id
constantNamesToId []       = Id ""
constantNamesToId (name:_) = constantNameToId name

builtinFunctions :: [(String, ([Type], Type))]
builtinFunctions =
  [ ("printInt", ([Type_int], Type_void))
  , ("printDouble", ([Type_double], Type_void))
  , ("printString", ([Type_string], Type_void))
  , ("readInt", ([], Type_int))
  , ("readDouble", ([], Type_double))
  ]

getBuiltinSignature :: String -> String
getBuiltinSignature name =
  case lookup
         name
         [ (n, invokeStatic n "Runtime" args ret)
         | (n, (args, ret)) <- builtinFunctions
         ] of
    Just sig -> sig
    Nothing  -> error $ "Unknown built-in function: " ++ name

compile :: String -> Program -> [Instruction]
compile className program =
  cgsInstructions
    $ execState (compileProgram program) (initCodeGenState className)

compileProgram :: Program -> State CodeGenState ()
compileProgram (PDefs definitions) = do
  state <- get
  let className = cgsClassName state
  -- Register all function signatures first
  mapM_
    (\def ->
       let (name, sig) = extractFunctionSignature def
        in registerFunction name sig)
    definitions
  -- Emit class header
  emit $ ".class public " ++ className
  emit $ ".super java/lang/Object"
  emit ""
  -- Emit default constructor
  emit $ ".method public <init>()V"
  emit "  aload_0"
  emit "  invokenonvirtual java/lang/Object/<init>()V"
  emit "  return"
  emit ".end method"
  emit ""
  -- Compile all definitions
  mapM_ compileDefinition definitions

-- | Compile function definition
compileDefinition :: Def -> State CodeGenState ()
compileDefinition (DFun returnType (Id methodName) args body) = do
  modify $ \state -> state {cgsVarIndices = Map.empty, cgsNextIndex = 0}
  if methodName == "main"
    then do
      emit ".method public static main([Ljava/lang/String;)V"
      _ <- allocateVariable Type_string (Id "args")
      return ()
    else do
      let argTypes = map (\(ADecl t _) -> t) args
          signature = methodSignature methodName argTypes returnType
      emit $ ".method public static " ++ signature
  emit ".limit locals 1000" -- Son bastante conservadores los limites, se podria ser mas preciso
  emit ".limit stack 1000" -- Son bastante conservadores los limites, se podria ser mas preciso
  mapM_ (\(ADecl argType argId) -> allocateVariable argType argId) args
  compileBody body
  emit ".end method"
  emit ""

emitReturn :: Type -> State CodeGenState ()
emitReturn Type_double = emit "dreturn"
emitReturn Type_string = emit "areturn"
emitReturn Type_void   = emit "return"
emitReturn _           = emit "ireturn"

compileBody :: Body -> State CodeGenState ()
compileBody (Body1 statements) = mapM_ compileStatement statements
compileBody Body2              = return ()

compileStatement :: Stm -> State CodeGenState ()
compileStatement (SBlock statements) = mapM_ compileStatement statements
compileStatement (SIfElse (ETyped condition condType) thenStmt elseStmt) = do
  elseLabel <- newLabel
  endLabel <- newLabel
  compileExpression (ETyped condition condType)
  emit $ "ifeq " ++ elseLabel
  compileStatement thenStmt
  emit $ "goto " ++ endLabel
  emit $ elseLabel ++ ":"
  compileStatement elseStmt
  emit $ endLabel ++ ":"
compileStatement (SIf (ETyped condition condType) stmt) = do
  endLabel <- newLabel
  compileExpression (ETyped condition condType)
  emit $ "ifeq " ++ endLabel
  compileStatement stmt
  emit $ endLabel ++ ":"
compileStatement (SWhile (ETyped condition condType) stmt) = do
  startLabel <- newLabel
  endLabel <- newLabel
  emit $ startLabel ++ ":"
  compileExpression (ETyped condition condType)
  emit $ "ifeq " ++ endLabel
  compileStatement stmt
  emit $ "goto " ++ startLabel
  emit $ endLabel ++ ":"
compileStatement (SDoWhile stmt (ETyped condition condType)) = do
  startLabel <- newLabel
  emit $ startLabel ++ ":"
  compileStatement stmt
  compileExpression (ETyped condition condType)
  emit $ "ifne " ++ startLabel
compileStatement (SExp (ETyped expression exprType)) = do
  compileExpression (ETyped expression exprType)
  case exprType of
    Type_double -> emit "pop2"
    Type_void   -> return ()
    _           -> emit "pop"
compileStatement (SReturn (ETyped expression exprType)) = do
  compileExpression (ETyped expression exprType)
  case exprType of
    Type_double -> emit "dreturn"
    Type_string -> emit "areturn"
    _           -> emit "ireturn"
compileStatement (SReturnVal (ETyped expression exprType)) = do
  compileExpression (ETyped expression exprType)
  case exprType of
    Type_double -> emit "dreturn"
    Type_string -> emit "areturn"
    _           -> emit "ireturn"
compileStatement SReturnVoid = emit "return"
compileStatement SEmpty = return ()
compileStatement (SDecls (XDecl varType idSpecs _)) = do
  mapM_ (allocateVarSpec varType) idSpecs
  where
    allocateVarSpec :: Type -> IdSpec -> State CodeGenState ()
    allocateVarSpec t (IdSpecId i) = do
      _ <- allocateVariable t i
      return ()
    allocateVarSpec t (IdSpec1 i _) = do
      _ <- allocateVariable t i
      return ()
compileStatement (SInit varType varId (ETyped expression exprType)) = do
  compileExpression (ETyped expression exprType)
  index <- allocateVariable varType varId
  emitStore varType index
compileStatement stmt = error $ "Untyped statement encountered: " ++ show stmt

compileExpression :: Exp -> State CodeGenState ()
compileExpression (ETyped expr exprType) = compileTypedExpression expr exprType
compileExpression expr =
  error $ "Untyped expression not supported: " ++ show expr

compileTypedExpression :: Exp -> Type -> State CodeGenState ()
compileTypedExpression ETrue _ = emit "iconst_1"
compileTypedExpression EFalse _ = emit "iconst_0"
compileTypedExpression (EInt value) _ = emit $ "ldc " ++ show value
compileTypedExpression (EDouble value) _ = emit $ "ldc2_w " ++ show value
compileTypedExpression (EString strings) _ =
  emit $ "ldc \"" ++ concat strings ++ "\""
compileTypedExpression (EId varNames) exprType = do
  let varId = constantNamesToId varNames
  index <- lookupVariableIndex varId
  emitLoad exprType index
compileTypedExpression (EApp (EId functionNames) args) _ = do
  let functionId = constantNamesToId functionNames
      (Id functionName) = functionId
  -- Compile arguments
  mapM_ compileExpression args
  -- Emit function call
  if functionName `elem` map fst builtinFunctions
    then emit $ getBuiltinSignature functionName
    else do
      state <- get
      let className = cgsClassName state
      case Map.lookup functionName (cgsFunctions state) of
        Just (argTypes, returnType) -> do
          let signature = methodSignature functionName argTypes returnType
          emit $ "invokestatic " ++ className ++ "/" ++ signature
        Nothing -> error $ "Unknown function: " ++ functionName
compileTypedExpression (EPlus (ETyped expr1 type1) (ETyped expr2 type2)) exprType = do
  compileExpression (ETyped expr1 type1)
  compileExpression (ETyped expr2 type2)
  case exprType of
    Type_int    -> emit "iadd"
    Type_double -> emit "dadd"
    Type_string -> emit $ getBuiltinSignature "concatStr"
    _           -> error $ "Addition not supported for type: " ++ show exprType
compileTypedExpression (EMinus (ETyped expr1 type1) (ETyped expr2 type2)) exprType = do
  compileExpression (ETyped expr1 type1)
  compileExpression (ETyped expr2 type2)
  case exprType of
    Type_int -> emit "isub"
    Type_double -> emit "dsub"
    _ -> error $ "Subtraction not supported for type: " ++ show exprType
compileTypedExpression (ETimes (ETyped expr1 type1) (ETyped expr2 type2)) exprType = do
  compileExpression (ETyped expr1 type1)
  compileExpression (ETyped expr2 type2)
  case exprType of
    Type_int -> emit "imul"
    Type_double -> emit "dmul"
    _ -> error $ "Multiplication not supported for type: " ++ show exprType
compileTypedExpression (EDiv (ETyped expr1 type1) (ETyped expr2 type2)) exprType = do
  compileExpression (ETyped expr1 type1)
  compileExpression (ETyped expr2 type2)
  case exprType of
    Type_int    -> emit "idiv"
    Type_double -> emit "ddiv"
    _           -> error $ "Division not supported for type: " ++ show exprType
compileTypedExpression (ELt (ETyped expr1 type1) (ETyped expr2 type2)) _ =
  compileComparison "lt" expr1 type1 expr2 type2
compileTypedExpression (EGt (ETyped expr1 type1) (ETyped expr2 type2)) _ =
  compileComparison "gt" expr1 type1 expr2 type2
compileTypedExpression (ELtEq (ETyped expr1 type1) (ETyped expr2 type2)) _ =
  compileComparison "le" expr1 type1 expr2 type2
compileTypedExpression (EGtEq (ETyped expr1 type1) (ETyped expr2 type2)) _ =
  compileComparison "ge" expr1 type1 expr2 type2
compileTypedExpression (EEq (ETyped expr1 type1) (ETyped expr2 type2)) _ =
  compileComparison "eq" expr1 type1 expr2 type2
compileTypedExpression (ENEq (ETyped expr1 type1) (ETyped expr2 type2)) _ =
  compileComparison "ne" expr1 type1 expr2 type2
compileTypedExpression (EAnd (ETyped expr1 _) (ETyped expr2 _)) _ = do
  falseLabel <- newLabel
  endLabel <- newLabel
  compileExpression (ETyped expr1 Type_bool)
  emit $ "ifeq " ++ falseLabel
  compileExpression (ETyped expr2 Type_bool)
  emit $ "ifeq " ++ falseLabel
  emit "iconst_1"
  emit $ "goto " ++ endLabel
  emit $ falseLabel ++ ":"
  emit "iconst_0"
  emit $ endLabel ++ ":"
compileTypedExpression (EOr (ETyped expr1 _) (ETyped expr2 _)) _ = do
  trueLabel <- newLabel
  endLabel <- newLabel
  compileExpression (ETyped expr1 Type_bool)
  emit $ "ifne " ++ trueLabel
  compileExpression (ETyped expr2 Type_bool)
  emit $ "ifne " ++ trueLabel
  emit "iconst_0"
  emit $ "goto " ++ endLabel
  emit $ trueLabel ++ ":"
  emit "iconst_1"
  emit $ endLabel ++ ":"
compileTypedExpression (EAss (ETyped (EId varNames) _) (ETyped expr _)) exprType = do
  let varId = constantNamesToId varNames
  compileExpression (ETyped expr exprType)
  index <- lookupVariableIndex varId
  emitDuplicate exprType
  emitStore exprType index
compileTypedExpression (EIncr (EId varNames)) exprType = do
  let varId = constantNamesToId varNames
  index <- lookupVariableIndex varId
  compileIncrement index exprType True
compileTypedExpression (EDecr (EId varNames)) exprType = do
  let varId = constantNamesToId varNames
  index <- lookupVariableIndex varId
  compileDecrement index exprType True
compileTypedExpression (EPIncr (EId varNames)) exprType = do
  let varId = constantNamesToId varNames
  index <- lookupVariableIndex varId
  compileIncrement index exprType False
compileTypedExpression (EPDecr (EId varNames)) exprType = do
  let varId = constantNamesToId varNames
  index <- lookupVariableIndex varId
  compileDecrement index exprType False
compileTypedExpression (EAddAss (ETyped (EId varNames) _) (ETyped expr _)) exprType = do
  let varId = constantNamesToId varNames
  index <- lookupVariableIndex varId
  emitLoad exprType index
  compileExpression (ETyped expr exprType)
  case exprType of
    Type_int -> emit "iadd"
    Type_double -> emit "dadd"
    _ -> error $ "Add assignment not supported for type: " ++ show exprType
  emitDuplicate exprType
  emitStore exprType index
compileTypedExpression (ESubAss (ETyped (EId varNames) _) (ETyped expr _)) exprType = do
  let varId = constantNamesToId varNames
  index <- lookupVariableIndex varId
  emitLoad exprType index
  compileExpression (ETyped expr exprType)
  case exprType of
    Type_int -> emit "isub"
    Type_double -> emit "dsub"
    _ -> error $ "Subtract assignment not supported for type: " ++ show exprType
  emitDuplicate exprType
  emitStore exprType index
compileTypedExpression expr exprType =
  error
    $ "Unsupported expression: " ++ show expr ++ " with type: " ++ show exprType

compileComparison ::
     String -> Exp -> Type -> Exp -> Type -> State CodeGenState ()
compileComparison op expr1 type1 expr2 type2 = do
  trueLabel <- newLabel
  endLabel <- newLabel
  compileExpression (ETyped expr1 type1)
  compileExpression (ETyped expr2 type2)
  if type1 == Type_double && type2 == Type_double
    then compileDoubleComparison op trueLabel
    else compileIntComparison op trueLabel
  emit "iconst_0"
  emit $ "goto " ++ endLabel
  emit $ trueLabel ++ ":"
  emit "iconst_1"
  emit $ endLabel ++ ":"

compileDoubleComparison :: String -> String -> State CodeGenState ()
compileDoubleComparison op trueLabel = do
  case op of
    "lt" -> emit "dcmpg" >> emit ("iflt " ++ trueLabel)
    "gt" -> emit "dcmpg" >> emit ("ifgt " ++ trueLabel)
    "le" -> emit "dcmpl" >> emit ("ifle " ++ trueLabel)
    "ge" -> emit "dcmpl" >> emit ("ifge " ++ trueLabel)
    "eq" -> emit "dcmpl" >> emit ("ifeq " ++ trueLabel)
    "ne" -> emit "dcmpl" >> emit ("ifne " ++ trueLabel)
    _    -> error $ "Unknown comparison operator: " ++ op

compileIntComparison :: String -> String -> State CodeGenState ()
compileIntComparison op trueLabel = do
  case op of
    "lt" -> emit ("if_icmplt " ++ trueLabel)
    "gt" -> emit ("if_icmpgt " ++ trueLabel)
    "le" -> emit ("if_icmple " ++ trueLabel)
    "ge" -> emit ("if_icmpge " ++ trueLabel)
    "eq" -> emit ("if_icmpeq " ++ trueLabel)
    "ne" -> emit ("if_icmpne " ++ trueLabel)
    _    -> error $ "Unknown comparison operator: " ++ op

compileIncrement :: Int -> Type -> Bool -> State CodeGenState ()
compileIncrement index Type_int isPrefix =
  if isPrefix
    then do
      emit $ "iinc " ++ show index ++ " 1"
      emit $ "iload " ++ show index
    else do
      emit $ "iload " ++ show index
      emit $ "iinc " ++ show index ++ " 1"
compileIncrement index Type_double isPrefix = do
  emit $ "dload " ++ show index
  unless isPrefix $ emit "dup2"
  emit "dconst_1"
  emit "dadd"
  when isPrefix $ emit "dup2"
  emit $ "dstore " ++ show index
compileIncrement _ varType _ =
  error $ "Increment not supported for type: " ++ show varType

compileDecrement :: Int -> Type -> Bool -> State CodeGenState ()
compileDecrement index Type_int isPrefix =
  if isPrefix
    then do
      emit $ "iinc " ++ show index ++ " -1"
      emit $ "iload " ++ show index
    else do
      emit $ "iload " ++ show index
      emit $ "iinc " ++ show index ++ " -1"
compileDecrement index Type_double isPrefix = do
  emit $ "dload " ++ show index
  unless isPrefix $ emit "dup2"
  emit "dconst_1"
  emit "dsub"
  when isPrefix $ emit "dup2"
  emit $ "dstore " ++ show index
compileDecrement _ varType _ =
  error $ "Decrement not supported for type: " ++ show varType

emitLoad :: Type -> Int -> State CodeGenState ()
emitLoad Type_double index = emit $ "dload " ++ show index
emitLoad Type_string index = emit $ "aload " ++ show index
emitLoad _ index           = emit $ "iload " ++ show index

emitStore :: Type -> Int -> State CodeGenState ()
emitStore Type_double index = emit $ "dstore " ++ show index
emitStore Type_string index = emit $ "astore " ++ show index
emitStore _ index           = emit $ "istore " ++ show index

emitDuplicate :: Type -> State CodeGenState ()
emitDuplicate Type_double = emit "dup2"
emitDuplicate _           = emit "dup"
