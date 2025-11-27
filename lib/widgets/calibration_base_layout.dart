import 'package:flutter/material.dart';

class CalibrationBaseLayout extends StatelessWidget {
  final Widget child; 
  
  // Logic Switcher: 
  // TRUE  = Menu Awal (Background Robot + Tangan sudah nempel)
  // FALSE = Edit/Calib (Background Biru Polos + Tangan Terpisah)
  final bool useRobotBackground; 

  const CalibrationBaseLayout({
    super.key,
    required this.child,
    this.useRobotBackground = false, // Default false (Biru)
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan gambar background
    String bgImage = useRobotBackground 
        ? 'assets/bg_menu.png'   // Gambar Menu (Robot + Tangan)
        : 'assets/bg_edit.png'; // Gambar Edit/Calib (Biru Polos)

    return Scaffold(
      body: Stack(
        alignment: Alignment.center, 
        children: [
          // --- LAYER 1: BACKGROUND ---
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // --- LAYER 2: HOLOGRAM TANGAN (KONDISIONAL) ---
          // Hanya munculkan tangan terpisah JIKA KITA TIDAK PAKAI BACKGROUND ROBOT.
          // (!useRobotBackground artinya: "Jika BUKAN background robot")
          if (!useRobotBackground)
            Align(
              alignment: const Alignment(0, -0.2), 
              child: Image.asset(
                'assets/tangan.png',
                height: 380, 
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) => const Icon(Icons.back_hand, size: 200, color: Colors.cyanAccent),
              ),
            ),

          // --- LAYER 3: KONTEN DINAMIS ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}