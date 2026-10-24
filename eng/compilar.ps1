param(
  [ValidateSet('Debug', 'Release')]
  [string]$Configuracion = 'Debug',
  [ValidateSet('Win32', 'Win64', 'Ambas')]
  [string]$Plataforma = 'Ambas',
  [string]$CarpetaSalida = '',
  [switch]$SoloValidar
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Reutilizar las dependencias ya instaladas con la marca anterior.
foreach ($componente in @('DELPHI', 'DEVEXPRESS', 'FASTREPORT', 'UNIDAC',
    'DUNITX', 'JCL', 'JVCL', 'DCPCRYPT', 'SYNEDIT', 'SYNPDF')) {
  $variableNueva = 'VIRACASH_' + $componente + '_ROOT'
  if ([string]::IsNullOrWhiteSpace(
      [Environment]::GetEnvironmentVariable($variableNueva, 'Process'))) {
    [Environment]::SetEnvironmentVariable($variableNueva,
      [Environment]::GetEnvironmentVariable(
        'FACTUZAM_' + $componente + '_ROOT', 'Process'), 'Process')
  }
}

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$proyecto = Join-Path $raiz 'vcash.dproj'
$raizSalida = if ([string]::IsNullOrWhiteSpace($CarpetaSalida)) {
  Join-Path $raiz 'build\reproducible'
}
else {
  [IO.Path]::GetFullPath($CarpetaSalida)
}
$plataformas = if ($Plataforma -eq 'Ambas') {
  @('Win32', 'Win64')
}
else {
  @($Plataforma)
}

$errores = [System.Collections.Generic.List[string]]::new()
$delphiRoot = $env:VIRACASH_DELPHI_ROOT
if ([string]::IsNullOrWhiteSpace($delphiRoot)) {
  $delphiRoot = $env:BDS
}
if ([string]::IsNullOrWhiteSpace($delphiRoot)) {
  $errores.Add(
    'Falta Delphi. Defina VIRACASH_DELPHI_ROOT con la raíz de RAD Studio.')
}

$rsvars = ''
if (-not [string]::IsNullOrWhiteSpace($delphiRoot)) {
  $rsvars = Join-Path $delphiRoot 'bin\rsvars.bat'
  if (-not (Test-Path -LiteralPath $rsvars -PathType Leaf)) {
    $errores.Add("No existe el entorno de Delphi: $rsvars.")
  }
}

$devExpressRoot = $env:VIRACASH_DEVEXPRESS_ROOT
if ([string]::IsNullOrWhiteSpace($devExpressRoot)) {
  $errores.Add(
    'Falta DevExpress. Defina VIRACASH_DEVEXPRESS_ROOT; consulte ' +
    'factuzam_web\scripts\README.md.')
}
$fastReportRoot = $env:VIRACASH_FASTREPORT_ROOT
if ([string]::IsNullOrWhiteSpace($fastReportRoot)) {
  $errores.Add(
    'Falta FastReport. Defina VIRACASH_FASTREPORT_ROOT; consulte ' +
    'factuzam_web\scripts\README.md.')
}
$uniDacRoot = $env:VIRACASH_UNIDAC_ROOT
if ([string]::IsNullOrWhiteSpace($uniDacRoot)) {
  $errores.Add(
    'Falta UniDAC. Defina VIRACASH_UNIDAC_ROOT; consulte ' +
    'factuzam_web\scripts\README.md.')
}

foreach ($destino in $plataformas) {
  if (-not [string]::IsNullOrWhiteSpace($devExpressRoot)) {
    $rutaDevExpress = if ($destino -eq 'Win32') {
      $devExpressRoot
    }
    else {
      Join-Path $devExpressRoot 'Win64'
    }
    $unidadDevExpress = Join-Path $rutaDevExpress 'cxClasses.dcu'
    if (-not (Test-Path -LiteralPath $unidadDevExpress -PathType Leaf)) {
      $errores.Add(
        "DevExpress no contiene cxClasses.dcu para $($destino): " +
        "$rutaDevExpress.")
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($fastReportRoot)) {
    $rutaFastReport = Join-Path $fastReportRoot $destino
    $unidadFastReport = Join-Path $rutaFastReport 'frxClass.dcu'
    if (-not (Test-Path -LiteralPath $unidadFastReport -PathType Leaf)) {
      $errores.Add(
        "FastReport no contiene frxClass.dcu para $($destino): " +
        "$rutaFastReport.")
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($uniDacRoot)) {
    $rutaUniDac = Join-Path $uniDacRoot $destino
    $unidadUniDac = Join-Path $rutaUniDac 'Uni.dcu'
    if (-not (Test-Path -LiteralPath $unidadUniDac -PathType Leaf)) {
      $errores.Add(
        "UniDAC no contiene Uni.dcu para $($destino): $rutaUniDac.")
    }
  }
}

$dependenciasAdicionales = @(
  @{ Nombre = 'JCL'; Variable = 'VIRACASH_JCL_ROOT'; Archivos = @(
      'lib\d37\{0}\JclBase.dcu', 'source\include\jcl.inc') },
  @{ Nombre = 'JVCL'; Variable = 'VIRACASH_JVCL_ROOT'; Archivos = @(
      'lib\d37\{0}\JvComponentBase.dcu', 'common\jvcl.inc',
      'resources\JvConsts.res') },
  @{ Nombre = 'DCPCrypt'; Variable = 'VIRACASH_DCPCRYPT_ROOT'; Archivos = @(
      'DCPcrypt2.pas', 'Ciphers\DCPrijndael.pas', 'Hashes\DCPsha256.pas') },
  @{ Nombre = 'SynEdit'; Variable = 'VIRACASH_SYNEDIT_ROOT'; Archivos = @(
      'build\{0}\SynEdit.dcu', 'Source\SynEdit.res') },
  @{ Nombre = 'SynPDF'; Variable = 'VIRACASH_SYNPDF_ROOT'; Archivos = @(
      'Lib\RS37\{0}\SynPdf.dcu') }
)
foreach ($dependencia in $dependenciasAdicionales) {
  $directorio = [Environment]::GetEnvironmentVariable(
    $dependencia.Variable, 'Process')
  if ([string]::IsNullOrWhiteSpace($directorio)) {
    $errores.Add(
      "Falta $($dependencia.Nombre). Defina $($dependencia.Variable).")
  }
  else {
    foreach ($archivo in $dependencia.Archivos) {
      $destinosArchivo = if ($archivo.Contains('{0}')) {
        $plataformas
      }
      else {
        @('comun')
      }
      foreach ($destinoArchivo in $destinosArchivo) {
        $rutaArchivo = Join-Path $directorio ($archivo -f $destinoArchivo)
        if (-not (Test-Path -LiteralPath $rutaArchivo -PathType Leaf)) {
          $errores.Add(
            "$($dependencia.Nombre) no contiene $rutaArchivo.")
        }
      }
    }
  }
}

$msbuild = ''
$candidatos = @(
  (Join-Path $env:SystemRoot (
    'Microsoft.NET\Framework\v4.0.30319\MSBuild.exe')),
  (Join-Path $env:SystemRoot (
    'Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe'))
)
foreach ($candidato in $candidatos) {
  if (([string]::IsNullOrWhiteSpace($msbuild)) -and
      (Test-Path -LiteralPath $candidato -PathType Leaf)) {
    $msbuild = $candidato
  }
}
if ([string]::IsNullOrWhiteSpace($msbuild)) {
  $comandoMsBuild = Get-Command 'MSBuild.exe' -ErrorAction SilentlyContinue
  if ($null -ne $comandoMsBuild) {
    $msbuild = $comandoMsBuild.Source
  }
}
if ([string]::IsNullOrWhiteSpace($msbuild)) {
  $errores.Add(
    'No se encontró MSBuild.exe. Instale .NET Framework o añádalo a PATH.')
}

if ($errores.Count -gt 0) {
  Write-Output 'No se puede compilar ViraCash:'
  foreach ($errorDependencia in $errores) {
    Write-Output "  - $errorDependencia"
  }
  exit 2
}

Write-Output (
  'Dependencias de compilación: OK. Plataformas: ' +
  ($plataformas -join ', ') + '.')
if ($SoloValidar) {
  exit 0
}

foreach ($destino in $plataformas) {
  $salidaDcu = Join-Path $raizSalida "dcu\$destino\$Configuracion"
  $salidaExe = Join-Path $raizSalida "bin\$destino\$Configuracion"
  [void](New-Item -ItemType Directory -Path $salidaDcu -Force)
  [void](New-Item -ItemType Directory -Path $salidaExe -Force)
  Write-Output "Compilando viracash $Configuracion $destino..."
  $argumentos = @(
    '"' + $proyecto + '"',
    '/t:Build',
    "/p:Config=$Configuracion",
    "/p:Platform=$destino",
    '/p:ImportEnvOptions=false',
    '/p:DCC_DcuOutput="' + $salidaDcu + '"',
    '/p:DCC_ExeOutput="' + $salidaExe + '"',
    '/nologo',
    '/verbosity:minimal'
  )
  $orden = 'call "' + $rsvars + '" && "' + $msbuild + '" ' +
    ($argumentos -join ' ')
  & $env:ComSpec /d /s /c $orden
  if ($LASTEXITCODE -ne 0) {
    Write-Output (
      "Compilación fallida: $Configuracion $destino " +
      "(código $LASTEXITCODE).")
    exit $LASTEXITCODE
  }
  Write-Output "Compilación correcta: $Configuracion $destino."
}

exit 0
