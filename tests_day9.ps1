$ErrorActionPreference = "Stop"

Write-Host "Test: /version should be 0.1.0"
try {
    $resp = Invoke-RestMethod http://127.0.0.1:8000/version
    if ($resp.version -eq "0.1.0") {
        Write-Host "PASS: /version = 0.1.0"
        exit 0
    } else {
        Write-Host ("FAIL: expected 0.1.0, got " + $resp.version)
        exit 1
    }
}
catch {
    Write-Host ("FAIL: request error -> " + $_.Exception.Message)
    exit 1
}
