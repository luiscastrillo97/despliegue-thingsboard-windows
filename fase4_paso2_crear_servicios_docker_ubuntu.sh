#!/usr/bin/env bash

# ============================================================
# Fase 4 - Paso 2
# Crear e iniciar servicios Docker con Docker Compose
# Sistema operativo: Ubuntu
# ============================================================

set -e

echo "============================================="
echo " CREACIÓN E INICIO DE SERVICIOS DOCKER"
echo "============================================="

# ------------------------------------------------------------
# Variables generales
# ------------------------------------------------------------
PROJECT_DIR="thingsboard-deploy-template"

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
# Validar disponibilidad de Docker
# ------------------------------------------------------------
echo ""
echo "Verificando instalación de Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker no está instalado o no está disponible en el PATH."
    echo "Ejecute primero la Fase 3 de instalación y configuración de Docker."
    exit 1
fi

docker --version

# ------------------------------------------------------------
# Validar disponibilidad de Docker Compose Plugin
# ------------------------------------------------------------
echo ""
echo "Verificando Docker Compose Plugin..."

if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: Docker Compose Plugin no está disponible."
    echo "Verifique que el paquete docker-compose-plugin esté instalado."
    exit 1
fi

docker compose version

# ------------------------------------------------------------
# Validar que el servicio Docker esté activo
# ------------------------------------------------------------
echo ""
echo "Verificando estado del servicio Docker..."

if command -v systemctl >/dev/null 2>&1; then
    if ! systemctl is-active --quiet docker; then
        echo "Docker no está activo. Intentando iniciar el servicio..."
        sudo systemctl start docker
    fi

    if systemctl is-active --quiet docker; then
        echo "Docker está activo y en ejecución."
    else
        echo "ERROR: No fue posible iniciar Docker."
        exit 1
    fi
else
    echo "ADVERTENCIA: systemctl no está disponible. Se omite validación del servicio Docker."
fi

# ------------------------------------------------------------
# Ubicar carpeta del proyecto
# ------------------------------------------------------------
echo ""
echo "Ubicando carpeta del proyecto: $PROJECT_DIR"

if [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
elif [ -d "$HOME/$PROJECT_DIR" ]; then
    cd "$HOME/$PROJECT_DIR"
else
    echo "ERROR: No se encontró la carpeta '$PROJECT_DIR'."
    echo "Ejecute primero la Fase 4 - Paso 1 para clonar el repositorio y crear el archivo .env."
    exit 1
fi

echo "Ubicación actual del proyecto:"
pwd

# ------------------------------------------------------------
# Validar archivo docker-compose.yml
# ------------------------------------------------------------
echo ""
echo "Validando archivo Docker Compose..."

if [ ! -f "docker-compose.yml" ] && [ ! -f "compose.yml" ]; then
    echo "ERROR: No se encontró docker-compose.yml ni compose.yml en la carpeta del proyecto."
    exit 1
fi

echo "Archivo Docker Compose encontrado."

# ------------------------------------------------------------
# Validar archivo .env
# ------------------------------------------------------------
echo ""
echo "Validando archivo .env..."

if [ ! -f ".env" ]; then
    echo "ERROR: No se encontró el archivo .env en la carpeta del proyecto."
    echo "Ejecute primero la Fase 4 - Paso 1."
    exit 1
fi

echo "Archivo .env encontrado."

# ------------------------------------------------------------
# Inicializar ThingsBoard CE
# ------------------------------------------------------------
echo ""
echo "Inicializando ThingsBoard CE..."
echo "Comando:"
echo "docker compose run --rm -e INSTALL_TB=true -e LOAD_DEMO=true thingsboard-ce"

docker compose run --rm \
    -e INSTALL_TB=true \
    -e LOAD_DEMO=true \
    thingsboard-ce

echo "Inicialización de ThingsBoard CE finalizada correctamente."

# ------------------------------------------------------------
# Levantar servicios en segundo plano
# ------------------------------------------------------------
echo ""
echo "Levantando servicios Docker en segundo plano..."
echo "Comando:"
echo "docker compose up -d"

docker compose up -d

echo "Servicios Docker iniciados correctamente."

# ------------------------------------------------------------
# Mostrar estado de los contenedores
# ------------------------------------------------------------
echo ""
echo "Estado actual de los servicios:"
docker compose ps

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------
echo ""
echo "============================================="
echo " PROCESO FINALIZADO"
echo "============================================="
echo ""
echo "Los servicios fueron creados e iniciados correctamente."
echo "Puede revisar los logs con:"
echo "docker compose logs -f"
echo ""
echo "Si se está usando el puerto HTTP por defecto, ThingsBoard debería quedar disponible en:"
echo "http://localhost:8080"
echo ""

exit 0
