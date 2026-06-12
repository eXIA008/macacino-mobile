# Panduan Pengujian Aplikasi di Perangkat Mobile (Android & iOS)

Dokumen ini berisi panduan langkah demi langkah untuk menguji aplikasi **Flutter Macacino** di perangkat handphone Anda (fisik maupun emulator), setelah sebelumnya Anda hanya melakukan pengujian menggunakan browser Edge di Windows.

---

## DAFTAR ISI
1. [Metode 1: Menguji Lewat Mobile Browser (Tanpa Setup SDK)](#metode-1-menguji-lewat-mobile-browser-tanpa-setup-sdk)
2. [Metode 2: Menguji Sebagai Aplikasi Android Native (HP Fisik / Emulator)](#metode-2-menguji-sebagai-aplikasi-android-native-hp-fisik--emulator)
   - [Langkah A: Setup Android SDK & Toolchain](#langkah-a-setup-android-sdk--toolchain)
   - [Langkah B: Menggunakan HP Android Asli (Rekomendasi)](#langkah-b-menggunakan-hp-android-asli-rekomendasi)
   - [Langkah C: Menggunakan Emulator (Virtual Device)](#langkah-c-menggunakan-emulator-virtual-device)
3. [Metode 3: Build & Install File APK secara Permanen](#metode-3-build--install-file-apk-secara-permanen)
4. [Catatan Khusus untuk iOS (iPhone) di Windows](#catatan-khusus-untuk-ios-iphone-di-windows)

---

## 1. Metode 1: Menguji Lewat Mobile Browser (Tanpa Setup SDK)

Metode ini adalah cara paling instan untuk melihat tampilan mobile di HP (Android/iOS) tanpa perlu mengunduh Android Studio. Aplikasi akan dijalankan sebagai web server lokal di laptop, dan diakses menggunakan browser HP Anda.

### Langkah-langkah:
1. **Hubungkan HP dan Laptop ke jaringan Wi-Fi yang sama.**
2. **Cari IP Address Laptop Anda:**
   Buka terminal/PowerShell di laptop Anda dan jalankan perintah:
   ```bash
   ipconfig
   ```
   Cari baris `IPv4 Address` di bawah adapter Wi-Fi aktif Anda (contoh: `192.168.1.15`).
3. **Jalankan Flutter Web Server:**
   Buka terminal proyek Anda dan jalankan:
   ```bash
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```
4. **Akses dari Browser HP:**
   Buka browser (Chrome, Safari, dll.) di HP Anda dan ketikkan alamat:
   ```text
   http://<IP-LAPTOP-ANDA>:8080
   ```
   *(Contoh: http://192.168.1.15:8080)*

---

## 2. Metode 2: Menguji Sebagai Aplikasi Android Native (HP Fisik / Emulator)

Untuk menjalankan aplikasi ini sebagai aplikasi Android native `.apk` dengan performa sesungguhnya, Anda harus mempersiapkan Android SDK terlebih dahulu.

### Langkah A: Setup Android SDK & Toolchain
1. **Unduh Android Studio:**
   Download installer dari [Android Studio Official Website](https://developer.android.com/studio) dan lakukan instalasi dengan opsi default.
2. **Instal SDK Command-line Tools:**
   - Buka Android Studio.
   - Pilih menu **Tools > SDK Manager** (atau ikon tiga titik di kanan atas).
   - Masuk ke tab **SDK Tools**.
   - Centang **Android SDK Command-line Tools (latest)**.
   - Klik **Apply** lalu tunggu hingga selesai.
3. **Setujui Lisensi Android:**
   Buka terminal Windows Anda dan jalankan perintah berikut:
   ```bash
   flutter doctor --android-licenses
   ```
   Tekan tombol `y` lalu Enter untuk setiap pertanyaan yang muncul sampai selesai.
4. **Cek Kesiapan Sistem:**
   Jalankan `flutter doctor` di terminal. Pastikan baris **Android toolchain** sudah tercentang hijau (`[√]`).

---

### Langkah B: Menggunakan HP Android Asli (Rekomendasi)
Menjalankan langsung di HP asli memberikan performa terbaik dan hemat memori laptop.

1. **Aktifkan Opsi Developer & USB Debugging di HP Anda:**
   - Buka **Settings (Pengaturan)** di HP Anda.
   - Masuk ke **About Phone (Tentang Ponsel)**.
   - Cari **Build Number (Nomor Bentukan)** dan ketuk sebanyak **7 kali** berturut-turut hingga muncul tulisan *"You are now a developer!"*.
   - Kembali ke menu utama Settings, buka **Developer Options (Pilihan Pengembang)**.
   - Aktifkan opsi **Developer Options** dan **USB Debugging**.
2. **Hubungkan HP ke Laptop:**
   - Gunakan kabel USB yang berkualitas.
   - Jika muncul pop-up perizinan USB Debugging di layar HP Anda, pilih **Allow (Izinkan)** atau **Always Allow**.
3. **Deteksi Perangkat di Laptop:**
   Jalankan perintah ini di terminal proyek:
   ```bash
   flutter devices
   ```
   Pastikan nama perangkat HP Anda muncul di daftar perangkat yang terhubung.
4. **Jalankan Aplikasi:**
   Mulai jalankan aplikasi dengan perintah:
   ```bash
   flutter run
   ```
   *(Pilih nomor perangkat HP Anda jika diminta).*

---

### Langkah C: Menggunakan Emulator (Virtual Device)
Jika Anda tidak memiliki HP Android fisik, Anda bisa menggunakan HP virtual di layar laptop.

1. Buka Android Studio.
2. Buka **Device Manager** (Virtual Device Manager).
3. Klik **Create Device**, pilih tipe HP yang diinginkan (contoh: Pixel 7).
4. Pilih dan unduh System Image Android yang disarankan (contoh: API 33/34 / Android 13/14).
5. Klik tombol **Play (Run)** untuk menyalakan emulator di layar laptop.
6. Setelah emulator menyala, jalankan perintah ini di terminal proyek:
   ```bash
   flutter run
   ```

---

## 3. Metode 3: Build & Install File APK secara Permanen

Jika Anda ingin menginstal aplikasi secara permanen di HP Anda tanpa harus terus terhubung ke laptop/terminal:

1. **Jalankan Build APK Rilis:**
   Buka terminal proyek dan jalankan:
   ```bash
   flutter build apk --release
   ```
   *Catatan:* Flutter secara otomatis akan mengalihkan koneksi API ke alamat produksi di **`https://macacino.vercel.app`** dan menyembunyikan menu pengaturan IP server pada mode rilis ini.
2. **Temukan File APK:**
   Setelah proses build selesai, file APK Anda akan tersimpan di:
   `build/app/outputs/flutter-apk/app-release.apk`
3. **Kirim dan Instal ke HP:**
   - Kirim file `app-release.apk` tersebut ke HP Anda (bisa lewat WhatsApp, Google Drive, atau kabel data).
   - Buka file APK tersebut di HP Anda untuk melakukan instalasi (izinkan instalasi dari sumber tidak dikenal jika diminta oleh sistem).

---

## 4. Catatan Khusus untuk iOS (iPhone) di Windows

> [!WARNING]
> Apple mewajibkan penggunaan sistem operasi **macOS** dan aplikasi **Xcode** untuk melakukan kompilasi/build aplikasi iOS native (`.ipa`) atau menjalankan simulator iPhone.
>
> **Solusi Alternatif di Windows:**
> 1. Gunakan **Metode 1 (Web Server)** untuk menguji performa dan UI aplikasi langsung melalui browser Safari di iPhone Anda.
> 2. Menggunakan layanan cloud build seperti [Codemagic](https://codemagic.io/) atau GitHub Actions untuk mem-build file `.ipa` secara otomatis dari repositori Git Anda jika ingin diuji di HP iPhone secara native.
