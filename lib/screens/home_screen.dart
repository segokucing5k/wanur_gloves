import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glove_provider.dart';
import 'measurement_screen.dart';    // Page Genggaman
import 'touch_menu_screen.dart';     // Page Menu Kalibrasi

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. AMBIL DATA PROVIDER
    final glove = context.watch<GloveProvider>();

    // 2. LOGIKA SAPAAN OTOMATIS (MAGIC DISINI 🌟)
    // Kita ambil jam saat ini (format 0-23)
    var hour = DateTime.now().hour;
    String greeting;

    if (hour < 11) {
      greeting = "Selamat Pagi";
    } else if (hour < 15) {
      greeting = "Selamat Siang";
    } else if (hour < 19) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Abu-abu putih bersih
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Back',
        ),
        title: const Text(
          "HandGrip Rehab",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // INDIKATOR & TOMBOL CONNECT
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                glove.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                color: glove.isConnected ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                if (glove.isConnected) {
                  glove.disconnect();
                } else {
                  glove.scanAndConnect();
                }
              },
              tooltip: glove.isConnected ? "Disconnect Glove" : "Scan & Connect",
            ),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER TEXT DINAMIS ---
            Text(
              "Halo, $greeting!", // <--- PAKAI VARIABEL DISINI
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A44)),
            ),
            Text(
              "Siap latihan hari ini?",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            
            const SizedBox(height: 24),

            // --- KARTU 1: UKUR GENGGAMAN (POTENSIO) ---
            ActionCard(
              title: "Ukur Genggaman",
              subtitle: "Ukur kekuatan genggam (Slider)",
              icon: Icons.back_hand,
              themeColor: const Color(0xFF2F80ED), // Biru
              buttonText: "Mulai Ukur",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MeasurementScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // --- KARTU 2: GAME KALIBRASI (TOUCH SENSOR) ---
            ActionCard(
              title: "Kalibrasi Jari",
              subtitle: "Cek respons sensor sentuh (Touch)",
              icon: Icons.touch_app,
              themeColor: const Color(0xFF27AE60), // Hijau
              buttonText: "Mulai Kalibrasi",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TouchMenuScreen()),
                );
              },
            ),

            const SizedBox(height: 24),
            
            // STATUS INFO
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      glove.isConnected 
                        ? "Status: Perangkat Terhubung. Siap digunakan."
                        : "Status: Belum Terhubung. Tekan ikon Bluetooth di atas.",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- WIDGET KARTU (Tidak Berubah) ---
class ActionCard extends StatelessWidget {
  final String title, subtitle, buttonText;
  final IconData icon;
  final Color themeColor;
  final VoidCallback onPressed;

  const ActionCard({
    super.key,
    required this.title, required this.subtitle, required this.buttonText,
    required this.icon, required this.themeColor, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: themeColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              child: Text(buttonText, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}