# Verifikasi revisi aplikasi

Pengujian otomatis: `flutter analyze --no-pub` bersih tanpa temuan;
`flutter test --no-pub` lulus 38 pengujian, termasuk regresi revisi ini.

Uji penerimaan pada dua ponsel Android (ketua dan anggota):

| Revisi | Skenario | Hasil yang diharapkan |
| --- | --- | --- |
| Sesi selesai | Buka sesi selesai dari daftar, notifikasi, atau tautan lobi/kalibrasi/sesi aktif | Langsung ringkasan; sensor dan layanan pemantauan tidak dimulai |
| Nama akun | Daftar sebagai Roma menggunakan jaringan lambat | Status memuat profil, lalu Halo, Roma; tidak pernah memakai nama contoh |
| Kata sandi | Buka daftar akun | Label Buat Kata Sandi |
| Notifikasi | Akun baru, buat ruang, akhiri sesi hari ini | Akun baru kosong; tanggal kejadian benar; tidak ada notifikasi sensor/anggota contoh |
| Status baca | Baca satu notifikasi atau Tandai Baca; keluar dan buka kembali | Tetap dibaca, termasuk ikon lonceng; akun lain punya status tersendiri |
| Foto profil | Gunakan foto unggahan, diamkan di ruang beberapa menit | Foto tetap stabil ketika timer, telemetri, dan heartbeat diperbarui |
| Notifikasi sesi | Mulai sesi dan tunggu satu menit | Satu notifikasi pemantauan tetap, tanpa pemberitahuan berulang setiap detik |
| Sensor awal | Kalibrasi di meja, uji menghadap atas dan bawah | Awalnya aman; angkat memicu satu pelanggaran; letakkan kembali memulihkan status |
| Latar belakang | Kunci layar, angkat lalu letakkan HP; buka aplikasi | Pelanggaran dan pemulihan sinkron; tidak ada dua mesin sensor yang menulis bersamaan |
| Tombol kembali HP | Buka pengaturan dari profil, tekan kembali sampai dashboard | Kembali satu halaman; dashboard menampilkan konfirmasi sebelum keluar |
| Google | Ikuti panduan OAuth, uji akun baru/lama dan batal pilih akun | Login berhasil dengan proyek/sertifikat yang sesuai; batal tetap di autentikasi |
| Tentang dan profil | Buka Tentang Aplikasi dan Profil | Nama Dr. Siti Mas'ula, M.Pd.; menu integrasi kalender dihapus |

Status baca disimpan per akun pada `users/{uid}/notificationReads`, menggunakan
aturan akses node pengguna yang sudah ada. Membaca riwayat tidak lagi menulis
ulang `completedAt` atau membuat rekaman sesi dari jadwal. Rekaman lama yang
tanggalnya sudah terlanjur ditimpa tidak dikoreksi dengan perkiraan.

Perangkat fisik belum terhubung saat implementasi. Alarm, pengalihan pemantauan
ke layanan Android, dan dialog akun Google tetap memerlukan uji perangkat.
