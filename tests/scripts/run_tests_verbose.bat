@echo off
setlocal enabledelayedexpansion
echo ========================================
echo    EJECUTANDO SUITE DE TESTS (VERBOSE)
echo ========================================
echo.

set /a passed=0
set /a failed=0
set /a total=0

echo Ejecutando tests con output detallado:
echo.

for %%f in (..\input\test_*.cpp) do (
    set /a total+=1
    echo ========================================
    echo [TEST !total!] %%f
    echo ========================================
    
    echo --- Contenido del archivo ---
    type "%%f"
    echo.
    echo --- Output del compilador ---
    ..\..\build\TestCompiler.exe "%%f"
    
    if !errorlevel! equ 0 (
        echo.
        echo RESULTADO: PASS
        set /a passed+=1
    ) else (
        echo.
        echo RESULTADO: FAIL
        set /a failed+=1
    )
    echo.
    echo Presiona cualquier tecla para continuar con el siguiente test...
    pause > nul
    cls
)

echo ========================================
echo           RESUMEN FINAL
echo ========================================
echo Tests ejecutados: !total!
echo Tests exitosos:   !passed!
echo Tests fallidos:   !failed!

if !failed! equ 0 (
    echo.
    echo Todos los tests pasaron
) else (
    echo.
    echo Hay !failed! test(s) fallando. Revisar implementación.
)

echo.
echo Presiona cualquier tecla para salir...
pause > nul