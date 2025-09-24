import sys, json, subprocess
import logging
from pydantic import BaseModel, conint
from fastapi import FastAPI
from collections import defaultdict
import logging, sys
import uuid
from fastapi import Request
from fastapi.responses import JSONResponse
from uuid import uuid4
from fastapi import FastAPI, Request

timelog = logging.getLogger("timing")
timelog.setLevel(logging.INFO)
if not timelog.handlers:
    _h = logging.StreamHandler(sys.stdout)  # force stdout
    _h.setFormatter(logging.Formatter("%(message)s"))
    timelog.addHandler(_h)
    timelog.propagate = False
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
    force=True,
)
log = logging.getLogger()

def build_error_json(req_id: str, error_code: str, message: str | None = None) -> dict:
    data = {"status": "error", "req_id": req_id, "error_code": error_code}
    if message:
        data["message"] = message
    return data


app = FastAPI()

def _req_id(request: Request) -> str:
    return getattr(request.state, "req_id", request.headers.get("x-request-id", "")) or ""
    
@app.middleware("http")
async def request_id_middleware(request: Request, call_next):
    req_id = request.headers.get("X-Request-Id") or str(uuid.uuid4())
    request.state.req_id = req_id
    response = await call_next(request)
    response.headers["X-Request-Id"] = req_id
    return response

metrics = defaultdict(int)  # simple in-memory counters
from time import perf_counter

@app.middleware("http")
async def add_timing(request, call_next):
    t0 = perf_counter()
    resp = await call_next(request)
    dt_ms = (perf_counter() - t0) * 1000
    resp.headers["X-Process-Time-ms"] = f"{dt_ms:.2f}"
    req_id = getattr(request.state, "req_id", "-")
    timelog.info(f"{request.method} {request.url.path} {resp.status_code} {dt_ms:.2f}ms req_id={req_id}")
    metrics["_total"] += 1
    metrics[request.url.path] += 1
    return resp

@app.get("/health")
def health():
    log.info("health_check ok=true")
    return {"ok": True}

from datetime import datetime, timezone

@app.get("/ping")
def ping():
    return {"pong": True, "ts": datetime.now(timezone.utc).isoformat()}


class ProcessInput(BaseModel):
    user_id: conint(ge=1, le=10)
    timeout: conint(ge=1, le=30)

@app.post("/process")
def process(payload: ProcessInput, request: Request):
    # Prefer middleware’s req_id from state → header; only generate if truly missing
    req_id = _req_id(request) or str(uuid4())
    try:
        # DEV-ONLY trigger to test error shape
        if request.headers.get("X-Debug-Force-Error") == "1":
            raise RuntimeError("forced error for test")

        r = subprocess.run(
            [sys.executable, "app.py", "--user-id", str(payload.user_id), "--timeout", str(payload.timeout)],
            capture_output=True, text=True, check=False, timeout=payload.timeout
        )
        if r.returncode != 0:
            raise RuntimeError(f"engine nonzero exit={r.returncode}: {r.stderr.strip()}")
        out = r.stdout.strip()
        data = json.loads(out) if out.startswith("{") else {"stdout": out}
        result = {"status": "ok", "req_id": req_id, "data": data}
        log.info("process_out status=%s req_id=%s", result["status"], req_id)
        return result
    except subprocess.TimeoutExpired as e:
        code = "ENGINE_TIMEOUT"
        err = build_error_json(req_id, code, f"engine timed out after {e.timeout}s")
        log.error("process_error error_code=%s req_id=%s msg=%s", code, req_id, str(e))
        err["req_id"] = req_id
        return JSONResponse(status_code=500, content=err)
    except ValueError as e:
        code = "ENGINE_BAD_OUTPUT"
        err = build_error_json(req_id, code, str(e))
        log.error("process_error error_code=%s req_id=%s msg=%s", code, req_id, str(e))
        err["req_id"] = req_id
        return JSONResponse(status_code=500, content=err)
    except RuntimeError as e:
        code = "ENGINE_NONZERO_EXIT"
        err = build_error_json(req_id, code, str(e))
        log.error("process_error error_code=%s req_id=%s msg=%s", code, req_id, str(e))
        err["req_id"] = req_id
        return JSONResponse(status_code=500, content=err)
    except Exception as e:
        code = "ENGINE_FAIL"
        err = build_error_json(req_id, code, str(e))
        log.error("process_error error_code=%s req_id=%s msg=%s", code, req_id, str(e))
        err["req_id"] = req_id
        return JSONResponse(status_code=500, content=err)




APP_VERSION = "0.1.0"

@app.get("/version")
def version():
    return {"version": APP_VERSION}
# --- metrics endpoint (explicit, safe placement) ---
from typing import Dict
try:
    metrics  # ensure counters exist if already defined
except NameError:
    from collections import defaultdict
    metrics = defaultdict(int)

@app.get("/metrics")
def metrics_endpoint() -> dict:
    return {"counts": dict(metrics)}
