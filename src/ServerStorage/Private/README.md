# Private
Data/tabel yang TIDAK BOLEH pernah direplikasi atau diakses client sama sekali
(mis. formula drop rate asli, seed anti-cheat, log internal).

Apapun yang butuh dibaca client (meski hanya sebagian) sebaiknya lewat
`Configs/` (ReplicatedStorage) atau dikirim terfilter lewat RemoteFunction —
jangan taruh data yang memang perlu dilihat client di sini.
