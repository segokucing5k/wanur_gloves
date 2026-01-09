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
      backgroundColor: const Color(0xFF0B101F), // Deep Navy sesuai gambar
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "WanurGlove",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // INDIKATOR KONEKSI
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                glove.isConnected ? Icons.cloud_done : Icons.cloud,
                color: glove.isConnected ? Colors.greenAccent : Colors.cyanAccent,
              ),
              onPressed: () {
                if (glove.isConnected) {
                  glove.disconnect();
                } else {
                  glove.startConnection();
                }
              },
              tooltip: glove.isConnected ? "Disconnect" : "Connect",
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
            Text(
              "Siap latihan hari ini?",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            
            const SizedBox(height: 24),

            // --- KARTU 1: UKUR GENGGAMAN (POTENSIO) ---
            ActionCard(
              title: "Ukur Genggaman",
              subtitle: "Ukur kekuatan genggaman tangan",
              icon: Icons.back_hand,
              themeColor: const Color(0xFF00BFA5), // Hijau tosca aksen
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
              subtitle: "Cek respons sensor",
              icon: Icons.touch_app,
              themeColor: const Color(0xFF4A5240), // Olive gelap
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
            // Container(
            //   padding: const EdgeInsets.all(15),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF121A2D),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(
            //         glove.isConnected ? Icons.cloud_done : Icons.info_outline,
            //         color: glove.isConnected ? Colors.greenAccent : Colors.cyanAccent
            //       ),
            //       const SizedBox(width: 10),
            //       Expanded(
            //         // HAPUS FutureBuilder yang rumit. Gunakan data dari Provider saja.
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               glove.isConnected ? "Status: Terhubung" : "Status: Tidak ada data",
            //               style: const TextStyle(
            //                 fontSize: 14, 
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.white
            //               ),
            //             ),
            //             Text(
            //               glove.isConnected 
            //                 ? "Realtime Database aktif."
            //                 : "Tekan ikon awan untuk mulai listener.",
            //               style: const TextStyle(fontSize: 12, color: Colors.white70),
            //             ),
            //           ],
            //         ),
            //       )
            //     ],
            //   ),
            // ),

            const SizedBox(height: 24),
            // === AKSI KEYMAP ===
            // Container(
            //   padding: const EdgeInsets.all(15),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF121A2D),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         "Keymap",
            //         style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
            //       ),
            //       const SizedBox(height: 8),
            //       Text(
            //         "Saat ini: ${glove.keyMap['index1']}${glove.keyMap['index2']}${glove.keyMap['index3']}${glove.keyMap['index4']}",
            //         style: const TextStyle(color: Colors.white70),
            //       ),
            //       const SizedBox(height: 8),
            //       Row(
            //         children: [
            //           ElevatedButton(
            //             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
            //             onPressed: () async {
            //               await glove.sendKeymapToESP();
            //             },
            //             child: const Text("Kirim ke ESP", style: TextStyle(color: Colors.white)),
            //           ),
            //           const SizedBox(width: 8),
            //           OutlinedButton(
            //             onPressed: () {
            //               // contoh toggle cepat
            //               final cur = glove.keyMap;
            //               context.read<GloveProvider>().updateLocalKey('index1', cur['index1'] == 'f' ? 'a' : 'f');
            //             },
            //             child: const Text("Ubah Cepat"),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // )

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
        color: Colors.white70,
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