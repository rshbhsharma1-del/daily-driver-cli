import sys, json, subprocess

from pydantic import BaseModel, conint

from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"ok": True}
class ProcessInput(BaseModel):
    user_id: conint(ge=1, le=10)
    timeout: conint(ge=1, le=30)

@app.post("/process")
def process(payload: ProcessInput):
    try:
        r = subprocess.run([sys.executable, "app.py", str(payload.user_id)],
                           capture_output=True, text=True, check=False)
        out = r.stdout.strip()
        data = json.loads(out) if out.startswith("{") else {"stdout": out}
        return {"status": "ok", "data": data}
    except Exception as e:
        return {"status": "error", "error": str(e)}

