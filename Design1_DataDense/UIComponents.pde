// ============================================================
// UIComponents.pde  —  Design 1 (Data-Dense Dark Theme)
// Custom Components:
//   1. SliderComponent
//   2. DashboardButton
//   3. LiveBarGraph
//   4. ProgressRing
//   5. HeartRateGraph (scrolling waveform)
//   6. WatchFace (smartwatch UI sub-component)
// ============================================================

// ---- Shared palette refs (must match main sketch) ----
// BG PANEL ACCENT TEXT DIM GREEN BLUE RED YELLOW

// ============================================================
// 1. SliderComponent
// ============================================================
class SliderComponent {
  float x, y, w, h;
  float minVal, maxVal, value;
  boolean dragging = false;
  String label;
  color accent;

  SliderComponent(float x, float y, float w, float h,
                  float mn, float mx, float val, String lbl, color acc) {
    this.x=x; this.y=y; this.w=w; this.h=h;
    minVal=mn; maxVal=mx; value=val; label=lbl; accent=acc;
  }

  void draw() {
    // Track
    fill(#3D444D); noStroke(); rect(x, y+h/2-4, w, 8, 4);
    // Fill
    float fw = map(value, minVal, maxVal, 0, w);
    fill(accent); rect(x, y+h/2-4, fw, 8, 4);
    // Thumb
    float tx = x+fw;
    fill(dragging ? lerpColor(accent,#FFFFFF,0.3f) : accent);
    noStroke(); ellipse(tx, y+h/2, 20, 20);
    // Value label on thumb
    fill(#FFFFFF); textSize(9); textAlign(CENTER);
    text(nf(value,0,0), tx, y+h/2+4);
    // Range labels
    fill(#8B949E); textSize(10);
    textAlign(LEFT);  text(label + ": " + nf(minVal,0,0), x, y+h+14);
    textAlign(RIGHT); text(nf(maxVal,0,0), x+w, y+h+14);
  }

  void tryDrag(float mx, float my) {
    float tx = x + map(value, minVal, maxVal, 0, w);
    if (dist(mx,my,tx,y+h/2) < 14) dragging=true;
  }
  void drag(float mx) {
    if (dragging) value = constrain(map(mx,x,x+w,minVal,maxVal),minVal,maxVal);
  }
  void release() { dragging=false; }
  float getValue() { return value; }
}

// ============================================================
// 2. DashboardButton
// ============================================================
class DashboardButton {
  float x, y, w, h;
  String label;
  color bg, fg;
  boolean hovered;

  DashboardButton(float x, float y, float w, float h, String lbl, color bg, color fg) {
    this.x=x; this.y=y; this.w=w; this.h=h; label=lbl; this.bg=bg; this.fg=fg;
  }

  void draw() {
    hovered = mouseX>=x && mouseX<=x+w && mouseY>=y && mouseY<=y+h;
    color c = hovered ? lerpColor(bg,#FFFFFF,0.18f) : bg;
    fill(c); noStroke(); rect(x,y,w,h,10);
    fill(fg); textSize(13); textAlign(CENTER);
    text(label, x+w/2, y+h/2+5);
  }

  boolean clicked(float mx, float my) {
    return mx>=x && mx<=x+w && my>=y && my<=y+h;
  }
}

// ============================================================
// 3. LiveBarGraph
// ============================================================
class LiveBarGraph {
  float x, y, w, h;
  float[] values;
  String[] labels;
  color[] colors;
  float[] maxVals;
  String title;

  LiveBarGraph(float x, float y, float w, float h, String title,
               String[] lbl, color[] col, float[] maxV) {
    this.x=x; this.y=y; this.w=w; this.h=h; this.title=title;
    labels=lbl; colors=col; maxVals=maxV;
    values = new float[lbl.length];
  }

  void setValues(float[] v) { values=v; }

  void draw() {
    fill(#161B22); noStroke(); rect(x,y,w,h,8);
    fill(#8B949E); textSize(10); textAlign(LEFT);
    text(title, x+8, y+14);

    int n = values.length;
    float bw = (w-20) / n - 5;
    for (int i=0; i<n; i++) {
      float bh = map(min(values[i], maxVals[i]), 0, maxVals[i], 0, h-32);
      float bx = x+10 + i*(bw+5);
      float by = y+h-18-bh;
      // Bar
      fill(colors[i]); noStroke(); rect(bx, by, bw, bh, 3);
      fill(#E6EDF3); textSize(9); textAlign(CENTER);
      text(nf(values[i],0,0), bx+bw/2, by-3);
      // Label
      text(labels[i], bx+bw/2, y+h-4);
    }
  }
}

// ============================================================
// 4. ProgressRing
// ============================================================
class ProgressRing {
  float x, y, r;
  float progress;
  color ringCol, bgCol;
  String centerLabel, subLabel;

  ProgressRing(float x, float y, float r, color rc, color bg) {
    this.x=x; this.y=y; this.r=r;
    ringCol=rc; bgCol=bg; progress=0;
  }

  void set(float p, String lbl, String sub) {
    progress=constrain(p,0,1); centerLabel=lbl; subLabel=sub;
  }

  void draw() {
    noFill(); stroke(bgCol); strokeWeight(9);
    ellipse(x,y,r*2,r*2);
    stroke(ringCol); strokeWeight(9);
    arc(x,y,r*2,r*2,-HALF_PI,-HALF_PI+TWO_PI*progress);
    noStroke();
    text(centerLabel, x, y+5);
    fill(#8B949E); textSize(9);
    text(subLabel, x, y+18);
  }
}

// ============================================================
// 5. HeartRateGraph (scrolling ECG-style waveform)
// ============================================================
class HeartRateGraph {
  float x, y, w, h;
  float[] hrHistory;
  int histLen = 120;
  int ptr = 0;
  color lineCol;
  String title;

  HeartRateGraph(float x, float y, float w, float h, String title, color c) {
    this.x=x; this.y=y; this.w=w; this.h=h; this.title=title; lineCol=c;
    hrHistory = new float[histLen];
    for (int i=0; i<histLen; i++) hrHistory[i]=72;
  }

  void addValue(float hr) {
    hrHistory[ptr % histLen] = hr;
    ptr++;
  }

  void draw() {
    fill(#0D1117); noStroke(); rect(x,y,w,h,6);
    fill(#8B949E); textSize(10); textAlign(LEFT);
    text(title, x+6, y+13);

    float minHR=40, maxHR=200;
    stroke(lineCol); strokeWeight(1.5); noFill();
    beginShape();
    for (int i=0; i<histLen; i++) {
      int idx = (ptr+i) % histLen;
      float sx = x + map(i, 0, histLen, 0, w);
      float sy = y + map(hrHistory[idx], minHR, maxHR, h-10, 18);
      vertex(sx, sy);
    }
    endShape();
    noStroke();

    float cur = hrHistory[(ptr-1+histLen)%histLen];
    fill(lineCol); textSize(12); textAlign(RIGHT);
    text(nf(cur,0,0)+" BPM", x+w-6, y+13);

    stroke(#3D444D,80); strokeWeight(1);
    for (float hr=80; hr<=160; hr+=40) {
      float gy = y + map(hr, minHR, maxHR, h-10, 18);
      line(x, gy, x+w, gy);
    }
    noStroke();
  }
}

// ============================================================
// 6. WatchFace — smartwatch sub-panel
// ============================================================
class WatchFace {
  float x, y, sz;

  WatchFace(float x, float y, float sz) { this.x=x; this.y=y; this.sz=sz; }

  void draw(float hr, float cals, String act, int timerSec) {
    // Watch body
    fill(#1C2128); stroke(#3D444D); strokeWeight(2);
    rect(x, y, sz, sz*1.2, sz*0.22);
    noStroke();

    // Watch band stubs
    fill(#0D1117);
    rect(x+sz*0.2, y-12, sz*0.6, 14, 4);
    float cx = x+sz/2, cy = y+sz*0.6;

    // HR value
    fill(#F85149); textSize(sz*0.18); textAlign(CENTER);
    text(nf(hr,0,0), cx, cy-sz*0.04);
    fill(#8B949E); textSize(sz*0.09);
    text("BPM", cx, cy+sz*0.08);

    // Activity label
    fill(#58A6FF); textSize(sz*0.1); textAlign(CENTER);
    text(act, cx, y+sz*0.18);

    // Timer
    fill(#E6EDF3); textSize(sz*0.12); textAlign(CENTER);
    text(formatTime(timerSec), cx, y+sz*1.08);

    // Cals
    fill(#D29922); textSize(sz*0.09); textAlign(CENTER);
    text(nf(cals,0,0)+" kcal", cx, y+sz*0.95);
  }
}
