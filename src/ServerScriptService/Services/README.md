# Services
Satu ModuleScript = satu sistem/domain (mis. `DataService`, `CombatService`,
`QuestService`, `GateService`, `InventoryService`, `PartyService`).

Aturan (lihat `docs/02_TDD.md` §4 dan `docs/04_AI_AGENT_RULES.md`):
- Service TIDAK boleh mencampur tanggung jawab lebih dari satu domain.
- Semua Remote yang masuk ke Service ini wajib divalidasi (tipe, batas nilai,
  kepemilikan, rate limit) sebelum diproses — server tidak pernah percaya client.
- Semua angka/nama diambil dari `ReplicatedStorage/Configs/*`, tidak hardcode.

Belum ada Service yang diimplementasikan — folder ini masih skeleton kosong.
