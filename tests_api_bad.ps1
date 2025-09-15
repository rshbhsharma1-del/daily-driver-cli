$badBody = @{ user_id = 99; timeout = 5 } | ConvertTo-Json
try {
    $res = Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/process -Body $badBody -ContentType 'application/json'
    Write-Error "Expected validation error, but got: $($res | ConvertTo-Json -Depth 5)"
    exit 1
} catch {
    "PASS: bad request produced error as expected"
}
