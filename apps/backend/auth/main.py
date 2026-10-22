
import os
import json
import hashlib
import secrets
from contextlib import asynccontextmanager

import redis.asyncio as redis
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from pwdlib import PasswordHash


REDIS_HOST = os.getenv("REDIS_HOST", "g2b-konep-redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
SESSION_TTL = 3600

password_hash = PasswordHash.recommended()
bearer = HTTPBearer()

r = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=os.getenv("REDIS_PASSWORD") or None,
    decode_responses=True,
    socket_connect_timeout=5,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await r.ping()
    yield
    await r.aclose()


app = FastAPI(
    title="G2B KONEP Auth API",
    version="1.0.0",
    lifespan=lifespan,
)


class UserCredentials(BaseModel):
    username: str = Field(
        min_length=3, max_length=50,
        pattern=r"^[a-zA-Z0-9_]+$"
    )
    password: str = Field(min_length=8, max_length=128)


def user_key(username: str):
    return f"auth:user:{username}"


def session_key(token: str):
    digest = hashlib.sha256(token.encode()).hexdigest()
    return f"auth:session:{digest}"


async def current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
):
    token = credentials.credentials
    username = await r.get(session_key(token))

    if username is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired session",
        )

    return username


@app.get("/health")
async def health():
    try:
        await r.ping()
    except redis.RedisError:
        raise HTTPException(503, "Redis unavailable")

    return {"status": "ok"}


@app.post("/api/auth/register", status_code=201)
async def register(payload: UserCredentials):
    key = user_key(payload.username)

    hashed = password_hash.hash(payload.password)

    created = await r.set(
        key,
        json.dumps({
            "username": payload.username,
            "password_hash": hashed,
        }),
        nx=True,
    )

    if not created:
        raise HTTPException(
            status_code=409,
            detail="Username already exists",
        )

    return {
        "message": "User registered",
        "username": payload.username,
    }


@app.post("/api/auth/login")
async def login(payload: UserCredentials):
    data = await r.get(user_key(payload.username))

    if data is None:
        raise HTTPException(401, "Invalid credentials")

    user = json.loads(data)

    if not password_hash.verify(
        payload.password,
        user["password_hash"],
    ):
        raise HTTPException(401, "Invalid credentials")

    token = secrets.token_urlsafe(32)

    await r.set(
        session_key(token),
        payload.username,
        ex=SESSION_TTL,
    )

    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in": SESSION_TTL,
    }


@app.get("/api/auth/me")
async def me(username: str = Depends(current_user)):
    return {
        "username": username,
        "authenticated": True,
    }


@app.post("/api/auth/logout")
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
    username: str = Depends(current_user),
):
    await r.delete(session_key(credentials.credentials))

    return {"message": "Logged out"}
