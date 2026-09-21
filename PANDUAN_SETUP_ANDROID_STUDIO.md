# 📱 PANDUAN LENGKAP SETUP & MENJALANKAN PROJECT DI ANDROID STUDIO
**Mata Kuliah:** Mobile and Wireless Computing  
**Nama Project:** FocusRoom - Study Group Anti-Distraction  
**Repository GitHub:** [https://github.com/acaaaaaaaaa/project-mobile](https://github.com/acaaaaaaaaa/project-mobile)

---

## 📋 Daftar Isi
1. [Tentang Aplikasi & Konsep Matakuliah](#1-tentang-aplikasi--konsep-matakuliah)
2. [Kebutuhan Software (Prerequisites)](#2-kebutuhan-software-prerequisites)
3. [Langkah 1: Setup Flutter & Android Studio Pertama Kali](#langkah-1-setup-flutter--android-studio-pertama-kali)
4. [Langkah 2: Mengambil Project dari GitHub (Clone)](#langkah-2-mengambil-project-dari-github-clone)
5. [Langkah 3: Membuka Project di Android Studio](#langkah-3-membuka-project-di-android-studio)
6. [Langkah 4: Install Dependencies (`pub get`)](#langkah-4-install-dependencies-pub-get)
7. [Langkah 5: Menjalankan Aplikasi (Pilih Emulator atau HP Fisik)](#langkah-5-menjalankan-aplikasi)
   - [Opsi A: Menggunakan HP Fisik (Sangat Direkomendasikan)](#opsi-a-menggunakan-hp-android-fisik-sangat-direkomendasikan)
   - [Opsi B: Menggunakan Android Virtual Device (Emulator)](#opsi-b-menggunakan-emulator-android-studio)
8. [Cara Menguji Fitur Deteksi Angkat HP](#cara-menguji-fitur-deteksi-angkat-hp)
9. [Solusi Masalah Umum (Troubleshooting FAQ)](#solusi-masalah-umum-troubleshooting-faq)

---

## 1. Tentang Aplikasi & Konsep Matakuliah

Aplikasi **FocusRoom** dirancang untuk memecahkan masalah distraksi gadget saat belajar kelompok (baik belajar bersama di satu ruangan maupun secara online/jarak jauh):

* **Mobile Computing (Sensor Processing)**:  
  Aplikasi memanfaatkan sensor gerak internal smartphone (**Accelerometer Tri-Axis: X, Y, Z**). Saat sesi belajar dimulai, peserta meletakkan HP di atas meja. Algoritma akan mendeteksi perubahan akselerasi (delta magnitude $M = \sqrt{X^2 + Y^2 + Z^2}$). Ketika HP diangkat oleh anggota, sistem mendeteksi lonjakan gaya gerak tersebut.
* **Wireless Computing (Wireless Room Synchronization & Broadcast)**:  
  Setiap peserta terhubung dalam satu **Ruang Belajar (Room)** menggunakan kode room unik. Ketika salah satu anggota mengangkat HP-nya, aplikasi secara otomatis menyiarkan sinyal peringatan nirkabel ke seluruh anggota di room tersebut secara *real-time*.

---

## 2. Kebutuhan Software (Prerequisites)

Pastikan di laptop Anda sudah terinstall:
1. **Git**: [https://git-scm.com/downloads](https://git-scm.com/downloads)
2. **Android Studio**: [https://developer.android.com/studio](https://developer.android.com/studio) (Versi Ladybug, Jellyfish, atau terbaru)
3. **Flutter SDK**: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) (versi 3.20.0 atau lebih baru)

> **Catatan:** Jika belum yakin apakah Flutter sudah terpasang, buka Command Prompt / Terminal dan ketik:
> ```bash
> flutter doctor
> ```
> Pastikan ada tanda centang hijau `[√] Flutter` dan `[√] Android toolchain`.

---

## Langkah 1: Setup Flutter & Android Studio Pertama Kali

Jika Anda baru pertama kali mengintegrasikan Flutter dengan Android Studio:
1. Buka aplikasi **Android Studio**.
2. Di halaman selamat datang (*Welcome Screen*), klik menu **Plugins** di sebelah kiri.
3. Di tab **Marketplace**, cari plugin bernama **Flutter**.
4. Klik tombol **Install** (Android Studio otomatis meminta konfirmasi untuk menginstall plugin **Dart** juga, klik **Accept** / **Install**).
5. Setelah instalasi selesai, klik **Restart IDE**.

---

## Langkah 2: Mengambil Project dari GitHub (Clone)

Ada 2 cara mudah untuk mengambil project:

### Cara A: Melalui Android Studio (Paling Mudah)
1. Buka Android Studio.
2. Di layar awal, klik tombol **Get from VCS** (atau dari menu atas: `File` -> `New` -> `Project from Version Control...`).
3. Pada kolom **URL**, masukkan tautan repositori:
   ```
   https://github.com/acaaaaaaaaa/project-mobile.git
   ```
4. Tentukan folder penyimpanan di laptop Anda (misal: `D:\Kuliah\project-mobile`).
5. Klik **Clone**.

### Cara B: Melalui Terminal / Git Bash
Buka terminal dan jalankan:
```bash
git clone https://github.com/acaaaaaaaaa/project-mobile.git
cd project-mobile
```

---

## Langkah 3: Membuka Project di Android Studio

1. Di Android Studio, pilih menu **File** -> **Open...**
2. Arahkan ke folder tempat Anda meng-clone project (`project-mobile`).
3. Klik **OK** / **Trust Project**.
4. Tunggu beberapa saat hingga Android Studio selesai melakukan sinkronisasi dan indexing file di pojok kanan bawah.

---

## Langkah 4: Install Dependencies (`pub get`)

Sebelum menjalankan aplikasi, library eksternal (seperti modul sensor gerak dan share) harus diunduh:
1. Buka file **`pubspec.yaml`** yang ada di daftar file sebelah kiri.
2. Di bagian atas editor file tersebut, klik tombol **Flutter pub get** (atau ikon panah biru download).
3. Atau, Anda bisa membuka tab **Terminal** di bagian bawah Android Studio dan mengetik:
   ```bash
   flutter pub get
   ```
4. Pastikan muncul pesan `exit code 0` / `Got dependencies!`.

---

## Langkah 5: Menjalankan Aplikasi

Anda dapat menjalankan aplikasi menggunakan HP fisik Android (sangat disarankan agar sensor bergerak nyata) atau Emulator.

### Opsi A: Menggunakan HP Android Fisik (Sangat Direkomendasikan)
Menjalankan di HP asli memberikan pengalaman uji coba sensor accelerometer yang paling akurat:

1. **Aktifkan Developer Options di HP Android Anda**:
   - Buka **Pengaturan (Settings)** di HP Anda.
   - Masuk ke **Tentang Ponsel (About Phone)**.
   - Ketuk pada tulisan **Nomor Bentukan (Build Number)** sebanyak **7 kali berturut-turut** sampai muncul notifikasi *"Anda sekarang adalah seorang pengembang!"*.
2. **Aktifkan USB Debugging**:
   - Masuk ke menu **Opsi Pengembang (Developer Options)**.
   - Aktifkan toggle **Debugging USB (USB Debugging)**.
3. **Hubungkan HP ke Laptop**:
   - Sambungkan HP ke laptop menggunakan kabel data USB.
   - Di layar HP akan muncul pop-up izin: *"Izinkan debugging USB?"*, centang *"Selalu izinkan"* dan pilih **Izinkan (Allow)**.
4. **Pilih Perangkat di Android Studio**:
   - Di toolbar bagian atas Android Studio, cari menu dropdown perangkat (biasanya bertuliskan `<no device>` atau `Chrome (web)`).
   - Klik dropdown tersebut, nama tipe HP Anda akan terdeteksi (misal: *Samsung SM-G991B*, *Xiaomi 2201117TY*, dll).
   - Pilih HP Anda.
5. **Jalankan Aplikasi**:
   - Klik tombol **Run** (ikon segitiga hijau ▶️) atau tekan tombol pintas **Shift + F10**.
   - Aplikasi akan otomatis dicompile dan terpasang di HP Anda!

---

### Opsi B: Menggunakan Emulator Android Studio

Jika tidak membawa kabel data atau HP fisik:
1. Di Android Studio, buka menu **Device Manager** (ikon HP di toolbar kanan atas, atau dari menu `Tools` -> `Device Manager`).
2. Klik tombol **Create Virtual Device** (buat baru) atau jalankan perangkat yang sudah ada dengan menekan tombol **Play** ▶️.
3. Setelah emulator menyala di layar komputer, pilih nama emulator tersebut di dropdown perangkat atas Android Studio.
4. Klik tombol **Run** (segitiga hijau ▶️).
5. **Tips Khusus Emulator**: Karena emulator laptop tidak bergerak secara fisik, kami telah menyediakan tombol **"Simulasi: Angkat HP Sekarang"** di dalam aplikasi untuk mendemonstrasikan pergerakan sensor secara instan!

---

## Cara Menguji Fitur Deteksi Angkat HP

1. **Uji Sensor Mandiri (Sandbox)**:
   - Di halaman utama aplikasi, pilih menu **"Uji Sensor HP (Sandbox)"**.
   - Letakkan HP di atas meja (indikator akan berwarna **Hijau** / Aman).
   - Angkat HP Anda (indikator seketika berubah menjadi **Merah** mendeteksi pergerakan akselerometer).

2. **Uji Coba Sesi Belajar Kelompok (Room Session)**:
   - Klik **"Buat Ruang Belajar Baru"** (atur durasi misal 30 menit).
   - Masuk ke layar ruang belajar. Kode Room akan tampil (misal `ROOM-7492`).
   - Tekan tombol **Share** di pojok kanan atas untuk membagikan kode room ke teman kelompok via WhatsApp.
   - Letakkan HP di meja dan mulai belajar bersama.
   - Begitu ada yang tergoda mengambil HP, layar akan menyalakan peringatan berkedip merah dan notifikasi getar/broadcast!

---

## Solusi Masalah Umum (Troubleshooting FAQ)

#### 1. HP Fisik Tidak Terdeteksi di Android Studio
* Pastikan kabel USB mendukung transfer data (bukan kabel charger saja).
* Pastikan mode koneksi USB di bar notifikasi HP diubah dari *"Hanya Mengisi Daya"* ke *"Transfer File (MTP)"*.
* Pastikan driver OEM USB terpasang di laptop (jika menggunakan Windows).

#### 2. Error *"Android SDK license not accepted"*
Buka terminal dan jalankan:
```bash
flutter doctor --android-licenses
```
Ketik `y` lalu tekan Enter untuk setiap persetujuan lisensi yang diminta.

#### 3. Error Build Gradle / Downloading Gradle Lambat
Saat pertama kali dijalankan, Android Studio akan mengunduh Gradle wrapper dan SDK dependencies. Pastikan laptop terhubung ke koneksi internet yang stabil.

---
*Dibuat untuk mempermudah kolaborasi kelompok pada Mata Kuliah Mobile and Wireless Computing.*
