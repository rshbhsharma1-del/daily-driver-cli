$resp = Invoke-WebRequest http://127.0.0.1:8000/health
$hdr  = $resp.Headers["X-Process-Time-ms"]
Write-Host "Test: X-Process-Time-ms header exists and > 0"
if (-not $hdr) { Write-Host "FAIL: header missing"; exit 1 }
if (-not ($hdr -as [double])) { Write-Host "FAIL: not numeric: $hdr"; exit 1 }
if ([double]$hdr -le 0) { Write-Host "FAIL: not > 0: $hdr"; exit 1 }
Write-Host "PASS: header=$hdr ms"
exit 0
