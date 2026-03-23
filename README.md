# 🥦 Makan Bergizi Murah

Aplikasi Flutter untuk membantu masyarakat menemukan pilihan makanan bergizi dengan harga terjangkau.

## Fitur

### 🏠 Beranda
- Tips gizi harian
- Rekomendasi makanan di bawah Rp 10.000

### 🍽️ Daftar Menu
- Browsing menu berdasarkan kategori
- Sortir berdasarkan harga, kalori, atau protein
- Info nutrisi lengkap (kalori, protein, karbo, lemak)

### 🧮 Kalkulator Budget
- Masukkan budget harian
- Pilih jumlah makan per hari
- Lihat makanan mana yang sesuai budget kamu

## Struktur Proyek

```
lib/
├── main.dart              # Entry point + navigasi
├── models/
│   └── food_item.dart     # Model data makanan
├── screens/
│   ├── home_screen.dart   # Halaman beranda
│   ├── menu_screen.dart   # Halaman daftar menu
│   └── calculator_screen.dart  # Kalkulator budget
└── widgets/
    └── food_card.dart     # Komponen kartu makanan
```

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

## Tech Stack

- Flutter 3.x
- Material Design 3
- Dart

---

*Dibuat dengan ❤️ — Makan sehat nggak harus mahal!*
