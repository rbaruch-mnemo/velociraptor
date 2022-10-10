#!/bin/bash

USERNAME="forense"
INTERFAZ=$(nmcli device status | grep "ethernet" | cut -d " " -f 1) # ens33 por defecto
DIRECCION="{{direccion}}"
MASCARA="{{mascara}}"
GATEWAY="{{gateway}}"
DNS="{{dns}}"

# Configuracion inicial del servidor host
timedatectl set-timezone America/Mexico_City
apt update && apt install -y vim whois net-tools # cualquier otro paquete que se quiera instalalar por defecto en el servidor

 # Configuración Velociraptor
mkdir /opt/velociraptor && mkdir /opt/velociraptor/logs
chown -R $USERNAME /opt/velociraptor && chown -R $USERNAME /opt/velociraptor/logs

# Configuracion de red
echo -e "  ethernets:\n    $INTERFAZ:\n      dhcp4: no\n      addresses:\n        - $DIRECCION/$MASCARA\n      gateway4: $GATEWAY\n      nameservers:\n        addresses: [$DNS]" >> /etc/netplan/01-network-manager-all.yaml
netplan apply