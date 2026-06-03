# ============================================================
# Fase 0 - Paso 1
# Verificar soporte de virtualización en Windows
# ============================================================
# Sistema operativo: Windows / Windows Server 2022
# Ejecutar preferiblemente en PowerShell como Administrador
# ============================================================
#
# Criterio práctico para este despliegue:
# - VirtualizationFirmwareEnabled = True es suficiente para continuar
#   con WSL2 y Docker en la mayoría de escenarios.
# - VMMonitorModeExtensions puede aparecer en False y no necesariamente
#   impide instalar o usar Docker con WSL2.
# ============================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " VALIDACIÓN DE VIRTUALIZACIÓN DEL SISTEMA" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# ------------------------------------------------------------
# Obtener información del procesador
# ------------------------------------------------------------
Write-Host "`nConsultando información del procesador..." -ForegroundColor Cyan

$cpuInfo = Get-CimInstance Win32_Processor |
Select-Object Name, VirtualizationFirmwareEnabled, VMMonitorModeExtensions

# ------------------------------------------------------------
# Mostrar resultados
# ------------------------------------------------------------
Write-Host "`nInformación del procesador:" -ForegroundColor White
$cpuInfo | Format-Table -AutoSize

# ------------------------------------------------------------
# Validación principal
# ------------------------------------------------------------
Write-Host "`nResultado de la validación:" -ForegroundColor White

if ($cpuInfo.VirtualizationFirmwareEnabled -eq $true) {
    Write-Host "✔ Virtualización habilitada correctamente desde BIOS/UEFI." -ForegroundColor Green
    Write-Host "El servidor puede continuar con la instalación de WSL2 y Docker." -ForegroundColor Green

    if ($cpuInfo.VMMonitorModeExtensions -eq $true) {
        Write-Host "VMMonitorModeExtensions aparece en True." -ForegroundColor Green
    }
    else {
        Write-Host "Nota: VMMonitorModeExtensions aparece en False." -ForegroundColor Yellow
        Write-Host "Esto no impide necesariamente el uso de WSL2/Docker en este despliegue." -ForegroundColor Yellow
    }

    exit 0
}
else {
    Write-Host "⚠ Advertencia: la virtualización NO está habilitada desde BIOS/UEFI." -ForegroundColor Red
    Write-Host "`nAcciones recomendadas:" -ForegroundColor Yellow
    Write-Host "- Ingresar a BIOS/UEFI." -ForegroundColor Yellow
    Write-Host "- Activar Intel VT-x o AMD-V, según corresponda." -ForegroundColor Yellow
    Write-Host "- Guardar cambios y reiniciar el sistema." -ForegroundColor Yellow
    Write-Host "- Ejecutar nuevamente este script." -ForegroundColor Yellow

    exit 1
}
