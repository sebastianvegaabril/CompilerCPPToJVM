@echo off
echo ========================================
echo    CONSTRUYENDO COMPILADOR C++ TO JVM
echo ========================================

rem Cambiar al directorio raíz del proyecto
cd /d "%~dp0.."

rem Configurar variables de ruta
set SRC_DIR=src
set BUILD_DIR=build
set GRAMMAR_DIR=%SRC_DIR%\grammar
set COMPILER_DIR=%SRC_DIR%\compiler
set EXEC_DIR=%SRC_DIR%\executables
set GENERATED_DIR=%GRAMMAR_DIR%\generated

rem Crear directorio de build si no existe
if not exist %BUILD_DIR% mkdir %BUILD_DIR%

echo Compilando TestCompiler...
ghc -i%GENERATED_DIR%;%COMPILER_DIR%;%EXEC_DIR% -outputdir %BUILD_DIR% -o %BUILD_DIR%\TestCompiler.exe %EXEC_DIR%\TestCompiler.hs

if %errorlevel% neq 0 (
    echo ERROR: Fallo al compilar TestCompiler
    pause
    exit /b 1
)

echo Compilando TestTypeChecker...
ghc -i%GENERATED_DIR%;%COMPILER_DIR%;%EXEC_DIR% -outputdir %BUILD_DIR% -o %BUILD_DIR%\TestTypeChecker.exe %EXEC_DIR%\TestTypeChecker.hs

if %errorlevel% neq 0 (
    echo ERROR: Fallo al compilar TestTypeChecker
    pause
    exit /b 1
)

echo.
echo ========================================
echo      COMPILACION EXITOSA
echo ========================================
echo Ejecutables creados en: %BUILD_DIR%
echo - TestCompiler.exe
echo - TestTypeChecker.exe
echo.
pause