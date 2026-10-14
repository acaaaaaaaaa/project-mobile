# Panduan Resmi Integrasi Akun Google & Google Calendar (KerKom)

Dokumen ini berisi panduan langkah demi langkah untuk mengonfigurasi **Google Sign-In** dan **Google Calendar** agar izin/persetujuan resmi Google OAuth berfungsi tanpa error `PlatformException` (ApiException: 10 / 12500) saat dijalankan di perangkat Android.

---

## 1. Fingerprint Sertifikat SHA-1 & SHA-256 (Keystore)

Aplikasi Android KerKom saat ini menggunakan keystore dengan fingerprint berikut:

- **Nama Paket (Package Name / Application ID)**: `com.mobcom.focusroom.focus_room`
- **SHA-1**:
  ```
  03:36:3B:B9:59:75:FD:62:5D:96:AE:52:2F:05:F4:EF:7E:72:1A:BC
  ```
- **SHA-256**:
  ```
  E5:6C:89:DE:01:9B:4F:07:B5:88:E3:79:EA:D9:F0:1E:25:58:D4:88:9C:92:C1:AE:70:CC:31:66:C2:94:F0:42
  ```

---

## 2. Langkah Konfigurasi di Firebase Console

1. Buka [Firebase Console](https://console.firebase.google.com/) dan pilih project Anda (**kerkom-project**).
2. Klik ikon gerigi (Settings) di sebelah kiri atas -> pilih **Project settings**.
3. Di tab **General**, gulir ke bawah ke bagian **Your apps** -> pilih aplikasi Android (`com.mobcom.focusroom.focus_room`).
4. Pada bagian **SHA certificate fingerprints**, klik **Add fingerprint**:
   - Tempelkan **SHA-1** di atas, lalu klik Simpan.
   - Klik **Add fingerprint** lagi, tempelkan **SHA-256** di atas, lalu klik Simpan.
5. Klik tombol **Download google-services.json**.
6. Gantikan file lama di project ini pada lokasi:
   `android/app/google-services.json`.

> [!NOTE]
> Setelah SHA-1 dimasukkan, Firebase secara otomatis membuatkan OAuth 2.0 Client ID untuk Android sehingga kolom `"oauth_client"` di `google-services.json` tidak lagi kosong.

---

## 3. Langkah Konfigurasi Google Authentication

1. Di menu kiri Firebase Console, klik **Build** -> **Authentication** -> tab **Sign-in method**.
2. Pastikan penyedia **Google** berstatus **Enabled (Diaktifkan)**.
3. Masukkan Project support email (email Anda/Google developer).
4. Klik **Save**.

---

## 4. Langkah Konfigurasi Google Calendar API (Google Cloud)

Untuk memunculkan persetujuan resmi Google Calendar (*"KerKom ingin mengakses Kalender Google Anda"*):

1. Buka [Google Cloud Console](https://console.cloud.google.com/).
2. Pastikan project yang aktif di bagian atas adalah **kerkom-project** (nomor project: `834453228503`).
3. Buka menu navigasi -> **APIs & Services** -> **Library**.
4. Cari `Google Calendar API`, lalu klik tombol **Enable (Aktifkan)**.
5. Buka **APIs & Services** -> **OAuth consent screen** (Layar persetujuan OAuth):
   - **User Type**: Pilih *External* (atau *Internal* jika Google Workspace).
   - **App name**: `KerKom Focus`
   - **User support email**: Email Anda
   - Di bagian **Scopes (Cakupan)**, klik **Add or Remove Scopes**:
     - Tambahkan `.../auth/calendar.events` (Melihat dan mengedit acara di Google Calendar).
   - Di bagian **Test users**: Tambahkan email akun Google yang Anda gunakan untuk menguji aplikasi di ponsel.
   - Klik **Save and Continue**.

---

## 5. Menguji di Aplikasi KerKom

1. Buka menu **Profil** -> **Integrasi Kalender**.
2. Aktifkan toggle **Google Calendar**:
   - Sistem akan memunculkan dialog resmi pemilihan akun Google & persetujuan akses Google Calendar.
   - Klik **Izinkan (Allow)**.
   - Indikator akan langsung berubah menjadi hijau: `Persetujuan Google Calendar berhasil!`.
