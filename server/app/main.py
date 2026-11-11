from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.database import Base, engine
from app.routers import auth


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup (Alembic migrations will replace this later)
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="CashCompass API", version="0.1.0", lifespan=lifespan)
app.include_router(auth.router)


@app.get("/health")
def health():
    """Simple check that the server is running."""
    return {"status": "ok"}