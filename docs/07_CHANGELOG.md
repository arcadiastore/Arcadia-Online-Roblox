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

## [2026-08-06] InventoryService + Items — tested ✅
### Ditambahkan
- `InventoryService/init.lua` (ServerScriptService/Services): server-authoritative
  inventory & equipment. API: `AddItem`, `RemoveItem`, `EquipItem`, `UnequipItem`,
  `UseItem`, `GetInventory`, `GetEquipment`, `GetEquipmentStats`, `HasItem`.
  Equipment slots: Weapon, Head, Chest, Legs, Feet, Shield, Accessory.
  Remote `Inventory/GetInventory`, `Inventory/Equip`, `Inventory/Unequip`,
  `Inventory/UseItem`. Stackable items, max 50 inventory slots.
- `Items.lua`: 27 item definitions — 7 weapon (tier 1-2), 5 armor, 1 shield,
  2 accessory, 3 consumable (HP/MP/Antidote), 4 material, 1 quest item.
  Full stats, rarity, element, level/class requirements.
- Remote model: `Inventory/GetInventory`, `Inventory/Equip`, `Inventory/Unequip`,
  `Inventory/UseItem`.

---

## [2026-08-06] CombatService + DamageFormula — tested ✅
### Ditambahkan
- `CombatService/init.lua` (ServerScriptService/Services): server-authoritative
  combat. API: `ProcessAttack`, `SpawnEnemy`, `ResetEnemy`, `GetAvailableSkills`,
  `GetEnemyStatus`. Server-side enemy state, cooldown tracking, mana system.
  Remote `Combat/RequestAttack`, `Combat/GetSkills`.
- `DamageFormula.lua` (ReplicatedStorage/Shared): pure function damage calc.
  STR/INT scaling (1.5x), element multiplier (1.5x strong/0.5x weak),
  defense reduction (`100/(100+def)`), crit rate from LUK (5% + 0.5%/LUK, cap 50%).
- `Skills.lua`: 21 skill definitions (Warrior/Knight/Warlord, Assassin/Shadowblade/
  Nightstalker, Mage/Elementalist/Archmage, Healer/Priest/HighPriest, Archer/Ranger/
  Deadeye, Defender/Guardian/Sentinel). DamageType Physical/Magical, Target Single/AoE.
- `Enemies.lua`: 12 enemy definitions (Millhaven Lv1-8, Duskwood Lv12-40, Frostpeak
  Lv28-40). Stats, defense, element, exp/currency rewards.
- Remote model: `Combat/RequestAttack`, `Combat/GetSkills`.

---

## [2026-08-06] QuestService — tested ✅
### Ditambahkan
- `QuestService/init.lua` (ServerScriptService/Services): server-authoritative
  quest system. API: `AcceptQuest`, `ReportProgress` (server-side only, anti-cheat),
  `CompleteQuest`, `GetQuestLog`, `GetAvailableQuests`. Remote `Quest/Accept`,
  `Quest/Complete`, `Quest/GetLog` (masing-masing rate-limited).
- `Configs/Quests.lua`: 20 quest definitions — Main (Millhaven intro, wolf, herbs),
  Gate unlock (Duskwood, Frostpeak), Job change (6x Tier2, 6x Tier3), Daily
  repeatable (wolf hunt, herb run). Objective types: Kill, Collect, Talk, Explore.
- Remote model: `Quest/GetLog`, `Quest/Accept`, `Quest/Complete`.

---

## [2026-08-06] JobChangeService — tested ✅
### Ditambahkan
- `JobChangeService/init.lua` (ServerScriptService/Services): server-authoritative
  job change. API: `TryJobChange(player)`. Cek: ClassId ada, bukan Tier 3,
  Level >= requiredLevel, CompletedQuests[requiredQuestId]. Update ClassId +
  ClassTier. Remote `Character/JobChange` (rate-limited 2s).
- `ClassTier` field di ProfileTemplate (1/2/3).
- Remote model: `Character/JobChange`.

---

## [2026-08-06] Gate/Portal system — tested ✅
### Ditambahkan
- `GateService.lua` (ServerScriptService/Services): server-authoritative gate
  system. API: `TryOpenGate`, `GetUnlockedGates`, `IsGateUnlocked`. Remote
  `Gate/RequestOpen` (rate-limited 1s). Validasi: Level, Quest (CompletedQuests),
  Item (Inventory), LevelAndQuest. Unlock disimpan di `profile.UnlockedGates`.
- `GatePortalBuilder.server.lua`: spawn 3D portal di workspace (20-segment
  glowing ring, inner surface, particles, PointLight, ProximityPrompt, BillboardGui
  label). Juga buat zone spawn points.
- `GateController.lua` (StarterPlayerScripts/Controllers): detect ProximityPrompt,
  tampilkan UI confirm, handle request open + teleport.
- `GateConfirm/init.lua` (StarterGui/UI): overlay + card konfirmasi (gate name,
  destination, requirements, confirm/cancel buttons).
- `CompletedQuests` field di ProfileTemplate (dipakai GateService).
- Remote model: `Gate/RequestOpen`, `Gate/GateOpened`.
### Diperbaiki
- Gate model.json: hapus `Name` field (Rojo 6.0 warning).
- GatePortalBuilder ditambahkan ke `default.project.json`.

---

## [2026-08-06] CharacterCreation UI — tested ✅
### Ditambahkan
- `CharacterCreation/init.lua` (StarterGui/UI): full race reveal + class select
  UI dengan tema Portal/Arcadia. Animasi orb, rarity tag, stat pills, class
  grid cards.
- `CharacterCreationController.lua` (StarterPlayerScripts/Controllers):
  client-side controller yang menghubungkan UI ke server remotes.
### Diperbaiki
- `Enum.Font.Cinzel` → `Enum.Font.GothamBlack` (font tidak ada di Roblox).
- `newLabel` Position/AnchorPoint nil crash → guard with if-check.
- UI scale ~30% lebih kecil untuk Studio viewport.
- `DataService.ResetToTemplate` — test cleanup reset profile ke fresh state
  supaya `Release()` simpan data bersih.
- Controller: pcall wrapper untuk semua `InvokeServer` calls.

---

## [2026-08-06] LevelService + AllocateCP — tested ✅
### Ditambahkan
- `LevelService.AllocateCP(player, statName)` direct API method — bisa
  dipanggil dari server script (test, admin) tanpa remote.
- `CharacterService` direct API: `RerollRace`, `ConfirmRace`,
  `SelectClass` — server-only callable.
- `TestLevelCurve.server.lua` v4: 29/29 test lulus (Play Solo otomatis).
### Diubah
- `CharacterService/init.lua`: refactored — remote handlers wrap direct
  API methods, bukan inline logic.
- `LevelService/init.lua`: extract `AllocateCP` dari inline
  `OnServerInvoke` jadi standalone method.
### Diperbaiki
- Test script sekarang handle player yang sudah Lv50 (max level cap).
- EXP comparison di test: simpan `oldExp` sebelum mutate.

---

## [2026-08-06] LevelCurve + LevelService (leveling, EXP, Combat Points)
### Ditambahkan
- `LevelCurve.lua` (`ReplicatedStorage/Configs/`): config EXP progression
  — formula kuadratik `base + level^2 * factor`, MaxLevel 50, base stat
  +2 per level ke semua stat, 3 Combat Points per level-up. Helper
  functions: `GetRequiredExp(lv)`, `GetTotalExpToLevel(lv)`,
  `GetBaseStats(lv)`, `GetCombatPointsGain(lv)`, `GetLevelFromTotalExp(exp)`.
- `LevelService.lua` (`ServerScriptService/Services/LevelService/`):
  service leveling & EXP — server-only API `AddExp(player, amount)` untuk
  Service lain (CombatService, QuestService, dst.), proses level-up
  otomatis (multiple level sekaligus jika EXP cukup), recalculate base
  stats otomatis, award Combat Points. Remote `Level/AllocateCP`
  (RemoteFunction, client→server): alokasi 1 CP ke stat pilihan
  (validasi statName, cek UnspentCombatPoints > 0, 0.2s debounce).
  Remote `Level/LevelUp` (RemoteEvent, server→client): notifikasi
  level-up ke client (newLevel, combatPointsGained, baseStats).
  Helper: `GetLevel`, `GetRequiredExpForNextLevel`, `GetProgressPercent`,
  `GetUnspentPoints`.
- Remote model `.model.json` untuk 2 remote Level: `LevelUp` (Event),
  `AllocateCP` (Function).
### Diubah
- `Main.server.lua`: tambah LevelService ke service registry (urutan:
  DataService → CharacterService → LevelService).
- `docs/02_TDD.md` §5: tambah 2 baris remote Level ke tabel Remote.
### Catatan Teknis / Risiko
- **Belum dites manual di Roblox Studio** — wajib Play Solo: test AddExp
  (gain EXP → level-up → CP naik → base stat naik), test multiple
  level-up dalam satu AddExp call, test AllocateCP (sukses, stat tidak
  valid, CP habis, spam), test notifikasi LevelUp ke client.
- Base stat recalculation di `processLevelUps`: saat level-up, base stat
  lama dikurangi dan base baru ditambahkan — ini mempertahankan ras bonus
  & CP-allocated points yang sudah ada. Asumsi: ras bonus & CP points
  tidak berubah saat level-up (benar — hanya base yang naik). Kalau ada
  sistem reset stat di masa depan, perlu review logic ini.
- `AddExp` bisa dipanggil Service lain tanpa remote — ini sengaja
  (server-only API), client tidak bisa inject EXP. Tapi kalau ada bug
  di CombatService/QuestService yang memanggil AddExp dengan amount salah,
  EXP bisa naik tak terduga — semua Service pemanggil wajib validasi
  amount sebelum panggil.
- Level cap 50: kalau pemain sudah MaxLevel, `AddExp` tetap menambah
  `data.Exp` (overflow EXP tercatat) tapi level tidak naik. Design
  decision: EXP overflow tidak di-reset, bisa dipakai nanti untuk
  prestige/sistem pasca-cap.
- AllocateCP tidak ada cost selain UnspentCombatPoints — tidak ada
  batasan waktu/level untuk alokasi. Bisa ditambah nanti kalau ada
  mekanik "reset stat" berbayar (GDD §17 monetisasi).

## [2026-08-06] Service/Controller pattern, RemoteValidator, CharacterService
### Ditambahkan
- `BaseService.lua` (`ServerScriptService/Services/`): pola dasar Service
  server — `Extend(name)`, lifecycle `Init()`/`Start()` dengan flag guard
  (tidak bisa dipanggil dua kali), registry global `RegisterService()`/
  `BindRegistry()`, lazy cross-reference `GetService(name)`. Semua Service
  baru wajib mewarisi dari modul ini.
- `BaseController.lua` (`StarterPlayerScripts/Controllers/`): mirror
  client-side BaseService — lifecycle Init/Start, registry `RegisterController()`
  /`BindRegistry()`, lazy `GetController(name)`.
- `RemoteValidator.lua` (`ReplicatedStorage/Shared/`): util validasi argumen
  remote generik — type check (`typeof`), string length (min/max), number
  range (min/max/integer), table maxEntries, rate limit per-player (debounce
  clock), `Validate(player, rules)` → `true|false, error`, `WrapHandler(fn)`
  → pcall wrapper anti-stacktrace-leak, `CleanupPlayer(player)`.
- `CharacterService.lua` (`ServerScriptService/Services/CharacterService/`):
  service pembuatan karakter — 4 RemoteFunction:
  - `RerollRace`: RNG berbobot server-side (weight dari `Configs/Races.lua`),
    0.5s debounce, hanya bisa dipanggil jika `RaceId == nil`.
  - `ConfirmRace`: validasi `raceId` di Config, terapkan stat bonus ras
    langsung ke `data.Stats`, idempotensi (tidak bisa re-pilih).
  - `SelectClass`: validasi `classId` di Config + `tier == 1`, syarat
    sudah punya `RaceId`, idempotensi.
  - `CreationStatus`: kirim `{ hasRace, hasClass }`, 1s debounce.
- Remote model `.model.json` untuk 4 remote Character:
  `RerollRace`, `ConfirmRace`, `SelectClass`, `CreationStatus`.
- `MainController.client.lua` (`StarterPlayerScripts/`): bootstrap
  client-side 3-phase (Register → Init → Start) dengan BaseController.
  Untuk saat ini belum ada Controller aktif (placeholder).
- Entry `MainController` di `default.project.json` (StarterPlayerScripts).
### Diubah
- `DataService/init.lua`: refactor extends `BaseService` — lifecycle
  dipecah `Init()` (flag only) dan `Start()` (connect events, BindToClose,
  RemoteHandlers). Behavior tidak berubah, hanya pola yang diterapkan.
- `DataService/RemoteHandlers.lua`: refactor pakai `RemoteValidator.new()`
  + `WrapHandler()` mengganti implementasi rate-limit sendiri — behavior
  identik (same debounce value dari `DataConstants`), hanya kode yang lebih
  konsisten.
- `Main.server.lua`: refactor dari `DataService.Init()` manual ke pola
  3-phase BaseService (Register → Init → Start), mendaftarkan
  DataService + CharacterService.
- `docs/02_TDD.md` §5: tambah 4 baris remote Character ke tabel Remote
  Events/Functions.
### Catatan Teknis / Risiko
- **Semua sistem baru belum dites manual di Roblox Studio** — AI tidak
  punya akses runtime. Wajib Play Solo sebelum menandai ✅ (lihat skenario
  uji di `05_PROGRESS_TRACKER.md` session log).
- `BaseService`/`BaseController` dan `RemoteValidator` baru terbukti secara
  kode (pattern diterapkan konsisten, tidak ada syntax error obvious),
  belum terbukti di runtime.
- Refactor DataService ke BaseService mengubah cara Init dipanggil
  (dari `DataService.Init()` ke `DataService:Init()` via BaseService)
  — perlu verifikasi di Studio.
- `Character/ConfirmRace`: stat bonus ras dijumlahkan langsung ke
  `data.Stats[stat]` — kalau ada operasi yang me-reset/mengganti Stats
  (bukan update), bonus bisa hilang. Saat ini tidak ada risiko karena
  tidak ada operasi lain yang me-reset Stats.
- `Character/RerollRace`: unlimited reroll (tanpa cost) — bisa ditambah
  nanti untuk mekanik monetisasi (GDD §17). Hanya rate limit 0.5s.

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
