# CashCompass

Budget analytics app for students: all money (cash and cards) in one place,
spending analytics and a daily allowance until the next stipend.

## Stack
- Mobile: Flutter, Bloc
- Server: FastAPI (Python)
- CI: GitHub Actions

## Run the server
    cd server
    python -m venv .venv
    .venv\Scripts\python.exe -m pip install -r requirements.txt
    .venv\Scripts\python.exe -m uvicorn app.main:app --reload

API docs: http://127.0.0.1:8000/docs

## Run the app
    cd mobile
    flutter pub get
    flutter run

## Course requirements
| Requirement | Status |
|---|---|
| Flutter cross-platform app | in progress |
| Mobile communicates with server | in progress |
| Pushed on GitHub | done |
| Bloc state management | in progress |