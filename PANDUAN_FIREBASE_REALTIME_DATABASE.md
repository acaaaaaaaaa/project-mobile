# 🔥 Panduan Firebase Realtime Database & Fitur Sinkronisasi Fokus

Panduan ini menjelaskan cara mengonfigurasi Firebase Realtime Database pada proyek **StudyPact / FocusRoom**, aturan keamanan (*Security Rules*), struktur penyimpanan data, serta cara menguji sinkronisasi data antar-pengguna secara real-time.

---

## 1. URL Database & Wilayah
- **URL Realtime Database:** `https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/`
- **Region:** `asia-southeast1` (Singapura)
- **Project ID:** `kerkom-project`

---

## 2. Pengaturan Rules (Aturan Database) di Firebase Console

Buka [Firebase Console](https://console.firebase.google.com/) -> Pilih project **kerkom-project** -> Pilih **Realtime Database** pada menu sebelah kiri -> Buka tab **Rules (Aturan)**.

### Opsi A: Aturan Pengujian & Pengembangan (Development / Testing Mode)
Gunakan aturan ini agar aplikasi langsung dapat membaca dan menulis data tanpa autentikasi yang rumit:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

### Opsi B: Aturan Terstruktur (Production / Validated Mode)
Jika ingin memastikan data hanya diakses pada node yang terstruktur (pengguna, ruang, dan riwayat sesi):

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": true,
        ".write": true
      }
    },
    "rooms": {
      "$roomCode": {
        ".read": true,
        ".write": true,
        "members": {
          "$memberId": {
            ".read": true,
            ".write": true
          }
        },
        "alerts": {
          ".read": true,
          ".write": true
        }
      }
    },
    "session_logs": {
      "$uid": {
        ".read": true,
        ".write": true
      }
    }
  }
}
```

> **Langkah Simpan:** Klik tombol **Publish (Publikasikan)** di pojok kanan atas tab Rules di Firebase Console.

---

## 3. Struktur Node Data di Firebase

Database dirancang untuk menyimpan dan menyebarkan data secara efisien melalui 3 node utama:

```
kerkom-project-default-rtdb/
├── users/
│   └── {userId}/
│       ├── id: "user-123"
│       ├── name: "Farhan"
│       ├── level: 14
│       ├── xp: 840
│       ├── streakDays: 7
│       └── lastActive: 1712490000000
│
├── rooms/
│   └── {roomCode}/               (Contoh: PACT-7492)
│       ├── code: "PACT-7492"
│       ├── title: "Kerkom Algoritma Lanjut"
│       ├── leaderId: "user-123"
│       ├── durationMinutes: 45
│       ├── remainingSeconds: 2700
│       ├── isSessionActive: true
│       ├── members/
│       │   ├── {memberId_1}/
│       │   │   ├── id: "user-123"
│       │   │   ├── name: "Farhan (Anda)"
│       │   │   ├── isLeader: true
│       │   │   ├── status: "focusing"  (atau "phoneLifted")
│       │   │   ├── distractionCount: 0
│       │   │   ├── pitch: 0.02
│       │   │   ├── roll: 0.02
│       │   │   └── vibration: 0.0
│       │   └── {memberId_2}/
│       │       ├── id: "user-456"
│       │       ├── name: "Budi Santoso"
│       │       └── status: "focusing"
│       └── alerts/
│           └── {alertId}/
│               ├── memberName: "Budi Santoso"
│               ├── message: "Budi Santoso baru saja mengangkat smartphone!"
│               └── timestamp: 1712490123000
│
└── session_logs/
    └── {userId}/
        └── {logId}/
            ├── roomCode: "PACT-7492"
            ├── title: "Kerkom Algoritma Lanjut"
            ├── durationMinutes: 45
            ├── distractionCount: 1
            ├── xpEarned: 29
            └── completedAt: 1712492700000
```

---

## 4. Alur Kerja Sinkronisasi Antar-Pengguna (Sharing Fitur Focus)

1. **Host Membuat Ruang**:
   - Host membuka dialog *Buat Ruang* di tab Beranda.
   - Aplikasi membuat ruang baru dan mendaftarkannya ke Firebase di node `/rooms/{roomCode}`.
   - Host membagikan kode ruang (contoh: `PACT-7492`) ke teman kelompok.

2. **Anggota Bergabung**:
   - Anggota memasukkan kode `PACT-7492` melalui tombol *Gabung Kode*.
   - Aplikasi mendaftarkan data anggota ke node `/rooms/PACT-7492/members/{memberId}`.
   - Seluruh anggota di dalam ruang otomatis melihat daftar anggota yang terus diperbarui secara live.

3. **Mulai Sesi Bersama**:
   - Host menekan tombol *Mulai Kalibrasi Bersama*.
   - Nilai `isSessionActive` di Firebase berubah menjadi `true`.
   - Seluruh perangkat peserta yang terhubung langsung memulai sesi fokus dan mengaktifkan sensor.

4. **Deteksi Distraksi & Broadcast Peringatan**:
   - Jika salah satu peserta mengangkat HP dari meja, sensor gerak (`sensors_plus`) mendeteksi perubahan akselerasi/sudut kemiringan.
   - Status anggota diperbarui ke Firebase: `status = "phoneLifted"` dan `distractionCount += 1`.
   - Sebuah peringatan di-broadcast ke `/rooms/PACT-7492/alerts`.
   - **Seluruh perangkat peserta lain serentak menerima peringatan** berupa indikator kartu berubah merah dan notifikasi darurat.

---

## 5. Cara Menguji Sinkronisasi Antara 2 Perangkat

Anda dapat menguji fitur ini dengan:
1. **Device 1 (Emulator Android Studio)**: Jalankan aplikasi, lalu buat room (Host). Catat kode ruang yang muncul (misal: `PACT-8291`).
2. **Device 2 (HP Android Fisik via USB / Emulator kedua)**: Jalankan aplikasi, klik *Gabung Kode*, lalu masukkan kode `PACT-8291`.
3. Keduanya akan otomatis terhubung ke room yang sama melalui Firebase Realtime Database.
4. Coba gerakkan HP fisik atau tekan tombol **Simulasi Angkat HP** di emulator:
   - Status di layar kedua perangkat akan langsung berubah serentak secara real-time!
