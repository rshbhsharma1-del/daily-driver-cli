# DAY16_TIMEOUT_TEST v3

param(
  [string]$Url = "http://127.0.0.1:8000/process"
)

# Fresh request id for traceability (header + body must match)
$reqId = [guid]::NewGuid().ToString()

# Prepare request JSON as a file to avoid quoting issues
$bodyPath = ".\tmp_post_day16.json"
'{"user_id":1,"timeout":5}' | Set-Content -Encoding ASCII $bodyPath

# Temp files for headers and body
$hdrPath  = ".\tmp_hdr_day16.txt"
$bodyOut  = ".\tmp_body_day16.json"

# Call API: dump headers to $hdrPath and body to $bodyOut
curl.exe -s -S -X POST `
  -H "Content-Type: application/json" `
  -H "X-Req-Id: $reqId" `
  -H "X-Dev-Force: ENGINE_TIMEOUT" `
  --data-binary "@$bodyPath" `
  -D $hdrPath `
  -o $bodyOut `
  "$Url" | Out-Null

# Read header and body
if (-not (Test-Path $hdrPath) -or -not (Test-Path $bodyOut)) {
  Write-Host "FAIL: expected temp files not created"
  exit 1
}
$hdrs = Get-Content $hdrPath -Raw
$resp = Get-Content $bodyOut -Raw

# Extract X-Req-Id from response headers (fallback to X-Request-Id if present)
$hdrReq = $null
$hdrLines = $hdrs -split "`r?`n"
$hdrReq = ($hdrLines | Where-Object { $_ -match '^X-Req-Id:' } | ForEach-Object { ($_ -split ':',2)[1].Trim() }) | Select-Object -First 1
if (-not $hdrReq) {
  $hdrReq = ($hdrLines | Where-Object { $_ -match '^X-Request-Id:' } | ForEach-Object { ($_ -split ':',2)[1].Trim() }) | Select-Object -First 1
}

# Parse JSON body
try {
  if ([string]::IsNullOrWhiteSpace($resp)) { throw "empty body" }
  $json = $resp | ConvertFrom-Json
} catch {
  Write-Host "FAIL: response body not valid JSON (or empty). Raw body follows:"
  Write-Host $resp
  exit 1
}

# Assertions
$okStatus   = ($json.status -eq "error")
$okCode     = ($json.error_code -eq "ENGINE_TIMEOUT")
$okReqMatch = ($hdrReq -and ($json.req_id -eq $hdrReq))


if ($okStatus -and $okCode -and $okReqMatch) {
  Write-Host "PASS: ENGINE_TIMEOUT path ok; req_id=$($json.req_id) matches header"
  exit 0
} else {
  Write-Host "FAIL:"
  Write-Host "  status=='error'? $okStatus"
  Write-Host "  error_code=='ENGINE_TIMEOUT'? $okCode (got: $($json.error_code))"
  Write-Host "  body.req_id==header? $okReqMatch (hdr:$hdrReq, body:$($json.req_id))"
  Write-Host "`n--- Raw body ---`n$resp"
  Write-Host "`n--- Response Headers ---`n$hdrs"
  exit 1
}
