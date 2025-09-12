import sys,json,requests,argparse,csv; from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument("--url", default="https://jsonplaceholder.typicode.com/todos")
p.add_argument("--timeout", type=int, default=10)
p.add_argument("--out", default="out/data.json")
p.add_argument("--format", choices=["json","csv"], default="json")
p.add_argument("--user-id", type=int, help="User ID filter (positive int)")
a=p.parse_args()
final_url=a.url
if a.user_id is not None:
    final_url = a.url + ("&" if "?" in a.url else "?") + f"userId={a.user_id}"
r=requests.get(final_url,timeout=a.timeout)
# log first (stderr): url, status, count (1 for object; N for list)
try: payload=r.json()
except Exception: payload=None
count=len(payload) if isinstance(payload,list) else (1 if payload else 0)
print(f"[log] url={final_url} status={r.status_code} count={count}", file=sys.stderr)
if r.status_code!=200: print(f"HTTP {r.status_code} from {final_url}", file=sys.stderr); sys.exit(1)
d=payload; Path(a.out).parent.mkdir(parents=True,exist_ok=True)
if a.format=="json": open(a.out,"w",encoding="utf-8").write(json.dumps(d,ensure_ascii=False,indent=2)); print(json.dumps(d,ensure_ascii=False)); sys.exit(0)
rows=d if isinstance(d,list) else [d]; cols=sorted({k for x in rows for k in x}); f=open(a.out,"w",newline="",encoding="utf-8"); w=csv.DictWriter(f,fieldnames=cols); w.writeheader(); w.writerows(rows); f.close(); print(f"Wrote {len(rows)} rows to {a.out}")
