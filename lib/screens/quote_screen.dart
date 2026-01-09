import 'dart:async';
import 'package:flutter/material.dart';
import 'loading_screen.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoadingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6E4FF), 
      body: Stack(
        children: [
          // --- LAYER 1: BACKGROUND SHAPE ---
          Positioned(
            top: 0, 
            right: 0,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/bg_shape_1.png',
                width: 250, 
                fit: BoxFit.contain,
                errorBuilder: (c,o,s)=>const SizedBox(),
              ),
            ),
          ),

          // --- LAYER 2: KONTEN TENGAH (YANG DIPERBAIKI) ---
          // Mas tambahkan widget 'Center' di sini sebagai pembungkus utama
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                // mainAxisSize: MainAxisSize.min artinya:
                // "Hei Column, jangan maruk ambil semua tinggi layar,
                // ambil secukupnya aja sesuai tinggi teks."
                // Karena sudah dibungkus Center, dia bakal otomatis ke tengah.
                mainAxisSize: MainAxisSize.min, 
                
                children: const [
                  Icon(Icons.format_quote_rounded, size: 60, color: Color(0xFF2F80ED)),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    "\"Health is the complete harmony of the body and soul.\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2A44),
                      height: 1.3,
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  Text(
                    "— ARISTOTLE",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F80ED),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}