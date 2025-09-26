$ErrorActionPreference="Stop"
$codes=@("ENGINE_TIMEOUT","ENGINE_BAD_OUTPUT","ENGINE_NONZERO_EXIT","ENGINE_FAIL"); $ok=$true
foreach($c in $codes){
  $r=Invoke-WebRequest -Uri "http://127.0.0.1:8000/process" -Method POST `
    -Headers @{ "Content-Type"="application/json"; "X-Dev-Force"=$c } `
    -Body '{"user_id":1,"timeout":5}'

  $rid=$r.Headers["X-Request-Id"]
  $j=$r.Content | ConvertFrom-Json

  if($j.status -ne "error" -or $j.error_code -ne $c -or $j.req_id -ne $rid){
    Write-Host "FAIL: $c"
    $ok=$false
  } else {
    Write-Host "PASS: $c (req_id=$($j.req_id))"
  }
}
if($ok){ exit 0 } else { exit 1 }
