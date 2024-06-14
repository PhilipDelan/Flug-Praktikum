import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import processing.data.JSONObject; 
import java.util.ArrayList;

PImage imgMap;
PImage imgPlane;
DatagramSocket socket;

float lat, lon, alt, pitch, roll, yaw;
float i = 45;

int maxPoints = 300; 
ArrayList<PVector> points = new ArrayList<PVector>(); 

void setup() {
  size(734, 733);
  imgMap = loadImage("1_1_AIP_VFR.png"); // Karte laden
  imgPlane = loadImage("Flugzeug.png"); // Flugzeugbild laden

  try {
    socket = new DatagramSocket(5000);
  } catch (SocketException e) {
    e.printStackTrace();
  }
}

void draw() {
  image(imgMap, 0, 0);
  receiveData();
  geoToPixel(lat, lon, yaw);  

  // Punkte
  for (PVector point : points) {
    fill(255, 0, 0); 
    stroke(255, 0, 0); 
    ellipse(point.x, point.y, 4, 4); 
  }
}

void receiveData() {
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
    println("Received data: " + lat + ", " + lon + ", " + alt + ", " + pitch + ", " + roll + ", " + yaw);
  } catch (IOException e) {
    e.printStackTrace();
  }
  /*
  lat = coordinate(48, i, 0.1);
  //i = i + 0.01;
  if(i >= 47){
    i = i + 0.01;
  }else{;
    i = i + 0.01;
  }
  //delay(300);
  lon = coordinate(11, 40, 0.1);
  */
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
