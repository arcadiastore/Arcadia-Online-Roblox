# Shared
ModuleScript yang dipakai BERSAMA oleh client dan server: fungsi util murni,
tipe/struct data (mis. definisi tipe lewat komentar Luau), konstanta non-rahasia
yang bukan bagian dari balance game (mis. nama folder Remote, key attribute).

**Tidak boleh masuk sini:**
- Data balance game (masuk `Configs/`)
- Logic yang memutuskan hasil gameplay (masuk `Services/` di server)
- Data rahasia yang tidak boleh dilihat client (masuk `ServerStorage/Private/`)
