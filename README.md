### 🚆 CargoGuardian - IoT-Based Train Cargo Management System

**CargoGuardian** is a smart, IoT-powered system that automates the monitoring, clearance, and tracking of train cargo. Designed for efficiency, safety, and transparency, it enables railway operators to detect overloading, prevent theft, and keep accurate, automated records of cargo movement — all through a centralized, cross-platform application powered by advanced graph database intelligence.

🌐 [Try the Live App](https://vector-shield-io-t-based-train-cargo-managment-system.vercel.app/)

🏆 Developed at **HackHiest Hackathon 2025**, awarded **2nd Runner-Up**.

---

## 📦 Project Overview

CargoGuardian enhances railway logistics through **automated weight monitoring**, **live GPS tracking**, and **remote clearance capabilities**. By integrating IoT sensors with a smart app interface and an advanced logistics graph database, it:

- Detects **overload/underload conditions** and blocks unsafe cargo.
- Uses **RFID or mobile app** for clearance—both online and offline.
- Prevents cargo theft via **access control and live monitoring**.
- Logs every cargo's **origin, destination, timestamp, and status** automatically for full documentation and accountability.
- Employs **advanced route optimization** and **logistics intelligence** using TigerGraph.

---

## 🚀 Key Features

### 📉 Real-Time Load Monitoring
- Detects overload/underload conditions on cargo wagons
- Displays color-coded alerts: ✅ Green (Normal), ⚠️ Yellow (Underload), 🚫 Red (Overload)
- Automates weight checks to remove manual paperwork

### 📍 Live GPS Tracking & Route Optimization
- Monitors train location in real-time
- Tracks routes, journey status, and ETA
- Leverages graph algorithms to compute optimal paths across complex rail networks
- Visual map interface for intuitive navigation

### 🔐 Anti-Theft Protection
- Uses RFID-based access control and tamper alerts
- Ensures only authorized clearance and access
- Detects unauthorized removal or tampering in cargo sections

### 🧠 Graph-Powered Intelligence & Analytics
- Deep connectivity analysis using TigerGraph
- Intelligent insights on cargo delays, network bottlenecks, and high-traffic nodes
- Stores digital cargo manifests and automates log retrieval for audits and reports

### 🧑‍💼 Role-Based Access System
CargoGuardian includes a hierarchical user access model:
- **Worker Level**: Can scan cargo, view current train status, and submit logs
- **Train Master Level**: Can view current and past train cargo logs, authorize train clearances
- **Admin/Authority Level**: Full access to all historical records, analytics dashboards, and permission management

### 🌐 Multi-Platform Access
- Works as a **web app, Android app, and iOS app**
- Responsive design for phones, tablets, and desktops
- Built with Flutter for consistent UX everywhere

---

## 🧰 Tech Stack

- **Frontend:** Flutter (cross-platform UI)
- **Middleware API:** FastAPI (Python REST API for secure backend communication)
- **Database & Intelligence:** TigerGraph (Graph Database, Route Optimization) & Firebase (Auth, Cloud Functions)
- **IoT Integration:** Blynk (sensor communication)
- **Maps & Location:** Google Maps API
- **Visualization:** FL Chart (for analytics dashboard)
- **Hardware:** ESP32/Arduino, GPS Module, RFID Units (for offline cargo clearance and anti-theft), Load cells

---

## 🏗️ System Architecture

- **Flutter App**: Unified interface for all platforms with interactive route and intelligence dashboards.
- **Middleware API**: A robust FastAPI bridge connecting the frontend with backend graph processing.
- **TigerGraph Cloud**: Handles deep logistics queries, journey optimization, and complex relationship mapping.
- **Firebase**: Manages real-time data sync, user authentication, and basic records.
- **IoT Layer**: Weight sensors, RFID units, and GPS modules feeding live data telemetry to the system.

---

## ⚙️ Getting Started

### 1. Set Up Middleware (FastAPI)

Navigate to the middleware directory, set up your Python environment, and start the local server:

```bash
cd middleware
pip install -r requirements.txt

# Start the FastAPI server
uvicorn main:app --reload
```
The middleware runs on `http://127.0.0.1:8000` and securely interfaces with TigerGraph.

### 2. Set Up the Flutter App

Navigate to the frontend directory:

```bash
cd CargoGuardian_Software
```

Install dependencies:
```bash
flutter pub get
```

Set up environment variables:
Create a `.env` file in the root of `CargoGuardian_Software` containing your map keys, API URLs, and configuration lines.

Run the Flutter app:
```bash
flutter run
```

---

## 👨‍💻 Team Members

- **Vaibhav Sharma**
- **Parth Garg**
- **Samarth Sharma**
- **Piyush**

> 🚆 Built with both **hardware (IoT)** and **software** components to create a complete cargo safety and logistics solution.

---

## 🖼️ Screenshots

![Image](https://github.com/user-attachments/assets/82ad6c49-187f-4098-a242-206c48c28ce6)
![Image](https://github.com/user-attachments/assets/1cf11547-aa73-4bac-b74e-e10809b2ee6c)
![Image](https://github.com/user-attachments/assets/396ac0ce-d3d4-4661-8eaa-bc0361695437)
