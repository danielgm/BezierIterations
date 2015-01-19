

import java.util.LinkedList;
import java.util.Queue;

PImage inputImg, outputImg;
int outputScale;
ArrayList<int[]> sources;

FileNamer folderNamer, fileNamer;

void setup() {
  size(500, 405);
  frameRate(10);

  outputScale = 4;
  sources = new ArrayList<int[]>();
  sources.add(point(62, 51));

  folderNamer = new FileNamer("output/export", "/");

  reset();
  redraw();
}

void draw() {}

void reset() {
  inputImg = loadImage("assets/test.png");
  outputImg = createImage(
    inputImg.width * outputScale,
    inputImg.height * outputScale, RGB);

  fileNamer = new FileNamer(folderNamer.next() + "frame", "gif");
}

void redraw() {
  background(128);
  step();
  image(outputImg, 2, 2);
}

void step() {
  float score;

  int w = inputImg.width;
  int h = inputImg.height;

  drawSources(inputImg, sources);
  unvisitPixels(inputImg);
  traversePixels(inputImg, sources.get(0));

  score = getDissipationScore(inputImg, sources.get(0));
  println(score);

  ArrayList<int[]> expandables = getExpandablePixels(inputImg);
  for (int[] p : expandables) {
    //px(inputImg, p, color(255, 255, 0));
  }

  int[] newPixel = expandables.get(randi(expandables.size()));
  px(inputImg, newPixel, color(0));
  unvisitPixels(inputImg);
  traversePixels(inputImg, sources.get(0));

  score = getDissipationScore(inputImg, sources.get(0));
  println(score);

  for (int x = 0; x < outputImg.width; x++) {
    for (int y = 0; y < outputImg.height; y++) {
      px(outputImg, x, y, px(inputImg, floor(x/outputScale), floor(y/outputScale)));
    }
  }
  outputImg.updatePixels();
}

void drawSources(PImage img, ArrayList<int[]> sources) {
  for (int[] p : sources) {
    px(img, p[0], p[1], color(255, 0, 0));
  }
}

void unvisitPixels(PImage img) {
  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    if (red(img.pixels[i]) < 255) {
      img.pixels[i] = color(0, 0, 255);
    }
  }
}

// Traverse from the given source and return any potential new pixels.
void traversePixels(PImage img, int[] source) {
  Queue<int[]> brink = new LinkedList<int[]>();
  brink.add(source);
  ArrayList<int[]> newPixels;
  while (brink.size() > 0) {
    int[] curr = brink.poll();
    newPixels = traversePixel(img, curr);
    for (int i = 0; i < newPixels.size(); i++) {
      brink.add(newPixels.get(i));
    }
  }
}

// Traverse the given pixel and return any new pixels to add to the brink. Add
// expandable pixels to the expandables array.
ArrayList<int[]> traversePixel(PImage img, int[] p) {
  ArrayList<int[]> neighbors = getNeighbors(img, p);
  ArrayList<int[]> visitedNeighbors = filterVisited(img, neighbors);
  if (visitedNeighbors.size() > 0) {
    int[] q = getMostEnergeticPixel(img, visitedNeighbors);
    px(img, p, color(red(px(img, q)) - 1, 0, 0));
  }
  else {
    //px(img, p, color(254, 0, 0));
  }

  return filterUnvisited(img, neighbors);
}

ArrayList<int[]> getNeighbors(PImage img, int[] p) {
  ArrayList<int[]> neighbors = new ArrayList<int[]>();
  for (int x = p[0] - 1; x <= p[0] + 1; x++) {
    if (x < 0 || x >= img.width) continue;
    for (int y = p[1] - 1; y <= p[1] + 1; y++) {
      if (y < 0 || y >= img.height) continue;
      if (x == p[0] && y == p[1]) continue;
      neighbors.add(point(x, y));
    }
  }
  return neighbors;
}

int[] getMostEnergeticPixel(PImage img, ArrayList<int[]> points) {
  int[] mostEnergeticPixel = null;
  int energy, highestEnergy = 0;
  for (int[] p : points) {
    energy = getPixelEnergy(img, p);
    if (energy > highestEnergy) {
      mostEnergeticPixel = p;
      highestEnergy = energy;
    }
  }
  return mostEnergeticPixel;
}

int getPixelEnergy(PImage img, int[] p) {
  return floor(red(px(img, p)));
}

ArrayList<int[]> getExpandablePixels(PImage img) {
  // FIXME: Fetching expandable pixels needs to be done on a per-source basis.
  ArrayList<int[]> expandables = new ArrayList<int[]>();
  color c = color(255);
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      if (px(img, x, y) == c) {
        int[] p = point(x, y);
        ArrayList<int[]> neighbors = getNeighbors(img, p);
        if (filterUnexpandable(img, neighbors).size() > 0) {
          expandables.add(p);
        }
      }
    }
  }
  return expandables;
}

float getDissipationScore(PImage img, int[] source) {
  // FIXME: Calculating dissipation score needs to be done on a per-source basis.
  color c = color(255);
  float score = 0;
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      if (px(img, x, y) != c) {
        int[] p = point(x, y);
        ArrayList<int[]> neighbors = getNeighbors(img, p);
        score += red(px(img, p)) * filterExpandable(img, neighbors).size();
      }
    }
  }
  return score;
}

ArrayList<int[]> filterVisited(PImage img, ArrayList<int[]> points) {
  ArrayList<int[]> result = new ArrayList<int[]>();
  color c;
  for (int[] p : points) {
    c = px(img, p);
    if (red(c) > 0 && green(c) == 0 && blue(c) == 0) {
      result.add(p);
    }
  }
  return result;
}

ArrayList<int[]> filterUnvisited(PImage img, ArrayList<int[]> points) {
  ArrayList<int[]> result = new ArrayList<int[]>();
  color unvisitedColor = color(0, 0, 255);
  for (int[] p : points) {
    if (px(img, p) == unvisitedColor) {
      result.add(p);
    }
  }
  return result;
}

ArrayList<int[]> filterExpandable(PImage img, ArrayList<int[]> points) {
  ArrayList<int[]> result = new ArrayList<int[]>();
  color expandableColor = color(255);
  for (int[] p : points) {
    if (px(img, p) == expandableColor) {
      result.add(p);
    }
  }
  return result;
}

ArrayList<int[]> filterUnexpandable(PImage img, ArrayList<int[]> points) {
  ArrayList<int[]> result = new ArrayList<int[]>();
  color expandableColor = color(255);
  for (int[] p : points) {
    if (px(img, p) != expandableColor) {
      result.add(p);
    }
  }
  return result;
}

color px(PImage img, int x, int y) {
  return img.pixels[y * img.width + x];
}

color px(PImage img, int[] p) {
  return img.pixels[p[1] * img.width + p[0]];
}

void px(PImage img, int x, int y, color c) {
  if (x < 0 || x >= width || y < 0 || y >= height) return;
  img.pixels[y * img.width + x] = c;
}

void px(PImage img, int[] p, color c) {
  if (p[0] < 0 || p[0] >= width || p[1] < 0 || p[1] >= height) return;
  img.pixels[p[1] * img.width + p[0]] = c;
}

int[] point(int x, int y) {
  int[] p = new int[2];
  p[0] = x;
  p[1] = y;
  return p;
}

float randf(float max) {
  return random(max);
}

float randf(float min, float max) {
  return min + random(1) * (max - min);
}

int randi(int max) {
  return floor(random(max));
}

int randi(int min, int max) {
  return floor(min + random(1) * (max - min));
}

void keyReleased() {
  switch (key) {
    case 'e':
      reset();
      redraw();
      break;
    case ' ':
      step();
      redraw();
      break;
    case 'r':
      inputImg.save(fileNamer.next());
      break;
  }
}
