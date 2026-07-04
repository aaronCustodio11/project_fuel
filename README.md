# FleetSense

A Flutter prototype for fuel delivery operations, connecting tanker truck drivers, gas station managers, and fuel suppliers. Uses local JSON files for mock data.

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/                              # Shared infrastructure
│   ├── models/                        # Data classes
│   │   ├── fleet_tracking.dart
│   │   ├── maintenance.dart
│   │   ├── auth_user.dart             # AuthUser
│   │   └── truck.dart                 # TruckModel, DeliveryModel
│   ├── routes/                        # Navigation
│   │   ├── app_routes.dart            # Route name constants
│   │   └── route_generator.dart       # onGenerateRoute handler
│   ├── services/                      # Business logic & data access
│   │   ├── authentication.dart        # AuthUser, AuthenticationService
│   │   ├── deliveries.dart            # DeliveryService
│   │   ├── json_reader.dart           # Reads mock JSON assets
│   │   ├── maintenance_service.dart
│   │   └── osrm_routing.dart          # OSRM API client
│   └── theme/
│       └── app_theme.dart             # Light/dark Material 3 themes
│
├── features/                          # Feature-first modules
│   ├── authentication/
│   │   └── pages/
│   │       ├── login_page.dart
│   │       └── splash_page.dart
│   ├── driver/
│   │   ├── driver_screen.dart         # Shell with bottom nav + IndexedStack
│   │   ├── pages/
│   │   │   ├── map_page.dart          # Live map, route, stops tracker
│   │   │   ├── deliveries_page.dart   # Delivery stats & history
│   │   │   └── maintenance_page.dart  # Vehicle maintenance schedule
│   │   └── widgets/                   # Driver-specific components
│   ├── profile/
│   │   └── pages/
│   │       └── profile_page.dart
│   ├── manager/
│   │   ├── manager_screen.dart        # Shell with sidebar + IndexedStack
│   │   ├── pages/
│   │   │   ├── dashboard_page.dart
│   │   │   ├── fuel_monitoring_page.dart
│   │   │   └── theft_detection_page.dart
│   │   └── widgets/                   # Manager-specific components
│   └── supplier/
│       ├── supplier_screen.dart       # Shell with sidebar + IndexedStack
│       ├── pages/
│       │   ├── dashboard_page.dart
│       │   ├── fleet_tracking_page.dart
│       │   ├── maintenance_page.dart
│       │   ├── theft_detection_page.dart
│       │   └── user_dashboard_page.dart
│       └── widgets/                   # Supplier-specific components
│
└── shared/
    └── widgets/
        ├── bottom_nav_bar.dart        # WaterDropNavBar wrapper
        ├── logout_dialog.dart         # Confirmation dialog
        ├── role_badge.dart            # Color-coded marker with glow
        └── sidebar.dart               # Collapsible sidebar with items prop

assets/
└── mock_data/
    ├── authentication.json
    ├── maintenance.json
    └── vehicles.json
```

---

## Key Conventions

### File naming

| Pattern | What it is | Example |
|---------|-----------|---------|
| `*_page.dart` | Routable screen | `map_page.dart` |
| `*_screen.dart` | Shell with bottom nav / tabs | `driver_screen.dart` |
| `*_service.dart` | Service class | `deliveries.dart` |
| `*_widget.dart` | Widget directory | `role_badge.dart` |
| `*_route.dart` | Route constants | `app_routes.dart` |

### Architecture

- **Feature-first** — each user role is a self-contained module under `features/`.
- **Pages in `pages/`** — every routable screen goes into a `pages/` sub-directory.
- **Widgets in `widgets/`** — feature-specific reusable widgets.
- **Shared in `shared/`** — widgets used across multiple features.
- **Package imports only** — all internal references use `package:project_fuel/...`.

---

## Routes

| Route | Screen | Role |
|-------|--------|------|
| `/splash` | `SplashPage` | — |
| `/login` | `LoginPage` | — |
| `/driver/home` | `DriverScreen` → `DriverMapPage` (tab 0) | Driver |
| `/manager/home` | `ManagerScreen` (sidebar: Dashboard, Fuel Monitoring, Theft Detection) | Manager |
| `/supplier/home` | `SupplierScreen` (sidebar: Dashboard, Users, Maintenance, Fleet, Theft) | Supplier |
| `/profile` | `ProfilePage` | All |

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter + Dart |
| Map | flutter_map + OpenStreetMap tiles |
| Routing | OSRM API (router.project-osrm.org) |
| Mock data | Local JSON files via `JsonReaderService` |
| Navigation | Named routes + `onGenerateRoute` |
| Nav bar | `water_drop_nav_bar` (driver) |
| Sidebar | `sidebarx` (shared, configurable items) |

---

## Mock Data

All data is read from `assets/mock_data/`:
- `authentication.json` — user accounts with roles
- `vehicles.json` — truck profiles with delivery stops
- `maintenance.json` — service records

No backend or real database is required.
