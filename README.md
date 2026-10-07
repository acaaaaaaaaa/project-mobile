# 📱 StudyPact - Focus & Study Group Anti-Distraction App
> **Project Mata Kuliah: Mobile and Wireless Computing**  
> Repository GitHub: [https://github.com/acaaaaaaaaa/project-mobile](https://github.com/acaaaaaaaaa/project-mobile)

**StudyPact** adalah aplikasi cerdas berbasis mobile & wireless computing untuk mengatasi distraksi smartphone saat belajar kelompok (baik tatap muka maupun daring) dengan mendeteksi stabilitas sensor kemiringan/gerak smartphone secara real-time dan menyinkronkan komitmen fokus tim.

---

## 🎨 Implementasi Desain & Antarmuka Layar (Sesuai Mockup UI)

Aplikasi telah mengimplementasikan seluruh desain visual modern dengan presisi tinggi:

1. **Beranda (Home Screen)**:
   - Header StudyPact dengan streak harian (**🔥 7 HARI**) dan profil pengguna.
   - Sapaan dinamis (*"Halo, Farhan! 👋"*) dan status badge *● SIAP SESI*.
   - **Level & XP Progress Card** (Tier 14 Focus Master, progress bar 840/1000 XP, dan visual mingguan 7 hari beruntun).
   - **Kartu Undangan Mabar Study** (Timer hitung mundur, info host, kuota anggota, tombol *Tolak* & *Terima & Masuk Lobi*).
   - **Quick Action Grid**: Tombol *Buat Ruang* (Mulai Instan) & *Gabung Kode* (Input PIN).
   - **Kalender Fokus April 2025**: Total jam fokus 32.4 jam, kepatuhan sensor 98.2%, indikator warna intensitas harian (>60 mnt, 25–45 mnt, Istirahat).
   - **Teman Belajar Aktif**: Daftar rekan online (Rizky Ramadhan, Nabila Putri, Dimas Arya) dengan aksi cepat *Ajak*.

2. **Ruang Sesi / Lobi (Session Room & Pre-Session Sensor Check)**:
   - Status badge lobi aktif & host badge (*Host: Farhan (Anda)*).
   - Detail ruang: Judul sesi (*Kerkom Algoritma Lanjut*), kode ruang unik (*PACT-7492*) dengan tombol salin cepat, dan durasi.
   - **Anggota Terkoneksi (4/5 Kursi)**: Status real-time tiap anggota (Farhan 100%, Rizky DND, Nabila Toleran, Dimas Kalibrasi, Slot Kosong Undang).
   - **Pemeriksaan Sensor Ponsel (3/3 Lolos)**:
     - Toggle interaktif *Mode Perjalanan (Travel Mode 🚆/🚗)*.
     - Status sensor *Mode DND/Senyap (✓ Aktif)*.
     - Status *Peletakan HP di Bidang Datar (✓ Terdeteksi)*.
     - Pembacaan telemetri real-time: `X: 0.2° | Y: 0.1° (Stabil)` yang terhubung langsung ke sensor smartphone.
   - Tombol utama: **⚡ Mulai Kalibrasi 3 Detik Bersama** (dengan dialog hitungan mundur interaktif) & **Undang Teman Lain**.
   - Tombol shortcut demonstrasi untuk membuka layar insiden, layar late-joiner, riwayat sesi, dan sesi aktif langsung di Android Studio.

3. **Layar Sesi Fokus Aktif (Live Focus & Sensor Telemetry)**:
   - Header atas: Bar status gelap `🔒 SENSOR TERKUNCI: GYRO & ACCELE... ● LIVE`.
   - **Kartu Timer Midnight Indigo**:
     - Badge sensitivitas: `Sensitivitas: Stabil • 0 getaran terdeteksi`.
     - **Circular Dial Countdown Timer**: Menampilkan sisa waktu hitung mundur (misal: `34:12` dari 45:00 menit) dengan progress ring neon mint dan badge reward `+15 XP / 10m`.
     - **3 Kotak Telemetri Sensor**: `PITCH (+0.02°)`, `ROLL (+0.02°)`, dan `VIBRATION (0.00 G)`.
   - **Kartu Akumulasi XP**: `+34 XP Terkumpul` (+15 Teamwork Bonus menanti di menit 45) dengan badge `SYNC 100%`.
   - **Kelompok Belajar Aktif (4)**: Status kedisiplinan fisik 4 anggota (*Farhan - ● Aman*, *Rizky R. - ✓ 34m Tetap*, *Nabila P. - 🚆 Mobil*, *Budi Santoso - 🔄 Menunggu*).
   - **Prosedur Keluar Sesi (Bebas Penalti)**: Slider interaktif *Geser untuk Izin Keluar Normal* agar anggota dapat keluar dengan aman tanpa mengganggu rekan tim.

4. **Layar Insiden Pelanggaran (Sensor Trigger & Violation Screen)**:
   - Header darurat merah: *SESI TERGANGGU! PELANGGARAN TERDETEKSI* (Sensor Trigger: ACCEL-Z Fault).
   - Kartu Sumber Pelanggaran: Rincian pelanggar (*Dimas Arya - Culprit*), aksi pelanggaran (HP terangkat kemiringan +48° & akselerasi 1.4G), perbandingan toleransi >15° Max, dan status alarm audio serentak.
   - Kartu Dampak & Kalkulasi XP: Penalti -10 XP untuk pelanggar dan kompensasi aman +28 XP untuk anggota lain.
   - Status rekan lain di sesi (Sarah K., Rayhan, Anda).
   - Tombol aksi pemulihan: *Mulai Ulang Sesi Bersama (Reset Room)*, *Lanjutkan Tanpa Pelanggar (Kick Dimas & Resume)*, dan *Akhiri & Simpan Log Sesi*.

4. **Riwayat & Log (Session Success & Summary Report)**:
   - Badge medali hijau: *SESI SUKSES PENUH* (*Tugas Akhir HCI - Kelompok 4*), durasi 45 menit, stabilitas meja 100% valid.
   - Kartu Perolehan Pengalaman: **+60 TOTAL XP** (Fokus Dasar +45 XP, Teamwork Bonus +15 XP, Penalti 0 XP) dan perpanjangan streak 8 hari beruntun.
   - **Papan Peringkat Sesi**: Peringkat kedisiplinan 4 peserta (Farhan #1, Rizky #2, Nabila #3, Budi #4).
   - **Buku Tamu Sistem (Audit Trail)**: Timeline log kronologis dari inisiasi host (14:00:00) hingga selesai final (14:45:00).
   - Tombol aksi: *Kembali ke Beranda* & *Bagikan Hasil Sesi ke WhatsApp/Grup*.

5. **Layar Bergabung Terlambat (Late Joiner & Calibration Flow)**:
   - Status sesi aktif sedang berjalan (*Kerkom Algoritma Lanjut*).
   - Indikator kemajuan sesi (12:40 / 45:00 menit) dengan avatar anggota aktif terkunci.
   - Kartu notifikasi late-joiner dengan target sisa waktu 32 menit dan potensi XP +32 XP.
   - Switch travel mode dan ilustrasi peletakan HP di permukaan meja datar.
   - Lingkaran hitung mundur 3 detik kalibrasi mandiri sebelum tersinkronisasi ke ruang aktif.

6. **Layar Profil**:
   - Kartu ringkasan Farhan (Tier 14 Focus Master, 7 Hari Streak, 32.4 Jam, 98.2% Kepatuhan).
   - Pengaturan sensitivitas sensor gerak, alarm audio rekan meja, dan preferensi grup belajar.

---

## 💻 Cara Membuka & Menjalankan di Android Studio

1. **Buka Android Studio**:
   - Klik **File** > **Open...**
   - Pilih folder: `C:\Mobile-Project`
2. **Sync Dependensi**:
   - Android Studio akan otomatis mendeteksi project Flutter. Jika diminta, klik **`pub get`** atau jalankan `flutter pub get` di terminal bawaan.
3. **Pilih Perangkat (Device)**:
   - Di toolbar atas, pilih Emulator Android (Pixel / Nexus) atau sambungkan HP Android fisik via USB Debugging.
4. **Jalankan Aplikasi**:
   - Tekan tombol hijau **Run ▶** (atau shortcut `Shift + F10`).
   - Aplikasi akan otomatis ter-compile dan berjalan di emulator/HP Anda.

Untuk panduan instalasi lengkap dari nol bagi pemula, lihat:  
👉 **[PANDUAN_SETUP_ANDROID_STUDIO.md](PANDUAN_SETUP_ANDROID_STUDIO.md)**
