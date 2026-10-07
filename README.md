# 📱 FocusRoom - Study Group Anti-Distraction App
> **Project Mata Kuliah: Mobile and Wireless Computing**  
> Repository GitHub: [https://github.com/acaaaaaaaaa/project-mobile](https://github.com/acaaaaaaaaa/project-mobile)

FocusRoom adalah aplikasi cerdas untuk meningkatkan fokus saat belajar kelompok (baik tatap muka maupun daring) dengan mendeteksi pergerakan sensor smartphone anggota secara real-time dan memberikan peringatan nirkabel ke ruang belajar bersama ketika seseorang mengangkat gawainya.

---

## 🚀 Fitur Utama

1. **Room Collaboration System**:
   - Leader dapat membuat ruang belajar terkelola, menentukan durasi timer belajar, dan membagikan kode/link room.
   - Anggota kelompok dapat bergabung dengan kode room unik 6 karakter.

2. **Mobile Computing (Sensor Accelerometer Processing)**:
   - Membaca telemetri pergerakan 3-sumbu ($X$, $Y$, $Z$) secara real-time.
   - Deteksi otomatis saat HP dipindahkan atau dimiringkan dengan accelerometer, user accelerometer, dan gyroscope.
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

## Menjalankan dengan backend lokal

Backend lokal tidak memerlukan proyek Firebase cloud. Pastikan Node.js, Java, Flutter, dan Firebase CLI tersedia, lalu jalankan:

```powershell
cd functions
npm install
npm run build
cd ..
firebase emulators:start --project demo-focusroom
```

Biarkan terminal tersebut aktif. Emulator Android memakai alamat `10.0.2.2` secara otomatis. Pada terminal lain:

```powershell
flutter pub get
flutter run
```

Untuk HP fisik di Wi-Fi yang sama, ganti `192.168.1.10` dengan IPv4 komputer:

```powershell
flutter run --dart-define=FIREBASE_EMULATOR_HOST=192.168.1.10
```

Firebase Emulator UI tersedia di `http://localhost:4000`.

## Menghubungkan Firebase cloud

Aktifkan Anonymous Authentication dan buat Firestore di region `asia-southeast1`. Pilih proyek lalu deploy backend:

```powershell
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Jalankan aplikasi dengan nilai dari Firebase Project Settings:

```powershell
flutter run `
  --dart-define=USE_FIREBASE_EMULATORS=false `
  --dart-define=FIREBASE_PROJECT_ID=PROJECT_ID `
  --dart-define=FIREBASE_APP_ID=APP_ID `
  --dart-define=FIREBASE_API_KEY=API_KEY `
  --dart-define=FIREBASE_SENDER_ID=SENDER_ID
```

Saat sesi aktif, letakkan HP di meja selama kalibrasi awal. Kemiringan sekitar 25 derajat atau gerakan yang disertai rotasi selama sekitar 0,65 detik akan membuat satu event. Status disinkronkan melalui Firestore; tombol simulasi tetap tersedia untuk Android Emulator yang tidak mempunyai sensor fisik.

