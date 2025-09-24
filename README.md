# Compilador Simple en C++

## Compilar el proyecto

scripts\build.bat

## Ejecutar todos los tests (Hay que estar parado en el directorio \tests\scripts)

tests\scripts\run_tests.bat

## Limpiar archivos compilados

scripts\clean.bat

# Scripts para probar el Compilador

## Scripts

### `run_tests.bat` - Ejecucion Rápida

```batch
.\run_tests.bat
```

- Ejecuta todos los 20 tests automaticamente
- Muestra resumen de tests exitosos/fallidos

### `run_tests_verbose.bat` - Todas en Detalle

```batch
.\run_tests_verbose.bat
```

- Muestra el contenido de cada test
- Muestra el output completo del compilador
- Pausa entre cada test para revisar

### `run_single_test.bat` - Test Individual

```batch
.\run_single_test.bat test_01_basic_syntax.cpp
.\run_single_test.bat test_20_division.cpp
```

- Ejecuta un solo test especifico
- Muestra contenido y output detallado de cada parte del compilador

## Tests Incluidos (20 total)

1. **test_01_basic_syntax.cpp** - Sintaxis basica
2. **test_02_variables.cpp** - Variables y asignacion
3. **test_03_arithmetic.cpp** - Operadores aritmeticos (+, -, \*, /)
4. **test_04_if_else.cpp** - Condicionales if-else
5. **test_05_if_simple.cpp** - Condicionales if simples
6. **test_06_while_loop.cpp** - Bucles while
7. **test_07_do_while_loop.cpp** - Bucles do-while
8. **test_08_boolean_expressions.cpp** - Expresiones booleanas
9. **test_09_comparison_ops.cpp** - Operadores de comparacion
10. **test_10_compound_assignment.cpp** - Asignación compuesta (+=)
11. **test_11_sub_assignment.cpp** - Asignacion de resta (-=)
12. **test_12_increment_ops.cpp** - Operadores de incremento (++/--)
13. **test_13_logical_and.cpp** - Operador AND (&&)
14. **test_14_logical_or.cpp** - Operador OR (||)
15. **test_15_function_params.cpp** - Funciones con parametros
16. **test_16_void_function.cpp** - Funciones void
17. **test_17_block_scope.cpp** - Scope de bloques
18. **test_18_assignment.cpp** - Asignacion simple
19. **test_19_parentheses.cpp** - Precedencia con parentesis
20. **test_20_division.cpp** - Operador de division (/)

## Caracteristicas Implementadas

- Tipos basicos: `int`, `bool`, `void`
- Operadores aritmeticos: `+`, `-`, `*`, `/`
- Operadores de comparacion: `==`, `!=`, `<`, `<=`, `>`, `>=`
- Operadores logicos: `&&`, `||`
- Asignacion: `=`, `+=`, `-=`
- Incremento/Decremento: `++x`, `x++`, `--x`, `x--`
- Control de flujo: `if`, `if-else`, `while`, `do-while`
- Funciones con parametros y sin parametros
- Scope de variables y bloques de codigo

## Características No Implementadas

- Operador modulo (`%`)
- Operador negacion (`-x`)
- Operador ternario (`?:`)
- Bucles `for`
- Caracteristicas no mencionadas en el libro de Ranta.
