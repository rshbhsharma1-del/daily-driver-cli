import argparse, sys, subprocess
p=argparse.ArgumentParser(prog="cli"); p.add_argument("--version", action="version", version="cli 0.1"); sp=p.add_subparsers()
g=sp.add_parser("greet"); g.add_argument("--name", required=True); g.set_defaults(func=lambda a: print(f"Hello, {a.name}!"))
s=sp.add_parser("sum"); s.add_argument("a", type=int); s.add_argument("b", type=int); s.set_defaults(func=lambda a: print(a.a+a.b))
f=sp.add_parser("fetch", help="HTTP fetch → JSON/CSV"); f.add_argument("--url", default="https://jsonplaceholder.typicode.com/todos"); f.add_argument("--timeout", type=int, default=10); f.add_argument("--out", default="out/data.json"); f.add_argument("--format", choices=["json","csv"], default="json"); f.add_argument("--user-id", type=int, help="User ID filter (positive int)")
def run_fetch(a):
    if a.user_id is not None and a.user_id <= 0:
        print("error: --user-id must be a positive integer", file=sys.stderr); sys.exit(2)
    if a.timeout <= 0:
        print("error: --timeout must be > 0 seconds", file=sys.stderr); sys.exit(2)
    cmd = [sys.executable, "app.py",
           "--url", a.url,
           "--timeout", str(a.timeout),
           "--out", a.out,
           "--format", a.format]
    if a.user_id is not None:
        cmd += ["--user-id", str(a.user_id)]
    return sys.exit(subprocess.call(cmd))

f.set_defaults(func=run_fetch)
args=p.parse_args()
if getattr(args,"cmd",None)=="fetch":
    if args.user_id is not None and args.user_id <= 0:
        print("error: --user-id must be a positive integer", file=sys.stderr); sys.exit(2)
    if args.timeout <= 0:
        print("error: --timeout must be > 0 seconds", file=sys.stderr); sys.exit(2)
args.func(args) if hasattr(args,"func") else p.print_help()



