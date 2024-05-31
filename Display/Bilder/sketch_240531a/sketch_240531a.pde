import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

PImage imgMap;
PImage imgPlane;
DatagramSocket socket;

float lat, lon, alt, pitch, roll, yaw;

void setup() {
  size(734, 733);
  imgMap = loadImage("1_1_AIP_VFR.png"); // Load the map image into the program
  imgPlane = loadImage("Flugzeug.png"); // Load the plane image into the program
  try {
    socket = new DatagramSocket(5000); // Create a UDP socket to listen on port 5000
  } catch (SocketException e) {
    e.printStackTrace();
  }
}

void draw() {
  image(imgMap, 0, 0);
  receiveData();
  geoToPixel(lat, lon, yaw);  // Use the updated coordinates and rotation
}

void receiveData() {
  byte[] buffer = new byte[48]; // 6 double values, each 8 bytes
  DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
  try {
    socket.receive(packet); // Receive the UDP packet
    ByteBuffer bb = ByteBuffer.wrap(packet.getData());
    bb.order(ByteOrder.BIG_ENDIAN); // Ensure the correct byte order
    lat = (float) bb.getDouble();
    lon = (float) bb.getDouble();
    alt = (float) bb.getDouble();
    pitch = (float) bb.getDouble();
    roll = (float) bb.getDouble();
    yaw = (float) bb.getDouble();
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

void move(float x, float y, float rot) {
  translate(x, y);
  rotate(rot * DEG_TO_RAD);
  image(imgPlane, -imgPlane.width / 24, -imgPlane.height / 24, imgPlane.width / 12, imgPlane.height / 12);
}

float coordinate(float deg, float min, float sec) {
  float decimal = deg + (min / 60) + (sec / 3600);
  return decimal;
}
