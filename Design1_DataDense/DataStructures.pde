// ============================================================
// DataStructures.pde
// WorkoutSession, WorkoutRecord, MovementLog, StackManager
// Used by both Design 1 and Design 2
// ============================================================

// ---- WorkoutSession: live session data ----
class WorkoutSession {
  String type;
  color  typeColor;
  int    duration;   // seconds
  float  avgHR;
  float  calories;
  float  steps;
  int    reps;

  WorkoutSession(String t, color c, int dur, float hr, float cal, float st, int r) {
    type=t; typeColor=c; duration=dur;
    avgHR=hr; calories=cal; steps=st; reps=r;
  }
}

// ---- WorkoutRecord: saved history entry ----
class WorkoutRecord {
  String type, date;
  color  typeColor;
  int    duration;
  float  avgHR, calories, steps;
  int    reps;

  WorkoutRecord(WorkoutSession s, String date) {
    type=s.type; typeColor=s.typeColor; duration=s.duration;
    avgHR=s.avgHR; calories=s.calories; steps=s.steps;
    reps=s.reps; this.date=date;
  }
}

// ---- MovementLog: x,y coordinate + activity snapshot ----
// Satisfies "Record random movement of objects showing x,y coordinates"
class MovementLog {
  float x, y;
  int   timestamp;
  String activity;
  float hr;

  MovementLog(float x, float y, int t, String act, float hr) {
    this.x=x; this.y=y; timestamp=t; activity=act; this.hr=hr;
  }

  String toCSV() {
    return timestamp+","+nf(x,0,1)+","+nf(y,0,1)+","+activity+","+nf(hr,0,1);
  }
}

// ---- StackManager: push/pop for gesture/transform history ----
class StackManager {
  ArrayList<String> stack = new ArrayList<String>();
  int maxSize = 8;

  void push(String s) {
    stack.add(s);
    if (stack.size() > maxSize) stack.remove(0);
  }

  String pop() {
    if (stack.size() > 0) return stack.remove(stack.size()-1);
    return "";
  }

  String peek() {
    return stack.size() > 0 ? stack.get(stack.size()-1) : "Empty";
  }

  // Returns last N items newest-first as a readable string
  String peekAll(int n) {
    String out = "";
    int start = max(0, stack.size()-n);
    for (int i = stack.size()-1; i >= start; i--) {
      out += stack.get(i);
      if (i > start) out += "  ›  ";
    }
    return out.length() > 0 ? out : "No gestures yet";
  }

  int size() { return stack.size(); }
}

// ---- Sorting: bubble sort ArrayList<WorkoutRecord> by calories desc ----
ArrayList<WorkoutRecord> sortByCalories(ArrayList<WorkoutRecord> list) {
  ArrayList<WorkoutRecord> sorted = new ArrayList<WorkoutRecord>(list);
  for (int i = 0; i < sorted.size()-1; i++)
    for (int j = 0; j < sorted.size()-1-i; j++)
      if (sorted.get(j).calories < sorted.get(j+1).calories) {
        WorkoutRecord tmp = sorted.get(j);
        sorted.set(j, sorted.get(j+1));
        sorted.set(j+1, tmp);
      }
  return sorted;
}

// ---- Search: linear search for highest HR session ----
int searchMaxHR(ArrayList<WorkoutRecord> list) {
  if (list.size() == 0) return -1;
  int idx = 0;
  for (int i = 1; i < list.size(); i++)
    if (list.get(i).avgHR > list.get(idx).avgHR) idx = i;
  return idx;
}

// ---- Export sorted log to file ----
void exportSortedLog(ArrayList<WorkoutRecord> sorted, ArrayList<MovementLog> moves) {
  PrintWriter pw = createWriter("workout_sorted_log.txt");
  pw.println("=== FITTRACK PRO — Sorted Workout Log (Calories Desc) ===");
  pw.println("Rank | Type       | Duration | Calories | Steps | AvgHR");
  pw.println("-----+------------+----------+----------+-------+------");
  for (int i = 0; i < sorted.size(); i++) {
    WorkoutRecord r = sorted.get(i);
    pw.println( nf(i+1,2,0) + "   | " + r.type +
                "     | " + formatTime(r.duration) +
                "   | " + nf(r.calories,0,1) +
                "    | " + nf(r.steps,0,0) +
                " | " + nf(r.avgHR,0,1));
  }
  pw.println("\n=== Movement Coordinate Log ===");
  pw.println("Time,X,Y,Activity,HR");
  for (MovementLog m : moves) pw.println(m.toCSV());
  pw.flush(); pw.close();
}

String formatTime(int s) {
  int mins = s / 60;
  int secs = s % 60;
  String minStr = mins < 10 ? "0" + mins : "" + mins;
  String secStr = secs < 10 ? "0" + secs : "" + secs;
  return minStr + ":" + secStr;
}
