# GAME DESIGN DOCUMENT (GDD)

## 1. Ringkasan Eksekutif
Sebuah MMORPG medieval-fantasy di Roblox dengan pace lambat, di mana pemain adalah pahlawan yang menjelajahi dunia terpecah oleh **Portal/Gate** yang menghubungkan wilayah-wilayah berbeda, melawan kekuatan jahat yang menyebar. Progres didapat lewat leveling bertahap, pemilihan Ras & Kelas, sistem elemen, dungeon party-based, dan quest cerita.

## 2. Genre & Platform
- Genre: MMORPG, Fantasy, Adventure, party-based combat
- Platform: Roblox (PC, Mobile, Console — wajib cross-platform friendly)
- Pace: **Slow-paced** secara sengaja — progres bertahap, bukan instant-gratification

## 3. Target Audience
- Pemain penggemar MMORPG grinding di Roblox
- Pemain yang menyukai eksplorasi dunia, party play, dan build karakter jangka panjang

## 4. Pilar Desain (Core Pillars)
1. **Progression bermakna** — tiap level/job change/gate terasa seperti pencapaian, bukan grind kosong.
2. **Dunia berlapis lewat Portal** — wilayah baru terbuka secara progresif via gate, bukan open-world instan.
3. **Build identity** — kombinasi Ras + Kelas + Elemen menghasilkan banyak variasi build.
4. **Party > Solo** — dungeon dan boss dirancang mendorong kerja sama, tapi solo tetap mungkin lebih lambat.
5. **Fair monetization** — kosmetik/kenyamanan, bukan pay-to-win, agar sesuai Roblox Community Standards.

## 5. Dunia & Lore
- Setting: zaman medieval fantasi, "tanah" yang perlahan dikuasai kekuatan jahat (Corruption).
- **Portal/Gate** adalah mekanik dunia sekaligus lore: gerbang kuno yang membuka jalur ke wilayah lain (hutan, gunung, kastil, dungeon bawah tanah, dimensi corrupted). Setiap gate memiliki syarat pembuka (level, quest, item kunci).
- Pemain berperan sebagai Hero yang dibangkitkan/direkrut untuk menutup sumber Corruption dan membebaskan tiap wilayah.

_(Detail cerita, nama wilayah, nama NPC, dan timeline lore diisi tim naratif — dokumen ini menyediakan kerangka, bukan lore final.)_

## 6. Peta Wilayah / Zona
| Zona | Level Rekomendasi | Cara Unlock | Catatan |
|---|---|---|---|
| Starting Village | 1–10 | Default | Tutorial, pilih Ras & Kelas |
| Zona 2 (contoh: Hutan Corrupted) | 10–25 | Selesaikan quest gate 1 | Elemen dominan: Nature/Dark |
| Zona 3 (contoh: Pegunungan) | 25–45 | Buka Portal ke-2 | Elemen dominan: Earth/Ice |
| Dungeon Instance | Bervariasi | Party + key item | Private server/instance |
| Endgame Zone | Cap level | Semua gate utama selesai | Raid & PvP hub |

_(Isi ulang tabel ini sesuai jumlah zona final; ini kerangka awal.)_

## 7. Core Gameplay Loop
```
Terima Quest → Grind/Jelajah Zona → Naik Level & Loot →
Upgrade Gear/Skill → Buka Gate baru / Job Change →
Masuk Dungeon (party) → Loot lebih baik → Ulangi dengan tantangan lebih tinggi
```

## 8. Karakter

### 8.1 Sistem Ras
- Ras umum (contoh: Human, Elf, Beastkin) dengan bonus stat berbeda.
- Ras langka/varian tersembunyi (contoh: "Corrupted Human") dengan bonus stat lebih kuat, didapat via reroll/RNG saat pembuatan karakter.
- Ras memengaruhi stat awal (STR, VIT, INT, AGI, dst.), bukan mengunci kelas.

### 8.2 Sistem Kelas
- Kelas dasar (contoh): **Warrior** (physical DPS), **Defender** (tank), **Enchanter/Wizard** (magic DPS), **Healer** (support), **Ranger/Assassin** (agility DPS).
- **Job Change**: kelas dasar dapat naik tingkat ke kelas lanjutan setelah syarat level/quest terpenuhi (bukan sekadar reskin, tapi membuka skill baru).
- Kelas menentukan skill tree, tipe senjata yang dipakai, dan role di party.

### 8.3 Stat & Combat Points
- Stat inti: Strength, Vitality, Intelligence, Agility, Luck (sesuaikan sesuai desain final).
- **Combat Points**: poin yang didapat dari leveling/achievement untuk dialokasikan ke stat secara manual → mendukung build variety.
- Achievement dapat memberi bonus stat permanen kecil (mendorong eksplorasi konten, bukan cuma grinding).

## 9. Sistem Elemen
- Elemen (contoh): Fire, Water, Earth, Wind/Air, Light, Dark, Nature, Ice.
- Setiap elemen punya relasi **strong-against / weak-against** dalam bentuk "Element Chart" (mirip rock-paper-scissors diperluas).
- Skill dan senjata bisa memiliki afinitas elemen; musuh punya resistensi/kelemahan elemen tertentu.
- Element Chart harus berupa **data**, bukan hardcode di logic combat (lihat `03_DDD.md`).

## 10. Sistem Combat
- Real-time, bukan turn-based. Kombinasi normal attack + skill dengan cooldown + block/dodge.
- Server-authoritative: hit detection & damage dihitung ulang di server (lihat `02_TDD.md` bagian anti-exploit).
- Damage formula mempertimbangkan: stat pelaku, stat/defense target, elemen, tipe senjata, buff/debuff aktif.

## 11. Portal / Gate System (mekanik ciri khas game ini)
- Gate adalah struktur dunia yang menghubungkan zona.
- Status gate: **Terkunci → Syarat terpenuhi → Terbuka permanen** (per-pemain atau per-server, tentukan di desain final).
- Gate bisa juga menjadi pintu ke **dungeon instance** (private server/reserved server di Roblox).
- Membuka gate = milestone naratif + milestone progression sekaligus.

## 12. Dungeon & Instance
- Dungeon berbasis party (disarankan 2–5 pemain).
- Dijalankan sebagai **reserved server / private instance** agar tidak saling mengganggu antar party.
- Struktur: beberapa ruangan/lantai → mini-boss → boss akhir → loot chest.

## 13. Quest System
- Main Quest (mendorong cerita & buka gate).
- Side Quest (lore tambahan, item unik).
- Daily/Repeatable Quest (grinding terstruktur, currency).
- Quest disimpan sebagai data (lihat `03_DDD.md`), bukan hardcode per NPC.

## 14. Ekonomi
- Currency utama (soft currency, didapat in-game) dan currency premium (Robux-based, gamepass).
- Shop NPC, kemungkinan player trading (jika ada, wajib anti-scam & anti-dupe — lihat TDD).
- Crafting sistem opsional untuk fase lanjutan.

## 15. Sosial
- Party system (2–5 pemain, share XP/loot dengan aturan jelas).
- Guild/Clan (opsional fase lanjutan).
- Chat, emote, friend list (pakai fitur Roblox native sebisa mungkin).

## 16. PvP
- Opsional, arena terpisah dari PvE agar tidak mengganggu balance PvE.
- Tidak memengaruhi progres PvE utama di fase awal (hindari kompleksitas balance ganda).

## 17. Monetisasi
- Prinsip: **kosmetik & kenyamanan, bukan power langsung** (sesuai kebijakan Roblox & menjaga fairness).
- Contoh: skin, extra inventory slot, boost XP terbatas waktu (bukan stat permanen), reroll ras tambahan.

## 18. UI/UX (garis besar)
- HUD: HP/MP bar, minimap, quest tracker, hotbar skill.
- Menu: Inventory, Character/Stats, Quest Log, Party, Map/Gate status, Shop.
- Mobile-first considerations: tombol besar, auto-target opsional untuk mobile.

## 19. Roadmap Konten (placeholder)
| Fase | Fokus |
|---|---|
| Fase 1 (MVP) | 1 zona awal, 2–3 kelas, sistem combat dasar, 1 dungeon |
| Fase 2 | Zona 2, element chart penuh, job change, party system |
| Fase 3 | Dungeon tambahan, quest cerita lanjutan, ekonomi/shop |
| Fase 4 | PvP, guild, endgame content |

_(Update tabel ini di `05_PROGRESS_TRACKER.md`, bukan di sini — dokumen ini adalah rencana, bukan status.)_
