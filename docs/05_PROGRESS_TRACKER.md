# PROGRESS TRACKER
> Dokumen ini WAJIB dibaca di awal setiap sesi dan diupdate di akhir setiap sesi.
> Legend status: ⬜ Belum mulai · 🔄 Sedang dikerjakan · ✅ Selesai · 🚫 Diblokir/butuh keputusan

## 1. Status Sistem

### Fondasi Teknis
| Sistem | Status | Catatan |
|---|---|---|
| Struktur project Rojo | ✅ | Skeleton folder + `default.project.json` + Config terisi. Bootstrap 3-phase BaseService/Main. Tested di Studio. |
| DataStore / Profile system | ✅ | ProfileStore session-locked + DataService + migrasi v1→v2 + remote `Data/GetProfile`. Tested di Studio (join normal, session lock, leave, shutdown). |
| Service/Controller pattern dasar | ✅ | `BaseService.lua` + `BaseController.lua` + lifecycle (Init/Start) + registry inter-service. DataService extends BaseService. Tested di Studio. |
| Remote validation framework dasar | ✅ | `RemoteValidator.lua` (Shared) — type check, range check, rate limit, WrapHandler. Tested di Studio via DataService & CharacterService. |

### Karakter & Progression
| Sistem | Status | Catatan |
|---|---|---|
| Desain Ras final (5 ras) | ✅ | Data di `Configs/Races.lua`. Lihat `01_GDD.md` §8.1 |
| Desain Kelas combat final (6 jalur, Tier 1–3) | ✅ | Data di `Configs/Classes.lua`. Lihat `01_GDD.md` §8.2 (5 jalur awal + **Assassin→Shadowblade→Nightstalker**) |
| Desain Profesi non-combat final (Craftsman) | ✅ | Data di `Configs/Professions.lua`. Lihat `01_GDD.md` §8.4. Terpisah dari Job Tier combat |
| Character creation (pilih Ras) — implementasi | ✅ | `CharacterService` + remotes `RerollRace`/`ConfirmRace`/`CreationStatus`. RNG berbobot di server. Stat bonus ras diterapkan ke profile saat konfirmasi. Tested di Studio. |
| Character creation (pilih Kelas) — implementasi | ✅ | Remote `SelectClass` di `CharacterCreationService`. Validasi Tier 1 only. Tested di Studio. UI CharacterCreation (race reveal + class select) tested — Evil/Assassin flow sukses. |
| Sistem stat & Combat Points — implementasi | ✅ | `LevelService.AllocateCP` (direct API + remote). Tested: alokasi CP sukses, invalid stat ditolak, CP berkurang. |
| Leveling / EXP curve | ✅ | `LevelCurve.lua` + `LevelService`. Tested: EXP required, base stats, CP gain, level-up otomatis, max level cap, `AllocateCP`. Semua 29 test lulus. |
| Job change — implementasi | ✅ | `JobChangeService.lua`: TryJobChange, validasi level+quest, ClassTier tracking. Remote `Character/JobChange`. Tested: no class→tolak, questbelum→tolak, Warrior→Knight→Warlord, tier max→tolak (72/72). |

### Gameplay Inti
| Sistem | Status | Catatan |
|---|---|---|
| Desain Element Chart final | ✅ | Data di `Configs/Elements.lua`. Lihat `01_GDD.md` §9 |
| Sistem elemen — implementasi combat | ⬜ | Data sudah siap, logic Service belum |
| Sistem combat dasar (attack + skill) | ⬜ | |
| Desain Zona & Gate final (Millhaven → Shattered Sanctum) | ✅ | Lihat `01_GDD.md` §6, data gate di `Configs/Gates.lua` |
| Gate/Portal system — implementasi | ✅ | `GateService.lua` (server): validasi syarat Level/Quest/Item, unlock gate, simpan ke `UnlockedGates`. Remote `Gate/RequestOpen` (rate-limited 1s). Tested: fake gate ditolak, LevelAndQuest (level OK + quest), idempotent unlock, Frostpeak ditolak (no quest). 3D portal builder + GateUI confirm + GateController. |
| Zona 1 (Millhaven) — build/implementasi | ⬜ | |
| Dungeon instance pertama (The Sunken Crypt) | ⬜ | |
| Quest system (main quest) | ⬜ | `Configs/Quests.lua` masih skeleton kosong; id quest job-change/gate sudah direferensikan di Classes.lua & Gates.lua sebagai placeholder |

### Sosial & Ekonomi
| Sistem | Status | Catatan |
|---|---|---|
| Party system | ⬜ | |
| Shop / currency | ⬜ | |
| Inventory & equipment | ⬜ | |

### Lanjutan
| Sistem | Status | Catatan |
|---|---|---|
| PvP arena | ⬜ | |
| Guild/Clan | ⬜ | |
| Monetisasi (gamepass, dsb.) | ⬜ | |

_(Tambahkan baris baru bila ada sistem baru yang mulai dikerjakan — jangan hapus baris sistem lama meskipun belum dikerjakan.)_

## 2. Session Log
_(Entri terbaru di paling atas. Format lihat `04_AI_AGENT_RULES.md` §3.)_

### [2026-08-06] Test fresh reset v5 — Character Creation + LevelService (49/49 ✅)
- Dikerjakan: test full flow dari fresh state (Lv1, Race=nil, Class=nil).
  - Reset profile ke fresh state sebelum test.
  - BAGIAN 2: 13 test character creation — SelectClass ditolak tanpa Race,
    RerollRace, ConfirmRace (valid/invalid/idempotent), stat bonus Human
    (STR 5→7), SelectClass (valid/Tier2 invalid/idempotent), CreationStatus.
  - BAGIAN 3: 12 test LevelService — AddExp kecil (belum level-up), level
    1→2 (STR naik), multiple level-up ke Lv42, AllocateCP valid/invalid.
  - Total: 24 config + 13 creation + 12 level = 49 passed, 0 failed.
- Fix: `Enum.Font.Cinzel` → `Enum.Font.GothamBlack` di CharacterCreation UI.
- File yang disentuh:
  `src/ServerScriptService/Tests/TestLevelCurve.server.lua` (v5),
  `src/StarterGui/UI/CharacterCreation/init.lua` (font fix).

### [2026-08-06] LevelService + AllocateCP — tested ✅
- Dikerjakan: implementasi & testing LevelService dan Combat Points allocation.
  - `LevelService.lua`: extends BaseService. API: `AddExp(player, amount)`,
    `AllocateCP(player, statName)`, `GetLevel()`, `GetRequiredExpForNextLevel()`,
    `GetProgressPercent()`, `GetUnspentPoints()`. Auto level-up, base stat
    recalculation, CP gain per level, LevelUp notification ke client.
  - `CharacterService.lua`: refactor — extract direct API methods
    (`RerollRace`, `ConfirmRace`, `SelectClass`) supaya bisa dipanggil
    dari server test tanpa RemoteFunction.
  - `TestLevelCurve.server.lua` v4: full auto test (Play Solo, no Command Bar).
    29/29 lulus: LevelCurve config, EXP formula, base stats, CP gain,
    max level cap, AllocateCP valid/invalid, EXP overflow.
- File yang disentuh:
  `src/ServerScriptService/Services/LevelService/init.lua` (AllocateCP as direct API),
  `src/ServerScriptService/Services/CharacterService/init.lua` (API refactor),
  `src/ServerScriptService/Tests/TestLevelCurve.server.lua` (v4),
  `docs/05_PROGRESS_TRACKER.md`, `docs/07_CHANGELOG.md`.

### [2026-08-06] Service/Controller pattern + RemoteValidator + CharacterService
- Dikerjakan: implementasi infrastruktur dasar arsitektur Service/Controller
  dan validasi remote, sekaligus implementasi Character Creation Service.
  - `BaseService.lua` (`ServerScriptService/Services/`): pola dasar Service
    server — `Extend()`, lifecycle `Init()`/`Start()`, registry global
    `RegisterService()`/`BindRegistry()`, lazy cross-reference
    `GetService()`. Semua Service baru wajib mewarisi dari modul ini.
  - `BaseController.lua` (`StarterPlayerScripts/Controllers/`): mirror
    client-side BaseService — lifecycle Init/Start, registry, `GetController()`.
  - `RemoteValidator.lua` (`ReplicatedStorage/Shared/`): util validasi
    argumen remote generik — type check, string length, number range,
    integer check, table maxEntries, rate limit per-player (debounce),
    `WrapHandler()` anti-stacktrace-leak (pcall + warn di server,
    `{ error = "..." }` aman ke client). Dipakai oleh semua RemoteHandlers.
  - `CharacterService.lua` (`ServerScriptService/Services/CharacterService/`):
    service pembuatan karakter — 4 RemoteFunction:
    `RerollRace` (RNG berbobot server-side, 0.5s debounce),
    `ConfirmRace` (validasi raceId di Config + terapkan stat bonus ras),
    `SelectClass` (validasi classId di Config + tier == 1),
    `CreationStatus` (cek status RaceId/ClassId). Player tidak bisa
    mengubah Ras/Kelas setelah dikonfirmasi (idempotensi).
  - Refactor `DataService/init.lua`: extends `BaseService`, lifecycle
    `Init()` (flag only) → `Start()` (connect events + BindToClose +
    RemoteHandlers).
  - Refactor `DataService/RemoteHandlers.lua`: pakai `RemoteValidator`
    mengganti implementasi rate-limit sendiri.
  - `Main.server.lua`: bootstrap 3-phase (Register → Init → Start)
    dengan BaseService, mendaftarkan DataService + CharacterService.
  - `MainController.client.lua`: bootstrap mirror client-side dengan
    BaseController (Register → Init → Start), untuk saat ini belum ada
    Controller aktif.
  - Remote model `.model.json` baru untuk 4 remote Character
    (`RerollRace`, `ConfirmRace`, `SelectClass`, `CreationStatus`).
  - `default.project.json`: tambah entry `MainController` di
    StarterPlayerScripts.
- File yang disentuh:
  `docs/02_TDD.md` (§5 tambah 4 baris remote Character),
  `src/ReplicatedStorage/Shared/RemoteValidator.lua` (baru),
  `src/ServerScriptService/Services/BaseService.lua` (baru),
  `src/ServerScriptService/Services/DataService/init.lua` (refactor
    extends BaseService, Init→Start split),
  `src/ServerScriptService/Services/DataService/RemoteHandlers.lua`
    (refactor pakai RemoteValidator),
  `src/ServerScriptService/Services/CharacterService/init.lua` (baru),
  `src/ServerScriptService/Main.server.lua` (refactor 3-phase +
    daftar CharacterService),
  `src/ReplicatedStorage/Remotes/Character/*.model.json` (4 file baru),
  `src/StarterPlayerScripts/Controllers/BaseController.lua` (baru),
  `src/StarterPlayerScripts/MainController.client.lua` (baru),
  `default.project.json` (tambah MainController entry).
- Status sistem yang berubah:
  - Service/Controller pattern dasar ⬜→🔄
  - Remote validation framework dasar ⬜→🔄
  - Character creation (pilih Ras) ⬜→🔄
  - Character creation (pilih Kelas) ⬜→🔄
  - DataStore / Profile system tetap 🔄 (refactor ke BaseService,
    tidak mengubah behavior — RemoteHandlers sekarang pakai RemoteValidator
    tapi logic rate-limit & deep-copy identik).
- Diketahui belum selesai / next step:
  - **Semua sistem baru belum diuji manual di Roblox Studio** (AI tidak
    punya akses runtime). Wajib Play Solo sebelum ditandai ✅: test
    bootstrap Init/Start order, test RerollRace RNG distribution,
    test ConfirmRace stat bonus, test SelectClass validation,
    test idempotensi (tidak bisa re-pilih setelah confirm), test
    CreationStatus, test anti-exploit (kirim argumen tipe salah,
    classId Tier 2, raceId tidak ada di Config).
  - `BaseService`/`BaseController` belum ✅ karena belum terbukti di
    runtime Studio — baru terbukti secara kode (pattern diterapkan
    konsisten ke DataService, tidak ada syntax error obvious).
  - `RemoteValidator` belum ✅ karena belum terbukti live — rate limit
    & error wrapping baru diverifikasi secara kode.
  - **LevelCurve.lua** masih skeleton — belum ada formula EXP per level
    (syarat sebelum leveling/combat bisa jalan).
  - `CharacterController` (client-side UI) belum diimplementasikan —
    saat ini hanya ada infrastruktur server. UI character creation
    (tombol Reroll, daftar ras, daftar kelas) perlu diimplementasikan
    terpisah di StarterPlayerScripts/StarterGui.
  - Refactor DataService ke BaseService mengubah cara Init dipanggil
    (dari `DataService.Init()` ke `DataService:Init()` via BaseService)
    — perlu verifikasi di Studio bahwa tidak ada side effect.
- Catatan risiko/exploit yang perlu direview manusia:
  - `Character/ConfirmRace`: stat bonus ras dijumlahkan langsung ke
    `data.Stats[stat]` — kalau ada migrasi yang me-reset Stats atau
    field Stats di-replace (bukan di-update), bonus bisa hilang.
    Saat ini tidak ada risiko karena tidak ada operasi lain yang
    me-reset Stats, tapi perlu diingat kalau ada sistem reset stat
    di kemudian hari.
  - `Character/SelectClass`: tidak ada validation `RaceId` dipilih
    sebelum `ClassId` (hanya cek `RaceId ~= nil`) — ini sengaja
    karena Ras dan Kelas bebas dikombinasikan (GDD §8.1: "Kombinasi
    Ras × Kelas bebas dipilih pemain").
  - `Character/RerollRace`: unlimited reroll untuk saat ini (tidak ada
    cost currency/reroll token) — bisa ditambah nanti kalau ada
    mekanik monetisasi reroll (GDD §17). Tidak ada batasan jumlah
    reroll per session, hanya rate limit 0.5s antar panggilan.
  - Race stat bonus: Angel (-3 STR) dan Evil (-4 LUK, -2 AGI) bisa
    membuat stat di bawah 0 kalau base stat sangat rendah. Saat ini
    base stat = 5 (ProfileTemplate), jadi minimum Angel STR = 2,
    Evil LUK = 1, Evil AGI = 3 — masih positif, tapi perlu
    dipertimbangkan kalau ada sistem yang mengurangi stat lebih jauh.

### [2026-08-06] LevelCurve + LevelService
- Dikerjakan: implementasi config EXP progression dan service leveling.
  - `LevelCurve.lua`: formula EXP kuadratik (base + level² × 2), MaxLevel
    50, base stat +2/level, 3 CP/level. 5 helper functions: GetRequiredExp,
    GetTotalExpToLevel, GetBaseStats, GetCombatPointsGain,
    GetLevelFromTotalExp.
  - `LevelService.lua`: service leveling — API server-only `AddExp(player,
    amount)` dengan proses level-up otomatis (support multiple level dalam
    satu call), base stat recalculate via LevelCurve.GetBaseStats(), CP
    award. Remote `Level/AllocateCP` (validasi statName, cek CP > 0, 0.2s
    debounce). Remote `Level/LevelUp` (server→client notification).
    Helper: GetLevel, GetRequiredExpForNextLevel, GetProgressPercent,
    GetUnspentPoints.
  - Remote model `.model.json` untuk 2 remote Level: LevelUp (Event),
    AllocateCP (Function).
  - Main.server.lua: tambah LevelService ke registry.
  - docs/02_TDD.md §5: tambah 2 baris remote Level.
- Status sistem yang berubah:
  - Leveling / EXP curve ⬜→🔄 (config diisi + Service diimplementasi)
  - Sistem stat & Combat Points ⬜→🔄 (AllocateCP + base stat recalculate)
- Diketahui belum selesai / next step: belum dites manual di Studio.
  Job change, combat, quest, gate masih ⬜ (tidak diubah sesi ini).
- Catatan risiko/exploit: AddExp hanya server-side API (aman). AllocateCP
  divalidasi (statName, CP > 0, character creation selesai). Base stat
  recalculation mempertahankan ras bonus & CP points (asumsi tidak ada
  yang me-reset Stats saat level-up).

### [2026-08-06] Implementasi DataStore / Profile system
- Dikerjakan: implementasi penuh sistem penyimpanan data pemain sesuai
  `02_TDD.md` §6 & `03_DDD.md` §4-5.
  - `ServerStorage/Private/ProfileStore.lua`: engine DataStore session-locked
    buatan sendiri (pure Luau, tanpa dependency eksternal — lihat
    `02_TDD.md` §11 untuk alasan keputusan ini) dengan auto-retry+backoff,
    autosave berkala, save saat player leave & `game:BindToClose`.
  - `ReplicatedStorage/Configs/ProfileTemplate.lua`: skema default profil
    baru, SchemaVersion 2 (sudah termasuk `ProfessionId`/`ProfessionExp`).
  - `ServerScriptService/Services/DataService/` (Service utama +
    `ProfileMigrations/` + `RemoteHandlers.lua`): satu-satunya titik akses
    resmi data pemain (`DataService.GetProfile`/`WaitForProfile`/`IsLoaded`),
    menjalankan migrasi resmi v1→v2 (`ProfessionId`/`ProfessionExp`) sesuai
    `03_DDD.md` §5 poin 0, plus jaring pengaman `TableUtil.ReconcileDefaults`.
  - Remote `Data/GetProfile` (RemoteFunction, sudah ada di tabel `02_TDD.md`
    §5 sebelumnya) diimplementasikan: rate-limited per player, hanya kirim
    data milik pemain sendiri, deep copy sebelum dikirim ke client.
  - `ReplicatedStorage/Shared/TableUtil.lua` (util baru, dipakai luas):
    `DeepCopy` & `ReconcileDefaults`.
  - `ServerScriptService/Main.server.lua` (bootstrap baru) + `Main` entry
    baru di `default.project.json` untuk memanggil `DataService.Init()`.
- File yang disentuh: `docs/02_TDD.md` (§5 update baris remote, §11 catat
  keputusan arsitektur), `docs/03_DDD.md` (§5 resolusi migrasi, catatan
  implementasi & asumsi RaceId/ClassId default nil), `default.project.json`,
  `src/ReplicatedStorage/Shared/{TableUtil,DataConstants}.lua`,
  `src/ReplicatedStorage/Configs/ProfileTemplate.lua`,
  `src/ReplicatedStorage/Remotes/Data/GetProfile.model.json`,
  `src/ServerStorage/Private/ProfileStore.lua`,
  `src/ServerScriptService/Services/DataService/**`,
  `src/ServerScriptService/Main.server.lua`.
- Status sistem yang berubah: "DataStore / Profile system" ⬜→🔄 (kode
  selesai, belum ✅ — lihat catatan di tabel status di atas).
- Diketahui belum selesai / next step: **belum diuji manual di Roblox
  Studio sama sekali** (AI tidak punya akses runtime Roblox) — wajib
  Play Solo/Team Test sebelum ditandai ✅, termasuk skenario: join normal,
  dua sesi/server rebut profil yang sama (cek session lock benar-benar
  menolak), player leave cepat sebelum load selesai, server shutdown
  (`BindToClose`) benar-benar menyimpan. Asumsi `RaceId`/`ClassId` default
  `nil` (bukan `"Human"`/`"Warrior"`) perlu dikonfirmasi pemilik project —
  lihat `03_DDD.md` §4 catatan implementasi. `Service/Controller pattern
  dasar` & `Remote validation framework dasar` masih ⬜ terpisah — DataService
  baru mengimplementasikan pola untuk dirinya sendiri, belum ada
  util/base-class Service generik untuk sistem lain.
- Catatan risiko/exploit yang perlu direview manusia: remote `Data/GetProfile`
  sudah lolos checklist dasar (`06_CODING_STANDARDS.md` §3: tipe/rate-limit/
  filter data), tapi **belum pernah dites live** — perlu verifikasi manual
  bahwa rate-limit & deep-copy benar-benar berfungsi di Studio. Session-lock
  di `ProfileStore.lua` punya limitasi: tidak ada MessagingService
  cross-server "release segera", server lain menunggu
  `SessionLockTimeoutSeconds` (30 detik) sebelum boleh mencuri lock dari
  server yang crash — didokumentasikan di header `ProfileStore.lua`, cukup
  untuk MVP single-place tapi perlu direview ulang saat Reserved
  Server/dungeon instance mulai dipakai.

### [2026-08-06] Skema aset visual (meshId/textureId/iconId) di Items.lua
- Dikerjakan: menambah konvensi field aset visual 3D/2D untuk item
  (`meshId`, `textureId`, `iconId`, format `rbxassetid://...`, placeholder
  wajib `"rbxassetid://0"`) di `docs/03_DDD.md` §3 (contoh entry + §3.1
  penjelasan konvensi) dan header dokumentasi `Configs/Items.lua`. Tidak
  menambah item aktual (`Items.lua` masih skeleton kosong, belum ada
  desain item final) — murni menyiapkan tempat field-nya agar tidak perlu
  ubah struktur data lagi begitu aset 3D (dari Roblox Studio Cube/Meshy/
  Sloyd/artist — dibahas terpisah dengan pemilik project) sudah tersedia.
- File yang disentuh: `docs/03_DDD.md`, `src/ReplicatedStorage/Configs/Items.lua`
- Status sistem yang berubah: tidak ada baris status yang berubah (item
  masih ⬜, ini murni persiapan skema, belum "desain item final")
- Diketahui belum selesai / next step: item aktual (weapon/armor/material)
  belum didesain sama sekali di `01_GDD.md` — perlu sesi desain terpisah
  sebelum `Items.lua` diisi. Field visual sama (`meshId` dkk.) kemungkinan
  perlu direplikasi ke `Enemies.lua` nanti untuk model musuh — belum
  dikerjakan, tunggu diminta eksplisit.
- Catatan risiko/exploit yang perlu direview manusia: tidak ada (murni
  dokumentasi skema, belum ada data/logic baru).

### [2026-08-06] Tambah jalur Kelas Assassin & profesi non-combat Craftsman
- Dikerjakan: menambah **Assassin** sebagai jalur ke-6 Kelas combat
  (Melee Physical DPS varian stealth/crit, Dagger/Dual Blade, chain
  Assassin→Shadowblade→Nightstalker) di `01_GDD.md` §8.2 & `Classes.lua` —
  bersifat aditif (jalur Warrior/Knight/Warlord dkk tidak diubah). Menambah
  **Craftsman** sebagai profesi non-combat baru (§8.4, config module baru
  `Configs/Professions.lua`), terpisah dari sistem Job Tier combat, dengan 3
  rank (Apprentice/Journeyman/Master) & progression EXP sendiri. Player
  Profile schema (`03_DDD.md` §4) ditambah field `ProfessionId`/
  `ProfessionExp` (belum berlaku sampai Profile system diimplementasi &
  lewat migrasi resmi, lihat `03_DDD.md` §5 poin 0). Perubahan ini
  dikonfirmasi eksplisit oleh pemilik project sebagai bagian dari desain
  final sekarang (bukan penambahan pasca-MVP terpisah), meski §8.2/Crafting
  sebelumnya berstatus "Selesai" — sesuai `04_AI_AGENT_RULES.md` §1.3.
- File yang disentuh: `docs/01_GDD.md`, `docs/03_DDD.md`,
  `src/ReplicatedStorage/Configs/Classes.lua`,
  `src/ReplicatedStorage/Configs/Professions.lua` (baru)
- Status sistem yang berubah: "Desain Kelas final (5 jalur)" diganti jadi
  "Desain Kelas combat final (6 jalur)" ✅ (tetap Selesai, isi bertambah);
  baris baru "Desain Profesi non-combat final (Craftsman)" ⬜→✅
- Diketahui belum selesai / next step: `Q_JobChange_Shadowblade` &
  `Q_JobChange_Nightstalker` baru placeholder id (belum ada isi quest-nya,
  sama seperti quest job-change kelas lain — lihat `Configs/Quests.lua`
  yang masih skeleton). Resep Craftsman & item bertipe `"Material"` di
  `Items.lua` belum didesain (`Professions.lua` recipe section masih
  kosong). Skill Assassin & implementasi Service apapun untuk Craftsman
  belum ada.
- Catatan risiko/exploit yang perlu direview manusia: tidak ada (masih data
  desain murni, belum ada logic Service yang berjalan).

### [2026-08-06] Finalisasi desain MVP: Ras, Kelas/Job Tier, Elemen, Zona/Gate
- Dikerjakan: mengisi bagian yang tadinya placeholder di `01_GDD.md` (§5 Lore,
  §6 Zona, §8.1 Ras, §8.2 Kelas, §9 Elemen, §19 Roadmap) dengan keputusan
  desain final MVP sesuai arahan pemilik project (5 Ras: Human/Elf/Dwarf/
  Angel/Evil; 5 jalur Kelas linear Tier 1-3; 6 elemen dengan chart siklus
  4-elemen + Light/Dark saling counter; 5 zona/gate: Millhaven, Duskwood
  Forest, Frostpeak Mountains, The Sunken Crypt, The Shattered Sanctum).
  Data diturunkan langsung ke `Configs/Races.lua`, `Configs/Classes.lua`,
  `Configs/Elements.lua`, `Configs/Gates.lua`.
- File yang disentuh: `docs/01_GDD.md`, `src/ReplicatedStorage/Configs/
  {Races,Classes,Elements,Gates}.lua`
- Status sistem yang berubah: Desain Ras/Kelas/Elemen/Zona ⬜→✅ (desain),
  implementasi teknis semua sistem terkait masih ⬜ (belum ada logic Service)
- Diketahui belum selesai / next step: `Skills.lua`, `Items.lua`,
  `Enemies.lua`, `Quests.lua`, `LevelCurve.lua` masih skeleton kosong —
  quest id (job change, buka gate) baru placeholder, isi kontennya belum
  didesain. Belum ada satu Service/Controller pun yang berlogic.
- Catatan risiko/exploit yang perlu direview manusia: tidak ada (masih data
  desain murni, belum ada logic yang berjalan).

### [2026-08-06] Scaffolding struktur Rojo
- Dikerjakan: buat `default.project.json` (manifest Rojo), skeleton folder
  `src/ReplicatedStorage/{Shared,Configs,Remotes}`,
  `src/ServerScriptService/Services`, `src/ServerStorage/Private`,
  `src/StarterPlayerScripts/Controllers`, `src/StarterGui/UI`. Tiap folder
  diberi README penjelasan tanggung jawabnya. Modul Config
  (Races/Classes/Elements/Skills/Items/Enemies/Quests/Gates/LevelCurve.lua)
  dibuat sebagai skeleton table kosong sesuai skema di `03_DDD.md`.
- File yang disentuh: `default.project.json`, `src/**/README.md`,
  `src/ReplicatedStorage/Configs/*.lua`
- Status sistem yang berubah: Struktur project Rojo ⬜→🔄
- Diketahui belum selesai / next step: belum ada satu pun Service/Controller
  berlogic, belum ada Remote didefinisikan, Config masih kosong (menunggu
  konten desain final di GDD — nama ras/kelas/zona, dsb).
- Catatan risiko/exploit yang perlu direview manusia: tidak ada (belum ada
  logic yang berjalan).

### [Sesi dokumentasi awal]
- Dokumentasi awal (GDD/TDD/DDD/aturan agent) dibuat, belum ada implementasi kode.

## 3. Isu Terbuka / Butuh Keputusan Manusia
_(Daftar hal yang AI temui tapi tidak bisa putuskan sendiri — lihat `04_AI_AGENT_RULES.md` §4)_

- _(kosong)_
