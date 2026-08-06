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
