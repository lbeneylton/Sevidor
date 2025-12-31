@echo off
color 02
setlocal enabledelayedexpansion

cls
echo.
if exist .venv\Scripts\activate.bat (
    echo Ambiente virtual ja existe.
) else (
    echo [+] Criando Ambiente Virtual
    python -m venv .venv

    echo [+] Ambiente Virtual Criado
    set MOMENTO = %date% %time%
    echo Ambiente virtual criado em !MOMENTO >> logs.txt
)




echo.
color 02
echo [A] Iniciando Ambiente Virtual
call .venv\Scripts\activate


