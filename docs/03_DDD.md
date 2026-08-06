# DATA DESIGN DOCUMENT (DDD)

## 1. Filosofi: Data-Driven, Bukan Hardcode
Semua angka balance, nama, ID, teks deskripsi, dan relasi (mis. elemen kuat/lemah) **harus** berada di modul Config (`ReplicatedStorage/Configs/*`), bukan ditulis literal di dalam logic script (`Services/*`).

**Salah (hardcode):**
```lua
-- di dalam CombatService
if attacker.Race == "Elf" then
    damage = damage * 1.1 -- DILARANG: angka & nama ras literal di logic
end
```

**Benar (data-driven):**
```lua
-- Configs/Races.lua
return {
    Elf = { damageMultiplier = 1.1, statBonus = { AGI = 5, INT = 3 } },
    Human = { damageMultiplier = 1.0, statBonus = { STR = 2, VIT = 2 } },
}
```
```lua
-- CombatService.lua
local RacesConfig = require(Configs.Races)
local mult = RacesConfig[attacker.Race].damageMultiplier
damage = damage * mult
```

## 2. Modul Config yang Wajib Ada
| File Config | Isi |
|---|---|
| `Configs/Races.lua` | Daftar ras + stat bonus + rarity/weight untuk reroll |
| `Configs/Classes.lua` | Daftar kelas + skill list + syarat job change |
| `Configs/Elements.lua` | Element chart (strong/weak matrix) |
| `Configs/Skills.lua` | Definisi tiap skill (damage base, cooldown, mana cost, elemen, target type) |
| `Configs/Items.lua` | Definisi item (equipment, consumable, stat, rarity) |
| `Configs/Enemies.lua` | Definisi musuh (HP, stat, resistensi elemen, drop table id) |
| `Configs/Quests.lua` | Definisi quest (syarat, reward, langkah) |
| `Configs/Gates.lua` | Definisi gate/portal (syarat buka, zona tujuan) |
| `Configs/LevelCurve.lua` | Rumus/tabel EXP per level |
| `Configs/Professions.lua` | Daftar profesi non-combat (Craftsman) + rank + resep crafting |

## 3. Contoh Skema Entry

### Race entry
```lua
{
  id = "Elf",
  displayName = "Elf",
  rarity = "Common",      -- Common | Rare
  statBonus = { STR = 0, VIT = 2, INT = 5, AGI = 6 },
  weight = 20,              -- bobot untuk RNG reroll
}
```

### Class entry
```lua
{
  id = "Warrior",
  displayName = "Warrior",
  tier = 1,                          -- 1 = base class
  weaponTypes = { "Sword", "Axe" },
  skillIds = { "SlashCombo", "WarCry" },
  jobChange = {
    nextClassId = "Berserker",
    requiredLevel = 40,
    requiredQuestId = "Q_BerserkerTrial",
  },
}
```

### Element chart entry
```lua
Fire = { strongAgainst = { "Nature", "Ice" }, weakAgainst = { "Water" } },
```

### Item entry
```lua
{
  id = "IronSword",
  displayName = "Iron Sword",
  type = "Weapon",
  rarity = "Common",
  stats = { STR = 4 },
  element = nil,
  tradable = true,

  -- Aset visual 3D/2D — lihat §3.1 di bawah untuk konvensi lengkap.
  meshId = "rbxassetid://0",     -- placeholder sampai model final diupload
  textureId = "rbxassetid://0",  -- placeholder, nil kalau mesh belum bertekstur sendiri
  iconId = "rbxassetid://0",     -- ikon 2D untuk UI inventory/hotbar
}
```

### 3.1 Konvensi Aset Visual (meshId / textureId / iconId)
Berlaku untuk semua entry `Items.lua` yang punya wujud fisik (Weapon, Armor, dsb — item abstrak seperti currency/quest item boleh skip field ini) dan (nanti) `Enemies.lua`.

- **`meshId`** — id aset MeshPart Roblox (`rbxassetid://...`) hasil upload manual dari Studio atau tool AI generator (lihat §8.4 GDD & percakapan desain untuk daftar tool: Roblox Studio Cube, Meshy, Sloyd, dsb.). Untuk item non-equipment yang tidak butuh model 3D unik (mis. bahan crafting generik), boleh `nil` dan pakai part/ikon generik dari `Shared`.
- **`textureId`** — id aset texture terpisah, dipakai kalau mesh diexport tanpa material ter-bake. Kalau mesh sudah datang dengan PBR material dari generator, boleh `nil`.
- **`iconId`** — wajib diisi untuk semua item yang muncul di UI (inventory, hotbar, shop) — beda dari `meshId` karena ini gambar 2D datar (thumbnail), bukan model 3D.
- **Placeholder wajib `"rbxassetid://0"`, bukan string kosong `""` atau `nil` diam-diam**, supaya jelas dibedakan "belum diisi" vs "sengaja tanpa model". Ganti ke id asli begitu aset final diupload ke Roblox — cukup edit di `Items.lua`, tidak menyentuh Service manapun (konsisten dengan §1 Single Source of Truth).
- Proses upload aset (dari hasil AI generator eksternal seperti Meshy/Sloyd, atau bikinan artist) tetap manual lewat Roblox Studio/Creator Hub — **bukan** sesuatu yang dilakukan otomatis oleh Service saat runtime.

### Material item entry (bahan crafting — tetap di `Items.lua`, type = "Material")
```lua
{
  id = "IronOre",
  displayName = "Iron Ore",
  type = "Material",
  rarity = "Common",
  tradable = true,
}
```

### Profession entry (`Configs/Professions.lua`)
```lua
Craftsman = {
  id = "Craftsman",
  displayName = "Craftsman",
  ranks = {
    { id = "Apprentice", displayName = "Apprentice Craftsman", requiredExp = 0 },
    { id = "Journeyman",  displayName = "Journeyman Craftsman", requiredExp = 500 },
    { id = "Master",      displayName = "Master Craftsman",     requiredExp = 2000 },
  },
  recipeIds = { "Recipe_IronSword" }, -- placeholder, isi setelah resep didesain
}
```

### Recipe entry (`Configs/Professions.lua`)
```lua
Recipe_IronSword = {
  id = "Recipe_IronSword",
  professionId = "Craftsman",
  requiredRank = "Apprentice",
  materials = { { itemId = "IronOre", quantity = 3 } },
  resultItemId = "IronSword",
  resultQuantity = 1,
}
```

## 4. Skema Data Pemain (Player Profile)
```lua
{
  SchemaVersion = 1,
  Level = 1,
  Exp = 0,
  RaceId = "Human",
  ClassId = "Warrior",
  ProfessionId = nil,      -- nil = belum ambil profesi; kalau ada, mis. "Craftsman" (§8.4 GDD)
  ProfessionExp = 0,       -- independen dari character Exp/Level
  Stats = { STR = 5, VIT = 5, INT = 5, AGI = 5, LUK = 5 },
  UnspentCombatPoints = 0,
  Currency = { Soft = 0, Premium = 0 },
  Inventory = { --[[ list of { itemId, quantity, instanceData } ]] },
  Equipment = { --[[ slot -> itemInstanceId ]] },
  QuestLog = { --[[ questId -> { status, progress } ]] },
  UnlockedGates = { --[[ list of gateId ]] },
  Achievements = { --[[ list of achievementId ]] },
  Settings = { --[[ preferensi UI, dsb ]] },
}
```

**Implementasi teknis:** skema di atas diimplementasikan sebagai
`ReplicatedStorage/Configs/ProfileTemplate.lua` (nilai default profil BARU) +
`ServerStorage/Private/ProfileStore.lua` (engine DataStore session-locked) +
`ServerScriptService/Services/DataService` (Service resmi, satu-satunya
titik akses data pemain — lihat `02_TDD.md` §6). Asumsi yang diambil saat
implementasi: `RaceId`/`ClassId` default **nil** (bukan `"Human"`/`"Warrior"`
seperti contoh di atas), karena character creation belum diimplementasi —
perlu dikonfirmasi pemilik project apakah ini perilaku yang diinginkan.

## 5. Aturan Versi & Migrasi Data
0. `ProfessionId`/`ProfessionExp` di §4 adalah field baru (ditambahkan bersama desain Craftsman) — begitu implementasi Profile system mulai berjalan, penambahan ini wajib lewat migrasi resmi (poin 1–3 di bawah), bukan langsung ditulis ke schema versi berjalan, karena saat ditulis dokumen ini belum ada satupun data pemain di production.
   **[Resolusi — implementasi Profile system]:** `Configs/ProfileTemplate.lua` (SchemaVersion baseline untuk pemain baru) memakai **SchemaVersion 2** (skema §4 sekarang, termasuk `ProfessionId`/`ProfessionExp`). Migrasi resmi `v1_to_v2` (`ServerScriptService/Services/DataService/ProfileMigrations/v1_to_v2.lua`) dibuat mengikuti poin 0 ini secara harfiah, walau pada praktiknya belum ada data v1 nyata di production — supaya jalur migrasi sudah teruji sebelum dibutuhkan sungguhan nanti.
1. Setiap perubahan struktur `Player Profile` **menaikkan** `SchemaVersion`.
2. Migrasi ditulis sebagai fungsi tambahan (`Migrations/v1_to_v2.lua`, dst.), dipanggil berurutan saat load data lama — **jangan** menghapus/menimpa field lama secara diam-diam.
3. Field baru harus punya default value yang aman jika field itu belum ada di data lama (jangan asumsikan semua data pemain sudah punya field terbaru).
4. Dilarang mengganti *tipe data* sebuah field yang sudah dipakai di production tanpa migrasi eksplisit (mis. Currency dari number jadi table harus lewat migrasi, bukan langsung ganti).

## 6. Konvensi Penamaan
- ID (kunci di Config) pakai `PascalCase` tanpa spasi, unik secara global per kategori (mis. `IronSword`, `Q_BerserkerTrial`, `Gate_ForestOfCorruption`).
- Field data pemain pakai `PascalCase` konsisten dengan skema di atas.
- Satu ID hanya boleh didefinisikan **satu kali** di satu file Config — jangan duplikasi definisi item/quest yang sama di dua tempat.

## 7. Single Source of Truth
- Nilai balance HANYA boleh diubah lewat file di `Configs/`. Jika sebuah angka game perlu diubah, cari & edit di Config — jangan tambal lewat angka baru di Service.
- Dokumen `01_GDD.md` menjelaskan *maksud desain* (mis. "Elf lebih cepat"), file Config adalah *implementasi angka sebenarnya*. Kalau keduanya beda, Config di kode adalah kebenaran teknis saat ini — tapi harus dicek ulang apakah sesuai niat GDD, dan dicatat jika sengaja menyimpang.
