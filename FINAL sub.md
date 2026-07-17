# RESKU: Rescue and Knowledge Utility

## Inspiration
Natural disasters—such as earthquakes, volcanic eruptions, tsunamis, and severe flooding—frequently obliterate local communications infrastructure. Within minutes, cellular towers, fiber-optic internet backbones, and electrical grids collapse. This leaves survivors completely isolated and search-and-rescue teams operating blind, forced to navigate rubble and search for victims manually. 

Witnessing the tragic delay in emergency response times caused by these communication blackouts inspired us to build **RESKU (Rescue and Knowledge Utility)**. Our vision is to turn every consumer smartphone already present in the disaster zone into a localized, ad-hoc routing beacon. By bypassing the need for cellular towers or internet access, RESKU creates a resilient, bottom-up communication network that bridges the critical information gap in the first 72 hours of a disaster.

---

## What it does
RESKU is an offline-first ad-hoc emergency communication and tactical dispatch platform that operates in zero-infrastructure environments:
1.  **Survivor Logging (Offline)**: Survivors use their smartphones to report their name, medical triage status (Safe, Injured, Critical), and specific needs (Food & Water, Medical, Shelter, Tools). The app automatically retrieves GPS coordinates and bundles this data into a local NoSQL database.
2.  **Ad-Hoc BLE Mesh Routing**: The app initiates a time-sliced BLE scanning and advertising loop. Using Delay-Tolerant Networking (DTN) and Epidemic Routing, survivor devices exchange small data catalogs (Latest Update Vectors) to identify missing records and sync delta logs over a single BLE characteristic.
3.  **Data Mule Harvesting**: Field rescuers or drones equipped with the collector app move through affected areas, acting as "Data Mules." They aggressively scan and sync survivor records into their database while injecting official command announcements back into the mesh.
4.  **Local Sync Hotspot**: Upon returning to base camp, the collector app spawns a local HTTP sync server over a mobile Wi-Fi hotspot on port `8080`.
5.  **Tactical Command Dashboard**: Command operators connect to the collector's hotspot and pull the aggregated data. The desktop dashboard renders survivors on an interactive **OpenStreetMap** with concentric tactical rings, lists them in a sortable **Triage Database**, and ranks them using a mathematically grounded **Heuristic AI Dispatch Planner**.
6.  **Bidirectional Broadcasts**: Rescuers draft short evacuation alerts (max 160 characters) on the dashboard. These announcements sync back to mobile collectors and propagate down the survivor mesh, keeping communities informed.

---

## How we built it
*   **Core Framework**: Built using **Flutter (Dart)** for cross-platform Android, iOS, and Web build targets.
*   **Local Storage**: Built with **Hive** and **Hive Flutter** NoSQL key-value stores for fast, offline-first data caching.
*   **Networking Protocol**: Implemented a custom Central/Peripheral BLE role-switching state machine using `flutter_blue_plus` and `ble_peripheral` to bypass OS limitations.
*   **DTN Sync Engine**: Developed an Epidemic Routing protocol based on Latest Update Vector (LUV) catalog comparisons to synchronize local databases over BLE characteristics.
*   **Sync Server Middleware**: Developed a localized HTTP REST server using **Shelf** (`shelf` and `shelf_io`) to allow offline database harvesting.
*   **Command Map & GIS**: Integrated `flutter_map` with OpenStreetMap tile caching and `latlong2` for spatial calculations.

---

## Challenges we ran into
*   **Concurrent BLE Roles**: Consumer smartphones cannot reliably maintain concurrent BLE central and peripheral states. We resolved this by implementing a time-sliced role-switching cycle that alternates advertising (8s) and scanning (4s) states separated by a cooldown period.
*   **BLE MTU Constraints**: BLE has strict payload size limits. We solved this by using the LUV catalog handshake. Instead of transferring the entire database, devices exchange lightweight catalogs, determine exactly which records are newer or missing, and only transmit those delta packages.
*   **Battery Power Management**: Continuous BLE scanning drains device batteries rapidly. We built an adaptive **Battery Saver Mode** using `battery_plus` that scales down the cycle frequency when battery levels drop below 20%.
*   **Distributed Database Merging**: Merging offline, desynchronized databases that arrive from random ad-hoc paths causes write conflicts. We solved this by assigning monotonic sequence numbers and epoch timestamps to every survivor record, using a strict "last-write-wins" resolution policy.

---

## Accomplishments that we're proud of
*   **100% Offline Dispatch Pipeline**: Built a working end-to-end tactical command pipeline that maps victims, visualizes network topology, and calculates priority rescue queues in a total communications blackout.
*   **Bidirectional Broadcast Propagation**: Successfully engineered a data-mule pipeline that aggregates survivor data and injects rescue announcements back into the ad-hoc mesh.
*   **Highly Efficient Sync Handshake**: Created a delta-based catalog sync that minimizes BLE transmission time, reducing battery draw and radio collision rates.
*   **Mathematically Grounded Triage Score**: Built an offline rescue planner ranking algorithm that factors in wait time alongside medical urgency and distance to prevent remote victims from being forgotten.

---

## What we learned
*   **Delay-Tolerant Networking (DTN)**: Gained deep theoretical and practical understanding of epidemic routing and distributed synchronization algorithms.
*   **BLE Low-Level Mechanics**: Mastered GATT profile configurations (Services, Characteristics, Descriptors), BLE advertisement payloads, and platform-specific radio limitations.
*   **Offline-First System Design**: Learned how to construct resilient NoSQL database schemas, coordinate local caches, and compress serialization payloads.
*   **User-Centered Design for Disasters**: Realized the critical need for high-contrast UI elements, simple forms, and integrated offline first-aid guides in high-stress, low-power environments.

---

## What's next for RESKU
*   **Binary Serialization**: Upgrade from JSON strings to compact binary serialization (such as Protocol Buffers or MessagePack) to further compress payloads and fit larger data sets within single-packet BLE frames.
*   **Gemini AI Command Integration**: Fully connect the online Gemini API fallback mode on the central dashboard so that when internet connectivity is briefly restored, the base camp commander receives natural-language dispatch recommendations and resource estimations.
*   **Offline Regional Tile Packager**: Build an offline map downloader utility directly into the command dashboard, allowing rescuers to import regional GIS map archives from USB drives.
*   **Static Repeater Beacon Nodes**: Integrate ruggedized, solar-powered BLE microcontrollers (like ESP32) to act as stationary repeater beacons placed in high-risk zones, extending the reach of the mobile mesh.

---

## Business & Monetization Model
To ensure long-term operational sustainability, RESKU implements a hybrid B2G/B2NGO software-as-a-service (SaaS) and hardware partnership model:

### 1. SaaS Subscriptions (B2G & B2NGO)
Disaster management agencies (e.g., BNPB, BPBD, FEMA) and humanitarian NGOs (e.g., Red Cross, UNOCHA) pay an annual subscription for the centralized command suite:
*   **Rescuer Command Dashboard**: Full multi-agent mapping and triage database synchronization.
*   **Local AI Decision Support System (DSS)**: A CPU-friendly AI assistant that runs 100% offline on standard responder laptops using quantized Small Language Models (SLMs) to estimate operational costs, plan logistics (tents, generators, medical kits), and analyze terrain hazards in the first hours of a disaster.
*   **Offline GIS & Maps Update**: Licensing to import and update localized regional offline map tile packs.

### 2. Hardware Partnerships
We provide integrated physical hardware to expand the BLE mesh range:
*   **Resku Hub (BLE Beacon)**: Ruggedized, battery or solar-powered BLE beacons placed at designated evacuation points. They act as static mesh routers and can transmit through building rubble up to a 10-meter radius, protecting a search volume of **±4,000 m³** per beacon.
*   **Drone BLE Scanner firmware**: Integration firmware allowing search-and-rescue drones to scan and harvest mesh data from survivor zones.

### 3. Case Study: DKI Jakarta Megacity Implementation
*   **Deployment Standard**: Penning 3 Resku Hub Beacons per Kelurahan across all **267 Kelurahan** in Jakarta, totaling **800 beacons**.
*   **Rubble Volume Coverage**: 800 beacons x ±4.000 m³ = **3,200,000 m³** of collapsed structural volume protected by signal coverage.
*   **Open Evacuation Coverage**: 800 beacons x 31,416 m² (100m line-of-sight radius) = **25.1 km²** of critical evacuation meeting points covered.
*   **Project Pricing & Cost Efficiency**:
    *   *Previous High-Cost Scheme*: 40 Packages x IDR 195,000,000 = **IDR 7.8 Billion**.
    *   *RESKU Optimized Scheme*: 40 Packages x IDR 45,000,000 = **IDR 1.8 Billion**.
    *   **Budget Saving**: Saves the government **IDR 6.0 Billion (77% budget reduction)**. At IDR 1.8 Billion, the procurement can be executed rapidly via direct regional budgets without lengthy public bidding processes.

---

## Development Process Q&A
*   **How did you develop this project?**: We followed a strict top-down engineering workflow. We drafted specifications in the Product Requirements Document ([PRD.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/PRD.md)) and Operational Flow ([FLOW.md](file:///d:/4. Thoriq_KULIAH/1.Lomba Thoriq/SEMESTER 4/12.Garuda/resku/FLOW.md)) before code implementation. We built the local NoSQL storage layer first, followed by the BLE communication loops on physical devices, the Shelf-based server, and finally the web/desktop UI dashboards.
*   **What are the thought processes behind the decisions of solution you made?**: We prioritized accessibility and reliability. We chose BLE because it operates silently without intrusive OS-level Wi-Fi connection prompts. We chose Hive for database caching because of its high-speed performance on mobile and web platforms. We chose a local heuristic priority AI over cloud LLMs to guarantee operational uptime in complete network blackouts.

---

## Tools & AI Usage Disclosure
*   **Tools Used**: Flutter SDK, VS Code, Git, Shelf (HTTP server), Hive (Database), open-source packages (`flutter_blue_plus`, `ble_peripheral`, `flutter_map`, `latlong2`, `geolocator`, `battery_plus`). Mobile builds are compiled to Android Package (`.apk`) files for offline side-loading in disaster zones.
*   **AI Usage**: The core system architecture, database schemas, role-switching states, and synchronization handshakes were designed 100% by the human development team. The Gemini-powered Antigravity AI assistant acted as the executor to implement the planned architecture and generate the code. The human team conducted manual testing on physical devices, handled ~20% of the debugging, and verified compile-time and structural integrity. It is **not** a vibe-coded project; it was structurally engineered.
*   **End-Product AI**: Incorporates offline natural language processing (supporting quantized SLMs like Qwen 2.5 via local Ollama services) and online Gemini API configurations for command post upgrades.
*   **Copyrighted Materials**: All Flutter packages used are open-source under MIT, BSD, or Apache 2.0 licenses. Map tile data is provided by OpenStreetMap (OSM) under the Open Database License (ODbL). Typography is provided by Inter and JetBrains Mono under the SIL Open Font License (OFL). All UI wireframes in `Scart/` and vector assets in `svg/` are original works developed by the team.
