import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/calibration_base_layout.dart';
import '../providers/glove_provider.dart';

class TouchCalibrationScreen extends StatefulWidget {
  const TouchCalibrationScreen({super.key});

  @override
  State<TouchCalibrationScreen> createState() => _TouchCalibrationScreenState();
}

class _TouchCalibrationScreenState extends State<TouchCalibrationScreen> {
  final List<String> _sequence = ['pinky', 'ring', 'middle', 'index'];
  int _currentIndex = 0;
  bool _isAllDone = false;

  final Map<String, Offset> _offsets = {
    'pinky': const Offset(-80, -130),
    'ring': const Offset(-30, -200),
    'middle': const Offset(30, -200),
    'index': const Offset(80, -130),
  };

  @override
  Widget build(BuildContext context) {
    final glove = context.watch<GloveProvider>();
    
    // LOGIKA OTOMATIS
    if (!_isAllDone) {
      String targetFinger = _sequence[_currentIndex];
      // Mapping UI finger -> provider key
      final targetMapKey = _mapFingerKey(targetFinger);
      final targetAssignedKey = glove.keyMap[targetMapKey];
      final isPressed = (targetAssignedKey != null) &&
          (glove.data.lastKey.toString().toLowerCase() == targetAssignedKey.toLowerCase());
      if (isPressed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isAllDone) {
            setState(() {
              if (_currentIndex < _sequence.length - 1) {
                _currentIndex++; 
              } else {
                _isAllDone = true; 
              }
            });
          }
        });
      }
    }

    String currentFingerKey = _sequence[_currentIndex]; 
    // Ambil huruf yang dipetakan dari provider menggunakan key 'index1'..'index4'
    final currentMapKey = _mapFingerKey(currentFingerKey);
    String assignedChar = glove.keyMap[currentMapKey] ?? "?"; 
    String labelFinger = currentFingerKey.toUpperCase(); 

    return CalibrationBaseLayout(
      child: Stack(
        alignment: Alignment.center,
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
          // --- LAYER 1: UI ATAS & BAWAH (FIX TABRAKAN) ---
          // Kita pakai Column biar Header mentok atas, Footer mentok bawah
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // HEADER (Mentok Atas)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: _buildHeader(labelFinger, assignedChar),
              ),

              // FOOTER (Mentok Bawah)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildBottomControls(),
              ),
            ],
          ),

          // --- LAYER 2: BADGE HURUF (TETAP DI TENGAH) ---
          // Ini tetap pakai Stack/Transform biar nempel di jari tangan
          if (!_isAllDone)
            Transform.translate(
              offset: _offsets[currentFingerKey]!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50, height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 20)]
                    ),
                    child: Text(assignedChar, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 40)
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(String labelFinger, String assignedChar) {
    // Teks yang mau ditampilkan
    String text = _isAllDone 
        ? "KALIBRASI SUKSES!" 
        : "GERAKKAN JARI $labelFinger ($assignedChar)";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        // Kasih background gelap biar kalaupun kena tangan, teksnya tetep kebaca
        color: Colors.black87, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_isAllDone) {
      return SizedBox(
        width: 200, height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
          onPressed: () => Navigator.pop(context), 
          child: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20)
        ),
        child: const Text(
          "Menunggu sensor ditekan...", 
          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
        ),
      );
    }
  }

  // Helper lokal: map UI finger -> provider key ('index1'..'index4')
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