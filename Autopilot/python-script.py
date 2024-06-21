import xpc
import time

import sys


def monitor():
    with xpc.XPlaneConnect() as client:
        i=client.getDREF("sim/cockpit2/autopilot/heading_dial_deg_mag_pilot")[0]
        client.sendDREF("sim/cockpit2/autopilot/heading_dial_deg_mag_pilot", i-90.0)
        while True:
            posi = client.getPOSI();

            #print("Loc: (%4f, %4f, %4f) Attitude (P %4f) (R %4f) (Y %4f)\n"\
            #   % (posi[0], posi[1], posi[2], posi[3] , posi[4], posi[5]))
               
            print(client.getDREF("sim/cockpit2/autopilot/heading_dial_deg_mag_pilot")[0])
            print("(Y %4f)\n" % (posi[5]))
            print(client.getDREF("sim/flightmodel/position/mag_psi")[0])

            time.sleep(1)
           

if __name__ == "__main__":


    dref1 = "sim/cockpit2/autopilot/vvi_dial_fpm"
    dref2 = "sim/cockpit/autopilot/autopilot_state"
        

    # Setup
    client = xpc.XPlaneConnect()

    # Execute
    client.sendDREF(dref1, 180.0)
    value = 2+16384
    client.sendDREF(dref2, value)
    # Cleanup
    client.close()
            
    monitor()