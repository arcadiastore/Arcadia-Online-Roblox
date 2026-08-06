# PROGRESS TRACKER
> Dokumen ini WAJIB dibaca di awal setiap sesi dan diupdate di akhir setiap sesi.
> Legend status: ⬜ Belum mulai · 🔄 Sedang dikerjakan · ✅ Selesai · 🚫 Diblokir/butuh keputusan

## 1. Status Sistem

### Fondasi Teknis
| Sistem | Status | Catatan |
|---|---|---|
| Struktur project Rojo | 🔄 | Skeleton folder + `default.project.json` + Config kosong sudah dibuat. Belum ada logic Service/Controller. |
| DataStore / Profile system | ⬜ | |
| Service/Controller pattern dasar | ⬜ | |
| Remote validation framework dasar | ⬜ | |

### Karakter & Progression
| Sistem | Status | Catatan |
|---|---|---|
| Character creation (pilih Ras) | ⬜ | |
| Character creation (pilih Kelas) | ⬜ | |
| Sistem stat & Combat Points | ⬜ | |
| Leveling / EXP curve | ⬜ | |
| Job change | ⬜ | |

### Gameplay Inti
| Sistem | Status | Catatan |
|---|---|---|
| Sistem elemen (Element Chart) | ⬜ | |
| Sistem combat dasar (attack + skill) | ⬜ | |
| Gate/Portal system | ⬜ | |
| Zona 1 (Starting Village) | ⬜ | |
| Dungeon instance pertama | ⬜ | |
| Quest system (main quest) | ⬜ | |

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
