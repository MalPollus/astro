@echo off
setlocal EnableExtensions

pushd "%~dp0"
if errorlevel 1 exit /b 1

rem Python version installed if missing
set "PY_WINGET_ID=Python.Python.3.12"
set "PY_FULL_VERSION=3.12.8"
set "PYTHON="
set "ERRMSG="

rem checks if python is installed and if the virtual enviroment works
call :trova_python
if defined PYTHON (
    echo Python with venv already installed.
    goto :python_ok
)

echo Python or venv not found! Installing...
call :installa_windows
if errorlevel 1 goto :fallisci

call :trova_python
if not defined PYTHON (
    set "ERRMSG=Python was installed but is not reachable yet. Close this window and run the script again."
    goto :fallisci
)
echo Python installed!

:python_ok

rem venv creation
if not exist ".venv\Scripts\activate.bat" (
    echo Creating venv...
    if exist ".venv" rmdir /s /q ".venv"
    %PYTHON% -m venv .venv
    if errorlevel 1 (
        set "ERRMSG=Could not create venv."
        goto :fallisci
    )
)

call ".venv\Scripts\activate.bat"
if errorlevel 1 (
    set "ERRMSG=Could not activate venv."
    goto :fallisci
)

if not exist "requirements.txt" (
    set "ERRMSG=requirements.txt doesn't exist! Try to reinstall the repo or contact me at malpollus@gmail.com"
    goto :fallisci
)

echo Installing requirements...
python -m pip install -r requirements.txt
if errorlevel 1 (
    set "ERRMSG=Could not install the requirements."
    goto :fallisci
)

if not exist "main.py" (
    set "ERRMSG=main.py not found. Try to reinstall the repo or contact me at malpollus@gmail.com"
    goto :fallisci
)

python main.py
set "STATUS=%ERRORLEVEL%"

if not "%STATUS%"=="0" (
    echo main.py exited with error ^(code %STATUS%^)
    set /p dummy=press enter to close the window...
    exit /b %STATUS%
)

for /l %%i in (5,-1,1) do (
    echo closing window in %%i...
    timeout /t 1 /nobreak >nul
)
exit /b 0

:fallisci
echo.
echo Errore: %ERRMSG%
set /p dummy=press enter to close the window...
exit /b 1

:trova_python
set "PYTHON="
for %%C in (py python python3) do (
    if not defined PYTHON (
        %%C -c "import venv, ensurepip" >nul 2>&1
        if not errorlevel 1 set "PYTHON=%%C"
    )
)
exit /b 0

:aggiorna_path
for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python3*") do call :aggiungi_path "%%~fD"
if exist "%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" set "PATH=%LOCALAPPDATA%\Programs\Python\Launcher;%PATH%"
exit /b 0

:aggiungi_path
if exist "%~1\python.exe" set "PATH=%~1;%~1\Scripts;%PATH%"
exit /b 0


:installa_windows
where winget >nul 2>&1
if errorlevel 1 (
    echo winget not available, using the official installer...
    goto :scarica_installer
)

echo Trying to install Python with winget...
winget install -e --id %PY_WINGET_ID% --scope user --silent --accept-package-agreements --accept-source-agreements
call :aggiorna_path
call :trova_python
if defined PYTHON exit /b 0
echo winget didn't complete the installation, trying the official installer...

:scarica_installer
where curl >nul 2>&1
if errorlevel 1 (
    set "ERRMSG=curl not found, please install Python manually from https://www.python.org/downloads/"
    exit /b 1
)

rem picks the right installer for the CPU
set "ARCH_SUFFIX=-amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH_SUFFIX=-arm64"
if /i "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "ARCH_SUFFIX=-arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if not defined PROCESSOR_ARCHITEW6432 set "ARCH_SUFFIX="

set "URL=https://www.python.org/ftp/python/%PY_FULL_VERSION%/python-%PY_FULL_VERSION%%ARCH_SUFFIX%.exe"
set "INSTALLER=%TEMP%\python-%PY_FULL_VERSION%-installer.exe"

echo Downloading %URL% ...
curl -fL --retry 3 -o "%INSTALLER%" "%URL%"
if errorlevel 1 (
    set "ERRMSG=Download failed. Check your connection or install Python manually."
    exit /b 1
)

echo Installing Python, it may take a minute...
rem waits for the GUI program to finish
start /wait "" "%INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_test=0
if errorlevel 1 (
    del "%INSTALLER%" >nul 2>&1
    set "ERRMSG=The Python installer failed."
    exit /b 1
)

del "%INSTALLER%" >nul 2>&1
call :aggiorna_path
exit /b 0
