from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Tuple
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

app = FastAPI()

# === Ініціалізація моделей, скейлерів, буферів ===
user_models: Dict[str, IsolationForest] = {}
user_scalers: Dict[str, StandardScaler] = {}
user_buffers: Dict[str, List[List[float]]] = {}
MIN_TRAIN_SIZE = 100

# === Простий CUSUM детектор ===
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
            # Сигнал аномалії, скидаємо накопичення
            self.pos_sum = 0
            self.neg_sum = 0
            return True

        return False

user_cusums: Dict[str, CusumDetector] = {}

# === Очікувана агрегована структура від сенсора ===
class AggregatedTraffic(BaseModel):
    timestamp: int
    packet_count: int
    unique_src_ip_count: int
    proto_counter: Dict[str, int]
    tcp_syn_count: int
    top_dst_ports: List[Tuple[int, int]]

# === Фічі для моделі IsolationForest ===
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

@app.post("/api/detect")
async def receive_aggregate(request: Request, payload: AggregatedTraffic):
    auth = request.headers.get("Authorization")
    if not auth or not auth.startswith("Bearer "):
        raise HTTPException(status_code=403, detail="Missing or invalid Authorization header")

    user_key = auth.split()[1]

    feature_vector = extract_features_from_aggregate(payload)

    # === Буфер фічей для тренування
    if user_key not in user_buffers:
        user_buffers[user_key] = []
    user_buffers[user_key].append(feature_vector)

    # === Ініціалізація CUSUM для кожного користувача
    if user_key not in user_cusums:
        user_cusums[user_key] = CusumDetector(threshold=500.0, drift=10.0)

    # === CUSUM: середній SYN count (чи packet size - залежно від метрики)
    cusum_anomaly = user_cusums[user_key].update(payload.tcp_syn_count)

    # === Тренування моделі якщо ще немає
    if user_key not in user_models and len(user_buffers[user_key]) >= MIN_TRAIN_SIZE:
        data = np.array(user_buffers[user_key])
        scaler = StandardScaler()
        scaled_data = scaler.fit_transform(data)
        model = IsolationForest(contamination=0.05, random_state=42)
        model.fit(scaled_data)
        user_models[user_key] = model
        user_scalers[user_key] = scaler
        return {**payload.dict(), "anomaly": False, "message": "Model trained"}

    # === Визначення аномалії
    isolation_anomaly = False
    if user_key in user_models:
        scaled = user_scalers[user_key].transform([feature_vector])
        pred = user_models[user_key].predict(scaled)[0]  # -1 = anomaly
        isolation_anomaly = (pred == -1)

    # === Остаточне рішення: якщо хоч одна модель сигналить
    is_anomaly = cusum_anomaly or isolation_anomaly

    return {
        **payload.dict(),
        "anomaly": is_anomaly,
        "cusum_anomaly": cusum_anomaly,
        "isolation_anomaly": isolation_anomaly
    }
