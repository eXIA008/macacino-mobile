# 🍌 Macacino Mobile

A modern mobile application featuring document management, PDF viewing/generation, and audio capabilities with a clean, intuitive user interface.

## Overview

Macacino is a feature-rich mobile application with modern design principles and best practices. It includes authentication, document management, PDF handling, local storage, and audio functionality with a Material 3 design system.

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

## Resources

- [Dart Documentation](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [Syncfusion Docs](https://help.syncfusion.com/flutter/introduction/overview)
- [Material 3 Design](https://m3.material.io/)

---

## License

This project is proprietary and provided for portfolio/showcase purposes only. 
See [LICENSE](./LICENSE) for details — no reuse, modification, or distribution 
is permitted without explicit permission.

---
