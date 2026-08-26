from fastapi import FastAPI

app = FastAPI(title="SpecCheck")

@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "speccheck"}
