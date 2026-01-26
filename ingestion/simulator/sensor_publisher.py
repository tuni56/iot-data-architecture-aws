import json
import time
import random
import ssl
from datetime import datetime
from paho.mqtt import client as mqtt

import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CERTS_DIR = os.path.join(BASE_DIR, "certs")


# ===== CONFIG =====
IOT_ENDPOINT = "ak6sahgjl0pzf-ats.iot.us-east-2.amazonaws.com"
CLIENT_ID = "iot-sensor-demo-01"
TOPIC = "iot/sensors/temperature"

CERT_PATH = os.path.join(CERTS_DIR, "device.pem.crt")
KEY_PATH = os.path.join(CERTS_DIR, "private.pem.key")
CA_PATH = os.path.join(CERTS_DIR, "AmazonRootCA1.pem")

# ==================


def generate_sensor_data():
    return {
        "device_id": CLIENT_ID,
        "timestamp": datetime.utcnow().isoformat(),
        "temperature": round(random.uniform(18.0, 30.0), 2),
        "humidity": round(random.uniform(40.0, 70.0), 2)
    }


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to AWS IoT Core")
    else:
        print(f"Connection failed with code {rc}")


client = mqtt.Client(client_id=CLIENT_ID)
client.on_connect = on_connect

client.tls_set(
    ca_certs=CA_PATH,
    certfile=CERT_PATH,
    keyfile=KEY_PATH,
    tls_version=ssl.PROTOCOL_TLSv1_2
)

client.connect(IOT_ENDPOINT, 8883)
client.loop_start()

try:
    while True:
        payload = generate_sensor_data()
        client.publish(TOPIC, json.dumps(payload))
        print("Published:", payload)
        time.sleep(5)
except KeyboardInterrupt:
    client.loop_stop()
    client.disconnect()
