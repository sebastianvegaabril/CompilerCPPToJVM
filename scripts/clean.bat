@echo off
echo ========================================
echo      LIMPIANDO ARCHIVOS COMPILADOS
echo ========================================

rem Cambiar al directorio raíz del proyecto
cd /d "%~dp0.."

rem Limpiar directorio build
if exist build (
    echo Eliminando archivos en build\...
    del /q build\*.* 2>nul
    echo Directorio build limpiado.
) else (
    echo Directorio build no existe.
)

rem Limpiar archivos compilados que pudieran estar en otros directorios
echo Limpiando archivos .hi, .o, .exe dispersos...
del /s /q *.hi 2>nul
del /s /q *.o 2>nul
del /s /q *.exe 2>nul

echo.
echo ========================================
echo      LIMPIEZA COMPLETADA
echo ========================================
pause