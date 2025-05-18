from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
from typing import List, Dict
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

app = FastAPI()

# Існуючі структури
user_models: Dict[str, IsolationForest] = {}
user_scalers: Dict[str, StandardScaler] = {}
user_buffers: Dict[str, List[List[float]]] = {}
MIN_TRAIN_SIZE = 100

# Додамо CUSUM для кожного користувача
user_cusums: Dict[str, CusumDetector] = {}

class Packet(BaseModel):
    timestamp: float
    src_ip: str
    dst_ip: str
    proto: int
    length: int
    src_port: int = None
    dst_port: int = None

class PacketPayload(BaseModel):
    data: List[Packet]

def extract_features(packet: Packet) -> List[float]:
    return [
        packet.proto,
        packet.length,
        packet.src_port or 0,
        packet.dst_port or 0
    ]

@app.post("/api/sensor/submit")
async def receive_traffic(request: Request, payload: PacketPayload):
    auth = request.headers.get("Authorization")
    if not auth or not auth.startswith("Bearer "):
        raise HTTPException(status_code=403, detail="Missing or invalid Authorization header")

    user_key = auth.split()[1]
    feature_vectors = [extract_features(pkt) for pkt in payload.data]

    # Ініціалізація буфера
    if user_key not in user_buffers:
        user_buffers[user_key] = []
    user_buffers[user_key].extend(feature_vectors)

    # Ініціалізація CUSUM
    if user_key not in user_cusums:
        user_cusums[user_key] = CusumDetector(threshold=10.0, drift=0.1)

    # Витягуємо для CUSUM скалярну метрику, наприклад середню довжину пакетів у цьому запиті
    mean_length = np.mean([pkt.length for pkt in payload.data])

    # Запускаємо CUSUM
    cusum_anomaly = user_cusums[user_key].update(mean_length)

    # Обробка Isolation Forest
    if user_key not in user_models and len(user_buffers[user_key]) >= MIN_TRAIN_SIZE:
        data = np.array(user_buffers[user_key])
        scaler = StandardScaler()
        scaled_data = scaler.fit_transform(data)
        model = IsolationForest(contamination=0.05, random_state=42)
        model.fit(scaled_data)
        user_models[user_key] = model
        user_scalers[user_key] = scaler
        return {"message": f"Model trained for user {user_key}", "status": "trained"}

    if user_key in user_models:
        data = np.array(feature_vectors)
        scaled = user_scalers[user_key].transform(data)
        preds = user_models[user_key].predict(scaled)
        isolation_anomalies = [1 if p == -1 else 0 for p in preds]
    else:
        isolation_anomalies = []

    return {
        "cusum_anomaly": cusum_anomaly,
        "isolation_anomalies": isolation_anomalies,
        "total_packets": len(feature_vectors)
    }
