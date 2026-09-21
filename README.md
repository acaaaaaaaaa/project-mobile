# 📱 FocusRoom - Study Group Anti-Distraction App
> **Project Mata Kuliah: Mobile and Wireless Computing**  
> Repository GitHub: [https://github.com/acaaaaaaaaa/project-mobile](https://github.com/acaaaaaaaaa/project-mobile)

FocusRoom adalah aplikasi cerdas untuk meningkatkan fokus saat belajar kelompok (baik tatap muka maupun daring) dengan mendeteksi pergerakan sensor smartphone anggota secara real-time dan memberikan peringatan nirkabel ke ruang belajar bersama ketika seseorang mengangkat gawainya.

---

## 🚀 Fitur Utama

1. **Room Collaboration System**:
   - Leader dapat membuat ruang belajar terkelola, menentukan durasi timer belajar, dan membagikan kode/link room.
   - Anggota kelompok dapat bergabung dengan kode room unik (`ROOM-XXXX`).

2. **Mobile Computing (Sensor Accelerometer Processing)**:
   - Membaca telemetri pergerakan 3-sumbu ($X$, $Y$, $Z$) secara real-time.
   - Deteksi otomatis saat HP diangkat dari meja menggunakan kalkulasi *delta magnitude acceleration* ($M = \sqrt{x^2 + y^2 + z^2}$).
   - Fitur kalibrasi sensor terhadap permukaan meja.

3. **Wireless Computing (Real-time Broadcast & Synchronization)**:
   - Sinyal status fokus/terdistraksi dikomunikasikan secara nirkabel antar perangkat dalam satu room.
   - Pop-up alert dan indikator visual seketika saat ada anggota yang mengangkat HP.

4. **Testing Sandbox & Simulator**:
   - Menu sandbox diagnostik untuk menguji kepekaan sensor perangkat.
   - Tombol simulasi hardware khusus saat pengujian dilakukan di Android Studio Emulator / PC.

---

## 📖 Panduan Anggota Kelompok

Untuk panduan lengkap langkah-demi-langkah membuka dan menjalankan aplikasi ini menggunakan **Android Studio**, silakan baca:
👉 **[PANDUAN_SETUP_ANDROID_STUDIO.md](PANDUAN_SETUP_ANDROID_STUDIO.md)**

---

## 🛠️ Tech Stack & Dependencies
- **Target Platform**: Khusus Android (OS Android 8.0+ / API 26+)
- **Framework**: Flutter 3.x / Dart 3.x
- **IDE**: Android Studio
- **Sensor**: `sensors_plus` (Hardware Accelerometer Telemetry)
- **Sharing**: `share_plus` (Broadcast Room Link / Code)
- **Design System**: Material 3 Modern Slate Dark UI with Live Sync Telemetry
*(Catatan: Direktori platform non-Android seperti iOS, Windows, macOS, Linux, dan Web telah dibersihkan agar project ramping, ringan, dan fokus pada target Android).*

