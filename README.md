# FleetSense

**FleetSense** is a high-fidelity mobile application prototype developed using the **Flutter framework**. The application is designed to streamline communication and coordination between three primary stakeholders involved in fuel delivery operations:

- 🚚 **Tanker Truck Driver**
- ⛽ **Gas Station Manager**
- 🏢 **Fuel Supplier**

This project focuses on demonstrating user interface design, navigation flow, and feature interaction rather than implementing a complete production backend. A lightweight local JSON database is used to simulate data storage and authentication.

---

# Project Structure

```
lib/
│
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── routes/
│   ├── services/
│   ├── utils/
│   └── widgets/
│
├── data/
│   ├── json/
│   ├── models/
│   ├── repositories/
│   └── local_database/
│
├── features/
│   ├── authentication/
│   ├── driver/
│   ├── station_manager/
│   ├── supplier/
│   ├── notifications/
│   ├── profile/
│   └── settings/
│
<<<<<<< Updated upstream
├── shared/
│   ├── widgets/
│   ├── models/
│   └── providers/
│
└── assets/
    ├── images/
    ├── icons/
    ├── animations/
    └── mock_data/
=======
└── shared/
    └── widgets/
        ├── bottom_nav_bar.dart        # WaterDropNavBar wrapper
        ├── logout_dialog.dart         # Confirmation dialog
        ├── onboarding.dart            # Role-based onboarding overlay
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
>>>>>>> Stashed changes
```

---

# Directory Overview

## `main.dart`

Application entry point that launches the Flutter application.

---

## `app.dart`

Contains the root application configuration including:

- MaterialApp
- Application theme
- Initial route
- Route configuration

---

# Core

The **core** directory contains reusable resources that are shared across the entire application.

```
core/
```

### `constants/`

Stores application-wide constants.

Examples:

- Colors
- Strings
- User roles
- API constants

---

### `theme/`

Contains the application's visual styling.

Examples:

- Color palette
- Typography
- Button themes
- Input decoration themes

<<<<<<< Updated upstream
---
=======
### Onboarding

On first login, each role sees a role-specific introduction overlay with feature overview pages (illustrated with screenshots), a step progress timeline, and a preferences setup page (theme: System/Light/Dark, notification toggle). The overlay can be skipped at any time.

### Driver
>>>>>>> Stashed changes

### `routes/`

Responsible for application navigation.

Contains:

<<<<<<< Updated upstream
- Named routes
- Route generator
- Navigation configuration
=======
**Vehicle Maintenance** — full request lifecycle from the driver's perspective. Shows the assigned truck info, pending requests (with edit button), scheduled & in-progress items (with priority indicators), rejected requests (with reason and resubmit button), and completed service history (with dates and costs). A "Request" button opens a dialog to submit a new request (type, description, priority, preferred date). Pending requests can be edited in-place; rejected requests can be resubmitted after addressing the rejection reason.
>>>>>>> Stashed changes

---

### `services/`

Provides reusable services used throughout the application.

Examples:

- Authentication service
- JSON reader
- Notification service
- Location service

---

### `utils/`

<<<<<<< Updated upstream
Utility functions and helper classes.
=======
**Maintenance** — full maintenance lifecycle management covering driver-submitted requests. KPI row (Total, Pending, In Progress, Overdue, Completed), cost analytics (Total Spent, Avg per Request, In Progress, Completed) with a cost-by-type bar chart, requests-by-type bar chart, status-distribution pie chart, and three-column record list (Pending Requests / Active / Service History). Pending requests show an "Approve/Reject" dialog (approve with scheduled date and note, or reject with required reason). The status workflow progresses through Pending → Scheduled → In Progress → Completed, with progress notes on each transition and cost recording on completion. Cancelled records display the rejection reason. Each record card shows type, vehicle, status/priority badges, dates, assigned user, cost, notes, and contextual action buttons based on current status.
>>>>>>> Stashed changes

Examples:

- Validators
- Date formatting
- Extensions
- Common helper methods

---

### `widgets/`

Reusable widgets shared across multiple screens.

Examples:

- Custom buttons
- Custom text fields
- Loading indicators
- Cards
- Dialogs

---

# Data

The **data** folder stores models and handles local data access.

```
data/
```

---

## `json/`

Contains mock JSON files used as a lightweight local database.

Examples:

```
users.json
stations.json
deliveries.json
notifications.json
fuel_inventory.json
```

---

## `models/`

Defines the application's data models.

Examples:

- User
- Driver
- Delivery
- Station
- Truck
- Notification

---

## `repositories/`

Acts as the bridge between the UI and local JSON data.

Responsibilities include:

- Reading JSON
- Parsing models
- Returning data to the application

---

## `local_database/`

Provides helper classes for local storage implementation.

This layer can later be replaced with:

- SQLite
- Hive
- Firebase
- REST API

without affecting the application's presentation layer.

---

# Features

The application is organized using a **feature-first architecture**, where each major system has its own module.

---

## `authentication/`

Handles user authentication.

Includes:

- Login
- Registration
- Forgot Password
- Role selection

---

## `driver/`

Features available to tanker truck drivers.

Examples:

- Dashboard
- Assigned deliveries
- Route information
- Delivery history
- Delivery status updates

---

## `station_manager/`

Features available to gas station managers.

Examples:

- Inventory monitoring
- Incoming deliveries
- Delivery confirmation
- Fuel requests
- Reports

---

## `supplier/`

Features available to fuel suppliers or administrators.

Examples:

- Dashboard
- Driver management
- Delivery scheduling
- Fleet monitoring
- Station management
- Analytics

---

## `notifications/`

Centralized notification system.

Examples:

- Delivery assignments
- Delivery completion
- Fuel alerts
- System announcements

---

## `profile/`

Contains user profile management.

Examples:

- Personal information
- Edit profile
- Change password

---

## `settings/`

Application preferences.

Examples:

- Theme
- About
- Help
- Logout

---

# Shared

The **shared** folder contains resources used across multiple features.

---

## `widgets/`

Reusable UI components.

Examples:

- Delivery cards
- Custom AppBar
- Bottom navigation
- Status indicators

---

## `models/`

Shared model classes referenced by multiple modules.

---

## `providers/`

Application state management.

Examples:

- Authentication provider
- Theme provider
- Delivery provider

---

# Assets

Stores all application resources.

```
assets/
```

---

## `images/`

Application images and illustrations.

---

## `icons/`

Custom icons and SVG assets.

---

## `animations/`

Lottie animations and motion assets.

---

## `mock_data/`

Additional mock datasets for prototyping.

---

# Architecture

This project follows a **Feature-First Architecture**, which organizes files by application functionality instead of file type.

Benefits include:

- Easier maintenance
- Better scalability
- Clear separation of responsibilities
- Reusable components
- Simplified collaboration

---

# Technology Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Mobile UI Framework |
| Dart | Programming Language |
| JSON | Mock Local Database |
| Provider / Riverpod *(optional)* | State Management |
| Material Design 3 | UI Components |

---

# User Roles

## 🚚 Tanker Truck Driver

- View assigned deliveries
- Navigate delivery routes
- Update delivery progress
- Receive notifications

---

## ⛽ Gas Station Manager

- Monitor fuel inventory
- Receive fuel deliveries
- Confirm delivery completion
- Request fuel replenishment

---

## 🏢 Fuel Supplier

- Manage fuel stations
- Manage drivers
- Schedule deliveries
- Monitor fleet operations
- View reports and analytics

---

# Future Improvements

The current project serves as a high-fidelity prototype. Future enhancements may include:

- Firebase Authentication
- Cloud Firestore
- REST API integration
- GPS tracking
- Real-time notifications
- Offline synchronization
- IoT sensor integration
- QR code delivery verification
- Analytics dashboard
- Role-based authorization

---

# License

This project is intended for educational and prototyping purposes.
