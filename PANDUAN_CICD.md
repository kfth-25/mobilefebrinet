# 🚀 Panduan Final CI/CD Flutter: Febri.Net Pro

Dokumen ini berisi cara menjalankan build aplikasi Flutter menggunakan sistem **Build Variants (Flavors)** dan **GitHub Actions** yang sudah kita optimasi.

## 🛠️ 1. Konfigurasi Project (Status: Aktif)
Project lo sekarang menggunakan format **Groovy (`.gradle`)** yang lebih stabil dan mendukung:
- **Java SDK**: Versi 24 (Lokal) / Versi 17 (GitHub).
- **NDK**: Versi 28.2.x (Sesuai syarat plugin JNI).
- **Gradle**: Versi 8.10.2.
- **Flavors**: `dev` (Development) & `prod` (Production).

---

## 💻 2. Cara Menjalankan di Lokal (Laptop)
Karena sekarang kita menggunakan **Flavors**, perintah build standar sudah berubah.

### **A. Build Versi Production (Rekomendasi)**
Gunakan ini untuk hasil akhir yang siap dipakai:
```bash
flutter clean
flutter build apk --release --flavor prod --split-per-abi
```

### **B. Build Versi Development**
Gunakan ini kalau lo mau ngetes versi "developer" (dengan package ID `.dev`):
```bash
flutter clean
flutter build apk --release --flavor dev --split-per-abi
```

---

## 🤖 3. Cara Menjalankan di GitHub (Otomatis)
Sistem **GitHub Actions** lo sekarang sudah "Dewa" (Parallel Build).

### **A. Push Kode Biasa**
Tiap kali lo push ke branch `main`, GitHub akan otomatis nge-build **Dua Versi Sekaligus** (Dev & Prod) secara paralel.
```bash
git add .
git commit -m "feat: deskripsi perubahan lo"
git push origin main
```
*Hasil: Notifikasi & APK dikirim ke Telegram.*

### **B. Membuat Release Resmi**
Gunakan ini untuk membuat arsip download di halaman Release GitHub.
```bash
git tag v1.0.0
git push origin v1.0.0
```
*Hasil: APK masuk ke menu "Releases" di GitHub + Kirim ke Telegram.*

---

## 📢 4. Notifikasi Telegram
Setelah build selesai, bot lo akan mengirimkan:
1. **Pesan Status**: Sukses atau Gagal.
2. **File APK**: 3 jenis file (arm64, v7a, x86) untuk masing-masing flavor.
   - Pake yang **`arm64-v8a`** buat HP Android jaman sekarang.

---

## ⚠️ Troubleshooting (Jika ada masalah)
1. **Masalah Java di Lokal**: Jika lo install Java baru dan error lagi, jalankan:
   `flutter config --jdk-dir="C:\Program Files\Java\jdk-24"`
2. **Terima Lisensi**: Jika ada error soal license, jalankan:
   `flutter doctor --android-licenses`

---

**Selamat Coding, Bos! Sistem lo sekarang udah sekelas Senior Developer! 🦾🚀🔥**
