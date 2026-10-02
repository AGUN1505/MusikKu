# MusikKu

Aplikasi pemutar musik modern berbasis **Flutter** (Material 3) dengan antarmuka yang elegan dan responsif.

---

## Fitur Utama (UI & State Awal)

- **Dark Theme Imersif:** Palette warna modern berbasis Material 3 dengan kontras dan gradien aksen.
- **Beranda Interaktif:**
  - Header profil & pencarian.
  - *Baru Saja Diputar* (Quick grid).
  - *Playlist Pilihan* (Horizontal card scroll dengan gradien).
  - *Daftar Lagu Terpopuler*.
  - *Persistent Mini-Player* dengan kontrol Play/Pause responsif.
  - *Bottom Navigation Bar* (Beranda, Jelajah, Koleksi, Profil).
- **Layar Now Playing (Full Screen Player):**
  - Cover art dengan efek glow dan bayangan lembut.
  - Judul lagu, artis, dan tombol favorit toggle.
  - Seek bar / slider progress lagu yang dapat digeser.
  - Kontrol lengkap (Shuffle, Previous, Play/Pause, Next, Repeat).

---

## Struktur Direktori

Proyek ini menggunakan arsitektur **Feature-First / Core** yang modular dan mudah dikembangkan:

```
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart         # Palet warna & token desain
│   └── theme/
│       └── app_theme.dart          # Konfigurasi Material 3 Dark Theme
├── features/
│   ├── home/
│   │   └── presentation/
│   │       └── screens/
│   │           └── home_screen.dart # Halaman beranda & mini-player
│   └── player/
│       ├── domain/
│       │   └── models/
│       │       └── song.dart       # Model data lagu & sample data
│       └── presentation/
│           └── screens/
│               └── now_playing_screen.dart # Layar pemutar musik penuh
├── app.dart                        # Widget root MusikKuApp
└── main.dart                       # Entry point aplikasi & konfigurasi SystemUI
```

---

## Cara Menjalankan

1. **Jalankan aplikasi di emulator atau perangkat:**
   ```bash
   flutter run
   ```

2. **Jalankan analisis kode:**
   ```bash
   flutter analyze
   ```

3. **Jalankan unit/widget test:**
   ```bash
   flutter test
   ```
