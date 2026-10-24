<#
  aplicar_cambios.ps1  (v3)
  Aplica los renombrados de columnas definidos en aplicar_cambios.csv
  a los ficheros .pas y .dfm de una carpeta (recursivo).

  Mejoras respecto a versiones anteriores:
   - En .dfm UNE las cadenas Pascal continuadas con + ANTES de buscar.
     Asi 'FOO_EM' + 'PRESA' se trata como 'FOO_EMPRESA' y no se queda
     un nombre partido sin reemplazar.
   - Tras aplicar los reemplazos, en .dfm RE-TROCEA las cadenas largas
     en chunks de ~200 chars con el formato Delphi habitual:
        'foo_........_bar' +
        'baz_........_qux'
     Esto evita que RLINK32 falle con "Unsupported 16bit resource"
     cuando una linea DFM supera los ~4096 chars.
   - Los .pas se procesan SIN unir strings (la concatenacion + en
     codigo Pascal puede ser semantica del programador).

  Reglas:
   - Reemplazo CASE-SENSITIVE.
   - Solo "palabra completa" (boundary regex en clase [A-Za-z0-9_]).
   - Procesa nombres mas largos primero.
   - Crea .bak antes de modificar (si no existe).

  Uso:
    .\aplicar_cambios.ps1 -Carpeta '.'
    .\aplicar_cambios.ps1 -Carpeta '.' -DryRun
    .\aplicar_cambios.ps1 -Carpeta '...' -ChunkLen 180
#>
param(
    [Parameter(Mandatory=$true)] [string] $Carpeta,
    [string] $Csv = (Join-Path $PSScriptRoot 'aplicar_cambios.csv'),
    [string[]] $Extensiones = @('.pas', '.dfm'),
    [int] $ChunkLen = 200,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Carpeta -PathType Container)) {
    Write-Error "La carpeta indicada no existe: $Carpeta"
    exit 1
}
if (-not (Test-Path -LiteralPath $Csv -PathType Leaf)) {
    Write-Error "No encuentro el CSV de pares: $Csv"
    exit 1
}

# --- Cargar CSV de pares ---------------------------------------------------
$pares = Import-Csv -LiteralPath $Csv -Delimiter ';' -Encoding UTF8
$seen = @{}
$pairs = @()
foreach ($p in $pares) {
    if (-not $p.OldName -or -not $p.NewName) { continue }
    if ($p.OldName -eq $p.NewName)            { continue }
    if ($seen.ContainsKey($p.OldName))        { continue }
    $seen[$p.OldName] = $true
    $pairs += [pscustomobject]@{ Old = $p.OldName; New = $p.NewName }
}
$pairs = $pairs | Sort-Object @{Expression={$_.Old.Length}; Descending=$true}, Old
Write-Host ("Pares de renombrado a aplicar: {0}" -f $pairs.Count)

# --- Recolectar ficheros ---------------------------------------------------
$archivos = @()
foreach ($ext in $Extensiones) {
    $archivos += Get-ChildItem -LiteralPath $Carpeta -Recurse -File `
                 -Filter ("*" + $ext) -ErrorAction SilentlyContinue
}
$archivos = $archivos | Where-Object { $_.Name -notmatch '\.bak$' } |
            Sort-Object FullName -Unique
Write-Host ("Ficheros a revisar: {0}" -f $archivos.Count)

# --- Codificacion ---------------------------------------------------------
function Get-FileEncoding {
    param([string] $Path)
    # 1) Detectar por BOM
    $bytes = [byte[]](Get-Content -LiteralPath $Path -Encoding Byte -ReadCount 4 -TotalCount 4)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { return 'utf-8-bom' }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { return 'utf-16le' }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { return 'utf-16be' }

    # 2) Sin BOM: probar UTF-8 estricto. Si encaja, es UTF-8; si no, ANSI.
    try {
        $allBytes = [System.IO.File]::ReadAllBytes($Path)
        $utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)  # throwOnInvalidBytes
        [void]$utf8Strict.GetString($allBytes)
        # Sólo decimos 'utf-8' si hay algun byte > 0x7F. Si todo es ASCII puro,
        # tratar como 'ansi' es indistinguible.
        $hasNonAscii = $false
        foreach ($b in $allBytes) { if ($b -gt 0x7F) { $hasNonAscii = $true; break } }
        if ($hasNonAscii) { return 'utf-8' } else { return 'ansi' }
    } catch {
        return 'ansi'
    }
}
function Read-Text {
    param([string] $Path, [string] $Enc)
    switch ($Enc) {
        'utf-8-bom' { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
        'utf-8'     { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
        'utf-16le'  { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::Unicode) }
        'utf-16be'  { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::BigEndianUnicode) }
        default     { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::GetEncoding(1252)) }
    }
}
function Write-Text {
    param([string] $Path, [string] $Content, [string] $Enc)
    switch ($Enc) {
        'utf-8-bom' { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($true)) }
        'utf-8'     {
            # UTF-8 sin BOM (mantenemos lo que tenia el archivo).
            # ATENCION: para .dfm esto NO se recomienda; RLINK32 puede fallar
            # con caracteres > 0x7F si no hay BOM. Si el archivo .dfm fuente
            # estaba en UTF-8 sin BOM, quizas sea mejor escribirlo CON BOM.
            [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
        }
        'utf-16le'  { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::Unicode) }
        'utf-16be'  { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::BigEndianUnicode) }
        default     { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::GetEncoding(1252)) }
    }
}

# --- DFM helpers (NUEVOS) -------------------------------------------------
function Join-PascalStrings {
    param([string] $Text)
    # Une  ' ... ' + ' ... '  -> ' ... ... '
    return [regex]::Replace($Text, "'\s*\+\s*'", '')
}

function Rewrap-LongDfmStrings {
    param([string] $Text, [int] $MaxLen = 200)
    if ($MaxLen -lt 40) { $MaxLen = 40 }
    $sb = [System.Text.StringBuilder]::new($Text.Length)
    # Detectar tipo de salto de linea predominante
    $lines = $Text -split "(`r`n|`n)"
    # PowerShell -split conserva separadores cuando se usan parentesis. Recopongo:
    $rebuilt = @()
    for ($i = 0; $i -lt $lines.Count; $i += 2) {
        $line = $lines[$i]
        $sep  = if ($i + 1 -lt $lines.Count) { $lines[$i+1] } else { "" }

        if ($line.Length -le $MaxLen + 32) {
            [void]$sb.Append($line)
            [void]$sb.Append($sep)
            continue
        }

        # Calcular indentacion
        $j = 0
        while ($j -lt $line.Length -and $line[$j] -eq ' ') { $j++ }
        $indent = $line.Substring(0, $j)
        $trim   = $line.Substring($j)

        if ($trim.Length -lt 2 -or $trim[0] -ne "'") {
            [void]$sb.Append($line); [void]$sb.Append($sep); continue
        }

        # Buscar ultima comilla
        $k = $trim.Length - 1
        while ($k -gt 0 -and $trim[$k] -ne "'") { $k-- }
        if ($k -le 0) { [void]$sb.Append($line); [void]$sb.Append($sep); continue }

        $body = $trim.Substring(1, $k - 1)
        $tail = $trim.Substring($k + 1)
        if ($body.Length -eq 0) { [void]$sb.Append($line); [void]$sb.Append($sep); continue }

        # Trocear body
        $eol = if ($sep) { $sep } else { "`r`n" }
        $start = 0
        while ($start -lt $body.Length) {
            $end = [Math]::Min($start + $MaxLen, $body.Length)
            # No partir un '' (apostrofo escapado Pascal): si justo en el corte hay
            # dos apostrofos consecutivos, los incluimos juntos.
            if ($end -lt $body.Length -and $body[$end - 1] -eq "'" -and $body[$end] -eq "'") {
                $end++
            }
            $chunk = $body.Substring($start, $end - $start)
            [void]$sb.Append($indent); [void]$sb.Append("'"); [void]$sb.Append($chunk); [void]$sb.Append("'")
            $start = $end
            if ($start -lt $body.Length) {
                [void]$sb.Append(' +'); [void]$sb.Append($eol)
            } else {
                [void]$sb.Append($tail); [void]$sb.Append($sep)
            }
        }
    }
    return $sb.ToString()
}

# --- Bucle principal -------------------------------------------------------
$totalFicherosTocados = 0
$totalReemplazos      = 0
$detalle              = @()

foreach ($f in $archivos) {
    try {
        $enc = Get-FileEncoding -Path $f.FullName
        $original = Read-Text -Path $f.FullName -Enc $enc

        # Para .dfm: unir strings continuados antes de buscar
        if ($f.Extension -ieq '.dfm') {
            $modificado = Join-PascalStrings $original
        } else {
            $modificado = $original
        }

        $reempEnFichero = 0
        foreach ($par in $pairs) {
            $patron = '(?<![A-Za-z0-9_])' + [regex]::Escape($par.Old) + '(?![A-Za-z0-9_])'
            $matches = [regex]::Matches($modificado, $patron)
            if ($matches.Count -gt 0) {
                $reempEnFichero += $matches.Count
                $modificado = [regex]::Replace($modificado, $patron, $par.New)
            }
        }

        # Para .dfm: trocear strings largos antes de escribir, para que
        # RLINK32 no se ahogue con lineas mayores de 4 KB.
        if ($f.Extension -ieq '.dfm') {
            $modificado = Rewrap-LongDfmStrings $modificado $ChunkLen
        }

        if ($modificado -ne $original) {
            if ($DryRun) {
                Write-Host ("[DRY] {0,4} reemplazos -> {1}" -f $reempEnFichero, $f.FullName)
            } else {
                $bak = "$($f.FullName).bak"
                if (-not (Test-Path -LiteralPath $bak)) {
                    Copy-Item -LiteralPath $f.FullName -Destination $bak -ErrorAction Stop
                }
                # Para .dfm: si veniamos de UTF-8 sin BOM, escribir CON BOM.
                # RLINK32 (compilador de recursos) no acepta UTF-8 sin BOM en
                # .dfm con caracteres acentuados y falla con
                # "Unsupported 16bit resource".
                $encOut = $enc
                if ($f.Extension -ieq '.dfm' -and $encOut -eq 'utf-8') {
                    $encOut = 'utf-8-bom'
                }
                Write-Text -Path $f.FullName -Content $modificado -Enc $encOut
                Write-Host ("OK   {0,4} reemplazos -> {1}" -f $reempEnFichero, $f.FullName)
            }
            $totalFicherosTocados++
            $totalReemplazos += $reempEnFichero
            $detalle += [pscustomobject]@{
                Archivo      = $f.FullName
                Reemplazos   = $reempEnFichero
                Codificacion = $enc
            }
        }
    } catch {
        Write-Warning ("Error procesando {0}: {1}" -f $f.FullName, $_.Exception.Message)
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host ("=== DRY RUN: {0} ficheros cambiarian, {1} reemplazos en total ===" -f $totalFicherosTocados, $totalReemplazos)
} else {
    Write-Host ("=== Listo: {0} ficheros modificados, {1} reemplazos aplicados ===" -f $totalFicherosTocados, $totalReemplazos)
}

if ($detalle.Count -gt 0) {
    $logCsv = Join-Path $PSScriptRoot ("aplicar_cambios_log_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".csv")
    $detalle | Export-Csv -LiteralPath $logCsv -Delimiter ';' -Encoding UTF8 -NoTypeInformation
    Write-Host ("Detalle: {0}" -f $logCsv)
}