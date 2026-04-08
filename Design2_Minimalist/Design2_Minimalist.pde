// ============================================================
// Design2_Minimalist.pde
// COMP 350     Team Project: FitTrack Pro
// Design 2: Minimalist Card UI (Light Theme)
// Team: Akshit Jindal    Bhavik Wadhwa    Arsh Kapoor
//
// Layout (900px wide):
//   [0   300]  = 3D Simulation Environment
//   [300   620]= Phone Card UI
//   [620   900]= Smartwatch + Analytics
// ============================================================

// ============================================================
// PALETTE     Light / Minimalist
// ============================================================
color BG2    = #F0F2F5;
color CARD   = #FFFFFF;
color ACCENT2= #6C63FF;
color TXT2   = #1A1A2E;
color GRAY2  = #8892A4;
color LGRAY  = #E8ECF0;
color C_RED  = #E74C3C;
color C_YLW  = #F39C12;
color C_GRN  = #27AE60;
color C_BLU  = #3498DB;
color C_PUR  = #9B59B6;

// ============================================================
// APP FSM
// ============================================================
int appState = 0;      // 0=ST_START, 1=ST_SIM, 2=ST_END
int activityState = 0; // 0=ACT_IDLE

// ---- Per-activity data ----
color[] ACT_COLORS2 = {
  #95A5A6, #27AE60, #3498DB, #E74C3C,
  #F1C40F, #9B59B6, #E91E63, #1ABC9C
};
float[] CALORIE_RATE2 = {0.012,0.055,0.08,0.14,0.0,0.09,0.0,0.01};
float[] TARGET_HR2    = {72,96,118,148,120,126,118,88};
float[] STEP_RATE2    = {0,1.5,2.1,2.8,0,0,0,0.4};
float[] REP_RATE2     = {0,0,0,0,0,12,0,0};

// ============================================================
// LIVE DATA
// ============================================================
int   simTimer  = 0;
float simHR     = 72;
float simCals   = 0;
float simSteps  = 0;
int   simReps   = 0;
float repAccum  = 0, stepAccum = 0;
float noiseHR   = 0;

// ============================================================
// CHARACTER
// ============================================================
float charX=150, charY=310;
float charTargetX=150, charTargetY=310;
float prevCharX=150, prevCharY=310;
boolean holdWalk = false;
boolean holdSprint = false;
boolean holdSquat = false;

// ============================================================
// DATA STORAGE
// ============================================================
ArrayList<WorkoutRecord> history   = new ArrayList<WorkoutRecord>();
ArrayList<MovementLog>   movLog    = new ArrayList<MovementLog>();
WorkoutSession currentSession = null;
ArrayList<WorkoutRecord> sortedHist;
int searchResultIdx = -1;

// ============================================================
// UI COMPONENTS
// ============================================================
HumanoidFigure  figure;
MetricCard[]    metricCards;
PulseButton     startBtn;
MinimalSlider   speedSlider;
ActivityPill    actPill;
MinimalWatchFace watchUI;
MinimalBarChart  phoneBarChart;
MinimalBarChart  watchBarChart;
StackManager    gestureStack;

// ---- Swipeable metric card state ----
int   activeCard   = 0;
float cardSwipeX   = 0;
float cardTargetX  = 0;
float swipeStart   = 0;

// ---- Phone card scroll offset ----
boolean showHistory = false;

// ---- Environment ----
float[] eX=new float[10], eY=new float[10], eN=new float[10];

// ============================================================
// SETUP
// ============================================================
void setup() {
  size(900, 660);
  frameRate(30);
  textFont(createFont("Arial",13));

  figure = new HumanoidFigure(charX, charY);
  gestureStack = new StackManager();

  // 4 metric cards
  String[] mLbl  = {"Heart Rate","Calories","Steps","Reps"};
  String[] mUnit = {"BPM","kcal","steps","count"};
  color[]  mCol  = {C_RED, C_YLW, C_BLU, C_GRN};
  metricCards = new MetricCard[4];
  for (int i=0; i<4; i++)
    metricCards[i] = new MetricCard(310+i*310, 82, 295, 120, mLbl[i], mUnit[i], mCol[i]);

  startBtn   = new PulseButton(450, 600, 34, "GO", ACCENT2);
  speedSlider= new MinimalSlider(20,600,260,20,0.5,3.0,1.0,"Speed",ACCENT2);
  actPill    = new ActivityPill(150,240);
  watchUI    = new MinimalWatchFace(652, 34, 120);
  phoneBarChart = new MinimalBarChart(
    310, 430, 295, 70, "Performance",
    new String[]{"HR","Cals","Steps/10","Reps"},
    new float[]{200,600,80,60},
    new color[]{C_RED,C_YLW,C_BLU,C_GRN});
  watchBarChart = new MinimalBarChart(
    630, 355, 260, 150, "Performance",
    new String[]{"HR","Cals","Steps/10","Reps"},
    new float[]{200,600,80,60},
    new color[]{C_RED,C_YLW,C_BLU,C_GRN});

  for (int i=0; i<10; i++) {
    eX[i]=random(10,280); eY[i]=random(80,400); eN[i]=random(100);
  }
  sortedHist = new ArrayList<WorkoutRecord>();
}

// ============================================================
// DRAW
// ============================================================
void draw() {
  background(BG2);
  switch(appState) {
    case ST_START: drawStart();  break;
    case ST_SIM:   drawSim();    break;
    case ST_END:   drawEnd();    break;
  }
}

// ============================================================
// START SCREEN
// ============================================================
void drawStart() {
  // Clean white card background
  fill(CARD); noStroke(); rect(0,0,900,660);

  // Left accent strip
  fill(ACCENT2); noStroke(); rect(0,0,8,660);

  // Title
  fill(ACCENT2); textSize(44); textAlign(CENTER);
  text("FitTrack Pro", 450,140);
  fill(GRAY2); textSize(15);
  text("Design 2      Minimalist Card UI", 450,170);
  fill(TXT2); textSize(13);
  text("A clean, focused fitness simulation experience", 450,194);

  // Body figure preview
  figure.setActivity(ACT_IDLE);
  figure.x=450; figure.y=390;
  figure.draw();
  figure.x=150; figure.y=310;

  // Feature pills
  String[] feats={"Real-Time 3D Simulation","Swipeable Metric Cards",
                   "Phone + Smartwatch UI","FSM    OOP    Stack    Sort"};
  color[] fc={ACCENT2,C_GRN,C_BLU,C_YLW};
  for(int i=0;i<feats.length;i++){
    float px=140+i*160;
    fill(fc[i],30); noStroke(); rect(px,480,145,32,16);
    fill(fc[i]); textSize(11); textAlign(CENTER); text(feats[i],px+72,501);
  }

  fill(#F4F6FA); noStroke(); rect(240,380,420,86,10);
  fill(TXT2); textSize(11); textAlign(LEFT);
  text("Project Goal: Simple realistic run demo with live biometric feedback", 252,404);
  text("Target Users: Students and new fitness-tracking users", 252,426);
  text("Usability Focus: Quick keyboard control + readable watch metrics", 252,448);

  // Controls
  fill(LGRAY); noStroke(); rect(160,530,580,44,12);
  fill(GRAY2); textSize(11); textAlign(LEFT);
  text("  Hold A = Walk    Hold W = Sprint/Run    Hold S = Squat", 168,557);

  // Start button
  startBtn.draw();
}

// ============================================================
// SIMULATION SCREEN
// ============================================================
void drawSim() {
  updateSim();
  drawSimPanel2();
  drawPhonePanel2();
  drawWatchPanel2();
  drawBottomBar2();
}

// ============================================================
// SIM PANEL (left, light)
// ============================================================
void drawSimPanel2() {
  fill(#EEF2FF); noStroke(); rect(0,0,300,660);
  stroke(#D5DCF5); strokeWeight(1);
  for(int gx=0;gx<300;gx+=30) line(gx,0,gx,660);
  for(int gy=0;gy<660;gy+=30) line(0,gy,300,gy);
  noStroke();

  for(int i=0;i<eX.length;i++){
    eN[i]+=0.008;
    float sz=noise(eN[i])*10+3;
    float al=noise(eN[i]+50)*120+30;
    fill(ACCENT2,(int)al); ellipse(eX[i],eY[i],sz,sz);
  }

  fill(LGRAY); rect(0,418,300,6);
  fill(0,0,0,55); ellipse(charX,418,40,10);

  figure.x=charX; figure.y=charY;
  figure.draw();

  actPill.x=charX; actPill.y=charY-148;
  actPill.set(ACTIVITY_NAMES[activityState], ACT_COLORS2[activityState], #FFFFFF);
  actPill.draw();

  fill(CARD); stroke(LGRAY); strokeWeight(1); rect(0,0,300,24);
  noStroke(); fill(TXT2); textSize(10); textAlign(LEFT);
  text("  3D SIMULATION  |  A Walk  W Sprint  S Squat", 4, 16);

  fill(CARD); noStroke(); rect(0,424,300,44);
  fill(GRAY2); textSize(10); textAlign(LEFT);
  text("  Activity: "+ACTIVITY_NAMES[activityState]+"  Time: "+formatTime(simTimer), 8,442);
  text("  HR: "+nf(simHR,0,0)+" BPM  Calories: "+nf(simCals,0,1)+" kcal", 8,458);

  fill(LGRAY); rect(299,0,2,660);
}

// ============================================================
// PHONE PANEL (middle, minimalist cards)
// ============================================================
void drawPhonePanel2() {
  fill(BG2); noStroke(); rect(300,0,320,660);

  fill(#F9FAFB); stroke(LGRAY); strokeWeight(1);
  rect(305,12,310,520,26);
  noStroke();
  fill(TXT2); rect(390,12,130,16,8);
  fill(BG2); ellipse(455,12,12,12);

  fill(#F9FAFB); rect(305,28,310,18);
  fill(GRAY2); textSize(8); textAlign(LEFT); text("  9:41",310,42);
  textAlign(RIGHT); text("100%",613,42);

  fill(ACCENT2); rect(305,46,310,36);
  fill(#FFFFFF); textSize(15); textAlign(LEFT); text("  FitTrack", 310,70);

  color ac2=ACT_COLORS2[activityState];
  fill(lerpColor(ac2,#FFFFFF,0.88f)); rect(305,82,310,30);
  fill(ac2); textSize(14); textAlign(CENTER);
  text(ACTIVITY_NAMES[activityState].toUpperCase(), 460,102);

  drawPrimaryMetric(310, 120, 295, 108, "HEART RATE", nf(simHR,0,0), "BPM", C_RED);
  drawPrimaryMetric(310, 236, 142, 86, "CALORIES", nf(simCals,0,1), "kcal", C_YLW);
  drawPrimaryMetric(463, 236, 142, 86, "STEPS", nf(simSteps,0,0), "steps", C_BLU);

  fill(CARD); stroke(LGRAY); strokeWeight(1);
  rect(310,332,295,64,12); noStroke();
  fill(TXT2); textSize(30); textAlign(CENTER);
  text(formatTime(simTimer),460,372);
  fill(GRAY2); textSize(9); text("ELAPSED", 460,388);

  drawZonePill2(310,404,295);

  fill(CARD); stroke(LGRAY); strokeWeight(1);
  rect(310,438,295,64,12); noStroke();
  fill(GRAY2); textSize(10); textAlign(LEFT);
  text("Controls", 322,456);
  fill(TXT2); textSize(11);
  text("Hold A: Walk   Hold W: Sprint   Hold S: Squat", 322,478);

  fill(LGRAY); rect(619,0,2,660);
}
void drawZonePill2(float x, float y, float w) {
  String zone; color zc;
  float hrPct = constrain(simHR / 190.0, 0, 1);
  if(hrPct<0.57){zone="Very Light";zc=C_GRN;}
  else if(hrPct<0.64){zone="Light";zc=#7ED957;}
  else if(hrPct<0.77){zone="Vigorous";zc=C_YLW;}
  else{zone="High";zc=C_RED;}

  fill(lerpColor(zc,#FFFFFF,0.82f)); noStroke(); rect(x,y,w,26,13);
  fill(zc); textSize(11); textAlign(CENTER);
  text(zone+" Zone  "+nf(simHR,0,0)+" BPM",x+w/2,y+17);
}

void drawPrimaryMetric(float x, float y, float w, float h, String label, String value, String unit, color c){
  fill(CARD); stroke(LGRAY); strokeWeight(1); rect(x,y,w,h,14); noStroke();
  fill(c); rect(x,y,w,5,3,3,0,0);
  fill(GRAY2); textSize(10); textAlign(LEFT); text(label, x+12, y+22);
  fill(TXT2); textSize(48); textAlign(LEFT); text(value, x+12, y+h-24);
  fill(GRAY2); textSize(15); textAlign(RIGHT); text(unit, x+w-12, y+h-24);
}

void drawBodyZoneMap(float x, float y, float w, float h) {
  // Simple colored silhouette zones showing active muscle groups
  fill(CARD); stroke(LGRAY); strokeWeight(1); rect(x,y,w,h,10); noStroke();
  fill(GRAY2); textSize(9); textAlign(LEFT); text("  Active Zones:", x+4,y+14);

  // Zones based on activity
  color[] zoneColors = new color[4];
  String[] zoneNames = {"Core","Arms","Legs","Cardio"};
  switch(activityState){
    case ACT_WALK:   zoneColors=new color[]{LGRAY,LGRAY,C_GRN,C_BLU};  break;
    case ACT_JOG:    zoneColors=new color[]{C_YLW,LGRAY,C_YLW,C_YLW}; break;
    case ACT_RUN:    zoneColors=new color[]{C_RED,C_YLW,C_RED,C_RED};  break;
    case ACT_JUMP:   zoneColors=new color[]{C_YLW,C_YLW,C_RED,C_RED};  break;
    case ACT_SQUAT:  zoneColors=new color[]{C_YLW,LGRAY,C_RED,C_YLW}; break;
    case ACT_PUSHUP: zoneColors=new color[]{C_RED,C_RED,LGRAY,C_YLW};  break;
    case ACT_RECOVER:zoneColors=new color[]{C_GRN,C_GRN,C_GRN,C_GRN}; break;
    default:         zoneColors=new color[]{LGRAY,LGRAY,LGRAY,LGRAY};
  }
  for(int i=0;i<4;i++){
    float bx=x+10+i*68;
    fill(zoneColors[i]); noStroke(); rect(bx,y+22,58,20,10);
    fill(brightness(zoneColors[i])>150?TXT2:#FFFFFF);
    textSize(9); textAlign(CENTER); text(zoneNames[i],bx+29,y+35);
  }
}

// ============================================================
// WATCH + ANALYTICS PANEL (right)
// ============================================================
void drawWatchPanel2() {
  fill(CARD); noStroke(); rect(620,0,280,660);
  stroke(LGRAY); strokeWeight(1); line(620,0,620,660); noStroke();

  fill(GRAY2); textSize(10); textAlign(LEFT);
  text("  SMARTWATCH   ANALYTICS", 624,16);

  watchUI.draw(simHR, simCals, ACTIVITY_NAMES[activityState], simTimer);

  drawRightStat(630,262,C_GRN,"Steps",nf(simSteps,0,0));
  drawRightStat(630,314,C_BLU,"Duration",formatTime(simTimer));
  drawRightStat(630,366,C_RED,"Heart Rate",nf(simHR,0,0)+" BPM");
  drawRightStat(630,418,C_YLW,"Calories",nf(simCals,0,1)+" kcal");

  fill(LGRAY); noStroke(); rect(630,486,260,90,10);
  fill(GRAY2); textSize(10); textAlign(LEFT);
  text("Active Mode", 640,505);
  fill(TXT2); textSize(22);
  text(ACTIVITY_NAMES[activityState], 640,533);
  fill(GRAY2); textSize(10);
  text("Hold key to continue motion", 640,553);

  fill(ACCENT2); noStroke(); rect(630,625,260,28,14);
  fill(#FFFFFF); textSize(11); textAlign(CENTER);
  text("Save Session",760,643);
}
void drawRightStat(float x, float y, color c, String lbl, String val){
  fill(lerpColor(c,#FFFFFF,0.88f)); noStroke(); rect(x,y,260,42,10);
  fill(GRAY2); textSize(9); textAlign(LEFT); text(lbl,x+8,y+14);
  fill(c); textSize(18); textAlign(LEFT); text(val,x+8,y+36);
}

// ============================================================
// BOTTOM BAR
// ============================================================
void drawBottomBar2() {
  fill(CARD); stroke(LGRAY); strokeWeight(1); rect(0,610,300,50); noStroke();

  if(appState==ST_SIM){
    fill(C_RED); rect(20,620,200,32,16);
    fill(#FFFFFF); textSize(13); textAlign(CENTER); text("Finish & Save",120,641);
  }

  fill(LGRAY); noStroke(); rect(8,642,284,14,7);
  fill(GRAY2); textSize(9); textAlign(CENTER);
  text("A=Walk   W=Sprint   S=Squat", 150,652);

  fill(LGRAY); noStroke(); rect(300,640,320,20);
  fill(GRAY2); textSize(8); textAlign(LEFT);
  text("  Design 2: Minimal Run Demo     Sessions: "+history.size(), 305,655);
}
void drawEnd(){
  fill(CARD); noStroke(); rect(0,0,900,660);

  // Header
  fill(ACCENT2); noStroke(); rect(0,0,900,75);
  fill(#FFFFFF); textSize(30); textAlign(CENTER); text("Great Workout!     ",450,42);
  fill(lerpColor(#FFFFFF,ACCENT2,0.4f)); textSize(13);
  text("Design 2: Minimalist      COMP 350 Team Project",450,65);

  if(currentSession!=null){
    // 6 summary tiles
    String[] sLbl={"Activity","Time","Avg HR","Calories","Steps","Reps"};
    String[] sVal={
      currentSession.type, formatTime(currentSession.duration),
      nf(currentSession.avgHR,0,1)+" BPM",
      nf(currentSession.calories,0,1)+" kcal",
      nf(currentSession.steps,0,0), str(currentSession.reps)
    };
    color[] sCol={ACCENT2,C_BLU,C_RED,C_YLW,C_GRN,C_PUR};

    for(int i=0;i<6;i++){
      float bx=30+i*142;
      fill(lerpColor(sCol[i],#FFFFFF,0.85f)); noStroke(); rect(bx,90,132,90,12);
      fill(sCol[i]); noStroke(); rect(bx,90,132,5,2,2,0,0);
      fill(GRAY2); textSize(10); textAlign(CENTER); text(sLbl[i],bx+66,112);
      fill(TXT2); textSize(19); text(sVal[i],bx+66,148);
    }
  }

  // Body figure recovery pose
  figure.setActivity(ACT_RECOVER);
  figure.x=450; figure.y=340;
  figure.draw();
  figure.x=150; figure.y=310;

  // Sorted history
  fill(LGRAY); noStroke(); rect(30,195,840,200,12);
  fill(ACCENT2); textSize(13); textAlign(LEFT);
  text("Sorted Workout History (Calories    )", 46,220);
  fill(#3D444D); rect(30,228,840,1);

  ArrayList<WorkoutRecord> srt=sortByCalories(history);
  String[] hdr={"#","Type","Duration","Calories","Steps","HR","Reps"};
  float[] hx={42,80,180,300,410,515,630};
  fill(GRAY2); textSize(10);
  for(int i=0;i<hdr.length;i++){textAlign(LEFT);text(hdr[i],hx[i],246);}

  for(int i=0;i<min(6,srt.size());i++){
    WorkoutRecord r=srt.get(i);
    fill(i%2==0?lerpColor(LGRAY,CARD,0.5f):CARD); noStroke(); rect(30,250+i*24,840,23);
    textAlign(LEFT); textSize(10);
    fill(GRAY2);text("#"+(i+1),hx[0],266+i*24);
    fill(r.typeColor);text(r.type,hx[1],266+i*24);
    fill(TXT2);
    text(formatTime(r.duration),hx[2],266+i*24);
    text(nf(r.calories,0,1),hx[3],266+i*24);
    text(nf(r.steps,0,0),hx[4],266+i*24);
    text(nf(r.avgHR,0,1),hx[5],266+i*24);
    text(str(r.reps),hx[6],266+i*24);
  }
  if(srt.size()==0){fill(GRAY2);textSize(12);textAlign(CENTER);text("No sessions yet",450,295);}

  // Movement + search summary
  fill(lerpColor(LGRAY,CARD,0.5f)); noStroke(); rect(30,408,840,75,10);
  fill(GRAY2); textSize(11); textAlign(LEFT); text("Movement Analysis:", 46,430);
  fill(TXT2); textSize(10);
  text("Coordinates logged: "+movLog.size(), 46,450);
  int best=searchMaxHR(history);
  if(best>=0){
    WorkoutRecord br=history.get(best);
    text("Peak HR session: "+br.type+"    "+nf(br.avgHR,0,1)+" BPM    "+nf(br.calories,0,1)+" kcal",46,468);
  }
  fill(C_GRN); text("    workout_sorted_log.txt saved",500,468);

  // Buttons
  fill(ACCENT2); noStroke(); rect(30,500,265,45,22);
  fill(#FFFFFF); textSize(14); textAlign(CENTER); text("     New Workout",162,528);

  fill(LGRAY); noStroke(); rect(320,500,265,45,22);
  fill(TXT2); textSize(14); textAlign(CENTER); text("     Home",452,528);

  fill(C_RED); noStroke(); rect(610,500,260,45,22);
  fill(#FFFFFF); textSize(14); textAlign(CENTER); text("     Exit",740,528);

  fill(GRAY2); textSize(10); textAlign(CENTER);
  text("Design 2: Minimalist Card UI      COMP 350      Akshit    Bhavik    Arsh",450,620);
}

// ============================================================
// SIMULATION UPDATE
// ============================================================
void updateSim(){
  applyHeldActivity();
  if(frameCount % 30==0) simTimer++;

  noiseHR+=0.01;

  float tHR=TARGET_HR2[activityState];
  simHR += (tHR-simHR)*0.0065;
  simHR += noise(noiseHR)*0.35-0.175;
  simHR  = constrain(simHR,55,200);

  simCals  += CALORIE_RATE2[activityState]*(1.0/30.0);
  stepAccum+= STEP_RATE2[activityState]*(1.0/30.0);
  if(stepAccum>=1){simSteps+=int(stepAccum);stepAccum-=int(stepAccum);}
  repAccum += REP_RATE2[activityState]/60.0*(1.0/30.0);
  if(repAccum>=1){simReps+=int(repAccum);repAccum-=int(repAccum);}

  prevCharX=charX;
  prevCharY=charY;

  if(activityState==ACT_RUN) {
    charTargetX += 1.25;
    charTargetY = 300;
    if(charTargetX>272) charTargetX = 28;
  } else if(activityState==ACT_WALK) {
    charTargetX += 0.6;
    charTargetY = 310;
    if(charTargetX>272) charTargetX = 28;
  } else if(activityState==ACT_SQUAT) {
    charTargetY = 350;
  } else {
    charTargetY = 310;
  }

  charX=lerp(charX,charTargetX,0.06);
  charY=lerp(charY,charTargetY,0.09);

  if(frameCount%60==0){
    movLog.add(new MovementLog(charX,charY,simTimer,
               ACTIVITY_NAMES[activityState],simHR));
  }

  figure.setActivity(activityState);
}

void applyHeldActivity(){
  if(holdSquat){
    activityState=ACT_SQUAT;
  } else if(holdSprint){
    activityState=ACT_RUN;
  } else if(holdWalk){
    activityState=ACT_WALK;
  } else {
    activityState=ACT_IDLE;
  }
}
void saveSession(){
  currentSession=new WorkoutSession(
    ACTIVITY_NAMES[activityState],ACT_COLORS2[activityState],
    simTimer,simHR,simCals,simSteps,simReps);
  history.add(new WorkoutRecord(currentSession,"Apr 08, 2026"));
  sortedHist=sortByCalories(history);
  searchResultIdx=searchMaxHR(history);
  exportSortedLog(sortedHist,movLog);
}

void resetSim(){
  simTimer=0;simHR=72;simCals=0;simSteps=0;simReps=0;
  repAccum=0;stepAccum=0;
  charX=150;charY=310;charTargetX=150;charTargetY=310;
  prevCharX=150;prevCharY=310;
  holdWalk=false; holdSprint=false; holdSquat=false;
  movLog.clear(); activityState=ACT_IDLE;
  activeCard=0; cardSwipeX=0;
  figure.setActivity(ACT_IDLE);
}

// ============================================================
// MOUSE
// ============================================================
void mousePressed(){
  if(appState==ST_START){
    if(startBtn.isClicked(mouseX,mouseY)){ appState=ST_SIM;resetSim(); }
    return;
  }
  if(appState==ST_END){
    if(mouseX>=30&&mouseX<=295&&mouseY>=500&&mouseY<=545){ resetSim();appState=ST_SIM; }
    if(mouseX>=320&&mouseX<=585&&mouseY>=500&&mouseY<=545){ resetSim();appState=ST_START; }
    if(mouseX>=610&&mouseX<=870&&mouseY>=500&&mouseY<=545){ resetSim();appState=ST_START; }
    return;
  }
  // ST_SIM
  if(mouseX>=20&&mouseX<=220&&mouseY>=620&&mouseY<=652){ saveSession();appState=ST_END; return; }
  if(mouseX>=630&&mouseX<=886&&mouseY>=625&&mouseY<=653){
    saveSession();
    appState=ST_END;
    return;
  }
  swipeStart=mouseX;

  // Click in sim panel to move char
  if(mouseX<300&&mouseY>24&&mouseY<420){
    charTargetX=mouseX;
    charTargetY=constrain(mouseY,160,416);
    gestureStack.push("CLICK("+int(mouseX)+","+int(mouseY)+")");
  }
}

void mouseDragged(){
  if(mouseX<300&&mouseY>24&&mouseY<420){
    charTargetX=mouseX;
    charTargetY=constrain(mouseY,160,416);
  }
}

void mouseReleased(){
  // no-op
}

// ============================================================
// KEYBOARD
// ============================================================
void keyPressed(){
  if(appState!=ST_SIM) return;
  if(key==CODED){
    if(keyCode==LEFT)  charTargetX=max(20,charTargetX-30);
    if(keyCode==RIGHT) charTargetX=min(280,charTargetX+30);
    if(keyCode==UP)    charTargetY=max(160,charTargetY-20);
    if(keyCode==DOWN)  charTargetY=min(415,charTargetY+20);
  } else {
    if(key=='a' || key=='A') holdWalk=true;
    if(key=='w' || key=='W') holdSprint=true;
    if(key=='s' || key=='S') holdSquat=true;
  }
  applyHeldActivity();
  figure.setActivity(activityState);
}

void keyReleased(){
  if(appState!=ST_SIM) return;
  if(key=='a' || key=='A') holdWalk=false;
  if(key=='w' || key=='W') holdSprint=false;
  if(key=='s' || key=='S') holdSquat=false;
  applyHeldActivity();
  figure.setActivity(activityState);
}







