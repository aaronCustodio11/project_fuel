# FleetSense

A Flutter prototype for fuel delivery operations, connecting tanker truck drivers, gas station managers, and fuel suppliers. Uses local JSON files for mock data with Batangas-area locations.

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, theme persistence
├── core/                              # Shared infrastructure
│   ├── models/                        # Data classes
│   │   ├── auth_user.dart             # AuthUser, user roles
│   │   ├── fleet_tracking.dart        # FleetTruck, FleetStation
│   │   ├── maintenance.dart           # MaintenanceRecord
│   │   ├── theft_alert.dart           # TheftAlert
│   │   └── truck.dart                 # TruckModel, DeliveryModel
│   ├── routes/                        # Navigation
│   │   ├── app_routes.dart            # Route name constants
│   │   └── route_generator.dart       # onGenerateRoute handler
│   ├── services/                      # Business logic & data access
│   │   ├── authentication.dart        # AuthenticationService
│   │   ├── deliveries.dart            # DeliveryService (3-way join)
│   │   ├── json_reader.dart           # Reads mock JSON assets
│   │   ├── maintenance_service.dart   # Maintenance record queries
│   │   └── osrm_routing.dart          # OSRM API client
│   └── theme/
│       └── app_theme.dart             # Light/dark Material 3, ThemeProvider
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
│   │       └── profile_page.dart      # Account, appearance, logout
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
│       │   ├── fleet_tracking_page.dart  # Live map, user location
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
    ├── authentication.json            # 10 users (drivers, managers, suppliers)
    ├── deliveries.json                # 8 deliveries (truckId + stationId FK)
    ├── maintenance.json               # 12 records (assignedToId FK)
    ├── stations.json                  # 12 stations in Batangas area
    ├── theft_alerts.json              # 7 alerts (vehicleId FK)
    └── vehicles.json                  # 9 trucks (fuelLevel, driverId nullable)
```

---

## Routes

| Route | Screen | Role |
|-------|--------|------|
| `/splash` | `SplashPage` | — |
| `/login` | `LoginPage` | — |
| `/driver/home` | `DriverScreen` (bottom nav: Map, Deliveries, Maintenance) | Driver |
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
| Theme persistence | SharedPreferences |

---

## Mock Data

All data is read from `assets/mock_data/`:

| File | Contents | Key Relationships |
|------|----------|-------------------|
| `authentication.json` | 10 user accounts (2 suppliers, 4 managers, 4 drivers) | Roles: `supplier`, `manager`, `driver` |
| `vehicles.json` | 9 trucks with `supplierId`, `driverId` (nullable), `fuelLevel`, status | `truckId` ← `deliveries.truckId`, `theft_alerts.vehicleId` |
| `stations.json` | 12 fuel stations in Batangas area with `supplierId`, capacity, stock | `stationId` ← `deliveries.stationId` |
| `deliveries.json` | 8 deliveries with `truckId`, `stationId`, product, quantity | FK: `truckId` → `vehicles.truckId`, `stationId` → `stations.stationId` |
| `maintenance.json` | 12 service records with `vehicleId`, `assignedToId` (driver/manager) | FK: `assignedToId` → `authentication.id` |
| `theft_alerts.json` | 7 theft alerts with `vehicleId`, Batangas-area coordinates | FK: `vehicleId` → `vehicles.truckId` |

No backend or real database is required.
