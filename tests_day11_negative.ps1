try {
  Invoke-WebRequest -Method POST "http://127.0.0.1:8000/process" `
    -Headers @{ "Content-Type" = "application/json" } `
    -Body '{"user_id":99,"timeout":5}' -ErrorAction Stop | Out-Null
  Write-Host "FAIL: expected non-2xx"; exit 1
} catch {
  $code = [int]$_.Exception.Response.StatusCode
  $body = $_.ErrorDetails.Message
  if (-not $body) {
    $reader = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
    $body = $reader.ReadToEnd()
  }
  if ($code -ne 422) { Write-Host "FAIL: expected 422 got $code"; exit 1 }
  if ($body -notmatch '"detail"') { Write-Host "FAIL: no detail in body"; exit 1 }
  Write-Host "PASS: /process invalid → 422 + detail"; exit 0
}
