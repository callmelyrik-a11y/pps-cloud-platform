"""G2B KONEP notice API — in-memory development implementation.
Not production persistence: data, version checks and audit are local to one process.
"""
import json
import os
from datetime import datetime, timezone
from decimal import Decimal
from enum import Enum
from threading import RLock
from typing import Optional
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from fastapi import FastAPI, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator

app = FastAPI(title="G2B KONEP Notice API", version="1.0.0")
lock = RLock()
notices: dict[int, dict] = {}
audit_logs: list[dict] = []
next_id = 1

@app.get("/health", include_in_schema=False)
def health():
    return {"status": "ok"}


class NoticeStatus(str, Enum):
    DRAFT = "DRAFT"
    PUBLISHED = "PUBLISHED"
    CLOSED = "CLOSED"
    CANCELLED = "CANCELLED"


class NoticeCreate(BaseModel):
    organization_id: int = Field(gt=0)
    title: str = Field(min_length=1, max_length=300)
    amount_decimal: Decimal = Field(ge=0, max_digits=18, decimal_places=2)

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Title must not be blank")
        return value


class NoticeUpdate(BaseModel):
    version: int = Field(ge=1)
    title: Optional[str] = Field(default=None, min_length=1, max_length=300)
    amount_decimal: Optional[Decimal] = Field(default=None, ge=0, max_digits=18, decimal_places=2)

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, value: Optional[str]) -> Optional[str]:
        if value is not None and not value.strip():
            raise ValueError("Title must not be blank")
        return value.strip() if value is not None else value


class TransitionRequest(BaseModel):
    version: int = Field(ge=1)
    actor: str = Field(min_length=1, max_length=100)


class NoticeOut(BaseModel):
    id: int
    organization_id: int
    title: str
    status: NoticeStatus
    amount_decimal: str
    version: int


class NoticeList(BaseModel):
    items: list[NoticeOut]
    total: int
    limit: int
    offset: int


def verify_organization(organization_id: int) -> None:
    base = os.environ.get("ORGANIZATION_SERVICE_URL", "").rstrip("/")
    if not base:
        raise HTTPException(status_code=503, detail="ORGANIZATION_SERVICE_URL is not configured")
    request = Request(f"{base}/api/organizations/{organization_id}", headers={"Accept": "application/json"})
    try:
        with urlopen(request, timeout=3) as response:
            data = json.load(response)
    except HTTPError as exc:
        if exc.code == 404:
            raise HTTPException(status_code=422, detail="Organization does not exist") from exc
        raise HTTPException(status_code=503, detail="Organization service returned an error") from exc
    except (URLError, TimeoutError, ValueError) as exc:
        raise HTTPException(status_code=503, detail="Organization service unavailable") from exc
    if data.get("status") != "ACTIVE":
        raise HTTPException(status_code=422, detail="Organization is not active")

