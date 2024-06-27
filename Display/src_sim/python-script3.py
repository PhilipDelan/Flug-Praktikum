import xpc
import socket
import json
from time import sleep
import threading
 
def send_position_data(client, ip, send_port):
    while True:
        posi = client.getPOSI()
        data = {
            "lat": posi[0],
            "lon": posi[1],
            "alt": posi[2],
            "pitch": posi[3],
            "roll": posi[4],
            "yaw": posi[5]
        }
        json_data = json.dumps(data)
 
        # Send position data to Processing
        send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        send_sock.sendto(json_data.encode(), (ip, send_port))
        send_sock.close()
        print(f"Sent data: {json_data}")
 
        #sleep(0.5)  # Adjust sleep duration as needed
 
def receive_rwsk_data(client, ip, recv_port):
    while True:
        try:
            recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            recv_sock.bind((ip, recv_port))
            recv_sock.settimeout(0.5)  # Increased timeout to 0.5 seconds
            
            data, _ = recv_sock.recvfrom(1024)
            rwsk = float(data.decode('utf-8'))
            send_heading(rwsk, client)
            
            recv_sock.close()
        except socket.timeout:
            continue
 
def send_heading(rwsk, client):
    dref = "sim/cockpit2/autopilot/heading_dial_deg_mag_pilot"
    client.sendDREF(dref, rwsk)
    print(f"Sent heading {rwsk} to XPlane")
 
def monitor():
    ip = '127.0.0.1'
    send_port = 5000
    recv_port = 6000
 
    with xpc.XPlaneConnect() as client:
        send_thread = threading.Thread(target=send_position_data, args=(client, ip, send_port))
        recv_thread = threading.Thread(target=receive_rwsk_data, args=(client, ip, recv_port))
        
        send_thread.start()
        recv_thread.start()
        
 
        sleep(0.5)  # Adjust sleep duration as needed
 
if __name__ == "__main__":
    monitor()