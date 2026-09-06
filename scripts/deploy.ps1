param([string]$Tomcat='C:\apache-tomcat-11.0.24')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$war=Join-Path $projectRoot 'target\hotel.war'
if(-not (Test-Path $war)){throw 'Ejecute scripts/build.ps1 primero.'}
if(-not (Test-Path (Join-Path $Tomcat 'conf\hotel-db.properties'))){throw 'Configure conf/hotel-db.properties según config/hotel-db.properties.example.'}
Copy-Item -LiteralPath $war -Destination (Join-Path $Tomcat 'webapps\hotel.war') -Force
Write-Host 'WAR copiado. Tomcat lo despliega automáticamente en http://localhost:8080/hotel/'
