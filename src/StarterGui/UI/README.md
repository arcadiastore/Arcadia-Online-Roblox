# UI
Komponen antarmuka (ScreenGui, Frame, dsb.), diorganisir per sistem
(mis. `Inventory/`, `QuestLog/`, `PartyPanel/`, `HUD/`).

Teks yang tampil ke pemain (nama, deskripsi) idealnya diambil dari
`ReplicatedStorage/Configs/*`, bukan ditulis literal di dalam script UI — lihat
`docs/06_CODING_STANDARDS.md` §2.

## Status
- `CharacterCreation/` — sudah diimplementasikan (Race reveal+reroll → Class select),
  lihat `StarterPlayerScripts/Controllers/CharacterCreationController.lua` untuk wiring
  ke Remote `Character/*`. Sistem UI lain (HUD, Inventory, QuestLog, PartyPanel) masih
  skeleton kosong, ikuti pola yang sama saat diimplementasikan.
