# Flutter Macacino

A Flutter application built with modern design principles.

## Getting Started

Follow these steps to set up and run the project locally on your machine.

### Prerequisites

Before you begin, make sure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (matching the SDK version in `pubspec.yaml`, Dart SDK `^3.11.5` or higher)
* [Dart SDK](https://dart.dev/get-started) (included with Flutter)
* An IDE/Text Editor: [VS Code](https://code.visualstudio.com/) with Flutter extensions, or [Android Studio](https://developer.android.com/studio)
* Git

---

### Installation & Setup

1. **Clone the Repository**
   Clone this repository to your local machine using Git:
   ```bash
   git clone <your-repository-url>
   ```

2. **Navigate to the Project Directory**
   ```bash
   cd flutter_macacino
   ```

3. **Install Dependencies**
   Run the following command to download and install all required packages listed in `pubspec.yaml`:
   ```bash
   flutter pub get
   ```

4. **Verify Your Environment Setup**
   Ensure your development environment and target devices are ready:
   ```bash
   flutter doctor
   ```

---

### Running the App

To run the app, make sure you have an emulator/simulator running, or a physical device connected.

1. **List Connected Devices**
   Check the available devices/platforms (Android, iOS, Web, Windows, macOS, etc.):
   ```bash
   flutter devices
   ```

2. **Run the Project**
   Run the application in debug mode:
   ```bash
   flutter run
   ```
   *If you have multiple devices connected, specify the target device ID:*
   ```bash
   flutter run -d <device-id>
   ```

---

### Key Features & Packages Used
This project utilizes the following main libraries:
* **State Management**: `provider`
* **Network Requests**: `http`, `http_parser`
* **PDF viewer/generator**: `syncfusion_flutter_pdf`, `syncfusion_flutter_pdfviewer`
* **File Operations**: `file_picker`, `path_provider`
* **Local Storage**: `shared_preferences`
* **UI & Audio**: `google_fonts`, `audioplayers`, `percent_indicator`, `intl`, `url_launcher`
