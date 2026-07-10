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
│   │   ├── navigation_simulator.dart  # Reusable ValueNotifier-based truck movement simulation
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
│   │   │   ├── map_page.dart          # Navigation map, depot + station markers, OSRM routing
│   │   │   ├── deliveries_page.dart   # Two-phase delivery planning view + selection mode
│   │   │   └── maintenance_page.dart  # Vehicle maintenance schedule
│   │   └── widgets/                   # Driver-specific components
│   ├── manager/
│   │   ├── manager_screen.dart        # Shell with sidebar + IndexedStack
│   │   └── pages/
│   │       ├── dashboard_page.dart
│   │       ├── fuel_monitoring_page.dart
│   │       └── theft_detection_page.dart
│   ├── profile/
│   │   └── pages/
│   │       └── profile_page.dart      # Account, appearance, logout
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
        ├── onboarding.dart            # Role-based onboarding overlay
        ├── role_badge.dart            # Color-coded marker with glow
        └── sidebar.dart               # Collapsible sidebar with items prop

assets/
├── images/
│   └── Onboarding/                    # 9 intro screenshots (Supplier, Driver, Manager)
└── mock_data/
    ├── authentication.json            # 12 users (2 suppliers, 4 managers, 6 drivers)
    ├── deliveries.json                # 14 deliveries (truckId + stationId FK, supports inProgress/completed)
    ├── maintenance.json               # 14 records (assignedToId FK)
    ├── stations.json                  # 11 stations (2 depots, 9 gas stations)
    ├── theft_alerts.json              # 7 alerts (vehicleId FK)
    └── vehicles.json                  # 9 trucks (fuelLevel, tankCapacity, driverId, dynamic status)
```

---

## Routes

| Route | Screen | Role |
|-------|--------|------|
| `/splash` | `SplashPage` | — |
| `/login` | `LoginPage` | — |
| `/register` | `PlaceholderPage` | — |
| `/driver/home` | `DriverScreen` (bottom nav: Map, Maintenance, Deliveries, Profile) | Driver |
| `/manager/home` | `ManagerScreen` (sidebar: Dashboard, Fuel Monitoring, Theft Detection) | Manager |
| `/supplier/home` | `SupplierScreen` (sidebar: Dashboard, Users, Maintenance, Fleet, Theft) | Supplier |
| `/profile` | `ProfilePage` | All |
| `/settings` | `PlaceholderPage` | All |

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
| `authentication.json` | 12 user accounts (2 suppliers, 4 managers, 6 drivers) | Roles: `supplier`, `manager`, `driver` |
| `vehicles.json` | 9 trucks with `supplierId`, `driverId`, `fuelLevel`, `tankCapacity`, status | `truckId` ← `deliveries.truckId`, `theft_alerts.vehicleId` |
| `stations.json` | 11 stations in Batangas area, types: `depot`, `gasStation` | `stationId` ← `deliveries.stationId`, `stationType` differentiates depot vs gas station |
| `deliveries.json` | 14 deliveries with `truckId`, `stationId`, `sourceStation`, product, quantity, status (`scheduled`/`inProgress`/`completed`) | FK: `truckId` → `vehicles.truckId`, `stationId`/`sourceStation` → `stations.stationId` |
| `maintenance.json` | 14 service records with `vehicleId`, `assignedToId` (driver/manager) | FK: `assignedToId` → `authentication.id` |
| `theft_alerts.json` | 7 theft alerts with `vehicleId`, Batangas-area coordinates | FK: `vehicleId` → `vehicles.truckId` |

### Data Model

**Two location types:**
- **Depots** (`type: "depot"`) — Company-owned fuel storage hubs. Trucks start here after loading fuel. Supply origin for all deliveries. Two depots: FleetSense Depot Batangas City (supplier 9) and FleetSense Depot Lipa (supplier 10).
- **Gas Stations** (`type: "gasStation"`) — Customer delivery endpoints. Trucks deliver fuel here.

**Supply chain flow:**
```
   Supplier → Depot → Truck starts at depot → Gas Station delivery
```

**Delivery relationships:**
Each delivery has a `sourceStation` (the depot the truck loads from) and a `stationId` (the destination gas station). The `StationType` (depot/gasStation) is resolved at load time via `DeliveryService.getAllDeliveries()` by joining `deliveries.json` with `stations.json`. Both models carry `stationType`/`sourceStationType` for UI differentiation.

**New drivers added:**
| User | Name | Truck | Depot | Status |
|------|------|-------|-------|--------|
| 11 | Ricardo Santos | TRK-007 | FleetSense Depot Lipa | En Route |
| 12 | Pedro Gonzales | TRK-008 | FleetSense Depot Batangas | Idle |

**Truck status & live simulation:**
Truck status is driven by both static JSON data and runtime state. Trucks with `"En Route"` in `vehicles.json` map to `TruckStatus.moving` in the supplier fleet dashboard. On the driver's deliveries page, the truck status shows `"En Route"` when either an active navigation route is running or the static JSON status is `"En Route"`, and `"Idle"` otherwise.

On the supplier fleet tracking page, en-route trucks are animated via `NavigationSimulator` — they move along OSRM routes from their current position through their in-progress and scheduled delivery stops. Simulators update positions every 2 seconds and trigger arrival notifications at each stop.

No backend or real database is required.

---

## Application Walkthrough

### Authentication

**Splash** — startup screen; checks for a saved session and redirects to Login or the appropriate dashboard. Shows loading animation while deciding.

**Login** — email/password authentication. Responsive layout (desktop: hero panel + form side-by-side; mobile: stacked). Toggles password visibility, shows inline errors on failed login, navigates to the role-specific screen on success.

### Onboarding

On first login, each role sees a role-specific introduction overlay with feature overview pages (illustrated with screenshots), a step progress timeline, and a preferences setup page (theme: System/Light/Dark, notification toggle). The overlay can be skipped at any time.

### Driver

The driver shell uses a **bottom tab bar** with four tabs, preserving page state via `IndexedStack`. Routes are coordinated between the Deliveries and Map pages via shared `Set<String>` delivery IDs in the parent `DriverScreen`.

**Deliveries** — two-phase interface for planning and starting delivery routes with per-truck status tracking.

*View mode* — Shows four KPI cards (Total, Completed, En Route, Pending), truck info (speed, dynamic status), and a scrollable delivery history list (product name only, quantity hidden). Each tile shows a station-type-aware icon (depot icon for depots, gas pump icon for gas stations) and a status chip. Tapping a tile opens a detail bottom sheet with full info (source, type, dates, notes). A "Start Delivery" button in the bottom bar enters selection mode.

*Selection mode* — Checkboxes appear on each non-completed tile. The header changes to "Select destinations". The bottom bar shows Cancel, selected count, and a "Start Navigation" button. Tapping "Start Navigation" shows a non-dismissable loading dialog ("Calculating most efficient route...") before switching to the map.

*Route active state* — When a route is active (navigation in progress on the map), a banner appears at the top of the delivery list showing "Route active — N destinations" with a "View on Map" button. The bottom bar shows a navigation button instead of "Start Delivery".

**Map** — navigation interface with live position simulation via `NavigationSimulator`. Renders an interactive `flutter_map` with:
- Driver's current position marker (set from the truck's `currentLocation` in `vehicles.json`, updated in real-time by the simulator).
- Source depot markers (blue warehouse icon) showing fuel origin points for deliveries.
- Destination markers (orange gas pump icon) showing delivery stops.
- OSRM route polyline between waypoints.
- Navigation info card (distance, ETA, next stop) with an "End Navigation" button.
- On stop arrival, a notification banner shows "Arrived at [station]".
- When navigation ends (all stops complete or user taps "End Navigation"), the parent screen clears the active route, restoring the deliveries page to view mode via `onNavigationEnd` callback.
- A `ValueNotifier<NavigationState>` drives live driver position, completed stops, remaining distance, and ETA.
- Only selected deliveries' markers appear during navigation; all driver deliveries show by default.

**Vehicle Maintenance** — full request lifecycle from the driver's perspective. Shows the assigned truck info, pending requests (with edit button), scheduled & in-progress items (with priority indicators), rejected requests (with reason and resubmit button), and completed service history (with dates and costs). A "Request" button opens a dialog to submit a new request (type, description, priority, preferred date). Pending requests can be edited in-place; rejected requests can be resubmitted after addressing the rejection reason.

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

**Fleet Tracking** — live fleet monitoring with automatic position simulation for en-route trucks:
- Interactive map showing user location, color-coded truck markers (Moving/Idle/Maintenance/Off Duty), station markers, and context-aware side panel.
- En-route trucks (`TruckStatus.moving`) are automatically animated via `NavigationSimulator` — each moves along its OSRM route through in-progress and scheduled delivery stops, updating markers every 2 seconds.
- Five KPI cards (Total, Moving, Idle, Maintenance, Off Duty).
- Context-aware side panel: truck list by default, detail panel on marker tap, delivery tracker panel when tracking a truck with live OSRM route.
- "Add Location" dialog (map pin + type/name/address fields).
- "Notify Truck Driver" dialog (truck selection + message).
- Truck Fuel Monitoring list with fuel progress bars and color thresholds.
- Fuel analytics KPIs + bar chart.

**Maintenance** — full maintenance lifecycle management covering driver-submitted requests. KPI row (Total, Pending, In Progress, Overdue, Completed), cost analytics (Total Spent, Avg per Request, In Progress, Completed) with a cost-by-type bar chart, requests-by-type bar chart, status-distribution pie chart, and three-column record list (Pending Requests / Active / Service History). Pending requests show an "Approve/Reject" dialog (approve with scheduled date and note, or reject with required reason). The status workflow progresses through Pending → Scheduled → In Progress → Completed, with progress notes on each transition and cost recording on completion. Cancelled records display the rejection reason. Each record card shows type, vehicle, status/priority badges, dates, assigned user, cost, notes, and contextual action buttons based on current status.

**Theft Detection** — security incident management. Defines alert types (fuelTheft, unauthorizedAccess, gpsTampering, routeDeviation), severities (critical → low), and statuses (new → investigating → resolved/dismissed). KPI row (Total, Critical, Investigating, Resolved), alerts-by-type bar chart, severity-distribution pie chart, and two-column list (Active / Resolved & Dismissed) with update-status workflow.

**User Dashboard** — user CRUD for suppliers. Analytics row (Total Users, Managers, Drivers, Suppliers), role/company pie and bar charts, search + role filter toolbar, and a horizontally scrollable `DataTable` (columns: User ID, Name, Company, Role, Email, Plate Number, Actions). Add/Edit dialogs with conditional fields (plate number, assigned supplier, location), delete with confirmation. Filters users by the logged-in supplier's `assignedSupplierId`.

### Profile (Shared)

Available from all roles. Shows avatar, name, role/company chips, email, user ID, and company. Actions include a theme toggle (Light/Dark persisted via `SharedPreferences`) and a logout button with confirmation. Responsive: side-by-side cards on wide screens, stacked on narrow.
