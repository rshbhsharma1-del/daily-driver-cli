## Day 3 — HTTP fetch + JSON/CSV

- Run direct:  
  `python app.py --url ... --timeout N --format [json|csv] --out out/file`

- Run via CLI:  
  `python cli.py fetch --url ... --timeout N --format [json|csv] --out out/file`

- Success: prints log to **stderr** like `[log] url=… status=200 count=N`,  
  writes the file, and exits `0`.

- Failure: prints `HTTP <code>` message, exits `1`.
## Day 4 – CLI flags & exits
- New: `--user-id` (positive int) and `--timeout` (seconds, default **10**).
- Success: `python cli.py fetch --user-id 3 --out out/u3.json` → exit **0**.
- Input error: `--user-id -5` → prints error to **stderr** → exit **2**.
- HTTP error: `--url https://httpstat.us/404` → prints error → exit **1**.
- Default URL is `https://jsonplaceholder.typicode.com/todos` so filtering works.
## Day 5 – Argument Validation

- New strict checks:
  - `--user-id` must be an integer **1–10**
  - `--timeout` must be a positive integer **≤30**
- Invalid inputs → clear error to **stderr** and exit **2**.
- Success path (exit **0**) and HTTP error path (exit **1**) unchanged.

**PowerShell tip:** `echo $?` only shows True/False. Use **`$LASTEXITCODE`** to see numeric exit codes.

### Demo (copy–paste)

# Good → exit 0
python cli.py fetch --user-id 3 --timeout 10 --out out/data.json
$LASTEXITCODE

# Bad user-id → exit 2
python cli.py fetch --user-id 11 --timeout 10 --out out/data.json
$LASTEXITCODE

# Bad timeout → exit 2
python cli.py fetch --user-id 3 --timeout 40 --out out/data.json
$LASTEXITCODE
## Run (FastAPI) + Logging

# Start API (venv required)
cd C:\Users\rshbh\daily-driver-cli
.\.venv\Scripts\Activate.ps1
python -m uvicorn main:app --reload

# Smoke tests (new window)
curl http://127.0.0.1:8000/health
curl -Method POST "http://127.0.0.1:8000/process" `
  -Headers @{ "Content-Type" = "application/json" } `
  -Body '{"user_id":1,"timeout":5}'

# Expected logs in server window
# INFO health_check ok=true
# INFO process_in user_id=1 timeout=5
# INFO process_out status=ok
## Day 9 - /version & test

Run (dev server):
.\.venv\Scripts\Activate.ps1
python -m uvicorn main:app --reload

Checks:
curl http://127.0.0.1:8000/version
powershell -File .\tests_day9.ps1
$LASTEXITCODE   # expect 0
## Day 10 – Request Timing (X-Process-Time-ms)

Run:
1) .\.venv\Scripts\Activate.ps1
2) python -m uvicorn main:app --reload

Test:
3) (Invoke-WebRequest http://127.0.0.1:8000/health).Headers["X-Process-Time-ms"]
4) Set-ExecutionPolicy -Scope Process Bypass; powershell -File .\tests_day10.ps1
## Day 10 – /ping (UTC timestamp)

Run:
1) .\.venv\Scripts\Activate.ps1
2) python -m uvicorn main:app --reload

Test:
3) curl http://127.0.0.1:8000/ping
4) Set-ExecutionPolicy -Scope Process Bypass; powershell -File .\tests_day10_ping.ps1
## Day 11 – Timing Log + Negative Test

**What:** Compact per-request timing line (`METHOD PATH STATUS MS`) via timing logger; negative test for /process invalid input (expects 422 + "detail").

**Run API:**
python -m uvicorn main:app --reload --log-level info

**Smoke:**
curl http://127.0.0.1:8000/ping

**Tests:**
.\tests_day10.ps1
.\tests_day10_ping.ps1
.\tests_day11_negative.ps1
### Day 11 – /metrics (basic counters)

Run:
python -m uvicorn main:app --reload --log-level info

Check:
curl http://127.0.0.1:8000/metrics
# expect: {"counts":{ "_total":N, "/metrics":M, ... }}

Tests:
.\tests_day11_metrics.ps1
## Docker — local build & run (Windows)

Prereqs
- Docker Desktop (WSL 2 backend) with Ubuntu enabled.
- App listens on port 8000 inside the container.

Build
docker build -t daily-driver:dev .

Run
docker run --rm -p 8000:8000 daily-driver:dev

Smoke tests (PowerShell)
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/ping
Invoke-RestMethod http://127.0.0.1:8000/version
Invoke-RestMethod http://127.0.0.1:8000/metrics

Troubleshooting (from today)
- If 'docker' is not recognized, install Docker Desktop and enable WSL 2 integration for Ubuntu.
- If 'Windows Features' is empty or DISM shows 'Error 87 (option unknown)', repair Windows via In-Place Upgrade (keep files & apps), then retry WSL/Docker setup.
## Error Shapes

Successful `/process` (unchanged):
```json
{ "status": "ok", "data": { "...": "..." } }
```
Runtime errors (not FastAPI 422 validation):
```json
{ "status": "error", "req_id": "<uuid>", "error_code": "ENGINE_FAIL", "message": "…optional…" }
```
### Day 15 — Request ID in `/process` responses

**Success**
```json
{"status":"ok","req_id":"<uuid>","data":{"stdout":"..."}}
```

**Error**
```json
{"status":"error","req_id":"<uuid>","error_code":"ENGINE_TIMEOUT|ENGINE_BAD_OUTPUT|ENGINE_NONZERO_EXIT|ENGINE_FAIL","message":"..."}
```

**Trace by req_id (PowerShell)**
```powershell
# Start server and tee logs to a file
python -m uvicorn main:app --reload *| Tee-Object -FilePath .\server.log

# Send with a known X-Request-Id
$rid=[guid]::NewGuid().ToString()
$h=@{'Content-Type'='application/json';'X-Request-Id'=$rid}
'{"user_id":1,"timeout":5}' | Set-Content -NoNewline tmp_post.json
irm http://127.0.0.1:8000/process -Method Post -Headers $h -InFile tmp_post.json

# Grep logs for this request
Select-String -Path .\server.log -Pattern $rid
```
### Day 16 – Test Error Codes
Deterministic dev-only triggers via `X-Dev-Force`:
- `ENGINE_TIMEOUT` → `.\tests_day16_timeout.ps1`
- `ENGINE_BAD_OUTPUT` → `.\tests_day16_bad_output.ps1`
- `ENGINE_NONZERO_EXIT` → `.\tests_day16_nonzero_exit.ps1`
- `ENGINE_FAIL` → `.\tests_day16_engine_fail.ps1`

Each script asserts:
- `status: "error"`
- top-level `error_code` matches the forced value
- `req_id` in the response **body** matches `X-Request-Id` in **headers** (server-generated)

Troubleshooting: see `TROUBLESHOOTING.md` (use `curl.exe`, write JSON to a temp file, and run Uvicorn from repo root).
## Error handling (central helper)

- All error codes + JSON builder live in `errors.py`.
- Import in handlers: `from errors import build_error_json, ERROR_CODES`.
- Forced error testing (dev-only): send header `X-Dev-Force: <ENGINE_* code>` to `/process`.
