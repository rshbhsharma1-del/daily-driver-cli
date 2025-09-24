$uri = "http://127.0.0.1:8000/process"

# Ensure a clean JSON body file for the POST
$payloadPath = Join-Path $PWD "tmp_post.json"
'{"user_id":1,"timeout":5}' | Set-Content -NoNewline -Encoding ASCII $payloadPath

$bodyPath = Join-Path $PWD "tmp_body.json"
$codePath = Join-Path $PWD "tmp_code.txt"
Remove-Item -ErrorAction SilentlyContinue $bodyPath, $codePath

# Use curl.exe; capture body + status code separately
& curl.exe -s -o $bodyPath -w "%{http_code}" -H "X-Debug-Force-Error: 1" -H "Content-Type: application/json" `
  -X POST --data-binary "@$payloadPath" $uri | Out-File -Encoding ascii $codePath

$code = [int](Get-Content -Raw $codePath).Trim()
$jsonText = Get-Content -Raw $bodyPath

try { $json = $jsonText | ConvertFrom-Json } catch { Write-Error "invalid JSON: $jsonText"; exit 1 }

if ($code -ne 500)            { Write-Error ("Expected 500 got {0}" -f $code); exit 1 }
if ($json.status -ne "error") { Write-Error ("status != error. body: {0}" -f $jsonText); exit 1 }
if (-not $json.req_id)        { Write-Error "missing req_id"; exit 1 }
if (-not $json.error_code)    { Write-Error "missing error_code"; exit 1 }

"PASS: error shape ok; code=$code status=$($json.status) req_id=$($json.req_id) error_code=$($json.error_code)"
exit 0
