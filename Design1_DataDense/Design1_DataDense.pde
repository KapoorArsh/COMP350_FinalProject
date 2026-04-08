// ============================================================
// Design1_DataDense.pde
// COMP 350 — Team Project: FitTrack Pro
// Design 1: Data-Dense Dashboard (Dark Theme)
// Team: Akshit Jindal · Bhavik Wadhwa · Arsh Kapoor
//
// Layout (width=900):
//   [0–300]  = 3D Simulation panel
//   [300–600]= Phone UI panel
//   [600–900]= Smartwatch + Stats panel
// ============================================================

// ============================================================
// COLOR PALETTE
// ============================================================
color BG     = #0D1117;
color PANEL  = #161B22;
color ACCENT = #FF6B35;
color TEXT   = #E6EDF3;
color DIM    = #8B949E;
color GREEN  = #3FB950;
color BLUE   = #58A6FF;
color RED    = #F85149;
color YELLOW = #D29922;
color PURPLE = #BC8CFF;

// ============================================================
// APP FSM
// 0=START  1=SIMULATION  2=END
// ============================================================
int appState = 0;  // 0=ST_START, 1=ST_SIM, 2=ST_END

// ============================================================
// ACTIVITY FSM (inner state during simulation)
// Idle/Walking/Jogging/Running/Jumping/Squats/Push-Ups/Recovery
// ============================================================
int activityState = 0;  // 0=ACT_IDLE
int prevActivity  = 0;

// ---- activity colors ----
color[] ACT_COLORS = {
  #8B949E,  // Idle
  #3FB950,  // Walk
  #58A6FF,  // Jog
  #FF6B35,  // Run
  #FFD700,  // Jump
  #BC8CFF,  // Squat
  #FF69B4,  // Push-up
  #27AE60   // Recover
};
// ---- calorie rates per second by activity ----
float[] CALORIE_RATE = {0.003, 0.05, 0.09, 0.14, 0.16, 0.12, 0.11, 0.02};
// ---- target HR by activity ----
float[] TARGET_HR    = {68, 95, 120, 155, 160, 140, 130, 80};
// ---- step rate per second by activity ----
float[] STEP_RATE    = {0, 1.2, 2.2, 3.5, 0, 0, 0, 0.3};
// ---- rep rate (reps per 60s) ----
float[] REP_RATE     = {0,0,0,0,30,25,20,0};

// ============================================================
// SIMULATION DATA
// ============================================================
int   simTimer    = 0;      // seconds elapsed
float simHR       = 72;     // current heart rate
float simCals     = 0;
float simSteps    = 0;
int   simReps     = 0;
float repAccum    = 0;
float stepAccum   = 0;

float noiseHR   = 0;
float noiseStep = 100;

// ============================================================
// CHARACTER POSITION (used for movement logging)
// ============================================================
float charX = 150, charY = 320;
float charVX = 0, charVY = 0;
float charTargetX = 150, charTargetY = 320;
float prevCharX = 150, prevCharY = 320;
int manualOverrideFrames = 0;
int autoCandidateState = 0;
int autoCandidateHoldFrames = 0;

// ============================================================
// HISTORY & MOVEMENT LOG
// ============================================================
ArrayList<WorkoutRecord> history = new ArrayList<WorkoutRecord>();
ArrayList<MovementLog>   movLog  = new ArrayList<MovementLog>();
WorkoutSession currentSession = null;

// ============================================================
// UI COMPONENT INSTANCES
// ============================================================
HumanoidFigure figure;
SliderComponent sensitivitySlider;
LiveBarGraph    liveGraph;
ProgressRing    calorieRing, hrRing;
HeartRateGraph  hrGraph;
WatchFace       watchFace;
DashboardButton[] activityBtns;
DashboardButton   btnStart, btnEnd, btnRestart, btnHistory;
StackManager    gestureStack;

// ---- History scroll ----
int histScroll = 0;
boolean showHistory = false;
boolean showSortedView = false;
ArrayList<WorkoutRecord> sortedHistory;
int searchResultIdx = -1;

// ---- Environment dots (noise-driven background) ----
float[] envX = new float[12];
float[] envY = new float[12];
float[] envN = new float[12];

// ============================================================
// SETUP
// ============================================================
void setup() {
  size(900, 660);
  frameRate(30);
  textFont(createFont("Arial", 13));

  figure = new HumanoidFigure(charX, charY);
  gestureStack = new StackManager();

  // Sliders
  sensitivitySlider = new SliderComponent(
    310, 600, 275, 20, 0.5, 3.0, 1.0, "Sim Speed", ACCENT);

  // Live bar graph — Phone panel (below the phone frame)
  liveGraph = new LiveBarGraph(
    310, 492, 275, 100, "Live Metrics",
    new String[]{"HR","Cals","Steps/10","Reps"},
    new color[]{RED, YELLOW, BLUE, GREEN},
    new float[]{200, 800, 80, 50});

  // Rings — right panel
  calorieRing = new ProgressRing(820, 120, 36, YELLOW, #3D444D);
  hrRing      = new ProgressRing(820, 230, 36, RED,    #3D444D);

  // HR graph — right panel
  hrGraph = new HeartRateGraph(612, 330, 280, 90, "Heart Rate History", RED);

  // Smartwatch
  watchFace = new WatchFace(680, 424, 90);

  // Activity buttons (phone panel, below condition bar)
  String[] aNames = {"Idle","Walk","Jog","Run","Jump","Squat","Push-Up","Recover"};
  activityBtns = new DashboardButton[aNames.length];
  for (int i=0; i<aNames.length; i++) {
    int col = i%2, row = i/2;
    activityBtns[i] = new DashboardButton(
      310 + col*137, 360 + row*28, 128, 24,
      aNames[i], PANEL, ACT_COLORS[i]);
  }

  // Main control buttons
  btnStart   = new DashboardButton(340, 622, 220, 30, "▶  BEGIN SIMULATION", ACCENT,   TEXT);
  btnEnd     = new DashboardButton(30,  612, 240, 40, "■  FINISH & SAVE",  RED,      TEXT);
  btnRestart = new DashboardButton(30,  560, 240, 48, "↺  NEW WORKOUT",    GREEN,    TEXT);
  btnHistory = new DashboardButton(612, 600, 280, 40, "VIEW SORTED HISTORY", PANEL,  BLUE);

  // Environment dots
  for (int i=0; i<12; i++) {
    envX[i] = random(20, 280);
    envY[i] = random(80, 400);
    envN[i] = random(100);
  }

  sortedHistory = new ArrayList<WorkoutRecord>();
}

// ============================================================
// DRAW
// ============================================================
void draw() {
  background(BG);

  switch(appState) {
    case ST_START: drawStartScreen(); break;
    case ST_SIM:   drawSimScreen();   break;
    case ST_END:   drawEndScreen();   break;
  }
}

// ============================================================
// START SCREEN
// ============================================================
void drawStartScreen() {
  // Left panel — hero
  fill(PANEL); noStroke(); rect(0,0,900,660);

  // Animated background circles
  noFill(); stroke(ACCENT,40); strokeWeight(1);
  for (int i=0; i<5; i++) ellipse(450, 330, 120+i*100, 120+i*100);
  noStroke();

  // Title
  fill(ACCENT); textSize(42); textAlign(CENTER);
  text("FitTrack Pro", 450, 180);
  fill(BLUE); textSize(16);
  text("3D Fitness Simulation — Design 1: Data-Dense Dashboard", 450, 215);

  // Body figure preview
  figure.setActivity(ACT_IDLE);
  figure.x = 450; figure.y = 400;
  figure.draw();

  // Feature list
  String[] feats = {
    "✦  Real-time 3D humanoid simulation",
    "✦  Auto-detected workout activity",
    "✦  Phone UI + Smartwatch UI",
    "✦  FSM · Inheritance · Stack · Sort · Search"
  };
  fill(DIM); textSize(13); textAlign(LEFT);
  for (int i=0; i<feats.length; i++) text(feats[i], 240, 480+i*24);

  fill(#1C2128); noStroke(); rect(240, 380, 420, 86, 10);
  fill(TEXT); textSize(11); textAlign(LEFT);
  text("Project Goal: Real-time running simulation with synced phone/watch metrics", 252, 404);
  text("Target Users: Students and casual fitness learners", 252, 426);
  text("Usability Focus: Keyboard-first controls + clear live feedback", 252, 448);

  // Controls hint
  fill(#3D444D); noStroke(); rect(240, 565, 420, 55, 10);
  fill(DIM); textSize(11); textAlign(LEFT);
  text("Keyboard: W=Walk  R=Run  J=Jump  S=Squat  P=Push-Up  Space=Idle", 255, 582);
  text("Mouse: Click activity buttons · Drag slider · Hover figure to label parts", 255, 600);

  // Start button
  btnStart.draw();

  figure.x=150; figure.y=320;
}

// ============================================================
// SIMULATION SCREEN
// ============================================================
void drawSimScreen() {
  // ---- UPDATE ----
  updateSimulation();

  // ============================================================
  // PANEL 1: 3D Simulation Environment (0–300)
  // ============================================================
  drawSimPanel();

  // ============================================================
  // PANEL 2: Phone UI (300–600)
  // ============================================================
  drawPhonePanel();

  // ============================================================
  // PANEL 3: Smartwatch + Stats (600–900)
  // ============================================================
  drawWatchStatsPanel();

  // ---- Bottom Controls ----
  drawBottomControls();
}

// ============================================================
// SIM PANEL (left)
// ============================================================
void drawSimPanel() {
  // Background — simulated "ground"
  fill(#0A0F14); noStroke(); rect(0,0,300,660);

  // Grid floor
  stroke(#1C2128); strokeWeight(1);
  for (int gx=0; gx<300; gx+=30) line(gx,0,gx,660);
  for (int gy=0; gy<660; gy+=30) line(0,gy,300,gy);
  noStroke();

  // Environment noise-driven dots (simulating environment variation)
  for (int i=0; i<envX.length; i++) {
    envN[i] += 0.01;
    float sz = noise(envN[i])*12+4;
    float alpha = noise(envN[i]+50)*180+40;
    fill(BLUE, alpha); noStroke();
    ellipse(envX[i], envY[i], sz, sz);
  }

  // "Ground" line
  fill(#1C2128); noStroke(); rect(0, 430, 300, 8);
  fill(#3D444D); textSize(9); textAlign(CENTER);
  text("SIMULATION ENVIRONMENT", 150, 445);

  // Trajectory trail (movement log dots)
  int trailLen = min(movLog.size(), 30);
  for (int i=0; i<trailLen; i++) {
    MovementLog m = movLog.get(movLog.size()-trailLen+i);
    float alpha = map(i,0,trailLen,20,160);
    fill(ACCENT, alpha); noStroke();
    float sz = map(i,0,trailLen,2,6);
    ellipse(m.x, m.y+330, sz, sz);
  }

  // Character shadow
  fill(0,0,0,100); noStroke(); ellipse(charX, 428, 40, 10);

  // Draw humanoid figure
  figure.x = charX; figure.y = charY;
  figure.checkHover(mouseX, mouseY, charX, charY);
  figure.draw();

  // Activity label above figure
  color ac = ACT_COLORS[activityState];
  fill(PANEL); noStroke(); rect(charX-48, charY-145, 96, 22, 6);
  fill(ac); textSize(11); textAlign(CENTER);
  text(ACTIVITY_NAMES[activityState], charX, charY-130);

  // Panel label
  fill(PANEL); noStroke(); rect(0,0,300,22);
  fill(DIM); textSize(10); textAlign(LEFT);
  text("  3D SIMULATION  |  WASD+Mouse to interact", 0, 16);

  // Coordinate display
  fill(#1C2128); noStroke(); rect(0, 455, 300, 30);
  fill(DIM); textSize(9); textAlign(LEFT);
  text("  POS  X:" + nf(charX,0,0) + "  Y:" + nf(charY,0,0) +
       "  |  LOG: " + movLog.size() + " pts", 0, 474);

  // Gesture stack display
  fill(#1C2128); noStroke(); rect(0,490,300,50);
  fill(DIM); textSize(9); textAlign(LEFT);
  text("  GESTURE STACK:", 4, 506);
  fill(TEXT); textSize(8);
  text("  " + gestureStack.peekAll(4), 4, 520);
  text("  " + figure.transformStack.peekAll(3), 4, 533);

  // Separator
  fill(#3D444D); noStroke(); rect(299,0,2,660);
}

// ============================================================
// PHONE PANEL (middle)
// ============================================================
void drawPhonePanel() {
  // Phone bezel
  fill(#1C2128); noStroke(); rect(300,0,300,660);

  // Phone frame
  fill(#0D0D0D); noStroke(); rect(318, 18, 264, 468, 22);
  fill(PANEL);    rect(326, 30, 248, 444, 18);

  // Notch
  fill(#0D0D0D); noStroke(); rect(390,30,100,18,9);

  // ---- Phone content ----
  // Status bar
  fill(PANEL); noStroke(); rect(326,48,248,18);
  fill(DIM); textSize(8); textAlign(LEFT); text("  9:41 AM", 330, 62);
  textAlign(RIGHT); text("100%  ●●●●  ", 572, 62);

  // App header
  fill(ACCENT); noStroke(); rect(326,66,248,36);
  fill(TEXT); textSize(14); textAlign(LEFT);
  text("  FitTrack Pro", 330, 90);
  fill(lerpColor(TEXT,ACCENT,0.4f)); textSize(9); textAlign(RIGHT);
  text("LIVE ● ", 572, 90);

  // Activity badge
  color ac = ACT_COLORS[activityState];
  fill(ac); noStroke(); rect(326,102,248,30,0,0,0,0);
  fill(#FFFFFF); textSize(13); textAlign(CENTER);
  text(ACTIVITY_NAMES[activityState].toUpperCase(), 450, 123);

  // 4-metric grid
  drawPhoneMetric(326, 132, 124, 70, "❤ Heart Rate",  nf(simHR,0,0),    "BPM",  RED);
  drawPhoneMetric(450, 132, 124, 70, "🔥 Calories",   nf(simCals,0,1),   "kcal", YELLOW);
  drawPhoneMetric(326, 202, 124, 70, "👣 Steps",      nf(simSteps,0,0), "steps",BLUE);
  drawPhoneMetric(450, 202, 124, 70, "💪 Reps",       str(simReps),      "reps", GREEN);

  // Timer
  fill(#0A0F14); noStroke(); rect(326,272,248,44);
  fill(TEXT); textSize(28); textAlign(CENTER);
  text(formatTime(simTimer), 450, 306);
  fill(DIM); textSize(9); text("ELAPSED TIME", 450, 320);

  // Body condition zone bar
  drawConditionBar(326, 320, 248);

  // HR bar graph
  liveGraph.setValues(new float[]{simHR, simCals, simSteps/10, simReps});
  liveGraph.draw();

  // Activity buttons row
  for (DashboardButton b : activityBtns) b.draw();

  // Highlight selected
  int bi = activityState;
  if (bi < activityBtns.length) {
    stroke(ACT_COLORS[bi]); strokeWeight(2); noFill();
    rect(activityBtns[bi].x, activityBtns[bi].y,
         activityBtns[bi].w, activityBtns[bi].h, 10);
    noStroke();
  }

  // Sensitivity slider
  sensitivitySlider.draw();

  // Panel divider
  fill(#3D444D); noStroke(); rect(599,0,2,660);
}

void drawPhoneMetric(float x, float y, float w, float h,
                     String label, String value, String unit, color c) {
  fill(#0A0F14); noStroke(); rect(x,y,w,h);
  fill(c,60); rect(x,y+h-4,w,4);
  fill(DIM); textSize(9); textAlign(LEFT); text(label, x+6, y+16);
  fill(c); textSize(22); textAlign(LEFT); text(value, x+6, y+50);
  fill(DIM); textSize(9); textAlign(LEFT); text(unit, x+6, y+64);
}

void drawConditionBar(float x, float y, float w) {
  fill(DIM); textSize(9); textAlign(LEFT); text("  Zone:", x, y+13);
  String zone; color zc;
  float hrPct = constrain(simHR / 190.0, 0, 1);
  if (hrPct<0.57){zone="Very Light";zc=GREEN;}
  else if(hrPct<0.64){zone="Light";zc=#7ED957;}
  else if(hrPct<0.77){zone="Vigorous";zc=YELLOW;}
  else{zone="High";zc=RED;}
  float pw=80;
  fill(lerpColor(zc,#000000,0.5f)); noStroke(); rect(x+50,y+2,pw,16,8);
  fill(zc); textSize(10); textAlign(CENTER); text(zone, x+50+pw/2, y+14);

  // Zone strip
  noStroke();
  fill(GREEN);  rect(x,y+20,w*0.28,8,4,0,0,4);
  fill(YELLOW); rect(x+w*0.28,y+20,w*0.22,8);
  fill(ACCENT); rect(x+w*0.50,y+20,w*0.22,8);
  fill(RED);    rect(x+w*0.72,y+20,w*0.28,8,0,4,4,0);
  // Needle
  float nx = x + map(simHR,60,200,0,w);
  fill(TEXT); triangle(nx-5,y+28,nx+5,y+28,nx,y+20);
}

// ============================================================
// WATCH + STATS PANEL (right)
// ============================================================
void drawWatchStatsPanel() {
  fill(#0D1117); noStroke(); rect(600,0,300,660);

  // Panel title
  fill(PANEL); noStroke(); rect(600,0,300,22);
  fill(DIM); textSize(10); textAlign(LEFT);
  text("  SMARTWATCH + ANALYTICS", 604, 16);

  // ---- Calorie Ring ----
  calorieRing.set(min(simCals/500.0,1), nf(simCals,0,0), "kcal");
  calorieRing.draw();
  fill(YELLOW); textSize(9); textAlign(CENTER); text("CALORIES", 820, 165);

  // ---- HR Ring ----
  hrRing.set(map(simHR,60,200,0,1), nf(simHR,0,0), "BPM");
  hrRing.draw();
  fill(RED); textSize(9); textAlign(CENTER); text("HEART RATE", 820, 275);

  // ---- HR History Graph ----
  hrGraph.draw();

  // ---- Smartwatch Face ----
  watchFace.draw(simHR, simCals, ACTIVITY_NAMES[activityState], simTimer);

  // ---- Sorted history / search panel ----
  if (showHistory) {
    drawHistoryPanel();
  } else {
    // Default: gesture stack + activity log
    fill(PANEL); noStroke(); rect(612,536,280,58,8);
    fill(DIM); textSize(10); textAlign(LEFT); text("GESTURE LOG:", 620, 552);
    fill(TEXT); textSize(9);
    String[] lines = gestureStack.peekAll(5).split("  ›  ");
    for (int i=0; i<min(lines.length,3); i++)
      text("  " + lines[i], 620, 566+i*18);
  }

  // History / sort button
  btnHistory.draw();
}

void drawHistoryPanel() {
  fill(#0A0F14); noStroke(); rect(612,536,280,62,8);
  fill(BLUE); textSize(10); textAlign(LEFT);
  text("SORTED BY CALORIES:", 620, 552);

  ArrayList<WorkoutRecord> src = showSortedView ? sortedHistory : history;
  int maxShow = min(3, src.size());
  for (int i=0; i<maxShow; i++) {
    WorkoutRecord r = src.get(i);
    fill(i==searchResultIdx ? lerpColor(r.typeColor,#FFFFFF,0.3f) : PANEL);
    noStroke(); rect(612,556+i*24,280,22,4);
    fill(r.typeColor); textSize(9); textAlign(LEFT);
    text(r.type, 618, 572+i*24);
    fill(TEXT);
    text(formatTime(r.duration)+"  "+nf(r.calories,0,0)+"kcal  HR:"+nf(r.avgHR,0,0), 668, 572+i*24);
  }
  if (src.size()==0) {
    fill(DIM); textSize(11); textAlign(CENTER); text("No history yet", 752, 570);
  }
}

// ============================================================
// BOTTOM CONTROLS
// ============================================================
void drawBottomControls() {
  fill(PANEL); noStroke(); rect(0,610,300,50);
  btnEnd.draw();

  // Sim speed label
  fill(DIM); textSize(9); textAlign(LEFT);
  text("  Timer: " + formatTime(simTimer) +
       "  |  Sessions: " + history.size(), 4, 656);
}

// ============================================================
// END SCREEN
// ============================================================
void drawEndScreen() {
  fill(PANEL); noStroke(); rect(0,0,900,660);

  // Header
  fill(ACCENT); noStroke(); rect(0,0,900,80);
  fill(TEXT); textSize(32); textAlign(CENTER);
  text("Workout Complete!", 450, 48);
  fill(lerpColor(TEXT,ACCENT,0.4f)); textSize(14);
  text("Design 1  —  Data-Dense Dashboard", 450, 68);

  if (currentSession != null) {
    // Summary metrics (top row)
    String[] sLabels = {"Activity","Duration","Avg HR","Calories","Steps","Reps"};
    String[] sVals = {
      currentSession.type,
      formatTime(currentSession.duration),
      nf(currentSession.avgHR,0,1)+" BPM",
      nf(currentSession.calories,0,1)+" kcal",
      nf(currentSession.steps,0,0),
      str(currentSession.reps)
    };
    color[] sColors = {ACCENT,BLUE,RED,YELLOW,GREEN,PURPLE};

    for (int i=0; i<6; i++) {
      float bx = 30 + i*142;
      fill(#1C2128); noStroke(); rect(bx,95,132,90,8);
      fill(sColors[i]); textSize(11); textAlign(CENTER); text(sLabels[i], bx+66, 116);
      fill(TEXT); textSize(20); text(sVals[i], bx+66, 148);
    }

    // Body figure end pose
    figure.setActivity(ACT_RECOVER);
    figure.x=450; figure.y=360;
    figure.draw();
    figure.x=150; figure.y=320;
  }

  // Sorted history table
  fill(#1C2128); noStroke(); rect(30,205,840,200,8);
  fill(BLUE); textSize(13); textAlign(LEFT);
  text("Sorted Workout Log (Calories ↓):", 45, 228);
  fill(DIM); textSize(10);
  String[] hdr = {"Rank","Type","Duration","Calories","Steps","Avg HR","Reps"};
  float[] hx = {45,100,200,320,430,540,660};
  for (int i=0; i<hdr.length; i++) { textAlign(LEFT); text(hdr[i], hx[i], 248); }
  fill(#3D444D); rect(30,252,840,1);

  ArrayList<WorkoutRecord> srt = sortByCalories(history);
  for (int i=0; i<min(6,srt.size()); i++) {
    WorkoutRecord r = srt.get(i);
    fill(i%2==0?#1C2128:PANEL); noStroke(); rect(30,256+i*24,840,23);
    fill(TEXT); textSize(10); textAlign(LEFT);
    text("#"+(i+1), hx[0], 272+i*24);
    fill(r.typeColor); text(r.type, hx[1], 272+i*24);
    fill(TEXT);
    text(formatTime(r.duration), hx[2], 272+i*24);
    text(nf(r.calories,0,1), hx[3], 272+i*24);
    text(nf(r.steps,0,0), hx[4], 272+i*24);
    text(nf(r.avgHR,0,1), hx[5], 272+i*24);
    text(str(r.reps), hx[6], 272+i*24);
  }
  if (srt.size()==0) {
    fill(DIM); textSize(12); textAlign(CENTER); text("No previous sessions", 450, 330);
  }

  // Movement log stats
  fill(#1C2128); noStroke(); rect(30,415,840,80,8);
  fill(PURPLE); textSize(12); textAlign(LEFT); text("Movement Log Summary:", 45,438);
  fill(TEXT); textSize(10);
  text("Total coordinates recorded: "+movLog.size(), 45, 458);
  if (movLog.size()>0) {
    MovementLog last = movLog.get(movLog.size()-1);
    text("Last pos: X="+nf(last.x,0,1)+" Y="+nf(last.y,0,1)+
         "  Activity: "+last.activity+"  HR: "+nf(last.hr,0,1), 45, 474);
  }
  // Search result
  int best = searchMaxHR(history);
  if (best>=0) {
    WorkoutRecord br = history.get(best);
    text("Highest HR session: "+br.type+" · "+nf(br.avgHR,0,1)+" BPM · "+nf(br.calories,0,1)+" kcal", 45, 490);
  }
  fill(GREEN); text("✔ workout_sorted_log.txt exported", 500, 490);

  // Buttons
  btnRestart.x=30;  btnRestart.y=510; btnRestart.draw();
  DashboardButton home = new DashboardButton(300,510,260,48,"⌂  Home",PANEL,TEXT);
  home.draw();
  DashboardButton exit = new DashboardButton(590,510,280,48,"✕  Close",#3D444D,DIM);
  exit.draw();

  fill(DIM); textSize(10); textAlign(CENTER);
  text("Design 1: Data-Dense Dashboard  |  COMP 350 Team Project  |  Akshit · Bhavik · Arsh", 450, 640);
}

// ============================================================
// SIMULATION UPDATE (called once per frame during ST_SIM)
// ============================================================
void updateSimulation() {
  float speed = sensitivitySlider.getValue();
  if (frameCount % max(1, int(30.0/speed)) == 0) simTimer++;

  noiseHR   += 0.015;
  noiseStep += 0.018;

  // ---- HR: gradual convergence toward target + noise ----
  float targetHR = TARGET_HR[activityState];
  simHR += (targetHR - simHR) * 0.025;
  simHR += noise(noiseHR)*6 - 3;
  simHR  = constrain(simHR, 55, 200);

  // ---- Calories ----
  simCals += CALORIE_RATE[activityState] * speed * (1.0/30.0);

  // ---- Steps ----
  stepAccum += STEP_RATE[activityState] * speed * (1.0/30.0);
  if (stepAccum >= 1) { simSteps += int(stepAccum); stepAccum -= int(stepAccum); }

  // ---- Reps ----
  repAccum += REP_RATE[activityState] / 60.0 * speed * (1.0/30.0);
  if (repAccum >= 1) { simReps += int(repAccum); repAccum -= int(repAccum); }

  // ---- Update HR graph ----
  hrGraph.addValue(simHR);

  // ---- Character movement (smooth lerp toward target) ----
  prevCharX = charX;
  prevCharY = charY;
  charX = lerp(charX, charTargetX, 0.04);
  charY = lerp(charY, charTargetY, 0.04);

  if (manualOverrideFrames > 0) {
    manualOverrideFrames--;
  } else {
    autoDetectActivity();
  }

  // ---- Log movement every 2s ----
  if (frameCount % 60 == 0) {
    movLog.add(new MovementLog(charX, charY, simTimer,
               ACTIVITY_NAMES[activityState], simHR));
    gestureStack.push(ACTIVITY_NAMES[activityState]+"@"+nf(simHR,0,0));
  }

  // ---- Auto-detect transitions (simple heuristic FSM) ----
  // If HR drops below 85 after running for at least 10s, auto-recover to jog
  if (activityState==ACT_RUN && simHR < 85 && simTimer > 10) {
    figure.setActivity(ACT_JOG); activityState=ACT_JOG;
  }

  // Update figure
  figure.setActivity(activityState);
}

void autoDetectActivity() {
  float dx = charX - prevCharX;
  float dy = charY - prevCharY;
  float speedPxPerSec = sqrt(dx*dx + dy*dy) * frameRate;
  float verticalDrift = abs(dy) * frameRate;
  float targetJump = prevCharY - charTargetY;

  int detected = ACT_IDLE;
  if (targetJump > 14 && verticalDrift > 18) {
    detected = ACT_JUMP;
  } else if (charTargetY > 360 && speedPxPerSec < 28) {
    detected = ACT_SQUAT;
  } else if (speedPxPerSec > 80) {
    detected = ACT_RUN;
  } else if (speedPxPerSec > 45) {
    detected = ACT_JOG;
  } else if (speedPxPerSec > 14) {
    detected = ACT_WALK;
  } else if (simHR > 95) {
    detected = ACT_RECOVER;
  }

  if (detected == autoCandidateState) {
    autoCandidateHoldFrames++;
  } else {
    autoCandidateState = detected;
    autoCandidateHoldFrames = 1;
  }

  if (autoCandidateHoldFrames >= 8) {
    activityState = autoCandidateState;
  }
}

void setManualActivity(int newActivity) {
  activityState = newActivity;
  manualOverrideFrames = 90;
}

// ============================================================
// SAVE SESSION & EXPORT
// ============================================================
void saveSession() {
  currentSession = new WorkoutSession(
    ACTIVITY_NAMES[activityState],
    ACT_COLORS[activityState],
    simTimer, simHR, simCals, simSteps, simReps);
  history.add(new WorkoutRecord(currentSession, "Apr 08, 2026"));
  sortedHistory = sortByCalories(history);
  searchResultIdx = searchMaxHR(history);
  exportSortedLog(sortedHistory, movLog);
}

void resetSim() {
  simTimer=0; simHR=72; simCals=0; simSteps=0; simReps=0;
  repAccum=0; stepAccum=0;
  charX=150; charY=320; charTargetX=150; charTargetY=320;
  prevCharX=150; prevCharY=320;
  manualOverrideFrames=0;
  autoCandidateState=ACT_IDLE;
  autoCandidateHoldFrames=0;
  movLog.clear();
  activityState=ACT_IDLE;
  figure.setActivity(ACT_IDLE);
}

// ============================================================
// MOUSE
// ============================================================
void mousePressed() {
  if (appState==ST_START) {
    if (btnStart.clicked(mouseX, mouseY)) {
      appState=ST_SIM; resetSim();
    }
    return;
  }

  if (appState==ST_END) {
    if (btnRestart.clicked(mouseX,mouseY)) { resetSim(); appState=ST_SIM; }
    if (mouseX>=300&&mouseX<=560&&mouseY>=510&&mouseY<=558) { resetSim(); appState=ST_START; }
    if (mouseX>=590&&mouseX<=870&&mouseY>=510&&mouseY<=558) { resetSim(); appState=ST_START; }
    return;
  }

  // ST_SIM
  if (btnEnd.clicked(mouseX,mouseY)) { saveSession(); appState=ST_END; return; }
  if (btnHistory.clicked(mouseX,mouseY)) {
    showHistory=!showHistory;
    showSortedView=true;
    sortedHistory=sortByCalories(history);
  }

  for (int i=0; i<activityBtns.length; i++) {
    if (activityBtns[i].clicked(mouseX,mouseY)) {
      setManualActivity(i);
      figure.setActivity(activityState);
      gestureStack.push("BTN:"+ACTIVITY_NAMES[i]);
    }
  }

  sensitivitySlider.tryDrag(mouseX,mouseY);

  // Click in sim panel → move character target
  if (mouseX<300 && mouseY>60 && mouseY<430) {
    charTargetX = mouseX;
    charTargetY = constrain(mouseY, 200, 420);
    gestureStack.push("MOVE("+int(mouseX)+","+int(mouseY)+")");
  }
}

void mouseDragged() {
  sensitivitySlider.drag(mouseX);
  if (mouseX<300 && mouseY>60 && mouseY<430) {
    charTargetX = mouseX;
    charTargetY = constrain(mouseY, 200, 420);
  }
}

void mouseReleased() { sensitivitySlider.release(); }

// ============================================================
// KEYBOARD
// ============================================================
void keyPressed() {
  if (appState != ST_SIM) return;
  if (key == CODED) {
    if(keyCode==LEFT)  charTargetX=max(20,charTargetX-30);
    if(keyCode==RIGHT) charTargetX=min(280,charTargetX+30);
    if(keyCode==UP)    charTargetY=max(180,charTargetY-20);
    if(keyCode==DOWN)  charTargetY=min(420,charTargetY+20);
  } else {
    switch(key) {
      case 'w': case 'W': setManualActivity(ACT_WALK);    break;
      case 'j': case 'J': setManualActivity(ACT_JOG);     break;
      case 'r': case 'R': setManualActivity(ACT_RUN);     break;
      case ' ':            setManualActivity(ACT_JUMP);    break;
      case 's': case 'S': setManualActivity(ACT_SQUAT);   break;
      case 'p': case 'P': setManualActivity(ACT_PUSHUP);  break;
      case 'i': case 'I': setManualActivity(ACT_IDLE);    break;
      case 'x': case 'X': setManualActivity(ACT_RECOVER); break;
    }
  }
  figure.setActivity(activityState);
  gestureStack.push("KEY:"+ACTIVITY_NAMES[activityState]);
}
