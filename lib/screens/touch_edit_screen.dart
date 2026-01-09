import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/calibration_base_layout.dart';
import '../providers/glove_provider.dart';

class TouchEditScreen extends StatelessWidget {
  const TouchEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalibrationBaseLayout(
      // useRobotBackground: false, <-- DEFAULTNYA SUDAH FALSE (BIRU), JADI AMAN.
      child: Stack(
        children: [
          // Back button top-left
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          ),
          // HEADER ATAS
          const Positioned(
            top: 60, left: 0, right: 0,
            child: Center(
              child: Text(
                "EDIT TOMBOL", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
              ),
            ),
          ),

          // AREA TENGAH: BADGE HURUF (Visualisasi)
          // Kita pakai Consumer biar update real-time kalau key berubah atau sensor ditekan
          Consumer<GloveProvider>(
            builder: (context, glove, child) {
              return Stack(
                children: [
                  _buildBadge(glove, 'pinky', const Offset(-80, -130)),
                  _buildBadge(glove, 'ring', const Offset(-30, -200)),
                  _buildBadge(glove, 'middle', const Offset(30, -200)),
                  _buildBadge(glove, 'index', const Offset(80, -130)),
                ],
              );
            },
          ),

          // AREA BAWAH: 4 TOMBOL JARI (Untuk memicu Dialog Edit)
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _FingerEditBtn(fingerKey: 'pinky', label: 'LITTLE FINGER')),
                    const SizedBox(width: 16),
                    Expanded(child: _FingerEditBtn(fingerKey: 'ring', label: 'RING FINGER')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _FingerEditBtn(fingerKey: 'middle', label: 'MIDDLE FINGER')),
                    const SizedBox(width: 16),
                    Expanded(child: _FingerEditBtn(fingerKey: 'index', label: 'INDEX FINGER')),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget Badge Huruf Melayang (W, A, S, D)
  Widget _buildBadge(GloveProvider glove, String fingerKey, Offset offset) {
    // Cek apakah jari sedang ditekan?
    // Mapping finger UI -> key di provider
    final mapKey = _toProviderKey(fingerKey);
    final assignedKey = glove.keyMap[mapKey];
    // Cek apakah jari sedang ditekan berdasarkan lastKey dari ESP
    final isActive = (assignedKey != null) &&
        (glove.data.lastKey.toString().toLowerCase() == assignedKey.toLowerCase());

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: offset,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), // Efek kedip halus
          width: 45, height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Kalau jari ditekan: HIJAU TERANG. Kalau diam: HIJAU GELAP.
            color: isActive ? Colors.greenAccent : const Color(0xFF4A5240),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white30),
            boxShadow: isActive 
                ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.8), blurRadius: 20)] 
                : [],
          ),
          child: Text(
            assignedKey ?? "?",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }

  // Helper: konversi nama finger UI -> key di provider ('index1'..'index4')
  String _toProviderKey(String fingerKey) {
    switch (fingerKey) {
      case 'index':
        return 'index1';
      case 'middle':
        return 'index2';
      case 'ring':
        return 'index3';
      case 'pinky':
        return 'index4';
      default:
        return fingerKey;
    }
  }
}

// Widget Tombol Bawah (Dipisah biar rapi)
class _FingerEditBtn extends StatelessWidget {
  final String fingerKey; // 'pinky', 'index', dll
  final String label;     // 'LITTLE FINGER'

  const _FingerEditBtn({required this.fingerKey, required this.label});

  @override
  Widget build(BuildContext context) {
    final glove = context.watch<GloveProvider>();
    final mapKey = _mapFingerKey(fingerKey);
    final assignedKey = glove.keyMap[mapKey] ?? '?';
    final isPressedRealTime = glove.data.lastKey.toLowerCase() == assignedKey.toLowerCase();

    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // Tombol ikut menyala kalau sensor ditekan
          backgroundColor: isPressedRealTime ? const Color(0xFF00BFA5) : const Color(0xFF121A2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.cyanAccent, width: 1)
          ),
        ),
        onPressed: () => _showEditDialog(context, glove, fingerKey),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: isPressedRealTime ? Colors.white : Colors.white70, fontSize: 10)),
            Text(
              "[ $assignedKey ]",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Popup Dialog untuk ganti huruf
  void _showEditDialog(BuildContext context, GloveProvider glove, String fingerKey) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B101F),
        title: Text("Edit Tombol $label", style: const TextStyle(color: Colors.cyanAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan 1 tombol keyboard:", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLength: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "A-Z", 
                hintStyle: TextStyle(color: Colors.white24),
                counterText: ""
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final mapKey = _mapFingerKey(fingerKey);
                glove.updateLocalKey(mapKey, controller.text.toLowerCase());
                glove.sendKeymapToESP();
              }
              Navigator.pop(ctx);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Lokal helper untuk mapping UI key -> provider key
  String _mapFingerKey(String fingerKey) {
    switch (fingerKey) {
      case 'index':
        return 'index1';
      case 'middle':
        return 'index2';
      case 'ring':
        return 'index3';
      case 'pinky':
        return 'index4';
      default:
        return fingerKey;
    }
  }
}