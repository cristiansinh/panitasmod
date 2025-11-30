@echo off
setlocal ENABLEDELAYEDEXPANSION

set "GITHUB_OWNER=cristiansinh"
set "GITHUB_REPO=panitasmod"
set "GITHUB_BRANCH=main"

set "MODS_LIST_URL=https://raw.githubusercontent.com/%GITHUB_OWNER%/%GITHUB_REPO%/%GITHUB_BRANCH%/mods_client_list.txt"
set "MC_MODS_DIR=%APPDATA%\.minecraft\mods"
set "TEMP_LIST=%TEMP%\mods_client_list_panitas.txt"

color 1F
title PANITAS MODS UPDATER

:menu
cls
echo.
echo  ###########################################################
echo  #                                                         #
echo  #                PANITAS MODS UPDATER                     #
echo  #                                                         #
echo  ###########################################################
echo.
echo   Proyecto   : Panitas Server by eladmin (yo xdxdxdxdxd)
echo   Repo       : https://github.com/%GITHUB_OWNER%/%GITHUB_REPO%
echo   Carpeta de mods local:
echo       %MC_MODS_DIR%
echo.
echo   Este actualizador NO borra ni reemplaza tus mods.
echo   Solo agrega los archivos que faltan por nombre.
echo.
echo   [1]  Actualizar mods existentes
echo   [2]  Instalar / reparar pack completo
echo.
echo  -----------------------------------------------------------
choice /C 12 /N /M "Selecciona una opcion: "

if errorlevel 2 goto instalar
if errorlevel 1 goto actualizar
goto menu

:prepare_mods_dir
if not exist "%MC_MODS_DIR%" (
    echo.
    echo [INFO] Creando carpeta de mods: "%MC_MODS_DIR%"
    mkdir "%MC_MODS_DIR%" 2>nul
)
goto :eof

:download_list
echo.
echo [INFO] Descargando lista desde GitHub...
if exist "%TEMP_LIST%" del /f /q "%TEMP_LIST%" >nul 2>&1

where curl >nul 2>&1
if %ERRORLEVEL%==0 (
    curl -L -s "%MODS_LIST_URL%" -o "%TEMP_LIST%"
) else (
    powershell -Command "Invoke-WebRequest -Uri '%MODS_LIST_URL%' -OutFile '%TEMP_LIST%' -UseBasicParsing"
)

if not exist "%TEMP_LIST%" (
    echo [ERROR] No se pudo descargar mods_client_list.txt
    echo [ERROR] Verifica tu conexion o la URL:
    echo         %MODS_LIST_URL%
    echo.
    pause
    goto menu
)

echo [OK] Lista descargada.
goto :eof

:sync_mods
echo.
echo [INFO] Sincronizando mods...
echo.

set /A COUNT_TOTAL=0
set /A COUNT_DESCARGADOS=0
set /A COUNT_YA_EXISTIAN=0

set "NEW_MODS_FILE=%TEMP%\panitas_new_mods_%RANDOM%.txt"
if exist "%NEW_MODS_FILE%" del /f /q "%NEW_MODS_FILE%" >nul 2>&1

for /f "usebackq tokens=1,2 delims=|" %%A in ("%TEMP_LIST%") do (
    set "URL=%%A"
    set "FILENAME=%%B"

    if not "!URL!"=="" if not "!FILENAME!"=="" (
        set /A COUNT_TOTAL+=1

        if exist "%MC_MODS_DIR%\!FILENAME!" (
            echo [YA EXISTE] !FILENAME!
            set /A COUNT_YA_EXISTIAN+=1
        ) else (
            echo [DESCARGANDO] !FILENAME!
            call :download_single "!URL!" "!FILENAME!"
            if exist "%MC_MODS_DIR%\!FILENAME!" (
                set /A COUNT_DESCARGADOS+=1
                >>"%NEW_MODS_FILE%" echo !FILENAME!
            ) else (
                echo [ERROR] No se pudo descargar !FILENAME!
            )
        )
    )
)

echo.
echo =================== RESUMEN ====================
echo  Mods en lista        : %COUNT_TOTAL%
echo  Descargados nuevos   : %COUNT_DESCARGADOS%
echo  Ya existian          : %COUNT_YA_EXISTIAN%
echo =================================================

if exist "%NEW_MODS_FILE%" (
    echo.
    echo  Mods nuevos agregados en esta actualizacion:
    for /f "usebackq delims=" %%N in ("%NEW_MODS_FILE%") do echo     - %%N
) else (
    echo.
    echo  No se agregaron mods nuevos en esta ejecucion.
)

if exist "%NEW_MODS_FILE%" del /f /q "%NEW_MODS_FILE%" >nul 2>&1

echo.
pause
goto menu

:download_single
set "URL_SINGLE=%~1"
set "FILE_SINGLE=%~2"

where curl >nul 2>&1
if %ERRORLEVEL%==0 (
    curl -L -s "%URL_SINGLE%" -o "%MC_MODS_DIR%\%FILE_SINGLE%"
) else (
    powershell -Command "Invoke-WebRequest -Uri '%URL_SINGLE%' -OutFile '%MC_MODS_DIR%\%FILE_SINGLE%' -UseBasicParsing"
)
goto :eof

:actualizar
call :prepare_mods_dir
call :download_list
echo.
echo [MODO] Actualizar mods existentes.
call :sync_mods
goto menu

:instalar
call :prepare_mods_dir
call :download_list
echo.
echo [MODO] Instalacion / reparacion del pack completo.
call :sync_mods
goto menu
