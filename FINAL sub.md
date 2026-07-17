# RESKU: Rescue and Knowledge Utility (All-in-One Submission & Documentation)

## 1. Inspiration
In the immediate aftermath of catastrophic natural disasters—such as volcanic eruptions, earthquakes, tsunamis, or severe flash floods—the physical infrastructure we take for granted vanishes. Cellular towers collapse or lose power, fiber-optic lines tear under shifting ground, and the electrical grid blackouts. 

This communication blackout creates a double-sided emergency:
1.  **Isolated Survivors**: Victims are left trapped, injured, or lost in dangerous areas with no means to request help, report status, or access basic emergency survival guidelines.
2.  **Blind Rescue Teams**: Search-and-rescue (SAR) coordinators at base camps are forced to dispatch personnel into hazardous environments without situational mapping, triage priorities, or coordinates. Rel rescuers are left searching blindly, wasting vital time during the "Golden Hour" of survival.

This critical communication gap inspired us to build **RESKU (Rescue and Knowledge Utility)**. Our vision is to bypass centralized infrastructure entirely. By turning standard, consumer smartphones already in the hands of survivors and rescuers into ad-hoc communication routers, RESKU forms a resilient, decentralized delay-tolerant network. We designed RESKU to ensure that even in a complete grid blackout, coordination, triage, mapping, and survival information remain fully operational.

---

## 2. What It Does
RESKU is a zero-infrastructure, offline-first emergency coordination suite that operates across three primary user roles: the **Survivor**, the **Data Mule Collector**, and the **Base Camp Command Center**.

```
  [ Survivor Node ]  <-- BLE Ad-Hoc Mesh -->  [ Survivor Node ]
          |
  (BLE Sync Handshake)
          v
  [ Rescuer Mobile Collector (Data Mule) ]
          |
  (Local Wi-Fi HTTP Sync over Shelf Server - Port 8080)
          v
  [ Rescuer Command Dashboard (Base Camp Laptop/Desktop) ]
```

### 2.1 The Survivor Experience (Mobile Client)
*   **Zero-Network Reporting**: Survivors open the app in a blackout area and fill out a simple, high-contrast status form. They select their medical triage status (Safe, Injured, or Critical) and toggle resource checkmarks (Food & Water, First Aid / Medical, Shelter, Tools / Warmth).
*   **Offline GPS Integration**: The app uses the device's hardware GPS to capture coordinates without cellular data or internet connection, saving a signed, stamped `SurvivorRecord`.
*   **Emergency Announcements Feed**: The home screen features a rolling card carousel displaying official rescue notices (e.g., helicopter dispatch times, evacuation point coordinate updates) gathered dynamically from the mesh.
*   **Offline First Aid Guide**: A comprehensive, offline markdown-styled expansion guide outlining protocols for CPR, Severe Bleeding, Fractures, Severe Burns, and Dehydration.
*   **Mesh Node Database**: Survivors can search and filter a list of all other cached survivor records nearby to coordinate group survival efforts.

### 2.2 The Rescuer Collector Experience (Data Mule)
*   **Passive Scanning ("Data Mule" Mode)**: Field rescuers or search drones move through search zones carrying mobile devices running the collector app.
*   **Aggressive Harvesting**: The app scans in BLE Central mode, automatically connecting to survivor nodes in the background, harvesting their local database logs, and writing command announcements into their devices.
*   **Localized Sync Gateway**: When rescuers return to base camp, they enable a localized Wi-Fi hotspot on their mobile device and start the Resku Hotspot Server on port `8080` to bridge the gathered data to the command dashboard.

### 2.3 The Rescuer Command Center Experience (Web/Desktop Dashboard)
*   **Visual GIS Mapping**: Operators download data from the collector. An interactive map renders all survivors as color-coded pins (Red: Critical, Orange: Injured, Green: Safe) on an OpenStreetMap interface showing concentric tactical distance rings centered on base camp.
*   **Sortable Triage Roster**: Displays a comprehensive table of all survivors showing names, status badges, battery percentages, primary needs, exact coordinates, and a "Locate" map focusing button.
*   **AI Rescue Planner**: Ranks active survivors into an optimal rescue queue using a mathematically grounded heuristic scoring engine that factors in triage status, proximity from base camp, and wait time.
*   **Broadcast Console**: Allows command operators to draft news alerts that are saved to the local database, synced back to the mobile collector, and propagated down the survivor mesh.

---

## 3. How We Built It
We engineered RESKU from the ground up to ensure high reliability, modularity, and cross-platform compatibility:
*   **Core Cross-Platform Stack**: Built using **Flutter (Dart)** to compile native mobile apps (for survivors and rescuers) and the desktop/web dashboard from a single, unified codebase.
*   **Offline Storage Layer**: Built using **Hive** and **Hive Flutter** as a lightweight, high-performance NoSQL database Box system. All records are serialized and cached locally with an auto-pruner that automatically purges logs older than 72 hours (3 days) to protect local storage capacity.
*   **Ad-Hoc BLE Mesh Engine**: We built a custom time-sliced Central/Peripheral role-switching engine using `flutter_blue_plus` and `ble_peripheral`. Devices alternate scanning and advertising states to dynamically form ad-hoc peer connections.
*   **Epidemic Routing Sync Protocol**: We designed a custom Delay-Tolerant Networking (DTN) sync protocol. Nodes handshake by exchanging a **Latest Update Vector (LUV)** catalog containing known survivor IDs and message sequence numbers. The nodes compare LUVs, calculate missing records, compile a delta package, and exchange these deltas over a single BLE characteristic.
*   **Shelf-Based REST Sync Server**: The mobile collector app runs a local HTTP API server using **Shelf** (`shelf` and `shelf_io`) on port `8080`. It handles CORS requests, allowing dashboard operators to pull harvested records as JSON payloads via local Wi-Fi hotspots.
*   **Command Map & GIS**: Integrated `flutter_map` with OpenStreetMap tile caching and `latlong2` for spatial calculations.

---

## 4. Challenges We Ran Into & Solutions

### 4.1 Smartphone BLE Role Limitations
*   *Challenge*: Consumer smartphones (especially iOS and Android devices) cannot reliably maintain concurrent BLE central (scanning/connecting) and peripheral (advertising/hosting GATT) states. 
*   *Solution*: We engineered a **Time-Sliced Role-Switching Cycle** that alternates states: 8 seconds advertising (Peripheral), 4 seconds scanning (Central), followed by a 30-second cooldown (idle) state. This prevents OS-level radio collisions and allows devices to reliably act as both routers and receivers.

### 4.2 BLE MTU & Payload Constraints
*   *Challenge*: BLE characteristics have a strict Maximum Transmission Unit (MTU) size limit (often negotiated down to 23-512 bytes), making full database transfers impossible.
*   *Solution*: We designed a **Latest Update Vector (LUV)** handshake catalog. Upon connection, the Central node reads the Peripheral's LUV (a compact index mapping Survivor IDs to sequence numbers). The Central node compares this against its own database, identifies exactly which records are newer or missing on the peer, and compiles a delta payload. Only these delta records are serialized and written over the characteristic, minimizing packet transmission time.

### 4.3 Rapid Battery Drain in Emergency Zones
*   *Challenge*: Continuous Bluetooth scanning and advertising drains smartphone batteries rapidly. In disaster zones, keeping devices powered is a matter of life and death.
*   *Solution*: We built an adaptive **Battery Saver Mode** using the `battery_plus` package. If the device's battery falls below 20%, the role-switching interval scales down (4s advertising, 2s scanning, and increasing the idle cooldown to 90s), reducing radio duty cycle and extending device uptime by up to 300%.

### 4.4 Distributed Database Synchronization Conflicts
*   *Challenge*: In an ad-hoc epidemic routing network, data packages arrive via random paths, out of order, and at different times. Merging these desynchronized files creates write conflicts.
*   *Solution*: We assigned monotonic sequence numbers and millisecond epoch timestamps to every `SurvivorRecord`. When merging databases, the system compares sequence numbers and timestamps, enforcing a strictly validated "last-write-wins" policy to ensure database integrity across all nodes.

---

## 5. Accomplishments That We're Proud Of
*   **100% Offline Coordination Pipeline**: Successfully established a functioning emergency response ecosystem that maps victims, visualizes network topology, and calculates priority rescue queues in a total communications blackout.
*   **Passive Data Mule Integration**: Built a robust pipeline that allows field rescuers and drones to passively harvest mesh data from survivor zones and sync it directly to the dashboard over a localized Wi-Fi HTTP sync server.
*   **Mathematically Grounded Rescue Score**: Designed and integrated a heuristic ranking engine that factors in waiting time alongside medical urgency and distance, preventing victims in remote areas from being ignored.
*   **Cross-Platform BLE Interoperability**: Achieved reliable BLE peripheral GATT server hosting and central client scanning that works seamlessly across different device platforms.

---

## 6. What We Learned
*   **Delay-Tolerant Networking (DTN)**: We gained deep theoretical and practical knowledge of epidemic routing algorithms, conflict resolution in distributed databases, and decentralized state synchronization.
*   **Low-Level BLE Protocol Stack**: Mastered the low-level mechanics of GATT profiles (Services, Characteristics, Descriptors), BLE advertisement payloads, and mobile Bluetooth radio constraints.
*   **Offline-First System Design**: Learned how to construct resilient NoSQL database schemas, coordinate local caches, and compress serialization payloads.
*   **User-Centered Design for Disasters**: Realized the critical need for high-contrast UI elements, simple forms, and integrated offline first-aid guides in high-stress, low-power environments.

---

## 7. Business & Monetization Model
To ensure long-term operational sustainability, RESKU implements a hybrid B2G/B2NGO software-as-a-service (SaaS) and hardware partnership model:

### 7.1 SaaS Subscriptions (B2G & B2NGO)
Disaster management agencies (e.g., BNPB, BPBD, FEMA) and humanitarian NGOs (e.g., Red Cross, UNOCHA) pay an annual subscription for the centralized command suite:
*   **Rescuer Command Dashboard**: Full multi-agent mapping and triage database synchronization.
*   **Local AI Decision Support System (DSS)**: A CPU-friendly AI assistant that runs 100% offline on standard responder laptops using quantized Small Language Models (SLMs) to estimate operational costs, plan logistics (tents, generators, medical kits), and analyze terrain hazards in the first hours of a disaster.
*   **Offline GIS & Maps Update**: Licensing to import and update localized regional offline map tile packs.

### 7.2 Hardware Partnerships
We provide integrated physical hardware to expand the BLE mesh range:
*   **Resku Hub (BLE Beacon)**: Ruggedized, battery or solar-powered BLE beacons placed at designated evacuation points. They act as static mesh routers and can transmit through building rubble up to a 10-meter radius, protecting a search volume of **4,000 m³** per beacon.
*   **Drone BLE Scanner firmware**: Integration firmware allowing search-and-rescue drones to scan and harvest mesh data from survivor zones.

### 7.3 Case Study: DKI Jakarta Megacity Implementation
*   **Deployment Standard**: Penning 3 Resku Hub Beacons per Kelurahan across all **267 Kelurahan** in Jakarta, totaling **800 beacons**.
*   **Rubble Volume Coverage**: 800 beacons x ±4.000 m³ = **3,200,000 m³** of collapsed structural volume protected by signal coverage.
*   **Open Evacuation Coverage**: 800 beacons x 31,416 m² (100m line-of-sight radius) = **25.1 km²** of critical evacuation meeting points covered.
*   **Project Pricing & Cost Efficiency**:
    *   *Previous High-Cost Scheme*: 40 Packages x IDR 195,000,000 = **IDR 7.8 Billion**.
    *   *RESKU Optimized Scheme*: 40 Packages x IDR 45,000,000 = **IDR 1.8 Billion**.
    *   **Budget Saving**: Saves the government **IDR 6.0 Billion (77% budget reduction)**. At IDR 1.8 Billion, the procurement can be executed rapidly via direct regional budgets without lengthy public bidding processes.

---

## 8. Technical Specifications & Developer Q&A

### 8.1 Database Schema
RESKU uses a simple, flat NoSQL document schema in Hive to store mesh state.

#### Survivor Record (`SurvivorRecord`)
Represents the status and location of a survivor node, propagated throughout the mesh.
```json
{
  "id": "String (Stable device UUID: survivor_timestamp_random)",
  "name": "String",
  "latitude": "Double",
  "longitude": "Double",
  "status": "Enum (safe | injured | critical)",
  "needs": "String (e.g., 'Food & Water, First Aid / Medical')",
  "timestamp": "Int64 (Milliseconds since epoch)",
  "sequenceNumber": "Int32",
  "batteryPercentage": "Int32",
  "message": "String (Raw emergency message)"
}
```

#### Rescuer Broadcast Message (`RescuerMessage`)
Represents messages broadcasted by rescuers (e.g., evacuation locations, arrival times) that propagate down the mesh.
```json
{
  "id": "String (ann-timestamp)",
  "message": "String (Max 160 characters)",
  "timestamp": "Int64 (Milliseconds since epoch)"
}
```

### 8.2 Operational Telemetry Specifications
*   **GATT Service UUID**: `8f7b3e0c-d3a9-4672-9b2f-7a4c6a8b79d2`
*   **GATT Sync Characteristic UUID**: `a3f5b2c9-e7d1-42a8-9b8f-3c6d4e5f0a1b`
*   **Sync Server Port**: `8080` (endpoints: `/api/sync`)
*   **Base Camp Coordinates**: `-6.2100` latitude, `106.8475` longitude

### 8.3 Development Process Q&A
*   **How did you develop this project?**: We followed a strict top-down engineering workflow. We drafted specifications in the Product Requirements Document ([PRD.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/PRD.md)) and Operational Flow ([FLOW.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/FLOW.md)) before code implementation. We built the local NoSQL storage layer first, followed by the BLE communication loops on physical devices, the Shelf-based server, and finally the web/desktop UI dashboards.
*   **What are the thought processes behind the decisions of solution you made?**: We prioritized accessibility and reliability. We chose BLE because it operates silently without intrusive OS-level Wi-Fi connection prompts. We chose Hive for database caching because of its high-speed performance on mobile and web platforms. We chose a local heuristic priority AI over cloud LLMs to guarantee operational uptime in complete network blackouts.

---

## 9. Tools & AI Usage Disclosure
*   **Tools Used**: Flutter SDK, VS Code, Git, Shelf (HTTP server), Hive (Database), open-source packages (`flutter_blue_plus`, `ble_peripheral`, `flutter_map`, `latlong2`, `geolocator`, `battery_plus`). Mobile builds are compiled to Android Package (`.apk`) files for offline side-loading in disaster zones.
*   **AI Usage**: The core system architecture, database schemas, role-switching states, and synchronization handshakes were designed 100% by the human development team. The Gemini-powered Antigravity AI assistant acted as the executor to implement the planned architecture and generate the code. The human team conducted manual testing on physical devices, handled ~20% of the debugging, and verified compile-time and structural integrity. It is **not** a vibe-coded project; it was structurally engineered.
*   **End-Product AI**: Incorporates offline natural language processing (supporting quantized SLMs like Qwen 2.5 via local Ollama services) and online Gemini API configurations for command post upgrades.
*   **Copyrighted Materials**: All Flutter packages used are open-source under MIT, BSD, or Apache 2.0 licenses. Map tile data is provided by OpenStreetMap (OSM) under the Open Database License (ODbL). Typography is provided by Inter and JetBrains Mono under the SIL Open Font License (OFL). All UI wireframes in `Scart/` and vector assets in `svg/` are original works developed by the team.
