// ============================================================
// UIComponents.pde  —  Design 2 (Minimalist Light Theme)
// Custom Components:
//   1. MetricCard        (large single-stat card)
//   2. PulseButton       (animated round button)
//   3. MinimalSlider     (thin pill slider)
//   4. ActivityPill      (rounded label badge)
//   5. MinimalWatchFace  (clean circular watch UI)
//   6. MinimalBarChart   (horizontal bar chart)
// ============================================================

// ---- Palette refs ----
// BG2 CARD ACCENT2 TXT2 GRAY2 LGRAY

// ============================================================
// 1. MetricCard
// ============================================================
class MetricCard {
  float x, y, w, h;
  String label, unit;
  color accent;
  String value = "0";
  float animVal = 0;

  MetricCard(float x, float y, float w, float h,
             String label, String unit, color accent) {
    this.x=x; this.y=y; this.w=w; this.h=h;
    this.label=label; this.unit=unit; this.accent=accent;
  }

  void setValue(String v) { value=v; }

  void draw() {
    // Drop shadow
    fill(0,0,0,18); noStroke(); rect(x+3,y+3,w,h,18);
    // Card
    fill(#FFFFFF); noStroke(); rect(x,y,w,h,18);
    // Accent top strip
    fill(accent); rect(x,y,w,6,3,3,0,0);
    // Label
    fill(#8892A4); textSize(10); textAlign(LEFT);
    text(label.toUpperCase(), x+14,y+24);
    // Value
    fill(#1A1A2E); textSize(40); textAlign(LEFT);
    text(value, x+14, y+80);
    // Unit
    fill(#8892A4); textSize(12); textAlign(LEFT);
    text(unit, x+14, y+100);
    // Accent circle decoration
    fill(lerpColor(accent,#FFFFFF,0.8f)); noStroke();
    ellipse(x+w-26, y+30, 42, 42);
    fill(accent); textSize(18); textAlign(CENTER);
    text("●", x+w-26, y+36);
  }
}

// ============================================================
// 2. PulseButton
// ============================================================
class PulseButton {
  float x, y, r;
  String label;
  color bg;
  float pulse=0;

  PulseButton(float x, float y, float r, String label, color bg) {
    this.x=x; this.y=y; this.r=r; this.label=label; this.bg=bg;
  }

  void draw() {
    pulse += 0.06;
    float p = abs(sin(pulse));
    // Outer pulse rings
    noFill();
    stroke(lerpColor(bg,#FFFFFF,0.55f)); strokeWeight(2);
    ellipse(x,y, r*2+28+p*22, r*2+28+p*22);
    stroke(lerpColor(bg,#FFFFFF,0.25f)); strokeWeight(1.5);
    ellipse(x,y, r*2+52+p*14, r*2+52+p*14);
    noStroke();
    // Button
    fill(bg); ellipse(x,y,r*2,r*2);
    // Inner highlight
    fill(255,255,255,50); ellipse(x,y-r*0.15,r*1.3,r*0.7);
    fill(#FFFFFF); textSize(15); textAlign(CENTER); text(label,x,y+5);
  }

  boolean isClicked(float mx, float my) { return dist(mx,my,x,y)<r; }
}

// ============================================================
// 3. MinimalSlider
// ============================================================
class MinimalSlider {
  float x, y, w, h;
  float minVal, maxVal, value;
  boolean dragging=false;
  String label;
  color accent;

  MinimalSlider(float x, float y, float w, float h,
                float mn, float mx, float val, String lbl, color acc) {
    this.x=x; this.y=y; this.w=w; this.h=h;
    minVal=mn; maxVal=mx; value=val; label=lbl; accent=acc;
  }

  void draw() {
    // Track
    fill(#E8ECF0); noStroke(); rect(x,y+h/2-3,w,6,3);
    // Fill
    float fw = map(value,minVal,maxVal,0,w);
    fill(accent); rect(x,y+h/2-3,fw,6,3);
    // Thumb
    float tx=x+fw;
    fill(dragging?lerpColor(accent,#000000,0.1f):accent);
    noStroke(); ellipse(tx,y+h/2,20,20);
    fill(#FFFFFF); textSize(9); textAlign(CENTER); text(nf(value,0,1),tx,y+h/2+4);
    // Label
    fill(#8892A4); textSize(10); textAlign(LEFT); text(label,x,y+h+14);
    textAlign(RIGHT); text(nf(maxVal,0,0),x+w,y+h+14);
  }

  void tryDrag(float mx,float my) {
    float tx=x+map(value,minVal,maxVal,0,w);
    if(dist(mx,my,tx,y+h/2)<13) dragging=true;
  }
  void drag(float mx) {
    if(dragging) value=constrain(map(mx,x,x+w,minVal,maxVal),minVal,maxVal);
  }
  void release() { dragging=false; }
  float getValue() { return value; }
}

// ============================================================
// 4. ActivityPill
// ============================================================
class ActivityPill {
  float x, y;
  String label;
  color bg, fg;
  float w;

  ActivityPill(float x, float y) { this.x=x; this.y=y; }

  void set(String lbl, color b, color f) {
    label=lbl; bg=b; fg=f;
    textSize(11);
    w=textWidth(lbl)+24;
  }

  void draw() {
    fill(bg); noStroke(); rect(x-w/2,y-14,w,24,12);
    fill(fg); textSize(11); textAlign(CENTER); text(label,x,y+1);
  }
}

// ============================================================
// 5. MinimalWatchFace
// ============================================================
class MinimalWatchFace {
  float x, y, sz;
  float pulsePhase=0;

  MinimalWatchFace(float x, float y, float sz) { this.x=x; this.y=y; this.sz=sz; }

  void draw(float hr, float cals, String act, int timerSec) {
    pulsePhase += 0.04;

    float watchW = sz * 1.02;
    float watchH = sz * 1.34;
    float cx = x + watchW * 0.5;

    // Body + crown
    fill(#090B10); stroke(#3B404A); strokeWeight(2.2);
    rect(x, y, watchW, watchH, watchW*0.25);
    noStroke();
    fill(#1B202A); rect(x+watchW+2, y+watchH*0.44, 6, watchH*0.14, 3);

    // Straps
    fill(#171C26);
    rect(x+watchW*0.24, y-12, watchW*0.52, 14, 5);
    rect(x+watchW*0.24, y+watchH-2, watchW*0.52, 14, 5);

    // Header label
    fill(#89FF2E); textSize(sz*0.10); textAlign(CENTER);
    text("WORKOUT VIEWS", cx, y + watchH*0.16);

    // Inner metrics card
    float cardX = x + watchW*0.16;
    float cardY = y + watchH*0.24;
    float cardW = watchW*0.68;
    float cardH = watchH*0.58;
    fill(#13161D); stroke(#5E6472); strokeWeight(1.4);
    rect(cardX, cardY, cardW, cardH, 18);
    noStroke();

    // Activity icon bubble
    fill(#1F3D1F); ellipse(cardX+18, cardY+16, 24, 24);
    fill(#89FF2E); textSize(13); textAlign(CENTER);
    text("R", cardX+18, cardY+20);

    // Timer
    fill(#FFD94A); textSize(sz*0.17); textAlign(LEFT);
    text(formatTime(timerSec), cardX+12, cardY+42);

    // HR
    fill(#FFFFFF); textSize(sz*0.15);
    text(nf(hr,0,0), cardX+12, cardY+66);
    fill(#FF3B30); textSize(sz*0.08);
    text("HR", cardX+44, cardY+64);

    // Pace / average pace style lines
    fill(#C4CAD4); textSize(sz*0.09);
    text("9'00\"  ROLLING", cardX+12, cardY+86);
    text("9'00\"  AVERAGE", cardX+12, cardY+102);
    text(nf(max(0.1, cals/20.0),0,2)+" MI", cardX+12, cardY+118);

    // Bottom activity + calories
    fill(#9BA5B3); textSize(sz*0.08); textAlign(CENTER);
    text(act.toUpperCase(), cx, y + watchH*0.88);
    fill(#F7B500); textSize(sz*0.09);
    text(nf(cals,0,2)+" kcal", cx, y + watchH*0.95);
  }
}

// ============================================================
// 6. MinimalBarChart (horizontal)
// ============================================================
class MinimalBarChart {
  float x, y, w, h;
  String[] labels;
  float[] values;
  float[] maxVals;
  color[] colors;
  String title;

  MinimalBarChart(float x,float y,float w,float h,String title,
                  String[] lbl,float[] mv,color[] col) {
    this.x=x;this.y=y;this.w=w;this.h=h;this.title=title;
    labels=lbl;maxVals=mv;colors=col;
    values=new float[lbl.length];
  }

  void setValues(float[] v){values=v;}

  void draw(){
    fill(#FFFFFF); noStroke(); rect(x,y,w,h,14);
    fill(#8892A4); textSize(10); textAlign(LEFT); text(title,x+12,y+16);
    float bh=14;
    float vspace=(h-30)/max(1,labels.length);
    for(int i=0;i<labels.length;i++){
      float by=y+22+i*vspace;
      // Track
      fill(#E8ECF0); noStroke(); rect(x+80,by,w-100,bh,7);
      // Fill
      float fw=map(min(values[i],maxVals[i]),0,maxVals[i],0,w-100);
      fill(colors[i]); rect(x+80,by,fw,bh,7);
      // Label
      fill(#1A1A2E); textSize(10); textAlign(RIGHT); text(labels[i],x+74,by+11);
      // Value
      fill(colors[i]); textAlign(LEFT); text(nf(values[i],0,0),x+84+fw,by+11);
    }
  }
}
