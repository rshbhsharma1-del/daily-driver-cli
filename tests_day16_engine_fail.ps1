# DAY16_ENGINE_FAIL_TEST v1
param([string]$Url = "http://127.0.0.1:8000/process")

$reqId    = [guid]::NewGuid().ToString()
$bodyPath = ".\tmp_post_day16.json"
'{"user_id":1,"timeout":5}' | Set-Content -Encoding ASCII $bodyPath

$hdrPath  = ".\tmp_hdr_day16_fail.txt"
$bodyOut  = ".\tmp_body_day16_fail.json"

curl.exe -s -S -X POST `
  -H "Content-Type: application/json" `
  -H "X-Req-Id: $reqId" `
  -H "X-Dev-Force: ENGINE_FAIL" `
  --data-binary "@$bodyPath" `
  -D $hdrPath `
  -o $bodyOut `
  "$Url" | Out-Null

if (-not (Test-Path $hdrPath) -or -not (Test-Path $bodyOut)) { Write-Host "FAIL: expected temp files not created"; exit 1 }

$hdrs = Get-Content $hdrPath -Raw
$resp = Get-Content $bodyOut -Raw

$hdrLines = $hdrs -split "`r?`n"
$hdrReq = ($hdrLines | Where-Object { $_ -match '^(?i)X-Req-Id:' } | ForEach-Object { ($_ -split ':',2)[1].Trim() }) | Select-Object -First 1
if (-not $hdrReq) { $hdrReq = ($hdrLines | Where-Object { $_ -match '^(?i)X-Request-Id:' } | ForEach-Object { ($_ -split ':',2)[1].Trim() }) | Select-Object -First 1 }

try {
  if ([string]::IsNullOrWhiteSpace($resp)) { throw "empty body" }
  $json = $resp | ConvertFrom-Json
} catch {
  Write-Host "FAIL: response body not valid JSON (or empty). Raw body follows:"; Write-Host $resp; exit 1
}

# Assertions: status error, TOP-LEVEL error_code, and header/body req_id match
$okStatus   = ($json.status -eq "error")
$okCode     = ($json.error_code -eq "ENGINE_FAIL")
$okReqMatch = ($hdrReq -and ($json.req_id -eq $hdrReq))

if ($okStatus -and $okCode -and $okReqMatch) {
  Write-Host "PASS: ENGINE_FAIL path ok; req_id=$($json.req_id) matches header"
  exit 0
} else {
  Write-Host "FAIL:"
  Write-Host "  status=='error'? $okStatus"
  Write-Host "  error_code=='ENGINE_FAIL'? $okCode (got: $($json.error_code))"
  Write-Host "  body.req_id==header? $okReqMatch (hdr:$hdrReq, body:$($json.req_id))"
  Write-Host "`n--- Raw body ---`n$resp"
  Write-Host "`n--- Response Headers ---`n$hdrs"
  exit 1
}
