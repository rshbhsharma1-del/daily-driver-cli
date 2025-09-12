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
