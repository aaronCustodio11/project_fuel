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

---

## Application Walkthrough

### Authentication

**Splash** — startup screen; checks for a saved session and redirects to Login or the appropriate dashboard. Shows loading animation while deciding.

**Login** — email/password authentication. Responsive layout (desktop: hero panel + form side-by-side; mobile: stacked). Toggles password visibility, shows inline errors on failed login, navigates to the role-specific screen on success.

### Driver

The driver shell uses a **bottom tab bar** with four tabs, preserving page state via `IndexedStack`.

**Map** — the primary driving interface. Renders an interactive `flutter_map` with:
- Driver's current position marker.
- Nearest-neighbor-ordered delivery stop markers with numbered badges.
- OSRM route polyline between stops.
- Auto-simulation: animates the driver marker along the route, marking stops as completed when within 50m.
- Collapsible stop tracker panel and a bottom navigation info card (instruction, distance, ETA).
- Completion notifications with animated banners.

**Deliveries** — summary of all assigned deliveries. Shows four KPI cards (Total, Completed, En Route, Pending), truck info (volume, speed, status), and a scrollable history list with status chips.

**Vehicle Maintenance** — displays the driver's assigned truck info, scheduled maintenance items (with priority indicators), and completed service history (with dates and costs).

### Manager

The manager shell uses a **sidebar** with three pages (all currently placeholders showing "Coming soon").

- **Dashboard** — placeholder
- **Fuel Monitoring** — placeholder
- **Theft Detection** — placeholder

### Supplier

The supplier shell uses a **sidebar** with five pages, preserving page state via `IndexedStack`.

**Dashboard** — analytics hub with:
- Time-based greeting banner (Morning/Afternoon/Evening) with user/company badges.
- Period selector (Q1–Q4 2026, Yearly).
- Four KPI cards with trend indicators (fleet size, active drivers, fuel consumption, open tickets).
- Charts: Fuel Consumption Trend (line, Diesel/Gasoline), Fleet Status (bar), Fleet Composition (pie), Revenue vs Costs (area).
- Recent alerts list (with "View All" navigation).
- Maintenance overview (scheduled/in progress/overdue/completed counts).

**Fleet Tracking** — live fleet monitoring with:
- Interactive map showing user location, color-coded truck markers (Moving/Idle/Maintenance/Off Duty), and station markers.
- Five KPI cards (Total, Moving, Idle, Maintenance, Off Duty).
- Context-aware side panel: truck list by default, detail panel on marker tap, delivery tracker panel when tracking a truck with live OSRM route.
- "Add Location" dialog (map pin + type/name/address fields).
- "Notify Truck Driver" dialog (truck selection + message).
- Truck Fuel Monitoring list with fuel progress bars and color thresholds.
- Fuel analytics KPIs + bar chart.

**Maintenance** — full maintenance lifecycle management. KPI row (Total, In Progress, Overdue, Completed), cost analytics (Total Spent, Avg per Request, In Progress, Completed) with a cost-by-type bar chart, requests-by-type bar chart, status-distribution pie chart, and two-column record list (Active / Completed & Cancelled). Each record card shows type, vehicle, status/priority badges, dates, assigned user, cost, notes, and an "Update Status" multi-step dialog (select status → add notes → confirm).

**Theft Detection** — security incident management. Defines alert types (fuelTheft, unauthorizedAccess, gpsTampering, routeDeviation), severities (critical → low), and statuses (new → investigating → resolved/dismissed). KPI row (Total, Critical, Investigating, Resolved), alerts-by-type bar chart, severity-distribution pie chart, and two-column list (Active / Resolved & Dismissed) with update-status workflow.

**User Dashboard** — user CRUD for suppliers. Analytics row (Total Users, Managers, Drivers, Suppliers), role/company pie and bar charts, search + role filter toolbar, and a horizontally scrollable `DataTable` (columns: User ID, Name, Company, Role, Email, Plate Number, Actions). Add/Edit dialogs with conditional fields (plate number, assigned supplier, location), delete with confirmation. Filters users by the logged-in supplier's `assignedSupplierId`.

### Profile (Shared)

Available from all roles. Shows avatar, name, role/company chips, email, user ID, and company. Actions include a theme toggle (Light/Dark persisted via `SharedPreferences`) and a logout button with confirmation. Responsive: side-by-side cards on wide screens, stacked on narrow.
