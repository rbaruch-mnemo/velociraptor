# Velociraptor - Creador de archivos de despliegue
Herramienta  que permite crear de manera desatendida los archivos necesarios para levantar un laboratorio de Velociraptor:
- **Servidor**: Archivos .sh y .deb para configuración de red e instalación de paquetes dentro del servidor 
- **Clientes**
	- **Windows**: Archivo MSI que instala el servicio de Velociraptor
	- **Linux**: Archivos .deb y .rpm que instala el servicio de Velociraptor

## Requisitos
- **.NET 3.5+**.
- **Wix Tool Set**.
- **WSL** (cualquier distribución) con el paquete **dos2unix** instalado.
> Estos requisitos, son instalados por la herramienta si no se encuentran presentes dentro del equipo.

## Uso 
### Descarga de la herramienta
Para comenzar a utilizar la herramienta, será necesario clonar el repositorio ejecutando: 
```
git clone https://github.com/rbaruch-mnemo/velociraptor
``` 
### Parámetros obligatorios
Para el flujo de la herramienta, así como realizar la configuración de red y paquetes dentro del servidor, la herramienta espera los siguientes parámetros:
- *DirectorioTrabajo*: Ruta donde la herramienta colocará los archivos generados.
- *IP*: Dirección IP que tendrá el servidor de Velociraptor.
> Esta dirección, será incluida dentro de la configuración de los servicios para los clientes.
- *Mascara*: Número de octetos (8,16,24).
- *Gateway*: Dirección IP del gateway.
- *DNS*: Direcciones IP de los servidores DNS. 
### Ejemplos
Abir una instancia de Powershell como Administrador y colocarse en la raíz del repositorio y ejecutar el siguientes comando
```
.\Generar-ArchivosDeConfiguracion.ps1 -DirectorioTrabajo "..\SALIDA" -IP "172.20.4.150" -Mascara "24" -Gateway "172.20.4.1" -DNS "8.8.8.8"
``` 
> Generar archivos para la IP 172.20.4.150, los cuales serán colocados en la carpeta "SALIDA" nivel arriba.