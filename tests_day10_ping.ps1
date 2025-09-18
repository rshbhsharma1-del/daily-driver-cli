$resp = Invoke-WebRequest http://127.0.0.1:8000/ping
Write-Host "Test: /ping returns pong=true and ts"
if ($resp.StatusCode -ne 200) { Write-Host "FAIL: status $($resp.StatusCode)"; exit 1 }
$body = $resp.Content | ConvertFrom-Json
if (-not $body.pong) { Write-Host "FAIL: pong != true"; exit 1 }
if (-not $body.ts) { Write-Host "FAIL: ts missing"; exit 1 }
Write-Host "PASS: /ping ok ts=$($body.ts)"
exit 0
