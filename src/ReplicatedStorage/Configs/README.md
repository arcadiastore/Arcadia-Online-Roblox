# Configs
Satu-satunya tempat sumber kebenaran untuk SEMUA angka balance, ID, dan relasi
data game (ras, kelas, elemen, skill, item, musuh, quest, gate, level curve).

Lihat `docs/03_DDD.md` untuk skema lengkap tiap file & contoh entry.
Logic di `Services/` (server) WAJIB `require()` modul di sini — dilarang keras
menulis angka/nama literal langsung di dalam Service (lihat aturan anti-hardcode
di `docs/06_CODING_STANDARDS.md` §2).

File di folder ini saat ini masih skeleton (return table kosong) — belum diisi
data desain final. Isi tabel setelah konten di `docs/01_GDD.md` difinalisasi.
