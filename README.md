<<<<<<< HEAD
# Smart EA MT5 - Super Agresif

Expert Advisor (EA) MT5 super agresif namun tetap aman. EA ini mampu melakukan 20–30 trade per hari dengan drawdown rendah (<5%) dan target pertumbuhan balance cepat (5–12% per minggu).

## Fitur Utama

- **Multi-strategy**: Scalping, Breakout, Reversal, News, Trend Following
- **Risk engine adaptif**: Menyesuaikan berdasarkan kondisi market, hasil trading, dan confidence score
- **AI strategy selector**: Pemilihan strategi berdasarkan regime pasar + sentimen berita BytePlus NLP
- **Confidence scoring**: Penilaian kepercayaan untuk setiap sinyal trading dengan penyesuaikan otomatis
- **Auto-learning**: Pembelajaran dan retrain otomatis setiap 2 hari berdasarkan evaluasi
- **Logging otomatis**: Integrasi ke database PostgreSQL via PostgREST dan Persistent Knowledge Graph untuk error/critical logs
- **BytePlus NLP**: Analisis sentimen berita menggunakan ModelArk LLM untuk strategi adaptif
- **Fitur keamanan**: Trailing stop dinamis berdasarkan ATR/confidence, dynamic TP/SL adaptif, filter sesi waktu (overlap London/NY), hedging opsional untuk manajemen risiko tambahan
- **Knowledge Graph**: Integrasi dengan Trae.ai MCP untuk penyimpanan pengetahuan dan logging jadwal
- **Deployment**: Dukungan Docker Compose untuk lokal/cloud, integrasi GitHub untuk manajemen repo

## Struktur Folder

```
├── ai/                  # Modul AI dan backend
│   ├── logger.py        # Logging ke database
│   ├── model_loop.py    # Auto-learning dan retrain
│   ├── risk_engine.py   # Manajemen risiko adaptif
│   ├── scheduler.py     # Scheduler untuk retrain otomatis
│   ├── server_api.py    # API server Flask
│   └── strategy_selector.py # Pemilihan strategi AI
├── config/              # File konfigurasi
│   └── trae_agent.yaml  # Konfigurasi Trae.ai MCP agent
├── ea/                  # Expert Advisor MT5
│   ├── smart_ea.ex5     # EA terkompilasi
│   └── smart_ea.mq5     # Source code EA
├── logs/                # Folder log
└── requirements.txt     # Dependensi Python
```

## Setup dan Instalasi

### Prasyarat

- MetaTrader 5
- Python 3.8+
- PostgreSQL (opsional, untuk logging)
- Trae.ai MCP (opsional, untuk knowledge graph)
- Docker dan Docker Compose (untuk deployment cloud/lokal)

### Instalasi Docker pada Windows

1. Unduh dan instal Docker Desktop dari [situs resmi Docker](https://www.docker.com/products/docker-desktop).
2. Aktifkan WSL 2 jika diperlukan.
3. Verifikasi instalasi dengan menjalankan `docker --version` di PowerShell.

### Langkah Instalasi

1. **Setup Python Backend**

   ```bash
   # Install dependensi
   pip install -r requirements.txt
   
   # Set API key BytePlus untuk analisis sentimen
   set BYTEPLUS_API_KEY=your_api_key  # Windows
   export BYTEPLUS_API_KEY=your_api_key  # Linux/Mac
   
   # Jalankan server API
   python ai/server_api.py
   
   # Jalankan scheduler di terminal terpisah
   python ai/scheduler.py
   ```

2. **Deployment dengan Docker**

   Pastikan Docker berjalan, kemudian:

   ```bash
   docker-compose up -d
   ```

   Ini akan menjalankan API server, scheduler, PostgREST, dan database PostgreSQL dalam container.

2. **Setup MT5**

   - Kompilasi `smart_ea.mq5` di MetaEditor
   - Attach EA ke chart XAUUSD (timeframe H1 direkomendasikan)
   - Sesuaikan parameter input sesuai kebutuhan

3. **Setup Database (Opsional)**

   - Buat database PostgreSQL
   - Jalankan PostgREST untuk API
   - Update URL di `logger.py` dan `trae_agent.yaml`

4. **Setup Trae.ai MCP (Opsional)**

   - Pastikan Trae.ai MCP server berjalan
   - Gunakan konfigurasi di `trae_agent.yaml`

## Penggunaan

- EA akan otomatis memilih strategi terbaik berdasarkan kondisi pasar
- Monitoring log di MT5 dan database untuk analisis kinerja
- Retrain model dilakukan otomatis setiap 2 hari
- Gunakan Trae.ai MCP untuk melihat knowledge graph

## Konfigurasi

### Parameter EA

- **LotSize**: Ukuran lot default (0.01 direkomendasikan untuk awal)
- **MagicNumber**: Nomor identifikasi untuk order EA
- **ApiUrl**: URL API untuk strategi (default: http://localhost:5000/strategy)
- **RiskUrl**: URL API untuk manajemen risiko
- **UpdateUrl**: URL API untuk update win-rate
- **LogUrl**: URL API untuk logging

### Konfigurasi Server

Edit `server_api.py` untuk mengubah host/port server Flask.

## Troubleshooting

- **API Error**: Pastikan server Flask berjalan dan URL benar
- **BytePlus Error**: Verifikasi API key dan koneksi internet
- **Database Error**: Periksa koneksi PostgreSQL dan PostgREST

## Pengembangan Lanjutan

- Untuk deployment cloud, upload proyek ke server cloud (e.g., AWS, GCP) dan jalankan docker-compose.
- Integrasikan dengan Trae.ai MCP untuk offloading tugas seperti retrain ke cloud.
- Tambahkan strategi baru di `strategy_selector.py`
- Kustomisasi risk engine di `risk_engine.py`
- Integrasi sumber data tambahan untuk analisis

## Lisensi

Proprietary - All rights reserved

## Deployment Cloud

1. Upload proyek ke GitHub menggunakan MCP GitHub tools (create_repository, push_files).
2. Di server cloud (e.g., AWS EC2), clone repo dan jalankan `docker-compose up -d`.
3. Konfigurasi environment variables untuk API keys dan database URL di docker-compose.yaml.
4. Gunakan MCP Docker untuk manage container (create-container, get-logs).
5. Monitor via dashboard di http://server_ip:5000/.
6. Integrasikan MCP Fetch untuk pengambilan data real-time dan Persistent Knowledge Graph untuk logging.
=======
# smart-ea-mt5
Aggressive MT5 EA for XAUUSD with AI integration
>>>>>>> 1e4ea06ff4e0ceee8c5a2edf011aea7b5776aa71
