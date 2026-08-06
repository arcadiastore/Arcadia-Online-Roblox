# CODING STANDARDS & CHECKLIST

## 1. Gaya Penulisan Luau
- `PascalCase` untuk Service, Controller, ModuleScript, dan nama class/tipe.
- `camelCase` untuk variabel lokal dan parameter fungsi.
- `SCREAMING_SNAKE_CASE` hanya untuk konstanta benar-benar tetap di dalam satu modul (jarang dipakai — biasanya konstanta tetap masuk Config).
- Satu ModuleScript = satu tanggung jawab jelas. Jika sebuah Service sudah >300–400 baris dan menangani banyak hal berbeda, pertimbangkan pecah jadi sub-modul.
- Setiap fungsi publik di Service diberi komentar singkat: tujuan, parameter, siapa yang boleh memanggil (server-only/client-callable).

## 2. Checklist Anti-Hardcode
Sebelum commit, cek ulang kode yang baru ditulis:
- [ ] Tidak ada angka "ajaib" (magic number) untuk damage, harga, EXP, cooldown, dsb. langsung di logic — semua dari `Configs/*`.
- [ ] Tidak ada nama Ras/Kelas/Item/Quest ditulis sebagai string literal untuk pengambilan keputusan logic (`if raceId == "Elf"`) — gunakan lookup ke Config, bukan perbandingan string tersebar di banyak file.
- [ ] Teks yang tampil ke pemain (nama, deskripsi) diambil dari Config/tabel lokalisasi, bukan ditulis langsung di script UI (memudahkan perubahan & lokalisasi di masa depan).
- [ ] Tidak ada ID unik yang di-generate ulang secara berbeda di beberapa tempat (gunakan satu util generator terpusat bila perlu ID acak).

## 3. Checklist Anti-Exploit (wajib per fitur baru yang melibatkan Remote)
- [ ] **Validasi tipe**: setiap argumen dari client dicek `typeof`/`type` sebelum dipakai.
- [ ] **Validasi batas nilai**: angka dicek rentang wajar (tidak negatif, tidak melebihi batas masuk akal) sebelum diproses.
- [ ] **Validasi kepemilikan/state**: pemain benar-benar memiliki item/skill/quest yang diklaim, dan dalam state yang valid (mis. tidak sedang dead, tidak di zona lain).
- [ ] **Rate limiting server-side**: debounce per-player untuk mencegah spam remote (cooldown dicek ulang di server, bukan hanya UI di-disable di client).
- [ ] **Tidak ada trust-by-default terhadap hasil kalkulasi client** (damage, jarak tembak, hasil crafting, dsb. dihitung ulang di server).
- [ ] **Tidak expose data berlebihan**: RemoteFunction hanya mengembalikan data yang memang boleh dilihat pemain terkait (jangan kirim seluruh tabel Config rahasia/loot table asli ke client jika tidak perlu).
- [ ] **Idempotensi transaksi**: aksi yang mengubah currency/item (beli, jual, buka chest, selesai quest) tidak bisa dobel-proses jika player klik cepat/berulang atau request datang dua kali.
- [ ] **Logging**: aksi ekonomi penting (perubahan currency besar, trading) dicatat log server untuk audit, bukan cuma diam-diam diproses.

## 4. Checklist Sebelum Menandai Fitur "Selesai"
Gunakan bersamaan dengan Definition of Done di `04_AI_AGENT_RULES.md` §2:
- [ ] Lolos checklist anti-hardcode di atas.
- [ ] Lolos checklist anti-exploit di atas (jika fitur melibatkan Remote/data pemain).
- [ ] Sudah dites manual di Studio, termasuk mencoba minimal satu skenario "nakal" (kirim nilai negatif/ekstrem, spam klik, dsb.) untuk memastikan server menolak dengan benar.
- [ ] Tidak meninggalkan `print()`/debug log berlebihan di kode produksi (boleh pakai flag debug terpusat bila perlu logging permanen).
- [ ] Progress tracker & changelog sudah diupdate (lihat `05_PROGRESS_TRACKER.md`, `07_CHANGELOG.md`).
