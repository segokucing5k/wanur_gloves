import 'dart:async';
import 'package:flutter/material.dart';

class GloveData {
  // Nilai HX711 (Loadcell)
  final int hxValue; 
  // Tombol Keypad terakhir yang ditekan (misalnya 'f', 'g', 'h', 'j')
  final String lastKey; 

  GloveData({
    this.hxValue = 0,
    this.lastKey = 'N/A',
  });
}

class GloveProvider with ChangeNotifier {
  // TODO: Implement alternative data source (e.g., Bluetooth, HTTP, WebSocket)

  // --- STATE UTAMA ---
  GloveData _data = GloveData();
  bool _isConnected = false; // menandakan listener aktif
  bool _isScanning = false; // tidak digunakan lagi, tetap ada untuk UI

  // --- STATE KONFIGURASI TOMBOL (MAPPING) ---
  // Keymap awal (sesuai ESP32: f, g, h, j)
  Map<String, String> _keyMap = {
    'index1': 'f', 
    'index2': 'g', 
    'index3': 'h', 
    'index4': 'j',
  };

  // --- GETTERS ---
  GloveData get data => _data;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  Map<String, String> get keyMap => _keyMap;

  // ==============================================================
  // BAGIAN A: LOGIKA MAPPING & PENGIRIMAN DATA
  // ==============================================================
  
  // 1. Ubah Huruf Tombol (Di UI Flutter)
  void updateLocalKey(String fingerName, String newKey) {
    if (newKey.length != 1) return;
    _keyMap[fingerName] = newKey;
    notifyListeners();
    print("🔧 Mapping Lokal Update: $fingerName -> $newKey");
  }

  // 2. Kirim Keymap Baru ke ESP32
  Future<void> sendKeymapToESP() async {
    final keymapString = _keyMap['index1']! + _keyMap['index2']! + _keyMap['index3']! + _keyMap['index4']!;
    if (keymapString.length != 4) {
      print("❌ Gagal Kirim: Keymap tidak 4 karakter.");
      return;
    }
    // TODO: Implement sending keymap via Bluetooth/HTTP/WebSocket
    print("⚠️ sendKeymapToESP belum diimplementasikan");
  }

  // TODO: Implement alternative connection method (Bluetooth/HTTP/WebSocket)
  void startConnection() {
    print("⚠️ startConnection belum diimplementasikan");
    // TODO: Implement Bluetooth/HTTP/WebSocket connection here
  }

  // Tidak ada koneksi BLE lagi.

  // ==============================================================
  // BAGIAN E: CLEANUP
  // ==============================================================
  void disconnect() async {
    _isConnected = false;
    _data = GloveData(); // Reset data
    
    notifyListeners();
    print("✅ Terputus Sepenuhnya");
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  // Konstruktor: TODO - implement alternative connection
  GloveProvider() {
    // startConnection(); // Uncomment when implemented
    print("⚠️ GloveProvider initialized - koneksi belum diimplementasikan");
  }
}