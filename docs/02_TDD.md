# TECHNICAL DESIGN DOCUMENT (TDD)

## 1. Tech Stack
- **Engine:** Roblox Studio
- **Bahasa:** Luau
- **Workflow:** Rojo (sinkronisasi file .lua ↔ Roblox Studio) + Git untuk version control
- **Arsitektur:** Server-authoritative, client hanya untuk input & presentasi

## 2. Arsitektur Umum
```
Client (input, UI, prediksi visual ringan)
   ⇅  RemoteEvent / RemoteFunction (tervalidasi)
Server (logika, kalkulasi, kebenaran data, DataStore)
```
- Semua keputusan yang memengaruhi progres pemain (damage, loot, currency, level) **dihitung di server**.
- Client boleh melakukan efek visual/prediksi lokal, tapi hasil akhir selalu ditimpa oleh server.

## 3. Struktur Project (Rojo)
```
src/
├── ReplicatedStorage/
│   ├── Shared/          -- ModuleScript dipakai client & server (util, tipe, konstanta non-rahasia)
│   ├── Configs/         -- SEMUA data balance & konten (Races, Classes, Elements, Items, Enemies, Quests, Gates)
│   └── Remotes/          -- Definisi RemoteEvent/RemoteFunction (folder terstruktur per sistem)
├── ServerScriptService/
│   └── Services/         -- Satu ModuleScript "Service" per sistem (CombatService, QuestService, DataService, dst.)
├── ServerStorage/
│   └── Private/          -- Data/model yang TIDAK BOLEH diakses client (loot table asli, formula rahasia)
├── StarterPlayerScripts/
│   └── Controllers/       -- Satu "Controller" per sistem di sisi client, menangani UI & input
└── StarterGui/
    └── UI/                -- Komponen UI
```
**Aturan:** satu sistem = satu Service (server) + satu Controller (client) + satu Config (data). Jangan campur logic beberapa sistem dalam satu file besar ("God Script").

## 4. Pola Desain
- **Service Pattern**: setiap domain (Combat, Quest, Inventory, Gate, Party, Data) adalah modul Service tersendiri dengan API jelas (`Service.DoX(player, args)`).
- Boleh pakai framework ringan (mis. Knit-style) **jika** disepakati dan dicatat di sini — jangan ganti arsitektur di tengah jalan tanpa update dokumen ini.
- Hindari singleton global yang saling bergantung tanpa jalur jelas (circular dependency).

## 5. Remote Events / Functions
| Nama Remote | Arah | Payload | Validasi Server Wajib |
|---|---|---|---|
| `Character/RerollRace` | Client→Server (Function) | - (tidak ada argumen) | rate-limited (0.5s debounce); RNG dihitung di server berdasarkan bobot di `Configs/Races.lua`; hanya bisa dipanggil jika `RaceId == nil` (belum pilih ras) |
| `Character/ConfirmRace` | Client→Server (Function) | raceId (string) | tipe argumen string; `raceId` divalidasi ada di `Configs/Races.lua`; hanya jika `RaceId == nil`; stat bonus ras diterapkan server-side |
| `Character/SelectClass` | Client→Server (Function) | classId (string) | tipe argumen string; `classId` divalidasi ada di `Configs/Classes.lua` dan `tier == 1`; hanya jika sudah punya `RaceId` dan `ClassId == nil` |
| `Character/CreationStatus` | Client→Server (Function) | - (tidak ada argumen) | rate-limited (1s debounce); hanya kirim status milik pemain sendiri (`hasRace`, `hasClass`) |
| `Combat/RequestAttack` | Client→Server | targetId, skillId | cooldown, jarak, LOS, kepemilikan skill, mana cukup |
| `Inventory/UseItem` | Client→Server | itemId | kepemilikan item, jumlah, cooldown item |
| `Quest/Accept` | Client→Server | questId | syarat level/prasyarat quest terpenuhi |
| `Gate/RequestOpen` | Client→Server | gateId | syarat gate (level/quest/key) benar-benar terpenuhi di server |
| `Data/GetProfile` | Client→Server (Function) | - | hanya kirim data milik pemain sendiri (tidak ada parameter userId), rate-limited per player (`GetProfileMinIntervalSeconds`), deep copy sebelum dikirim (bukan reference server) — implementasi: `Services/DataService/RemoteHandlers.lua` |

_(Tabel ini WAJIB diperbarui setiap kali menambah remote baru — jangan biarkan remote baru tanpa baris validasi.)_

**Aturan baku semua remote:**
1. Selalu `typeof()`/type-check tiap argumen sebelum dipakai.
2. Selalu rate-limit (debounce per-player) di server, bukan cuma di client.
3. Selalu recompute nilai penting di server (jangan percaya angka damage/harga yang dikirim client).
4. RemoteFunction yang mengembalikan data harus difilter agar tidak bocorkan data pemain lain / config rahasia.

## 6. Penyimpanan Data (DataStore)
- Gunakan pola **profile-based DataStore** (session locking, auto-retry, auto-save berkala, save saat player leave & saat server shutdown `game:BindToClose`).
- Setiap profil data punya field `SchemaVersion` (lihat `03_DDD.md`) untuk migrasi aman.
- **Backup/anti-data-loss:** simpan ke DataStore utama + (opsional) OrderedDataStore/backup store untuk histori penting (mis. currency besar).
- **Anti-dupe:** operasi yang mengubah currency/item harus atomik dalam satu alur server (lock profil selama transaksi), tidak boleh ada 2 request paralel memproses transaksi yang sama.

## 7. Anti-Exploit Checklist (wajib untuk SETIAP fitur baru)
- [ ] Tidak ada keputusan penting (damage, drop, currency, level up) yang murni dihitung di client lalu "dipercaya" server.
- [ ] Semua RemoteEvent/Function divalidasi tipe data & batas nilai (min/max, tidak negatif, dst.).
- [ ] Rate limiting / debounce per-player di server untuk aksi yang bisa di-spam.
- [ ] Sanity check posisi/jarak (mis. tidak bisa menyerang musuh yang jauh, tidak bisa buka gate dari zona lain).
- [ ] Tidak ada informasi sensitif (formula loot, config rahasia, data pemain lain) dikirim ke client tanpa perlu.
- [ ] Semua item/currency yang bertambah, tercatat via satu jalur Service resmi (tidak ada shortcut/manual `leaderstat` edit dari script lain).
- [ ] Diuji: apakah exploit umum (spam remote, ubah argumen jadi nilai ekstrem/negatif, replay request lama) tetap gagal?

## 8. Replikasi & Performance
- Gunakan `Instance:SetAttribute` untuk state ringan yang perlu direplikasi (HP, status effect) daripada RemoteEvent broadcast terus-menerus.
- Streaming Enabled untuk dunia besar.
- Dungeon/instance dijalankan via **Reserved Server / TeleportService** agar terisolasi per-party.
- Pooling untuk efek VFX/proyektil yang sering muncul (hindari `Instance.new` berlebihan tiap frame).

## 9. Testing
- Test manual di Studio (Play Solo + Team Test/local server untuk multipemain).
- Modul murni (kalkulasi damage, elemen, formula) sebaiknya bisa dites terpisah dari Roblox API (pure function) agar mudah di-unit-test.
- Gunakan test/staging place terpisah dari place produksi sebelum publish perubahan besar.

## 10. Workflow Git/Rojo
- Branch per fitur, PR/review sebelum merge ke `main`.
- `default.project.json` (Rojo) menjadi sumber kebenaran struktur instance — jangan susun ulang hierarki manual di Studio tanpa sinkron balik ke source.
- Commit message jelas, rujuk ke sistem yang diubah (mis. `feat(combat): tambah skill AoE Wizard`).

## 11. Perubahan Arsitektur
Setiap keputusan teknis besar (ganti framework, ganti pola DataStore, dsb.) **wajib ditulis di sini dengan tanggal & alasan**, bukan diam-diam diganti oleh AI/dev lain.

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-08-06 | Implementasi DataStore/Profile system pakai `ProfileStore.lua` **buatan sendiri** (pure Luau, `ServerStorage/Private/ProfileStore.lua`), BUKAN library eksternal populer seperti ProfileService/ProfileStore (Wally). | Project belum punya dependency manager (Wally) terpasang (lihat `aftman.toml` — cuma Rojo). Menambah dependency eksternal baru butuh persetujuan & pencatatan eksplisit di sini per `04_AI_AGENT_RULES.md` §1.9; daripada menambah Wally di tengah sesi tanpa arahan pemilik project, dibuat implementasi sendiri yang cukup untuk kebutuhan §6 (session lock, auto-retry, autosave, save saat leave/shutdown). **Bisa direvisit**: kalau pemilik project lebih memilih ProfileService/ProfileStore asli (lebih teruji di produksi skala besar), ganti di sesi terpisah dengan mencatat alasan & migrasi datanya di sini — jangan diam-diam diganti.|
