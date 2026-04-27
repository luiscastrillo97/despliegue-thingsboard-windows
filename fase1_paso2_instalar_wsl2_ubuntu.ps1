# ============================================================
# Fase 1 - Paso 2 - Versión 2
# Instalar / actualizar WSL2 e instalar Ubuntu
# ============================================================
# Sistema operativo: Windows
# Ejecutar en PowerShell como Administrador
# ============================================================
#
# Esta versión corrige el flujo para escenarios donde aparece:
# "An error occurred during installation. Distribution Name: 'Ubuntu'
#  Error Code: 0x8000ffff"
#
# Estrategia:
# 1. Verificar permisos de administrador.
# 2. Verificar características requeridas.
# 3. Actualizar WSL antes de instalar Ubuntu.
# 4. Usar --web-download cuando esté disponible para evitar dependencias
#    problemáticas de Microsoft Store.
# 5. Configurar WSL 2 como versión predeterminada.
# 6. Instalar Ubuntu.
# ============================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " INSTALACIÓN DE WSL2 Y UBUNTU - VERSIÓN 2" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# ------------------------------------------------------------
# Validar ejecución como administrador
# ------------------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`nERROR: Este script debe ejecutarse como Administrador." -ForegroundColor Red
    Write-Host "Abra PowerShell como Administrador y vuelva a ejecutar el script." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nPermisos de administrador verificados correctamente." -ForegroundColor Green

# ------------------------------------------------------------
# Verificar disponibilidad de wsl.exe
# ------------------------------------------------------------
Write-Host "`nVerificando disponibilidad de wsl.exe..." -ForegroundColor Cyan

$wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue

if (-not $wslCommand) {
    Write-Host "ERROR: No se encontró wsl.exe en el sistema." -ForegroundColor Red
    Write-Host "Verifique que la Fase 1 - Paso 1 se haya ejecutado y que el servidor haya sido reiniciado." -ForegroundColor Yellow
    exit 1
}

Write-Host "wsl.exe está disponible." -ForegroundColor Green

# ------------------------------------------------------------
# Verificar características requeridas
# ------------------------------------------------------------
Write-Host "`nVerificando características de Windows requeridas..." -ForegroundColor Cyan

$RequiredFeatures = @(
    "Microsoft-Windows-Subsystem-Linux",
    "VirtualMachinePlatform"
)

foreach ($feature in $RequiredFeatures) {
    $featureState = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue

    if ($null -eq $featureState) {
        Write-Host "ADVERTENCIA: No fue posible consultar la característica: $feature" -ForegroundColor Yellow
        continue
    }

    Write-Host "$feature : $($featureState.State)" -ForegroundColor White

    if ($featureState.State -ne "Enabled") {
        Write-Host "ERROR: La característica '$feature' no está habilitada." -ForegroundColor Red
        Write-Host "Ejecute primero la Fase 1 - Paso 1 y reinicie el servidor." -ForegroundColor Yellow
        exit 1
    }
}

# ------------------------------------------------------------
# Mostrar estado actual de WSL
# ------------------------------------------------------------
Write-Host "`nEstado actual de WSL:" -ForegroundColor Cyan
wsl --status

# ------------------------------------------------------------
# Actualizar WSL
# ------------------------------------------------------------
Write-Host "`nActualizando WSL..." -ForegroundColor Cyan
Write-Host "Intentando primero con: wsl --update --web-download" -ForegroundColor White

$UpdateSucceeded = $false

try {
    wsl --update --web-download
    if ($LASTEXITCODE -eq 0) {
        $UpdateSucceeded = $true
        Write-Host "WSL actualizado correctamente usando --web-download." -ForegroundColor Green
    }
}
catch {
    Write-Host "No fue posible actualizar WSL con --web-download." -ForegroundColor Yellow
}

if (-not $UpdateSucceeded) {
    Write-Host "`nIntentando actualización estándar: wsl --update" -ForegroundColor White

    try {
        wsl --update
        if ($LASTEXITCODE -eq 0) {
            $UpdateSucceeded = $true
            Write-Host "WSL actualizado correctamente." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "No fue posible actualizar WSL con el método estándar." -ForegroundColor Yellow
    }
}

if (-not $UpdateSucceeded) {
    Write-Host "`nADVERTENCIA: No se pudo confirmar la actualización de WSL." -ForegroundColor Yellow
    Write-Host "Se continuará con el proceso, pero si aparece 0x8000ffff, ejecute los comandos de reparación indicados al final." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Apagar WSL para limpiar estado
# ------------------------------------------------------------
Write-Host "`nReiniciando estado de WSL..." -ForegroundColor Cyan
wsl --shutdown

# ------------------------------------------------------------
# Configurar WSL 2 como versión predeterminada
# ------------------------------------------------------------
Write-Host "`nConfigurando WSL 2 como versión predeterminada..." -ForegroundColor Cyan

wsl --set-default-version 2

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No fue posible configurar WSL 2 como versión predeterminada." -ForegroundColor Red
    exit 1
}

Write-Host "WSL 2 configurado como versión predeterminada." -ForegroundColor Green

# ------------------------------------------------------------
# Listar distribuciones disponibles en línea
# ------------------------------------------------------------
Write-Host "`nDistribuciones disponibles en línea:" -ForegroundColor Cyan
wsl --list --online

# ------------------------------------------------------------
# Verificar si Ubuntu ya está instalada
# ------------------------------------------------------------
Write-Host "`nVerificando distribuciones instaladas..." -ForegroundColor Cyan

$InstalledDistros = wsl --list --quiet 2>$null

if ($InstalledDistros -match "^Ubuntu$") {
    Write-Host "Ubuntu ya se encuentra instalada." -ForegroundColor Green
}
else {
    Write-Host "Ubuntu no está instalada. Iniciando instalación..." -ForegroundColor Cyan

    $InstallSucceeded = $false

    # Primer intento: con --web-download
    Write-Host "`nIntentando instalación con: wsl --install --distribution Ubuntu --web-download" -ForegroundColor White

    try {
        wsl --install --distribution Ubuntu --web-download

        if ($LASTEXITCODE -eq 0) {
            $InstallSucceeded = $true
            Write-Host "Ubuntu instalada correctamente usando --web-download." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Primer intento fallido." -ForegroundColor Yellow
    }

    # Segundo intento: comando tradicional
    if (-not $InstallSucceeded) {
        Write-Host "`nIntentando instalación con: wsl --install -d Ubuntu" -ForegroundColor White

        try {
            wsl --install -d Ubuntu

            if ($LASTEXITCODE -eq 0) {
                $InstallSucceeded = $true
                Write-Host "Ubuntu instalada correctamente." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Segundo intento fallido." -ForegroundColor Yellow
        }
    }

    if (-not $InstallSucceeded) {
        Write-Host "`nERROR: No fue posible instalar Ubuntu." -ForegroundColor Red
        Write-Host "Si el error mostrado fue 0x8000ffff, se recomienda ejecutar la rutina de reparación manual descrita abajo." -ForegroundColor Yellow

        Write-Host "`nComandos sugeridos en PowerShell como Administrador:" -ForegroundColor Cyan
        Write-Host "DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor White
        Write-Host "SFC /SCANNOW" -ForegroundColor White
        Write-Host "wsl --update --web-download" -ForegroundColor White
        Write-Host "wsl --shutdown" -ForegroundColor White
        Write-Host ".\fase1_paso2_instalar_wsl2_ubuntu_v2.ps1" -ForegroundColor White

        exit 1
    }
}

# ------------------------------------------------------------
# Mostrar estado final
# ------------------------------------------------------------
Write-Host "`nEstado final de WSL:" -ForegroundColor Cyan
wsl --status

Write-Host "`nDistribuciones instaladas:" -ForegroundColor Cyan
wsl --list --verbose

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " PROCESO FINALIZADO" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Write-Host "`nWSL2 y Ubuntu fueron procesados correctamente." -ForegroundColor Green
Write-Host "Si Ubuntu se instaló por primera vez, ábrala desde el menú de inicio para crear el usuario y contraseña de Linux." -ForegroundColor Yellow
Write-Host "Si Windows solicita reinicio, reinicie antes de continuar con la Fase 2." -ForegroundColor Yellow

exit 0
