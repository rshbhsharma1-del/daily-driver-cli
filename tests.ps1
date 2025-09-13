Write-Host "Running CLI validation tests..."

# Good case → expect 0
python cli.py fetch --user-id 3 --timeout 10 --out out/test-good.json
Write-Host "Good case exit code: $LASTEXITCODE"

# Bad user-id → expect 2
python cli.py fetch --user-id 11 --timeout 10 --out out/test-bad1.json
Write-Host "Bad user-id exit code: $LASTEXITCODE"

# Bad timeout → expect 2
python cli.py fetch --user-id 3 --timeout 40 --out out/test-bad2.json
Write-Host "Bad timeout exit code: $LASTEXITCODE"
exit 0
