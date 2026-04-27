#!/usr/bin/env bash

# ============================================================
# Fase 5 - Paso 2 Opcional
# Crear servicio systemd para levantar stack Docker Compose
# Sistema operativo: Ubuntu / WSL con systemd activo
# ============================================================
#
# Uso:
#   chmod +x fase5_paso2_crear_servicio_tb_stack_ubuntu.sh
#   ./fase5_paso2_crear_servicio_tb_stack_ubuntu.sh
#
# Uso indicando una ruta específica:
#   ./fase5_paso2_crear_servicio_tb_stack_ubuntu.sh /home/usuario/thingsboard-deploy-template
#
# ============================================================

set -e

echo "============================================="
echo " CREACIÓN DEL SERVICIO TB-STACK"
echo "============================================="

# ------------------------------------------------------------
# Variables generales
# ------------------------------------------------------------
SERVICE_NAME="tb-stack.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
DEFAULT_PROJECT_DIR="$HOME/thingsboard-deploy-template"

# Si el usuario pasa una ruta como argumento, se usa esa ruta.
# Si no, se usa la ruta por defecto.
PROJECT_DIR="${1:-$DEFAULT_PROJECT_DIR}"

# ------------------------------------------------------------
# Validar Ubuntu/Linux
# ------------------------------------------------------------
if [ ! -f /etc/os-release ]; then
    echo "ERROR: No se encontró /etc/os-release. Este script debe ejecutarse en Ubuntu."
    exit 1
fi

. /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    echo "ADVERTENCIA: Este script fue diseñado para Ubuntu."
    echo "Sistema detectado: $PRETTY_NAME"
fi

echo ""
echo "Sistema detectado: $PRETTY_NAME"

# ------------------------------------------------------------
# Validar systemd
# ------------------------------------------------------------
echo ""
echo "Verificando que systemd esté activo..."

if [ "$(ps -p 1 -o comm=)" != "systemd" ]; then
    echo "ERROR: systemd no parece estar activo en esta instancia de Ubuntu/WSL."
    echo ""
    echo "Debe activar systemd antes de crear este servicio."
    echo "Verifique el archivo /etc/wsl.conf y asegúrese de tener:"
    echo ""
    echo "[boot]"
    echo "systemd=true"
    echo ""
    echo "Luego cierre WSL completamente con:"
    echo "wsl --shutdown"
    echo ""
    echo "Y vuelva a abrir Ubuntu."
    exit 1
fi

echo "systemd está activo correctamente."

# ------------------------------------------------------------
# Validar permisos sudo
# ------------------------------------------------------------
echo ""
echo "Verificando permisos sudo..."
sudo -v

if [ $? -ne 0 ]; then
    echo "ERROR: El usuario actual no tiene permisos sudo."
    exit 1
fi

echo "Permisos sudo verificados correctamente."

# ------------------------------------------------------------
# Validar Docker
# ------------------------------------------------------------
echo ""
echo "Verificando Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker no está instalado o no está disponible en el PATH."
    echo "Ejecute primero la fase de instalación de Docker."
    exit 1
fi

docker --version

# ------------------------------------------------------------
# Validar Docker Compose Plugin
# ------------------------------------------------------------
echo ""
echo "Verificando Docker Compose Plugin..."

if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: Docker Compose Plugin no está disponible."
    echo "Verifique que docker-compose-plugin esté instalado."
    exit 1
fi

docker compose version

# ------------------------------------------------------------
# Validar directorio del proyecto
# ------------------------------------------------------------
echo ""
echo "Validando directorio del proyecto:"
echo "$PROJECT_DIR"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: No existe el directorio indicado:"
    echo "$PROJECT_DIR"
    echo ""
    echo "Puede ejecutar este script indicando la ruta correcta, por ejemplo:"
    echo "./fase5_paso2_crear_servicio_tb_stack_ubuntu.sh /home/$USER/thingsboard-deploy-template"
    exit 1
fi

cd "$PROJECT_DIR"

PROJECT_DIR_ABSOLUTE="$(pwd)"

echo ""
echo "Directorio absoluto detectado:"
echo "$PROJECT_DIR_ABSOLUTE"

# ------------------------------------------------------------
# Validar archivo Docker Compose
# ------------------------------------------------------------
echo ""
echo "Validando archivo Docker Compose..."

if [ ! -f "$PROJECT_DIR_ABSOLUTE/docker-compose.yml" ] && [ ! -f "$PROJECT_DIR_ABSOLUTE/compose.yml" ]; then
    echo "ERROR: No se encontró docker-compose.yml ni compose.yml en:"
    echo "$PROJECT_DIR_ABSOLUTE"
    exit 1
fi

echo "Archivo Docker Compose encontrado correctamente."

# ------------------------------------------------------------
# Crear archivo del servicio systemd
# ------------------------------------------------------------
echo ""
echo "Creando servicio systemd en:"
echo "$SERVICE_PATH"

SERVICE_CONTENT="[Unit]
Description=ThingsBoard Docker Stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${PROJECT_DIR_ABSOLUTE}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
"

echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_PATH" > /dev/null

echo "Archivo del servicio creado correctamente."

# ------------------------------------------------------------
# Recargar systemd y habilitar servicio
# ------------------------------------------------------------
echo ""
echo "Recargando systemd..."
sudo systemctl daemon-reload

echo "Habilitando servicio ${SERVICE_NAME}..."
sudo systemctl enable "$SERVICE_NAME"

# ------------------------------------------------------------
# Ejecutar servicio opcionalmente
# ------------------------------------------------------------
echo ""
read -p "¿Desea iniciar ahora el servicio tb-stack? [s/N]: " START_SERVICE

if [[ "$START_SERVICE" =~ ^[sS]$ ]]; then
    echo ""
    echo "Iniciando servicio ${SERVICE_NAME}..."
    sudo systemctl start "$SERVICE_NAME"
else
    echo "Inicio manual omitido por el usuario."
fi

# ------------------------------------------------------------
# Mostrar estado del servicio
# ------------------------------------------------------------
echo ""
echo "Estado actual del servicio:"
sudo systemctl status "$SERVICE_NAME" --no-pager || true

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------
echo ""
echo "============================================="
echo " PROCESO FINALIZADO"
echo "============================================="
echo ""
echo "Servicio creado:"
echo "$SERVICE_PATH"
echo ""
echo "Directorio configurado para Docker Compose:"
echo "$PROJECT_DIR_ABSOLUTE"
echo ""
echo "Comandos útiles:"
echo "sudo systemctl start tb-stack"
echo "sudo systemctl stop tb-stack"
echo "sudo systemctl status tb-stack"
echo "sudo journalctl -u tb-stack -n 100 --no-pager"
echo ""

exit 0
