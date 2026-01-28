@echo off
REM Script para limpar cache Helm e reinstalar crm-backend no Windows CMD

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Helm Clean Install - CRM Backend
echo ========================================
echo.

REM Cores (usando findstr para simular)
echo [*] Limpando cache Helm...
echo.

REM Limpar cache Helm
if exist "%APPDATA%\helm\cache" (
    echo   Deletando: %APPDATA%\helm\cache
    rmdir /s /q "%APPDATA%\helm\cache" >nul 2>&1
)

if exist "%USERPROFILE%\.cache\helm" (
    echo   Deletando: %USERPROFILE%\.cache\helm
    rmdir /s /q "%USERPROFILE%\.cache\helm" >nul 2>&1
)

echo.
echo [+] Cache limpo!
echo.

REM Deletar release anterior
echo [*] Deletando release anterior...
echo.

helm uninstall crm-backend -n crm-backend --ignore-not-found

echo.
echo [+] Release deletada!
echo.

REM Aguardar
echo [*] Aguardando 5 segundos...
timeout /t 5 /nobreak

echo.
echo [*] Instalando crm-backend...
echo.

REM Instalar novo
helm upgrade --install crm-backend .\helm-charts\crm-backend ^
  --namespace crm-backend ^
  --create-namespace ^
  --values .\helm-charts\crm-backend\values.yaml ^
  --wait ^
  --timeout 5m

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [+] Instalacao concluida com sucesso!
    echo.
    
    echo [*] Verificando pods...
    echo.
    kubectl get pods -n crm-backend
    
    echo.
    echo [+] Sucesso!
) else (
    echo.
    echo [-] Erro na instalacao!
    echo.
    exit /b 1
)

pause
