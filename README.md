# Arcadia Online

Medieval-fantasy MMORPG untuk Roblox — slow-paced progression, sistem Ras & Kelas,
Element Chart, dan dunia yang terbuka bertahap lewat Portal/Gate.

## Dokumentasi
Semua desain & aturan kerja ada di folder [`docs/`](./docs):
- `00_INDEX.md` — mulai dari sini
- `01_GDD.md` — Game Design Document
- `02_TDD.md` — Technical Design Document
- `03_DDD.md` — Data Design Document
- `04_AI_AGENT_RULES.md` — aturan wajib untuk AI agent (Claude Code, dll.)
- `05_PROGRESS_TRACKER.md` — status pengerjaan terkini (WAJIB dibaca sebelum kerja)
- `06_CODING_STANDARDS.md` — checklist anti-hardcode & anti-exploit
- `07_CHANGELOG.md` — riwayat perubahan

## Struktur kode (akan dibuat mengikuti 02_TDD.md)
```
src/
├── ReplicatedStorage/{Shared,Configs,Remotes}
├── ServerScriptService/Services
├── ServerStorage/Private
├── StarterPlayerScripts/Controllers
└── StarterGui/UI
```
