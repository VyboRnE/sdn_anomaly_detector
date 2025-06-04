from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Tuple
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import os
import joblib
import atexit
import asyncio

app = FastAPI()

MODEL_DIR = "models"
os.makedirs(MODEL_DIR, exist_ok=True)

user_models: Dict[str, IsolationForest] = {}
user_scalers: Dict[str, StandardScaler] = {}
user_buffers: Dict[str, List[List[float]]] = {}
user_cusums: Dict[str, 'CusumDetector'] = {}

MIN_TRAIN_SIZE = 100

class CusumDetector:
    def __init__(self, threshold: float, drift: float = 0.0):
        self.threshold = threshold
        self.drift = drift
        self.pos_sum = 0.0
        self.neg_sum = 0.0
        self.last_mean = None

    def update(self, value: float) -> bool:
        if self.last_mean is None:
            self.last_mean = value
            return False

        diff = value - self.last_mean - self.drift
        self.pos_sum = max(0, self.pos_sum + diff)
        self.neg_sum = min(0, self.neg_sum + diff)

        if self.pos_sum > self.threshold or abs(self.neg_sum) > self.threshold:
            self.pos_sum = 0
            self.neg_sum = 0
            return True

        return False

class AggregatedTraffic(BaseModel):
    timestamp: int
    packet_count: int
    unique_src_ip_count: int
    proto_counter: Dict[str, int]
    tcp_syn_count: int
    top_dst_ports: List[Tuple[int, int]]

def extract_features_from_aggregate(data: AggregatedTraffic) -> List[float]:
    proto_tcp = data.proto_counter.get("6", 0)
    proto_udp = data.proto_counter.get("17", 0)
    proto_icmp = data.proto_counter.get("1", 0)
    top_ports_count = sum([pair[1] for pair in data.top_dst_ports[:3]])
    return [
        data.packet_count,
        data.unique_src_ip_count,
        data.tcp_syn_count,
        proto_tcp,
        proto_udp,
        proto_icmp,
        top_ports_count
    ]

def get_model_path(user_key: str) -> str:
    return os.path.join(MODEL_DIR, f"{user_key}_model.pkl")

def get_scaler_path(user_key: str) -> str:
    return os.path.join(MODEL_DIR, f"{user_key}_scaler.pkl")

def load_user_model(user_key: str):
    model_path = get_model_path(user_key)
    scaler_path = get_scaler_path(user_key)
    if os.path.exists(model_path) and os.path.exists(scaler_path):
        user_models[user_key] = joblib.load(model_path)
        user_scalers[user_key] = joblib.load(scaler_path)

async def save_models_async():
    for user_key in user_models:
        joblib.dump(user_models[user_key], get_model_path(user_key))
        joblib.dump(user_scalers[user_key], get_scaler_path(user_key))
    print("[✔] Models saved asynchronously.")

def save_models_sync():
    asyncio.create_task(save_models_async())

atexit.register(save_models_sync)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(periodic_model_saver())

async def periodic_model_saver(interval_minutes: int = 10):
    while True:
        await asyncio.sleep(interval_minutes * 60)
        await save_models_async()

@app.post("/api/detect")
async def receive_aggregate(request: Request, payload: AggregatedTraffic):
    auth = request.headers.get("Authorization")
    if not auth or not auth.startswith("Bearer "):
        raise HTTPException(status_code=403, detail="Missing or invalid Authorization header")

    user_key = auth.split()[1]

    feature_vector = extract_features_from_aggregate(payload)

    if user_key not in user_buffers:
        user_buffers[user_key] = []
    user_buffers[user_key].append(feature_vector)

    if user_key not in user_cusums:
        user_cusums[user_key] = CusumDetector(threshold=500.0, drift=10.0)
    cusum_anomaly = user_cusums[user_key].update(payload.tcp_syn_count)

    if user_key not in user_models:
        load_user_model(user_key)

    if user_key not in user_models and len(user_buffers[user_key]) >= MIN_TRAIN_SIZE:
        data = np.array(user_buffers[user_key])
        scaler = StandardScaler()
        scaled_data = scaler.fit_transform(data)
        model = IsolationForest(contamination=0.05, random_state=42)
        model.fit(scaled_data)
        user_models[user_key] = model
        user_scalers[user_key] = scaler
        await save_models_async()  # Автоматичне збереження після тренування
        return {**payload.dict(), "anomaly": False, "message": "Model trained"}

    isolation_anomaly = False
    if user_key in user_models:
        scaled = user_scalers[user_key].transform([feature_vector])
        pred = user_models[user_key].predict(scaled)[0]
        isolation_anomaly = (pred == -1)

    is_anomaly = cusum_anomaly or isolation_anomaly

    return {
        **payload.dict(),
        "anomaly": bool(is_anomaly),
        "cusum_anomaly": bool(cusum_anomaly),
        "isolation_anomaly": bool(isolation_anomaly)
    }
