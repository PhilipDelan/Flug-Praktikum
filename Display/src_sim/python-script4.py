import xpc
import socket
import json
from time import sleep

def monitor():
    ip = '127.0.0.1'
    send_port = 5000
    recv_port = 6000

    with xpc.XPlaneConnect() as client:
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

            # Receive rwsk data from Processing
            recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            recv_sock.bind((ip, recv_port))
            
            data, _ = recv_sock.recvfrom(1024)
            rwsk = float(data.decode('utf-8'))
            send_heading(rwsk, client)
            
            recv_sock.close()

            # Send and print additional data
            #autopilot_state = client.getDREF("sim/cockpit/autopilot/autopilot_state")[0]
            #print(f"AP_State: {autopilot_state}")
            #heading_dial = client.getDREF("sim/cockpit2/autopilot/heading_dial_deg_mag_pilot")[0]
            #print(f"Heading Dial: {heading_dial}")
            #mag_psi = client.getDREF("sim/flightmodel/position/mag_psi")[0]
            #print(f"Magnetic Heading: {mag_psi}")

            sleep(0.5)  # Increased sleep duration to 0.5 seconds

def send_heading(rwsk, client):
    dref = "sim/cockpit2/autopilot/heading_dial_deg_mag_pilot"
    client.sendDREF(dref, rwsk)
    print(f"Sent heading {rwsk} to XPlane")

if __name__ == "__main__":
    monitor()
