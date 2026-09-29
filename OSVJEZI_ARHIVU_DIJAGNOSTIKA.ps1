$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ArchiveDir = Join-Path $Root "cjenik\arhiva"
$ArchiveIndex = Join-Path $ArchiveDir "index.html"

Write-Host ""
Write-Host "ROOT:" $Root -ForegroundColor Cyan
Write-Host "ARHIVA:" $ArchiveDir -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $ArchiveDir)) {
    Write-Host "GRESKA: Folder cjenik\arhiva ne postoji." -ForegroundColor Red
    Read-Host "Enter"
    exit 1
}

$Files = @(Get-ChildItem -LiteralPath $ArchiveDir -File | Where-Object { $_.Extension -ieq ".xml" } | Sort-Object Name)

Write-Host "PRONADJENO XML DATOTEKA:" $Files.Count -ForegroundColor Yellow
foreach ($f in $Files) {
    Write-Host " - $($f.Name)"
}
Write-Host ""

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<!DOCTYPE html>')
[void]$sb.AppendLine('<html lang="hr">')
[void]$sb.AppendLine('<head>')
[void]$sb.AppendLine('  <meta charset="UTF-8">')
[void]$sb.AppendLine('  <meta name="viewport" content="width=device-width, initial-scale=1.0">')
[void]$sb.AppendLine('  <meta name="robots" content="noindex, follow">')
[void]$sb.AppendLine('  <title>Arhiva digitalnog cjenika — DBESFILM</title>')
[void]$sb.AppendLine('  <style>')
[void]$sb.AppendLine('    body{margin:0;padding:40px 20px;font-family:Arial,sans-serif;background:#0b0b0b;color:#f4f4f4}')
[void]$sb.AppendLine('    main{max-width:900px;margin:0 auto}')
[void]$sb.AppendLine('    h1{font-size:28px;margin-bottom:12px}')
[void]$sb.AppendLine('    p{color:#aaa;line-height:1.6}')
[void]$sb.AppendLine('    ul{padding-left:20px;line-height:1.9}')
[void]$sb.AppendLine('    a{color:#f4f4f4;text-underline-offset:3px;overflow-wrap:anywhere}')
[void]$sb.AppendLine('  </style>')
[void]$sb.AppendLine('</head>')
[void]$sb.AppendLine('<body><main>')
[void]$sb.AppendLine('  <h1>Arhiva digitalnog cjenika</h1>')

if ($Files.Count -eq 0) {
    [void]$sb.AppendLine('  <p>Trenutno nema arhiviranih verzija cjenika.</p>')
}
else {
    [void]$sb.AppendLine("  <p>Prethodno objavljene verzije digitalnog cjenika ($($Files.Count)):</p>")
    [void]$sb.AppendLine('  <ul>')
    foreach ($f in $Files) {
        $display = [System.Net.WebUtility]::HtmlEncode($f.Name)
        $href = [Uri]::EscapeDataString($f.Name)
        [void]$sb.AppendLine("    <li><a href=""./$href"">$display</a></li>")
    }
    [void]$sb.AppendLine('  </ul>')
}

[void]$sb.AppendLine('</main></body></html>')

[System.IO.File]::WriteAllText(
    $ArchiveIndex,
    $sb.ToString(),
    (New-Object System.Text.UTF8Encoding($false))
)

Write-Host ""
Write-Host "INDEX PREPISAN:" $ArchiveIndex -ForegroundColor Green
Write-Host ""
Write-Host "Ako gore pise PRONADJENO XML DATOTEKA: 2, otvori sada cjenik\arhiva\index.html."
Write-Host ""
Read-Host "Pritisni Enter za zatvaranje"
