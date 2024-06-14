PImage img;
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
float WV = 10.0 * 1852.0 / 3600.0; //10
float luv;

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
   
   void cross()
   {
      stroke(255,0,0);
      strokeWeight(3);
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
   
  float getluv()
  {
    float TAS = gettas();
    float RWK = getrwk();
    float beta = WD - rwk; //durch Scheitelwinkel/Gegenwinkel
  
    luv = asin((WV * sin(beta * DEG_TO_RAD)) / TAS);
    println(luv * RAD_TO_DEG);
    return luv;
  }
  
  float getgamma(){
    float TAS = gettas();
    float RWK = getrwk();
    float beta = WD - rwk; //durch Scheitelwinkel/Gegenwinkel
    float luv = getluv();
  
    return (DEG_TO_RAD * 180) - (luv + beta) ;
  }
  
  float getGroundSpeed() {
    float TAS = gettas();
    float RWK = getrwk();
    float beta = WD - rwk; //durch Scheitelwinkel/Gegenwinkel
    float luv = getluv();
    //println(beta * RAD_TO_DEG);
    //println(luv * RAD_TO_DEG);
    float gamma = getgamma();
    float GS = sqrt(sq(WV) + sq(TAS) - 2 * WV * TAS * cos(gamma));
    println("GS: " + GS);
    return GS;
  }
}


ArrayList<waypoint> wpList = new ArrayList<waypoint>();

ArrayList<leg> legList = new ArrayList<leg>();

void setup() {
  size(1920,738);
  img = loadImage("Karte.jpg");
  stroke(255);
}



void draw() {
  background(0);
  image(img, 0, 0);
  textSize(15);
  for(int i=0; i<wpList.size(); i++)
  {
    text("WP" + i + "   lat:" + wpList.get(i).getlat() + "   lon:" + wpList.get(i).getlon(), 800,(i+1)*70);
  }
  
  if(wpList.size() > 0)
  {
    wpList.get(0).cross();
  }
  
  for (int i = 1; i<wpList.size(); i++) 
  {
    (wpList.get(i)).cross();
    line(wpList.get(i-1).getx(), wpList.get(i-1).gety(), wpList.get(i).getx(), wpList.get(i).gety());
  }
  float dist_sum =0.0;
  for(int j= 0;j<legList.size(); j++)
  {
     dist_sum += legList.get(j).getdist();
     text("dist: " + (int) (legList.get(j).getdist()+0.5) +"m" + "    rwK: " + (int)(legList.get(j).getrwk()+0.5) +"°" + "    luv: " + (int)(legList.get(j).getluv() * RAD_TO_DEG + 0.5) + "°" + "     WD/WV: " + WD + "°" + "/" + WV +"m/s" + "     time: " + (int) ((legList.get(j).getdist() / (legList.get(j).gettas()))+0.5) + "s" + "     accdist:" + (int)(dist_sum+0.5)+ "m", 850, 35+(j+1)*70);
  }
}


void mousePressed() {
  if(mouseButton == LEFT)
  {
    wpList.add( new waypoint((float) mouseX, (float) mouseY));
    if(wpList.size() > 1)
    {
        legList.add( new leg(wpList.get(wpList.size()-2), wpList.get(wpList.size()-1)));
    }
  }
}
