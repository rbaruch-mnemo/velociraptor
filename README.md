# Velociraptor - Creador de archivos de despliegue
Herramienta que permite crear de manera desatendida los archivos necesarios para levantar un laboratorio de Velociraptor:
- **Servidor**: Archivo *.deb* de instalación del servicio de Velociraptor.
> Nota: El servidor está considerado para que sea Linux; Debian o Ubuntu.
>> Puertos por defecto:
>>> 8000 para clientes, 8001 para API y 8889 para GUI.
- **Clientes**
	- **Windows**: Archivo MSI.
	- **Linux**: Archivos *.deb* y *.rpm*.
> Los clientes apuntan a la dirección del servidor que sea ingresada.

## Requisitos
- **.NET 3.5+**.
- **WSL** (cualquier distribución) con el paquete **dos2unix** instalado.
> Estos requisitos son validados por la herramienta; si no se encuentran presentes dentro del equipo, se puede instalar desde la misma pero se recomienda contar con ellos previamente.

## Uso 
### Descarga de la herramienta
Para comenzar a utilizar la herramienta, será necesario clonar el repositorio ejecutando: 
```
git clone https://github.com/rbaruch-mnemo/velociraptor
``` 
### Parámetros obligatorios
La herramienta espera los siguientes parámetros:
- **DirectorioTrabajo**: Ruta donde la herramienta colocará los archivos generados.
- **IP**: Dirección IP que tendrá el servidor de Velociraptor.
> Esta dirección IP será donde vivirá el servidor de Velociraptor y será incluida dentro de la configuración de los servicios para los clientes.
 
### Ejemplo
- **Abir una instancia de Powershell como Administrador**
- **Colocarse en la raíz del repositorio y ejecutar el siguientes comando**
```
.\Generar-ArchivosDeConfiguracion.ps1 -DirectorioTrabajo "..\SALIDA" -IP "172.20.4.150"
``` 
> Generar archivos para la IP 172.20.4.150, los cuales serán colocados en la carpeta "SALIDA" nivel arriba.

### Manipulación  de los servicios
#### Servidor
- Para parar el servicio:
```
sudo systemctl stop velociraptor_server.service
```
- Para reiniciar para el servicio:
```
sudo systemctl restart velociraptor_server.service
```
- Para eliminar completamente el servicio:
```
sudo systemctl stop velociraptor_server.service && sudo rm -r /opt/velociraptor /etc/velociraptor
```
#### Clientes
**1. Linux**
- Para parar el servicio:
```
sudo systemctl stop velociraptor_client.service
```
- Para reiniciar el servicio:
```
sudo systemctl restart velociraptor_client.service
```
**2. Windows**
- Para parar el servicio:
	- Abrir "Servicios"
	- Encontrar el servicio "Velociraptor"
	- Click Derecho > Parar
- Para reiniciar el servicio:
	- Abrir "Servicios".
	- Encontrar el servicio "Velociraptor".
	- Click Derecho > Reiniciar.
- Para eliminar el servicio:
	- Abrir un CMD como administrador.
	- Ejecutar el siguiente comando:
	```
	sc delete Velociraptor
	```
	-  Eliminar el contenido de las carpetas dentro de la ruta "C:\Program Files\Velociraptor"