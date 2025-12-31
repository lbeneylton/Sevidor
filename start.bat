    @echo off
    setlocal enabledelayedexpansion
    cls


    REM ===== LOGFILE ======
    for /f "tokens=2 delims==" %%I in ('wmic os get LocalDateTime /value') do set DATETIME=%%I

    set ANO=%DATETIME:~0,4%
    set MES=%DATETIME:~4,2%
    set DIA=%DATETIME:~6,2%

    if not exist logs mkdir logs
    set LOGFILE=logs\logs_%ANO%-%MES%-%DIA%.txt





    REM ===== CORES =====
    set COR_OK=02
    set COR_WARN=0E
    set COR_ERR=0C

    color %COR_OK%
    echo.

    REM ===== DETECCAO DO VENV =====
    set VENV_OK=1

    if not exist .venv\Scripts\activate.bat set VENV_OK=0
    if not exist .venv\Scripts\python.exe   set VENV_OK=0
    if not exist .venv\pyvenv.cfg            set VENV_OK=0

    REM ===== VENV CORROMPIDO =====
    if %VENV_OK%==0 (
        color %COR_WARN%
        echo [-] Ambiente virtual ausente ou corrompido. Recriando...
        echo [%date% %time:~0,8%] Venv ausente ou corrompido >> %LOGFILE%

        if exist .venv (
            rmdir /s /q .venv
            echo [%date% %time:~0,8%] Venv antigo removido >> %LOGFILE%
        )

        python -m venv .venv
        if errorlevel 1 (
            color %COR_ERR%
            echo [-] Falha ao criar o ambiente virtual!
            echo [%date% %time:~0,8%] - ao criar venv >> %LOGFILE%
            exit /b 1
        )

        color %COR_OK%
        echo [+] Ambiente virtual recriado com sucesso
        echo [%date% %time:~0,8%] Venv recriado com sucesso >> %LOGFILE%

    ) else (
        echo [A] Ambiente virtual valido detectado
        echo [%date% %time:~0,8%] Venv valido detectado >> %LOGFILE%
    )

    REM ===== ATIVACAO =====
    echo.
    echo [A] Iniciando Ambiente Virtual
    call .venv\Scripts\activate

    if errorlevel 1 (
        color %COR_ERR%
        echo [-] Falha ao ativar o ambiente virtual!
        echo [%date% %time:~0,8%] - ao ativar venv >> %LOGFILE%
        exit /b 1
    )

    echo [+] Ambiente Virtual Iniciado
    echo.
