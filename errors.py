from typing import Any, Dict, Optional

ERROR_CODES = {
    "ENGINE_TIMEOUT": "Request to engine timed out",
    "ENGINE_BAD_OUTPUT": "Engine returned invalid JSON",
    "ENGINE_NONZERO_EXIT": "Engine exited with non-zero status",
    "ENGINE_FAIL": "Unhandled engine failure",
}

def build_error_json(req_id: str, code: str, message: str, detail: Optional[Any] = None) -> Dict[str, Any]:
    return {"status": "error", "error": {"error_code": code, "message": message, "detail": detail, "req_id": req_id}}
