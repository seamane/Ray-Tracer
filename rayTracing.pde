VectorOrPoint camera;
VectorOrPoint currentPixel;
VectorOrPoint dirLight;
VectorOrPoint pointLight;
Color dirLightColor;
ArrayList<Sphere> spheres;
ArrayList<Color> colors;
int ny;
int nx;
double halfSide;
double pixelSize;
Color ambientColor;

void setup()
{
  size(450, 450, P3D); //size of screen
  camera = new VectorOrPoint(0,0,0,1);
  dirLight = new VectorOrPoint(1,1,-1,0);
  dirLight.normalize();
  dirLightColor = new Color(111,111,111);
  pointLight = new VectorOrPoint(5,5,0,1);
  double d = 10.0;// distance to camera
  float viewingAngle = PI/3;
  nx = 450;//number of pixels in x direction
  ny = 450;//number of pixels in y direction
  halfSide = tan(viewingAngle/2);//length of half of the screen width/height
  pixelSize = (halfSide*2)/450;//distance between pixels
  currentPixel = new VectorOrPoint(-halfSide+(pixelSize/2),halfSide-(pixelSize/2),1,1);//position of top left pixel
  spheres = new ArrayList();
  spheres.add(new Sphere(new VectorOrPoint(0,0,10,1),2.0, new Color(246, 225, 65)));
  spheres.add(new Sphere(new VectorOrPoint(-3,2,14,1),4.0, new Color(200, 2, 6)));
  spheres.add(new Sphere(new VectorOrPoint(1,5,9,1),1.0, new Color(1, 225, 65)));
  colors = new ArrayList();
  ambientColor = new Color(111,111,111);
}

double intersect(VectorOrPoint Ro, VectorOrPoint Rd, Sphere s)
{
  VectorOrPoint Sc = s.getCenter();
  double radius = s.getRadius();
  
  VectorOrPoint OC = Sc.subtract(Ro);
  double OCMagnitude = OC.magnitude();
  
  double Tca = OC.dotProduct(Rd);
  
  double Thc = radius*radius - OCMagnitude*OCMagnitude + Tca*Tca;
  if(Thc >= 0)
  {
    Thc = Math.sqrt(Thc);
  }
  else
  {
    return 2000001; 
  }
  
  double t = Tca - Math.abs(Thc);
  if(t < 0)//is the intersection behind Ro?
  {
     return 2000001; 
  }
  
  VectorOrPoint intersection = Ro.add(Rd.multiply(t));
  return intersection.subtract(Ro).magnitude();
}

Color illumination(Sphere s, VectorOrPoint poi, VectorOrPoint Rd)
{
  VectorOrPoint pointNormal = poi.subtract(s.getCenter());
  pointNormal.normalize();
  VectorOrPoint lightNormal = pointLight.subtract(poi);
  lightNormal.normalize();
  double max = max(0.0,(float)pointNormal.dotProduct(lightNormal));
  int r = (int)(((s.reflectiveColor.r/255.0)*((ambientColor.r/255.0)+(dirLightColor.r/255.0)*max))*255);
  int g = (int)(((s.reflectiveColor.g/255.0)*((ambientColor.g/255.0)+(dirLightColor.g/255.0)*max))*255);
  int b = (int)(((s.reflectiveColor.b/255.0)*((ambientColor.b/255.0)+(dirLightColor.b/255.0)*max))*255);
  Color toReturn = new Color(r,g,b);
  return toReturn;
}

color averageColor()
{
  float r = 0.0;
  float g = 0.0;
  float b = 0.0;
  for(int i = 0; i < colors.size(); ++i)
  {
    r += colors.get(i).r;
    g += colors.get(i).g;
    b += colors.get(i).b;
  }
  
  r /= colors.size();
  g /= colors.size();
  b /= colors.size();
  
  return color(r,g,b);
}

void traceRayPixel(double x, double y)
{
  traceRayCamera(x,y,camera.x,camera.y);
  traceRayCamera(x,y,camera.x+pixelSize*2,camera.y+pixelSize*2);
  traceRayCamera(x,y,camera.x+pixelSize*2,camera.y-pixelSize*2);
  traceRayCamera(x,y,camera.x-pixelSize*2,camera.y-pixelSize*2);
  traceRayCamera(x,y,camera.x-pixelSize*2,camera.y+pixelSize*2);
}

void traceRayCamera(double px, double py, double cx, double cy)
{
  VectorOrPoint tempPixel = new VectorOrPoint(px,py,currentPixel.z,currentPixel.w);
  VectorOrPoint cameraPoint = new VectorOrPoint(cx,cy,camera.z,camera.w);
  VectorOrPoint rayDirection = tempPixel.subtract(cameraPoint);
  rayDirection.normalize();
  double nearestIntersection = 2000000;
  Sphere sphereHit = null;
  
  for(Sphere s: spheres)
  {
    double n = intersect(cameraPoint,rayDirection,s);
    if(n < nearestIntersection)
    {
      nearestIntersection = n;
      sphereHit = s;
    }
  }
  if(sphereHit == null)
  {
    colors.add(new Color(122,122,122));
  }
  else
  {
    VectorOrPoint pointOfIntersection = cameraPoint.add(rayDirection.multiply(nearestIntersection));
//    colors.add(illumination(sphereHit,pointOfIntersection,rayDirection));
    VectorOrPoint rayDirection2 = pointLight.subtract(pointOfIntersection);
    rayDirection2.normalize();
    nearestIntersection = 2000000;
    Sphere sphereHit2 = null;
    for(Sphere s: spheres)
    {
      if(s != sphereHit)
      {
        double n = intersect(pointOfIntersection,rayDirection2,s);
        if(n < nearestIntersection)
        {
          nearestIntersection = n;
          sphereHit2 = s;
        }
      }
    }
    if(sphereHit2 == null)
    {
      colors.add(illumination(sphereHit,pointOfIntersection,rayDirection));
    }
    else
    {
      colors.add(new Color(0,0,0));
    }
  } 
}

void draw()
{
  loadPixels();
  
  currentPixel.x = -halfSide+(pixelSize/2);
  currentPixel.y = halfSide-(pixelSize/2);

  for(int i = 0; i < ny; ++i)
  {
    if(i != 0)
    {
      currentPixel.x = -halfSide+(pixelSize/2);
      currentPixel.y -= pixelSize;
    }
    for(int j = 0; j < nx; ++j)
    {
      colors.clear();
      if(j != 0)
      {
        currentPixel.x += pixelSize;
      }
      
      traceRayPixel(currentPixel.x,currentPixel.y);
      traceRayPixel(currentPixel.x+(pixelSize/4.0),currentPixel.y+(pixelSize/4.0));
      traceRayPixel(currentPixel.x+(pixelSize/4.0),currentPixel.y-(pixelSize/4.0));
      traceRayPixel(currentPixel.x-(pixelSize/4.0),currentPixel.y-(pixelSize/4.0));
      traceRayPixel(currentPixel.x-(pixelSize/4.0),currentPixel.y+(pixelSize/4.0));

      int pixelNumber = (nx*i)+j;
      pixels[pixelNumber] = averageColor();
    } 
  }

  updatePixels();
}

class Color
{
 int r;
 int g;
 int b;
 
 Color(int red, int green, int blue)
 {
  r = red;
  g = green;
  b = blue;
 } 
}

class Sphere
{
  VectorOrPoint center;
  double radius;
  Color reflectiveColor;
  
  Sphere(VectorOrPoint center, double radius, Color col)
  {
    this.reflectiveColor = col;
    this.radius = radius;
    this.center = center;
  }
  
  VectorOrPoint getCenter()
  {
    return center;
  }
  
  double getRadius()
  {
    return radius;
  }
  
  color getReflectiveColor()
  {
    return color(reflectiveColor.r,reflectiveColor.g,reflectiveColor.b);
  }
}

class VectorOrPoint 
{
  double x;
  double y;
  double z;
  double w;
  
  VectorOrPoint(double x, double y, double z, double w)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }
  
  void homogenize()
  {
    if(isPoint())
    {
      x /= w;
      y /= w;
      z /= w;
      w = 1.0;
    }
  }
  
  boolean isVector()
  {
    return (w == 0.0);
  }
  
  boolean isPoint()
  {
    return (w != 0.0);
  }
  
  void normalize()
  {
    if(isVector())
    {
      double denom = Math.sqrt(x*x + y*y + z*z);
      x /= denom;
      y /= denom;
      z /= denom;
    }
  }
  
  VectorOrPoint crossProductWith(VectorOrPoint other)
  {
    VectorOrPoint result = new VectorOrPoint(0,0,0,0);
    result.x = y*other.z - z*other.y;
    result.y = -(x*other.z - z*other.x);
    result.z = x*other.y - y*other.x;
    return result;
  }
  
  double angleBetween(VectorOrPoint other)
  {
    double result = -1;
    if(isVector())
    {
      result = dotProduct(other);
      result /= (magnitude()*other.magnitude());
      result = Math.acos(result);
    }
    return result;
  }
  
  double dotProduct(VectorOrPoint other)
  {
    return x*other.x + y*other.y + z*other.z;
  }
  
  double magnitude()
  {
    return Math.sqrt(x*x + y*y + z*z);
  }
  
  VectorOrPoint add(VectorOrPoint add)
  {
    if(add == null)
    {
      return this;
    }
    return new VectorOrPoint(x+add.x,y+add.y,z+add.z,w+add.w);
  }
  
  VectorOrPoint subtract(VectorOrPoint sub)
  {
    return new VectorOrPoint(x-sub.x,y-sub.y,z-sub.z,w-sub.w);
  }
  
  VectorOrPoint multiply(double d)
  {
    return new VectorOrPoint(x*d,y*d,z*d,w*d);
  }
}

