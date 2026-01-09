import 'dart:async';
import 'package:flutter/material.dart';
import 'quote_screen.dart'; // <--- Sambungkan ke Gerbong 2 (Quote)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tahan 2 detik di Logo, lalu pindah ke Quote
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuoteScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Positioned(
          //   top: 16,
          //   left: 16,
          //   child: IconButton(
          //     icon: const Icon(Icons.arrow_back, color: Colors.black54),
          //     onPressed: () {
          //       if (Navigator.of(context).canPop()) {
          //         Navigator.of(context).pop();
          //       }
          //     },
          //     tooltip: 'Back',
          //   ),
          // ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                // [ASET] Ganti dengan gambar logomu 'Splash.png'
                // Pastikan file ada di folder assets/
                // Jika aset tidak ada, gunakan ikon default
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Image(
                    image: AssetImage('assets/logo_aja.png'),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "WANUR",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2A44),
                    letterSpacing: -1.0,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "REHABMEDICS",
                  style: TextStyle(
                    letterSpacing: 2.0,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}