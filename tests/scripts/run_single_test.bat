@echo off
if "%1"=="" (
    echo Uso: run_single_test.bat ^<archivo_test.cpp^>
    echo Ejemplo: run_single_test.bat test_01_basic_syntax.cpp
    pause
    exit /b 1
)

rem Buscar el archivo en la carpeta input
set TEST_FILE=..\input\%1
if not exist "%TEST_FILE%" (
    echo ERROR: El archivo %1 no existe en tests\input\.
    pause
    exit /b 1
)

echo ========================================
echo     EJECUTANDO TEST INDIVIDUAL
echo ========================================
echo Archivo: %1
echo.

echo --- Contenido del archivo ---
type "%TEST_FILE%"
echo.

echo --- Output del compilador ---
..\..\build\TestCompiler.exe "%TEST_FILE%"

if %errorlevel% equ 0 (
    echo.
    echo TEST PASO CORRECTAMENTE
) else (
    echo.
    echo TEST FALLO
)

echo.
pause