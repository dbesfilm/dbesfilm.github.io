@echo off
setlocal
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$ErrorActionPreference='Stop';" ^
"$root = Get-Location;" ^
"$dir = Join-Path $root 'cjenik\arhiva';" ^
"$index = Join-Path $dir 'index.html';" ^
"if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null };" ^
"$files = @(Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Extension -ieq '.xml' } | Sort-Object Name -Descending);" ^
"$sb = New-Object System.Text.StringBuilder;" ^
"[void]$sb.AppendLine('<!DOCTYPE html>');" ^
"[void]$sb.AppendLine('<html lang=\"hr\">');" ^
"[void]$sb.AppendLine('<head>');" ^
"[void]$sb.AppendLine('  <meta charset=\"UTF-8\">');" ^
"[void]$sb.AppendLine('  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">');" ^
"[void]$sb.AppendLine('  <meta name=\"robots\" content=\"noindex, follow\">');" ^
"[void]$sb.AppendLine('  <title>Arhiva digitalnog cjenika — DBESFILM</title>');" ^
"[void]$sb.AppendLine('  <style>body{margin:0;padding:40px 20px;font-family:Arial,sans-serif;background:#0b0b0b;color:#f4f4f4}main{max-width:900px;margin:0 auto}h1{font-size:28px;margin-bottom:12px}p{color:#aaa;line-height:1.6}ul{padding-left:20px;line-height:1.9}a{color:#f4f4f4;text-underline-offset:3px;overflow-wrap:anywhere}</style>');" ^
"[void]$sb.AppendLine('</head>');" ^
"[void]$sb.AppendLine('<body><main>');" ^
"[void]$sb.AppendLine('  <h1>Arhiva digitalnog cjenika</h1>');" ^
"if ($files.Count -eq 0) { [void]$sb.AppendLine('  <p>Trenutno nema arhiviranih verzija cjenika.</p>') } else { [void]$sb.AppendLine(('  <p>Prethodno objavljene verzije digitalnog cjenika (' + $files.Count + '):</p>')); [void]$sb.AppendLine('  <ul>'); foreach($f in $files){ $n=[System.Net.WebUtility]::HtmlEncode($f.Name); $u=[Uri]::EscapeDataString($f.Name); [void]$sb.AppendLine(('    <li><a href=\"./' + $u + '\">' + $n + '</a></li>')) }; [void]$sb.AppendLine('  </ul>') };" ^
"[void]$sb.AppendLine('</main></body></html>');" ^
"[IO.File]::WriteAllText($index,$sb.ToString(),(New-Object Text.UTF8Encoding($false)));" ^
"Write-Host ''; Write-Host 'ARHIVA OSVJEZENA' -ForegroundColor Green; Write-Host ('Pronadjeno XML datoteka: ' + $files.Count); Write-Host ('Generirano: ' + $index); Write-Host ''; $files | ForEach-Object { Write-Host (' - ' + $_.Name) }; Write-Host ''; Read-Host 'Pritisni Enter za zatvaranje'"

endlocal
