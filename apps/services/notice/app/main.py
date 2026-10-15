from fastapi import FastAPI

app = FastAPI(title="PPS Tender notice Service", version="0.1.0")

@app.get("/healthz")
def healthcheck():
    return {"status": "ok", "service": "notice"}

@app.get("/api/notices")
def list_notices():
    # Explicit placeholder until Aurora schema and persistence layer are implemented.
    return []
