# Compila o app, sobe o servidor na rede local e abre a emulação do totem.
# Uso: powershell -ExecutionPolicy Bypass -File rodar_totem.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$porta = 8090
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
  $_.InterfaceAlias -notmatch 'Loopback|vEthernet|WSL|VirtualBox|VMware' -and $_.IPAddress -notlike '169.254*'
} | Select-Object -First 1).IPAddress
$url = "http://${ip}:$porta"
Write-Output "Endereco na rede local: $url"

flutter build web --release --dart-define=LAN_URL=$url

Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
Start-Process node -ArgumentList "ferramentas\servidor.js $porta" -WindowStyle Minimized

Start-Sleep 1
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
Start-Process $chrome -ArgumentList "--app=http://localhost:$porta/?totem", "--window-size=1400,1000"
Write-Output "Totem aberto. Celular (mesmo Wi-Fi): $url"
