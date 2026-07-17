# Project Q&A: RESKU (Rescue and Knowledge Utility)

## Development Process
### How We Developed the Project
We developed RESKU using an iterative, modular approach, isolating the offline storage layer, the BLE communication loop, and the frontend dashboards before integrating them. 
1.  **Architecture First**: We mapped the data lifecycle (Survivor -> BLE Mesh -> Data Mule -> Command Center) and designed the relational NoSQL schema in Hive.
2.  **BLE Loop Prototyping**: We tested the time-sliced role-switching mechanism on real devices to tune the intervals for scanning (4s) and advertising (8s) to prevent radio collisions.
3.  **Local Sync Hotspot Integration**: We built the HTTP sync protocol on a local Shelf server, verifying data integrity during high-throughput merges.
4.  **UI & Custom Design System**: We established the "Resku Design System"—a high-fidelity visual system built with curated HSL colors (Strava-inspired orange and deep slate), monospace tables, and interactive glassmorphic overlays.

### Thought Process Behind Technical Decisions
*   **Why BLE Mesh over Wi-Fi Direct or LoRa?**: Consumer smartphones do not require licensed hardware or extra modules to run BLE. Unlike Wi-Fi Direct, which triggers intrusive OS-level permission prompts and disconnects users from their current Wi-Fi network, BLE operates silently in the background, making it highly non-intrusive for panic-stricken survivors.
*   **Why Epidemic Routing with Latest Update Vectors (LUV)?**: Mobile BLE connections in emergency zones are fleeting ("contacts" last only seconds). Directly sending a full database sync is prone to failure. By exchanging a lightweight LUV catalog first, we determine precisely which records are out of date and transfer only the missing deltas, minimizing payload size and transmission duration.
*   **Why Rule-Based Heuristic AI for Dispatch?**: Relying solely on cloud APIs (like Gemini) is impossible in blackout areas. We designed a mathematical heuristic prioritizing urgency, distance, and wait time. This guarantees a 100% offline triage queuing mechanism that functions on low-end responder laptops.

---

## Tools Used
### Development & Build Tools
*   **Framework**: **Flutter (Dart)** for cross-platform Android, iOS, and Web build targets.
*   **Editor/IDE**: Visual Studio Code & Antigravity IDE.
*   **Version Control**: Git & GitHub for repository coordination and team branching.
*   **Design Tools**: Custom HTML/CSS prototypes (located in `Scart/` directory) and vector asset tools for UI/UX layouts.

### Deployment Method
*   **Survivor & Collector Mobile Apps**: Compiled into Android Package (`.apk`) files for offline side-loading (via SD card, local HTTP hotspots, or OTG cables) in disaster zones where app stores are unreachable.
*   **Rescuer Dashboard**: Run locally as a desktop executable (Windows/macOS) or hosted on a localized base camp server accessing the field databases.

### Key Libraries & Components
*   `flutter_blue_plus` & `ble_peripheral` (GATT profile and role management)
*   `hive` & `hive_flutter` (Lightweight offline database storage)
*   `shelf` & `shelf_io` (Localized Wi-Fi hotspot sync REST API server)
*   `flutter_map` & `latlong2` (Offline-ready OpenStreetMap rendering engine)
*   `battery_plus` (Dynamic power state scaling)
*   `geolocator` (Offline GPS coordinates collection)

---

## AI Usage Disclosure
### Extent of AI Utilization
*   **System Architecture & Logic Design (80% Human, 20% AI)**: The core system architecture, database schemas, BLE role-switching state machines, and synchronization algorithms were fully designed and conceptualized by the human development team.
*   **Code Generation & Execution (90% AI, 10% Human)**: We utilized the Gemini-powered Antigravity AI assistant to implement the planned architecture, generate clean, strongly typed Dart components, write local Shelf middleware, and structure UI elements.
*   **Debugging & Validation (20% Human, 80% AI)**: The human team conducted manual testing on physical devices, handled ~20% of fine-tuning, and guided the AI agent in resolving compile-time conflicts, dependency overlaps, and platform-specific BLE issues.

### Vibe-Coded or Structurally Engineered?
This is **not** a vibe-coded project. It was strictly engineered from the top down. We drafted detailed specifications in [PRD.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/PRD.md) and [FLOW.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/FLOW.md), ensuring database indices, BLE GATT callbacks, and network models were structured and reviewed before any code implementation began.

### AI in the End Product
The end-product features:
1.  An **Offline Natural Language Triage fallback** utilizing localized inference structures (designed to run against CPU-friendly quantized Qwen 2.5 SLMs via local Ollama services).
2.  An **Online Gemini AI upgrade module** designed to process survivor messages and provide strategic command center advice once satellite internet is briefly restored.

---

## Copyright Materials
All assets and packages not directly authored by us but integral to the project are listed below:
*   **Open-Source Libraries**: All Flutter plugins declared in `pubspec.yaml` (including `hive`, `flutter_blue_plus`, `ble_peripheral`, `shelf`, `flutter_map`, and `geolocator`) are licensed under the MIT, BSD, or Apache 2.0 open-source licenses.
*   **Mapping Imagery**: OpenStreetMap (OSM) tile data (© OpenStreetMap contributors) used under the Open Database License (ODbL).
*   **Typography**: The "Inter" font and "JetBrains Mono" monospace font (used for system telemetry and status displays) are open-source under the SIL Open Font License (OFL).
*   **Visual Assets & Layouts**: Wireframe sketches and HTML layouts in the `Scart/` directory (`Scart/dashboard.html`, `Scart/mobile.html`) and SVG graphics in the `svg/` directory are original works developed by the team.

---

## Technical Materials for Judges
To help judges evaluate the scale and depth of RESKU, we recommend reviewing:
1.  **[PRD.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/PRD.md)**: Product requirements detailing the role-switching intervals, offline pruning thresholds, and priority score calculations.
2.  **[FLOW.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/FLOW.md)**: Detailed technical workflow outlining the LUV handshake protocol, CORS middleware, and complete end-to-end data harvesting cycle.
3.  **UI Prototypes**: Reference layouts built in the `Scart/` directory showing the visual design system of the dashboard and survivor screens.
