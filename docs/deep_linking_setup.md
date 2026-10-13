# Panduan Konfigurasi Deep Linking Kerkom (`kerkom.app/j/{code}`)

Dokumen ini menjelaskan langkah-langkah teknis untuk mengaktifkan **Android App Links** dan **iOS Universal Links** untuk aplikasi Kerkom menggunakan domain `kerkom.app`.

---

## 1. File Konfigurasi Android (`assetlinks.json`)

Host file ini di server web publik Anda pada URL:
`https://kerkom.app/.well-known/assetlinks.json`
*(Harus diakses menggunakan HTTPS dengan Content-Type: `application/json`)*

### Isi File `assetlinks.json`:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.focus_room",
      "sha256_cert_fingerprints": [
        "14:D6:E7:5C:A5:42:3B:5A:F3:D5:77:4A:20:98:C0:B0:96:A2:8E:D6:7A:B4:8A:28:BE:76:CD:0B:4D:45:90:38"
      ]
    }
  }
]
```

> **Catatan Fingerprint SHA-256:**
> Anda dapat memperoleh SHA-256 keystore debug lokal dengan menjalankan perintah:
> ```bash
> keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
> ```
> Atau jika menggunakan Google Play App Signing, salin SHA-256 dari **Play Console > Release > Setup > App Signing**.

---

## 2. Konfigurasi iOS Universal Links (`apple-app-site-association`)

Host file ini pada URL:
`https://kerkom.app/.well-known/apple-app-site-association`
*(Tanpa ekstensi file `.json`, diakses via HTTPS)*

### Isi File `apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAM_ID>.com.example.focusRoom",
        "paths": ["/j/*"]
      }
    ]
  }
}
```

### Konfigurasi Xcode / iOS:
1. Buka project di Xcode (`ios/Runner.xcworkspace`).
2. Masuk ke **Signing & Capabilities** -> klik **+ Capability** -> pilih **Associated Domains**.
3. Tambahkan domain:
   `applinks:kerkom.app`

---

## 3. Alur Kerja di Aplikasi Kerkom
1. Teman membagikan tautan: `https://kerkom.app/j/KRK-7K2Q`.
2. Pengguna mengklik tautan dari WhatsApp / Telegram / Browser.
3. Aplikasi **Kerkom** langsung terbuka otomatis (tanpa dialog browser pilihan).
4. **Jika Pengguna Belum Login**:
   - Kode ruang disimpan sementara di aplikasi.
   - Pengguna diarahkan untuk Masuk (S02) atau Daftar (S18).
   - Setelah login/daftar selesai, pengguna **langsung dialihkan otomatis ke Lobi Ruang (S07)**.
5. **Jika Pengguna Sudah Login**:
   - Pengguna langsung otomatis bergabung ke ruang belajar dan masuk ke Lobi Ruang (S07).
