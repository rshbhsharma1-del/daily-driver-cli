$okBody = @{ user_id = 1; timeout = 5 } | ConvertTo-Json
$res = Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/process -Body $okBody -ContentType 'application/json'
if ($res.status -ne 'ok') { Write-Error "Expected status=ok. Got: $($res | ConvertTo-Json -Depth 5)"; exit 1 }
"PASS: good request"
