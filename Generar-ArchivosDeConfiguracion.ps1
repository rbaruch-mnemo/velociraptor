Param(
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la ruta de salida donde se colocarán los archivos de configuración para el servidor y los clientes. Puedes colocar '.' para ocupar el directorio actual como ruta de salida.")] [string] $DirectorioTrabajo,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la IP que tendrá el servidor Velociraptor")] [string] $IP,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la máscara (8,16,24,26,etc) para la IP asignada")] [string] $Mascara,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la dirección IP del gateway para la configuración de red del servidor")] [string] $Gateway,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa el/los servidores  DNS para la configuración de red`nPE: '8.8.8.8,1.1.1.1'")] [string] $DNS
)

function Validar-IPv4 { 
    param ($direccionIP)
    $valid_ipv4 = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
    if ($direccionIP -match $valid_ipv4) { return $direccionIP } else {
        Write-Host "[-] ERROR al validar dirección IP ingresada en el campp {IP/Gateway/DNS}.`nRevisar los valores ingresados e intentar de nuevo."
        exit
    }
}

function Validar-RutaTrabajo { 
    param ($DirectorioTrabajo)
    if (Test-Path -Path $DirectorioTrabajo) {
        $DirectorioTrabajo = Convert-Path $DirectorioTrabajo # Para casos donde sea "." o ".."
        return $DirectorioTrabajo
    } else {
        $ficheroAnterior = Split-Path -Path $DirectorioTrabajo
        $leaf = Split-Path -Path $DirectorioTrabajo -Leaf
        if (Test-Path -Path $ficheroAnterior) {
            $respuesta = Read-Host -Prompt "Desea crear el directorio $leaf dentro de $ficheroAnterior y usarlo como directorio de salida? [S/N]"
            if ($respuesta.ToLower() -eq "s") {
                New-Item -Path $DirectorioTrabajo -ItemType "Directory"
                Write-Host "Se ha creado la carpeta $leaf.`nRaiz del ambiente: $DirectorioTrabajo"
                return $DirectorioTrabajo
            } else {exit}
        } else {
            Write-Host "[-] ERROR en el path ingresado como directorio de salida."
            exit
        }
    }
}

function Verificar-Requisitos() {
    Write-Host "[+] Verificando requisitos de Velociraptor..."
    if ((Get-WindowsCapability -Online -Name NetFx3~~~~).State -ne "Installed") {
        Write-Host -NoNewLine "`t[*] Instalando .NET 3.5.1..."
        DISM /online /Enable-Feature /FeatureName:"NetFx3" | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" | Out-Null
        Write-Host -Fore Green "Listo!"
    } else { Write-Host "`t[*] Ya se encuentra instalado .NET 3.5.1." }
    if (-not (Test-Path -Path "C:\Program Files (x86)\WiX Toolset v3.11)")) {
        Write-Host -NoNewLine "`t[*] Instalando utilierias de WIX para crear clientes..."
        Start-Process -Wait -FilePath ".\bins\wix311.exe" -ArgumentList "/S" -PassThru | Out-Null
        Write-Host -Fore Green "Listo!"
    } else { Write-Host "`t[*] Ya se encuentran instaladas las utilerías de WIX." }
}

function Generar-ArchivosConfiguracion($DirectorioTrabajo, $IP, $Mascara, $Gateway, $DNS) {
    Write-Host "[+] Generando carpetas dentro de la ruta de trabajo..."
    "servidor","clientesWindows","clientesLinux" | % {mkdir $DirectorioTrabajo\$_} | Out-Null

    # Servidor Velociraptor
    Write-Host "`t[+] Generando archivos de configuración para el servidor..."
    Copy-Item -Path ".\archivosBase\server.config.yaml" -Destination "$DirectorioTrabajo\servidor" -Force | Out-Null
    (Get-Content "$DirectorioTrabajo\servidor\server.config.yaml").replace('{{IP}}', $IP) | Set-Content "$DirectorioTrabajo\servidor\server.config.yaml"

    # Clientes Windows
    Write-Host "`t[+] Generando archivos de configuración para los clientes Windows..."
    Copy-Item -Path ".\archivosBase\client.config.yaml" -Destination ".\bins\wix_orig\output" -Force | Out-Null
    (Get-Content ".\bins\wix_orig\output\client.config.yaml").replace('{{servidor}}', $IP) | Set-Content ".\bins\wix_orig\output\client.config.yaml"
    "Iniciando BAT..."
    Start-Process "cmd.exe" "/c .\bins\wix_orig\build_custom.bat"
    #Move-Item -Path ".\bins\wix_orig\custom.msi" -Destination "$DirectorioTrabajo\clientesWindows" -Force
    #Remove-Item -Path ".\bins\wix_orig\output\client.config.yaml"
    #msiexec /i custom.msi
}

# Validaciones de valores ingresados
$DirectorioTrabajo = Validar-RutaTrabajo($DirectorioTrabajo)
$IP = Validar-IPv4($IP)
$Gateway = Validar-IPv4($Gateway)
$DNS = Validar-IPv4($DNS)
if ($Mascara -NotMatch "^[0-9]{2}$") { Write-Host "[-] ERROR al validar la máscara ingresada.`nIngresar el número de octetos de la máscara. P.E: 24."; exit }
#Start
Verificar-Requisitos
if (($DirectorioTrabajo -and $IP -and $Mascara -and $Gateway -and $DNS) -ne $null) {
    Write-Host "DT: $DirectorioTrabajo`nIP: $IP`nMASK: $Mascara`nGW: $Gateway`nDNS: $DNS`n"
    Generar-ArchivosConfiguracion -DirectorioTrabajo $DirectorioTrabajo -IP $IP -Mascara $Mascara -Gateway $Gateway -DNS $DNS 
} else {
    Write-Host "[-] ERROR: Ingrese valores para IP, Mascara, Gateway y DNS."; exit
}