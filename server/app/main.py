from fastapi import FastAPI

app = FastAPI(title="CashCompass API", version="0.1.0")


@app.get("/health")
def health():
    """Simple check that the server is running."""
    return {"status": "ok"}