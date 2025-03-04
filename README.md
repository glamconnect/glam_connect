# Glam Connect

A Flutter application that connects users with salons and beauty professionals for booking beauty services.

## Features

- **OTP-based Authentication**: Secure phone number verification
- **Multiple User Roles**:
  - Normal User: Book appointments, view salons, manage profile
  - Super Admin: Manage salons, salon admins, and monitor app analytics
  - Salon Admin: Manage services, employees, and booking slots
  - Employee: View schedule, confirm services, and receive ratings
- **Salon Discovery**: Browse and search for salons
- **Appointment Booking**: Book appointments with preferred professionals
- **Real-time Updates**: Get notifications about appointment status changes

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Riverpod
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Notifications**: Firebase Cloud Messaging

## Project Structure

```
lib/
├── models/         # Data models
├── screens/        # UI screens
│   ├── auth/       # Authentication screens
│   ├── user/       # Normal user screens
│   ├── admin/      # Super admin screens
│   ├── salon/      # Salon admin screens
│   └── employee/   # Employee screens
├── widgets/        # Reusable UI components
│   ├── common/     # Shared widgets
│   └── auth/       # Authentication widgets
├── services/       # API and Firebase services
├── providers/      # Riverpod providers
└── utils/          # Utility functions and constants
```

## Setup Instructions

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Create a Firebase project and add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Enable Firebase Authentication (Phone) and Firestore in your Firebase project
5. Run the app with `flutter run`

## Reusable Components

The app is built with reusability in mind, featuring:

- Custom text fields with consistent styling
- Reusable buttons with loading states
- Authentication screens with shared components
- Consistent theming across the app
