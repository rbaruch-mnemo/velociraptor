#!/bin/bash
USERNAME="forense"
INTERFAZ=$(nmcli device status | grep "ethernet" | cut -d " " -f 1) # ens33 por defecto
DIRECCION="{{direccion}}"
MASCARA="{{mascara}}"
GATEWAY="{{gateway}}"
DNS="{{dns}}"

# Configuracion inicial del servidor host
timedatectl set-timezone America/Mexico_City
apt update && apt install -y vim whois net-tools

 # Configuración Velociraptor
mkdir /opt/velociraptor && mkdir /opt/velociraptor/logs
chown -R $USERNAME /opt/velociraptor && chown -R $USERNAME /opt/velociraptor/logs

# Creación de clientes 
./velociraptor-v0.6.6-1-linux-amd64 --config client.config.yaml debian client # Debian
./velociraptor-v0.6.6-1-linux-amd64 --config client.config.yaml rpm client
#mv velociraptor_0.6.6-1_client.deb 

# Configuracion de red
echo -e "  ethernets:\n    $INTERFAZ:\n      dhcp4: no\n      addresses:\n        - $DIRECCION/$MASCARA\n      gateway4: $GATEWAY\n      nameservers:\n        addresses: [$DNS]" >> /etc/netplan/01-network-manager-all.yaml
netplan apply
reboot