Param(
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la ruta de salida donde se colocarán los archivos de configuración para el servidor y los clientes. Puedes colocar '.' para ocupar el directorio actual como ruta de salida.")] [string] $DirectorioTrabajo,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la IP que tendrá el servidor Velociraptor")] [string] $IP,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la máscara (8,16,24,26,etc) para la IP asignada")] [string] $Mascara,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la dirección IP del gateway para la configuración de red del servidor")] [string] $Gateway,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa el/los servidores  DNS para la configuración de red`nPE: '8.8.8.8,1.1.1.1'")] [string] $DNS
)

function Validar-IPv4($direccionIP) {
    $valid_ipv4 = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
    if ($direccionIP -match $valid_ipv4) { return $direccionIP } else {
        Write-Host "[-] ERROR al validar dirección IP ingresada en el campp {IP/Gateway/DNS}.`nRevisar los valores ingresados e intentar de nuevo."
        exit
    }
}

function Validar-RutaTrabajo($DirectorioTrabajo) {
    $DirectorioTrabajo = Convert-Path $DirectorioTrabajo # Para casos donde sea "." o ".."
    if (Test-Path -Path $DirectorioTrabajo) {
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
            }
        } else {
            Write-Host "[-] ERROR en el path ingresado como directorio de salida."
            exit
        }
    }
}

function Instalar-Requisitos() {
}

function Instalar-Requisitos() {
    if ((Get-WindowsCapability -Online -Name NetFx3~~~~).State -ne "Installed") {
        Write-Host -NoNewLine "[*] Instalando .NET 3.5.1..."
        DISM /online /Enable-Feature /FeatureName:"NetFx3" | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" | Out-Null
        Write-Host -Fore Green "Listo!"
    } else { Write-Host "[*] Ya se encuentra instalado .NET 3.5.1." }
    if (-not (Test-Path -Path "C:\Program Files (x86)\WiX Toolset v3.11)")) {
        Write-Host -NoNewLine "[*] Instalando utilierias de WIX para crear clientes..."
        Start-Process -Wait -FilePath ".\bins\wix311.exe" -ArgumentList "/S" -PassThru
        Write-Host -Fore Green "Listo!"
    } else { Write-Host "[*] Ya se encuentran instaladas las utilerías de WIX." }
}

function Generar-ArchivosConfiguración($DirectorioTrabajo, $IP, $Mascara, $Gateway, $DNS) {
    #Write-Host ":)"
    Instalar-Requisitos
}

# Validaciones de valores ingresados
$DirectorioTrabajo = Validar-RutaTrabajo($DirectorioTrabajo)
$IP = Validar-IPv4($IP)
$Gateway = Validar-IPv4($Gateway)
$DNS = Validar-IPv4($DNS)
if ($Mascara -NotMatch "^[0-9]{2}$") { Write-Host "[-] ERROR al validar la máscara ingresada.`nIngresar el número de octetos de la máscara. P.E: 24."; exit }

# Creación de archivos con los valores validados
Generar-ArchivosConfiguración($DirectorioTrabajo, $IP, $Mascara, $Gateway, $DNS)