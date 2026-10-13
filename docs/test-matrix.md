# Kerkom Matrix Pengujian Pemantauan Layar Mati (Phase A6)

Dokumen ini adalah panduan dan lembar kerja pengujian real-device dan emulator untuk memvalidasi pemantauan sensor akselerometer & giroskop saat layar mati (foreground service Android) serta fallback layar menyala (iOS & Android izin ditolak).

---

## 1. Lingkungan & Penjelasan Foreground Service (Android 14+)

- **Foreground Service Type**: `specialUse` (`android.permission.FOREGROUND_SERVICE_SPECIAL_USE`).
- **Play Store Declaration Property**:
  `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` = `Educational group study focus session motion and lift detection while screen is off`.
- **Alasan Pemilihan `specialUse`**:
  Aplikasi fokus belajar kelompok ini memantau sensor akselerometer dan giroskop secara kontinu (50 Hz) saat layar ponsel mati di atas meja untuk mendeteksi apakah ponsel diangkat atau dibuka. Kategori standar seperti `health` (fitness tracking), `location`, atau `mediaPlayback` tidak sesuai dengan domain aplikasi ini. Tipe `specialUse` adalah tipe resmi Android 14 (API 34+) untuk use-case kritis latar belakang yang tidak masuk kategori standar.
- **Izin Tambahan**:
  - `POST_NOTIFICATIONS` (Android 13+ / API 33+) untuk notifikasi sticky sesi.
  - `WAKE_LOCK` (Partial Wake Lock) ditahan hanya selama sesi fokus aktif agar CPU tetap membaca sampling sensor saat layar mati.
  - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` untuk mencegah sistem OEM mematikan service.

---

## 2. Prosedur Pengujian Standar

### Uji Coba Emulator (Virtual Sensors):
1. Jalankan Kerkom di Android Emulator (API 34+).
2. Buat ruang atau bergabung ke ruang fokus.
3. Masuk ke **S08 Kalibrasi** -> letakkan virtual device flat -> kalibrasi selesai.
4. Masuk ke **S09 Sesi Aktif**.
5. Kunci layar emulator (`Power` button di sidebar atau `Ctrl + F12`).
6. Buka **Extended Controls > Virtual sensors**.
7. Putar pose perangkat perlahan (misal miringkan Roll / Pitch > 15°).
8. **Verifikasi**: HP anggota lain membunyikan alarm dalam waktu 1–2 detik, dan notifikasi ponsel menampilkan status terangkat.
9. Buka kunci layar -> aplikasi melanjutkan sesi.

### Uji Coba App Switch (Layar Menyala):
1. Masuk ke **S09 Sesi Aktif** dengan layar menyala.
2. Tekan tombol `Home` atau alihkan ke aplikasi lain.
3. **Verifikasi**: Pelanggaran langsung tercatat (`Terangkat`) karena layar menyala saat aplikasi ditinggalkan.

---

## 3. Matriks Pengujian Antar Merk Ponsel (OEM Test Matrix)

Silakan isi kolom **Hasil (Pass / Fail)** dan **Catatan** saat pengujian di perangkat fisik:

| No | Kasus Uji | Skenario Pengujian | Kriteria Lolos (Expected Result) | Google Pixel / Emulator | Samsung (One UI) | Xiaomi (MIUI / HyperOS) | Oppo / Vivo (ColorOS / Funtouch) | iOS (iPhone) |
|---|---|---|---|---|---|---|---|---|
| **TC-01** | **Izin S19** | Pilih 'Selalu' di sheet S19 | Dialog sistem optimasi baterai muncul & pilihan tersimpan di RTDB | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | N/A (Screen on) |
| **TC-02** | **Screen-Off Motion Detection** | Layar dimatikan (kunci tombol Power), lalu ponsel diangkat/dimiringkan > 15° | Alarm anggota lain berbunyi dalam 1–2 detik, liftCount bertambah | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | N/A |
| **TC-03** | **Screen-Off Stationary** | Layar mati selama 5–10 menit tanpa digerakkan | Sesi tetap 'Aman', service tidak dimatikan oleh sistem (Doze mode) | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | N/A |
| **TC-04** | **Sticky Notification Countdown** | Layar mati dinyalakan sekilas tanpa unlock (Lockscreen) | Notifikasi menampilkan countdown waktu tersisa dan nama ruang | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | N/A |
| **TC-05** | **App Switch (Screen ON)** | Layar menyala, tekan Home / pindah aplikasi | Pelanggaran tercatat seketika (status Terangkat) | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail |
| **TC-06** | **Unlock & Return** | Buka kunci ponsel setelah layar mati | Sesi kembali ke S09 dengan status dan timer tersinkronisasi | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail |
| **TC-07** | **Locked Peer Alarm** | Ponsel A dalam kondisi terkunci di meja, Ponsel B mengangkat HP | Ponsel A membunyikan alarm peringatan kelompok meski layar terkunci | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail (Foreground) |
| **TC-08** | **Session End / Exit** | Geser slider keluar atau waktu sesi habis | Foreground service dan notifikasi langsung berhenti tuntas | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail | [ ] Pass / Fail |
| **TC-09** | **iOS Wakelock Fallback** | Jalankan sesi di perangkat iOS | Layar tetap menyala tanpa sleep, note iOS muncul di S08 | N/A | N/A | N/A | N/A | [ ] Pass / Fail |

---

## 4. Panduan Khusus OEM (Aggressive Battery Killers)

Beberapa vendor Android memiliki mekanisme manajemen daya agresif yang dapat mematikan isolat background service jika optimasi baterai tidak dinonaktifkan:

### 1. Xiaomi / Redmi / POCO (MIUI & HyperOS)
- **Gejala**: Service mati setelah 1–3 menit layar mati.
- **Solusi**:
  1. Masuk ke **Pengaturan > Aplikasi > Kelola Aplikasi > Kerkom**.
  2. Aktifkan **Mulai Otomatis (Autostart)**.
  3. Di menu **Penghemat Baterai**, ubah dari *Rekomendasi* menjadi **Tidak ada pembatasan (No restrictions)**.
  4. Pada menu recent apps, tahan kartu aplikasi Kerkom dan aktifkan ikon **Gembok (Lock)**.

### 2. Samsung (One UI)
- **Gejala**: Notifikasi tetap ada namun sensor giroskop dihentikan saat memasuki deep sleep.
- **Solusi**:
  1. Masuk ke **Pengaturan > Aplikasi > Kerkom > Baterai**.
  2. Pilih mode **Tidak dibatasi (Unrestricted)**.
  3. Buka **Pengaturan > Perawatan Perangkat > Baterai > Batas Penggunaan Latar Belakang**.
  4. Pastikan Kerkom tidak dimasukkan ke dalam *Aplikasi yang tidur lelap (Deep sleeping apps)*.

### 3. Oppo & Realme (ColorOS / Realme UI)
- **Gejala**: Koneksi socket / stream sensor diputus saat layar mati lebih dari 5 menit.
- **Solusi**:
  1. Buka **Pengaturan > Aplikasi > Manajemen Aplikasi > Kerkom > Penggunaan Baterai**.
  2. Aktifkan **Izinkan aktivitas latar belakang (Allow background activity)**.
  3. Aktifkan **Izinkan mulai otomatis (Allow auto-launch)**.

### 4. Vivo & iQOO (Funtouch OS)
- **Gejala**: Layar mati memutus isolat sensor service.
- **Solusi**:
  1. Buka **Pengaturan > Baterai > Pengelolaan konsumsi daya di latar belakang**.
  2. Cari Kerkom dan pilih **Tingginya konsumsi daya di latar belakang diizinkan**.
