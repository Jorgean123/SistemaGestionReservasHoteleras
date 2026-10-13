param([switch]$Integration)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$jdk21='C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot'
if(Test-Path (Join-Path $jdk21 'bin\java.exe')){
  $env:JAVA_HOME=$jdk21
}else{
  $javac=Get-Command javac.exe -ErrorAction Stop
  $env:JAVA_HOME=Split-Path (Split-Path $javac.Source -Parent) -Parent
}
$maven=Join-Path $projectRoot '.tools\apache-maven-3.9.11\bin\mvn.cmd'
if(-not (Test-Path $maven)) { throw 'Instale Maven 3.9.11 en .tools/apache-maven-3.9.11 o ejecute mvn verify con su instalación.' }
if($Integration){ $env:HOTEL_INTEGRATION='true' }
try { & $maven '-Dcatalina.base=C:\apache-tomcat-11.0.24' -B verify; if($LASTEXITCODE -ne 0){throw 'Falló la compilación o las pruebas.'} }
finally { Remove-Item Env:HOTEL_INTEGRATION -ErrorAction SilentlyContinue }
