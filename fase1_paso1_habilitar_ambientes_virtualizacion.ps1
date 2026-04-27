# ============================================================
# Fase 1 - Paso 1
# Habilitar ambientes de virtualización en Windows
# ============================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " HABILITACIÓN DE AMBIENTES DE VIRTUALIZACIÓN" -ForegroundColor Cyan
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
# Lista de características a habilitar
# ------------------------------------------------------------
$features = @(
    "Microsoft-Windows-Subsystem-Linux",
    "VirtualMachinePlatform",
    "Microsoft-Hyper-V"
)

# ------------------------------------------------------------
# Habilitar características requeridas
# ------------------------------------------------------------
foreach ($feature in $features) {
    Write-Host "`nHabilitando característica: $feature" -ForegroundColor Cyan

    try {
        Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName $feature `
            -All `
            -NoRestart `
            -ErrorAction Stop

        Write-Host "Característica habilitada o ya disponible: $feature" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR al habilitar la característica: $feature" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " PROCESO FINALIZADO" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Write-Host "`nLas características de virtualización fueron procesadas correctamente." -ForegroundColor Green
Write-Host "Es necesario reiniciar el sistema para aplicar los cambios." -ForegroundColor Yellow

Write-Host "`nDespués del reinicio, continúe con el siguiente paso de la fase." -ForegroundColor White

exit 0
