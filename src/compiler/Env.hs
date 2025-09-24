{-# LANGUAGE CPP #-}

module Env where

import           AbsCppGrammar
import           ErrM
import           PrintCppGrammar

import           Data.Map        as Map
#if __GLASGOW_HASKELL__ >= 708 && __GLASGOW_HASKELL__ < 808
import           Control.Monad   hiding (fail)
import           Prelude         hiding (fail)

fail = Bad
#endif
type Env = (Sig, [Context])

type Sig = Map Id ([Type], Type)

type Context = Map Id Type

lookupVar :: Env -> Id -> Err Type
lookupVar (_, []) id = fail ("Variable " ++ show id ++ " no definida")
lookupVar (sig, ctx:ctxs) id =
  case Map.lookup id ctx of
    Just typ -> return typ
    Nothing  -> lookupVar (sig, ctxs) id

lookupFun :: Env -> Id -> Err ([Type], Type)
lookupFun (s, _) id =
  case Map.lookup id s of
    Just ts -> return ts
    Nothing -> fail ("No existe la funcion " ++ show id ++ " en el enviroment")

updateVar :: Env -> Id -> Type -> Err Env
updateVar (sig, ctx:ctxs) id typ =
  if Map.member id ctx
    then fail ("Variable " ++ show id ++ " ya definida")
    else return (sig, (Map.insert id typ ctx) : ctxs)
updateVar _ _ _ = fail "Error al actualizar el entorno"

updateFun :: Env -> Id -> ([Type], Type) -> Err Env
updateFun (s, c) id t =
  case (Map.lookup id s) of
    Just _ ->
      fail ("La funcion: " ++ show id ++ ". ya existe en el Sigma: " ++ show s)
    Nothing -> return ((Map.insert id t s), c)

newBlock :: Env -> Env
newBlock (sig, ctx) = (sig, Map.empty : ctx)

emptyEnv :: Env
emptyEnv = (Map.empty, [Map.empty])
