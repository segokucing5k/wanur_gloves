import 'package:flutter/material.dart';
import 'home_screen.dart'; // <--- Tujuan Akhir (Terminal)

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startLoadingAnimation();
  }

  void _startLoadingAnimation() async {
    // Simulasi loading bar jalan pelan-pelan (0% -> 100%)
    for (int i = 0; i <= 100; i++) {
      // Delay 25ms biar animasinya mulus (Total 2.5 detik)
      await Future.delayed(const Duration(milliseconds: 25)); 
      if(mounted) setState(() => _progress = i / 100);
    }
    
    // Kalau sudah penuh (100%), pindah ke Home Screen
    if(mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warna Biru Solid Terang (Sesuai gambar desain)
      backgroundColor: const Color(0xFF0066FF), 
      
      body: Stack(
        alignment: Alignment.center,
        children: [
          // --- LAYER 1: BACKGROUND SHAPE (HIASAN) ---
          // Ini yang kemarin sempat hilang, Mas balikin lagi posisinya di kiri bawah
          Positioned(
            bottom: -50, 
            left: -50,
            child: Opacity(
              opacity: 0.1, // Sangat tipis biar nyatu, tidak mengganggu teks
              child: Image.asset(
                'assets/edit_icon.png', // Pastikan file ini ada di assets
                width: 350, 
                fit: BoxFit.contain,
                // Kalau gambar blm ada, pakai kotak kosong biar gak error
                errorBuilder: (c,o,s) => const SizedBox(), 
              ),
            ),
          ),

          // --- LAYER 2: BULATAN PUTIH SAMAR (OPTIONAL) ---
          // Ini tambahan biar ada variasi texture seperti di desain asli
          Positioned(
            top: -100, 
            right: -50,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                 width: 300, height: 300,
                 decoration: const BoxDecoration(
                   shape: BoxShape.circle, 
                   color: Colors.white
                 ),
              ),
            ),
          ),

          // --- LAYER 3: KONTEN UTAMA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spacer ini mendorong konten ke tengah agak bawah
                const Spacer(flex: 2), 
                
                const Text(
                  "Loading...", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 24, 
                    fontWeight: FontWeight.bold
                  )
                ),
                
                const SizedBox(height: 15),
                
                // PROGRESS BAR
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24, // Jalur transparan
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // Isi putih
                  ),
                ),

                const Spacer(flex: 1),

                // BAGIAN SHAKE INTERACT
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.vibration, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "SHAKE SCREEN TO INTERACT!", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.0, 
                          fontSize: 12
                        )
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          )
        ],
      ),
    );
  }
}