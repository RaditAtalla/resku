# Storyboard Video Pitching 2 Menit - RESKU

Dokumen ini berisi panduan alur visual, narasi, dan demonstrasi teknologi untuk video pitching berdurasi **2 menit (120 detik)**. Storyboard ini dirancang agar mudah dipahami oleh juri, menunjukkan kemudahan penggunaan bagi siapa saja, menjelaskan teknologi offline-first, serta mendemonstrasikan cara kerjanya secara taktis.

---

## Ringkasan Alur Durasi (Total: 120 Detik)
* **00:00 - 00:30 (30 Detik)**: Pitching Masalah & Urgensi (Golden Hours & Blank Spot)
* **00:30 - 01:00 (30 Detik)**: Solusi RESKU & Aksesibilitas (Siapa pun Bisa Menggunakan)
* **01:00 - 01:30 (30 Detik)**: Demonstrasi Teknologi (BLE Mesh, Epidemic Routing, & Drone Data Mule)
* **01:30 - 02:00 (30 Detik)**: Pusat Komando & Pengambilan Keputusan Cepat (Local AI DSS & OSM)

---

## Detail Storyboard Per Segmen

### BAGIAN 1: PITCHING MASALAH & URGENSI (00:00 - 00:30)
**Fokus**: Membangun empati, memaparkan ancaman nyata rusaknya infrastruktur komunikasi saat bencana.

| Durasi | Visual (Adegan Video) | Audio (Narasi & Efek Suara) | Keterangan Teknologi |
| :--- | :--- | :--- | :--- |
| **00:00 - 00:15** | Layar dramatis. Footage gempa bumi atau cuaca ekstrem. Transisi cepat ke visual layar HP bertuliskan *"No Service"* atau *"Panggilan Darurat Saja"*. | **Voice Over (VO)**: *"Saat bencana melanda, infrastruktur seluler runtuh dalam hitungan detik. Tanpa sinyal, tanpa internet, korban terisolasi dalam kepanikan."* | Masalah: *Communication Blackout* akibat BTS mati daya. |
| **00:15 - 00:30** | Visual tim SAR di posko darurat yang kebingungan melihat peta kertas kosong. Jam analog berputar cepat di layar (menunjukkan *Golden 72 Hours* yang terbuang). | **VO**: *"Tim penyelamat berkejaran dengan 'Golden 72 Hours'. Tanpa informasi lapangan yang valid, pencarian korban kritis dilakukan secara acak dan lambat."* <br> *SFX: Detik jam berdetak kencang.* | Masalah: *Rescue Blind Spot* & keterlambatan triase medis. |

---

### BAGIAN 2: SOLUSI RESKU & AKSESIBILITAS (00:30 - 01:00)
**Fokus**: Memperkenalkan RESKU sebagai aplikasi penembus batas grid yang ramah bagi segala usia.

| Durasi | Visual (Adegan Video) | Audio (Narasi & Efek Suara) | Keterangan Teknologi |
| :--- | :--- | :--- | :--- |
| **00:30 - 00:45** | Logo **RESKU** muncul menyala orange. Transisi ke layar HP berdesain minimalis Strava-style. Menunjukkan jari seorang lansia dan anak kecil dengan mudah menekan tombol merah besar berlabel *"CRITICAL"*. | **VO**: *"Memperkenalkan RESKU. Solusi komunikasi darurat offline-first. Aplikasi ini dirancang sangat intuitif—tanpa konfigurasi rumit, siapa pun termasuk lansia dan anak-anak dapat melaporkan status mereka dalam satu ketukan."* | Kemudahan UX: *One-Tap Triage Form* dengan kontras tinggi untuk kondisi panik. |
| **00:45 - 01:00** | Layar HP korban menampilkan panduan pertolongan pertama (P3K) bergambar ilustrasi patah tulang tanpa koneksi internet. | **VO**: *"Aplikasi secara instan memandu korban melakukan pertolongan pertama secara mandiri lewat panduan medis P3K offline."* | Konten Edukasi: *Offline Markdown First Aid Guide*. |

---

### BAGIAN 3: DEMONSTRASI TEKNOLOGI & MEKANISME (01:00 - 01:30)
**Fokus**: Menjelaskan mesin di balik layar secara visual (bagaimana data berpindah tanpa pulsa/kuota).

| Durasi | Visual (Adegan Video) | Audio (Narasi & Efek Suara) | Keterangan Teknologi |
| :--- | :--- | :--- | :--- |
| **01:00 - 01:15** | Animasi grafis 3D/2D yang menunjukkan sinyal bluetooth memancar dari HP korban A, melompat ke HP korban B, hingga membentuk jaring laba-laba sinyal. | **VO**: *"Menggunakan teknologi Bluetooth Low Energy (BLE) Mesh, smartphone korban saling terhubung membentuk jaringan mandiri untuk menyebarkan data lokasi tanpa pulsa maupun kuota."* | Core Tech: **BLE Mesh ad-hoc network** & **Epidemic Routing algorithm**. |
| **01:15 - 01:30** | Relawan SAR berjalan memegang HP (atau drone terbang membawa modul kecil). Grafik menunjukkan data terkirim secara pasif dari jaring warga ke perangkat petugas saat berpapasan. | **VO**: *"Cukup dengan berjalan atau menerbangkan drone di sekitar area bencana, petugas mengumpulkan seluruh data survivor secara otomatis melalui metode data muling."* | Praktik Lapangan: **Passive Scan & Aggregate Sync** menggunakan data muling. |

---

### BAGIAN 4: PUSAT KOMANDO & PENGAMBILAN KEPUTUSAN (01:30 - 02:00)
**Fokus**: Demonstrasi dashboard rescuer dan kecerdasan buatan lokal yang membantu komandan.

| Durasi | Visual (Adegan Video) | Audio (Narasi & Efek Suara) | Keterangan Teknologi |
| :--- | :--- | :--- | :--- |
| **01:30 - 01:45** | Layar laptop dashboard menampilkan peta offline taktis dengan lingkaran radar berputar. Muncul antarmuka asisten AI yang menganalisis kebutuhan logistik dan anggaran (RAB) wilayah Alpha-7. | **VO**: *"Di posko utama, data di-load ke Dashboard Taktis. Didukung oleh Local AI Decision Support System yang berjalan 100% offline, sistem otomatis merekomendasikan prioritas evakuasi, kalkulasi RAB, dan logistik darurat."* | Core Tech: **Offline OpenStreetMap Cache** & **Local AI DSS (Small Language Model terkuantisasi)**. |
| **01:45 - 02:00** | Tim SAR berangkat menuju titik koordinat akurat. Korban berhasil diselamatkan dan dievakuasi. Layar diakhiri dengan teks penutup: *"RESKU: Bridging the Grid, Saving Lives Offline."* | **VO**: *"Dari kepanikan tanpa sinyal, menuju penyelamatan taktis yang terarah. RESKU: Menembus Batas Grid, Menyelamatkan Jiwa secara Offline."* <br> *SFX: Musik penutup dramatis dan inspiratif.* | Call to Action (CTA) & Brand Jargon. |
