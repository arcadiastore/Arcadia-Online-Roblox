# Controllers
Satu ModuleScript = satu Controller client untuk satu sistem, pasangan dari
Service di server dengan nama sistem yang sama (mis. `CombatController`
berpasangan dengan `CombatService`).

Controller menangani: input pemain, pemanggilan Remote ke server, efek visual/
prediksi lokal ringan, dan update UI. Controller TIDAK memutuskan hasil akhir
gameplay (damage final, reward, dsb.) — itu selalu keputusan server.

Belum ada Controller yang diimplementasikan — folder ini masih skeleton kosong.
