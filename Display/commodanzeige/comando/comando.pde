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
float latA = 0; // Breite des Approach Fixes
float lonA = 0; // Länge des Approach Fixes
float latH = 0; // Breite des Flughafens
float lonH = 0; // Länge des Flughafens
float centerX, centerY, hSpace, vSpace;
int numpoints;
int R = 6371;

void setup() {
  size(400,400);
  /*try {
    socket = new DatagramSocket(5000); // Erstelle einen UDP-Socket, der auf Port 5000 lauscht
  } catch (SocketException e) {
    e.printStackTrace();
  }*/
}

void draw() {
  receiveData();
  println(" ");
  println(" ");
  println(" ********************************************************************** ");
  println(" Received data: ");
  println(" lat: " + lat + ", lon: " + lon + ", alt: " + alt );
  println(" pitch: " + pitch + ", roll: " + roll + ", yaw: " + yaw);
  push();
  fontBold = createFont("Arial-Bold", 17);
  commandorinstrument();
  horizontal();
  vertikal();
  pop();
}

void receiveData() {
  /*
  
  byte[] buffer = new byte[1024]; // Puffer für empfangene Daten (größer, um JSON-Daten aufzunehmen)
  DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
  try {
    socket.receive(packet); // Empfange das UDP-Paket
    String json = new String(packet.getData(), 0, packet.getLength(), StandardCharsets.UTF_8);
    //println("Received JSON data: " + json); 
    JSONObject data = JSONObject.parse(json); 
    lat = data.getFloat("lat");
    lon = data.getFloat("lon");
    alt = data.getFloat("alt");
    pitch = data.getFloat("pitch");
    roll = data.getFloat("roll");
    yaw = data.getFloat("yaw");
    println("Received data: ");
    println("lat: " + lat + ", lon: " + lon + ", alt: " + alt + ", pitch: " + pitch + ", roll: " + roll + ", yaw: " + yaw);
  } catch (IOException e) {
    e.printStackTrace();
  }
  */
  //lat = coordinate(48, 45, 0.1);
  //lon = coordinate(11, 39, 0.1);
  lat = coordinate(48, 41, 0.1);
  lon = coordinate(11, 30, 0.1);
  alt = 300;
  pitch = 100;
  roll = 100;
  yaw = 100;
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
  float y = map(lineHeight, 0, 0.72, centerY, centerY + hSpace  * 5);
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
  float x = map(linePosition, 0, 2.5, centerX, centerX + vSpace * 5);
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
    float distance = sqrt(x * x + y * y) * R;

    return distance;
}


void horizontal()
{
  
  println(" --------------------------------Data--------------------------------- ");
  float distThreeDegree = calculateDistance(coordinate(48, 42, 51.76), coordinate(11, 33, 20.84), coordinate(48, 44, 44.81), coordinate(11, 40, 30.29));
  float distPlane = calculateDistance(coordinate(48, 42, 51.76), coordinate(11, 33, 20.84), lat, lon);
  println(" Distance Degree: " + distThreeDegree + "    Distance Plane: " + distPlane);
  
  float heightDegree = 0.5172456; //in km
  float heightPlane = (alt /*-367.978570*/) /1000;
  println(" Height Degree: " + heightDegree + "     Height Plane: " + heightPlane);
  
  float threeDegree = atan( heightDegree / abs(distThreeDegree));
  float degreePlane = atan(heightPlane / abs(distPlane));
  println(" Three Rad: " + degreePlane + "        Plane Rad: " + degreePlane);
  
  threeDegree = threeDegree * RAD_TO_DEG;
  degreePlane = degreePlane * RAD_TO_DEG;
  println(" Three Degree " + threeDegree + "       Plane Degree " + degreePlane);
  
  degreePlane = threeDegree - degreePlane;
  println(" ------------------------------Horizontal------------------------------ ");
  println(" Gleitwinkels: " + degreePlane);
  hline(max(-0.72, min(0.72, degreePlane)));
}  


void vertikal() {
  println(" -------------------------------Vertikal------------------------------- ");
  latH = coordinate(48, 42, 51.76); // Flughafen
  lonH = coordinate(11, 33, 20.84); // Flughafen
  latA = coordinate(48, 44, 44.81); // Approach Fix
  lonA = coordinate(11, 40, 30.29); // Approach Fix

  PVector H = geoToCartesian(latH, lonH);
  PVector A = geoToCartesian(latA, lonA);
  PVector P = geoToCartesian(lat, lon);

  // Vektroen
  PVector v1 = PVector.sub(P, H);
  PVector v2 = PVector.sub(A, H);

  float angle = calculateSignedAngle(v1, v2);
  angle = angle * RAD_TO_DEG;
  println(" Anflugwinkel " + angle);
 
  
  vline(max(-2.5, min(2.5, angle)));
}

//KArtesisches Koordinaten System
PVector geoToCartesian(float latC, float lonC) {
  latC = radians(latC);
  lonC = radians(lonC);
  float x = R * cos(latC) * cos(lonC);
  float y = R * cos(latC) * sin(lonC);
  float z = R * sin(latC);
  return new PVector(x, y, z);
}

float calculateSignedAngle(PVector v1, PVector v2) {
  float dotProduct = v1.dot(v2);
  float magnitudeV1 = v1.mag();
  float magnitudeV2 = v2.mag();
  float angle = acos(dotProduct / (magnitudeV1 * magnitudeV2));

  // Kreuzprodukt
  PVector crossProduct = v1.cross(v2);

  // Vorzeichen
  if (crossProduct.z < 0) {
    angle = -angle;
  }

  return angle;
}
