#!/usr/bin/env bash

# ============================================================
# Fase 3
# Instalación y configuración de Docker en Ubuntu
# ============================================================

set -e

echo "============================================="
echo " INSTALACIÓN Y CONFIGURACIÓN DE DOCKER"
echo "============================================="

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
# Validar privilegios sudo
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
# Desinstalar versiones anteriores o paquetes en conflicto
# ------------------------------------------------------------
echo ""
echo "Desinstalando versiones anteriores o paquetes en conflicto de Docker..."

OLD_PACKAGES=$(dpkg --get-selections \
    docker.io \
    docker-compose \
    docker-compose-v2 \
    docker-doc \
    podman-docker \
    containerd \
    runc 2>/dev/null | cut -f1 || true)

if [ -n "$OLD_PACKAGES" ]; then
    sudo apt remove -y $OLD_PACKAGES
    echo "Paquetes anteriores eliminados correctamente."
else
    echo "No se encontraron paquetes anteriores para desinstalar."
fi

# ------------------------------------------------------------
# Actualizar repositorios e instalar dependencias base
# ------------------------------------------------------------
echo ""
echo "Actualizando repositorios del sistema..."
sudo apt update

echo ""
echo "Instalando dependencias requeridas..."
sudo apt install -y ca-certificates curl

# ------------------------------------------------------------
# Agregar llave GPG oficial de Docker
# ------------------------------------------------------------
echo ""
echo "Configurando llave GPG oficial de Docker..."

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Llave GPG de Docker configurada correctamente."

# ------------------------------------------------------------
# Agregar repositorio oficial de Docker a APT
# ------------------------------------------------------------
echo ""
echo "Agregando repositorio oficial de Docker..."

UBUNTU_SUITE="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_SUITE}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "Repositorio Docker agregado para la suite: ${UBUNTU_SUITE}"

# ------------------------------------------------------------
# Actualizar repositorios luego de agregar Docker
# ------------------------------------------------------------
echo ""
echo "Actualizando repositorios con la fuente oficial de Docker..."
sudo apt update

# ------------------------------------------------------------
# Instalar Docker Engine y plugins
# ------------------------------------------------------------
echo ""
echo "Instalando Docker Engine, CLI, Containerd, Buildx y Docker Compose Plugin..."

sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "Paquetes de Docker instalados correctamente."

# ------------------------------------------------------------
# Habilitar e iniciar el servicio Docker
# ------------------------------------------------------------
echo ""
echo "Habilitando e iniciando el servicio Docker..."

sudo systemctl enable docker
sudo systemctl start docker

# ------------------------------------------------------------
# Verificar estado del servicio Docker
# ------------------------------------------------------------
echo ""
echo "Verificando estado del servicio Docker..."

if systemctl is-enabled docker >/dev/null 2>&1; then
    echo "Docker está habilitado para iniciar con el sistema."
else
    echo "ADVERTENCIA: Docker no está habilitado. Intentando habilitarlo..."
    sudo systemctl enable docker
fi

if systemctl is-active --quiet docker; then
    echo "Docker está activo y en ejecución."
else
    echo "ADVERTENCIA: Docker no está activo. Intentando iniciarlo manualmente..."
    sudo systemctl start docker
fi

echo ""
echo "Estado actual de Docker:"
sudo systemctl status docker --no-pager

# ------------------------------------------------------------
# Verificar versiones instaladas
# ------------------------------------------------------------
echo ""
echo "Versiones instaladas:"
docker --version
docker compose version

# ------------------------------------------------------------
# Prueba opcional con hello-world
# ------------------------------------------------------------
echo ""
read -p "¿Desea ejecutar una prueba con 'hello-world'? [s/N]: " RUN_TEST

if [[ "$RUN_TEST" =~ ^[sS]$ ]]; then
    echo ""
    echo "Ejecutando prueba de Docker con hello-world..."
    sudo docker run hello-world
else
    echo "Prueba hello-world omitida por el usuario."
fi

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------
echo ""
echo "============================================="
echo " PROCESO FINALIZADO"
echo "============================================="
echo ""
echo "Docker fue instalado y configurado correctamente en Ubuntu."
echo ""
echo "Nota:"
echo "Por defecto, Docker requiere sudo para ejecutar comandos."
echo "En un paso posterior se puede agregar el usuario actual al grupo docker si se desea usar Docker sin sudo."
echo ""

exit 0
