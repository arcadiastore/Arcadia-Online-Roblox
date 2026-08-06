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
}
```

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

## 5. Aturan Versi & Migrasi Data
0. `ProfessionId`/`ProfessionExp` di §4 adalah field baru (ditambahkan bersama desain Craftsman) — begitu implementasi Profile system mulai berjalan, penambahan ini wajib lewat migrasi resmi (poin 1–3 di bawah), bukan langsung ditulis ke schema versi berjalan, karena saat ditulis dokumen ini belum ada satupun data pemain di production.
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
