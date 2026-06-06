# Incident Reporting & Smart Dashboard

A Flutter mobile application for reporting public incidents (damaged roads, floods, etc.) with real-time status tracking and an admin dashboard.

> **Status: In Progress**

## Screenshots
<img width="2880" height="1532" alt="image" src="https://github.com/user-attachments/assets/313462ef-c0b8-402b-9700-7b7db01bf596" />
<img width="2880" height="1533" alt="image" src="https://github.com/user-attachments/assets/34d98552-5cfd-4d0c-bb1f-bcde7625f59d" />
<img width="2880" height="1529" alt="image" src="https://github.com/user-attachments/assets/d6c1ef38-3158-44c9-b5dc-29cf02d56258" />
<img width="2880" height="1528" alt="image" src="https://github.com/user-attachments/assets/619401be-fc7d-4c83-9d32-025c4d31c098" />
<img width="2880" height="1533" alt="image" src="https://github.com/user-attachments/assets/b5d9baf2-227c-4d68-aabc-8d4a17dabdf1" />

## Features
- Authentication with Role-Based Access Control (Admin & User)
- Incident reporting with photo upload & location tagging
- Status tracking: Pending → In Progress → Resolved
- QR Code generation per report for quick status check
- Map integration via OpenStreetMap
- Light / Dark mode
- Admin dashboard: view & update report status

## Tech Stack
- **Framework:** Flutter (Dart)
- **Backend & Storage:** Supabase
- **Maps:** OpenStreetMap (flutter_map)
- **Auth:** Supabase Auth with RBAC

## Getting Started

### Prerequisites
- Flutter SDK
- Supabase project setup

### Installation
1. Clone the repo
   ```bash
   git clone https://github.com/valmosee/incident-reporting.git
   ```
2. Install dependencies
   ```bash
   flutter pub get
   ```
3. Configure Supabase credentials in `.env` or `supabase_config.dart`
4. Run the app
   ```bash
   flutter run
   ```

## Team & Contribution

This project was built by 3 people. I was the one who initiated the concept and handled task delegation.

| Member | Contributions |
|--------|--------------|
| Joice | Project idea & task delegation, Create report, View report detail, Report history, OpenStreetMap integration |
| Louis | Admin: view report list, update report status, QR Code generation & scanner |
| Darrel | Login, Register, Profile, Change password, Light/Dark mode |

## 📄 License
This project is for educational purposes.
