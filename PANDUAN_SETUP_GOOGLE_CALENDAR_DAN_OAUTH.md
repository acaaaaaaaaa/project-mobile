# Konfigurasi login Google KerKom

Integrasi kalender telah dihapus. Login Google hanya meminta identitas akun dan email.

## Kondisi konfigurasi saat revisi

`android/app/google-services.json` untuk proyek `kerkom-project` masih berisi
`oauth_client: []`. ID klien OAuth tidak dapat dibuat dengan menebak nilainya;
konfigurasi berikut harus diselesaikan oleh pemilik proyek Firebase/Google Cloud.

## Langkah konfigurasi Android

1. Di Firebase Console proyek **kerkom-project**, aktifkan **Authentication >
   Sign-in method > Google**, tentukan email dukungan, lalu simpan.
2. Jalankan dari direktori `android`:

   ```powershell
   .\gradlew.bat signingReport
   ```

   Daftarkan SHA-1 dan SHA-256 dari sertifikat build yang benar di **Project settings >
   Your apps > com.mobcom.focusroom.focus_room**. Untuk build yang didistribusikan
   lewat Google Play, daftarkan juga sertifikat App Signing dari Play Console.
   Fingerprint debug dapat berbeda antar komputer; jangan menyalin fingerprint
   dari komputer lain sebagai pengganti sertifikat build yang sedang diuji.
3. Unduh ulang `google-services.json` setelah penyedia Google dan sertifikat
   dikonfigurasi. Ganti `android/app/google-services.json`.
4. Pastikan klien aplikasi Android mempunyai paket yang sesuai dan terdapat klien
   OAuth tipe web (`client_type: 3`). Plugin akan memakai Web Client ID tersebut
   untuk meminta ID token bagi Firebase Authentication.
5. Jika Web Client ID disediakan terpisah, aplikasi mendukung:

   ```powershell
   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
   ```

   Gunakan ID asli dari proyek yang sama. Pengaturan ini tidak menggantikan
   aktivasi penyedia Google atau pendaftaran sertifikat Android.
6. Bangun ulang aplikasi. Uji akun Google baru melalui tombol **Daftar dengan
   Google** dan akun lama melalui **Masuk dengan Google**. Akun baru menuju
   lengkapi profil, lalu dashboard menampilkan nama akun tersebut. Pembatalan
   pemilihan akun harus tetap meninggalkan pengguna pada halaman autentikasi.

Tidak ada konfigurasi Firebase jarak jauh yang diubah dalam revisi ini. Login
Google belum dapat dinyatakan berhasil sebelum konfigurasi di atas tersedia dan
diuji di perangkat dengan Google Play services.

Referensi: [Firebase Google authentication](https://firebase.google.com/docs/auth/flutter/federated-auth#google),
[konfigurasi plugin Android](https://pub.dev/packages/google_sign_in_android).
