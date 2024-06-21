import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import processing.data.JSONObject; 
import java.util.ArrayList;

PImage img;
PImage imgPlane;
DatagramSocket socket;

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

float lat, lon, alt, pitch, roll, yaw;
float prevLat = 0, prevLon = 0;
long prevTime = 0;
float i = 40;

int maxPoints = 300; 
ArrayList<PVector> points = new ArrayList<PVector>(); 

int currentWaypointIndex = 0;
final float THRESHOLD_DISTANCE = 300.0f;

ArrayList<Long> actualTimes = new ArrayList<Long>();

class waypoint
{
   float lat = 0.0;
   float lon = 0.0;
   float pixel_x=0;
   float pixel_y=0;
   
   waypoint(float x, float y)
   {
     pixel_x = x;
     pixel_y = y;
     
     lat = map(y,map_y_lo, map_y_ru, lat_y_lo, lat_y_ru);
     lon = map(x,map_x_lo, map_x_ru, lon_x_lo, lon_x_ru);
   }

   float getx()
   {
     return pixel_x;
   }

  float getlat()
  {
    return lat;
  }
  

   float gety()
   {
     return pixel_y;
   }
   
   float getlon()
   {
       return lon;
   }
   
   void cross(boolean isCurrent)
   {
      if (isCurrent) {
        stroke(255,0, 0);
      } else {
        stroke(255,0,0);
      }
      line(pixel_x-5, pixel_y, pixel_x+5, pixel_y);
      line(pixel_x, pixel_y-5, pixel_x, pixel_y+5);
   }
}


class leg
{
   waypoint start;
   waypoint end;
   
   float distance = 0.0;
   float rwk = 0.0;
   float time= 0.0; 
   // True air speed in m/s
   float tas = 100.0 * 1852.0 / 3600.0;
   
   leg(waypoint start, waypoint end)
   {
     distance = pow(pow ((start.getlat()-end.getlat())*60.0*1852,2) + pow( (start.getlon()-end.getlon())*cos(radians(start.getlat()))*60.0*1852 ,2), 0.5);
     
     if ((start.getlon()-end.getlon()) == 0.0 && (start.getlat()-end.getlat()) >0.0)
       rwk=180.0;
     else if  ((start.getlon()-end.getlon()) == 0.0 && (start.getlat()-end.getlat()) <0.0)
       rwk = 0.0; 
     else if  ((start.getlon()-end.getlon()) > 0.0 && (start.getlat()-end.getlat()) == 0.0)
         rwk = 270.0;
     else if  ((start.getlon()-end.getlon()) < 0.0 && (start.getlat()-end.getlat()) == 0.0)      
         rwk = 90.0;
         
     else if(((start.getlon()-end.getlon()) < 0.0) )
       rwk = degrees(PI/2.0 - atan( ((start.getlat()-end.getlat())*60.0*1852.0) / ((start.getlon()-end.getlon())*cos(radians(start.getlat()))*60.0*1852.0) ) );
     else if (((start.getlon()-end.getlon()) > 0.0) )
       rwk = degrees(3.0/2.0*PI- atan(((start.getlat()-end.getlat())*60.0*1852.0) / ((start.getlon()-end.getlon())*cos(radians(start.getlat()))*60.0*1852.0) ) );

     // print(distance, "\n");
   }
   
   float getdist()
   {
     return distance;
   }
   
   float getrwk()
   {
     return rwk;
   }
   
   float gettas()
   {
     return tas;
   }
   
   float getbeta()
  {
    float beta = (windDirectionInAircraftDirection - getrwk())* DEG_TO_RAD;  //durch Scheitelwinkel/Gegenwinkel
    //println("Beta: " + beta* RAD_TO_DEG);
    return beta; // RAD
  }
   
  float getluv() // Alpha
  {
    float luv = asin((WV * sin(getbeta())/ gettas()));
    //println("Luv: " + luv * RAD_TO_DEG);
    return luv; // RAD
  }
  
  float getgamma()
  {
     float gamma = (DEG_TO_RAD * 180) - (getluv() + getbeta());
    //println("Gamma: " + gamma* RAD_TO_DEG);
    return gamma; // RAD
  }
  
  float getGroundSpeed() 
  {
    float GS = sqrt(sq(WV) + sq(gettas()) - 2 * WV * gettas() * cos(getgamma()));
    //println("GS: " + GS);
    return GS;
  }
  
  float getEstTime()
  {
    float esttime = getdist() / getGroundSpeed();
    //println("est. Time: " + estTime + "   temp. Time: " + temp );
    return esttime;
  }
}


ArrayList<waypoint> wpList = new ArrayList<waypoint>();

ArrayList<leg> legList = new ArrayList<leg>();

void setup() {
  size(1920,738);
  img = loadImage("Karte.jpg");
  imgPlane = loadImage("Flugzeug.png"); // Flugzeugbild laden
  stroke(255);
  imgPlane = loadImage("Flugzeug.png"); // Flugzeugbild laden
  prevTime = millis();
  /*
  try {
    socket = new DatagramSocket(5000);
  } catch (SocketException e) {
    e.printStackTrace();
  }
  */
}

void draw() {
  background(0);
  image(img, 0, 0);
  receiveData();
  geoToPixel(lat, lon, yaw);  
  
    // Punkte
  for (PVector point : points) {
    fill(255, 0, 0); 
    stroke(255, 0, 0); 
    ellipse(point.x, point.y, 1, 1); 
  }
  
  textSize(15);
  strokeWeight(3);
  fill(255);
  int tempdist = 0;
  
  if (currentWaypointIndex < wpList.size()) {
    waypoint currentWaypoint = wpList.get(currentWaypointIndex);
    float distanceWaypoint = calculateDistance(lat, lon, currentWaypoint.getlat(), currentWaypoint.getlon());
    
    if (distanceWaypoint < THRESHOLD_DISTANCE) {
      long currentTime = millis();
      
      if (currentWaypointIndex > 0) {
        long timeTaken = (currentTime - actualTimes.get(currentWaypointIndex - 1)) / 1000; // Zeit in Sekunden
        actualTimes.add(timeTaken);
        //println("Time taken to reach waypoint " + currentWaypointIndex + ": " + timeTaken + " seconds");
      } else {
        actualTimes.add(currentTime);
      }
      
      currentWaypointIndex++;
      if (currentWaypointIndex < wpList.size()) {
        currentWaypoint = wpList.get(currentWaypointIndex);
        distanceWaypoint = calculateDistance(lat, lon, currentWaypoint.getlat(), currentWaypoint.getlon());
      } else {
        println("Alle Wegpunkte erreicht.");
      }  
    }
   for(int i=0; i<wpList.size(); i++)
    {
      float distanceWaypoint1 = calculateDistance(lat, lon, wpList.get(0).getlat(), wpList.get(0).getlon());
      tempdist = (int) distanceWaypoint + tempdist;
      float groundSpeed = calculateGroundSpeed(lat, lon, prevLat, prevLon, prevTime, millis());
      float esttime = distanceWaypoint / groundSpeed; // time in second
      fill(0);
      stroke(65,105,225);
      rect(1750, 40, 150, 120);
      fill(0);
      stroke(0);
      rect(1750, 0, 150, 35);
      strokeWeight(3);
      fill(255);
      text("WP" + i + " lat: " + wpList.get(i).getlat() + " lon: " + wpList.get(i).getlon() , 800,(i+1)*70);
      
      text(" flightinformation: " , 1750, 30);
      text(" wp dist: " + (int)distanceWaypoint + " m", 1750, 60);
      text(" tot. dist: " + (int)tempdist + " m", 1750, 90);
      text(" speed: " + (int)groundSpeed + " m/s", 1750, 120);
      text(" est. time: " + (int)esttime + " s", 1750, 150);
      
      if (i > 0 && i < actualTimes.size()) {
        long timeTaken = actualTimes.get(i); // Zeit in Sekunden
        fill(0);
        stroke(0);
        rect(1750, 170, 150, 15);
        fill(255);
        text(" time taken: " + timeTaken + " s", 1750, 180);
      }
    }
    fill(0);
    stroke(0);
    rect(800,(currentWaypointIndex+1)*70 -20, 300, 25);
    fill(255, 0,0);
    text("WP" + currentWaypointIndex + "   lat: " + currentWaypoint.getlat() + "   lon: " + currentWaypoint.getlon(), 800,(currentWaypointIndex+1)*70);
    fill(255, 0,0);
    
    
  }
  else
  {
    for(int i=0; i<wpList.size(); i++)
    {
      float distanceWaypoint = calculateDistance(lat, lon, wpList.get(0).getlat(), wpList.get(0).getlon());
      tempdist = (int) distanceWaypoint + tempdist;
      float groundSpeed = calculateGroundSpeed(lat, lon, prevLat, prevLon, prevTime, millis());
      float esttime = distanceWaypoint / groundSpeed; // time in second
      fill(0);
      stroke(65,105,225);
      rect(1750, 40, 150, 120);
      fill(0);
      stroke(0);
      rect(1750, 0, 150, 35);
      strokeWeight(3);
      fill(255);
      text("WP" + i + " lat: " + wpList.get(i).getlat() + " lon: " + wpList.get(i).getlon() , 800,(i+1)*70);
      
      text(" flightinformation: " , 1750, 30);
      text(" wp dist: " + (int)distanceWaypoint + " m", 1750, 60);
      text(" tot. dist: " + (int)tempdist + " m", 1750, 90);
      text(" speed: " + (int)groundSpeed + " m/s", 1750, 120);
      text(" est. time: " + (int)esttime + " s", 1750, 150);
      
      if (i > 0 && i < actualTimes.size()) {
        long timeTaken = actualTimes.get(i); // Zeit in Sekunden
        fill(0);
        stroke(0);
        rect(1750, 170, 150, 15);
        fill(255);
        text(" time taken: " + timeTaken + " s", 1750, 180);
      }
    }
  }
  
  for (int i = 0; i < wpList.size(); i++) {
    if (i == currentWaypointIndex) {
      wpList.get(i).cross(true);
    } else {
      wpList.get(i).cross(false);
    }
  }
  
  for (int i = 1; i < wpList.size(); i++) {
    line(wpList.get(i-1).getx(), wpList.get(i-1).gety(), wpList.get(i).getx(), wpList.get(i).gety());
  }
  
  int temptime = 0;
  float dist_sum = 0.0;
  for(int j= 0;j<legList.size(); j++) {  
     temptime = (int) (legList.get(j).getEstTime()) + temptime;
     dist_sum += legList.get(j).getdist();
     fill(255);
     text("dist: " + (int) (legList.get(j).getdist()+0.5) +"m" + "    rwK: " + (int)(legList.get(j).getrwk()+0.5) +"°" + "    luv: " + (float)(legList.get(j).getluv() * RAD_TO_DEG + 0.5) + "°" + "     est. time: " + (int) (legList.get(j).getEstTime()) + "s" + "     tot. est. time: " + temptime + "s" +"     WD/WV: " + WD + "°" + "/" + WV +"m/s" +"     time: " + (int) ((legList.get(j).getdist() / (legList.get(j).gettas()))+0.5) + "s" + "     accdist: " + (int)(dist_sum+0.5)+ "m", 850, 35+(j+1)*70);
  }
  
  
  // Update previous values
  prevLat = lat;
  prevLon = lon;
  prevTime = millis();
}

void mousePressed() {
  if(mouseButton == LEFT) {
    wpList.add( new waypoint((float) mouseX, (float) mouseY));
    if(wpList.size() > 1) {
        legList.add( new leg(wpList.get(wpList.size()-2), wpList.get(wpList.size()-1)));
    }
  }
}

void receiveData() {
  /*
  byte[] buffer = new byte[1024]; // Puffer für empfangene Daten (größer, um JSON-Daten aufzunehmen)
  DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
  try {
    socket.receive(packet); // Empfange das UDP-Paket
    String json = new String(packet.getData(), 0, packet.getLength(), StandardCharsets.UTF_8);
    println("Received JSON data: " + json); // Debugging-Ausgabe der empfangenen JSON-Daten
    JSONObject data = JSONObject.parse(json); // Deserialisiere die JSON-Daten in ein JSONObject
    lat = data.getFloat("lat");
    lon = data.getFloat("lon");
    alt = data.getFloat("alt");
    pitch = data.getFloat("pitch");
    roll = data.getFloat("roll");
    yaw = data.getFloat("yaw");
    println("Received data: " + lat + ", " + lon + ", " + alt + ", " + pitch + ", " + roll + ", yaw);
  } catch (IOException e) {
    e.printStackTrace();
  }
  */
  
  lat = coordinate(48, i, 0.1);
  if(i >= 47){
    i = i + 0.01;
  }else{
    i = i + 0.01;
  }
  delay(20);
  lon = coordinate(11, 40, 0.1);
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
  float R = 6371.0; // Radius der Erde in Kilometern
  float dLat = radians(lat2 - lat1);
  float dLon = radians(lon2 - lon1);
  float a = sin(dLat / 2) * sin(dLat / 2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  float c = 2 * atan2(sqrt(a), sqrt(1 - a));
  float distance = R * c;
  return distance * 1000; // convert to meters
}

float calculateGroundSpeed(float lat1, float lon1, float lat2, float lon2, long time1, long time2) {
  float distance = calculateDistance(lat1, lon1, lat2, lon2);
  float timeElapsed = (time2 - time1) / 1000.0; // Zeit in Sekunden
  float speed = distance / timeElapsed; // Geschwindigkeit in m/s
  return speed;
}



kannst du den code übersichtlicher machen 
das draw schön aufräumen
