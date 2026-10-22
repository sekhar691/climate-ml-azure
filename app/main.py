"""Demo model only: synthetic rain-risk classification, not real forecasts."""
import json
import logging
import os
import time
from contextlib import asynccontextmanager
from pathlib import Path

import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("climate-ml")
model = None

class ClimateFeatures(BaseModel):
    temperature_c: float = Field(ge=-80, le=70)
    humidity_pct: float = Field(ge=0, le=100)
    pressure_hpa: float = Field(ge=850, le=1100)
    wind_kmh: float = Field(ge=0, le=250)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global model
    model = joblib.load(Path(__file__).parent / "model.joblib")
    yield

app = FastAPI(title="Climate ML Demo", version="1.0.0", lifespan=lifespan)

@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": model is not None}

@app.post("/predict")
def predict(body: ClimateFeatures):
    start = time.perf_counter()
    if model is None:
        raise HTTPException(503, "Model not loaded")
    features = [[body.temperature_c, body.humidity_pct, body.pressure_hpa, body.wind_kmh]]
    rain_probability = float(model.predict_proba(features)[0][1])
    label = "rain" if rain_probability >= 0.5 else "no_rain"
    event = {"event": "prediction", "model_version": "synthetic-v1", "probability": round(rain_probability, 6), "prediction": label, "latency_ms": round((time.perf_counter()-start)*1000, 2)}
    logger.info(json.dumps(event))
    return {"prediction": label, "rain_probability": round(rain_probability, 4), "model_version": "synthetic-v1"}

@app.get("/keyvault-check")
def keyvault_check():
    """Optional identity smoke test. Never returns any secret value."""
    url = os.getenv("KEY_VAULT_URL")
    if not url:
        raise HTTPException(503, "KEY_VAULT_URL not configured")
    from azure.identity import DefaultAzureCredential
    from azure.keyvault.secrets import SecretClient
    try:
        credential = DefaultAzureCredential(
            managed_identity_client_id=os.getenv("AZURE_CLIENT_ID") or None
        )
        secret = SecretClient(vault_url=url, credential=credential).get_secret("demo-greeting")
        return {"keyvault_access": "ok", "secret_present": bool(secret.value)}
    except Exception:
        logger.exception("Key Vault access check failed")
        raise HTTPException(503, "Key Vault access check failed")
