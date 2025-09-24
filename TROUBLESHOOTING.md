# TROUBLESHOOTING (Local Dev Tips)

## Start the API (always from repo root)

```powershell
cd C:\Users\rshbh\daily-driver-cli
.\.venv\Scripts\Activate.ps1
python -m uvicorn main:app --reload
```

## Use the real curl on Windows

PowerShell aliases `curl` to Invoke-WebRequest. Use `curl.exe` for reliable behavior.

```powershell
curl.exe http://127.0.0.1:8000/ping
```

## POST JSON reliably (avoid 422 from bad quoting)

Put JSON in a file and send with --data-binary.

```powershell
Set-Content tmp_post.json '{"user_id":1,"timeout":5}'
curl.exe -X POST "http://127.0.0.1:8000/process" `
  -H "Content-Type: application/json" `
  --data-binary "@tmp_post.json"
```

## Force a runtime error (dev-only) to test error shape

```powershell
Set-Content tmp_post.json '{"user_id":1,"timeout":5}'
curl.exe -X POST "http://127.0.0.1:8000/process" `
  -H "Content-Type: application/json" `
  -H "X-Debug-Force-Error: 1" `
  --data-binary "@tmp_post.json"
```

## Know the difference: 422 vs 500

- **422 Unprocessable Entity** = Pydantic validation failed (your JSON/body/values are wrong). You did **not** hit runtime code.
- **500 Internal Server Error** = your handler ran and failed (this is the runtime error path your tests target).

## Tracing (X-Request-Id)

Every request gets/returns `X-Request-Id`. Include it in bug reports and use it to locate logs.  
Example: `req_id=8b8a…` appears in response header and access/timing log.

## Quick grep by request id (Windows)

If you capture logs to a file:

```powershell
Get-Content .\uvicorn.log | Select-String "req_id=8b8a"
```

## Common PowerShell pitfalls

- Stuck blue prompt = unterminated here-string (`@'` … `@`). Press Ctrl+C or edit in VS Code.
- `curl : Cannot find drive 'http'` → you used the alias; switch to `curl.exe`.
- `Invoke-WebRequest` hides bodies on non-2xx → use `curl.exe` and write body to file if needed.

## Uvicorn import errors

- “Could not import module 'main'” → start from project root and verify indentation/scope in `main.py`.

```powershell
python -m uvicorn main:app --reload
```

## Temp files to ignore (Git)

Add these to `.gitignore` to keep status clean:

```
tmp_*.json
tmp_code.txt
```

