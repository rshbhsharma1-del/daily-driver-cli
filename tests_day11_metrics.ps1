try {
  $r1 = Invoke-WebRequest -Uri "http://127.0.0.1:8000/metrics" -ErrorAction Stop
  $r2 = Invoke-WebRequest -Uri "http://127.0.0.1:8000/metrics" -ErrorAction Stop
} catch {
  Write-Host "FAIL: /metrics not reachable"; exit 1
}

$c1 = $r1.Content
$c2 = $r2.Content

# Must include /metrics with count >= 1 on the second call
if ($c2 -notmatch '"/metrics"\s*:\s*(\d+)') { Write-Host "FAIL: /metrics key missing"; exit 1 }
$m2 = [int]$Matches[1]
if ($m2 -lt 1) { Write-Host "FAIL: /metrics counter < 1"; exit 1 }

# _total should increase by at least 1 between first and second call
if ($c1 -notmatch '"_total"\s*:\s*(\d+)') { Write-Host "FAIL: _total missing in first"; exit 1 }
$tot1 = [int]$Matches[1]
if ($c2 -notmatch '"_total"\s*:\s*(\d+)') { Write-Host "FAIL: _total missing in second"; exit 1 }
$tot2 = [int]$Matches[1]
if ($tot2 -lt ($tot1 + 1)) { Write-Host "FAIL: _total did not increase"; exit 1 }

Write-Host "PASS: /metrics returns counts incl. /metrics and totals grow"
exit 0
