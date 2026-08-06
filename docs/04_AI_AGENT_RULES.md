# ATURAN WAJIB UNTUK AI AGENT

Dokumen ini adalah kontrak kerja untuk AI (Claude Code atau agent lain) yang membantu membangun project ini lintas sesi. **Baca ini di awal SETIAP sesi, tanpa kecuali.**

## 1. Aturan Non-Negotiable

1. **Selalu baca `05_PROGRESS_TRACKER.md` sebelum melakukan apapun.** Ini menentukan sistem mana yang boleh disentuh dan mana yang tidak.
2. **Selalu baca dokumen desain relevan** (`01_GDD.md` / `02_TDD.md` / `03_DDD.md`) untuk fitur yang akan dikerjakan, sebelum menulis kode.
3. **Dilarang mengubah, merefactor besar-besaran, atau menghapus sistem berstatus "✅ Selesai"** tanpa instruksi eksplisit dari pemilik project pada sesi berjalan. Bugfix kecil pada sistem "Selesai" boleh, tapi harus dicatat jelas sebagai bugfix di changelog, bukan disamarkan sebagai fitur baru.
4. **Perubahan bersifat ADITIF.** Tambahkan fitur baru lewat modul/fungsi baru. Jangan menimpa logic yang sudah berjalan kecuali memang itu tugasnya (bugfix yang diminta).
5. **Tidak ada hardcode.** Semua angka balance, ID, teks, relasi (elemen, drop table, dll.) wajib diambil dari modul `Configs/*`, sesuai `03_DDD.md`. Jika menemukan hardcode lama saat bekerja di area itu, boleh diusulkan untuk dipindah ke Config — tapi catat di progress tracker, jangan diam-diam mengubah banyak file sekaligus.
6. **Server tidak pernah percaya client.** Setiap RemoteEvent/Function baru wajib melalui checklist anti-exploit di `06_CODING_STANDARDS.md` sebelum ditandai selesai.
7. **Setiap sesi kerja WAJIB ditutup dengan update** ke `05_PROGRESS_TRACKER.md` (status sistem + entri session log) dan `07_CHANGELOG.md`. Jangan akhiri sesi tanpa mencatat apa yang berubah.
8. **Kode aktual adalah kebenaran soal "apa yang sudah dibangun".** Dokumen desain adalah kebenaran soal "apa yang seharusnya dibangun". Jika keduanya berbeda, laporkan perbedaan itu ke pemilik project, jangan diam-diam menyamakan salah satunya.
9. **Dilarang menambah dependency/library eksternal baru** tanpa mencatatnya di `02_TDD.md` bagian Tech Stack/Perubahan Arsitektur.
10. **Jika instruksi pemilik project bertentangan dengan dokumen ini** (mis. diminta menulis angka hardcode "karena buru-buru"), ingatkan risikonya dengan singkat, tapi ikuti keputusan eksplisit pemilik project untuk sesi tersebut — lalu catat penyimpangan itu di changelog agar bisa dirapikan nanti.

## 2. Definition of Done (per fitur)
Sebuah fitur baru baru boleh ditandai **✅ Selesai** di progress tracker jika:
- [ ] Sesuai spesifikasi di `01_GDD.md` (atau penyimpangan dicatat & disetujui).
- [ ] Tidak ada nilai hardcode — semua lewat `Configs/*`.
- [ ] Semua Remote terkait lolos checklist anti-exploit (`02_TDD.md` §7 dan `06_CODING_STANDARDS.md`).
- [ ] Sudah diuji manual minimal sekali di Studio (Play Solo atau Team Test).
- [ ] Tidak merusak fitur lain yang sebelumnya berstatus Selesai (dicek sekilas).
- [ ] `05_PROGRESS_TRACKER.md` dan `07_CHANGELOG.md` sudah diupdate.

## 3. Format Update Progress Tracker
Setiap sesi, tambahkan entri baru di bagian **Session Log** `05_PROGRESS_TRACKER.md` dengan format:
```
### [YYYY-MM-DD] Ringkasan singkat sesi
- Dikerjakan: ...
- File yang disentuh: ...
- Status sistem yang berubah: SistemX ⬜→🔄 / SistemY 🔄→✅
- Diketahui belum selesai / next step: ...
- Catatan risiko/exploit yang perlu direview manusia: ...
```

## 4. Kapan Harus Berhenti dan Bertanya (bukan asal jalan terus)
- Spesifikasi di GDD ambigu atau belum ada untuk fitur yang diminta.
- Task yang diminta akan memaksa mengubah sistem yang sudah "Selesai" secara signifikan.
- Task yang diminta secara eksplisit meminta hardcode, skip validasi server, atau shortcut yang berisiko exploit.
- Konflik antara apa yang tercatat di progress tracker dengan kondisi kode aktual (kemungkinan tracker basi/tidak update).

Dalam kasus di atas: **jelaskan situasinya dan minta arahan**, jangan menebak dan lanjut membangun di atas asumsi yang belum jelas.
