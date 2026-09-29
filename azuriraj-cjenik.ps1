param()

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$CjenikDir = Join-Path $Root "cjenik"
$ArhivaDir = Join-Path $CjenikDir "arhiva"
$CijeneFile = Join-Path $CjenikDir "cijene.txt"
$MainIndex = Join-Path $Root "index.html"
$ArchiveIndex = Join-Path $ArhivaDir "index.html"

$Objekt = "usluzni-objekt"
$Adresa = "petkovec-toplicki-39_42223-petkovec-toplicki"
$Oznaka = "OBJ-01"

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "GRESKA: $Message" -ForegroundColor Red
    Write-Host ""
    Read-Host "Pritisni Enter za zatvaranje"
    exit 1
}

try {
    if (!(Test-Path $CjenikDir)) { New-Item -ItemType Directory -Path $CjenikDir -Force | Out-Null }
    if (!(Test-Path $ArhivaDir)) { New-Item -ItemType Directory -Path $ArhivaDir -Force | Out-Null }
    if (!(Test-Path $CijeneFile)) { Fail "Nedostaje cjenik\cijene.txt" }
    if (!(Test-Path $MainIndex)) { Fail "Nedostaje glavni index.html" }

    # 1) Pronađi aktualni verzionirani XML samo u /cjenik/
    $CurrentFiles = @(
        Get-ChildItem -LiteralPath $CjenikDir -File |
        Where-Object { $_.Name -match "_OBJ-01_(\d+)_\d{8}-\d{4}\.xml$" } |
        Sort-Object Name
    )

    $Current = $null
    $CurrentVersion = 0

    foreach ($f in $CurrentFiles) {
        if ($f.Name -match "_OBJ-01_(\d+)_") {
            $v = [int]$Matches[1]
            if ($v -gt $CurrentVersion) {
                $CurrentVersion = $v
                $Current = $f
            }
        }
    }

    # 2) Ako postoji aktualni XML, arhiviraj ga
    if ($Current) {
        $ArchiveTarget = Join-Path $ArhivaDir $Current.Name
        if (!(Test-Path $ArchiveTarget)) {
            Copy-Item -LiteralPath $Current.FullName -Destination $ArchiveTarget
        }
    }

    # 3) Nova verzija
    $NextVersion = $CurrentVersion + 1
    if ($NextVersion -lt 1) { $NextVersion = 1 }

    $Timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $NewName = "${Objekt}_${Adresa}_${Oznaka}_${NextVersion}_${Timestamp}.xml"
    $NewPath = Join-Path $CjenikDir $NewName

    # 4) Učitaj cijene.txt
    $Lines = @(Get-Content -LiteralPath $CijeneFile -Encoding UTF8)
    if ($Lines.Count -lt 2) { Fail "cijene.txt nema nijednu uslugu." }

    $Rows = @()
    foreach ($line in ($Lines | Select-Object -Skip 1)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line.Split("|")
        if ($parts.Count -ne 5) { Fail "Neispravan red u cijene.txt: $line" }

        $Rows += [PSCustomObject]@{
            naziv = $parts[0].Trim()
            cijena = $parts[1].Trim()
            sidrena = $parts[2].Trim()
            jedinica = $parts[3].Trim()
            posebno = $parts[4].Trim().ToLower()
        }
    }

    if ($Rows.Count -eq 0) { Fail "Nema usluga za izradu XML-a." }

    function Escape-Xml([string]$Text) {
        return [System.Security.SecurityElement]::Escape($Text)
    }

    # 5) Generiraj novi XML
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

    [System.IO.File]::WriteAllText(
        $NewPath,
        $Xml.ToString(),
        (New-Object System.Text.UTF8Encoding($false))
    )

    # 6) Makni stare aktualne XML-ove iz /cjenik/ nakon uspješnog generiranja
    foreach ($f in $CurrentFiles) {
        if ($f.FullName -ne $NewPath) {
            Remove-Item -LiteralPath $f.FullName -Force
        }
    }

    # 7) Ažuriraj glavni index.html: svi /cjenik/*.xml linkovi idu na novi XML
    $Html = Get-Content -LiteralPath $MainIndex -Raw -Encoding UTF8
    $NewHref = "/cjenik/$NewName"

    # Existing XML links
    $Html = [regex]::Replace(
        $Html,
        '/cjenik/[^"''\s>]+\.xml',
        $NewHref
    )

    # Ensure noindex, follow
    $Html = $Html -replace 'content="noindex,\s*nofollow"', 'content="noindex, follow"'

    # Ensure machine-discovery link exists
    if ($Html -notmatch 'rel="alternate"[^>]*application/xml') {
        $HeadLink = "  <link rel=""alternate"" type=""application/xml"" href=""$NewHref"" title=""Digitalni cjenik"" />"
        $Html = $Html -replace '(<link rel="stylesheet"[^>]*>)', "$HeadLink`r`n`r`n`$1"
    }

    # Ensure visible footer links exist
    if ($Html -notmatch 'href="/cjenik/arhiva/"') {
        $FooterLinks = @"
      <div class="legal-footer">
        <a href="$NewHref" type="application/xml">Digitalni cjenik</a>
        <span aria-hidden="true"> · </span>
        <a href="/cjenik/arhiva/">Arhiva cjenika</a>
      </div>
"@
        $Html = $Html -replace '</footer>', "$FooterLinks`r`n    </footer>"
    }

    [System.IO.File]::WriteAllText(
        $MainIndex,
        $Html,
        (New-Object System.Text.UTF8Encoding($false))
    )

    # 8) Generiraj JAVNI index arhive prema stvarnim XML datotekama
    $ArchivedFiles = @(
        Get-ChildItem -LiteralPath $ArhivaDir -File |
        Where-Object { $_.Extension -ieq ".xml" } |
        Sort-Object Name -Descending
    )

    $A = New-Object System.Text.StringBuilder
    [void]$A.AppendLine('<!DOCTYPE html>')
    [void]$A.AppendLine('<html lang="hr">')
    [void]$A.AppendLine('<head>')
    [void]$A.AppendLine('  <meta charset="UTF-8">')
    [void]$A.AppendLine('  <meta name="viewport" content="width=device-width, initial-scale=1.0">')
    [void]$A.AppendLine('  <meta name="robots" content="noindex, follow">')
    [void]$A.AppendLine('  <title>Arhiva digitalnog cjenika — DBESFILM</title>')
    [void]$A.AppendLine('  <style>')
    [void]$A.AppendLine('    body{margin:0;padding:40px 20px;font-family:Arial,sans-serif;background:#0b0b0b;color:#f4f4f4}')
    [void]$A.AppendLine('    main{max-width:900px;margin:0 auto}')
    [void]$A.AppendLine('    h1{font-size:28px;margin-bottom:12px}')
    [void]$A.AppendLine('    p{color:#aaa;line-height:1.6}')
    [void]$A.AppendLine('    ul{padding-left:20px;line-height:1.9}')
    [void]$A.AppendLine('    a{color:#f4f4f4;text-underline-offset:3px;overflow-wrap:anywhere}')
    [void]$A.AppendLine('  </style>')
    [void]$A.AppendLine('</head>')
    [void]$A.AppendLine('<body><main>')
    [void]$A.AppendLine('  <h1>Arhiva digitalnog cjenika</h1>')

    if ($ArchivedFiles.Count -eq 0) {
        [void]$A.AppendLine('  <p>Trenutno nema arhiviranih verzija cjenika.</p>')
    } else {
        [void]$A.AppendLine("  <p>Prethodno objavljene verzije digitalnog cjenika ($($ArchivedFiles.Count)):</p>")
        [void]$A.AppendLine('  <ul>')

        foreach ($file in $ArchivedFiles) {
            $Display = [System.Net.WebUtility]::HtmlEncode($file.Name)
            $Href = [Uri]::EscapeDataString($file.Name)
            [void]$A.AppendLine("    <li><a href=""./$Href"">$Display</a></li>")
        }

        [void]$A.AppendLine('  </ul>')
    }

    [void]$A.AppendLine('</main></body></html>')

    [System.IO.File]::WriteAllText(
        $ArchiveIndex,
        $A.ToString(),
        (New-Object System.Text.UTF8Encoding($false))
    )

    Write-Host ""
    Write-Host "GOTOVO" -ForegroundColor Green
    Write-Host "Nova verzija: $NewName"
    Write-Host "Broj pohrane: $NextVersion"
    Write-Host "XML-ova u javnoj arhivi: $($ArchivedFiles.Count)"
    Write-Host "Arhiva: $ArchiveIndex"
    Write-Host ""
    Write-Host "Sada commit/pushaj ili uploaduj:"
    Write-Host " - index.html"
    Write-Host " - cijeli folder cjenik"
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "GRESKA:" $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}

Read-Host "Pritisni Enter za zatvaranje"
