import scapy.all as scapy
import requests
import json
import time
import threading
import os
from dotenv import load_dotenv

CONFIG_FILE = "sensor_config.json"
SEND_INTERVAL = 5
packet_buffer = []
lock = threading.Lock()

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
        config = {
            "api_key": api_key
        }
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f)
            print(f"[*] Конфігурацію збережено у {CONFIG_FILE}.")
    return config

def packet_callback(packet):
    if packet.haslayer(scapy.IP):
        pkt_info = {
            "timestamp": time.time(),
            "src_ip": packet[scapy.IP].src,
            "dst_ip": packet[scapy.IP].dst,
            "proto": packet[scapy.IP].proto,
            "length": len(packet)
        }

        if packet.haslayer(scapy.TCP):
            pkt_info["src_port"] = packet[scapy.TCP].sport
            pkt_info["dst_port"] = packet[scapy.TCP].dport
        elif packet.haslayer(scapy.UDP):
            pkt_info["src_port"] = packet[scapy.UDP].sport
            pkt_info["dst_port"] = packet[scapy.UDP].dport

        with lock:
            packet_buffer.append(pkt_info)

def send_packets(config):
    while True:
        time.sleep(SEND_INTERVAL)
        with lock:
            if packet_buffer:
                payload = {"data": packet_buffer.copy()}
                headers = {
                    "Authorization": f"Bearer {config['api_key']}",
                    "Content-Type": "application/json"
                }
                try:
                    response = requests.post(SERVER_URL, json=payload, headers=headers)
                    print(f"[+] Надіслано {len(packet_buffer)} пакетів. Статус: {response.status_code}")
                except Exception as e:
                    print(f"[!] Помилка надсилання: {e}")
                packet_buffer.clear()

def main():
    config = load_or_create_config()
    print("[*] Запуск сенсора трафіку...")
    threading.Thread(target=send_packets, args=(config,), daemon=True).start()
    scapy.sniff(prn=packet_callback, store=False)

if __name__ == "__main__":
    main()
