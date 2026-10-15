from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_healthz():
    result = client.get("/healthz")
    assert result.status_code == 200
    assert result.json()["status"] == "ok"

def test_initial_list():
    result = client.get("/api/notices")
    assert result.status_code == 200
    assert result.json() == []
