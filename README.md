# Lost & Found Flutter App

A comprehensive Flutter application for reporting and finding lost items with admin approval system and Firebase integration.

## Features

### 🔍 **Core Functionality**
- **Post Lost Items**: Users can report lost items with photos, descriptions, and location
- **Post Found Items**: Users can report found items to help reunite with owners
- **Search & Filter**: Search items by category, date, and keywords
- **Real-time Updates**: Live updates using Firebase Firestore
- **Image Support**: Upload and display item photos using Base64 encoding

### 🔐 **Authentication System**
- **User Registration**: Create accounts with email/password
- **Secure Login**: Firebase Authentication integration
- **Profile Management**: User profiles with account information
- **Session Management**: Persistent login sessions

### 👨‍💼 **Admin Panel**
- **Admin-only Access**: Restricted to `admin@gmail.com`
- **Post Approval**: Approve or reject user submissions
- **Content Moderation**: Review all posts before they go live
- **Admin Dashboard**: Separate tabs for pending and all items

### 🗺️ **Location Services**
- **Google Maps Integration**: Pin exact locations of lost/found items
- **Location Picker**: Interactive map for selecting item locations
- **Address Resolution**: Automatic address lookup from coordinates

### 🔒 **Security Features**
- **Back Button Protection**: Prevents accidental logout
- **Admin Access Control**: Strict admin authentication
- **Input Validation**: Form validation and error handling
- **Firebase Security**: Secure backend with Firestore rules

## Technology Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication)
- **Maps**: Google Maps Flutter
- **UI**: Material Design with Google Fonts
- **Image Handling**: Base64 encoding (Firestore-compatible)
- **State Management**: StatefulWidget
- **Architecture**: Modular structure with services

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── lost_found_item.dart  # Item data model
├── screens/
│   ├── welcome_screen.dart   # App welcome/landing
│   ├── login_screen.dart     # User authentication
│   ├── register_screen.dart  # User registration
│   ├── home_screen.dart      # Main item listing
│   ├── profile_screen.dart   # User profile
│   ├── post_item_form.dart   # Create new posts
│   ├── item_details_screen.dart  # Item details view
│   ├── map_picker_screen.dart    # Location picker
│   ├── chat_screen.dart      # Chat functionality
│   └── admin_panel_screen.dart   # Admin dashboard
├── services/
│   ├── auth_service.dart     # Authentication logic
│   ├── firebase_service.dart # Firestore operations
│   └── admin_service.dart    # Admin functionality
└── widgets/
    └── item_list.dart        # Reusable item list widget
```

## Getting Started

### Prerequisites
- Flutter SDK (^3.7.2)
- Firebase project setup
- Google Maps API key
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mhmdizdn/lost-and-found-app.git
   cd lost-and-found-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Download `google-services.json` and place in `android/app/`

4. **Google Maps Setup**
   - Get Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Add the API key to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Admin Access

To access the admin panel:

1. **Create admin account**: Register with email `admin@gmail.com`
2. **Login as admin**: Use the admin credentials
3. **Access admin panel**: Go to Profile → Admin Panel
4. **Manage posts**: Approve or reject user submissions

## Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.2
  image_picker: ^1.0.4
  google_fonts: ^6.1.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.0
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.12.1
```

## Known Issues & Solutions

### Firebase Auth PigeonUserDetails Error
This app includes workarounds for the Firebase Auth type casting error that occurs in certain versions. The authentication still works correctly despite error messages in the console.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For support and questions, please open an issue in the GitHub repository.

---

**Built with ❤️ using Flutter and Firebase**
