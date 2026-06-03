# Despliegue automatizado de ThingsBoard CE sobre Windows Server 2022 + WSL2 + Docker

Este repositorio contiene scripts para automatizar el despliegue de **ThingsBoard Community Edition (CE)** usando **Docker** dentro de **Ubuntu sobre WSL2**, ejecutado desde un servidor con **Windows Server 2022**.

El objetivo es reducir la intervención manual durante la instalación, configuración y arranque automático de ThingsBoard y sus servicios asociados.

---

# Resumen de despliegue rápido

Esta sección resume el orden de ejecución de los scripts y comandos principales para realizar el despliegue de ThingsBoard CE sobre **Windows Server 2022 + WSL2 + Ubuntu + Docker**.

> Para detalles, validaciones, explicación de errores y recomendaciones, consulte las secciones posteriores del documento.

---

## 0. Descargar archivo .zip del repositorio y descomprimirlo

Descargar archivo .zip que contiene los scripts de despliegue en Windows. Descomprimir la carpeta y una vez dentro de la carpeta donde están los scripts, abrir PowerShell en esa ubicación.

---

## 1. En Windows PowerShell

Habilitar las características requeridas de Windows:

```powershell
.\fase0_paso1_habilitar_ambientes_virtualizacion.ps1
```

Reiniciar el servidor:

```powershell
Restart-Computer
```

Después del reinicio, ejecutar la validación de virtualización:

```powershell
.\fase1_paso1_verificar_virtualizacion.ps1
```
---

## 2. Instalar Ubuntu / WSL

Instalar o actualizar WSL2 e instalar Ubuntu:

```powershell
.\fase1_paso2_instalar_wsl2_ubuntu.ps1
```

El sistema le solicitará crear usuario y contraseña en Ubuntu, por lo que va a ser necesario que introduzca los campos requeridos.

Al finalizar salga de WSL:

```powershell
exit
```

### Paso opcional, pero, útil: Validar que systemd esté activo

Abrir Ubuntu desde el menú de inicio y crear el usuario y contraseña de Linux.

Verificar que `systemd` esté activo:

```bash
ps -p 1 -o comm=
```

El resultado esperado es:

```text
systemd
```

Si no aparece `systemd`, crear o editar el archivo:

```bash
sudo nano /etc/wsl.conf
```

Agregar:

```ini
[boot]
systemd=true
```

Luego, desde PowerShell, cerrar WSL:

```powershell
wsl --shutdown
```

Volver a abrir Ubuntu y verificar nuevamente:

```bash
ps -p 1 -o comm=
```

---

## 3. Instalar Docker en Ubuntu

Se sugiere que ingrese a WSL realizando la búsqueda en la barra de Windows y elegir Ubuntu. Una vez dentro de Ubuntu, se recomienda crear una carpeta y clonar el repositorio de los scripts de despliegue dentro de esa carpeta usando el comando:

```bash
git clone https://github.com/luiscastrillo97/despliegue-thingsboard-windows.git .
```

Asimismo, se recomienda entrar como usuario root en Ubuntu, ingresando:

```bash
sudo su
```

Ahora sí. Vamos!

Ejecutar en Ubuntu:

```bash
chmod +x fase3_instalar_configurar_docker_ubuntu.sh && ./fase3_instalar_configurar_docker_ubuntu.sh
```

Verificar Docker:

```bash
docker --version
docker compose version
sudo systemctl status docker
```

---

## 4. Clonar el proyecto y crear el archivo `.env`

Ejecutar en Ubuntu:

```bash
chmod +x fase4_paso1_clonar_repo_crear_env_ubuntu.sh && ./fase4_paso1_clonar_repo_crear_env_ubuntu.sh
```

Este paso clona el repositorio:

```bash
git clone https://github.com/luiscastrillo97/thingsboard-deploy-template.git
```

y crea el archivo `.env` dentro de la carpeta del proyecto.

**Nota:** _Se recomienda cambiar al menos la `contraseña` y el `puerto` mediante el cual se expone el servicio de PostgreSQL._

_Ver ejemplo de archivo `.env` [aquí](#paso-1-clonar-repositorio-y-crear-archivo-env)_

---

## 5. Inicializar y levantar ThingsBoard

Ejecutar en Ubuntu:

```bash
chmod +x fase4_paso2_crear_servicios_docker_ubuntu.sh && ./fase4_paso2_crear_servicios_docker_ubuntu.sh
```

Comandos principales ejecutados por el script:

```bash
docker compose run --rm -e INSTALL_TB=true -e LOAD_DEMO=true thingsboard-ce
docker compose up -d
```

Verificar los contenedores:

```bash
cd ~/thingsboard-deploy-template
docker compose ps
```

Ver logs:

```bash
docker compose logs -f
```

Acceso local esperado:

```text
http://localhost:8080
```

las credenciales comunes de ThingsBoard son:

```text
Tenant Administrator:
usename: tenant@thingsboard.org
password: tenant

Customer User:
username: customer@thingsboard.org
password: customer

System Administrator:
username: sysadmin@thingsboard.org
password: sysadmin
```

---

## 6. Crear tarea programada para iniciar WSL/Docker en Windows Server 2022

Volver a **Windows PowerShell como Administrador** y ejecutar:

```powershell
.\fase5_paso1_crear_tarea_wsl_boot_windows_server_2022.ps1
```

Verificar la tarea:

```powershell
Get-ScheduledTask -TaskName "WSL-Boot"
Get-ScheduledTaskInfo -TaskName "WSL-Boot"
```

Ejecutarla manualmente si es necesario:

```powershell
Start-ScheduledTask -TaskName "WSL-Boot"
```

---

## 7. Paso opcional: crear servicio `tb-stack` en Ubuntu

Este paso es opcional. Se usa si los servicios Docker Compose no se levantan automáticamente al iniciar WSL.

Ejecutar en Ubuntu:

```bash
chmod +x fase5_paso2_crear_servicio_tb_stack_ubuntu.sh && ./fase5_paso2_crear_servicio_tb_stack_ubuntu.sh
```

O indicando manualmente la ruta del proyecto:

```bash
chmod +x fase5_paso2_crear_servicio_tb_stack_ubuntu.sh && ./fase5_paso2_crear_servicio_tb_stack_ubuntu.sh /home/usuario/thingsboard-deploy-template
```

Verificar el servicio:

```bash
sudo systemctl status tb-stack
```

---

## 8. Verificación final rápida

En Ubuntu:

```bash
cd ~/thingsboard-deploy-template
docker compose ps
docker compose logs -f thingsboard-ce
sudo systemctl status docker
```

En Windows PowerShell:

```powershell
wsl --list --verbose
wsl --status
Get-ScheduledTaskInfo -TaskName "WSL-Boot"
```

---

# Introducción al Despliegue de ThingsBoard en Windows Server 2022

## Arquitectura general del despliegue

La arquitectura propuesta es:

```text
Windows Server 2022
        ↓
WSL2
        ↓
Ubuntu
        ↓
Docker Engine + Docker Compose
        ↓
ThingsBoard CE + PostgreSQL + Kafka
```

El stack de servicios se ejecuta dentro de Ubuntu/WSL2 mediante Docker Compose.

---

## Requisitos previos

### Sistema operativo

- Windows Server 2022.
- Acceso con usuario administrador.
- Conexión a internet.
- Virtualización habilitada en BIOS/UEFI.
- PowerShell disponible en Windows.
- Ubuntu instalado sobre WSL2.
- Usuario Ubuntu con permisos `sudo`.

### Permisos requeridos

| Entorno | Requisito |
|---|---|
| Windows PowerShell | Ejecutar como Administrador |
| Ubuntu / WSL2 | Usuario con permisos `sudo` |
| Docker | Servicio activo dentro de Ubuntu |
| systemd | Debe estar activo en Ubuntu/WSL |

---

## Scripts incluidos

Se recomienda ubicar los scripts en una carpeta del repositorio, por ejemplo:

```text
scripts/
├── fase0_paso1_habilitar_ambientes_virtualizacion.ps1
├── fase1_paso1_verificar_virtualizacion.ps1
├── fase1_paso2_instalar_wsl2_ubuntu.ps1
├── fase3_instalar_configurar_docker_ubuntu.sh
├── fase4_paso1_clonar_repo_crear_env_ubuntu.sh
├── fase4_paso2_crear_servicios_docker_ubuntu.sh
├── fase5_paso1_crear_tarea_wsl_boot_windows_server_2022.ps1
└── fase5_paso2_crear_servicio_tb_stack_ubuntu.sh
```

---

## Orden recomendado de ejecución

De acuerdo con las pruebas realizadas, el orden recomendado es:

```text
1. Fase 0 - Paso 1
   Habilitar características de virtualización en Windows.

2. Reiniciar Windows Server 2022.

3. Fase 1 - Paso 1
   Verificar virtualización en Windows.

4. Fase 1 - Paso 2
   Instalar / actualizar WSL2 e instalar Ubuntu.

5. Abrir Ubuntu por primera vez.
   Crear usuario y contraseña.

6. Fase 2 - Paso 1, manual
   Verificar o habilitar systemd en Ubuntu.

7. Fase 3
   Instalar y configurar Docker en Ubuntu.

8. Fase 4 - Paso 1
   Clonar repositorio y crear archivo .env.

9. Fase 4 - Paso 2
   Inicializar y levantar servicios Docker Compose.

10. Fase 5 - Paso 1
   Crear tarea programada WSL-Boot en Windows Server 2022.

11. Fase 5 - Paso 2, opcional
   Crear servicio tb-stack.service en Ubuntu.
```

---

# Fase 0. Habilitación de ambientes de virtualización

## Paso 1. Habilitar características de Windows

Script:

```text
fase0_paso1_habilitar_ambientes_virtualizacion.ps1
```

Este script habilita las características necesarias para WSL2, Hyper-V y Docker.

Ejecutar en **Windows PowerShell como Administrador**:

```powershell
.\fase0_paso1_habilitar_ambientes_virtualizacion.ps1
```

El script ejecuta internamente comandos equivalentes a:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
```

Al finalizar, reiniciar Windows Server 2022.

---

# Fase 1. Validación inicial del servidor

## Paso 1. Verificar virtualización en Windows

Script:

```text
fase1_paso1_verificar_virtualizacion.ps1
```

Este script valida si el servidor cuenta con la virtualización habilitada para continuar con WSL2 y Docker.

Ejecutar en **Windows PowerShell como Administrador**:

```powershell
.\fase1_paso1_verificar_virtualizacion.ps1
```

El comando base utilizado por el script es:

```powershell
Get-CimInstance Win32_Processor |
Select Name, VirtualizationFirmwareEnabled, VMMonitorModeExtensions
```

## Resultado esperado

El escenario válido para continuar es:

```text
VirtualizationFirmwareEnabled : True
```

Puede ocurrir que el resultado sea:

```text
VirtualizationFirmwareEnabled : True
VMMonitorModeExtensions      : False
```

Este escenario también se considera válido para este despliegue, ya que en la práctica permite instalar y utilizar WSL2 y Docker.

Si `VirtualizationFirmwareEnabled` aparece como `False`, se debe ingresar a la BIOS/UEFI y habilitar:

- Intel VT-x, o
- AMD-V, según corresponda.

---

## Paso 2. Instalar WSL2 y Ubuntu

Asimismo, se recomienda entrar como usuario root en Ubuntu, ingresando:

```bash
sudo su
```

Script recomendado:

```text
fase1_paso2_instalar_wsl2_ubuntu.ps1
```

Esta versión del script fue ajustada para reducir errores durante la instalación de Ubuntu, especialmente el error:

```text
An error occurred during installation.
Distribution Name: 'Ubuntu'
Error Code: 0x8000ffff
```

Ejecutar en **Windows PowerShell como Administrador**:

```powershell
.\fase1_paso2_instalar_wsl2_ubuntu.ps1
```

El script realiza, entre otras acciones:

1. Verificación de permisos de administrador.
2. Validación de características requeridas.
3. Actualización de WSL.
4. Intento de actualización usando `--web-download`.
5. Configuración de WSL2 como versión predeterminada.
6. Instalación de Ubuntu.

Comandos base relacionados:

```powershell
wsl --update --web-download
wsl --shutdown
wsl --set-default-version 2
wsl --install --distribution Ubuntu --web-download
```

Si Windows solicita reinicio, reiniciar antes de continuar.

---

## Corrección sugerida si aparece el error 0x8000ffff

Si la instalación de Ubuntu falla con el error `0x8000ffff`, ejecutar en PowerShell como Administrador:

```powershell
DISM /Online /Cleanup-Image /RestoreHealth
SFC /SCANNOW
wsl --update --web-download
wsl --shutdown
```

Luego volver a ejecutar:

```powershell
.\fase1_paso2_instalar_wsl2_ubuntu.ps1
```

---

# Fase 2. Configuración inicial de Ubuntu

Esta fase se realiza manualmente dentro de Ubuntu.

## Paso 1. Crear usuario y contraseña

Después de instalar Ubuntu, abrirlo desde el menú de inicio de Windows.

Ubuntu solicitará crear:

- Nombre de usuario Linux.
- Contraseña del usuario.

Esta contraseña será usada para ejecutar comandos con `sudo`.

---

## Paso 2. Verificar que systemd esté activo

Dentro de Ubuntu, ejecutar:

```bash
ps -p 1 -o comm=
```

Resultado esperado:

```text
systemd
```

Si el resultado no es `systemd`, se debe habilitar manualmente.

Editar el archivo:

```bash
sudo nano /etc/wsl.conf
```

Agregar:

```ini
[boot]
systemd=true
```

Guardar el archivo, cerrar Ubuntu y desde PowerShell ejecutar:

```powershell
wsl --shutdown
```

Luego abrir nuevamente Ubuntu y verificar:

```bash
ps -p 1 -o comm=
```

---

# Fase 3. Instalación y configuración de Docker en Ubuntu

Script:

```text
fase3_instalar_configurar_docker_ubuntu.sh
```

Este script automatiza la instalación de Docker usando el repositorio oficial de Docker para Ubuntu.

Ejecutar en **Ubuntu**:

```bash
chmod +x fase3_instalar_configurar_docker_ubuntu.sh && ./fase3_instalar_configurar_docker_ubuntu.sh
```

El script realiza:

1. Desinstalación de paquetes antiguos o en conflicto.
2. Actualización del sistema.
3. Instalación de dependencias base.
4. Configuración de llaves GPG oficiales de Docker.
5. Agregado del repositorio oficial de Docker.
6. Instalación de:
   - `docker-ce`
   - `docker-ce-cli`
   - `containerd.io`
   - `docker-buildx-plugin`
   - `docker-compose-plugin`
7. Habilitación e inicio del servicio Docker.
8. Verificación del estado del servicio.

Comandos útiles de verificación:

```bash
docker --version
docker compose version
sudo systemctl status docker
```

---

# Fase 4. Despliegue de ThingsBoard con Docker Compose

## Paso 1. Clonar repositorio y crear archivo `.env`

Script:

```text
fase4_paso1_clonar_repo_crear_env_ubuntu.sh
```

Este script clona el repositorio base de despliegue:

```bash
git clone https://github.com/luiscastrillo97/thingsboard-deploy-template.git
```

Luego ingresa a la carpeta del proyecto:

```bash
cd thingsboard-deploy-template
```

y crea un archivo `.env` con las variables requeridas.

Ejecutar en **Ubuntu**:

```bash
chmod +x fase4_paso1_clonar_repo_crear_env_ubuntu.sh && ./fase4_paso1_clonar_repo_crear_env_ubuntu.sh
```

Contenido generado del archivo `.env`:

```env
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
```

Si ya existe un archivo `.env`, el script crea una copia de seguridad antes de sobrescribirlo.

**Nota:** _Se recomienda cambiar al menos la `contraseña` y el `puerto` mediante el cual se expone el servicio de PostgreSQL._

---

## Paso 2. Crear e iniciar servicios Docker

Script:

```text
fase4_paso2_crear_servicios_docker_ubuntu.sh
```

Este script inicializa ThingsBoard y luego levanta los servicios con Docker Compose.

Ejecutar en **Ubuntu**:

```bash
chmod +x fase4_paso2_crear_servicios_docker_ubuntu.sh && ./fase4_paso2_crear_servicios_docker_ubuntu.sh
```

Comandos ejecutados internamente:

```bash
docker compose run --rm -e INSTALL_TB=true -e LOAD_DEMO=true thingsboard-ce
docker compose up -d
```

Verificar servicios:

```bash
cd ~/thingsboard-deploy-template
docker compose ps
```

Ver logs:

```bash
docker compose logs -f
```

Si se usa el puerto HTTP por defecto, ThingsBoard debería quedar disponible localmente en:

```text
http://localhost:8080
```

---

# Fase 5. Arranque automático de WSL y servicios

## Paso 1. Crear tarea programada en Windows Server 2022

Script:

```text
fase5_paso1_crear_tarea_wsl_boot_windows_server_2022.ps1
```

Este script está orientado específicamente a **Windows Server 2022**.

Su propósito es crear una tarea programada que inicie WSL y Docker automáticamente, evitando que los servicios queden detenidos cuando se cierra la aplicación de Ubuntu o después de un reinicio del servidor.

Ejecutar en **Windows PowerShell como Administrador**:

```powershell
.\fase5_paso1_crear_tarea_wsl_boot_windows_server_2022.ps1
```

El script crea el archivo:

```text
C:\wsl-boot.cmd
```

con el contenido:

```cmd
@echo off
wsl.exe --exec bash -lc "dbus-launch true && systemctl start docker"
```

También crea la tarea programada:

```text
WSL-Boot
```

La tarea se configura para:

- Ejecutarse al iniciar Windows Server 2022.
- Ejecutarse al iniciar sesión.
- Ejecutarse con privilegios elevados.
- Ejecutarse aunque el usuario no haya iniciado sesión, cuando la política lo permita.
- Reiniciarse cada 5 minutos si falla, hasta 3 intentos.
- Poder ejecutarse bajo demanda.

Verificar la tarea:

```powershell
Get-ScheduledTask -TaskName "WSL-Boot"
Get-ScheduledTaskInfo -TaskName "WSL-Boot"
```

Ejecutarla manualmente:

```powershell
Start-ScheduledTask -TaskName "WSL-Boot"
```

---

## Paso 2 opcional. Crear servicio systemd para levantar Docker Compose

Script:

```text
fase5_paso2_crear_servicio_tb_stack_ubuntu.sh
```

Este paso es opcional.

Por lo general, al iniciar WSL, Docker inicia y los servicios que estaban corriendo antes de un reinicio vuelven a quedar disponibles. Sin embargo, si esto no ocurre, se puede crear un servicio `systemd` llamado:

```text
tb-stack.service
```

Ejecutar en **Ubuntu**:

```bash
chmod +x fase5_paso2_crear_servicio_tb_stack_ubuntu.sh && ./fase5_paso2_crear_servicio_tb_stack_ubuntu.sh
```

También puede indicarse manualmente la ruta donde se encuentra el archivo `docker-compose.yml`. El formato recomendado sigue siendo primero asignar permisos y luego ejecutar:

```bash
chmod +x fase5_paso2_crear_servicio_tb_stack_ubuntu.sh && ./fase5_paso2_crear_servicio_tb_stack_ubuntu.sh /home/usuario/thingsboard-deploy-template
```

El script crea:

```text
/etc/systemd/system/tb-stack.service
```

Con una estructura equivalente a:

```ini
[Unit]
Description=ThingsBoard Docker Stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/usuario/thingsboard-deploy-template
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
```

El script ejecuta internamente:

```bash
sudo systemctl daemon-reload
sudo systemctl enable tb-stack
```

Comandos útiles:

```bash
sudo systemctl start tb-stack
sudo systemctl stop tb-stack
sudo systemctl status tb-stack
sudo journalctl -u tb-stack -n 100 --no-pager
```

---

# Verificación final del despliegue

## En Ubuntu

Verificar contenedores:

```bash
cd ~/thingsboard-deploy-template
docker compose ps
```

Ver logs:

```bash
docker compose logs -f
```

Verificar Docker:

```bash
sudo systemctl status docker
```

Verificar servicio opcional:

```bash
sudo systemctl status tb-stack
```

---

## En Windows Server 2022

Verificar tarea programada:

```powershell
Get-ScheduledTask -TaskName "WSL-Boot"
Get-ScheduledTaskInfo -TaskName "WSL-Boot"
```

Verificar distribuciones WSL:

```powershell
wsl --list --verbose
```

Verificar estado de WSL:

```powershell
wsl --status
```

---

# Acceso local a ThingsBoard

Una vez finalizado el despliegue, ThingsBoard debería estar disponible desde el servidor en:

```text
http://localhost:8080
```

Si se desea acceso externo desde otros equipos, se deberán configurar posteriormente las reglas de redirección, firewall o publicación de puertos correspondientes. Ese procedimiento no se incluye en este README.

---

# Credenciales de demostración de ThingsBoard

Si se cargaron datos demo con:

```bash
LOAD_DEMO=true
```

las credenciales comunes son:

```text
Tenant Administrator:
tenant@thingsboard.org
tenant

Customer User:
customer@thingsboard.org
customer

System Administrator:
sysadmin@thingsboard.org
sysadmin
```

> Se recomienda cambiar las contraseñas por defecto después del primer acceso.

---

# Solución de problemas frecuentes

## Ubuntu no se instala y aparece el error 0x8000ffff

Ejecutar en PowerShell como Administrador:

```powershell
DISM /Online /Cleanup-Image /RestoreHealth
SFC /SCANNOW
wsl --update --web-download
wsl --shutdown
```

Luego volver a ejecutar:

```powershell
.\fase1_paso2_instalar_wsl2_ubuntu.ps1
```

---

## WSL no inicia automáticamente

Ejecutar manualmente:

```powershell
C:\wsl-boot.cmd
```

O revisar la tarea:

```powershell
Get-ScheduledTaskInfo -TaskName "WSL-Boot"
```

---

## Docker no está activo en Ubuntu

```bash
sudo systemctl start docker
sudo systemctl status docker
```

---

## Los contenedores no están corriendo

```bash
cd ~/thingsboard-deploy-template
docker compose up -d
docker compose ps
```

---

## ThingsBoard no responde localmente

Verificar los logs:

```bash
cd ~/thingsboard-deploy-template
docker compose logs -f thingsboard-ce
```

Verificar contenedores:

```bash
docker compose ps
```

Verificar puertos publicados por Docker:

```bash
docker ps
```

---

# Mantenimiento básico

## Reiniciar stack ThingsBoard

```bash
cd ~/thingsboard-deploy-template
docker compose restart
```

## Detener stack

```bash
docker compose down
```

## Levantar stack

```bash
docker compose up -d
```

## Ver uso de recursos

```bash
docker stats
```

## Ver logs de ThingsBoard

```bash
docker compose logs -f thingsboard-ce
```

---

# Consideraciones de seguridad

Antes de usar el entorno en producción, se recomienda:

1. Cambiar contraseñas por defecto.
2. No exponer PostgreSQL públicamente salvo que sea estrictamente necesario.
3. Usar HTTPS para acceso web a ThingsBoard.
4. Proteger MQTT/MQTTS con credenciales y certificados si aplica.
5. Mantener actualizado Windows Server, Ubuntu, Docker y ThingsBoard.
6. Implementar copias de seguridad periódicas de PostgreSQL.
7. Documentar cualquier cambio en variables de entorno, puertos o rutas del proyecto.

---

# Notas finales

Este procedimiento fue diseñado para un entorno con **Windows Server 2022 + WSL2 + Ubuntu + Docker**.

La instalación puede requerir reinicios entre fases, especialmente después de habilitar características de virtualización, instalar WSL2 o activar `systemd`.

El flujo recomendado incluye ejecutar dos veces la validación de la Fase 0:

1. Antes de habilitar características de virtualización.
2. Después del reinicio posterior a la Fase 1 - Paso 1.

Esto permite confirmar que el servidor queda en condiciones adecuadas antes de instalar Ubuntu, Docker y ThingsBoard.
