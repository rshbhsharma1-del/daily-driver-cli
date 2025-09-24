param(
  [string]$Url = "http://127.0.0.1:8000/process",
  [string]$BodyPath = "$env:USERPROFILE\tmp_post.json",
  [string]$LogPath = ".\server.log"
)

if (-not (Test-Path $BodyPath)) {
  '{"user_id":1,"timeout":5}' | Set-Content -NoNewline -Encoding ASCII $BodyPath
}

$rid = [guid]::NewGuid().ToString()
$headers = @{ 'Content-Type'='application/json'; 'X-Request-Id'=$rid }

$resp = Invoke-WebRequest -Uri $Url -Method Post -Headers $headers -InFile $BodyPath
$hdr = $resp.Headers['x-request-id']
$js  = $resp.Content | ConvertFrom-Json
$bid = $js.req_id

if ($hdr -ne $rid) { Write-Error "Header mismatch: expected $rid got $hdr"; exit 1 }
if ($bid -ne $rid) { Write-Error "Body req_id mismatch: expected $rid got $bid"; exit 1 }

if (Test-Path $LogPath) {
  $hits = Select-String -Path $LogPath -Pattern $rid
  if (-not $hits) { Write-Error "req_id not found in $LogPath"; exit 1 }
}

"PASS: req_id=$rid matches header and body"
exit 0
