# Project Rules & Guidelines - Resku

This document defines the instructions, directory structures, tech stack dependencies, and behavioral rules for any coding agent working on the Resku codebase.

---

## 1. Project Description
Resku is an offline-first emergency communication system designed for disaster-stricken areas. It relies on standard smartphones running a Bluetooth Low Energy (BLE) ad-hoc mesh network to aggregate and propagate survivor location and status updates using Delay-Tolerant Networking (DTN) and Epidemic Routing. These location databases are collected by field rescuers and loaded into a central Rescuer Web Dashboard to coordinate emergency search, rescue, and triage operations.

---

## 2. Directory Structure

Any additions or modifications to the codebase must follow the established architecture:

```
lib/
├── app/                      # Shared root routing and MaterialApp configurations
│   ├── rescuer_app.dart      # Rescuer App container (switches desktop dashboard/mobile collector)
│   └── survivor_app.dart     # Survivor App container (form, first aid, announcements feed)
├── core/                     # Shared services, utilities, database, and models
│   ├── database/             # Offline storage configurations (Hive databases)
│   ├── models/               # Data structures (SurvivorRecord, RescuerMessage)
│   ├── network/              # Mesh networking and synchronization engines
│   │   ├── ble/              # BLE scanning and peripheral advertising loops
│   │   ├── dtn/              # Epidemic routing algorithms
│   │   └── server/           # Shelf-based local Wi-Fi HTTP Server
│   └── utils/                # Helper utilities and offline cache handlers
├── features/                 # Modular feature screens and widgets
│   ├── rescuer/              # Rescuer features
│   │   ├── collector/        # Mobile Collector interface
│   │   └── dashboard/        # Rescuer Desktop Dashboard interfaces
│   │       ├── ai/           # Gemini & Heuristics AI recommendation panel
│   │       ├── map/          # OpenStreetMap view widget
│   │       └── table/        # Survivor details table
│   └── survivor/             # Survivor features
│       ├── feed/             # Evacuation announcements board
│       ├── forms/            # Location and medical need form
│       └── guide/            # Offline markdown first aid guides
├── main.dart                 # Dynamic Launcher selection Hub for developer/demo usage
├── main_rescuer.dart         # Specific entrypoint for Rescuer Web Dashboard & Collector
└── main_survivor.dart        # Specific entrypoint for Survivor Mobile App
```

---

## 3. Technology Stack & Key Dependencies
- **Core**: Flutter (Dart)
- **BLE Communications**: `flutter_blue_plus` (Central scan) and `ble_peripheral` (Peripheral advertise & GATT)
- **Local Storage**: `hive` and `hive_flutter` NoSQL database
- **Serialization**: `protobuf` (Protocol Buffers) or MessagePack (MsgPack) for compact binary payloads over BLE
- **Mapping (Dashboard)**: `flutter_map` using OpenStreetMap with offline tile caching
- **AI Core**: Gemini API (Online mode) / Local rule-based heuristic scoring engine (Offline mode)
- **Local Sync HTTP Server**: `shelf`

---

## 4. Coding & Clean Code Rules
- **Separation of Concerns**: Keep components and functions tightly focused on their specific responsibility.
  - Do NOT mix UI code with database or business logic.
  - Expose asynchronous managers (e.g. `LocalDB`, `BleMeshManager`) as singletons/services and inject or call them cleanly from the UI or controllers.
- **Strong Typing**: Avoid dynamic types where possible. Always define models, return types, and parameter types.
- **Maintain Documentation**: Keep comments, docstrings, and inline summaries updated on all components.

---

## 5. Agent Workflow Rules
- **Mandatory Implementation Plans**: Always create a detailed implementation plan (`implementation_plan.md`) and request user review/feedback before making any functional modifications, code additions, or database refactoring, **unless explicitly told otherwise in the prompt**.
- **Task Tracking**: Organize execution using a standard `task.md` TODO list. Mark progress cleanly as tasks are performed.
- **Verification**: Run `flutter analyze` or relevant test suites after completing any modifications to ensure zero warnings and zero errors.
