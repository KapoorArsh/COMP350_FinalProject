# FitTrack Pro — COMP 350 Team Project
**Team:** Akshit Jindal · Bhavik Wadhwa · Arsh Kapoor  
**Course:** COMP 350 — User Interface Design and Programming  
**Instructor:** KJ (Kyungjae Lee)

---

## How to Run

1. Install **Processing 4** → https://processing.org/download
2. Unzip this folder
3. **Design 1:** Open `Design1_DataDense/Design1_DataDense.pde` → press ▶
4. **Design 2:** Open `Design2_Minimalist/Design2_Minimalist.pde` → press ▶

> Each sketch folder MUST contain all 4 .pde files. Do NOT move files out of their folder.

---

## Controls (both designs)

| Key | Action |
|-----|--------|
| W | Walk |
| J | Jog |
| R | Run |
| Space | Jump |
| S | Squat |
| P | Push-Up |
| X | Recover |
| I | Idle |
| Arrow Keys | Move character |
| Click/Drag in sim panel | Move character to position |
| Drag slider | Adjust simulation speed |

---

## Layout (900×660 window)

```
[0–300]       3D Simulation Panel  — animated humanoid, movement trail, gesture log
[300–600/620] Phone UI Panel       — live metrics, activity detection, zone bar
[600/620–900] Smartwatch Panel     — watch face, rings, HR history, analytics
```

---

## Technical Requirements Fulfilled

### FSM — 5 States
| State | Name | Transitions |
|-------|------|-------------|
| 0 | START | Click Begin |
| 1 | SIMULATION | Active workout |
| 2 | END | Finish & Save |
| (inner) | Idle/Walk/Jog/Run/Jump/Squat/Push-Up/Recover | Keyboard or button |

### Inheritance Hierarchy (3 levels + interface + abstract)
```
interface Animatable { update(), resetPose() }
    ↓ implemented by
abstract BodyPart (grandparent) — position, angle, highlight, drawShape()
    ├── TorsoSegment (parent) — rect body, setCondition()
    │   ├── Head     (child)
    │   ├── Chest    (child)
    │   └── Pelvis   (child)
    └── LimbSegment (parent) — len, thick, mirrored limb
        ├── UpperArm (child)
        ├── Forearm  (child)
        ├── UpperLeg (child)
        └── LowerLeg (child)
    + Hand, Foot extend BodyPart directly
```

### Data Structures & Algorithms
- `ArrayList<WorkoutRecord>` — workout history
- `ArrayList<MovementLog>` — x,y coordinate tracking
- `float[] sortedCalories` — static array
- **Bubble sort** on WorkoutRecord by calories (descending)
- **Linear search** for max HR session
- Results exported to `workout_sorted_log.txt`

### Stack (push/pop)
- `StackManager` used for **gesture history** (every keyboard/click action pushed)
- `HumanoidFigure.transformStack` used for **hierarchical 2D transforms** (pushMatrix/popMatrix mirrored with push/pop calls)

### Custom UI Components (6 each)
| Design 1 | Design 2 |
|----------|----------|
| SliderComponent | MinimalSlider |
| DashboardButton | PulseButton |
| LiveBarGraph | MinimalBarChart |
| ProgressRing | MetricCard (swipeable) |
| HeartRateGraph | MinimalWatchFace |
| WatchFace | ActivityPill |

### Keyboard + Mouse
- All keyboard shortcuts above
- Click sim panel → move character
- Drag slider → adjust speed
- Design 2: swipe left/right on phone panel → switch metric cards
- Activity buttons on phone UI → switch workout type

### Realism
- HR converges **gradually** toward per-activity target using lerp (not instant jump)
- Calories calculated per activity type × simulation speed × time
- `noise()` adds realistic HR variability
- Smooth character position lerp (no teleporting)
- Body figure changes pose and chest color by workout intensity

---

## File Structure

```
FitTrack_COMP350/
├── Design1_DataDense/
│   ├── Design1_DataDense.pde   ← Main: FSM, draw, mouse, keyboard
│   ├── BodyFigure.pde          ← Inheritance + Animatable interface + HumanoidFigure
│   ├── UIComponents.pde        ← 6 custom UI components (dark theme)
│   └── DataStructures.pde      ← Records, Stack, Sort, Search, Export
│
└── Design2_Minimalist/
    ├── Design2_Minimalist.pde  ← Main: FSM, draw, mouse, keyboard
    ├── BodyFigure.pde          ← Same (shared) inheritance hierarchy
    ├── UIComponents.pde        ← 6 custom UI components (light theme)
    └── DataStructures.pde      ← Same (shared) data structures
```
