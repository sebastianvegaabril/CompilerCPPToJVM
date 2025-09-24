@echo off
echo ========================================
echo    REGENERANDO ARCHIVOS DE GRAMATICA
echo ========================================

rem Cambiar al directorio raíz del proyecto
cd /d "%~dp0.."

rem Ir al directorio de gramática
cd src\grammar

rem Verificar que existe el archivo de gramática
if not exist CppGrammar.cf (
    echo ERROR: No se encuentra CppGrammar.cf
    pause
    exit /b 1
)

echo Ejecutando BNFC en CppGrammar.cf...
bnfc --haskell CppGrammar.cf

if %errorlevel% neq 0 (
    echo ERROR: BNFC falló
    pause
    exit /b 1
)

echo Moviendo archivos generados a carpeta generated\...
move *.hs generated\ 2>nul
move *.x generated\ 2>nul
move *.y generated\ 2>nul
move Makefile generated\ 2>nul

echo.
echo ========================================
echo   GENERACION DE GRAMATICA COMPLETADA
echo ========================================
echo Archivos generados en: src\grammar\generated\
echo.
pause

rem Regresar al directorio raíz
cd ..\..