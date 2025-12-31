@echo off
cls

REM Setup inicial
if "%1"=="--restarted" goto :after_python_install

if not exist logs mkdir logs
set LOGFILE=logs\logs_%ANO%-%MES%-%DIA%.txt

REM ===== LOGFILE ======
for /f "tokens=2 delims==" %%I in ('wmic os get LocalDateTime /value') do set DATETIME=%%I

set ANO=%DATETIME:~0,4%
set MES=%DATETIME:~4,2%
set DIA=%DATETIME:~6,2%


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



REM ===== INSTALACAO DE DEPENDENCIAS =====
if exist requirements.txt (
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
) else (
    echo [I] Nenhum requirements.txt encontrado
    echo [%date% %time:~0,8%] requirements.txt nao encontrado >> %LOGFILE%
)

echo.   