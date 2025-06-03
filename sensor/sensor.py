import scapy.all as scapy
import requests
import json
import time
import threading
import os
from collections import Counter
from dotenv import load_dotenv

CONFIG_FILE = "sensor_config.json"
SEND_INTERVAL = 5
lock = threading.Lock()

# Агреговані дані
stats = {
    "packet_count": 0,
    "unique_src_ips": set(),
    "proto_counter": Counter(),
    "tcp_syn_count": 0,
    "dst_ports": Counter()
}

# Завантаження .env
load_dotenv()
SERVER_URL = os.getenv("SERVER_URL")

if not SERVER_URL:
    raise RuntimeError("[!] SERVER_URL не знайдено у .env файлі!")

def load_or_create_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
            print("[*] Конфігурацію сенсора завантажено.")
    else:
        print("[*] Введіть ваш унікальний API ключ (наданий адміністратором):")
        api_key = input("API ключ: ").strip()
        config = {"api_key": api_key}
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f)
            print(f"[*] Конфігурацію збережено у {CONFIG_FILE}.")
    return config

def packet_callback(packet):
    if packet.haslayer(scapy.IP):
        with lock:
            stats["packet_count"] += 1
            stats["unique_src_ips"].add(packet[scapy.IP].src)

            proto = packet[scapy.IP].proto
            stats["proto_counter"][proto] += 1

            if packet.haslayer(scapy.TCP):
                tcp_layer = packet[scapy.TCP]
                # Перевірка лише SYN флагу
                if tcp_layer.flags == "S":
                    stats["tcp_syn_count"] += 1
                stats["dst_ports"][tcp_layer.dport] += 1

            elif packet.haslayer(scapy.UDP):
                udp_layer = packet[scapy.UDP]
                stats["dst_ports"][udp_layer.dport] += 1

def send_stats(config):
    while True:
        time.sleep(SEND_INTERVAL)
        with lock:
            payload = {
                "timestamp": int(time.time()),
                "packet_count": stats["packet_count"],
                "unique_src_ip_count": len(stats["unique_src_ips"]),
                "proto_counter": dict(stats["proto_counter"]),
                "tcp_syn_count": stats["tcp_syn_count"],
                "top_dst_ports": stats["dst_ports"].most_common(10)
            }

            headers = {
                "Authorization": f"Bearer {config['api_key']}",
                "Content-Type": "application/json"
            }

            try:
                response = requests.post(SERVER_URL, json=payload, headers=headers)
                print(f"[+] Надіслано {payload['packet_count']} пакетів. Статус: {response.status_code}")
            except Exception as e:
                print(f"[!] Помилка надсилання: {e}")

            # Очистка
            stats["packet_count"] = 0
            stats["unique_src_ips"].clear()
            stats["proto_counter"].clear()
            stats["tcp_syn_count"] = 0
            stats["dst_ports"].clear()

def main():
    config = load_or_create_config()
    print("[*] Запуск сенсора трафіку...")
    threading.Thread(target=send_stats, args=(config,), daemon=True).start()
    scapy.sniff(prn=packet_callback, store=False)

if __name__ == "__main__":
    main()
