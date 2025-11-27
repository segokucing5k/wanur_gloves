import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Format Tanggal
import '../models/session_model.dart';
import '../services/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SessionModel>> _historyData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi Refresh Data
  void _loadData() {
    setState(() {
      _historyData = DatabaseHelper.instance.readAllSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Back',
        ),
        title: const Text("Riwayat Latihan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.cyanAccent), // Tombol back warna cyan
        actions: [
          // Tombol Hapus Semua (Buat Testing)
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () async {
              await DatabaseHelper.instance.deleteAll();
              _loadData();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Placeholder Grafik (Visual Saja)
          Container(
            height: 100, margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan.withOpacity(0.2)),
            ),
            child: Center(child: Icon(Icons.show_chart, size: 40, color: Colors.cyan.withOpacity(0.5))),
          ),

          // LIST DATA DARI DATABASE
          Expanded(
            child: FutureBuilder<List<SessionModel>>(
              future: _historyData,
              builder: (context, snapshot) {
                // 1. Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                }
                // 2. Error
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }
                // 3. Data Kosong
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 50, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        const Text("Belum ada data latihan", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 4. Ada Data -> Tampilkan List
                final sessions = snapshot.data!;
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(sessions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // KARTU ITEM HISTORY
  Widget _buildHistoryCard(SessionModel item) {
    // Parsing Tanggal
    DateTime date = DateTime.parse(item.date);
    String dayStr = DateFormat('d MMM y').format(date);
    String timeStr = DateFormat('HH:mm').format(date);

    // Warna Status
    Color statusColor = Colors.blueAccent;
    if (item.status == "Strong") statusColor = Colors.greenAccent;
    if (item.status == "Weak") statusColor = Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Ikon Tangan Kotak
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: statusColor),
          ),
          const SizedBox(width: 16),
          
          // Data Tengah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${item.kg.toStringAsFixed(1)} kg",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Courier'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Text("$dayStr  •  $timeStr", style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ],
            ),
          ),

          // Data Kanan
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text("Duration: ${item.duration}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}