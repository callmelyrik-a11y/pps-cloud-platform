from fastapi import FastAPI

app = FastAPI(title="PPS Organization Service", version="0.1.0")

@app.get("/healthz")
def healthcheck():
    return {"status": "ok", "service": "organization"}

@app.get("/api/organizations")
def list_organizations():
    # Explicit placeholder until Aurora schema and persistence layer are implemented.
    return []
