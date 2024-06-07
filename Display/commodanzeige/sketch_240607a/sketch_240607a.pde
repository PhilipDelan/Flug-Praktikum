import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import processing.data.JSONObject; // Importiere die JSONObject-Klasse von Processing
import java.util.ArrayList;

PFont fontBold;
DatagramSocket socket;


float lat, lon, alt, pitch, roll, yaw;
float centerX, centerY, hSpace, vSpace;
int numpoints;

void setup() {
  size(400,400);
  fontBold = createFont("Arial-Bold", 17);
  commandorinstrument();
  
  try {
    socket = new DatagramSocket(5000); // Erstelle einen UDP-Socket, der auf Port 5000 lauscht
  } catch (SocketException e) {
    e.printStackTrace();
  }
}

void draw() {
  receiveData();
  lines(-0.72, 2.5);
  //float dist = calculateDistance(coordinate(48, 42, 51.76), coordinate(11, 33, 20.84), coordinate(48, 44, 44.81), coordinate(411, 40, 30.29));
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


void commandorinstrument()
{
  centerX = width /2;
  centerY = height /2;
  numpoints = 5;  
  hSpace = (width/2 - 50) / numpoints;
  vSpace = (width/2 - 50) / numpoints;
  arc(200, 200, 400, 400, 0, PI*2, OPEN);
  fill(200);
  
  for(int i = - numpoints; i <= numpoints; i++) {
    float x= centerX + i * hSpace;
    ellipse(x, centerY, 5, 5);
  }
  
  for(int i = - numpoints; i <= numpoints; i++) {
    float y = centerY + i * vSpace;
    ellipse(centerX, y, 5, 5);
  }
  
  if(true)
  {
  fill(255,0,0);
  rect(centerX + (centerX / 2) - 46 , centerY - (centerY / 2) + 50, 50 , 20);
  fill(0);
  fontBold = createFont("Arial-Bold", 16);
  textFont(fontBold);
  text("INOP", centerX + (centerX / 2) - 40, centerY - (centerY / 2) + 66);
  }
}
/*
void geoToPixel(float lat, float lon, float rot) {
  float x = map(lon, 11.333333, 11.733333, 24, 710);
  float y = map(lat, 48.866667, 48.600000, 24, 710);
  move(x, y, rot);+
}

void move(float x, float y, float rot) {
  translate(x, y);
  rotate(rot * DEG_TO_RAD);
  image(imgPlane, -imgPlane.width / 24, -imgPlane.height / 24, imgPlane.width / 12, imgPlane.height / 12);
}
*/


void lines(float lineHeight, float linePosition)
{
  float lineLength = 150; 
   //hoizontale Linie
  float y = map(lineHeight, 0, 0.72, centerY, centerY + hSpace  + 120);
  stroke(0); 
  strokeWeight(4);
  line(centerX - lineLength/2, y, centerX + lineLength/2, y); 
  
  //vertikale Linie
  float x = map(linePosition, 0, 2.5, centerX, centerX + vSpace + 119);
  stroke(0); 
  strokeWeight(4);
  line(x, centerY - lineLength/2, x, centerY + lineLength/2); 
}

float coordinate(float deg, float min, float sec) {
  float decimal = deg + (min / 60) + (sec / 3600);
  return decimal;
}

float calculateDistance(float lat1, float lon1, float lat2, float lon2) {
    float lat1Rad = Math.toRadians(lat1);
    float lat2Rad = Math.toRadians(lat2);
    float lon1Rad = Math.toRadians(lon1);
    float lon2Rad = Math.toRadians(lon2);

    float x = (lon2Rad - lon1Rad) * Math.cos((lat1Rad + lat2Rad) / 2);
    float y = (lat2Rad - lat1Rad);
    float distance = Math.sqrt(x * x + y * y) * EARTH_RADIUS;

    return distance;
}
