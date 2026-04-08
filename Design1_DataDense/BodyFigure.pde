// ============================================================
// BodyFigure.pde
// 3-Level Inheritance + Abstract Class + Interface
//
// Interface:    Animatable
// Abstract:     BodyPart       (grandparent)
// Parents:      TorsoSegment, LimbSegment
// Children:     Head, Chest, Pelvis, Arm, Forearm, Hand,
//               UpperLeg, LowerLeg, Foot
// Composed by:  HumanoidFigure (the full character)
// ============================================================

// ---- FSM States (shared enum) ----
// Activity states drive body animation AND metric simulation
String[] ACTIVITY_NAMES = {
  "Idle", "Walking", "Jogging", "Running", "Jumping", "Squats", "Push-Ups", "Recovery"
};
final int ACT_IDLE=0, ACT_WALK=1, ACT_JOG=2, ACT_RUN=3,
          ACT_JUMP=4, ACT_SQUAT=5, ACT_PUSHUP=6, ACT_RECOVER=7;

// ---- App FSM States ----
final int ST_START=0, ST_SIM=1, ST_END=2;

// ============================================================
// INTERFACE — Animatable
// ============================================================
interface Animatable {
  void update(float phase);  // advance internal animation
  void resetPose();          // snap to neutral
}

// ============================================================
// ABSTRACT GRANDPARENT — BodyPart
// ============================================================
abstract class BodyPart implements Animatable {
  float px, py;       // position relative to figure root
  float angle;        // current rotation (radians)
  color col;
  boolean highlighted;
  String partName;

  BodyPart(float px, float py, color col, String name) {
    this.px=px; this.py=py; this.col=col;
    this.angle=0; this.highlighted=false; this.partName=name;
  }

  // Abstract — subclasses decide their shape
  abstract void drawShape();

  // Concrete shared method: wrap drawShape in transform
  void draw() {
    pushMatrix();
    translate(px, py);
    rotate(angle);
    if (highlighted) {
      stroke(255,255,100); strokeWeight(2);
    } else {
      noStroke();
    }
    drawShape();
    if (highlighted) drawNameTag();
    noStroke();
    popMatrix();
  }

  void drawNameTag() {
    fill(255,255,100,200); textSize(8); textAlign(CENTER);
    text(partName, 0, -22);
  }

  void highlight(boolean h) { highlighted=h; }

  // Default Animatable implementations (children may override)
  void update(float phase) {}
  void resetPose() { angle=0; }
}

// ============================================================
// PARENT A — TorsoSegment
// ============================================================
class TorsoSegment extends BodyPart {
  float w, h;
  color conditionCol;  // changes with workout intensity

  TorsoSegment(float px, float py, float w, float h, color col, String name) {
    super(px, py, col, name);
    this.w=w; this.h=h; conditionCol=col;
  }

  void setCondition(color c) { conditionCol=c; }

  void drawShape() {
    color hi = lerpColor(conditionCol, #FFFFFF, 0.22f);
    color lo = lerpColor(conditionCol, #000000, 0.24f);
    fill(lo);
    rect(-w*0.48, -h*0.52, w*0.96, h*1.02, w*0.22);
    fill(hi);
    rect(-w*0.42, -h*0.50, w*0.84, h*0.36, w*0.18);
    fill(conditionCol);
    rect(-w*0.44, -h*0.18, w*0.88, h*0.62, w*0.18);
    fill(lerpColor(conditionCol, #000000, 0.35f));
    ellipse(-w*0.33, -h*0.52, w*0.30, w*0.30);
    ellipse( w*0.33, -h*0.52, w*0.30, w*0.30);
  }
}

// ============================================================
// PARENT B — LimbSegment
// ============================================================
class LimbSegment extends BodyPart {
  float len, thick;
  boolean mirrored;
  float pivotAngle; // extra bend for elbow/knee

  LimbSegment(float px, float py, float len, float thick, color col, String name, boolean mirrored) {
    super(px, py, col, name);
    this.len=len; this.thick=thick; this.mirrored=mirrored; this.pivotAngle=0;
  }

  void drawShape() {
    float tTop = thick*0.88;
    float tBottom = thick*1.05;
    fill(col);
    beginShape();
    vertex(-tTop*0.5, 0);
    vertex( tTop*0.5, 0);
    vertex( tBottom*0.5, len);
    vertex(-tBottom*0.5, len);
    endShape(CLOSE);
    fill(lerpColor(col, #000000, 0.22f));
    ellipse(0, 0, thick*1.2, thick*1.2);
  }

  void update(float phase) {
    // mirrored limbs swing opposite phase
  }
}

// ============================================================
// CHILDREN of TorsoSegment
// ============================================================
class Head extends TorsoSegment {
  float bobPhase=0;
  Head(float px, float py) {
    super(px, py, 28, 32, #F4C2A1, "Head");
  }
  void drawShape() {
    fill(#E6B58F);
    ellipse(0, 0, 28, 32);
    fill(#F7D0AE);
    ellipse(0, -4, 24, 22);
    // eyes
    fill(highlighted ? #FF4444 : #2C2C2C);
    ellipse(-6, -5, 4, 4);
    ellipse( 6, -5, 4, 4);
    // pupils
    fill(#FFFFFF); ellipse(-5,-6,1.5,1.5); ellipse(7,-6,1.5,1.5);
    // mouth
    noFill(); stroke(#A0522D); strokeWeight(1.5);
    arc(0, 4, 10, 6, 0.1, PI-0.1);
    noStroke();
  }
  void update(float phase) {
    bobPhase = phase;
    py = -104 + sin(phase)*2;
  }
}

class Chest extends TorsoSegment {
  Chest(float px, float py) { super(px,py, 46, 52, #4A90D9, "Chest"); }
}

class Pelvis extends TorsoSegment {
  Pelvis(float px, float py) { super(px,py, 40, 24, #3A7AC0, "Pelvis"); }
}

// ============================================================
// CHILDREN of LimbSegment
// ============================================================
class UpperArm extends LimbSegment {
  UpperArm(float px, float py, boolean m) {
    super(px,py, 32, 11, #F4C2A1, m?"L-UpperArm":"R-UpperArm", m);
  }
}
class Forearm extends LimbSegment {
  Forearm(float px, float py, boolean m) {
    super(px,py, 30, 9, #E8B89A, m?"L-Forearm":"R-Forearm", m);
  }
}
class Hand extends BodyPart {
  Hand(float px, float py) { super(px,py, #F4C2A1, "Hand"); }
  void drawShape() {
    fill(col); ellipse(0,0,14,16);
    stroke(lerpColor(col,#000000,0.3f)); strokeWeight(1.5);
    for (int i=-2;i<=2;i++) line(i*2,-7,i*2,-13);
    noStroke();
  }
  void update(float p){}
  void resetPose(){}
}
class UpperLeg extends LimbSegment {
  UpperLeg(float px, float py, boolean m) {
    super(px,py, 46, 14, #3A6EA8, m?"L-Thigh":"R-Thigh", m);
  }
}
class LowerLeg extends LimbSegment {
  LowerLeg(float px, float py, boolean m) {
    super(px,py, 44, 12, #2E5A8E, m?"L-Shin":"R-Shin", m);
  }
}
class Foot extends BodyPart {
  boolean mirrored;
  Foot(float px, float py, boolean m) {
    super(px,py, #1E3F6E, m?"L-Foot":"R-Foot");
    mirrored=m;
  }
  void drawShape() {
    fill(col);
    rect(mirrored?-18:2, -5, 20, 11, 5);
  }
  void update(float p){}
  void resetPose(){}
}

// ============================================================
// HumanoidFigure — composes all body parts
// Uses StackManager push/pop for 2D transformation stack
// ============================================================
class HumanoidFigure {
  float x, y;        // world position (used for movement log)
  float vx, vy;      // velocity
  int   activityState;
  float animPhase;
  float animSpeed;
  StackManager transformStack;

  // All parts
  Head     head;
  Chest    chest;
  Pelvis   pelvis;
  UpperArm rUA, lUA;
  Forearm  rFA, lFA;
  Hand     rH, lH;
  UpperLeg rUL, lUL;
  LowerLeg rLL, lLL;
  Foot     rF, lF;

  // Highlight state
  boolean showLabels = false;

  HumanoidFigure(float x, float y) {
    this.x=x; this.y=y;
    activityState=ACT_IDLE;
    animPhase=0; animSpeed=0.04;
    transformStack = new StackManager();
    buildParts();
  }

  void buildParts() {
    head   = new Head(0, -112);
    chest  = new Chest(0, -72);
    pelvis = new Pelvis(0, -30);
    rUA = new UpperArm( 27, -86, false);
    lUA = new UpperArm(-27, -86, true);
    rFA = new Forearm(  27, -54, false);
    lFA = new Forearm( -27, -54, true);
    rH  = new Hand(    30, -18);
    lH  = new Hand(   -30, -18);
    rUL = new UpperLeg( 12, -18, false);
    lUL = new UpperLeg(-12, -18, true);
    rLL = new LowerLeg( 12,  28, false);
    lLL = new LowerLeg(-12,  28, true);
    rF  = new Foot(     10,  72, false);
    lF  = new Foot(    -10,  72, true);
  }

  void setActivity(int a) {
    if (a != activityState) {
      transformStack.push("→"+ACTIVITY_NAMES[a]);
      activityState=a;
    }
  }

  void update() {
    animPhase += animSpeed;

    // Update speed based on activity
    switch(activityState) {
      case ACT_IDLE:    animSpeed=0.02; break;
      case ACT_WALK:    animSpeed=0.05; break;
      case ACT_JOG:     animSpeed=0.08; break;
      case ACT_RUN:     animSpeed=0.12; break;
      case ACT_JUMP:    animSpeed=0.10; break;
      case ACT_SQUAT:   animSpeed=0.04; break;
      case ACT_PUSHUP:  animSpeed=0.05; break;
      case ACT_RECOVER: animSpeed=0.02; break;
    }
    head.update(animPhase);
  }

  void draw() {
    update();
    pushMatrix();
    translate(x, y);

    applyPose();

    // Draw order: legs back, torso, arms, head front
    rUL.draw(); lUL.draw();
    rLL.draw(); lLL.draw();
    rF.draw();  lF.draw();
    pelvis.draw();
    chest.draw();
    rUA.draw(); lUA.draw();
    rFA.draw(); lFA.draw();
    rH.draw();  lH.draw();
    head.draw();

    popMatrix();
  }

  // ---- Pose logic per activity ----
  void applyPose() {
    float s = sin(animPhase);
    float c = cos(animPhase);
    float absS = abs(s);

    // Reset torso
    chest.angle=0;
    pelvis.angle=0;
    chest.setCondition(#4A90D9);

    // Body-bob offset and segment controls
    float bob = 0;
    float rUAa=0, lUAa=0, rFArel=0, lFArel=0;
    float rULa=0, lULa=0, rLLrel=0, lLLrel=0;
    float torsoLean=0;

    switch(activityState) {
      case ACT_IDLE:
        rUAa = 0.16 + s*0.03;
        lUAa =-0.16 - s*0.03;
        rULa = 0.05;
        lULa =-0.05;
        rLLrel = 0.04;
        lLLrel = 0.04;
        break;

      case ACT_WALK:
        bob = absS * 3.2;
        rUAa =-0.35*s;   lUAa = 0.35*s;
        rFArel = 0.18 + max(0, s*0.12);
        lFArel = 0.18 + max(0,-s*0.12);
        rULa = 0.34*c;    lULa =-0.34*c;
        rLLrel = 0.22 + max(0,-c*0.30);
        lLLrel = 0.22 + max(0, c*0.30);
        chest.setCondition(#4A90D9);
        break;

      case ACT_JOG:
        bob = absS * 5.0;
        rUAa =-0.55*s;    lUAa = 0.55*s;
        rFArel = 0.30 + max(0.06, s*0.20);
        lFArel = 0.30 + max(0.06,-s*0.20);
        rULa = 0.54*c;    lULa =-0.54*c;
        rLLrel = 0.30 + max(0,-c*0.42);
        lLLrel = 0.30 + max(0, c*0.42);
        chest.setCondition(#F39C12);
        break;

      case ACT_RUN:
        bob = absS * 5.8;
        torsoLean = 0.07;
        rUAa =-0.72*s - 0.12;   lUAa = 0.72*s - 0.12;
        rFArel = 0.52 + max(0, s*0.16);
        lFArel = 0.52 + max(0,-s*0.16);
        rULa = 0.76*c - 0.06;   lULa =-0.76*c - 0.06;
        rLLrel = 0.38 + max(0,-c*0.52);
        lLLrel = 0.38 + max(0, c*0.52);
        chest.setCondition(#E74C3C);
        break;

      case ACT_JUMP:
        float t = (sin(animPhase)+1)/2;
        bob = -sin(animPhase*0.5)*30;
        rUA.angle =-PI/4 - t*PI/4;
        lUA.angle = PI/4 + t*PI/4;
        rUL.angle = t*0.7;  lUL.angle =-t*0.7;
        rLL.angle = t*0.9;  lLL.angle = t*0.9;
        chest.setCondition(#E74C3C);
        break;

      case ACT_SQUAT:
        float sq = (sin(animPhase)+1)/2;
        rUAa = 0.08;  lUAa =-0.08;
        rFArel = 0.52; lFArel = 0.52;
        rULa = 0.22 + sq*0.40;
        lULa =-0.22 - sq*0.40;
        rLLrel = 0.62 + sq*0.34;
        lLLrel = 0.62 + sq*0.34;
        bob = sq * 20;
        chest.setCondition(#9B59B6);
        break;

      case ACT_PUSHUP:
        float pu = (sin(animPhase)+1)/2;
        rUA.angle =-PI/2 + pu*0.2;  lUA.angle = PI/2 - pu*0.2;
        rFA.angle = PI/3 + pu*0.2;  lFA.angle =-PI/3 - pu*0.2;
        rUL.angle = 0.05; lUL.angle=-0.05;
        bob = 25 + pu*18;
        chest.angle = -0.08;
        chest.setCondition(#8E44AD);
        break;

      case ACT_RECOVER:
        rUAa = 0.2 + s*0.05;
        lUAa =-0.2 - s*0.05;
        rULa = 0.1; lULa=-0.1;
        rLLrel = 0.08; lLLrel = 0.08;
        chest.setCondition(#27AE60);
        break;
    }

    // Apply torso offsets
    float bv = -bob;
    chest.py  = -72 + bv;
    pelvis.py = -30 + bv;
    chest.angle = torsoLean;
    head.py   = -112 + bv;

    // Base joints
    float shoulderY = -86 + bv;
    float hipY = -18 + bv;
    rUA.px = 24;  rUA.py = shoulderY;
    lUA.px = -24; lUA.py = shoulderY;
    rUL.px = 11;  rUL.py = hipY;
    lUL.px = -11; lUL.py = hipY;

    // Resolve chained angles in world-space
    rUA.angle = rUAa;
    lUA.angle = lUAa;
    rFA.angle = rUA.angle + rFArel;
    lFA.angle = lUA.angle - lFArel;
    rUL.angle = rULa;
    lUL.angle = lULa;
    rLL.angle = rUL.angle + rLLrel;
    lLL.angle = lUL.angle + lLLrel;
    rF.angle  = rLL.angle * 0.30;
    lF.angle  = lLL.angle * 0.30;

    // Arm chain
    float rElbowX = rUA.px + sin(rUA.angle) * rUA.len;
    float rElbowY = rUA.py + cos(rUA.angle) * rUA.len;
    float lElbowX = lUA.px + sin(lUA.angle) * lUA.len;
    float lElbowY = lUA.py + cos(lUA.angle) * lUA.len;
    rFA.px = rElbowX; rFA.py = rElbowY;
    lFA.px = lElbowX; lFA.py = lElbowY;

    float rWristX = rFA.px + sin(rFA.angle) * rFA.len;
    float rWristY = rFA.py + cos(rFA.angle) * rFA.len;
    float lWristX = lFA.px + sin(lFA.angle) * lFA.len;
    float lWristY = lFA.py + cos(lFA.angle) * lFA.len;
    rH.px = rWristX; rH.py = rWristY;
    lH.px = lWristX; lH.py = lWristY;
    rH.angle = rFA.angle;
    lH.angle = lFA.angle;

    // Leg chain
    float rKneeX = rUL.px + sin(rUL.angle) * rUL.len;
    float rKneeY = rUL.py + cos(rUL.angle) * rUL.len;
    float lKneeX = lUL.px + sin(lUL.angle) * lUL.len;
    float lKneeY = lUL.py + cos(lUL.angle) * lUL.len;
    rLL.px = rKneeX; rLL.py = rKneeY;
    lLL.px = lKneeX; lLL.py = lKneeY;

    float rAnkleX = rLL.px + sin(rLL.angle) * rLL.len;
    float rAnkleY = rLL.py + cos(rLL.angle) * rLL.len;
    float lAnkleX = lLL.px + sin(lLL.angle) * lLL.len;
    float lAnkleY = lLL.py + cos(lLL.angle) * lLL.len;
    rF.px = rAnkleX; rF.py = rAnkleY;
    lF.px = lAnkleX; lF.py = lAnkleY;
  }

  // Check if mouse is near figure to highlight parts
  void checkHover(float mx, float my, float figX, float figY) {
    BodyPart[] parts = {head, chest, pelvis, rUA, lUA, rUL, lUL};
    for (BodyPart p : parts) {
      float dx = mx - (figX + p.px);
      float dy = my - (figY + p.py);
      p.highlight(sqrt(dx*dx+dy*dy) < 22);
    }
  }
}
