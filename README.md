# 📅 ScheldulEase  

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
- **Schedule service** – Express, Sequelize, and PostgreSQL backend.
- **Cloud SQL Proxy** – Secure database connectivity.  

### **Setup**  
1. **Clone the repository**  
   ```sh
   git clone https://github.com/your-username/ScheldulEase.git
   cd ScheldulEase

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

### **Prerequisites**  
Ensure you have the following installed:  
- Flutter SDK  
- Dart  
- PostgreSQL  
- A running Schedule service and PostgreSQL database
