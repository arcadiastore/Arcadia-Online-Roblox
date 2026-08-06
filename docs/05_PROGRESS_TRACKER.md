# PROGRESS TRACKER
> Dokumen ini WAJIB dibaca di awal setiap sesi dan diupdate di akhir setiap sesi.
> Legend status: ⬜ Belum mulai · 🔄 Sedang dikerjakan · ✅ Selesai · 🚫 Diblokir/butuh keputusan

## 1. Status Sistem

### Fondasi Teknis
| Sistem | Status | Catatan |
|---|---|---|
| Struktur project Rojo | 🔄 | Skeleton folder + `default.project.json` + Config kosong sudah dibuat. Belum ada logic Service/Controller. |
| DataStore / Profile system | 🔄 | Implementasi kode selesai (ProfileStore session-locked + DataService + migrasi v1→v2 + remote `Data/GetProfile`). Belum ✅ karena belum dites manual di Roblox Studio (syarat wajib `04_AI_AGENT_RULES.md` §2). |
| Service/Controller pattern dasar | ⬜ | |
| Remote validation framework dasar | ⬜ | |

### Karakter & Progression
| Sistem | Status | Catatan |
|---|---|---|
| Desain Ras final (5 ras) | ✅ | Data di `Configs/Races.lua`. Lihat `01_GDD.md` §8.1 |
| Desain Kelas combat final (6 jalur, Tier 1–3) | ✅ | Data di `Configs/Classes.lua`. Lihat `01_GDD.md` §8.2 (5 jalur awal + **Assassin→Shadowblade→Nightstalker**) |
| Desain Profesi non-combat final (Craftsman) | ✅ | Data di `Configs/Professions.lua`. Lihat `01_GDD.md` §8.4. Terpisah dari Job Tier combat |
| Character creation (pilih Ras) — implementasi | ⬜ | Data sudah siap, logic Service belum |
| Character creation (pilih Kelas) — implementasi | ⬜ | Data sudah siap, logic Service belum |
| Sistem stat & Combat Points — implementasi | ⬜ | |
| Leveling / EXP curve | ⬜ | `Configs/LevelCurve.lua` masih skeleton kosong |
| Job change — implementasi | ⬜ | Syarat per tier sudah ada di `Configs/Classes.lua`, logic belum |

### Gameplay Inti
| Sistem | Status | Catatan |
|---|---|---|
| Desain Element Chart final | ✅ | Data di `Configs/Elements.lua`. Lihat `01_GDD.md` §9 |
| Sistem elemen — implementasi combat | ⬜ | Data sudah siap, logic Service belum |
| Sistem combat dasar (attack + skill) | ⬜ | |
| Desain Zona & Gate final (Millhaven → Shattered Sanctum) | ✅ | Lihat `01_GDD.md` §6, data gate di `Configs/Gates.lua` |
| Gate/Portal system — implementasi | ⬜ | Data sudah siap, logic Service belum |
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
