# 🍌 Macacino Mobile

A modern mobile application featuring document management, PDF viewing/generation, and audio capabilities with a clean, intuitive user interface.

## Overview

Macacino is a feature-rich mobile application with modern design principles and best practices. It includes authentication, document management, PDF handling, local storage, and audio functionality with a Material 3 design system.

---

## Getting Started

Follow these steps to set up and run the project locally on your machine.

### Prerequisites

Before you begin, make sure you have the following installed:

* [SDK](https://docs.flutter.dev/get-started/install) (version `^3.11.5` or higher)
* [Dart SDK](https://dart.dev/get-started)
* **IDE/Text Editor**: 
  * [VS Code](https://code.visualstudio.com/) with extensions, or
  * [Android Studio](https://developer.android.com/studio)
* [Git](https://git-scm.com/)

### Installation & Setup

1. **Clone the Repository**

   Clone this repository to your local machine:
   ```bash
   git clone https://github.com/eXIA008/macacino-mobile.git
   cd macacino-mobile
   ```

2. **Install Dependencies**

   Run the following command to download and install all required packages:
   ```bash
   pub get
   ```

3. **Verify Your Environment Setup**

   Ensure your development environment and target devices are ready:
   ```bash
   doctor
   ```

   Address any issues flagged before proceeding.

---

## Running the App

### Prerequisites for Running
- An emulator/simulator running, or
- A physical device connected via USB with USB debugging enabled

### Steps

1. **List Connected Devices**

   Check available devices/platforms (Android, iOS, Web, Windows, macOS, etc.):
   ```bash
   devices
   ```

2. **Run the Project**

   Run the application in debug mode:
   ```bash
   run
   ```

   **If you have multiple devices connected**, specify the target device ID:
   ```bash
   run -d <device-id>
   ```

3. **Run in Release Mode** (Optional)

   For production-like performance:
   ```bash
   run --release
   ```

---

## Project Structure

```
lib/
├── main.dart                 # App entry point and configuration
├── constants/
│   └── api_constants.dart   # API base URL and endpoints
├── providers/
│   ├── auth_provider.dart   # Authentication state management
│   └── document_provider.dart # Document management state
├── screens/
│   ├── auth_screen.dart     # Login/Authentication UI
│   └── main_shell.dart      # Main app shell/navigation
├── services/
│   └── api_service.dart     # API request handling
└── widgets/                  # Reusable UI components
```

---

## Key Features

✨ **Modern Design**
- Material 3 design system with custom color scheme
- Warm, elegant color palette (Primary: #B45309)
- Responsive layouts for all screen sizes

🔐 **Authentication**
- Secure user login and session management
- Token-based authentication
- Persistent login state

📄 **Document Management**
- PDF viewing and generation
- File upload and download capabilities
- Document organization and storage

🎵 **Audio Support**
- Audio playback functionality
- Integrated audio controls

💾 **Local Storage**
- Persistent user data storage
- API base URL configuration storage

🌍 **Internationalization**
- Multi-language support with date and time formatting

🔗 **URL Handling**
- Deep linking and URL launching capabilities

---

## Core Technologies & Packages

### State Management
- **provider** - Efficient state management and dependency injection

### Networking & API
- **http** - HTTP client for API requests
- **http_parser** - HTTP parsing utilities

### PDF Handling
- **syncfusion_flutter_pdf** - PDF generation capabilities
- **syncfusion_flutter_pdfviewer** - PDF viewing and display

### File Operations
- **file_picker** - File selection from device storage
- **path_provider** - Access to device file system paths

### Local Storage
- **shared_preferences** - Key-value persistent storage

### UI & Media
- **google_fonts** - Custom Google Fonts integration
- **audioplayers** - Audio playback functionality
- **percent_indicator** - Progress indicators
- **intl** (v0.20.2) - Internationalization and date formatting
- **url_launcher** - Open URLs and launch external apps

### Platform & Design
- **Material Design 3** - Modern material design system
- **Cupertino Icons** - iOS-style icons

---

## App Configuration

### Theme

The app uses a custom Material 3 theme with the following configuration:

```
ColorScheme:
  Primary: #B45309 (Brown/Amber)
  Secondary: #B45309
  Surface: #FFFFFF
  Text: #0F172A (Dark Blue)
```

### API Configuration

API base URL can be:
- Set at runtime via local storage
- Modified through the app settings
- Configure in `constants/api_constants.dart`

---

## Environment

- **Channel**: Stable
- **SDK**: `^3.11.5`
- **Min SDK**: 3.11.5+
- **Supported Platforms**: Android, iOS, Web, Windows, macOS, Linux

---

## Development

### Building for Different Platforms

**Android:**
```bash
build apk          # Debug APK
build apk --release # Release APK
```

**iOS:**
```bash
build ios          # Debug build
build ios --release # Release build
```

**Web:**
```bash
build web
```

### Running Tests

```bash
test
```

### Code Analysis

```bash
analyze
```

---

## Project Metadata

- **Project Name**: macacino-mobile
- **Version**: 1.0.0+1
- **Language**: Dart
- **Created**: June 11, 2026
- **Last Updated**: June 29, 2026
- **Visibility**: Public
- **License**: Not specified

---

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bug reports and feature requests.

### Guidelines
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## Troubleshooting

### Common Issues

**Environment setup issues:**
```bash
doctor --android-licenses  # Accept platform licenses
doctor                      # Re-run after accepting
```

**Dependencies not installing:**
```bash
clean
pub get
```

**Device not recognized:**
- Ensure USB debugging is enabled on Android devices
- Accept USB debugging prompt on the device
- Check device drivers are installed

**App crashes on startup:**
- Run `clean`
- Rebuild the app with `run`
- Check console output for error messages

---

## Resources

- [Dart Documentation](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [Syncfusion Docs](https://help.syncfusion.com/flutter/introduction/overview)
- [Material 3 Design](https://m3.material.io/)

---

## License

This project is currently unlicensed. See the repository for more details.

---

## Support

For questions or support, please open an issue on the [GitHub repository](https://github.com/eXIA008/macacino-mobile/issues).

---

**Made with ❤️ by [eXIA008](https://github.com/eXIA008)**
