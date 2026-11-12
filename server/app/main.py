from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.migrations import run_migrations
from app.routers import (
    accounts,
    analytics,
    auth,
    budgets,
    categories,
    goals,
    recurring,
    stipend,
    transactions,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create or update the tables to the newest version (see alembic/versions)
    run_migrations()
    yield


app = FastAPI(title="CashCompass API", version="0.1.0", lifespan=lifespan)

# Allow the Flutter web app (runs on localhost with a random port) to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(accounts.router)
app.include_router(categories.router)
app.include_router(transactions.router)
app.include_router(budgets.router)
app.include_router(analytics.router)
app.include_router(stipend.router)
app.include_router(recurring.router)
app.include_router(goals.router)

@app.get("/health")
def health():
    """Simple check that the server is running."""
    return {"status": "ok"}