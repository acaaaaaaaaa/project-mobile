# 📱 Panduan Lengkap Setup & Instalasi dari Nol (Untuk Pemula)
### Project: **FocusRoom - Study Group Anti-Distraction**
**Mata Kuliah:** Mobile and Wireless Computing  
**Repository GitHub:** [https://github.com/acaaaaaaaaa/project-mobile](https://github.com/acaaaaaaaaa/project-mobile)

---

Panduan ini dibuat khusus untuk seluruh anggota tim, terutama yang **baru pertama kali menggunakan Flutter dan Android Studio**. Ikuti langkah-langkah di bawah ini secara berurutan dari nomor 1.

---

## 📑 Daftar Isi

1. [Konsep Aplikasi & Relevansi Matakuliah](#1-konsep-aplikasi--relevansi-matakuliah)
2. [Checklist Software yang Dibutuhkan](#2-checklist-software-yang-dibutuhkan)
3. [Langkah 1: Install Git for Windows](#langkah-1-install-git-for-windows)
4. [Langkah 2: Download & Setup Flutter SDK (Windows PATH)](#langkah-2-download--setup-flutter-sdk-windows-path)
5. [Langkah 3: Install & Setup Android Studio](#langkah-3-install--setup-android-studio)
6. [Langkah 4: Verifikasi & Terima Lisensi Android (`flutter doctor`)](#langkah-4-verifikasi--terima-lisensi-android-flutter-doctor)
7. [Langkah 5: Mengambil Project dari GitHub (Clone)](#langkah-5-mengambil-project-dari-github-clone)
8. [Langkah 6: Membuka Project & Install Library (`pub get`)](#langkah-6-membuka-project--install-library-pub-get)
9. [Langkah 7: Menyiapkan Perangkat (HP Fisik / Emulator)](#langkah-7-menyiapkan-perangkat-hp-fisik--emulator)
10. [Langkah 8: Menjalankan Aplikasi (Run / Debug)](#langkah-8-menjalankan-aplikasi-run--debug)
11. [Cara Menguji & Mendemonstrasikan Fitur Aplikasi](#cara-menguji--mendemonstrasikan-fitur-aplikasi)
12. [Solusi Masalah Umum (Troubleshooting FAQ)](#solusi-masalah-umum-troubleshooting-faq)

---

## 1. Konsep Aplikasi & Relevansi Matakuliah

Aplikasi **FocusRoom** dirancang untuk mengatasi distraksi ponsel pintar saat belajar kelompok (baik belajar bersama secara tatap muka maupun daring):

* **Komponen Mobile Computing (Sensor Processing)**:  
  Memanfaatkan sensor internal smartphone (**Accelerometer 3-Axis: X, Y, Z**). Ketika sesi belajar dimulai, peserta meletakkan HP di atas meja. Algoritma menghitung perubahan resultan akselerasi (*delta magnitude* $M = \sqrt{X^2 + Y^2 + Z^2}$). Jika HP diangkat atau disentuh secara signifikan, sensor seketika mendeteksi pergerakan tersebut.
* **Komponen Wireless Computing (Wireless Broadcast & State Sync)**:  
  Setiap peserta terhubung dalam satu **Ruang Belajar (Room)** menggunakan kode room unik (misal: `ROOM-7492`). Ketika ada anggota yang mengangkat gawainya, sistem secara nirkabel menyiarkan status pelanggaran/distraksi ke seluruh perangkat anggota lain di room tersebut secara *real-time*.

---

## 2. Checklist Software yang Dibutuhkan

Sebelum memulai, pastikan laptop Anda memiliki ruang penyimpanan kosong minimal **10 - 15 GB** dan koneksi internet yang stabil:

| No | Software | Fungsi | Link Download Resmi |
|---|---|---|---|
| 1 | **Git for Windows** | Mengunduh kode dari GitHub | [git-scm.com/downloads](https://git-scm.com/downloads) |
| 2 | **Flutter SDK** | Framework aplikasi mobile utama | [docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows) |
| 3 | **Android Studio** | IDE, Android SDK, & Emulator | [developer.android.com/studio](https://developer.android.com/studio) |

---

## Langkah 1: Install Git for Windows

Git diperlukan untuk meng-clone repositori dan mengelola dependensi:
1. Buka [https://git-scm.com/downloads](https://git-scm.com/downloads) dan unduh installer versi **Windows (64-bit)**.
2. Jalankan file installer yang diunduh.
3. Klik **Next** terus menerus (gunakan opsi default).
4. Klik **Install** dan tunggu hingga selesai.
5. Buka **Command Prompt (CMD)** di Windows, lalu ketik perintah berikut untuk memastikan Git terpasang:
   ```bash
   git --version
   ```
   *(Akan muncul teks versi seperti `git version 2.x.x`)*.

---

## Langkah 2: Download & Setup Flutter SDK (Windows PATH)

> ⚠️ **PERINGATAN PENTING**: Jangan pernah mengekstrak folder Flutter ke dalam `C:\Program Files\` karena folder tersebut membutuhkan izin Administrator dan memiliki spasi pada namanya, yang dapat menyebabkan error.

1. **Download Flutter SDK**:
   - Kunjungi [Dokumentasi Resmi Flutter Windows](https://docs.flutter.dev/get-started/install/windows/mobile).
   - Unduh file zip Flutter SDK stabil terbaru (misalnya `flutter_windows_x.x.x-stable.zip`).

2. **Ekstrak Folder**:
   - Buat folder baru di drive C Anda, misalnya: `C:\src\`
   - Ekstrak file zip tadi ke folder tersebut sehingga lokasinya menjadi:
     ```
     C:\src\flutter
     ```

3. **Menambahkan Flutter ke System PATH (Wajib agar perintah flutter dikenali)**:
   - Tekan tombol **Windows** di keyboard, ketik: **env** atau **Environment Variables**.
   - Klik **Edit the system environment variables** (Edit variabel lingkungan sistem).
   - Pada jendela yang muncul, klik tombol **Environment Variables...** di pojok kanan bawah.
   - Di bagian **User variables for [NamaUser]** (atau System variables), cari variabel bernama **`Path`**, lalu klik **Edit...**.
   - Klik tombol **New** di sebelah kanan.
   - Ketikkan alamat folder `bin` dari Flutter:
     ```
     C:\src\flutter\bin
     ```
   - Klik **OK**, lalu **OK**, dan **OK** sekali lagi untuk menutup jendela pengaturan.

4. **Verifikasi**:
   - Buka **Command Prompt (CMD)** baru (tutup CMD lama jika sebelumnya terbuka).
   - Ketik:
     ```bash
     flutter --version
     ```
   - Jika muncul versi Flutter dan Dart, artinya pengaturan PATH Anda telah berhasil!

---

## Langkah 3: Install & Setup Android Studio

Android Studio menyediakan Android SDK, Gradle, emulator, dan editor untuk menjalankan aplikasi Android:

1. **Instalasi Android Studio**:
   - Unduh dari [developer.android.com/studio](https://developer.android.com/studio).
   - Jalankan installer, ikuti wizard setup, pastikan **Android Virtual Device** dicentang saat instalasi komponen.
   - Selesaikan instalasi dan buka Android Studio.

2. **Install Android SDK Command-line Tools (Komponen Sangat Penting)**:
   - Pada layar awal Android Studio (*Welcome to Android Studio*), klik **More Actions** (ikon titik tiga) -> pilih **SDK Manager**.  
     *(Jika sudah di dalam project: Menu `Tools` -> `SDK Manager`)*.
   - Pilih tab **SDK Tools** di bagian atas.
   - Cari dan centang:
     - ☑️ **Android SDK Command-line Tools (latest)**
     - ☑️ **Android SDK Build-Tools**
     - ☑️ **Android SDK Platform-Tools**
   - Klik tombol **Apply** di kanan bawah, klik **OK** untuk mulai mengunduh, lalu klik **Finish** jika selesai.

3. **Install Plugin Flutter & Dart**:
   - Di Android Studio, klik menu **Plugins** di sebelah kiri.
   - Pilih tab **Marketplace**, pada kolom pencarian ketik: `Flutter`.
   - Klik tombol **Install** pada plugin Flutter.
   - Akan muncul pesan konfirmasi bahwa plugin ini membutuhkan plugin Dart, klik **Install** / **Accept**.
   - Setelah proses instalasi selesai, klik tombol **Restart IDE**.

---

## Langkah 4: Verifikasi & Terima Lisensi Android (`flutter doctor`)

Langkah ini penting untuk memastikan seluruh komponen Flutter dan Android SDK saling terhubung dan lisensi resmi Google telah disetujui:

1. Buka **Command Prompt** atau **PowerShell**.
2. Jalankan perintah diagnostik:
   ```bash
   flutter doctor
   ```
3. Jika pada bagian **Android toolchain** terdapat pesan lisensi belum disetujui (*Android license status unknown*), jalankan:
   ```bash
   flutter doctor --android-licenses
   ```
4. Terminal akan menampilkan serangkaian persetujuan lisensi. Ketik huruf **`y`** lalu tekan **Enter** untuk setiap pertanyaan yang muncul sampai selesai.
5. Jalankan kembali `flutter doctor` dan pastikan bagian berikut bertanda centang hijau `[√]`:
   - `[√] Flutter`
   - `[√] Android toolchain - develop for Android devices`
   - `[√] Android Studio`

*(Tanda seru pada Visual Studio Windows Desktop atau Xcode bisa diabaikan karena kita menargetkan platform Android).*

---

## Langkah 5: Mengambil Project dari GitHub (Clone)

Tautan repositori resmi:
```
https://github.com/acaaaaaaaaa/project-mobile.git
```

### Opsi 1: Lewat Android Studio Langsung (Termudah)
1. Buka Android Studio.
2. Di layar awal, klik tombol **Get from VCS** (atau di menu atas: `File` -> `New` -> `Project from Version Control...`).
3. Di kolom **URL**, paste link:
   ```
   https://github.com/acaaaaaaaaa/project-mobile.git
   ```
4. Pada kolom **Directory**, pilih lokasi folder di komputer Anda (misal: `D:\Kuliah\project-mobile` atau `C:\Projects\project-mobile`).
5. Klik **Clone**.

### Opsi 2: Menggunakan Terminal / Git Bash
Buka Terminal / Command Prompt di folder tempat Anda ingin menyimpan project:
```bash
git clone https://github.com/acaaaaaaaaa/project-mobile.git
cd project-mobile
```

---

## Langkah 6: Membuka Project & Install Library (`pub get`)

1. Di Android Studio, pilih **File** -> **Open...**
2. Cari dan pilih folder **`project-mobile`**, lalu klik **OK**.
3. Jika muncul dialog keamanan *"Trust Project?"*, klik **Trust Project**.
4. Tunggu beberapa saat sampai Android Studio selesai memindai dan membuat index file di pojok kanan bawah.
5. **Install Dependencies / Package**:
   - Di panel sebelah kiri (*Project Files*), cari dan klik file **`pubspec.yaml`**.
   - Di bagian atas editor file tersebut akan muncul bar biru dengan tombol **Flutter pub get**. Klik tombol tersebut.
   - *Alternatif:* Buka tab **Terminal** di bagian bawah Android Studio dan ketik:
     ```bash
     flutter pub get
     ```
   - Tunggu sampai muncul tulisan `exit code 0` atau `Got dependencies!`.

---

## Langkah 7: Menyiapkan Perangkat (HP Fisik / Emulator)

Aplikasi ini membutuhkan sensor gerak, sehingga sangat direkomendasikan menggunakan **HP Android Fisik**. Namun, jika tidak memungkinkan, Anda tetap bisa menggunakan **Emulator**.

### Opsi A: Menggunakan HP Android Fisik (Sangat Direkomendasikan)
1. **Aktifkan Opsi Pengembang (Developer Options)**:
   - Buka **Pengaturan (Settings)** di HP Android Anda.
   - Masuk ke menu **Tentang Ponsel (About Phone)**.
   - Cari baris **Nomor Bentukan (Build Number)**.  
     *(Pada HP Xiaomi: Versi OS/MIUI; pada HP Realme/Oppo: Versi pita basis & kernel)*.
   - Ketuk pada tulisan tersebut sebanyak **7 kali secara beruntun** sampai muncul tulisan pop-up: *"Sekarang Anda adalah seorang pengembang!"*.
2. **Aktifkan USB Debugging**:
   - Buka kembali Pengaturan, cari menu **Opsi Pengembang (Developer Options)** (biasanya ada di dalam menu *Sistem* atau *Pengaturan Tambahan*).
   - Aktifkan toggle **Debugging USB (USB Debugging)**.
3. **Sambungkan HP ke Laptop**:
   - Gunakan kabel data USB yang bagus.
   - Pada bar notifikasi HP, pastikan mode koneksi dipilih **Transfer File (MTP)**, bukan hanya *Mengisi Daya*.
   - Di layar HP akan muncul pop-up peringatan: *"Izinkan debugging USB dari komputer ini?"*.
   - Centang kotak **"Selalu izinkan dari komputer ini"**, lalu tekan **Izinkan (Allow / OK)**.

---

### Opsi B: Menggunakan Emulator Android Studio
1. Di toolbar kanan atas Android Studio, klik ikon **Device Manager** (atau buka menu `Tools` -> `Device Manager`).
2. Klik tombol **+ Create Device** (atau *Create Virtual Device*).
3. Pilih kategori **Phone**, pilih tipe perangkat (contoh: **Pixel 7** atau **Pixel 8**), lalu klik **Next**.
4. Di bagian sistem operasi (*System Image*), pilih versi Android yang ingin diunduh (disarankan **UpsideDownCake (API 34)** atau **Tiramisu (API 33)**). Klik ikon download jika belum terunduh, lalu klik **Next**.
5. Beri nama emulator, lalu klik **Finish**.
6. Klik tombol **Play (▶️)** pada daftar Device Manager untuk menyalakan emulator di layar laptop.

---

## Langkah 8: Menjalankan Aplikasi (Run / Debug)

1. Perhatikan toolbar bagian atas Android Studio. Di sebelah tombol palu hijau, terdapat menu dropdown perangkat.
2. Klik dropdown tersebut dan pilih perangkat Anda:
   - Nama HP fisik Anda (contoh: `Samsung SM-G991B`, `Xiaomi 2201117TY`), **ATAU**
   - Nama Emulator Android Anda.
3. Pastikan file target utama adalah `lib/main.dart`.
4. Klik tombol **Run** (ikon segitiga hijau ▶️) atau tekan shortcut **Shift + F10**.
5. *Catatan untuk Run pertama kali:*  
   Android Studio akan mengunduh Gradle wrapper dan dependensi Android. Proses ini membutuhkan waktu sekitar **3 - 8 menit** tergantung kecepatan internet laptop Anda. Mohon ditunggu hingga proses kompilasi selesai.
6. Aplikasi FocusRoom akan otomatis terpasang dan terbuka di layar HP / Emulator Anda! 🎉

---

## Cara Menguji & Mendemonstrasikan Fitur Aplikasi

Aplikasi telah dilengkapi dengan antarmuka modern Material 3 Dark Mode dan dua modul utama:

### 1. Uji Sensor Akselerometer (Mode Sandbox)
* Di halaman utama, klik menu **"Uji Sensor HP (Sandbox)"**.
* Letakkan HP di atas meja datar:
  * Status akan berwarna **Hijau (Tenang di Meja)**.
  * Anda dapat melihat grafik angka telemetri sumbu X, Y, Z secara live.
* Angkat HP Anda:
  * Sensor mendeteksi perubahan gaya gravitasi dan akselerasi (*delta magnitude* melampaui batas ambang threshold).
  * Status seketika berubah menjadi **Merah (HP Terangkat / Terdistraksi)** dan bergetar!

### 2. Sesi Belajar Kelompok (Room & Wireless Sync)
* **Membuat Room (Leader)**:
  1. Klik **"Buat Ruang Belajar Baru"**.
  2. Tentukan nama Anda dan durasi timer belajar (misal 25 menit / teknik Pomodoro).
  3. Klik Buat Room. Kode unik room (misal `ROOM-5821`) akan tampil.
  4. Klik tombol **Share (Ikon Bagikan)** di pojok kanan atas untuk membagikan kode dan pesan room ke teman kelompok via WhatsApp.
* **Bergabung ke Room (Anggota)**:
  1. Anggota lain memilih menu **"Gabung ke Ruang Belajar"** di halaman awal.
  2. Masukkan kode room yang dibagikan oleh Leader dan ketik nama anggota.
* **Mekanisme Anti-Distraksi**:
  * Semua peserta meletakkan HP di atas meja dan menekan tombol mulai sesi.
  * Apabila ada salah satu peserta yang tergoda mengangkat gawainya di tengah sesi belajar, layar aplikasi akan memicu peringatan peringatan visual berkedip dan memberitahu teman lainnya di ruangan tersebut.
* **Fitur Tambahan untuk Pengguna Emulator**:  
  Jika menguji di laptop tanpa HP fisik, kami menyediakan tombol khusus **"Simulasi: Angkat HP Sekarang"** di dalam aplikasi sehingga Anda tetap bisa memicu deteksi sensor dan mendemonstrasikan fiturnya dengan sempurna saat presentasi!

---

## Solusi Masalah Umum (Troubleshooting FAQ)

#### Q1: Muncul pesan error `'flutter' is not recognized as an internal or external command` di CMD
* **Penyebab**: Folder `flutter\bin` belum dimasukkan ke variabel Environment PATH Windows, atau CMD belum direstart setelah mengubah PATH.
* **Solusi**: Ikuti kembali petunjuk di [Langkah 2](#langkah-2-download--setup-flutter-sdk-windows-path). Pastikan tutup seluruh jendela CMD dan buka yang baru.

#### Q2: Error `Android SDK command line tool component is missing` saat menjalankan `flutter doctor`
* **Penyebab**: Komponen Command-line tools belum terpasang di Android Studio.
* **Solusi**: Buka Android Studio -> `Tools` -> `SDK Manager` -> tab `SDK Tools` -> centang **Android SDK Command-line Tools (latest)** -> klik **Apply**.

#### Q3: Error `Android license status unknown`
* **Solusi**: Jalankan perintah berikut di terminal:
  ```bash
  flutter doctor --android-licenses
  ```
  Ketik `y` dan Enter untuk setiap lisensi yang diminta sampai selesai.

#### Q4: HP Android tidak muncul di daftar perangkat Android Studio
* Pastikan kabel USB berfungsi untuk transfer data (bukan sekadar kabel charger isi daya).
* Pastikan mode koneksi USB di bar notifikasi HP diatur ke **File Transfer (MTP)**.
* Pastikan izin USB Debugging sudah disetujui di layar HP Anda.
* Coba cabut dan colokkan kembali kabel USB ke port laptop lainnya.

#### Q5: Proses build Gradle pertama kali macet atau sangat lama
* Pada build perdana, Gradle harus mengunduh file pendukung (sekitar 150-300MB) dari server Google/Maven. Pastikan koneksi internet aktif dan stabil. Jangan tutup Android Studio sebelum prosesnya selesai.

---
*Dokumentasi ini disusun untuk kelancaran pengerjaan tugas besar kelompok Mata Kuliah Mobile and Wireless Computing.*  
Jika ada kendala yang belum teratasi, silakan tanyakan di grup kelompok atau diskusikan bersama! 🚀
