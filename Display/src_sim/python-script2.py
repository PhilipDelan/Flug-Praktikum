import struct
import socket
import sys
import json
from time import sleep
from threading import Thread

def receive_data():
    recv_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    recv_socket.bind(('127.0.0.1', 6000))  # receive port

    while True:
        data, addr = recv_socket.recvfrom(1024)
        message = data.decode('utf-8')
        print("Received RWSK:", message)

def monitor():
    # Thread to receive data while sending data
    recv_thread = Thread(target=receive_data)
    recv_thread.daemon = True
    recv_thread.start()

    i = 48.711338
    j = 11.535961
    altitude = 450.0

    while True:
        posi = [i, j, altitude, 0.0, 0.0, 0.0]  # ETSI RWY24
        data = {
            "lat": posi[0],
            "lon": posi[1],
            "alt": posi[2],
            "pitch": posi[3],
            "roll": posi[4],
            "yaw": posi[5]
        }
        
        print("Send Position:", data)
        json_data = json.dumps(data)

        processing_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        addr = ('127.0.0.1', 5000)
        processing_socket.sendto(json_data.encode('utf-8'), addr)
        processing_socket.close()

        # Increase latitude and longitude to simulate movement
        i += 0.0001  # Increase latitude
        j += 0.0001  # Increase longitude

        sleep(0.1)

if __name__ == "__main__":
    monitor()
