@echo off
setlocal EnableDelayedExpansion

REM ========================================
REM n8n Resume Optimizer - Windows Manager
REM ========================================

set "SCRIPT_DIR=%~dp0"
set "COMPOSE_FILE=%SCRIPT_DIR%docker-compose.yml"
set "ENV_FILE=%SCRIPT_DIR%.env"

REM Colors for output
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:MAIN_MENU
cls
echo %BLUE%========================================%NC%
echo %BLUE%  n8n Resume Optimizer - Manager%NC%
echo %BLUE%========================================%NC%
echo.
echo %GREEN%1.%NC% Start n8n (First time setup)
echo %GREEN%2.%NC% Start n8n (Normal start)
echo %GREEN%3.%NC% Stop n8n
echo %GREEN%4.%NC% Restart n8n
echo %GREEN%5.%NC% View Status
echo %GREEN%6.%NC% View Logs
echo %GREEN%7.%NC% Clean/Reset Everything
echo %GREEN%8.%NC% Backup Data
echo %GREEN%9.%NC% Open n8n in Browser
echo %GREEN%0.%NC% Exit
echo.
set /p "choice=Enter your choice (0-9): "

if "%choice%"=="1" goto FIRST_SETUP
if "%choice%"=="2" goto START_N8N
if "%choice%"=="3" goto STOP_N8N
if "%choice%"=="4" goto RESTART_N8N
if "%choice%"=="5" goto VIEW_STATUS
if "%choice%"=="6" goto VIEW_LOGS
if "%choice%"=="7" goto CLEAN_RESET
if "%choice%"=="8" goto BACKUP_DATA
if "%choice%"=="9" goto OPEN_BROWSER
if "%choice%"=="0" goto EXIT
goto MAIN_MENU

:FIRST_SETUP
cls
echo %YELLOW%========================================%NC%
echo %YELLOW%         First Time Setup%NC%
echo %YELLOW%========================================%NC%
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED%ERROR: Docker is not installed or not in PATH%NC%
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop
    pause
    goto MAIN_MENU
)

REM Check if Docker Compose is available
docker compose version >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED%ERROR: Docker Compose is not available%NC%
    echo Please ensure Docker Desktop is properly installed
    pause
    goto MAIN_MENU
)

REM Create necessary directories
echo %BLUE%Creating directories...%NC%
if not exist "%SCRIPT_DIR%n8n-workflows" mkdir "%SCRIPT_DIR%n8n-workflows"
if not exist "%SCRIPT_DIR%n8n-credentials" mkdir "%SCRIPT_DIR%n8n-credentials"

REM Create environment file if it doesn't exist
if not exist "%ENV_FILE%" (
    echo %BLUE%Creating environment file...%NC%
    call :CREATE_ENV_FILE
)

REM Pull latest images
echo %BLUE%Pulling Docker images...%NC%
docker compose -f "%COMPOSE_FILE%" pull

REM Start services
echo %BLUE%Starting n8n for the first time...%NC%
docker compose -f "%COMPOSE_FILE%" up -d

REM Wait for services to be ready
echo %BLUE%Waiting for services to start...%NC%
timeout /t 10 /nobreak >nul

REM Check if services are running
call :CHECK_SERVICES

echo.
echo %GREEN%=== FIRST SETUP COMPLETE ===%NC%
echo.
echo %YELLOW%Important Information:%NC%
echo - n8n URL: http://localhost:5678
echo - Username: admin
echo - Password: admin123
echo - Database: PostgreSQL (automatically configured)
echo.
echo %YELLOW%Next Steps:%NC%
echo 1. Open n8n in your browser (Option 9)
echo 2. Import the Resume Optimizer workflow
echo 3. Configure your OpenAI API key
echo.
pause
goto MAIN_MENU

:START_N8N
cls
echo %BLUE%Starting n8n...%NC%
docker compose -f "%COMPOSE_FILE%" up -d
call :CHECK_SERVICES
echo %GREEN%n8n started successfully!%NC%
echo Access it at: http://localhost:5678
pause
goto MAIN_MENU

:STOP_N8N
cls
echo %BLUE%Stopping n8n...%NC%
docker compose -f "%COMPOSE_FILE%" down
echo %GREEN%n8n stopped successfully!%NC%
pause
goto MAIN_MENU

:RESTART_N8N
cls
echo %BLUE%Restarting n8n...%NC%
docker compose -f "%COMPOSE_FILE%" restart
call :CHECK_SERVICES
echo %GREEN%n8n restarted successfully!%NC%
pause
goto MAIN_MENU

:VIEW_STATUS
cls
echo %BLUE%Current Status:%NC%
echo.
docker compose -f "%COMPOSE_FILE%" ps
echo.
echo %BLUE%Docker System Info:%NC%
docker system df
echo.
pause
goto MAIN_MENU

:VIEW_LOGS
cls
echo %BLUE%Recent Logs (Press Ctrl+C to exit):%NC%
echo.
docker compose -f "%COMPOSE_FILE%" logs -f --tail=50
goto MAIN_MENU

:CLEAN_RESET
cls
echo %RED%========================================%NC%
echo %RED%         CLEAN/RESET WARNING%NC%
echo %RED%========================================%NC%
echo.
echo %YELLOW%This will:%NC%
echo - Stop all containers
echo - Remove all containers and volumes
echo - Delete all n8n data and workflows
echo - Delete all database data
echo.
echo %RED%THIS CANNOT BE UNDONE!%NC%
echo.
set /p "confirm=Are you sure? Type 'YES' to confirm: "
if not "%confirm%"=="YES" (
    echo Operation cancelled.
    pause
    goto MAIN_MENU
)

echo %BLUE%Stopping and removing everything...%NC%
docker compose -f "%COMPOSE_FILE%" down -v --remove-orphans
docker system prune -f
echo %GREEN%Clean/Reset completed!%NC%
pause
goto MAIN_MENU

:BACKUP_DATA
cls
echo %BLUE%Creating backup...%NC%
set "BACKUP_DIR=%SCRIPT_DIR%backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "BACKUP_DIR=%BACKUP_DIR: =0%"

mkdir "%BACKUP_DIR%"

REM Backup workflows and credentials
if exist "%SCRIPT_DIR%n8n-workflows" xcopy "%SCRIPT_DIR%n8n-workflows" "%BACKUP_DIR%\workflows\" /E /I
if exist "%SCRIPT_DIR%n8n-credentials" xcopy "%SCRIPT_DIR%n8n-credentials" "%BACKUP_DIR%\credentials\" /E /I

REM Backup database
echo %BLUE%Backing up database...%NC%
docker exec -t n8n-postgres-1 pg_dumpall -c -U n8n_user > "%BACKUP_DIR%\database_backup.sql" 2>nul

echo %GREEN%Backup created at: %BACKUP_DIR%%NC%
pause
goto MAIN_MENU

:OPEN_BROWSER
echo %BLUE%Opening n8n in browser...%NC%
start http://localhost:5678
goto MAIN_MENU

:CHECK_SERVICES
echo %BLUE%Checking services...%NC%
timeout /t 5 /nobreak >nul

docker compose -f "%COMPOSE_FILE%" ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"

REM Check if n8n is responding
curl -s http://localhost:5678/healthz >nul 2>&1
if !errorlevel! equ 0 (
    echo %GREEN%✓ n8n is responding%NC%
) else (
    echo %YELLOW%⚠ n8n might still be starting up...%NC%
)
goto :eof

:CREATE_ENV_FILE
echo # n8n Environment Configuration > "%ENV_FILE%"
echo POSTGRES_DB=n8n_db >> "%ENV_FILE%"
echo POSTGRES_USER=n8n_user >> "%ENV_FILE%"
echo POSTGRES_PASSWORD=n8n_password >> "%ENV_FILE%"
echo N8N_BASIC_AUTH_USER=admin >> "%ENV_FILE%"
echo N8N_BASIC_AUTH_PASSWORD=admin123 >> "%ENV_FILE%"
echo. >> "%ENV_FILE%"
echo # Add your OpenAI API key here >> "%ENV_FILE%"
echo # OPENAI_API_KEY=your_api_key_here >> "%ENV_FILE%"
goto :eof

:EXIT
echo %GREEN%Thank you for using n8n Resume Optimizer Manager!%NC%
pause
exit /b 0

:EOF