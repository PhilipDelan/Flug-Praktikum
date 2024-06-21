import xpc
import socket
import json
from time import sleep

def monitor():
    with xpc.XPlaneConnect() as client:
        while True:
            posi = client.getPOSI()
            # print(f"Retrieved POSI: {posi}")
            data = {
                "lat": posi[0],
                "lon": posi[1],
                "alt": posi[2],
                "pitch": posi[3],
                "roll": posi[4],
                "yaw": posi[5]
            }
            json_data = json.dumps(data)
            #print(f"JSON data: {json_data}")
            processing_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            address = ('127.0.0.1', 5000)
            processing_socket.sendto(json_data.encode(), address)
            processing_socket.close()
            print(f"Sent data: {json_data}")
            sleep(0.1)

if __name__ == "__main__":




    # dref1 = "sim/cockpit/autopilot/nav_steer_deg_mag"
    # dref2 = "sim/cockpit/autopilot/autopilot_state"
        

    # Setup
    # client = xpc.XPlaneConnect()

    # Execute
    # client.sendDREF(dref1, 120.0)
    # value = 512+16384
    # client.sendDREF(dref2, value)
    # Cleanup
    # client.close()
            
    monitor()