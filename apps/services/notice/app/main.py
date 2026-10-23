"""G2B KONEP Notice API — in-memory development implementation.

Data, version checks, and audit logs are local to one process.
This implementation does not provide production persistence or authentication.
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

from fastapi import FastAPI, HTTPException, Query, Response, status
from pydantic import BaseModel, Field, field_validator


app = FastAPI(
    title="G2B KONEP Notice API",
    version="1.0.0",
)

lock = RLock()
notices: dict[int, dict] = {}
audit_logs: list[dict] = []
next_id = 1


# ============================================================
# Models
# ============================================================

class NoticeStatus(str, Enum):
    DRAFT = "DRAFT"
    PUBLISHED = "PUBLISHED"
    CLOSED = "CLOSED"
    CANCELLED = "CANCELLED"


class NoticeCreate(BaseModel):
    organization_id: int = Field(gt=0)
    title: str = Field(min_length=1, max_length=300)
    amount_decimal: Decimal = Field(
        ge=0,
        max_digits=18,
        decimal_places=2,
    )

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Title must not be blank")
        return value


class NoticeUpdate(BaseModel):
    version: int = Field(ge=1)
    title: Optional[str] = Field(
        default=None,
        min_length=1,
        max_length=300,
    )
    amount_decimal: Optional[Decimal] = Field(
        default=None,
        ge=0,
        max_digits=18,
        decimal_places=2,
    )

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None

        value = value.strip()
        if not value:
            raise ValueError("Title must not be blank")
        return value


class TransitionRequest(BaseModel):
    version: int = Field(ge=1)
    actor: str = Field(min_length=1, max_length=100)

    @field_validator("actor")
    @classmethod
    def actor_not_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Actor must not be blank")
        return value


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


class AuditOut(BaseModel):
    notice_id: int
    action: str
    actor: str
    from_status: Optional[NoticeStatus] = None
    to_status: Optional[NoticeStatus] = None
    version: int
    timestamp: str


# ============================================================
# Helpers — call memory helpers while holding lock
# ============================================================

def get_notice_or_404(notice_id: int) -> dict:
    notice = notices.get(notice_id)
    if notice is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notice not found",
        )
    return notice


def check_version(notice: dict, version: int) -> None:
    if notice["version"] != version:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Version conflict. Fetch the latest notice and retry.",
        )


def append_audit(
    notice: dict,
    action: str,
    actor: str,
    from_status: Optional[NoticeStatus] = None,
    to_status: Optional[NoticeStatus] = None,
) -> None:
    audit_logs.append(
        {
            "notice_id": notice["id"],
            "action": action,
            "actor": actor,
            "from_status": from_status,
            "to_status": to_status,
            "version": notice["version"],
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )


def verify_organization(organization_id: int) -> None:
    base = os.environ.get(
        "ORGANIZATION_SERVICE_URL", ""
    ).strip().rstrip("/")

    if not base:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="ORGANIZATION_SERVICE_URL is not configured",
        )

    request = Request(
        f"{base}/api/organizations/{organization_id}",
        headers={"Accept": "application/json"},
    )

    try:
        with urlopen(request, timeout=3) as response:
            data = json.load(response)
    except HTTPError as exc:
        if exc.code == 404:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Organization does not exist",
            ) from exc

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Organization service returned an error",
        ) from exc
    except (URLError, TimeoutError, OSError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Organization service unavailable",
        ) from exc

    if not isinstance(data, dict):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Organization service returned an invalid response",
        )

    if data.get("status") != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Organization is not active",
        )


def transition_notice(
    notice_id: int,
    payload: TransitionRequest,
    target: NoticeStatus,
) -> NoticeOut:
    allowed = {
        NoticeStatus.DRAFT: {
            NoticeStatus.PUBLISHED,
            NoticeStatus.CANCELLED,
        },
        NoticeStatus.PUBLISHED: {
            NoticeStatus.CLOSED,
            NoticeStatus.CANCELLED,
        },
        NoticeStatus.CLOSED: set(),
        NoticeStatus.CANCELLED: set(),
    }

    with lock:
        notice = get_notice_or_404(notice_id)
        check_version(notice, payload.version)

        current = notice["status"]
        if target not in allowed[current]:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    f"Cannot transition from {current.value} "
                    f"to {target.value}"
                ),
            )

        notice["status"] = target
        notice["version"] += 1

        append_audit(
            notice,
            action=target.value,
            actor=payload.actor,
            from_status=current,
            to_status=target,
        )

        return NoticeOut(**notice)


# ============================================================
# Health checks
# ============================================================

@app.get("/health", include_in_schema=False)
@app.get("/healthz", include_in_schema=False)
def health():
    return {"status": "ok"}


# ============================================================
# Notice CRUD
# ============================================================

@app.get("/api/notices", response_model=NoticeList)
def list_notices(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    organization_id: Optional[int] = Query(default=None, gt=0),
    notice_status: Optional[NoticeStatus] = Query(
        default=None,
        alias="status",
    ),
):
    with lock:
        records = sorted(
            notices.values(),
            key=lambda item: item["id"],
        )

        if organization_id is not None:
            records = [
                item for item in records
                if item["organization_id"] == organization_id
            ]

        if notice_status is not None:
            records = [
                item for item in records
                if item["status"] == notice_status
            ]

        return NoticeList(
            items=[
                NoticeOut(**item)
                for item in records[offset:offset + limit]
            ],
            total=len(records),
            limit=limit,
            offset=offset,
        )


@app.get("/api/notices/{notice_id}", response_model=NoticeOut)
def get_notice(notice_id: int):
    with lock:
        return NoticeOut(**get_notice_or_404(notice_id))


@app.post(
    "/api/notices",
    response_model=NoticeOut,
    status_code=status.HTTP_201_CREATED,
)
def create_notice(payload: NoticeCreate):
    global next_id

    # External HTTP request runs outside the memory lock.
    verify_organization(payload.organization_id)

    with lock:
        notice = {
            "id": next_id,
            "organization_id": payload.organization_id,
            "title": payload.title,
            "status": NoticeStatus.DRAFT,
            "amount_decimal": format(payload.amount_decimal, ".2f"),
            "version": 1,
        }

        notices[next_id] = notice
        next_id += 1

        append_audit(
            notice,
            action="CREATE",
            actor="development",
            to_status=NoticeStatus.DRAFT,
        )

        return NoticeOut(**notice)


@app.patch("/api/notices/{notice_id}", response_model=NoticeOut)
def update_notice(notice_id: int, payload: NoticeUpdate):
    if payload.title is None and payload.amount_decimal is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Provide title or amount_decimal",
        )

    with lock:
        notice = get_notice_or_404(notice_id)
        check_version(notice, payload.version)

        if notice["status"] != NoticeStatus.DRAFT:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Only DRAFT notices can be updated",
            )

        if payload.title is not None:
            notice["title"] = payload.title

        if payload.amount_decimal is not None:
            notice["amount_decimal"] = format(
                payload.amount_decimal, ".2f"
            )

        notice["version"] += 1

        append_audit(
            notice,
            action="UPDATE",
            actor="development",
        )

        return NoticeOut(**notice)


@app.delete(
    "/api/notices/{notice_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_notice(
    notice_id: int,
    version: int = Query(ge=1),
):
    with lock:
        notice = get_notice_or_404(notice_id)
        check_version(notice, version)

        if notice["status"] != NoticeStatus.DRAFT:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Only DRAFT notices can be deleted",
            )

        append_audit(
            notice,
            action="DELETE",
            actor="development",
            from_status=notice["status"],
        )

        del notices[notice_id]

    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ============================================================
# Status transitions
# ============================================================

@app.post(
    "/api/notices/{notice_id}/publish",
    response_model=NoticeOut,
)
def publish_notice(notice_id: int, payload: TransitionRequest):
    return transition_notice(
        notice_id, payload, NoticeStatus.PUBLISHED
    )


@app.post(
    "/api/notices/{notice_id}/close",
    response_model=NoticeOut,
)
def close_notice(notice_id: int, payload: TransitionRequest):
    return transition_notice(
        notice_id, payload, NoticeStatus.CLOSED
    )


@app.post(
    "/api/notices/{notice_id}/cancel",
    response_model=NoticeOut,
)
def cancel_notice(notice_id: int, payload: TransitionRequest):
    return transition_notice(
        notice_id, payload, NoticeStatus.CANCELLED
    )


# ============================================================
# Audit logs — development only, no authentication
# ============================================================

@app.get(
    "/api/notices/{notice_id}/audit",
    response_model=list[AuditOut],
)
def get_notice_audit(notice_id: int):
    with lock:
        records = [
            AuditOut(**entry)
            for entry in audit_logs
            if entry["notice_id"] == notice_id
        ]

        if not records and notice_id not in notices:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notice not found",
            )

        return records
