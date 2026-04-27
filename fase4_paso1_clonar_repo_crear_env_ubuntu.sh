#!/usr/bin/env bash

# ============================================================
# Fase 4 - Paso 1
# Clonar repositorio de ThingsBoard y crear archivo .env
# Sistema operativo: Ubuntu
# ============================================================

set -e

echo "============================================="
echo " CLONAR REPOSITORIO Y CREAR ARCHIVO .ENV"
echo "============================================="

# ------------------------------------------------------------
# Variables generales
# ------------------------------------------------------------
REPO_URL="https://github.com/luiscastrillo97/thingsboard-deploy-template.git"
PROJECT_DIR="thingsboard-deploy-template"
ENV_FILE=".env"

# ------------------------------------------------------------
# Validar que el script se ejecute en Ubuntu/Linux
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
# Verificar e instalar Git si no está disponible
# ------------------------------------------------------------
echo ""
echo "Verificando instalación de Git..."

if ! command -v git >/dev/null 2>&1; then
    echo "Git no está instalado. Instalando Git..."
    sudo apt update
    sudo apt install -y git
else
    echo "Git ya se encuentra instalado."
fi

git --version

# ------------------------------------------------------------
# Clonar repositorio
# ------------------------------------------------------------
echo ""
echo "Preparando clonación del repositorio:"
echo "$REPO_URL"

if [ -d "$PROJECT_DIR" ]; then
    echo ""
    echo "La carpeta '$PROJECT_DIR' ya existe."
    echo "No se clonará nuevamente el repositorio para evitar sobrescribir información."
else
    git clone "$REPO_URL"
    echo "Repositorio clonado correctamente."
fi

# ------------------------------------------------------------
# Ingresar a la carpeta del proyecto
# ------------------------------------------------------------
if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: No se encontró la carpeta del proyecto '$PROJECT_DIR'."
    exit 1
fi

cd "$PROJECT_DIR"

echo ""
echo "Ubicación actual del proyecto:"
pwd

# ------------------------------------------------------------
# Crear archivo .env
# ------------------------------------------------------------
echo ""
echo "Creando archivo de variables de entorno: $ENV_FILE"

if [ -f "$ENV_FILE" ]; then
    BACKUP_FILE=".env.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$ENV_FILE" "$BACKUP_FILE"
    echo "Ya existía un archivo .env. Se creó copia de seguridad: $BACKUP_FILE"
fi

cat > "$ENV_FILE" <<'EOF'
# Postgres
POSTGRES_IMAGE=postgres:16
POSTGRES_DB=thingsboard
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_PORT=5432

# Kafka
KAFKA_IMAGE=bitnamilegacy/kafka:4.0
KAFKA_PLAINTEXT_PORT=9092

# ThingsBoard
TB_IMAGE=thingsboard/tb-node:4.1.0
TB_HTTP_PORT=8080
TB_TRANSPORT_API_PORT=7070
TB_MQTT_PORT=1883
TB_MQTTS_PORT=8883
TB_COAP_UDP_PORT_RANGE=5683-5688
EOF

echo "Archivo .env creado correctamente."

# ------------------------------------------------------------
# Mostrar contenido generado
# ------------------------------------------------------------
echo ""
echo "Contenido del archivo .env:"
echo "---------------------------------------------"
cat "$ENV_FILE"
echo "---------------------------------------------"

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------
echo ""
echo "============================================="
echo " PROCESO FINALIZADO"
echo "============================================="
echo ""
echo "Repositorio disponible en: $(pwd)"
echo "Archivo de variables de entorno creado en: $(pwd)/$ENV_FILE"
echo ""

exit 0
