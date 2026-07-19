# FleetSense

A Flutter prototype for fuel delivery operations, connecting tanker truck drivers, gas station managers, and fuel supervisors. Uses local JSON files for mock data with Batangas-area locations.

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, theme persistence
├── core/                              # Shared infrastructure
│   ├── constants/                     # App-wide constants
│   │   └── delivery_conditions.dart   # Fuel expansion rates, temp thresholds, warnings
│   ├── models/                        # Data classes
│   │   ├── auth_user.dart             # AuthUser, user roles
│   │   ├── fleet_tracking.dart        # FleetTruck, FleetStation
│   │   ├── maintenance.dart           # MaintenanceRecord
│   │   ├── order.dart                 # Order + OrderStatus enum
│   │   ├── theft_alert.dart           # TheftAlert
│   │   └── truck.dart                 # TruckModel, DeliveryModel
│   ├── routes/                        # Navigation
│   │   ├── app_routes.dart            # Route name constants
│   │   └── route_generator.dart       # onGenerateRoute handler
│   ├── services/                      # Business logic & data access
│   │   ├── authentication.dart        # AuthenticationService
│   │   ├── deliveries.dart            # DeliveryService (3-way join + order→delivery)
│   │   ├── json_reader.dart           # Reads mock JSON assets
│   │   ├── maintenance_service.dart   # Maintenance record queries
│   │   ├── navigation_simulator.dart  # Reusable ValueNotifier-based truck movement simulation (driver + supervisor fleet)
│   │   ├── order_service.dart         # Order CRUD (in-memory, JSON-backed)
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
│   └── supervisor/
│       ├── supervisor_screen.dart       # Shell with sidebar + IndexedStack
│       ├── pages/
│       │   ├── dashboard_page.dart
│       │   ├── fleet_tracking_page.dart
│       │   ├── maintenance_page.dart
│       │   ├── theft_detection_page.dart
│       │   └── user_dashboard_page.dart
│       └── widgets/                   # Supervisor-specific components
│
└── shared/
    └── widgets/
        ├── bottom_nav_bar.dart        # WaterDropNavBar wrapper
        ├── logout_dialog.dart         # Confirmation dialog
        ├── onboarding.dart            # Role-based onboarding overlay
        ├── role_badge.dart            # Color-coded marker with glow
        ├── sidebar.dart               # Collapsible sidebar with items prop
        └── warning_card.dart          # Fuel expansion / temperature warning card

assets/
├── images/
│   └── Onboarding/                    # 9 intro screenshots (Supervisor, Driver, Manager)
└── mock_data/
    ├── authentication.json            # 12 users (2 supervisors, 4 managers, 6 drivers)
    ├── deliveries.json                # 14 deliveries (truckId + stationId FK, supports inProgress/completed)
    ├── maintenance.json               # 14 records (assignedToId FK)
    ├── orders.json                    # 4 orders (pendingApproval, approved, rejected)
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
| `/manager/home` | `ManagerScreen` (sidebar: Dashboard, Fuel Monitoring, Fleet Tracking, Maintenance, Theft Detection) | Manager |
| `/supervisor/home` | `SupervisorScreen` (sidebar: Dashboard, Users, Maintenance, Fleet, Theft) | Supervisor |
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
| `authentication.json` | 12 user accounts (2 supervisors, 4 managers, 6 drivers) | Roles: `supervisor`, `manager`, `driver` |
| `vehicles.json` | 9 trucks with `supervisorId`, `driverId`, `fuelLevel`, `tankCapacity`, status | `truckId` ← `deliveries.truckId`, `theft_alerts.vehicleId` |
| `stations.json` | 11 stations in Batangas area, types: `depot`, `gasStation` | `stationId` ← `deliveries.stationId`, `stationType` differentiates depot vs gas station |
| `deliveries.json` | 14 deliveries with `truckId`, `stationId`, `sourceStation`, product, quantity, status (`scheduled`/`inProgress`/`completed`) | FK: `truckId` → `vehicles.truckId`, `stationId`/`sourceStation` → `stations.stationId` |
| `orders.json` | 4 orders following the Manager→Supervisor→Driver workflow | `depotId`/`stationId` → `stations.stationId`, `createdBy` → `authentication.userId` |
| `maintenance.json` | 14 service records with `vehicleId`, `assignedToId` (driver/manager) | FK: `assignedToId` → `authentication.id` |
| `theft_alerts.json` | 7 theft alerts with `vehicleId`, Batangas-area coordinates | FK: `vehicleId` → `vehicles.truckId` |

### Data Model

**Two location types:**
- **Depots** (`type: "depot"`) — Company-owned fuel storage hubs. Trucks start here after loading fuel. Supply origin for all deliveries. Two depots: FleetSense Depot Batangas City (supervisor 9) and FleetSense Depot Lipa (supervisor 10).
- **Gas Stations** (`type: "gasStation"`) — Customer delivery endpoints. Trucks deliver fuel here.

**Supply chain flow:**
```
   Manager (creates order via Fleet Tracking) → Supervisor (approves on Dashboard) → Driver (accepts in Deliveries) → Depot → Gas Station delivery
```

**Delivery relationships:**
Each delivery has a `sourceStation` (the depot the truck loads from) and a `stationId` (the destination gas station). The `StationType` (depot/gasStation) is resolved at load time via `DeliveryService.getAllDeliveries()` by joining `deliveries.json` with `stations.json`. Both models carry `stationType`/`sourceStationType` for UI differentiation.

**New drivers added:**
| User | Name | Truck | Depot | Status |
|------|------|-------|-------|--------|
| 11 | Ricardo Santos | TRK-007 | FleetSense Depot Lipa | En Route |
| 12 | Pedro Gonzales | TRK-008 | FleetSense Depot Batangas | Idle |

**Truck status & live simulation:**
Truck status is driven by both static JSON data and runtime state. Trucks with `"En Route"` in `vehicles.json` map to `TruckStatus.moving` in the supervisor fleet dashboard. On the driver's deliveries page, the truck status shows `"En Route"` when either an active navigation route is running or the static JSON status is `"En Route"`, and `"Idle"` otherwise.

On the supervisor fleet tracking page, en-route trucks are animated via `NavigationSimulator` — they move along OSRM routes from their current position through their in-progress and scheduled delivery stops. Simulators update positions every 2 seconds and trigger arrival notifications at each stop. The simulator guards against `speedKph = 0` (falls back to 45 kph) to prevent division-by-zero Infinity errors in ETA calculations.

No backend or real database is required.

---

## Delivery Order Workflow

The ordering system follows a 3-role approval pipeline using `orders.json` (status: `pendingApproval` → `approved` → `accepted` → `inProgress` → `completed`):

1. **Manager (Create Order)** — Inside Fleet Tracking page, toggles "Create Order" mode via floating map button. Taps a depot (fuel source) then a gas station (delivery destination) on the map. Fills in fuel type, quantity, scheduled date and time. A conditional warning from `DeliveryConditions` (fuel expansion risk with simulated weather forecast temperature) appears. On submit, the order is saved as `pendingApproval`.

2. **Supervisor (Approve/Reject)** — On the Dashboard, a "Pending Order Approvals" card lists all orders awaiting review. Each tile shows details and the same temperature warning. The supervisor can approve (status → `approved`) or reject (status → `rejected` with reason).

3. **Driver (Accept & Deliver)** — On the Deliveries page, an "Available Orders" section lists all approved orders. Tapping "Accept" changes the order status to `accepted` and calls `DeliveryService.createDeliveriesFromOrder()` which creates two `DeliveryModel` entries (depot stop + gas station stop) linked to the driver's truck. These entries merge into the existing delivery list and feed into the standard navigation flow (multi-select → Start Route → OSRM → stop-by-stop tracking).

**Warning system:** `DeliveryConditions` constants define fuel expansion rates per °C and a high-temperature threshold (35°C). `getAmbientTemp(date, hour)` returns a temperature based on the scheduled time of day with ±6°C daily variation for a "weather forecast" feel. If the resulting temperature exceeds 35°C, a forecast-style message is shown (e.g. "Forecast for Jul 20 at 2:00 PM — 38.0°C expected..."). The `WarningCard` widget renders this with amber/red styling; when no warning is active, it shows a green "No active warnings" indicator.

---

## Application Walkthrough

### Authentication

**Splash** — startup screen; checks for a saved session and redirects to Login or the appropriate dashboard. Shows loading animation while deciding.

**Login** — email/password authentication. Responsive layout (desktop: hero panel + form side-by-side; mobile: stacked). Toggles password visibility, shows inline errors on failed login, navigates to the role-specific screen on success.

### Onboarding

On first login, each role sees a role-specific introduction overlay with feature overview pages (illustrated with screenshots), a step progress timeline, and a preferences setup page (theme: System/Light/Dark, notification toggle). The overlay can be skipped at any time.

### Driver

The driver shell uses a **bottom tab bar** with four tabs, preserving page state via `IndexedStack`. Routes are coordinated between the Deliveries and Map pages via shared `Set<String>` delivery IDs in the parent `DriverScreen`. A `_completedDeliveryIds` set is also shared — the map page adds delivery IDs as stops are reached during simulation, and the deliveries page uses this set to override static JSON status for runtime-accurate display.

**Deliveries** — three-section interface combining order acceptance, delivery planning, and per-truck status tracking.

*Available Orders section* — At the top of the page, approved orders from the supervisor are listed as "Available Orders". Each tile shows the order ID, fuel type/quantity, and an "Accept" button. Accepting an order calls `DeliveryService.createDeliveriesFromOrder()` to create two `DeliveryModel` entries (depot fuel loading stop + gas station delivery stop) linked to the driver's truck. These entries merge into the driver's active delivery list and become available for the standard navigation flow. Accepted orders are removed from the available list.

*View mode* — Shows four KPI cards (Total, Completed, En Route, Pending), truck info (speed, dynamic status), and a delivery list split into two sections: **Active Deliveries** (scheduled/in-progress) and a collapsible **Delivery History** (completed). Each tile shows a station-type-aware icon (depot icon for depots, gas pump icon for gas stations) and a runtime-aware status chip. The history section shows the first 3 items by default with a "Show all" / "Show less" toggle. Tapping a tile opens a detail bottom sheet with full info (source, type, dates, notes). A "Start Delivery" button in the bottom bar enters selection mode.

*View mode* — Shows four KPI cards (Total, Completed, En Route, Pending), truck info (speed, dynamic status), and a delivery list split into two sections: **Active Deliveries** (scheduled/in-progress) and a collapsible **Delivery History** (completed). Each tile shows a station-type-aware icon (depot icon for depots, gas pump icon for gas stations) and a runtime-aware status chip. The history section shows the first 3 items by default with a "Show all" / "Show less" toggle. Tapping a tile opens a detail bottom sheet with full info (source, type, dates, notes). A "Start Delivery" button in the bottom bar enters selection mode.

*Selection mode* — Checkboxes appear on each non-completed tile. The header changes to "Select destinations". The bottom bar shows Cancel, selected count, and a "Start Navigation" button. Tapping "Start Navigation" shows a non-dismissable loading dialog ("Calculating most efficient route...") before switching to the map.

*Route active state* — When a route is active (navigation in progress on the map), a banner appears at the top of the delivery list showing "Route active — N destinations" with a "View on Map" button. The bottom bar shows a navigation button instead of "Start Delivery".

*Runtime status* — Deliveries completed during simulation (via `NavigationSimulator` stop arrivals) are tracked in a `_completedDeliveryIds` set shared between the map and deliveries pages via the parent `DriverScreen`. The deliveries page overrides each tile's displayed status using this set — deliveries reached en route show as "Completed" without modifying the static JSON data. KPI counts adjust accordingly.

**Map** — navigation interface with live position simulation via `NavigationSimulator`. Renders an interactive `flutter_map` inside a `ClipRRect` with rounded corners, using light OpenStreetMap tiles (consistent with the supervisor fleet tracking page). Features:
- Driver's current position marker (set from the truck's `currentLocation` in `vehicles.json`, updated in real-time by the simulator).
- Source depot markers (blue warehouse icon) showing fuel origin points for deliveries.
- Destination markers (orange gas pump icon) showing delivery stops.
- OSRM route polyline between waypoints, split into traveled (dimmed) and remaining (bright with white border) segments based on the simulator's `routeIndex`.
- Map uses heading-up auto-rotation (driver direction faces up like a mini-map) with `MapCamera.rotate()`. A compass "N" button counter-rotates to stay upright and appears only when rotation exceeds 0.5° from north-up. A re-center extended FAB (navigation arrowhead icon + "Re-center") restores heading-up alignment.
- All markers use `MarkerLayer(rotate: true)` — flutter_map's built-in `MobileLayerTransformer` rotates the marker container, and `MarkerLayer` counter-rotates each marker via `Transform.rotate(angle: -map.rotationRad)` to keep them screen-upright at all zoom/orientation states. Markers at identical positions stack naturally.
- Navigation info card (distance, ETA, next stop) with an "End Navigation" button.
- On stop arrival, a notification banner shows "Arrived at [station]".
- Runtime delivery completion is tracked per stop — when the simulator reaches a delivery destination, its ID is added to a shared `_completedDeliveryIds` set, overriding the static JSON status on the deliveries page.
- When all stops complete, "All stops completed" shows for 2 seconds, then navigation auto-ends: route clears, parent `_routeDeliveryIds` resets, and the tab switches to the deliveries page.
- A `ValueNotifier<NavigationState>` drives live driver position, completed stops, remaining distance, and ETA.
- Only selected deliveries' markers appear during navigation; all driver deliveries show by default.

**Vehicle Maintenance** — full request lifecycle from the driver's perspective. Shows the assigned truck info, pending requests (with edit button), scheduled & in-progress items (with priority indicators), rejected requests (with reason and resubmit button), and completed service history (with dates and costs). A "Request" button opens a dialog to submit a new request (type, description, priority, preferred date). Pending requests can be edited in-place; rejected requests can be resubmitted after addressing the rejection reason.

### Manager

The manager shell uses a **sidebar** with five pages, preserving page state via `IndexedStack`.

**Dashboard** — analytics hub with real-time fuel inventory, sales metrics, and operational status tracking.

**Fuel Monitoring** — real-time tank level monitoring with low-stock alerts and consumption tracking.

**Fleet Tracking** — live fleet monitoring with automatic position simulation for en-route trucks and **Create Order** functionality:
- Interactive map showing color-coded truck markers with `MarkerLayer(rotate: true)` for screen-upright rendering. A consistent color theme is applied across all maps: moving trucks green (`AppTheme.truckMoving`), idle amber, maintenance red, off-duty gray; gas stations orange (`AppTheme.stationGas`), depots dark blue (`AppTheme.stationDepot`). A collapsible **map legend** (toggle via `?` button at bottom-left) displays all six colors with labels for quick reference.
- En-route trucks automatically animated via `NavigationSimulator` along OSRM routes.
- OSRM route polyline split into traveled (dimmed) and remaining (bright) segments.
- **Create Order** mode toggled via a green `ActionButton` in the title row (beside "Notify Truck"). When active, the button turns red with "Cancel Order" label. In create-order mode, truck markers are hidden from the map to avoid accidental selection; only depot (blue) and gas station (orange) markers remain visible. Tap a depot then a gas station on the map to select fuel source and delivery destination. A side panel appears with fuel type dropdown, quantity field, scheduled date picker, and scheduled time picker. Shows a conditional fuel expansion warning with a simulated weather forecast temperature based on the selected date and time. Submit creates an order with status `pendingApproval` in `orders.json`. The order then enters the 3-role approval workflow.

**Maintenance** — full maintenance lifecycle management covering driver-submitted requests. KPI row (Total, Pending, In Progress, Overdue, Completed), cost analytics (Total Spent, Avg per Request, In Progress, Completed) with a cost-by-type bar chart, requests-by-type bar chart, status-distribution pie chart, and three-column record list (Pending Requests / Active / Service History). Pending requests show an "Approve/Reject" dialog (approve with scheduled date and note, or reject with required reason). The status workflow progresses through Pending → Scheduled → In Progress → Completed, with progress notes on each transition and cost recording on completion. Cancelled records display the rejection reason. Each record card shows type, vehicle, status/priority badges, dates, assigned user, cost, notes, and contextual action buttons based on current status.

**Theft Detection** — security incident management. Defines alert types (fuelTheft, unauthorizedAccess, gpsTampering, routeDeviation), severities (critical → low), and statuses (new → investigating → resolved/dismissed). KPI row (Total, Critical, Investigating, Resolved), alerts-by-type bar chart, severity-distribution pie chart, and two-column list (Active / Resolved & Dismissed) with update-status workflow.

### Supervisor

The supervisor shell uses a **sidebar** with five pages, preserving page state via `IndexedStack`.

**Dashboard** — analytics hub with:
- Time-based greeting banner (Morning/Afternoon/Evening) with user/company badges.
- Period selector (Q1–Q4 2026, Yearly).
- Four KPI cards with trend indicators (fleet size, active drivers, fuel consumption, open tickets).
- Charts: Fuel Consumption Trend (line, Diesel/Gasoline), Fleet Status (bar), Fleet Composition (pie), Revenue vs Costs (area).
- Recent alerts list (with "View All" navigation).
- Maintenance overview (scheduled/in progress/overdue/completed counts).
- **Pending Order Approvals** card — shows count of orders awaiting supervisor approval. Each order tile displays depot→station route, fuel type/quantity, scheduled date/time, and a conditional fuel expansion warning based on the order's scheduled time (simulated weather forecast). Approve/Reject buttons apply inline action — approve sets status to `approved`, reject shows a reason dialog and sets status to `rejected`. Uses shared `WarningCard` widget and `DeliveryConditions` constants for forecast-based temperature warnings.

**Fleet Tracking** — live fleet monitoring with automatic position simulation for en-route trucks:
- Interactive map showing user location, color-coded truck markers, station markers, and context-aware side panel. Uses the same unified color theme as the manager fleet tracking: moving trucks green, idle amber, maintenance red, off-duty gray; gas stations orange, depots dark blue. A collapsible **map legend** (toggle via `?` button at bottom-left) lists all six colors with labels. All markers use `MarkerLayer(rotate: true)` for screen-upright rendering regardless of map orientation.
- En-route trucks (`TruckStatus.moving`) are automatically animated via `NavigationSimulator` — each moves along its OSRM route through in-progress and scheduled delivery stops, updating markers every 2 seconds.
- When tracking a truck, the OSRM route polyline is rendered on the map, split into traveled (dimmed) and remaining (bright with white border) segments by looking up the truck's simulator `routeIndex` — matching the driver map's polyline behavior.
- Five KPI cards (Total, Moving, Idle, Maintenance, Off Duty).
- Context-aware side panel: truck list by default, detail panel on marker tap, delivery tracker panel when tracking a truck with live OSRM route.
- "Add Location" dialog (map pin + type/name/address fields).
- "Notify Truck Driver" dialog (truck selection + message).
- Truck Fuel Monitoring list with fuel progress bars and color thresholds.
- Fuel analytics KPIs + bar chart.

**Theft Detection** — security incident management. Defines alert types (fuelTheft, unauthorizedAccess, gpsTampering, routeDeviation), severities (critical → low), and statuses (new → investigating → resolved/dismissed). KPI row (Total, Critical, Investigating, Resolved), alerts-by-type bar chart, severity-distribution pie chart, and two-column list (Active / Resolved & Dismissed) with update-status workflow.

**User Dashboard** — user CRUD for supervisors. Analytics row (Total Users, Managers, Drivers, Supervisors), role/company pie and bar charts, search + role filter toolbar, and a horizontally scrollable `DataTable` (columns: User ID, Name, Company, Role, Email, Plate Number, Actions). Add/Edit dialogs with conditional fields (plate number, assigned supervisor, location), delete with confirmation. Filters users by the logged-in supervisor's `assignedSupervisorId`.

### Profile (Shared)

Available from all roles. Shows avatar, name, role/company chips, email, user ID, and company. Actions include a theme toggle (Light/Dark persisted via `SharedPreferences`) and a logout button with confirmation. Responsive: side-by-side cards on wide screens, stacked on narrow.
