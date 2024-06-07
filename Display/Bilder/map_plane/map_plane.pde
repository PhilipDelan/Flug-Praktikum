import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import processing.data.JSONObject; // Importiere die JSONObject-Klasse von Processing
import java.util.ArrayList;

PImage imgMap;
PImage imgPlane;
DatagramSocket socket;


float lat, lon, alt, pitch, roll, yaw;
ArrayList<PathStruct> flightpath = new ArrayList<PathStruct>();


class PathStruct {
    float lat, lon;
    PathStruct(float lat, float lon){
      this.lat = lat;
      this.lon = lon;
    }
}



void setup() {
  size(734, 733);
  imgMap = loadImage("1_1_AIP_VFR.png"); // Karte laden
  imgPlane = loadImage("Flugzeug.png"); // Flugzeugbild laden
  try {
    socket = new DatagramSocket(5000); // Erstelle einen UDP-Socket, der auf Port 5000 lauscht
  } catch (SocketException e) {
    e.printStackTrace();
  }
}

void draw() {
  image(imgMap, 0, 0);
  receiveData();
  geoToPixel(lat, lon, yaw);  // Nutze die aktualisierten Koordinaten und die Rotation
  pathAdd(lat,lon);
  path();
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
}

void geoToPixel(float lat, float lon, float rot) {
  float x = map(lon, 11.333333, 11.733333, 24, 710);
  float y = map(lat, 48.866667, 48.600000, 24, 710);
  move(x, y, rot);
}

void pathAdd(float lat, float lon)
{
  flightpath.add(new PathStruct(lat,lon));
 
}

void path()
{
  stroke(255,0,0);
  strokeWeight(5);
  noFill();
  beginShape();
  for(PathStruct point : flightpath)
  {
    vertex(point.lat, point.lon);
  }
  endShape(); 
}

void move(float x, float y, float rot) {
  translate(x, y);
  rotate(rot * DEG_TO_RAD);
  image(imgPlane, -imgPlane.width / 24, -imgPlane.height / 24, imgPlane.width / 12, imgPlane.height / 12);
}

float coordinate(float deg, float min, float sec) {
  float decimal = deg + (min / 60) + (sec / 3600);
  return decimal;
}
