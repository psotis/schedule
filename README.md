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
