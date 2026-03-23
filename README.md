# 📷 Scan Nilai Gizi

Aplikasi Flutter untuk memindai **Tabel Informasi Nilai Gizi** pada kemasan produk makanan Indonesia (format BPOM PerBPOM No.22/2019).

## Cara Kerja

1. Foto tabel "Informasi Nilai Gizi" pada kemasan produk
2. ML Kit OCR membaca teks dari gambar secara on-device
3. Parser mendeteksi semua field nutrisi otomatis
4. Hasil ditampilkan dalam format tabel BPOM resmi
5. Salin atau bagikan hasilnya

## Data yang Diekstrak

- Takaran Saji & Jumlah Sajian per Kemasan
- Energi Total & Energi dari Lemak
- Lemak Total, Lemak Jenuh, Lemak Trans
- Kolesterol & Natrium
- Karbohidrat Total, Serat Pangan, Gula
- Protein
- Vitamin & Mineral + %AKG

## Struktur Proyek

```
lib/
├── main.dart                        # Entry point
├── models/
│   └── nutrition_label.dart         # Data model label BPOM
├── screens/
│   └── scanner_screen.dart          # UI scanner + hasil
└── services/
    └── nutrition_parser.dart        # Parser OCR text → data terstruktur
```

## Dependencies

| Package | Fungsi |
|---|---|
| `google_mlkit_text_recognition` | OCR on-device (offline) |
| `image_picker` | Kamera & galeri |
| `share_plus` | Share sheet |
| `permission_handler` | Izin kamera/storage |

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

## Perizinan

- Android: `CAMERA`, `READ_MEDIA_IMAGES`
- iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
