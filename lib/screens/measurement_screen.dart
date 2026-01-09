import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glove_provider.dart';
import '../models/session_model.dart'; 
import '../services/database_helper.dart'; 
import 'history_screen.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  bool _isMeasuring = false;

  @override
  Widget build(BuildContext context) {
    final glove = context.watch<GloveProvider>();
    
    // --- UPDATE LOGIKA SENSOR BERAT (LOAD CELL) ---
    // Data dari GloveData: gunakan 'hxValue' (integer). Asumsikan dalam gram.
    int grams = glove.data.hxValue;
    double kgValue = grams / 1000.0; 

    return Scaffold(
      backgroundColor: const Color(0xFF0B101F), // Deep Navy
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Back di Kiri Atas
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Back',
        ),
        title: const Text("WanurGlove", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.cyanAccent),
            onPressed: () {}, 
          )
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 10), 

          // --- BAGIAN 1: VISUAL HOLOGRAM (RESPONSIVE) ---
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // LOGO UTAMA
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Image.asset(
                    'assets/logo_aja.png', // Nama file sesuai kode kamu
                    fit: BoxFit.contain, 
                    errorBuilder: (c,o,s) => const Icon(Icons.touch_app, size: 100, color: Colors.cyanAccent),
                  ),
                ),
                
                // TEKS JUDUL
                Positioned(
                  bottom: 0,
                  left: 0, right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Grip Strength Test", 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.cyanAccent, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          shadows: [Shadow(color: Colors.cyan, blurRadius: 10)]
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Real-time Force Measurement", // Teks diupdate biar keren
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11)
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                )
              ],
            ),
          ),

          // --- BAGIAN 2: KARTU DATA (SCROLLABLE) ---
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF121A2D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 20)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        kgValue.toStringAsFixed(2), // Tampilkan 2 desimal (presisi timbangan)
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 50, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                      ),
                    ),
                    const Text("kg force", style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 20),
                    _buildBarRow("Left Hand", 38.0, Colors.teal.shade700),
                    const SizedBox(height: 10),
                    _buildBarRow("Right Hand", kgValue, Colors.cyanAccent),
                  ],
                ),
              ),
            ),
          ),

          // --- BAGIAN 3: TOMBOL KONTROL ---
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMeasuring ? Colors.redAccent : const Color(0xFF00BFA5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                      icon: Icon(_isMeasuring ? Icons.save : Icons.play_arrow, color: Colors.white),
                      label: Text(
                        _isMeasuring ? "STOP & SAVE" : "START MEASUREMENT",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: () async {
                        if (_isMeasuring) {
                          await _saveToDatabase(kgValue);
                        }
                        setState(() {
                          _isMeasuring = !_isMeasuring;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOutlineButton(
                          icon: Icons.history, 
                          label: "History",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                          }
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildOutlineButton(icon: Icons.settings, label: "Settings", onTap: (){}),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Status Bar Bawah
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusIndicator(
                  label: glove.isConnected ? "Sensor Ready" : "Scanning...",
                  color: glove.isConnected ? Colors.greenAccent : Colors.redAccent,
                  icon: glove.isConnected ? Icons.scale : Icons.bluetooth_searching, // Ikon Timbangan
                ),
                _buildStatusIndicator(label: "Tare: Auto", color: Colors.blueAccent, icon: Icons.refresh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA SIMPAN KE DATABASE ---
  Future<void> _saveToDatabase(double value) async {
    String status = "Normal";
    if (value > 30) status = "Strong"; // Threshold disesuaikan utk load cell
    else if (value < 10) status = "Weak";

    SessionModel session = SessionModel(
      kg: value,
      date: DateTime.now().toIso8601String(),
      duration: "5.0s",
      status: status,
    );

    await DatabaseHelper.instance.create(session);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Data ${value.toStringAsFixed(2)}kg berhasil disimpan!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  // --- WIDGET HELPERS ---
  Widget _buildBarRow(String label, double value, Color color) {
    // Normalisasi bar: Anggap max 60kg
    double percentage = (value / 60.0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage, minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 35, child: Text("${value.toStringAsFixed(1)}kg", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildOutlineButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 45,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 16, color: Colors.cyanAccent),
        label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildStatusIndicator({required String label, required Color color, required IconData icon}) {
    return Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10))]);
  }
}