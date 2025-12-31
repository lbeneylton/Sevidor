@echo off
setlocal EnableExtensions EnableDelayedExpansion
cls


REM depois: suporte offline com cache de wheels /modo CI silencioso / requirements.lock/ ajeitar os parses arguments

REM Setup inicial
if "%1"=="--restarted" (
    shift
    goto :after_python_install
)

set NO_INSTALL=0
for %%A in (%*) do (
    if "%%A"=="--no-install" set NO_INSTALL=1
)

REM flag para ativação direta

REM ===== LOGFILE ======
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set DATETIME=%%I

set ANO=%DATETIME:~0,4%
set MES=%DATETIME:~4,2%
set DIA=%DATETIME:~6,2%

if not exist logs mkdir logs
set LOGFILE=logs\logs_%ANO%-%MES%-%DIA%.txt


REM Exclui a pasta logs de versionamentos
if not exist .gitignore (
    echo /logs/ > .gitignore
) else (
    findstr /C:"/logs/" .gitignore >nul || echo /logs/ >> .gitignore
)


REM ===== CORES =====
set COR_OK=02
set COR_WARN=0E
set COR_ERR=0C

color %COR_OK%
echo.

REM ===== DETECCAO DO PYTHON =====
python --version >nul 2>&1
if errorlevel 1 (
    color %COR_WARN%
    echo [!] Python nao encontrado. Tentando instalar via winget...
    echo [%date% %time:~0,8%] Python nao encontrado. Tentando instalar >> %LOGFILE%

    winget --version >nul 2>&1
    if errorlevel 1 (
        color %COR_ERR%
        echo [-] winget nao encontrado. Instale o Python manualmente.
        echo [%date% %time:~0,8%] winget nao encontrado >> %LOGFILE%
        exit /b 1
    )

    winget install -e --id Python.Python.3 --silent

    if errorlevel 1 (
        color %COR_ERR%
        echo [-] Falha ao instalar Python via winget!
        echo [%date% %time:~0,8%] Falha ao instalar Python >> %LOGFILE%
        exit /b 1
    )

    color %COR_OK%
    echo [+] Python instalado com sucesso.
    echo [+] Reabra o terminal e execute o script novamente.
    echo [%date% %time:~0,8%] Python instalado via winget >> %LOGFILE%
    echo [+] Reiniciando o script em novo terminal...

    REM Reabre o bat
    timeout /t 3 >nul
    start "" cmd /k "%~f0 --restarted"
    exit /b
)


REM Quando o bat é reiniciado começa daqui (ignorando instalação do python)
:after_python_install

REM ======= Verifica o laucher para rodar comandos python
set PY_CMD=
python --version >nul 2>&1 && set PY_CMD=python
if not defined PY_CMD (
    py -3 --version >nul 2>&1 && set PY_CMD=py -3
)

if not defined PY_CMD (
    color %COR_ERR%
    echo [-] Python instalado, mas nao acessivel!
    exit /b 1
)

echo [+] Usando: %PY_CMD%


REM ===== DETECCAO DO VENV =====
set VENV_OK=1

if not exist .venv\Scripts\activate.bat set VENV_OK=0
if not exist .venv\Scripts\python.exe set VENV_OK=0
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

    %PY_CMD% -m venv .venv
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

REM ===== FLAG --no-install =====
if %NO_INSTALL%==1 (
    color %COR_WARN%
    echo [!] --no-install ativo. Pulando instalacao de dependencias.
    echo [%date% %time:~0,8%] --no-install ativo >> %LOGFILE%
    goto :end
)

REM ===== HASH DO REQUIREMENTS =====
set INSTALL_REQ=1
set REQ_HASH_FILE=.venv\.requirements.hash

if exist requirements.txt (
    REM Cria hash do requirements e salva no ambiente virtual
    set CURRENT_HASH=
    for /f "tokens=1" %%H in ('certutil -hashfile requirements.txt SHA256 ^| findstr /R /V "hash CertUtil"') do (
        set CURRENT_HASH=%%H
    )

    if not defined CURRENT_HASH (
        echo [!] Falha ao gerar hash do requirements.txt
        set INSTALL_REQ=1
    )

    if exist %REQ_HASH_FILE% (
        set /p OLD_HASH=<%REQ_HASH_FILE%
        if "!OLD_HASH!"=="!CURRENT_HASH!" (
            set INSTALL_REQ=0
        )
    )
)


if %INSTALL_REQ%==0 (
    echo [A] requirements.txt inalterado. Pulando instalacao.
    echo [%date% %time:~0,8%] requirements.txt inalterado >> %LOGFILE%
    goto :end
)

REM ===== INSTALACAO DE DEPENDENCIAS =====
if exist requirements.txt (
    REM Cria Hash dos requirements e guarda no ambiente
    echo [I] Instalando dependencias...
    echo [%date% %time:~0,8%] Instalando requirements.txt >> %LOGFILE%

    .venv\Scripts\python.exe -m pip install --upgrade pip >nul 2>&1
    .venv\Scripts\python.exe -m pip install -r requirements.txt

    if errorlevel 1 (
        color %COR_ERR%
        echo [ERRO] Falha ao instalar dependencias!
        echo [%date% %time:~0,8%] ERRO ao instalar requirements.txt >> %LOGFILE%
        exit /b 1
    )

    echo [+] Dependencias instaladas com sucesso
    echo [%date% %time:~0,8%] Dependencias instaladas >> %LOGFILE%

    echo %CURRENT_HASH% > %REQ_HASH_FILE%
) else (
    echo [I] Nenhum requirements.txt encontrado
    echo [%date% %time:~0,8%] requirements.txt nao encontrado >> %LOGFILE%
)

:end
echo.   