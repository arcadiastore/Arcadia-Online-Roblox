# CHANGELOG

Format tiap entri:
```
## [YYYY-MM-DD] Judul singkat
### Ditambahkan
- ...
### Diubah
- ...
### Diperbaiki (bugfix)
- ...
### Catatan Teknis / Risiko
- ...
```

Entri terbaru selalu ditambahkan di **paling atas** file ini, di bawah baris ini.

---

## [2026-08-06] Implementasi DataStore / Profile system
### Ditambahkan
- `ProfileStore.lua` (`ServerStorage/Private`): engine DataStore
  session-locked buatan sendiri — auto-retry+backoff, session lock antar
  server, autosave berkala, save saat player leave & server shutdown
  (`game:BindToClose`).
- `DataService` (`ServerScriptService/Services/DataService/`): Service resmi
  satu-satunya titik akses data pemain (`GetProfile`/`WaitForProfile`/
  `IsLoaded`), termasuk sub-modul `ProfileMigrations` (migrasi resmi
  SchemaVersion 1→2, menambah `ProfessionId`/`ProfessionExp`) dan
  `RemoteHandlers` (wiring remote `Data/GetProfile`).
- `ProfileTemplate.lua` (`ReplicatedStorage/Configs`): skema default profil
  pemain baru, SchemaVersion 2.
- `TableUtil.lua` (`ReplicatedStorage/Shared`): util `DeepCopy` &
  `ReconcileDefaults`, dipakai ProfileStore & DataService.
- `DataConstants.lua` (`ReplicatedStorage/Shared`): konstanta nama
  DataStore, interval autosave, timeout session lock, dsb.
- Remote `Data/GetProfile` (RemoteFunction) — instance dibuat via
  `Remotes/Data/GetProfile.model.json`, diimplementasikan rate-limited per
  player & hanya mengirim data milik pemain sendiri (deep copy).
- `Main.server.lua` (`ServerScriptService`, bootstrap) + entry baru di
  `default.project.json` untuk memanggil `DataService.Init()` saat server start.
### Diubah
- `docs/03_DDD.md` §5: resolusi eksplisit bahwa migrasi `ProfessionId`/
  `ProfessionExp` (v1→v2) dijalankan sebagai migrasi resmi pertama, bukan
  ditulis langsung ke schema berjalan — sesuai catatan di poin 0 dokumen
  yang sama.
- `docs/02_TDD.md` §5: detail validasi remote `Data/GetProfile` diperjelas
  sesuai implementasi aktual. §11: keputusan arsitektur "ProfileStore
  buatan sendiri, bukan library eksternal" dicatat dengan alasan (belum ada
  dependency manager/Wally terpasang).
### Catatan Teknis / Risiko
- **Belum dites manual di Roblox Studio** — AI tidak punya akses runtime
  Roblox, jadi fitur ini masih 🔄 (bukan ✅) di progress tracker sampai
  pemilik project menguji langsung (join normal, rebutan session lock antar
  server, leave cepat, server shutdown). Lihat detail skenario uji di
  `05_PROGRESS_TRACKER.md` session log.
- Session lock tidak pakai MessagingService untuk release lintas-server
  segera — server lain menunggu timeout 30 detik sebelum boleh mencuri lock
  dari server yang crash tanpa sempat `Release()`. Didokumentasikan sebagai
  limitasi yang diketahui di header `ProfileStore.lua`.
- Asumsi desain: `RaceId`/`ClassId` default `nil` untuk profil baru (character
  creation belum diimplementasikan) — perlu dikonfirmasi pemilik project,
  lihat `docs/03_DDD.md` §4.

## [2026-08-06] Skema aset visual (meshId/textureId/iconId) di Items.lua
### Ditambahkan
- Konvensi field aset visual untuk item: `meshId` (model 3D MeshPart),
  `textureId` (texture terpisah, opsional), `iconId` (ikon 2D UI) — format
  `rbxassetid://...`, placeholder wajib `"rbxassetid://0"` sampai aset
  final diupload. Didokumentasikan di `docs/03_DDD.md` §3/§3.1 dan header
  `Configs/Items.lua`.
### Catatan Teknis / Risiko
- Murni penyiapan skema/dokumentasi — `Items.lua` tetap skeleton kosong,
  belum ada item aktual yang didesain. Tidak ada logic Service baru, tidak
  ada permukaan exploit baru.

## [2026-08-06] Tambah jalur Kelas Assassin & profesi non-combat Craftsman
### Ditambahkan
- Jalur Kelas combat ke-6: **Assassin → Shadowblade → Nightstalker**
  (Melee Physical DPS, Dagger/Dual Blade) — `docs/01_GDD.md` §8.2,
  `Configs/Classes.lua`.
- Sistem profesi non-combat baru: **Craftsman** (§8.4 GDD), 3 rank
  (Apprentice/Journeyman/Master Craftsman), config module baru
  `Configs/Professions.lua` (skema resep + rank).
### Diubah
- `docs/03_DDD.md`: tambah `Configs/Professions.lua` ke daftar modul wajib,
  contoh skema entry Profession/Recipe/Material item, dan field
  `ProfessionId`/`ProfessionExp` di Player Profile schema.
- `docs/01_GDD.md` §14 (Ekonomi): bullet crafting diarahkan ke §8.4,
  bukan lagi "opsional fase lanjutan".
### Catatan Teknis / Risiko
- Murni data desain (Config) & dokumentasi, belum ada logic Service —
  tidak ada permukaan exploit baru.
- Perubahan ini menyentuh sistem yang sebelumnya berstatus "Selesai" di
  progress tracker (Kelas & Crafting) — dilakukan atas instruksi eksplisit
  pemilik project pada sesi ini, lihat `05_PROGRESS_TRACKER.md` Session Log.
- Field `ProfessionId`/`ProfessionExp` di Player Profile baru berlaku saat
  Profile system diimplementasi; wajib lewat migrasi resmi sesuai
  `03_DDD.md` §5, bukan ditulis langsung ke schema versi berjalan.

## [2026-08-06] Finalisasi desain MVP: Ras, Kelas/Job Tier, Elemen, Zona/Gate
### Ditambahkan
- Lore inti dunia **Arcadia** & konflik utama (Malgrath the Hollow King,
  Corruption, Angel vs Evil) di `docs/01_GDD.md` §5.
- Data final **5 Ras** (Human, Elf, Dwarf, Angel, Evil) dengan stat bonus &
  rarity — `Configs/Races.lua`.
- Data final **5 jalur Kelas** (Warrior/Defender/Mage/Healer/Archer) dengan
  Job Tier 1→2→3 lengkap syarat job change — `Configs/Classes.lua`.
- Data final **Element Chart** 6 elemen (Fire/Water/Earth/Wind/Light/Dark)
  — `Configs/Elements.lua`.
- Data final **5 Zona & Gate** (Millhaven, Duskwood Forest, Frostpeak
  Mountains, The Sunken Crypt, The Shattered Sanctum) — `docs/01_GDD.md` §6,
  `Configs/Gates.lua`.
### Catatan Teknis / Risiko
- Ini murni data desain (Config), belum ada logic Service yang membaca/
  memakainya — tidak ada permukaan exploit baru.
- `Skills.lua`, `Items.lua`, `Enemies.lua`, `Quests.lua`, `LevelCurve.lua`
  masih skeleton kosong — quest id yang direferensikan di `Classes.lua`
  dan `Gates.lua` masih placeholder, belum didesain isinya.

## [2026-08-06] Scaffolding struktur Rojo
### Ditambahkan
- `default.project.json` — manifest Rojo yang memetakan `src/` ke hierarki Roblox
  (ReplicatedStorage/Shared, Configs, Remotes; ServerScriptService/Services;
  ServerStorage/Private; StarterPlayerScripts/Controllers; StarterGui/UI).
- README di tiap folder `src/*` menjelaskan tanggung jawab & batasan folder.
- Skeleton modul Config kosong: `Races.lua`, `Classes.lua`, `Elements.lua`,
  `Skills.lua`, `Items.lua`, `Enemies.lua`, `Quests.lua`, `Gates.lua`,
  `LevelCurve.lua` (semua `return {}`, menunggu konten desain final).
### Catatan Teknis / Risiko
- Belum ada logic Service/Controller maupun Remote — murni struktur folder,
  tidak ada permukaan exploit baru.
