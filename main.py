import sys, json, subprocess
import logging
from pydantic import BaseModel, conint
from fastapi import FastAPI

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
    force=True,
)
log = logging.getLogger()

app = FastAPI()

@app.get("/health")
def health():
    log.info("health_check ok=true")
    return {"ok": True}



class ProcessInput(BaseModel):
    user_id: conint(ge=1, le=10)
    timeout: conint(ge=1, le=30)

@app.post("/process")
def process(payload: ProcessInput):
    log.info("process_in user_id=%s timeout=%s", payload.user_id, payload.timeout)
    try:
        r = subprocess.run([sys.executable, "app.py", str(payload.user_id)],
                           capture_output=True, text=True, check=False)
        out = r.stdout.strip()
        data = json.loads(out) if out.startswith("{") else {"stdout": out}
        result = {"status": "ok", "data": data}
    except Exception as e:
        result = {"status": "error", "error": str(e)}
    log.info("process_out status=%s", result["status"])
    return result


APP_VERSION = "0.1.0"

@app.get("/version")
def version():
    return {"version": APP_VERSION}
