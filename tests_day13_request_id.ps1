$ErrorActionPreference = "Stop"

# 1) No header → server must generate a non-empty X-Request-Id
$r1 = Invoke-WebRequest -Uri "http://127.0.0.1:8000/health"
$gen = $r1.Headers["X-Request-Id"]
if (-not $gen) { Write-Host "FAIL: missing X-Request-Id on generated path"; exit 1 }

# 2) Supplied header → must round-trip exactly
$rid = "ps-test-reqid-123"
$r2 = Invoke-WebRequest -Uri "http://127.0.0.1:8000/ping" -Headers @{ "X-Request-Id" = $rid }
$echo = $r2.Headers["X-Request-Id"]
if ($echo -ne $rid) { Write-Host "FAIL: round-trip mismatch (got '$echo')"; exit 1 }

# 3) Metrics still reachable
$r3 = Invoke-WebRequest -Uri "http://127.0.0.1:8000/metrics"
if ($r3.StatusCode -ne 200) { Write-Host "FAIL: /metrics not 200"; exit 1 }

Write-Host "PASS: X-Request-Id generated and round-tripped; /metrics 200"
exit 0
