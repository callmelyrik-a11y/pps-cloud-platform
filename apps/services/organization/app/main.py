"""G2B KONEP organization API — in-memory development implementation.
Data is per-process, not shared across replicas. Replace with Aurora persistence before multi-replica use.
"""
from enum import Enum
from threading import RLock
from typing import Optional

from fastapi import FastAPI, HTTPException, Query, status
from pydantic import BaseModel, Field

app = FastAPI(title="G2B KONEP Organization API", version="1.0.0")
lock = RLock()
organizations: dict[int, dict] = {}
next_id = 1


class OrganizationStatus(str, Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


class OrganizationCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    status: OrganizationStatus = OrganizationStatus.ACTIVE


class OrganizationOut(BaseModel):
    id: int
    name: str
    status: OrganizationStatus
    version: int


class OrganizationList(BaseModel):
    items: list[OrganizationOut]
    total: int
    limit: int
    offset: int


@app.get("/healthz")
def healthcheck():
    return {"status": "ok", "service": "organization"}


@app.get("/api/organizations", response_model=OrganizationList)
def list_organizations(
    status_filter: Optional[OrganizationStatus] = Query(default=None, alias="status"),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    with lock:
        rows = sorted(organizations.values(), key=lambda row: row["id"])
        if status_filter is not None:
            rows = [row for row in rows if row["status"] == status_filter]
        return {"items": rows[offset:offset + limit], "total": len(rows), "limit": limit, "offset": offset}


@app.get("/api/organizations/{organization_id}", response_model=OrganizationOut)
def get_organization(organization_id: int):
    with lock:
        row = organizations.get(organization_id)

        if row is None:
            raise HTTPException(
                status_code=404,
                detail="Organization not found"
            )

        return row.copy()


@app.post("/api/organizations", response_model=OrganizationOut, status_code=status.HTTP_201_CREATED)
def create_organization(payload: OrganizationCreate):
    global next_id
    with lock:
        row = {"id": next_id, "name": payload.name.strip(), "status": payload.status, "version": 1}
        if not row["name"]:
            raise HTTPException(status_code=422, detail="Organization name must not be blank")
        organizations[next_id] = row
        next_id += 1
        return row.copy()
        
@app.get("/api/organizations/test-json")
def test_json():
    return {
        "success": True,
        "message": "G2B KONEP Organization API 정상 응답",
        "service": "organization",
        "data": {
            "id": 1,
            "organization_name": "조달청 본청",
            "status": "ACTIVE",
            "environment": "dev"
        }
    }

@app.get("/api/test")
def test_json():
    return {
        "success": True,
        "message": "G2B KONEP API 정상 응답",
        "service": "organization",
        "data": {
            "id": 1,
            "organization_name": "조달청 본청",
            "status": "ACTIVE",
            "environment": "dev"
        }
    }