//FINAL

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;
import java.io.IOException;
import java.net.InetAddress;
import java.nio.charset.StandardCharsets;
import processing.data.JSONObject; 
import java.util.ArrayList;

PImage img;
PImage imgPlane;
DatagramSocket receiveSocket;
DatagramSocket sendSocket;

// Linke obere Ecke
float map_x_lo = 27;
float map_y_lo = 27;
float lat_y_lo = 48+(52.0/60.0);
float lon_x_lo = 11+(20.0/60.0);
//rechte untere Ecke
float map_x_ru = 712;
float map_y_ru = 712;
float lat_y_ru = 48+(36.0/60.0);
float lon_x_ru = 11+(44.0/60.0);

float WD = 180.0;
float windDirectionInAircraftDirection = (WD + 180) % 360;
float WV = 10.0 * 1852.0 / 3600.0; //10
float luv;
int temp = 0;
float rwsk = 0;

float lat, lon, alt, pitch, roll, yaw;
float prevLat = 0, prevLon = 0;
long prevTime = 0;
float i = 40;
float j = 35;
float temptimer = 0; 
long timeT = 0;
float distWP = 0;

int maxPoints = 300; 
ArrayList<PVector> points = new ArrayList<PVector>(); 

int currentWaypointIndex = 0;
final float THRESHOLD_DISTANCE = 500.0f;

ArrayList<Long> actualTimes = new ArrayList<Long>();

class waypoint {
    float lat = 0.0;
    float lon = 0.0;
    float pixel_x = 0;
    float pixel_y = 0;
   
    waypoint(float x, float y) {
        pixel_x = x;
        pixel_y = y;
        lat = map(y, map_y_lo, map_y_ru, lat_y_lo, lat_y_ru);
        lon = map(x, map_x_lo, map_x_ru, lon_x_lo, lon_x_ru);
    }

    float getx() { return pixel_x; }
    float getlat() { return lat; }
    float gety() { return pixel_y; }
    float getlon() { return lon; }
   
    void cross(boolean isCurrent) {
        if (isCurrent) stroke(255, 0, 0);
        else stroke(255, 0, 0);
        line(pixel_x - 5, pixel_y, pixel_x + 5, pixel_y);
        line(pixel_x, pixel_y - 5, pixel_x, pixel_y + 5);
    }
}

class leg {
    waypoint start;
    waypoint end;
   
    float distance = 0.0;
    float distancePlane = 0.0;
    float rwk = 0.0;
    float rwkPlane = 0.0;
    float time = 0.0; 
    float tas = 100.0 * 1852.0 / 3600.0;
   
    leg(waypoint start, waypoint end) {
        this.start = start;
        this.end = end;
        println(start.getlat() + " " + start.getlon() +" " + end.getlat() + " " + end.getlon());
        distance = calculateDistance(start.getlat(), start.getlon(), end.getlat(), end.getlon());
        distancePlane = calculateDistance(lat, lon, end.getlat(), end.getlon());
        rwk = calculateRWK(start, end);
        rwkPlane = calculateRWKToPlane(lat, lon, end);
    }
   
    float getdist() { return distance; }
    float getrwk() { return rwk; }
    float gettas() { return tas; }
    float getrwkPlane() {return rwkPlane;}
    float getbeta() {
        float beta = (windDirectionInAircraftDirection - getrwkPlane()) * DEG_TO_RAD;
        return beta;
    }
    float getluv() {
        float luv = asin((WV * sin(getbeta()) / gettas()));
        return luv;
    }
    
    float getrwskPlane() {
       rwsk = rwkPlane + getluv() * RAD_TO_DEG;
       return rwsk;
    }
    
    float getgamma() {
        float gamma = (DEG_TO_RAD * 180) - (getluv() + getbeta());
        return gamma;
    }
    float getGroundSpeed() {
        float GS = sqrt(sq(WV) + sq(gettas()) - 2 * WV * gettas() * cos(getgamma()));
        return GS;
    }
    float getEstTime() {
        float esttime = getdist() / getGroundSpeed();
        return esttime;
    }
   
    private float calculateDistance(float lat1, float lon1, float lat2, float lon2) {
        float R = 6371.0;
        float dLat = radians(lat2 - lat1);
        float dLon = radians(lon2 - lon1);
        float a = sin(dLat / 2) * sin(dLat / 2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
        float c = 2 * atan2(sqrt(a), sqrt(1 - a));
        float distance = R * c;
        return distance * 1000;
    }

    private float calculateRWK(waypoint start, waypoint end) {
        float deltaLon = end.getlon() - start.getlon();
        float deltaLat = end.getlat() - start.getlat();
        float rwk = 0.0;

        if (deltaLon == 0.0 && deltaLat > 0.0) rwk = 180.0;
        else if (deltaLon == 0.0 && deltaLat < 0.0) rwk = 0.0;
        else if (deltaLon > 0.0 && deltaLat == 0.0) rwk = 270.0;
        else if (deltaLon < 0.0 && deltaLat == 0.0) rwk = 90.0;
        else if (deltaLon < 0.0) rwk = degrees(PI / 2.0 - atan(deltaLat * 60.0 * 1852.0 / (deltaLon * cos(radians(start.getlat())) * 60.0 * 1852.0)));
        else if (deltaLon > 0.0) rwk = degrees(3.0 / 2.0 * PI - atan(deltaLat * 60.0 * 1852.0 / (deltaLon * cos(radians(start.getlat())) * 60.0 * 1852.0)));
        
        return rwk;
    }
    
    private float calculateRWKToPlane(float planeLat, float planeLon, waypoint end) {
        float deltaLon = planeLon - end.getlon();
        float deltaLat = planeLat - end.getlat() ;
        float rwk = 0.0;

        if (deltaLon == 0.0 && deltaLat > 0.0) rwk = 180.0;
        else if (deltaLon == 0.0 && deltaLat < 0.0) rwk = 0.0;
        else if (deltaLon > 0.0 && deltaLat == 0.0) rwk = 270.0;
        else if (deltaLon < 0.0 && deltaLat == 0.0) rwk = 90.0;
        else if (deltaLon < 0.0) rwk = degrees(PI / 2.0 - atan(deltaLat * 60.0 * 1852.0 / (deltaLon * cos(radians(start.getlat())) * 60.0 * 1852.0)));
        else if (deltaLon > 0.0) rwk = degrees(3.0 / 2.0 * PI - atan(deltaLat * 60.0 * 1852.0 / (deltaLon * cos(radians(start.getlat())) * 60.0 * 1852.0)));
        
        return rwk;
    }
}

ArrayList<waypoint> wpList = new ArrayList<waypoint>();
ArrayList<leg> legList = new ArrayList<leg>();

boolean newWaypointAdded = false;

void setup() {
    size(1920,738);
    img = loadImage("Karte.jpg");
    imgPlane = loadImage("Flugzeug.png");
    stroke(255);
    imgPlane = loadImage("Flugzeug.png");
    prevTime = millis();
    
    try {
      receiveSocket = new DatagramSocket(5000);
      sendSocket = new DatagramSocket();  
    } catch (SocketException e) {
      e.printStackTrace();
    }
    
}

void draw() {
    background(0);
    image(img, 0, 0);
    receiveData();
    geoToPixel(lat, lon, yaw);
    updateRWSK(); // Update rwsk based on the current waypoint
    sendHeading();  // New function to send the heading
    drawPoints();
    drawFlightInformation();
    drawWaypointsAndLegs();
    updatePreviousValues();
    
    //DEBUG
    debugWaypoints();
}

void drawPoints() {
    for (PVector point : points) {
        fill(255, 0, 0); 
        stroke(255, 0, 0); 
        ellipse(point.x, point.y, 1, 1); 
    }
}

void drawFlightInformation() {
    int tempdist = 0;
    textSize(15);
    strokeWeight(3);
    fill(255);
    
    if (currentWaypointIndex < wpList.size()) {
        waypoint currentWaypoint = wpList.get(currentWaypointIndex);
        float distanceWaypoint = calculateDistance(lat, lon, currentWaypoint.getlat(), currentWaypoint.getlon());

        if (currentWaypointIndex == 0) { // Only check distance for the first waypoint
            if (distanceWaypoint < THRESHOLD_DISTANCE) {
                long currentTime = millis();
                long timeTaken = (currentTime) / 1000;
                actualTimes.add(timeTaken);
                currentWaypointIndex++;
            }
        } else { // Use the special distance calculation for subsequent waypoints
            if (calculateDistanceAlongAB(
                wpList.get(currentWaypointIndex - 1).getlat(), 
                wpList.get(currentWaypointIndex - 1).getlon(), 
                currentWaypoint.getlat(), 
                currentWaypoint.getlon(), 
                lat, 
                lon) < 0) {
                long currentTime = millis();
                long timeTaken = (currentTime - actualTimes.get(actualTimes.size() - 1) * 1000) / 1000;
                actualTimes.add(timeTaken);
                currentWaypointIndex++;
            }
        }
    }
    
    for (int i = 0; i < wpList.size(); i++) {
        waypoint wp = wpList.get(i);
        float distanceWaypoint = calculateDistance(lat, lon, wp.getlat(), wp.getlon());
        float distanceWaypointAB = 0;

        if (i < wpList.size() - 1) { 
            leg leg = legList.get(i);
            waypoint nextWp = wpList.get(i+1); // Nächster Wegpunkt
            distanceWaypointAB = calculateDistanceAlongAB(wp.getlat(), wp.getlon(), nextWp.getlat(), nextWp.getlon(), lat, lon);
            fill(255);
            //text("distanceWaypointAB: " + abs(distanceWaypointAB), 850, 45 + (i) * 70); // Position anpassen, damit der Text nicht überlappt
            //text("getrwkPlane: " + leg.getrwkPlane(), 1100 , 115 + (i) * 70); 
            //text("getrwskPlane: " + leg.getrwskPlane(), 1300 , 115 + (i) * 70);
        }
        tempdist += distWP;
        float groundSpeed = calculateGroundSpeed(lat, lon, prevLat, prevLon, prevTime, millis());
        float esttime = distWP / groundSpeed;

        fill(0);
        stroke(65, 105, 225);
        rect(1750, 40, 150, 90);  // Blau
        
        fill(0);
        stroke(0);
        rect(1750, 0, 150, 35); // flightinfo
        rect(1750, 140, 150, 20); // est time
        rect(1750, 170, 77, 20);  // taken time
        
        noFill();
        stroke(0, 255, 127);
        rect(1750, 132, 150, 95); // Gruens no fill
        strokeWeight(3);
        fill(255);

        text("WP" + i + " lat: " + wp.getlat() + " lon: " + wp.getlon(), 800, (i + 1) * 70);
        text("flightinformation:", 1750, 30);
        text("  wp-p dist: " + (int)distWP + " m", 1750, 60); //works
        text("  tot. dist: " + tempdist + " m", 1750, 90); //works
        text("  speed: " + (int)groundSpeed + " m/s", 1750, 120);
        text("  est. time: " + (int)esttime + " s", 1750, 150);
        
       
    }
    if(currentWaypointIndex < wpList.size()) {
        waypoint currentWaypoint = wpList.get(currentWaypointIndex);
        fill(0);
        stroke(0);
        rect(800, (currentWaypointIndex + 1) * 70 - 20, 300, 25);
        fill(255, 0, 0); // RED
        text("WP" + currentWaypointIndex + "   lat: " + currentWaypoint.getlat() + "   lon: " + currentWaypoint.getlon(), 800, (currentWaypointIndex + 1) * 70);
    }
}

void drawWaypointsAndLegs() {
    // Draw crosses for waypoints, skipping the first two
    for (int i = 0; i < wpList.size(); i++) {
        if (i > 0) { // Skip drawing cross for WP0
            if (i == currentWaypointIndex) wpList.get(i).cross(true);
            else wpList.get(i).cross(false);
        }
    }
  
    // Draw lines between waypoints, starting from WP2
    for (int i = 2; i < wpList.size(); i++) {
        line(wpList.get(i - 1).getx(), wpList.get(i - 1).gety(), wpList.get(i).getx(), wpList.get(i).gety());
    }
  
    int temptime = 0;
    float dist_sum = 0.0;
    for (int j = 0; j < legList.size(); j++) {
        leg leg = legList.get(j);
        temptime += (int)(leg.getEstTime());
        dist_sum += leg.getdist();

        fill(255);
        text("dist: " + (int)(leg.getdist() + 0.5) + "m" +
             "     luv: " + (leg.getluv() * RAD_TO_DEG + 0.5) + "°" +
             "     est. time: " + (int)(leg.getEstTime()) + "s" +
             "     tot. est. time: " + temptime + "s" +
             "     WD/WV: " + WD + "°" + "/" + WV + "m/s" +
             "     time: " + (int)(leg.getdist() / leg.gettas() + 0.5) + "s" +
             "     accdist: " + (int)(dist_sum + 0.5) + "m", 850, 25 + (j + 1) * 70);
    }
}


void updatePreviousValues() {
    prevLat = lat;
    prevLon = lon;
    prevTime = millis();
}

void mousePressed() {
    if (mouseButton == LEFT) {
        waypoint newWaypoint = new waypoint((float) mouseX, (float) mouseY);
        wpList.add(newWaypoint);
        if (wpList.size() > 1) {
            legList.add(new leg(wpList.get(wpList.size() - 2), wpList.get(wpList.size() - 1)));
        }
        newWaypointAdded = true; // Mark that a new waypoint was added
    }
}

void updateRWSK() {
    if (newWaypointAdded && currentWaypointIndex < wpList.size()) {
        waypoint currentWaypoint = wpList.get(currentWaypointIndex);
        float distanceWaypoint = calculateDistance(lat, lon, currentWaypoint.getlat(), currentWaypoint.getlon());
        distWP = distanceWaypoint;
        if (currentWaypointIndex <= 1) {                                                                                   // wenn erster Waypoint
            if (distanceWaypoint < THRESHOLD_DISTANCE) {
                currentWaypointIndex++;
            }
        } else {                                                                                                           // anderen Waypoints
            if (calculateDistanceAlongAB(
                wpList.get(currentWaypointIndex - 1).getlat(), 
                wpList.get(currentWaypointIndex - 1).getlon(), 
                currentWaypoint.getlat(), 
                currentWaypoint.getlon(), 
                lat, 
                lon) < 0) {
                currentWaypointIndex++;
             
                if (currentWaypointIndex >= wpList.size()) {                                                                // Stopt RWSK berechnung
                    //currentWaypointIndex = currentWaypointIndex; 
                    newWaypointAdded = false;                                                                 
                }
            }
        }

        if (currentWaypointIndex < wpList.size()) {                                                                          // neuer WP
            waypoint nextWaypoint = wpList.get(currentWaypointIndex);
            leg currentLeg = new leg(new waypoint(lat, lon), nextWaypoint);
            rwsk = currentLeg.getrwskPlane();
        }
    }
}

void sendHeading() {
  text("RWSK: " + rwsk, 850, 20);
  yaw = rwsk;
  try {
    byte[] buffer = Float.toString(rwsk).getBytes(StandardCharsets.UTF_8);
    DatagramPacket packet = new DatagramPacket(buffer, buffer.length, InetAddress.getByName("127.0.0.1"), 6000);
    sendSocket.send(packet);
  } catch (IOException e) {
    e.printStackTrace();
  }
}

void receiveData() {
    
    byte[] buffer = new byte[1024]; // Buffer for received data (larger to accommodate JSON data)
    DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
    try {
        receiveSocket.receive(packet); // Receive the UDP packet
        String json = new String(packet.getData(), 0, packet.getLength(), StandardCharsets.UTF_8);
        JSONObject data = JSONObject.parse(json); // Deserialize the JSON data into a JSONObject
        lat = data.getFloat("lat");
        lon = data.getFloat("lon");
        alt = data.getFloat("alt");
        pitch = data.getFloat("pitch");
        roll = data.getFloat("roll");
        yaw = data.getFloat("yaw");
        
        // Add the current position as a new waypoint
        updateWaypointList(lat, lon);

    } catch (IOException e) {
        e.printStackTrace();
    }
    /*
    lat = coordinate(48, i, 0.1);
    lon = coordinate(11, j, 0.1);
    //i += 0.01;
    //j += 0.001;
    */
    //delay(100);
    
    println("WPlane: " + lat + " , " + lon);
}

void updateWaypointList(float lat, float lon) {
    waypoint currentWaypoint = new waypoint(map(lon, lon_x_lo, lon_x_ru, map_x_lo, map_x_ru), map(lat, lat_y_lo, lat_y_ru, map_y_lo, map_y_ru));
    
    if (wpList.isEmpty()) {
        wpList.add(currentWaypoint);
    } else {
        wpList.set(0, currentWaypoint);
    }
    
    if (wpList.size() > 1) {
        legList.clear();
        for (int i = 1; i < wpList.size(); i++) {
            legList.add(new leg(wpList.get(i - 1), wpList.get(i)));
        }
    }
}

void geoToPixel(float lat, float lon, float rot) {
    float x = map(lon, 11.333333, 11.733333, 24, 710);
    float y = map(lat, 48.866667, 48.600000, 24, 710);
  
    points.add(0, new PVector(x, y));
  
    if (points.size() > maxPoints) {
        points.remove(points.size() - 1);
    }
    move(x, y, rot);
}

void move(float x, float y, float rot) {
    push();
    translate(x, y);
    rotate(rot * DEG_TO_RAD);
    image(imgPlane, -imgPlane.width / 24, -imgPlane.height / 24, imgPlane.width / 12, imgPlane.height / 12);
    pop();
}

float coordinate(float deg, float min, float sec) {
    float decimal = deg + (min / 60) + (sec / 3600);
    return decimal;
}

float calculateDistance(float lat1, float lon1, float lat2, float lon2) {
    float R = 6371.0;
    float dLat = radians(lat2 - lat1);
    float dLon = radians(lon2 - lon1);
    float a = sin(dLat / 2) * sin(dLat / 2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    float c = 2 * atan2(sqrt(a), sqrt(1 - a));
    float distance = R * c;
    return distance * 1000;
}

float calculateDistanceAlongAB(float latA, float lonA, float latB, float lonB, float latP, float lonP) {
    float distanceAB = calculateDistance(latA, lonA, latB, lonB);
    float distanceAP = calculateDistance(latA, lonA, latP, lonP);
    float distanceBP = calculateDistance(latB, lonB, latP, lonP);
    float cosAnglePAB = (distanceAP * distanceAP + distanceAB * distanceAB - distanceBP * distanceBP) / (2 * distanceAP * distanceAB);
    float projectionPOnAB = distanceAP * cos(acos(cosAnglePAB));
    float remainingDistanceAlongAB = distanceAB - projectionPOnAB;
    return remainingDistanceAlongAB;
}

float calculateGroundSpeed(float lat1, float lon1, float lat2, float lon2, long time1, long time2) {
    float distance = calculateDistance(lat1, lon1, lat2, lon2);
    float timeElapsed = (time2 - time1) / 1000.0;
    float speed = distance / timeElapsed;
    return speed;
}

//DEBUG
void debugWaypoints() {
    int numWaypoints = wpList.size();
    if (numWaypoints > 0) {
        println("Last three waypoints:");
        for (int i = max(0, numWaypoints - 3); i < numWaypoints; i++) {
            waypoint wp = wpList.get(i);
            println("WP" + i + " - Lat: " + wp.getlat() + ", Lon: " + wp.getlon() + ", Pixel X: " + wp.getx() + ", Pixel Y: " + wp.gety());
        }
    }
}
