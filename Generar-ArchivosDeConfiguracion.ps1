Param(
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la ruta de salida donde se colocarán los archivos de configuración para el servidor y los clientes. Puedes colocar '.' para ocupar el directorio actual como ruta de salida.")] [string] $DirectorioTrabajo,
    [Parameter(Mandatory=$true, HelpMessage="Ingresa la IP que tendrá el servidor Velociraptor")] [string] $IP
    #[Parameter(Mandatory=$true, HelpMessage="Ingresa la máscara (8,16,24,26,etc) para la IP asignada")] [string] $Mascara,
    #[Parameter(Mandatory=$true, HelpMessage="Ingresa la dirección IP del gateway para la configuración de red del servidor")] [string] $Gateway,
    #[Parameter(Mandatory=$true, HelpMessage="Ingresa el/los servidores  DNS para la configuración de red`nPE: '8.8.8.8,1.1.1.1'")] [string] $DNS
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
    # .NET 3.5+
    if ((Get-WindowsCapability -Online -Name NetFx3~~~~).State -ne "Installed") {
        Write-Host -NoNewLine "`t[*] Instalando .NET 3.5.1..."
        DISM /online /Enable-Feature /FeatureName:"NetFx3" | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" | Out-Null
        Write-Host -Fore Green "Listo!"
    } else { Write-Host "`t[*] Ya se encuentra instalado .NET 3.5.1." }
    # Wix Tool Set
    if (-not (Test-Path -Path "C:\Program Files (x86)\WiX Toolset v3.11")) {
        Write-Host -NoNewLine "`t[*] Instalando utilierias de WIX para crear clientes..."
        Start-Process -Wait -FilePath ".\bins\wix311.exe" -ArgumentList "/S" -PassThru | Out-Null
        Write-Host -Fore Green "Listo!"
    } else { Write-Host "`t[*] Ya se encuentran instaladas las utilerías de WIX." }
    # WSL
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Disabled") {
        Write-Host -NoNewLine "`t[*] Instalando WSL dentro del equipo..."
        wsl --install
        Write-Host -Fore Green "Listo!"
        Write-Host -Fore Yellow "Es necesario reinicar el equipo, reiniciando en 20 segundos..."
        Start-Sleep -Seconds 20
        Restart-Computer
    } else { Write-Host "`t[*] Ya se encuentra instalado WSL."}
}

function Generar-ArchivosConfiguracion($DirectorioTrabajo, $IP) {
    $IP_Printeable = $IP.Replace(".","_")
    Write-Host "[+] Generando carpetas dentro de la ruta de trabajo..."
    $current = $(Get-Location).Path # Se obtiene la ruta de donde se está ejecutando el script
    "servidor","clientesWindows","clientesLinux" | ForEach-Object {mkdir $DirectorioTrabajo\$_} | Out-Null # Se crean las carpetas de salida dentro del DirectorioTrajo
    
    ## SERVIDOR 
    Write-Host "[+] SERVIDOR: Generando archivo DEB..."
    Copy-Item -Path "$current\archivosBase\server.config.yaml" -Destination "$current\bins" -Force | Out-Null
    (Get-Content "$current\bins\server.config.yaml").replace('{{IP}}', $IP) | Set-Content "$current\bins\server.config.yaml"
    (Get-Content "$current\bins\server.config.yaml").replace('{{bind}}', $IP) | Set-Content "$current\bins\server.config.yaml"
    Set-Location -LiteralPath "$current\bins"
    bash -c "./velociraptor-v0.7.0-2-linux-amd64 --config server.config.yaml debian server --binary velociraptor-v0.7.0-2-linux-amd64"
    Start-Sleep -Seconds 15
    Move-Item -Path "velociraptor_server_0.7.0.2_amd64.deb" -Destination "$DirectorioTrabajo\servidor\servidor_velociraptor-v0.7.0-2-linux_$IP_Printeable.deb" -Force | Out-Null
    Set-Location $current
    
    
    ## CLIENTES WINDOWS
    Write-Host "[+] WINDOWS: Generando archivo MSI para los clientes..."
    Copy-Item -Path "$current\archivosBase\client.config.yaml" -Destination "$current\bins" -Force | Out-Null
    (Get-Content "$current\bins\client.config.yaml").replace('{{servidor}}', $IP) | Set-Content "$current\bins\client.config.yaml"
    Set-Location "$current\bins"
    bash -c "./velociraptor-v0.7.0-2-linux-amd64 config repack --msi velociraptor-v0.7.0-2-windows-amd64.msi client.config.yaml MNEMO_VelociraptorClient.msi" | Out-Null
    Start-Sleep -Seconds 10
    Move-Item -Path "MNEMO_VelociraptorClient.msi" -Destination "$DirectorioTrabajo\clientesWindows\MNEMO_VelociraptorClient_$IP_Printeable.msi" -Force
    #msiexec /i custom.msi
    
    ## Clientes Linux
    Write-Host "[+] LINUX:  Generando binarios para clientes..."
    #Move-Item -Path ".\bins\wix_orig\output\client.config.yaml" -Destination ".\bins" -Force
    #Set-Location -LiteralPath ".\bins"
    bash -c "./velociraptor-v0.7.0-2-linux-amd64 --config client.config.yaml debian client" | Out-Null
    bash -c "./velociraptor-v0.7.0-2-linux-amd64 --config client.config.yaml rpm client" | Out-Null
    Remove-Item -Path "$current\bins\client.config.yaml"
    Remove-Item -Path "$current\bins\server.config.yaml"
    Move-Item -Path "*client*" -Destination "$DirectorioTrabajo\clientesLinux" -Force
    

    ## Limpiando archivos creados en carpeta 'bins'
    Set-Location -LiteralPath $current
   
    
    Write-Host -BackgroundColor DarkMagenta -ForegroundColor Green "[+] Binarios creados.`nRevisa los archivos creados dentro de $DirectorioTrabajo"
    #dpkg -i client.deb
    #rpm -i client.rpm
}

# Validaciones de valores ingresados
$DirectorioTrabajo = Validar-RutaTrabajo($DirectorioTrabajo)
$IP = Validar-IPv4($IP)
#$Gateway = Validar-IPv4($Gateway)
#$DNS = Validar-IPv4($DNS)
#if ($Mascara -NotMatch "^[0-9]{2}$") { Write-Host "[-] ERROR al validar la máscara ingresada.`nIngresar el número de octetos de la máscara. P.E: 24."; exit }

$Banner = @"
 _    __     __           _                  __                ____             __                        ____  ______________     __  ____   __________  _______ 
| |  / /__  / /___  _____(_)________ _____  / /_____  _____   / __ \___  ____  / /___  __  __            / __ \/ ____/  _/ __ \   /  |/  / | / / ____/  |/  / __ \
| | / / _ \/ / __ \/ ___/ / ___/ __  `/ __ \/ __/ __ \/ ___/  / / / / _ \/ __ \/ / __ \/ / / /  ______   / / / / /_   / // /_/ /  / /|_/ /  |/ / __/ / /|_/ / / / /
| |/ /  __/ / /_/ / /__/ / /  / /_/ / /_/ / /_/ /_/ / /     / /_/ /  __/ /_/ / / /_/ / /_/ /  /_____/  / /_/ / __/ _/ // _, _/  / /  / / /|  / /___/ /  / / /_/ / 
|___/\___/_/\____/\___/_/_/   \__,_/ .___/\__/\____/_/     /_____/\___/ .___/_/\____/\__, /           /_____/_/   /___/_/ |_|  /_/  /_/_/ |_/_____/_/  /_/\____/  
                                  /_/                                /_/            /____/                                                                        
"@
Write-Host ""
Write-Host "$Banner"
Verificar-Requisitos
Generar-ArchivosConfiguracion -DirectorioTrabajo $DirectorioTrabajo -IP $IP