# INDEX DOKUMENTASI PROJECT
**Working Title:** _(isi nama project di sini)_
**Genre:** Medieval Fantasy MMORPG, slow-paced, party-based, portal/gate progression
**Inspirasi utama:** Roblox "The Portal" (race system, class system, element chart, slow progression)
**Engine:** Roblox Studio + Luau, workflow via Rojo + Git

---

## 1. Struktur Folder Dokumentasi

| File | Isi | Wajib dibaca sebelum |
|---|---|---|
| `00_INDEX.md` | Dokumen ini — peta semua dokumen | Selalu, pertama kali |
| `01_GDD.md` | Game Design Document — visi, gameplay, sistem game | Membuat/mengubah fitur gameplay |
| `02_TDD.md` | Technical Design Document — arsitektur, struktur project, jaringan | Menulis/mengubah kode |
| `03_DDD.md` | Data Design Document — skema data, config table, DataStore | Menyentuh data pemain/config |
| `04_AI_AGENT_RULES.md` | Aturan wajib untuk AI/agent yang mengerjakan project ini | **Setiap sesi kerja, tanpa kecuali** |
| `05_PROGRESS_TRACKER.md` | Status terkini semua sistem + log sesi kerja | **Setiap sesi kerja, tanpa kecuali** |
| `06_CODING_STANDARDS.md` | Standar kode, checklist anti-hardcode & anti-exploit | Sebelum menandai fitur "Selesai" |
| `07_CHANGELOG.md` | Riwayat perubahan versi | Setelah setiap sesi kerja |

---

## 2. Alur Kerja Wajib Setiap Sesi (SOP untuk AI)

```
1. Baca 05_PROGRESS_TRACKER.md  → tahu sistem apa saja yang sudah "Selesai",
   sedang dikerjakan, dan next step-nya apa.
2. Baca 04_AI_AGENT_RULES.md    → ingat batasan (jangan hardcode, jangan
   timpa sistem yang sudah Selesai, dst).
3. Baca bagian relevan di 01_GDD / 02_TDD / 03_DDD sesuai fitur yang
   akan dikerjakan.
4. Cek kode aktual di repo (bukan cuma dokumen) — kode adalah sumber
   kebenaran untuk "apa yang benar-benar sudah dibangun".
5. Kerjakan task secara ADDITIF (lihat aturan di 04_AI_AGENT_RULES.md).
6. Jalankan checklist di 06_CODING_STANDARDS.md sebelum selesai.
7. Update 05_PROGRESS_TRACKER.md (status + session log) dan
   07_CHANGELOG.md di akhir sesi. Ini WAJIB, bukan opsional.
```

## 3. Prinsip Inti Project

1. **Desain dulu, kode kemudian** — GDD/TDD/DDD adalah sumber kebenaran soal *apa yang seharusnya ada*.
2. **Progress tracker adalah sumber kebenaran soal *apa yang sudah ada*.** Jangan asumsi dari ingatan sesi sebelumnya.
3. **Tidak ada hardcode** — semua angka balance, ID, teks harus berasal dari modul Config, bukan ditulis literal di logic script.
4. **Server tidak pernah percaya client** — semua aksi penting divalidasi ulang di server.
5. **Aditif, bukan destruktif** — sistem yang sudah berstatus "Selesai" tidak diubah/direfactor tanpa instruksi eksplisit dari pemilik project.
