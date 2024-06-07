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
int EARTH_RADIUS = 6371;

void setup() {
  size(400,400);
  try {
    socket = new DatagramSocket(5000); // Erstelle einen UDP-Socket, der auf Port 5000 lauscht
  } catch (SocketException e) {
    e.printStackTrace();
  }
}

void draw() {
  receiveData();
  push();
  fontBold = createFont("Arial-Bold", 17);
  commandorinstrument();
  degreeCalc();
  pop();
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
  push();
  centerX = width /2;
  centerY = height /2;
  numpoints = 5;  
  hSpace = (width/2 - 50) / numpoints;
  vSpace = (width/2 - 50) / numpoints;
  arc(200, 200, 400, 400, 0, PI*2, OPEN);
  fill(200);
  
  for(int i = - numpoints; i <= numpoints; i++) {
    push();
    float x= centerX + i * hSpace;
    ellipse(x, centerY, 5, 5);
    pop();
  }
  
  for(int i = - numpoints; i <= numpoints; i++) {
    push();
    float y = centerY + i * vSpace;
    ellipse(centerX, y, 5, 5);
    pop();
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
  pop();
}


void hline(float lineHeight)
{
  push();
  float lineLength = 150; 
   //hoizontale Linie
  float y = map(lineHeight, 0, 0.72, centerY, centerY + hSpace  + 120);
  stroke(0); 
  strokeWeight(4);
  line(centerX - lineLength/2, y, centerX + lineLength/2, y); 
  
  pop();
}

void vline(float linePosition)
{
  push();
  float lineLength = 150; 
  //vertikale Linie
  float x = map(linePosition, 0, 2.5, centerX, centerX + vSpace + 119);
  stroke(0); 
  strokeWeight(4);
  line(x, centerY - lineLength/2, x, centerY + lineLength/2); 
  pop();
}

float coordinate(float deg, float min, float sec) {
  float decimal = deg + (min / 60) + (sec / 3600);
  return decimal;
}

float calculateDistance(float lat1, float lon1, float lat2, float lon2) {
    float lat1Rad = lat1 * DEG_TO_RAD;
    float lat2Rad = lat2 * DEG_TO_RAD;
    float lon1Rad = lon1 * DEG_TO_RAD;
    float lon2Rad = lon2 * DEG_TO_RAD;

    float x = (lon2Rad - lon1Rad) * cos((lat1Rad + lat2Rad) / 2);
    float y = (lat2Rad - lat1Rad);
    float distance = sqrt(x * x + y * y) * EARTH_RADIUS;

    return distance;
}


void degreeCalc()
{
  float distthreedegree = calculateDistance(coordinate(48, 42, 51.76), coordinate(11, 33, 20.84), coordinate(48, 44, 44.81), coordinate(11, 40, 30.29));
  float distplane = calculateDistance(coordinate(48, 42, 51.76), coordinate(11, 33, 20.84), lat, lon);
  
  float heightVADAN = 0.5172456; //in km
  float degree1h = tan( heightVADAN / distthreedegree) * RAD_TO_DEG;
  float degree2h = (tan(((alt -367.978570) / 1000.0) / abs(distplane)) * RAD_TO_DEG) - degree1h ;
  println("Hoehe: " + (alt / 1000.0) + " Dist: " + distplane);
  println("Akt. Winkelh: " + round(degree2h * 1000) / 1000.0 + " Ref. Winkelv: " + degree1h);
  hline(max(-0.72, min(0.72, degree2h)));
 

  
  /***********************************************************************/
   float deltaLatP = abs(coordinate(48, 42, 51.76) - lat);
   float deltaLonP = abs(coordinate(11, 33, 20.84) - lon) * cos(lat);
   float degree1v = tan(deltaLatP / deltaLonP);
   
   float deltaLatS = abs(coordinate(48, 42, 51.76) - coordinate(48, 44, 44.81));
   float deltaLonS = abs(coordinate(11, 33, 20.84) - coordinate(11, 40, 30.29)) * cos(coordinate(48, 44, 44.81));
   float degree2v = tan(deltaLatS / deltaLonS);
   
   float degreeV = (degree1v - degree2v) * RAD_TO_DEG; 
  
   println("Akt. Winkelv: " + round(degree1v * 1000) / 1000.0);
   vline(degreeV);
}
