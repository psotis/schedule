# 📅 Rantevia

A Flutter project helping companies to book and track their appointments.  

## 🚀 Features  
- 📅 **Appointment Booking** – Easily schedule appointments with an intuitive calendar interface.  
- 🔄 **Live Updates** – Appointment and customer screens refresh from the service.
- 👥 **User Management** – Secure authentication and user roles.  
- 📊 **Dashboard** – View upcoming appointments and analytics.  
- 📩 **Notifications** – Receive reminders via email or push notifications.  

## 🛠️ Technologies Used  
- **Flutter** – Frontend framework for cross-platform support.  
- **Provider** – State management for efficient UI updates.  
- **PostgreSQL** – Secure and scalable database.  
- **Rantevia service** – Express, Sequelize, and PostgreSQL backend.
- **Cloud SQL Proxy** – Secure database connectivity.  

### **Setup**  
1. **Clone the repository**  
   ```sh
   git clone <repository-url>
   cd schedule
   ```

## 🔧 Installation  
- flutter pub get
- flutter run

Copy `.env.example` to `.env` and configure the service URL and Google OAuth
client IDs. Pass these values with `--dart-define` when building or running the
app; `.env` is deliberately not bundled as a public Flutter asset. `localhost`
works for web, desktop, and the iOS simulator. Use
`10.0.2.2` for an Android emulator or the development computer's LAN address
for a physical device.

The app authenticates directly with the Schedule service. New owners select a
business type during registration, and tenant requests use the authenticated
session's active store rather than passing a user ID through the widget tree.
Customer, employee, appointment, and finance views use one authenticated,
store-scoped WebSocket connection for change notifications. The affected REST
resource is reloaded when the service reports a successful change; the app does
not poll these endpoints on a timer.

### Store workflows

- Settings → Access: create an employee account by selecting an existing employee,
  entering their email and an initial password. The account is linked to that store;
  the employee signs in on the normal login page. Existing accounts can also be linked.
- Staff can access their assigned appointments and customers. Store owners and admins
  can access finances, team management and store-wide reports. A shared appointment's
  schedule and service assignments are managed by an owner or admin.
- Settings → Reports: select a date range to see service and employee performance,
  busiest weekdays, peak hours and busiest dates in the store's timezone.
- Settings → Team → Services: explicitly select the services each employee can perform.
  New service assignments only offer qualified employees. Existing recorded assignments
  remain intact when editing historical appointments.
- Appointment history → Edit: change individual services, employees, prices and durations.
  Existing service prices and durations remain snapshots when the catalog changes.
- The appointment-level employee selector is optional and available even without a
  service. It supplies the default worker for services; individual service workers
  can still be overridden when a booking involves multiple employees.
- Completion and payments are managed from appointment history or the calendar's
  completion/payment button. Each new payment creates its matching income entry.
  Owners/admins can reverse a payment from its payment history. Historical balances
  are preserved without creating duplicate historical income entries.

For local web development, start the service and run:

```sh
flutter run -d web-server --web-hostname localhost --web-port 8080 --dart-define=API_BASE_URL=http://localhost:4001/api/v1
```

Pass Google OAuth client IDs separately with `--dart-define` as required by your
environment. Never pass a server `.env` file into the public web bundle.

### **Prerequisites**  
Ensure you have the following installed:  
- Flutter SDK  
- Dart  
- PostgreSQL  
- A running Schedule service and PostgreSQL database

### Saved display layouts

Use the calendar layout selector to choose Day, Week, Work Week, Agenda,
Month Agenda, employee timeline, the four timeline views, Heat Map, or Daily
Summary. Daily Summary adapts the Fare Calendar layout to appointment counts and
booked minutes. Cancelled appointments are excluded from the daily summaries;
the selected-day agenda keeps their records accessible. Employee rows show the
whole booking for each participating employee and include unassigned bookings.
Employee changes continue through the appointment editor and its availability
checks; dragging between employee rows does not reassign a booking.

Calendar and customer/employee list-grid choices are saved by the service for
each user and active store and restored after login. These choices also apply
when switching device sizes. Defaults remain Day on mobile, Work Week on larger
screens, and List for customers and employees until a choice is saved.

### Rantevia branding

The editable icon master is `assets/rantevia_icon.svg`; its PNG export is
`assets/rantevia_icon.png`. Regenerate web, Android, iOS, macOS, and Windows
launcher assets with `dart run flutter_launcher_icons`. Display names are
Rantevia; existing package IDs, bundle IDs, storage keys, and API paths remain
unchanged for compatibility with installed apps and Google login.

### Public landing page and application entry

The site root (`/` or `/index.html`) is a public Greek-language HTML landing
page. Its content, business types, navigation, and FAQ are readable without
JavaScript. `web/landing.css` provides responsive styling and reuses the bundled
IBM Plex Sans fonts. `web/landing.js` handles the mobile menu and loads Flutter
only on application paths such as `/login`, `/home`, `/app`, and `/user-admin`,
or on legacy `/#/...` application links. Normal section anchors stay on the
landing page. Existing API routes, authentication, and browser storage keys are
unchanged.

The login buttons point to `/login`. The web manifest also starts installed apps
there. `web/flutter_bootstrap.js` uses Flutter's template placeholders and does
not register an offline service worker. App startup retires only legacy Flutter
service workers and their caches, preserving authentication storage.

Nginx serves the landing page and application from the same web build. Application
routes receive an `X-Robots-Tag: noindex, nofollow` header; the public page has its
own description, language, canonical link, social metadata, and SoftwareApplication
structured data. The canonical link resolves to the deployed site's root, so no
unregistered domain is assumed. Configure the real production service URL and
Google OAuth origin before deployment. This prepares the page for indexing but
does not guarantee search rankings.

The native splash generator has web output disabled so regenerating Android/iOS
splash screens does not overwrite the public web page.

### Keeping the public calendar preview accurate

The landing page uses `web/images/calendar-preview.png`, exported from the real
`SyncFusionCalendar` widget using fictional appointments and mock repositories.
It is not a separately drawn product mockup and never reads the local database.
After calendar UI changes, regenerate it with:

```sh
flutter test --no-pub --dart-define=UPDATE_CALENDAR_PREVIEW=true test/calendar_preview_test.dart
```

The export test is skipped during ordinary test runs. The landing caption states
that this is the Day view with demonstration data, and the image can be opened at
full resolution.

### Store working days and navigation

Managers can choose store opening days in **Ρυθμίσεις → Λειτουργία**. Both Work
Week layouts use these days; Week continues to show all seven days. Stores without
an explicit choice retain Monday–Friday. The setting is stored additively as ISO
weekday numbers (Monday=1, Sunday=7) in `stores.settings.working_days`; updating it
preserves other settings. Employee availability and booking validation remain
separate. Calendar clients refresh this setting on store realtime events.

The sidebar arrow switches desktop/tablet navigation between expanded and compact
layouts without replacing the current page. The choice is saved per authenticated
store membership as `ui_preferences.sidebar_layout`. Mobile navigation is unchanged.
