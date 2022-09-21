#!/bin/bash

ayuda() {
  echo -e "USO: $0 < -i INTERFAZ > [ -d IP ] [ -m MASCARA ] [ -g GATEWAY ]" 1>&2
  exit 1
}

USERNAME="forense"
PASSWD="hola123.,"
INTERFAZ=$(nmcli device status | grep "ethernet" | cut -d " " -f 1) # ens33 por defecto
DIRECCION=""
MASCARA=""
GATEWAY=""
DNS="1.1.1.1, 8.8.8.8"

# Flags
while getopts ":i:d:m:g:" flag
do
    case "${flag}" in
        i) INTERFAZ=${OPTARG};;
        d) 
            DIRECCION=${OPTARG}
            if ! [[ $DIRECCION =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
                echo -e "[-] ERROR al validar la direcciÃ³n IP ingresada.\n    - Revise la IP ingresada para el servidor."
                exit 1
            fi
            ;;
        m) MASCARA=${OPTARG}
            if ! [[ $MASCARA =~ ^[0-9]{1,2}$ ]] ; then
                echo -e "[-] ERROR al validar la mÃ¡scara ingresada.\nIngrese el nÃºmero de octetos a usar. P.E: 18, 24, 26."
                exit 1
            fi
            ;;
        g) GATEWAY=${OPTARG}
            if ! [[ $GATEWAY =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
                echo -e "[-] ERROR al validar el gateway ingresado.\n    - Revise la IP ingresada como gateway."
                exit 1
            fi
            ;;
        :)
            echo "Error: -${OPTARG} requiere de un argumento."
            ayuda
            ;;
        ?) 
            echo "[-] ERROR: Flag no reconocida: -${OPTARG}"
            ayuda
            ;;
    esac
done

# Configuracion inicial del servidor
timedatectl set-timezone America/Mexico_City
apt update && apt install -y vim whois net-tools
SALTEDPASS=$(mkpasswd $PASSWD)
#useradd -m $USERNAME -p $SALTEDPASS -s /bin/bash
#echo "${USERNAME} ALL=(ALL:ALL) ALL" >> /etc/sudoers
 
# Instalacion  Velociraptor

wget https://github.com/Velocidex/velociraptor/releases/download/v0.6.6-1/velociraptor-v0.6.6-1-linux-amd64 && wget https://github.com/Velocidex/velociraptor/releases/download/v0.6.6-1/velociraptor-v0.6.6-1-linux-amd64.sig
#gpg --search-keys 0572F28B4EF19A043F4CBBE0B22A7FB19CB6CFA1
cp client.config.yaml $(date +"%s")_client.config.yaml
sed -i 's/localhost/'"$DIRECCION"'/g' $(date +"%s")_client.config.yaml
#sed -i 's/localhost/'"$DIRECCION"'/g' server.config.yaml
mkdir /opt/velociraptor && mkdir /opt/velociraptor/logs
chown -R $USERNAME /opt/velociraptor && chown -R $USERNAME /opt/velociraptor/logs

# Configuracion de red
echo -e "  ethernets:\n    $INTERFAZ:\n      dhcp4: no\n      addresses:\n        - $DIRECCION/$MASCARA\n      gateway4: $GATEWAY\n      nameservers:\n        addresses: [$DNS]" >> /etc/netplan/01-network-manager-all.yaml
netplan apply
reboot