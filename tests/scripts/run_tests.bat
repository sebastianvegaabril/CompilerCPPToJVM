@echo off
setlocal enabledelayedexpansion
echo ========================================
echo      EJECUTANDO SUITE DE TESTS
echo ========================================
echo.

set /a passed=0
set /a failed=0
set /a total=0

echo Ejecutando tests:
echo.

for %%f in (..\input\test_*.cpp) do (
    set /a total+=1
    echo [TEST !total!] %%f
    ..\..\build\TestCompiler.exe "%%f" > nul 2>&1
    if !errorlevel! equ 0 (
        echo   PASS
        set /a passed+=1
    ) else (
        echo   FAIL
        set /a failed+=1
    )
)

echo.
echo ========================================
echo           RESUMEN DE RESULTADOS
echo ========================================
echo Tests ejecutados: !total!
echo Tests exitosos:   !passed!
echo Tests fallidos:   !failed!

if !failed! equ 0 (
    echo.
    echo Todos los tests pasaron
) else (
    echo.
    echo Hay !failed! test^(s^) fallando. Revisar implementacion.
)

echo.
pause