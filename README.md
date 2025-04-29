### 🚆 Vector Shield - IoT-Based Train Cargo Management System

**Vector Shield** is a smart, IoT-powered system that automates the monitoring, clearance, and tracking of train cargo. Designed for efficiency, safety, and transparency, it enables railway operators to detect overloading, prevent theft, and keep accurate, automated records of cargo movement — all from a single cross-platform application.

🌐 [Try the Live App](https://vector-shield-io-t-based-train-cargo-managment-system.vercel.app/)

🏆 Developed at **HackHiest Hackathon 2025**, awarded **2nd Runner-Up**.

---

## 📦 Project Overview

Vector Shield enhances railway logistics through **automated weight monitoring**, **live GPS tracking**, and **remote clearance capabilities**. By integrating IoT sensors with a smart app interface, it:

- Detects **overload/underload conditions** and blocks unsafe cargo.
- Uses **RFID or mobile app** for clearance—both online and offline.
- Prevents cargo theft via **access control and live monitoring**.
- Logs every cargo's **origin, destination, timestamp, and status** automatically for full documentation and accountability.

---

## 🚀 Key Features

### 📉 Real-Time Load Monitoring
- Detects overload/underload conditions on cargo wagons
- Displays color-coded alerts: ✅ Green (Normal), ⚠️ Yellow (Underload), 🚫 Red (Overload)
- Automates weight checks to remove manual paperwork

### 📍 Live GPS Tracking
- Monitors train location in real-time
- Tracks routes, journey status, and ETA
- Maps interface for visual navigation

### 🔐 Anti-Theft Protection
- Uses RFID-based access control and tamper alerts
- Ensures only authorized clearance and access
- Detects unauthorized removal or tampering in cargo sections

### 📄 Automated Cargo Documentation
- Records what cargo was sent, from where, to where, and when
- Stores digital cargo manifests automatically
- Easy to retrieve logs for audits, reports, and investigations

### 🧑‍💼 Role-Based Access System
Vector Shield includes a hierarchical user access model:
- **Worker Level**: Can scan cargo, view current train status, and submit logs
- **Train Master Level**: Can view current and past train cargo logs, authorize train clearances
- **Admin/Authority Level**: Full access to all historical records, analytics dashboards, and permission management
- This ensures sensitive data is protected and only visible to the appropriate user roles

### 🌐 Multi-Platform Access
- Works as a **web app, Android app, and iOS app**
- Responsive design for phones, tablets, and desktops
- Built with Flutter for consistent UX everywhere

---

## 🧰 Tech Stack

- **Frontend:** Flutter (cross-platform UI)
- **Backend:** Firebase (Auth, Realtime DB, Cloud Functions)
- **IoT Integration:** Blynk (sensor communication)
- **Maps & Location:** Google Maps API
- **Visualization:** FL Chart (for analytics dashboard)
- **RFID Hardware:** For offline cargo clearance and anti-theft

---

## 🌟 Why Vector Shield?

- 🔄 **Fully Automated**: Reduces manual checks and paperwork
- 🔐 **Secure & Accountable**: Prevents unauthorized cargo access
- 📊 **Transparent**: Cargo history and movement always documented
- 🛠️ **Scalable**: Easily add more sensors or wagons
- 🏆 **Proven Winner**: HackHiest 2025 2nd Runner-Up Project

---

## 🏗️ System Architecture

- **Flutter App**: Unified interface for all platforms
- **IoT Layer**: Weight sensors, RFID units, GPS modules
- **Backend Services**: Firebase handles data sync, auth, and cloud logic
- **RFID & Clearance Logic**: Works online or offline with token-based validation
- **Analytics Dashboard**: Visualizes status, routes, and history

---

## ⚙️ Getting Started

1. **Set Up Flutter Environment**
2. **Clone Repository**  
   ```bash
   git clone https://github.com/your-repo/vector-shield.git
   ```
3. **Install Dependencies**  
   ```bash
   flutter pub get
   ```
4. **Configure Firebase**  
   Add your Firebase project files (`google-services.json`, etc.)
5. **Connect IoT Devices**  
   Configure Blynk and RFID setup using provided device tokens
6. **Run the App**  
   Launch on web, Android, or iOS:
   ```bash
   flutter run
   ```

---

## 👨‍💻 Team Members

- **Vaibhav Sharma**
- **Parth Garg**
- **Samarth Sharma**
- **Piyush**

> 🚆 Built with both **hardware (IoT)** and **software** components to create a complete cargo safety solution.

---

## 🖼️ Screenshots

