# ============================================================
# Fase 5 - Paso 1 - Versión Windows Server 2022
# Crear script de arranque WSL y tarea programada en Windows
# ============================================================
# Sistema operativo objetivo: Windows Server 2022
# Ejecutar en PowerShell como Administrador
# ============================================================
#
# Objetivo:
# Crear un script C:\wsl-boot.cmd y una tarea programada llamada
# "WSL-Boot" para iniciar WSL y Docker automáticamente al arrancar
# Windows Server 2022 o al iniciar sesión cualquier usuario.
#
# La tarea se configura con:
# - Ejecución con privilegios elevados.
# - Ejecución al iniciar el sistema.
# - Ejecución al iniciar sesión.
# - Reintento cada 5 minutos hasta 3 veces si falla.
# - Permitir ejecución bajo demanda.
# - Ejecutar tan pronto como sea posible si se pierde una ejecución.
# - Activar el equipo para ejecutar la tarea.
#
# Nota:
# En Windows Server 2022, para usar "Run whether user is logged on or not",
# puede ser necesario registrar la tarea con credenciales del usuario.
# Este script intenta usar el modo S4U para evitar solicitar contraseña.
# Si el entorno aplica políticas que bloquean S4U, se muestra una alternativa
# usando schtasks.
# ============================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " CREACIÓN DE TAREA WSL-BOOT - WINDOWS SERVER 2022" -ForegroundColor Cyan
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
# Validar versión del sistema operativo
# ------------------------------------------------------------
Write-Host "`nVerificando sistema operativo..." -ForegroundColor Cyan

$OS = Get-CimInstance Win32_OperatingSystem
$OSCaption = $OS.Caption
$OSVersion = $OS.Version

Write-Host "Sistema detectado: $OSCaption" -ForegroundColor White
Write-Host "Versión detectada: $OSVersion" -ForegroundColor White

if ($OSCaption -notmatch "Windows Server 2022") {
    Write-Host "`nADVERTENCIA: Este script fue diseñado para Windows Server 2022." -ForegroundColor Yellow
    Write-Host "Puede funcionar en otros sistemas compatibles con WSL2, pero no es el entorno objetivo." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Variables generales
# ------------------------------------------------------------
$TaskName = "WSL-Boot"
$BootScriptPath = "C:\wsl-boot.cmd"
$CurrentUser = "$env:USERDOMAIN\$env:USERNAME"

Write-Host "`nUsuario actual detectado: $CurrentUser" -ForegroundColor White

# ------------------------------------------------------------
# Validar disponibilidad de wsl.exe
# ------------------------------------------------------------
Write-Host "`nVerificando disponibilidad de WSL..." -ForegroundColor Cyan

$wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue

if (-not $wslCommand) {
    Write-Host "ERROR: No se encontró wsl.exe en el sistema." -ForegroundColor Red
    Write-Host "Verifique que WSL esté instalado antes de continuar." -ForegroundColor Yellow
    exit 1
}

Write-Host "WSL disponible correctamente." -ForegroundColor Green

# ------------------------------------------------------------
# Verificar estado de WSL
# ------------------------------------------------------------
Write-Host "`nEstado actual de WSL:" -ForegroundColor Cyan
try {
    wsl --status
}
catch {
    Write-Host "ADVERTENCIA: No fue posible consultar el estado de WSL." -ForegroundColor Yellow
}

Write-Host "`nDistribuciones WSL instaladas:" -ForegroundColor Cyan
try {
    wsl --list --verbose
}
catch {
    Write-Host "ADVERTENCIA: No fue posible listar las distribuciones WSL." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Crear script de arranque WSL
# ------------------------------------------------------------
Write-Host "`nCreando script de arranque en: $BootScriptPath" -ForegroundColor Cyan

$BootScriptContent = @'
@echo off
wsl.exe --exec bash -lc "dbus-launch true && systemctl start docker"
'@

try {
    Set-Content -Path $BootScriptPath -Value $BootScriptContent -Encoding ASCII -Force
    Write-Host "Script de arranque creado correctamente." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: No fue posible crear el script de arranque." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Eliminar tarea anterior si ya existe
# ------------------------------------------------------------
Write-Host "`nVerificando si ya existe una tarea llamada '$TaskName'..." -ForegroundColor Cyan

$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Host "La tarea '$TaskName' ya existe. Será reemplazada." -ForegroundColor Yellow

    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Tarea anterior eliminada correctamente." -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: No fue posible eliminar la tarea anterior." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# ------------------------------------------------------------
# Crear acción de la tarea
# ------------------------------------------------------------
Write-Host "`nConfigurando acción de la tarea programada..." -ForegroundColor Cyan

$Action = New-ScheduledTaskAction `
    -Execute "C:\Windows\System32\cmd.exe" `
    -Argument "/c `"$BootScriptPath`""

# ------------------------------------------------------------
# Crear disparadores de la tarea
# ------------------------------------------------------------
Write-Host "Configurando disparadores: al iniciar sistema y al iniciar sesión..." -ForegroundColor Cyan

$TriggerAtStartup = New-ScheduledTaskTrigger -AtStartup
$TriggerAtLogOn = New-ScheduledTaskTrigger -AtLogOn

# ------------------------------------------------------------
# Configurar condiciones y ajustes
# ------------------------------------------------------------
Write-Host "Configurando condiciones y ajustes de ejecución..." -ForegroundColor Cyan

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -WakeToRun `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5) `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0)

# ------------------------------------------------------------
# Configurar principal de seguridad
# ------------------------------------------------------------
# S4U permite ejecutar la tarea aunque el usuario no haya iniciado sesión,
# sin guardar contraseña. En algunas políticas de Windows Server puede estar
# restringido; si falla, se mostrará una alternativa.
# ------------------------------------------------------------
Write-Host "Configurando usuario propietario y privilegios elevados..." -ForegroundColor Cyan

$Principal = New-ScheduledTaskPrincipal `
    -UserId $CurrentUser `
    -LogonType S4U `
    -RunLevel Highest

# ------------------------------------------------------------
# Registrar tarea programada
# ------------------------------------------------------------
Write-Host "`nRegistrando tarea programada '$TaskName'..." -ForegroundColor Cyan

$TaskCreated = $false

try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger @($TriggerAtStartup, $TriggerAtLogOn) `
        -Settings $Settings `
        -Principal $Principal `
        -Description "Arranca WSL y Docker automáticamente al iniciar Windows Server 2022 o al iniciar sesión." `
        -Force | Out-Null

    $TaskCreated = $true
    Write-Host "Tarea programada creada correctamente." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: No fue posible crear la tarea programada con LogonType S4U." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host "`nAlternativa para Windows Server 2022:" -ForegroundColor Yellow
    Write-Host "Cree la tarea manualmente o use schtasks solicitando contraseña del usuario." -ForegroundColor Yellow
    Write-Host "Ejemplo:" -ForegroundColor Yellow
    Write-Host "schtasks /Create /TN `"WSL-Boot`" /TR `"C:\wsl-boot.cmd`" /SC ONSTART /RL HIGHEST /RU `"$CurrentUser`" /RP * /F" -ForegroundColor White
    exit 1
}

# ------------------------------------------------------------
# Ejecutar tarea una vez creada
# ------------------------------------------------------------
if ($TaskCreated) {
    Write-Host "`nEjecutando la tarea programada por primera vez..." -ForegroundColor Cyan

    try {
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 5
        Write-Host "Tarea ejecutada correctamente." -ForegroundColor Green
    }
    catch {
        Write-Host "ADVERTENCIA: La tarea fue creada, pero no se pudo ejecutar automáticamente." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
# Mostrar estado de la tarea
# ------------------------------------------------------------
Write-Host "`nEstado actual de la tarea:" -ForegroundColor White
Get-ScheduledTask -TaskName $TaskName | Format-List TaskName, State, Author

Write-Host "`nInformación de la última ejecución:" -ForegroundColor White
Get-ScheduledTaskInfo -TaskName $TaskName | Format-List LastRunTime, LastTaskResult, NextRunTime, NumberOfMissedRuns

# ------------------------------------------------------------
# Mostrar contenido del script creado
# ------------------------------------------------------------
Write-Host "`nContenido de $BootScriptPath:" -ForegroundColor White
Get-Content $BootScriptPath

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " PROCESO FINALIZADO" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Write-Host "`nScript creado en:" -ForegroundColor Green
Write-Host "$BootScriptPath" -ForegroundColor White

Write-Host "`nTarea programada creada:" -ForegroundColor Green
Write-Host "$TaskName" -ForegroundColor White

Write-Host "`nLa tarea está orientada a Windows Server 2022 y se ejecutará al iniciar Windows y al iniciar sesión." -ForegroundColor Yellow
Write-Host "También puede ejecutarse manualmente desde el Programador de tareas." -ForegroundColor Yellow

exit 0
