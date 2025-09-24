# Compilador C++ a JVM# Scripts para probar el Compilador

Un compilador que traduce un subconjunto de C++ a bytecode de JVM, implementado en Haskell usando BNFC.## Scripts

## Estructura del Proyecto### `run_tests.bat` - Ejecucion Rápida

```````batch

CompiladorCPPToJVM/.\run_tests.bat

├── src/                          # Código fuente```

│   ├── grammar/                  # Definición de gramática

│   │   ├── CppGrammar.cf        # Gramática BNF- Ejecuta todos los 20 tests automaticamente

│   │   └── generated/           # Archivos generados por BNFC- Muestra resumen de tests exitosos/fallidos

│   ├── compiler/                # Módulos del compilador

│   │   ├── TypeChecker.hs       # Verificador de tipos### `run_tests_verbose.bat` - Todas en Detalle

│   │   ├── CodeGen.hs           # Generador de código JVM

│   │   └── Env.hs               # Manejo de entornos```batch

│   └── executables/             # Puntos de entrada.\run_tests_verbose.bat

│       ├── TestCompiler.hs      # Compilador completo```

│       └── TestTypeChecker.hs   # Solo verificación de tipos

├── build/                       # Archivos compilados- Muestra el contenido de cada test

├── tests/                       # Suite de pruebas- Muestra el output completo del compilador

│   ├── input/                   # Archivos de test (.cpp)- Pausa entre cada test para revisar

│   └── scripts/                 # Scripts de testing

├── docs/                        # Documentación### `run_single_test.bat` - Test Individual

└── scripts/                     # Scripts de construcción

``````batch

.\run_single_test.bat test_01_basic_syntax.cpp

## Instalación y Compilación.\run_single_test.bat test_20_division.cpp

```

### Prerequisitos

- GHC (Glasgow Haskell Compiler)- Ejecuta un solo test especifico

- BNFC (BNF Converter)- Muestra contenido y output detallado de cada parte del compilador



### Compilar el Proyecto## Tests Incluidos (20 total)

```batch

scripts\build.bat1. **test_01_basic_syntax.cpp** - Sintaxis basica

```2. **test_02_variables.cpp** - Variables y asignacion

3. **test_03_arithmetic.cpp** - Operadores aritmeticos (+, -, \*, /)

Este script compilará ambos ejecutables:4. **test_04_if_else.cpp** - Condicionales if-else

- `build\TestCompiler.exe` - Compilador completo5. **test_05_if_simple.cpp** - Condicionales if simples

- `build\TestTypeChecker.exe` - Solo verificador de tipos6. **test_06_while_loop.cpp** - Bucles while

7. **test_07_do_while_loop.cpp** - Bucles do-while

## Uso8. **test_08_boolean_expressions.cpp** - Expresiones booleanas

9. **test_09_comparison_ops.cpp** - Operadores de comparacion

### Compilar un archivo C++10. **test_10_compound_assignment.cpp** - Asignación compuesta (+=)

```batch11. **test_11_sub_assignment.cpp** - Asignacion de resta (-=)

build\TestCompiler.exe archivo.cpp12. **test_12_increment_ops.cpp** - Operadores de incremento (++/--)

```13. **test_13_logical_and.cpp** - Operador AND (&&)

14. **test_14_logical_or.cpp** - Operador OR (||)

### Solo verificar tipos15. **test_15_function_params.cpp** - Funciones con parametros

```batch16. **test_16_void_function.cpp** - Funciones void

build\TestTypeChecker.exe archivo.cpp17. **test_17_block_scope.cpp** - Scope de bloques

```18. **test_18_assignment.cpp** - Asignacion simple

19. **test_19_parentheses.cpp** - Precedencia con parentesis

## Testing20. **test_20_division.cpp** - Operador de division (/)



### Ejecutar todos los tests## Caracteristicas Implementadas

```batch

tests\scripts\run_tests.bat- Tipos basicos: `int`, `bool`, `void`

```- Operadores aritmeticos: `+`, `-`, `*`, `/`

- Operadores de comparacion: `==`, `!=`, `<`, `<=`, `>`, `>=`

### Ejecutar tests con output detallado- Operadores logicos: `&&`, `||`

```batch- Asignacion: `=`, `+=`, `-=`

tests\scripts\run_tests_verbose.bat- Incremento/Decremento: `++x`, `x++`, `--x`, `x--`

```- Control de flujo: `if`, `if-else`, `while`, `do-while`

- Funciones con parametros y sin parametros

### Ejecutar un test específico- Scope de variables y bloques de codigo

```batch

tests\scripts\run_single_test.bat test_01_basic_syntax.cpp## Características No Implementadas

```

- Operador modulo (`%`)

## Características Implementadas- Operador negacion (`-x`)

- Operador ternario (`?:`)

- **Tipos básicos**: `int`, `bool`, `void`- Bucles `for`

- **Operadores aritméticos**: `+`, `-`, `*`, `/`- Caracteristicas no mencionadas en el libro de Ranta.

- **Operadores de comparación**: `==`, `!=`, `<`, `<=`, `>`, `>=`
- **Operadores lógicos**: `&&`, `||`
- **Asignación**: `=`, `+=`, `-=`
- **Incremento/Decremento**: `++x`, `x++`, `--x`, `x--`
- **Control de flujo**: `if`, `if-else`, `while`, `do-while`
- **Funciones**: Con parámetros y sin parámetros
- **Scope**: Variables y bloques de código

## Scripts Útiles

- `scripts\build.bat` - Compilar el proyecto
- `scripts\clean.bat` - Limpiar archivos compilados
- `scripts\generate_grammar.bat` - Regenerar archivos de gramática con BNFC

## Desarrollo

Para modificar la gramática:
1. Editar `src\grammar\CppGrammar.cf`
2. Ejecutar `scripts\generate_grammar.bat`
3. Recompilar con `scripts\build.bat`
```````
