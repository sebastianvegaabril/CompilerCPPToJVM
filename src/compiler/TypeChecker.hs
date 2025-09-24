{-# LANGUAGE CPP #-}

module TypeChecker where

import           AbsCppGrammar
import           Control.Monad   hiding (fail)
import           Env
import           ErrM
import           PrintCppGrammar
#if __GLASGOW_HASKELL__ >= 708 && __GLASGOW_HASKELL__ < 808
import           Prelude         hiding (fail)
#endif
typecheck :: Program -> Err ()
typecheck p@(PDefs defs) = do
  let emptyEnvironment = emptyEnv
  updatedEnvironment <- updateDefs emptyEnvironment defs
  checkProg updatedEnvironment p

typecheckAndTransform :: Program -> Err Program
typecheckAndTransform p@(PDefs defs) = do
  let emptyEnvironment = emptyEnv
  updatedEnvironment <- updateDefs emptyEnvironment defs
  checkProg updatedEnvironment p
  transformProgram updatedEnvironment p

updateDefs :: Env -> [Def] -> Err Env
updateDefs env [] = return env
updateDefs env ((DFun typ id args stms):defs) = do
  updatedEnv <- updateFun env id (args2Types args, typ)
  updateDefs updatedEnv defs

args2Types :: [Arg] -> [Type]
args2Types []                 = []
args2Types ((ADecl t _):args) = t : args2Types args

checkProg :: Env -> Program -> Err ()
checkProg env (PDefs defs) = checkDefs env defs

checkDefs :: Env -> [Def] -> Err ()
checkDefs env []         = return ()
checkDefs env (def:defs) = checkDef env def >> checkDefs env defs

checkDef :: Env -> Def -> Err ()
checkDef env (DFun returnType functionName args (Body1 stms)) = do
  updatedEnv <- updateAllVars env args
  checkStms returnType updatedEnv stms
  return ()
checkDef env (DFun returnType functionName args Body2) = do
  return ()
checkDef _ stm =
  fail
    ("La definicion de la funcion " ++ show stm ++ " no existe en el lenguaje")

updateAllVars :: Env -> [Arg] -> Err Env
updateAllVars env [] = return env
updateAllVars env ((ADecl varType varId):args) = do
  updatedEnv <- updateVar env varId varType
  updateAllVars updatedEnv args

inferExp :: Env -> Exp -> Err Type
inferExp env (EInt n) = return Type_int
inferExp env (EDouble n) = return Type_double
inferExp env (ETrue) = return Type_bool
inferExp env (EFalse) = return Type_bool
inferExp env (EString s) = return Type_string
inferExp env (EId [CNIdentifier varId]) =
  case lookupVar env varId of
    Ok varType -> return varType
    Bad _ ->
      fail ("Variable " ++ show varId ++ " no definida en el env: " ++ show env)
inferExp env (EId _) = fail "Identificadores complejos no soportados aún"
inferExp env (EIncr (EId [CNIdentifier varId])) =
  case lookupVar env varId of
    Ok varType ->
      if (varType == Type_int || varType == Type_double)
        then return varType
        else fail ("Variable " ++ show varId ++ " no es de tipo int o double")
    Bad _ ->
      fail ("Variable " ++ show varId ++ " no definida en el env: " ++ show env)
inferExp env (EDecr (EId [CNIdentifier varId])) =
  case lookupVar env varId of
    Ok varType ->
      if (varType == Type_int || varType == Type_double)
        then return varType
        else fail ("Variable " ++ show varId ++ " no es de tipo int o double")
    Bad _ ->
      fail ("Variable " ++ show varId ++ " no definida en el env: " ++ show env)
inferExp env (EPIncr (EId [CNIdentifier varId])) =
  case lookupVar env varId of
    Ok varType ->
      if (varType == Type_int || varType == Type_double)
        then return varType
        else fail ("Variable " ++ show varId ++ " no es de tipo int o double")
    Bad _ ->
      fail ("Variable " ++ show varId ++ " no definida en el env: " ++ show env)
inferExp env (EPDecr (EId [CNIdentifier varId])) =
  case lookupVar env varId of
    Ok varType ->
      if (varType == Type_int || varType == Type_double)
        then return varType
        else fail ("Variable " ++ show varId ++ " no es de tipo int o double")
    Bad _ ->
      fail ("Variable " ++ show varId ++ " no definida en el env: " ++ show env)
inferExp env (ETyped exp expectedType) =
  case inferExp env exp of
    Ok actualType ->
      if (actualType == expectedType)
        then return actualType
        else fail
               ("En "
                  ++ printTree exp
                  ++ " se esperaba el tipo: "
                  ++ printTree expectedType
                  ++ ", pero se encontro: "
                  ++ printTree actualType)
    Bad _ ->
      fail
        ("En "
           ++ printTree exp
           ++ " se esperaba el tipo: "
           ++ printTree expectedType
           ++ ", pero se encontro un error")
inferExp env (ETimes expr1 expr2) = do
  type1 <- inferExp env expr1
  type2 <- inferExp env expr2
  if ((type1 == Type_int && type2 == Type_int)
        || (type1 == Type_double && type2 == Type_double))
    then return type1
    else fail
           ("En "
              ++ printTree expr1
              ++ " y "
              ++ printTree expr2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree type1
              ++ " y "
              ++ printTree type2)
inferExp env (EDiv expr1 expr2) = do
  type1 <- inferExp env expr1
  type2 <- inferExp env expr2
  if ((type1 == Type_int && type2 == Type_int)
        || (type1 == Type_double && type2 == Type_double))
    then return type1
    else fail
           ("En "
              ++ printTree expr1
              ++ " y "
              ++ printTree expr2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree type1
              ++ " y "
              ++ printTree type2)
inferExp env (EPlus expr1 expr2) = do
  type1 <- inferExp env expr1
  type2 <- inferExp env expr2
  if ((type1 == Type_int && type2 == Type_int)
        || (type1 == Type_double && type2 == Type_double))
    then return type1
    else fail
           ("En "
              ++ printTree expr1
              ++ " y "
              ++ printTree expr2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree type1
              ++ " y "
              ++ printTree type2)
inferExp env (EMinus expr1 expr2) = do
  type1 <- inferExp env expr1
  type2 <- inferExp env expr2
  if ((type1 == Type_int && type2 == Type_int)
        || (type1 == Type_double && type2 == Type_double))
    then return type1
    else fail
           ("En "
              ++ printTree expr1
              ++ " y "
              ++ printTree expr2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree type1
              ++ " y "
              ++ printTree type2)
inferExp env (ELt expr1 expr2) = do
  type1 <- inferExp env expr1
  type2 <- inferExp env expr2
  if ((type1 == Type_int && type2 == Type_int)
        || (type1 == Type_double && type2 == Type_double))
    then return Type_bool
    else fail
           ("En "
              ++ printTree expr1
              ++ " y "
              ++ printTree expr2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree type1
              ++ " y "
              ++ printTree type2)
inferExp env (EGt expr1 expr2) = do
  type1 <- inferExp env expr1
  type2 <- inferExp env expr2
  if ((type1 == Type_int && type2 == Type_int)
        || (type1 == Type_double && type2 == Type_double))
    then return Type_bool
    else fail
           ("En "
              ++ printTree expr1
              ++ " y "
              ++ printTree expr2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree type1
              ++ " y "
              ++ printTree type2)
inferExp env (ELtEq e1 e2) = do
  typ1 <- inferExp env e1
  typ2 <- inferExp env e2
  if ((typ1 == Type_int && typ2 == Type_int)
        || (typ1 == Type_double && typ2 == Type_double))
    then return Type_bool
    else fail
           ("En "
              ++ printTree e1
              ++ " y "
              ++ printTree e2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree typ1
              ++ " y "
              ++ printTree typ2)
inferExp env (EGtEq e1 e2) = do
  typ1 <- inferExp env e1
  typ2 <- inferExp env e2
  if ((typ1 == Type_int && typ2 == Type_int)
        || (typ1 == Type_double && typ2 == Type_double))
    then return Type_bool
    else fail
           ("En "
              ++ printTree e1
              ++ " y "
              ++ printTree e2
              ++ " se esperaba el tipo: "
              ++ printTree Type_int
              ++ " o "
              ++ printTree Type_int
              ++ ", pero se encontro: "
              ++ printTree typ1
              ++ " y "
              ++ printTree typ2)
inferExp env (EEq e1 e2) = do
  typ1 <- inferExp env e1
  typ2 <- inferExp env e2
  if ((typ1 == Type_int && typ2 == Type_int)
        || (typ1 == Type_double && typ2 == Type_double)
        || (typ1 == Type_bool && typ2 == Type_bool))
    then return Type_bool
    else fail
           ("En "
              ++ printTree e1
              ++ " y "
              ++ printTree e2
              ++ " se esperaba el tipo: "
              ++ printTree typ1
              ++ " o "
              ++ printTree typ1
              ++ ", pero se encontro: "
              ++ printTree typ1
              ++ " y "
              ++ printTree typ2)
inferExp env (ENEq e1 e2) = do
  typ1 <- inferExp env e1
  typ2 <- inferExp env e2
  if ((typ1 == Type_int && typ2 == Type_int)
        || (typ1 == Type_double && typ2 == Type_double)
        || (typ1 == Type_bool && typ2 == Type_bool))
    then return Type_bool
    else fail
           ("En "
              ++ printTree e1
              ++ " y "
              ++ printTree e2
              ++ " se esperaba el tipo: "
              ++ printTree typ1
              ++ " o "
              ++ printTree typ1
              ++ ", pero se encontro: "
              ++ printTree typ1
              ++ " y "
              ++ printTree typ2)
inferExp env (EAnd e1 e2) = do
  typ1 <- inferExp env e1
  typ2 <- inferExp env e2
  if (typ1 == Type_bool && typ2 == Type_bool)
    then return Type_bool
    else fail
           ("En "
              ++ printTree e1
              ++ " y "
              ++ printTree e2
              ++ " se esperaba el tipo: "
              ++ printTree Type_bool
              ++ " o "
              ++ printTree Type_bool
              ++ ", pero se encontro: "
              ++ printTree typ1
              ++ " y "
              ++ printTree typ2)
inferExp env (EOr e1 e2) = do
  typ1 <- inferExp env e1
  typ2 <- inferExp env e2
  if (typ1 == Type_bool && typ2 == Type_bool)
    then return Type_bool
    else fail
           ("En "
              ++ printTree e1
              ++ " y "
              ++ printTree e2
              ++ " se esperaba el tipo: "
              ++ printTree Type_bool
              ++ " o "
              ++ printTree Type_bool
              ++ ", pero se encontro: "
              ++ printTree typ1
              ++ " y "
              ++ printTree typ2)
inferExp env (EApp (EId [CNIdentifier functionId]) expressions) = do
  (argumentTypes, returnType) <- lookupFun env functionId
  if (length argumentTypes == length expressions)
    then do
      checkExps env expressions argumentTypes
      return returnType
    else fail
           ("En "
              ++ printTree functionId
              ++ " se esperaba "
              ++ show (length argumentTypes)
              ++ " argumentos, pero se encontraron "
              ++ show (length expressions))
inferExp env (EAss (EId [CNIdentifier varId]) exp) = do
  type1 <- lookupVar env varId
  type2 <- inferExp env exp
  if (type1 == type2)
    then return type1
    else fail
           ("En "
              ++ printTree varId
              ++ " se esperaba el tipo: "
              ++ printTree type1
              ++ ", pero se encontro: "
              ++ printTree type2)
inferExp env (EAss (ETyped (EId [CNIdentifier varId]) _) exp) = do
  type1 <- lookupVar env varId
  type2 <- inferExp env exp
  if (type1 == type2)
    then return type1
    else fail
           ("En asignacion a "
              ++ printTree varId
              ++ " se esperaba el tipo: "
              ++ printTree type1
              ++ ", pero se encontro: "
              ++ printTree type2)
inferExp env (EAddAss (EId [CNIdentifier id]) exp) = do
  typ1 <- lookupVar env id
  typ2 <- inferExp env exp
  if (typ1 == typ2 && (typ1 == Type_int || typ1 == Type_double))
    then return typ1
    else fail
           ("En += a "
              ++ printTree id
              ++ " se esperaba el tipo: "
              ++ printTree typ1
              ++ ", pero se encontro: "
              ++ printTree typ2)
inferExp env (ESubAss (EId [CNIdentifier id]) exp) = do
  typ1 <- lookupVar env id
  typ2 <- inferExp env exp
  if (typ1 == typ2 && (typ1 == Type_int || typ1 == Type_double))
    then return typ1
    else fail
           ("En -= a "
              ++ printTree id
              ++ " se esperaba el tipo: "
              ++ printTree typ1
              ++ ", pero se encontro: "
              ++ printTree typ2)
inferExp env (EAddAss (ETyped (EId [CNIdentifier id]) _) exp) = do
  typ1 <- lookupVar env id
  typ2 <- inferExp env exp
  if (typ1 == typ2 && (typ1 == Type_int || typ1 == Type_double))
    then return typ1
    else fail
           ("En += a "
              ++ printTree id
              ++ " se esperaba el tipo: "
              ++ printTree typ1
              ++ ", pero se encontro: "
              ++ printTree typ2)
inferExp env (ESubAss (ETyped (EId [CNIdentifier id]) _) exp) = do
  typ1 <- lookupVar env id
  typ2 <- inferExp env exp
  if (typ1 == typ2 && (typ1 == Type_int || typ1 == Type_double))
    then return typ1
    else fail
           ("En -= a "
              ++ printTree id
              ++ " se esperaba el tipo: "
              ++ printTree typ1
              ++ ", pero se encontro: "
              ++ printTree typ2)
inferExp _ e = fail ("la expresion " ++ show e ++ " aun no esta implementada")

checkExps :: Env -> [Exp] -> [Type] -> Err ()
checkExps env [] [] = return ()
checkExps env (expr:expressions) (expectedType:expectedTypes) = do
  checkExp env expr expectedType
  checkExps env expressions expectedTypes

checkExp :: Env -> Exp -> Type -> Err ()
checkExp env exp expectedType = do
  actualType <- inferExp env exp
  if (actualType == expectedType)
    then return ()
    else fail
           ("En "
              ++ printTree exp
              ++ " se esperaba el tipo: "
              ++ printTree expectedType
              ++ ", pero se encontro: "
              ++ printTree actualType
              ++ " la exp era:"
              ++ show exp
              ++ ". Y el ENV era: "
              ++ show env)

checkStms :: Type -> Env -> [Stm] -> Err Env
checkStms returnType env (SReturn exp:stms) = do
  checkExp env exp returnType
  return env
checkStms returnType env (SReturnVal exp:stms) = do
  checkExp env exp returnType
  return env
checkStms returnType env (SExp exp:stms) = do
  _ <- inferExp env exp
  checkStms returnType env stms
checkStms returnType env (SIfElse exp stm1 stm2:stms) = do
  checkExp env exp Type_bool
  checkStms returnType env (stm1 : (stm2 : stms))
checkStms returnType env (SWhile exp stm:stms) = do
  checkExp env exp Type_bool
  checkStms returnType env (stm : stms)
checkStms returnType env (SDoWhile stm exp:stms) = do
  checkExp env exp Type_bool
  checkStms returnType env (stm : stms)
checkStms returnType env (SIf exp stm:stms) = do
  checkExp env exp Type_bool
  checkStms returnType env (stm : stms)
checkStms returnType env (SBlock stms2:stms) = do
  newEnv <- return (newBlock env)
  checkStms returnType newEnv stms2
  checkStms returnType env stms
checkStms returnType env (SDecls (XDecl varType idSpecs _):stms) = do
  newEnv <- updateAllIdSpecs env idSpecs varType
  checkStms returnType newEnv stms
checkStms returnType env (SInit varType varId exp:stms) = do
  checkExp env exp varType
  newEnv <- updateVar env varId varType
  checkStms returnType newEnv stms
checkStms returnType env (SReturnVoid:stms) = do
  checkStms Type_void env stms
  return env
checkStms returnType env (SEmpty:stms) = do
  checkStms returnType env stms
checkStms _ env [] = return env
checkStms _ _ (statement:statements) =
  fail ("El statement " ++ show statement ++ " aun no esta definido")

updateAllId :: Env -> [Id] -> Type -> Err Env
updateAllId env [] _ = return env
updateAllId env (variableId:variableIds) variableType = do
  newEnv <- updateVar env variableId variableType
  updateAllId newEnv variableIds variableType

updateAllIdSpecs :: Env -> [IdSpec] -> Type -> Err Env
updateAllIdSpecs env [] _ = return env
updateAllIdSpecs env ((IdSpecId variableId):idSpecs) variableType = do
  newEnv <- updateVar env variableId variableType
  updateAllIdSpecs newEnv idSpecs variableType
updateAllIdSpecs env ((IdSpec1 variableId _):idSpecs) variableType = do
  newEnv <- updateVar env variableId variableType
  updateAllIdSpecs newEnv idSpecs variableType

updateIfIsNotDefined :: Env -> Id -> Type -> Err Env
updateIfIsNotDefined env variableId variableType = do
  case lookupVar env variableId of
    Right _ -> fail ("Variable " ++ show variableId ++ " ya definida")
    Left _  -> updateVar env variableId variableType

transformProgram :: Env -> Program -> Err Program
transformProgram env (PDefs defs) = do
  transformedDefs <- mapM (transformDef env) defs
  return (PDefs transformedDefs)

transformDef :: Env -> Def -> Err Def
transformDef env (DFun varType varId args body) = do
  let argTypes = args2Types args
  newEnv <- foldM (\e (ADecl t i) -> updateVar e i t) env args
  transformedBody <- transformBody newEnv body
  return (DFun varType varId args transformedBody)
transformDef env def = return def

transformBody :: Env -> Body -> Err Body
transformBody env (Body1 stms) = do
  (transformedStms, _) <- transformStms env stms
  return (Body1 transformedStms)
transformBody env Body2 = return Body2

transformStms :: Env -> [Stm] -> Err ([Stm], Env)
transformStms env [] = return ([], env)
transformStms env (stm:stms) = do
  (transformedStm, newEnv) <- transformStmWithEnv env stm
  (transformedStms, finalEnv) <- transformStms newEnv stms
  return (transformedStm : transformedStms, finalEnv)

transformStmWithEnv :: Env -> Stm -> Err (Stm, Env)
transformStmWithEnv env (SReturnVal exp) = do
  transformedExp <- transformExp env exp
  return (SReturnVal transformedExp, env)
transformStmWithEnv env (SInit varType varId exp) = do
  transformedExp <- transformExp env exp
  newEnv <- updateVar env varId varType
  return (SInit varType varId transformedExp, newEnv)
transformStmWithEnv env (SIfElse conditionExp stm1 stm2) = do
  transformedCondition <- transformExp env conditionExp
  transformedStm1 <- transformStm env stm1
  transformedStm2 <- transformStm env stm2
  return (SIfElse transformedCondition transformedStm1 transformedStm2, env)
transformStmWithEnv env (SWhile conditionExp stm) = do
  transformedCondition <- transformExp env conditionExp
  transformedStm <- transformStm env stm
  return (SWhile transformedCondition transformedStm, env)
transformStmWithEnv env (SDoWhile stm conditionExp) = do
  transformedCondition <- transformExp env conditionExp
  transformedStm <- transformStm env stm
  return (SDoWhile transformedStm transformedCondition, env)
transformStmWithEnv env (SIf conditionExp stm) = do
  transformedCondition <- transformExp env conditionExp
  transformedStm <- transformStm env stm
  return (SIf transformedCondition transformedStm, env)
transformStmWithEnv env (SBlock stms) = do
  (transformedStms, _) <- transformStms env stms
  return (SBlock transformedStms, env)
transformStmWithEnv env (SExp exp) = do
  transformedExp <- transformExp env exp
  return (SExp transformedExp, env)
transformStmWithEnv env (SDecls (XDecl varType idSpecs maybeAssignment)) = do
  newEnv <-
    foldM
      (\e idSpec ->
         case idSpec of
           IdSpecId varId  -> updateVar e varId varType
           IdSpec1 varId _ -> updateVar e varId varType)
      env
      idSpecs
  return (SDecls (XDecl varType idSpecs maybeAssignment), newEnv)
transformStmWithEnv env SEmpty = return (SEmpty, env)
transformStmWithEnv env stm = return (stm, env)

transformStm :: Env -> Stm -> Err Stm
transformStm env stm = do
  (transformedStm, _) <- transformStmWithEnv env stm
  return transformedStm

transformExp :: Env -> Exp -> Err Exp
transformExp env exp = do
  transformedExp <- transformExpRecursive env exp
  expType <- inferExp env transformedExp
  return (ETyped transformedExp expType)

transformExpRecursive :: Env -> Exp -> Err Exp
transformExpRecursive env (ETimes expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (ETimes t1 t2)
transformExpRecursive env (EDiv expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EDiv t1 t2)
transformExpRecursive env (EMinus expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EMinus t1 t2)
transformExpRecursive env (EPlus expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EPlus t1 t2)
transformExpRecursive env (EAss lhs rhs) = do
  t1 <- transformExp env lhs
  t2 <- transformExp env rhs
  return (EAss t1 t2)
transformExpRecursive env (EAddAss lhs rhs) = do
  t1 <- transformExp env lhs
  t2 <- transformExp env rhs
  return (EAddAss t1 t2)
transformExpRecursive env (ESubAss lhs rhs) = do
  t1 <- transformExp env lhs
  t2 <- transformExp env rhs
  return (ESubAss t1 t2)
transformExpRecursive env (ELtEq expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (ELtEq t1 t2)
transformExpRecursive env (EGt expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EGt t1 t2)
transformExpRecursive env (ELt expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (ELt t1 t2)
transformExpRecursive env (EGtEq expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EGtEq t1 t2)
transformExpRecursive env (EEq expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EEq t1 t2)
transformExpRecursive env (ENEq expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (ENEq t1 t2)
transformExpRecursive env (EAnd expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EAnd t1 t2)
transformExpRecursive env (EOr expr1 expr2) = do
  t1 <- transformExp env expr1
  t2 <- transformExp env expr2
  return (EOr t1 t2)
transformExpRecursive env (EApp function arguments) = do
  transformedArgs <- mapM (transformExp env) arguments
  return (EApp function transformedArgs)
transformExpRecursive env exp = return exp
