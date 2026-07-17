# RESKU: Rescue and Knowledge Utility

## How we built it
RESKU is designed as an offline-first ad-hoc emergency communication system built using a robust, modular, and cross-platform stack:
*   **Core Framework**: We utilized **Flutter (Dart)** to build cross-platform mobile apps (for both Survivors and Rescuers) and the central command web/desktop dashboard from a single, unified codebase.
*   **Offline-First Storage Layer**: To ensure zero-latency reads/writes and complete database availability during a total network blackout, we implemented a local NoSQL database utilizing **Hive** and **Hive Flutter**. Survivor status reports, network links, and rescuer broadcasts are cached locally as serialized documents.
*   **Time-Sliced BLE Mesh**: Because consumer mobile operating systems (iOS and Android) cannot reliably host BLE Central (scanning) and Peripheral (advertising) roles simultaneously, we engineered a custom **Time-Sliced Role-Switching Cycle** using `flutter_blue_plus` and `ble_peripheral`. Survivor devices alternate between scanning and advertising states to dynamically form ad-hoc peer connections.
*   **Epidemic Routing Sync Protocol**: We designed a custom Delay-Tolerant Networking (DTN) sync protocol. Nodes handshake by exchanging a **Latest Update Vector (LUV)** catalog containing known survivor IDs and message sequence numbers. The nodes compare LUVs, calculate missing records, compile a delta package, and exchange these deltas over a single BLE characteristic.
*   **Data Mule Synchronization**: Rescuers in the field act as "Data Mules" via a mobile collector app. They run BLE in central scan-only mode to pull data from survivor meshes. The collector app hosts a local hotspot server built with **Shelf** (`shelf` and `shelf_io`) on port `8080`, allowing dashboard operators at base camp to connect to the collector's Wi-Fi hotspot and pull the aggregated database using a CORS-enabled REST endpoint (`/api/sync`).
*   **Base Camp Command Dashboard**: The central dashboard is built with **OpenStreetMap (OSM)** integration via `flutter_map` and `latlong2`. It visualizes survivors with color-coded triage pins, draws concentric tactical rings centered on Base Camp, houses a sortable database table, and features an **AI Rescue Planner** priority engine.

## Challenges we ran into
Building a fully decentralized, offline-first mesh network on consumer mobile devices presented several unique engineering challenges:
*   **Mobile BLE Limitations**: The inability of standard smartphones to reliably maintain concurrent BLE advertising and scanning states across Android and iOS was our first roadblock. We solved this by designing a precise state machine that alternates advertising (8s) and scanning (4s) states separated by a cooldown period.
*   **BLE MTU & Payload Size Constraints**: BLE characteristics have strict Maximum Transmission Unit (MTU) size limits, making database transfers impossible. We resolved this by implementing the **Latest Update Vector (LUV)** catalog handshake. Instead of transferring the entire database, nodes only exchange small catalogs to compute and transmit only the missing delta records as optimized, compact JSON strings.
*   **Rapid Battery Drain**: Continuous radio operation drains smartphone batteries quickly, which is dangerous in a disaster scenario. We integrated a dynamic **Battery Saver Mode** using `battery_plus`. When a device's battery drops below 20%, the mesh cycle adaptively scales down (advertising for 4s, scanning for 2s, and increasing the idle cooldown to 90s) to preserve device longevity.
*   **Distributed Conflict Resolution**: In an epidemic routing model, desynchronized records can arrive via multiple random paths. To ensure database integrity, we implemented monotonic sequence numbers and millisecond epoch timestamps on every `SurvivorRecord` to handle merges using a strictly validated "last-write-wins" policy.

## Accomplishments that we're proud of
*   **100% Offline Dispatch Capability**: We built a fully operational tactical system that maps disaster victims, visualizes network topology, and calculates priority rescue queues in a total communications blackout.
*   **Dynamic Data Harvesting**: Successfully established a robust data-mule pipeline linking the survivor mesh network to field rescuers and the central command post via a localized HTTP sync hotspot.
*   **Cross-Platform Interoperability**: Achieved reliable BLE peripheral GATT server hosting and central client scanning that works seamlessly across different device platforms.
*   **Mathematically Grounded Triage Score**: Programmed a priority scoring engine that prevents survivors in remote areas from being forgotten by factoring waiting time alongside medical urgency and distance.

## What we learned
*   **Delay-Tolerant Networking (DTN)**: We gained deep theoretical and practical knowledge of epidemic routing algorithms, conflict resolution in distributed systems, and decentralized state synchronization.
*   **BLE Protocol Stack**: We mastered the lower-level mechanics of GATT profiles (Services, Characteristics, Descriptors), BLE advertisement packets, and mobile Bluetooth radio constraints.
*   **Offline-First Software Engineering**: We learned the importance of local cache synchronization, robust NoSQL design patterns, and the criticality of minimizing transmission payloads.
*   **User-Centered Empathy**: Designing for disaster scenarios taught us to prioritize high-contrast UI, large text fields, and simple navigation menus that remain fully functional under high stress and low power conditions.

## What's next for RESKU: Rescue and Knowledge Utility
*   **Advanced Binary Serialization**: Transition from JSON string payloads to highly optimized binary serialization formats (such as **Protocol Buffers** or **MessagePack**) to further compress packets and fit larger data sets within single-packet BLE frames.
*   **Gemini AI Command Integration**: Fully connect the online Gemini API fallback mode on the central dashboard so that when satellite or temporary internet is restored, the base camp commander receives natural-language dispatch recommendations, terrain risk summaries, and resource estimations.
*   **Offline Regional Tile Packager**: Build an offline map downloader utility directly into the command dashboard, allowing rescuers to import regional GIS map archives from USB drives when internet maps cannot load.
*   **Static Repeater Beacon Nodes**: Integrate ruggedized, solar-powered BLE microcontrollers (like ESP32) to act as stationary repeater beacons placed in high-risk zones, extending the reach of the mobile mesh.
