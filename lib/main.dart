import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// IMPORT PROVIDER (OTAK APLIKASI)
import 'providers/glove_provider.dart';

// IMPORT SCREEN AWAL (GERBONG PERTAMA)
import 'screens/splash_screen.dart';

void main() {
  // Pastikan binding initialized sebelum menjalankan app (Best Practice)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // BUNGKUS APLIKASI DENGAN PROVIDER
    // Ini supaya 'GloveProvider' bisa diakses dari Splash, Home, Game, dll.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GloveProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wanur Glove',
      
      // Hilangkan banner "DEBUG" di pojok kanan atas
      debugShowCheckedModeBanner: false,

      // --- TEMA APLIKASI ---
      // Kita atur warna default biar seragam sama desain UI kamu
      theme: ThemeData(
        useMaterial3: true, // Pakai gaya desain terbaru (Material 3)
        brightness: Brightness.light, // Base-nya terang (sesuai Home Screen putih)
        
        // Warna Utama (Biru Asklepios)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F80ED), 
          primary: const Color(0xFF2F80ED),
          secondary: const Color(0xFF27AE60), // Hijau untuk aksen
        ),
        
        // Font default (Opsional, pakai default Flutter juga oke)
        fontFamily: 'Roboto', 
        
        // Style Background Scaffold default
        scaffoldBackgroundColor: Colors.white,
      ),

      // --- TITIK MULAI (ENTRY POINT) ---
      // Kita mulai dari Gerbong 1: Splash Screen (Logo)
      // Alurnya nanti: Splash -> Quote -> Loading -> Home
      home: const SplashScreen(),
    );
  }
}