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
- **Nama dunia: Arcadia.** Zaman medieval fantasi klasik, tanpa twist tema tambahan.
- Ratusan tahun lalu, sebuah entitas jatuh bernama **Malgrath the Hollow King** menodai jaringan Portal kuno yang dulunya menghubungkan seluruh penjuru Arcadia secara damai. Portal-portal itu kini retak, memancarkan **Corruption** yang perlahan merusak tanah, makhluk, dan pikiran di sekitarnya.
- **Portal/Gate** adalah mekanik dunia sekaligus lore utama: gerbang kuno yang dulu menyatukan Arcadia, kini menjadi jalur yang harus dibuka & dimurnikan satu per satu oleh Hero untuk membendung Corruption dan menghubungkan kembali wilayah-wilayah yang terisolasi.
- Pemain berperan sebagai Hero yang dibangkitkan oleh sisa kekuatan Portal untuk menutup sumber Corruption di tiap wilayah, sekaligus mengungkap kebenaran di balik jatuhnya Malgrath.
- **Angel** hadir ke Arcadia sebagai utusan yang berusaha memperbaiki Portal; **Evil** adalah keturunan makhluk yang pernah tersentuh Corruption namun mempertahankan kehendak bebasnya dan memilih melawan balik — dua ras ini merepresentasikan dua sisi ekstrem dari konflik Light vs Dark yang menjadi tema sentral lore.

_(Detail dialog NPC, nama tokoh pendukung, dan timeline lore rinci masih terbuka untuk dikembangkan tim naratif — kerangka utama di atas sudah final dan menjadi acuan.)_

## 6. Peta Wilayah / Zona
| Zona | Level Rekomendasi | Cara Unlock | Elemen Dominan | Catatan |
|---|---|---|---|---|
| **Millhaven** | 1–10 | Default (starting zone) | — | Desa awal, tutorial, pilih Ras & Kelas |
| **Duskwood Forest** | 10–25 | Selesaikan quest & buka `Gate_Duskwood` | Dark / Earth | Hutan yang mulai dirambati Corruption |
| **Frostpeak Mountains** | 25–45 | Buka `Gate_Frostpeak` | Water / Wind | Pegunungan bersalju, jalur ke dungeon pertama |
| **The Sunken Crypt** (Dungeon) | 30+ (party) | Party + key item dari Frostpeak | Dark | Reserved server/instance, boss pertama |
| **The Shattered Sanctum** | Cap level (endgame) | Semua gate utama selesai | Light vs Dark | Sumber Corruption Malgrath, raid & PvP hub |

_(Zona tambahan di fase lanjutan mengikuti pola penamaan yang sama — nama tempat berbahasa Inggris, deskriptif terhadap elemen/suasana wilayah.)_

## 7. Core Gameplay Loop
```
Terima Quest → Grind/Jelajah Zona → Naik Level & Loot →
Upgrade Gear/Skill → Buka Gate baru / Job Change →
Masuk Dungeon (party) → Loot lebih baik → Ulangi dengan tantangan lebih tinggi
```

## 8. Karakter

### 8.1 Sistem Ras (Final — MVP)
Stat inti per ras: **STR, VIT, INT, AGI, LUK**. Nilai adalah modifier tambahan di atas base stat karakter (base stat sama untuk semua ras, ditentukan `LevelCurve`/base stat table terpisah).

| Ras | Rarity | STR | VIT | INT | AGI | LUK | Ciri Khas |
|---|---|---|---|---|---|---|---|
| **Human** | Common | +2 | +2 | +2 | +2 | +2 | Serba bisa, tidak ada kelemahan — cocok untuk pemula & build fleksibel |
| **Elf** | Common | −2 | −2 | +6 | +6 | +2 | Afinitas magic & kecepatan tinggi, fisik rapuh |
| **Dwarf** | Common | +6 | +6 | −2 | −4 | 0 | Kuat & tahan banting, lambat, cocok tank/melee |
| **Angel** | Rare | −3 | +2 | +5 | +1 | +5 | Afinitas elemen **Light**, sangat beruntung, fisik lemah |
| **Evil** | Rare | +5 | +3 | +4 | −2 | −4 | Afinitas elemen **Dark**, kuat & sakti tapi sial (LUK rendah) |

- Ras **Common** didapat lewat pembuatan karakter normal. Ras **Rare** (Angel, Evil) didapat lewat mekanik reroll/RNG dengan bobot lebih kecil (lihat `Configs/Races.lua`, field `weight`).
- Ras memengaruhi stat awal & (khusus Angel/Evil) memberi afinitas elemen bawaan, **tidak** mengunci pilihan Kelas — kombinasi Ras × Kelas bebas dipilih pemain.

### 8.2 Sistem Kelas & Job Tier (Final — MVP)
5 jalur Kelas, masing-masing linear **Tier 1 → Tier 2 → Tier 3** (job change berikutnya membuka skill baru & memperkuat role, bukan sekadar ganti nama):

| Role | Tier 1 (mulai) | Tier 2 (job change) | Tier 3 (job change lanjutan) |
|---|---|---|---|
| Melee Physical DPS | **Warrior** | **Knight** | **Warlord** |
| Melee Physical DPS (Stealth/Crit) | **Assassin** | **Shadowblade** | **Nightstalker** |
| Tank | **Defender** | **Guardian** | **Sentinel** |
| Magic DPS | **Mage** | **Elementalist** | **Archmage** |
| Support/Healer | **Healer** | **Priest** | **High Priest** |
| Ranged Physical DPS | **Archer** | **Ranger** | **Deadeye** |

- Job change ke tier berikutnya butuh syarat **level minimum + quest job change** (syarat pasti diisi per kelas di `Configs/Classes.lua`, field `jobChange`).
- Tier 2 & 3 tidak mengubah role dasar (mis. Warrior tetap jalur melee sampai Warlord) — variasi build datang dari kombinasi Ras + Elemen + gear, bukan dari branching kelas di MVP ini. Branching (satu Tier 1 punya beberapa pilihan Tier 2) bisa ditambah di fase pasca-MVP dan dicatat sebagai perubahan desain baru, bukan menimpa chain yang sudah ada.
- Kelas menentukan tipe senjata yang dipakai dan role di party (tank/DPS/support), konsisten di semua tier dalam satu jalur.
- **Assassin** adalah jalur ke-6, paralel dengan Warrior — sama-sama Melee Physical DPS, tapi diferensiasi lewat weapon type (**Dagger/Dual Blade**, vs Sword/Axe milik Warrior) dan identitas kit (crit chance/stealth-burst tinggi, VIT lebih rendah, bergantung pada AGI/LUK) — bukan branching dari Warrior, melainkan jalur Tier 1 independen sejak awal. Detail skill pasti diisi belakangan di `Configs/Skills.lua`.

### 8.3 Stat & Combat Points
- Stat inti: **Strength (STR), Vitality (VIT), Intelligence (INT), Agility (AGI), Luck (LUK)** — final, dipakai konsisten di seluruh sistem (Ras, Kelas, Item, dsb).
- **Combat Points**: poin yang didapat dari leveling/achievement untuk dialokasikan ke stat secara manual → mendukung build variety.
- Achievement dapat memberi bonus stat permanen kecil (mendorong eksplorasi konten, bukan cuma grinding).

### 8.4 Sistem Profesi: Craftsman (Final — MVP)
Craftsman adalah **profesi non-combat** (lifeskill), terpisah total dari sistem Kelas/Job Tier di §8.2 — bukan role party, tidak punya weapon type, dan tidak masuk chain Tier 1→2→3 combat. Merealisasikan crafting yang sebelumnya disebut opsional di §14 Ekonomi.

- **Bebas dikombinasikan** dengan Ras + Kelas apapun — tiap karakter boleh sekaligus jadi mis. Mage + Craftsman, tanpa saling mengunci pilihan (paralel dengan filosofi Ras × Kelas bebas di §8.1).
- **Progression sendiri**, terpisah dari character level: **Craftsman EXP** didapat dari mengumpulkan bahan mentah (gathering di zona/dungeon) dan berhasil crafting, dinaikkan lewat 3 rank — **Apprentice Craftsman → Journeyman Craftsman → Master Craftsman** — tiap rank naik membuka tier resep lebih tinggi (bukan level minimum karakter, murni dari aktivitas crafting itu sendiri).
- **Output**: crafting menghasilkan equipment & consumable dari resep + bahan mentah (bahan didefinisikan sebagai item baru bertipe `"Material"` di `Configs/Items.lua`, resep didefinisikan di `Configs/Professions.lua` — modul Config baru).
- **Ekonomi**: hasil craft bisa dipakai sendiri atau (jika player trading diaktifkan, lihat §14) diperjualbelikan — mendukung pilar "Fair monetization" karena crafting adalah power lewat effort in-game, bukan Robux.
- Tidak menggantikan Job Change di §8.2 — pemain tetap wajib pilih Kelas combat terpisah untuk bertarung; Craftsman murni menambah utility/ekonomi.
- Skema data & contoh entry resep: lihat `03_DDD.md` §2–3 (`Configs/Professions.lua`) dan §4 (field `ProfessionId`/`ProfessionExp` di Player Profile).

## 9. Sistem Elemen (Final — MVP)
6 elemen: **Fire, Water, Earth, Wind, Light, Dark**.

Relasi strong/weak (siklus 4 elemen fisik + pasangan Light↔Dark yang saling counter):
```
Fire  → kuat lawan Wind   → kuat lawan Earth → kuat lawan Water → kuat lawan Fire (siklus)
Light ⇄ Dark saling kuat & lemah satu sama lain (counter langsung, tidak searah)
```
| Elemen | Kuat Melawan | Lemah Melawan |
|---|---|---|
| Fire | Wind | Water |
| Water | Fire | Earth |
| Earth | Water | Wind |
| Wind | Earth | Fire |
| Light | Dark | Dark |
| Dark | Light | Light |

- Skill dan senjata bisa memiliki afinitas elemen; musuh punya resistensi/kelemahan elemen tertentu.
- Ras **Angel** punya afinitas bawaan **Light**, ras **Evil** punya afinitas bawaan **Dark** (bonus damage kecil saat memakai skill elemen tersebut — besaran pasti di `Configs/Races.lua`/`Configs/Elements.lua`).
- Element Chart ini sudah dituangkan sebagai data di `Configs/Elements.lua` — **jangan** hardcode relasi ini di dalam `CombatService`.

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
- Crafting: lihat §8.4 (profesi **Craftsman**, final MVP) — hasil craft mengalir ke shop/trading di sini.

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

## 19. Roadmap Konten
| Fase | Fokus |
|---|---|
| Fase 1 (MVP) | Zona Millhaven, 5 Ras, 6 Kelas combat Tier 1 (termasuk Assassin) + profesi Craftsman, Element Chart penuh, combat dasar |
| Fase 2 | Duskwood Forest, Frostpeak Mountains, job change Tier 2, party system |
| Fase 3 | The Sunken Crypt (dungeon), job change Tier 3, quest cerita lanjutan, ekonomi/shop |
| Fase 4 | The Shattered Sanctum (endgame), PvP, guild |

_(Update tabel ini di `05_PROGRESS_TRACKER.md`, bukan di sini — dokumen ini adalah rencana, bukan status.)_
