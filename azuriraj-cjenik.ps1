param()

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$CjenikDir = Join-Path $Root "cjenik"
$ArhivaDir = Join-Path $CjenikDir "arhiva"
$CijeneFile = Join-Path $CjenikDir "cijene.txt"
$IndexFile = Join-Path $Root "index.html"

$Objekt = "usluzni-objekt"
$Adresa = "petkovec-toplicki-39_42223-petkovec-toplicki"
$Oznaka = "OBJ-01"

if (!(Test-Path $ArhivaDir)) {
    New-Item -ItemType Directory -Path $ArhivaDir | Out-Null
}

if (!(Test-Path $CijeneFile)) {
    throw "Nedostaje datoteka: $CijeneFile"
}

if (!(Test-Path $IndexFile)) {
    throw "Nedostaje index.html u root folderu stranice."
}

# Pronađi aktualni verzionirani XML u /cjenik (ne u arhivi)
$Current = Get-ChildItem -Path $CjenikDir -File -Filter "*.xml" |
    Where-Object { $_.Name -match "_OBJ-01_(\d+)_\d{8}-\d{4}\.xml$" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$NextVersion = 1

if ($Current) {
    if ($Current.Name -match "_OBJ-01_(\d+)_") {
        $NextVersion = [int]$Matches[1] + 1
    }

    # Arhiviraj staru verziju
    $ArchiveTarget = Join-Path $ArhivaDir $Current.Name
    if (!(Test-Path $ArchiveTarget)) {
        Copy-Item $Current.FullName $ArchiveTarget
    }

    # Makni staru aktualnu kopiju iz glavnog cjenik foldera
    Remove-Item $Current.FullName
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$NewName = "${Objekt}_${Adresa}_${Oznaka}_${NextVersion}_${Timestamp}.xml"
$NewPath = Join-Path $CjenikDir $NewName

# Učitaj cijene
$Lines = Get-Content $CijeneFile -Encoding UTF8
if ($Lines.Count -lt 2) {
    throw "cijene.txt nema nijednu uslugu."
}

$Rows = foreach ($line in $Lines | Select-Object -Skip 1) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split("|")
    if ($parts.Count -ne 5) {
        throw "Neispravan red u cijene.txt: $line"
    }

    [PSCustomObject]@{
        naziv = $parts[0].Trim()
        cijena = $parts[1].Trim()
        sidrena = $parts[2].Trim()
        jedinica = $parts[3].Trim()
        posebno = $parts[4].Trim().ToLower()
    }
}

function Escape-Xml([string]$Text) {
    return [System.Security.SecurityElement]::Escape($Text)
}

$Xml = New-Object System.Text.StringBuilder
[void]$Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$Xml.AppendLine('<cjenik>')
[void]$Xml.AppendLine('  <datum_referentne_cijene>2026-09-10</datum_referentne_cijene>')
[void]$Xml.AppendLine('  <valuta>EUR</valuta>')
[void]$Xml.AppendLine('')

foreach ($r in $Rows) {
    [void]$Xml.AppendLine('  <usluga>')
    [void]$Xml.AppendLine("    <naziv>$(Escape-Xml $r.naziv)</naziv>")
    [void]$Xml.AppendLine("    <jedinica>$(Escape-Xml $r.jedinica)</jedinica>")
    [void]$Xml.AppendLine("    <maloprodajna_cijena>$($r.cijena)</maloprodajna_cijena>")
    [void]$Xml.AppendLine("    <sidrena_cijena>$($r.sidrena)</sidrena_cijena>")
    [void]$Xml.AppendLine("    <posebni_oblik_prodaje>$($r.posebno)</posebni_oblik_prodaje>")
    [void]$Xml.AppendLine('  </usluga>')
    [void]$Xml.AppendLine('')
}

[void]$Xml.AppendLine('</cjenik>')

[System.IO.File]::WriteAllText($NewPath, $Xml.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# Ažuriraj svaki href koji vodi na /cjenik/*.xml
$Html = Get-Content $IndexFile -Raw -Encoding UTF8
$NewHref = "/cjenik/$NewName"
$Html = [regex]::Replace($Html, '/cjenik/[^"''\s>]+\.xml', $NewHref)
[System.IO.File]::WriteAllText($IndexFile, $Html, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "GOTOVO" -ForegroundColor Green
Write-Host "Nova verzija: $NewName"
Write-Host "Broj pohrane: $NextVersion"
Write-Host "Stara verzija je spremljena u cjenik\arhiva\"
Write-Host "index.html je ažuriran."
Write-Host ""
Write-Host "Sada uploaduj index.html i cijeli folder cjenik na hosting."
Write-Host ""
Read-Host "Pritisni Enter za zatvaranje"
