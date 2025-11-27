import 'package:flutter/material.dart';
import '../widgets/calibration_base_layout.dart';
import 'touch_edit_screen.dart';        // Import Halaman Edit
import 'touch_calibration_screen.dart'; // Import Halaman Kalibrasi

class TouchMenuScreen extends StatelessWidget {
  const TouchMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalibrationBaseLayout(
      // --- SETTING PENTING ---
      // TRUE = Pakai background 'bg_robot_menu.png' (Robot + Tangan Nempel)
      // Otomatis menyembunyikan tangan hologram terpisah biar tidak dobel/menumpuk.
      useRobotBackground: true, 
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          // Spacer ini gunanya mendorong tombol agak ke bawah
          // supaya tidak menutupi gambar tangan di background
          const Spacer(flex: 3), 
          
          // --- TOMBOL 1: KE MODE EDIT ---
          _buildBigButton(
            context, 
            "EDIT KEY MAPPING", 
            Icons.edit, 
            const Color(0xFF0F4C5C), // Warna Teal Gelap
            () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const TouchEditScreen())
              );
            }
          ),
          
          const SizedBox(height: 20),

          // --- TOMBOL 2: KE MODE KALIBRASI ---
          _buildBigButton(
            context, 
            "START CALIBRATION", 
            Icons.speed, 
            const Color(0xFF4A5240), // Warna Olive/Hijau Gelap
            () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const TouchCalibrationScreen())
              );
            }
          ),

          const Spacer(flex: 1),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Helper untuk membuat tombol besar yang seragam
  Widget _buildBigButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          shadowColor: color.withOpacity(0.5),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0
          ),
        ),
      ),
    );
  }
}