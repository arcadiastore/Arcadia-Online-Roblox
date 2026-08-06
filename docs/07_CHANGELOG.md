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
