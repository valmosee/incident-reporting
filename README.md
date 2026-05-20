# kelompokc_incidentreporting

A new Flutter project.

## Halaman Login & Session -> Darrel

File Terkait
```
lib/login.dart
lib/auth.dart
lib/main.dart
```

Fitur yang Diimplementasikan
1. Halaman Login

- Form input email dan password
- Validasi input sebelum request dikirim
- Feedback error jika kredensial salah
- Navigasi otomatis ke halaman sesuai role setelah login berhasil

2. Session Persistence

- Sesi pengguna tersimpan secara otomatis oleh Supabase Flutter SDK
- AuthGate mengecek status sesi setiap kali app dibuka
- Jika sesi masih aktif, pengguna langsung diarahkan ke halaman yang sesuai tanpa perlu login ulang