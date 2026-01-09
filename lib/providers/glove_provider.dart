import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
  // Firebase Realtime Database refs
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  DatabaseReference? _forceRef;
  DatabaseReference? _keymapRef;
  StreamSubscription<DatabaseEvent>? _forceSub;
  StreamSubscription<DatabaseEvent>? _keymapSub;

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

  // 2. Kirim Keymap Baru ke Firebase agar dibaca ESP32
  Future<void> sendKeymapToESP() async {
    final keymapString = _keyMap['index1']! + _keyMap['index2']! + _keyMap['index3']! + _keyMap['index4']!;
    if (keymapString.length != 4) {
      print("❌ Gagal Kirim: Keymap tidak 4 karakter.");
      return;
    }
    try {
      _keymapRef ??= _db.ref('/config/keymap');
      await _keymapRef!.set(keymapString);
      print("✅ Keymap ditulis ke Firebase: $keymapString");
    } catch (e) {
      print("❌ Error saat menulis keymap: $e");
    }
  }

  // Mulai listener Firebase (dipanggil otomatis saat provider dibuat)
  void startFirebase() {
    _forceRef = _db.ref('/status/force');
    _keymapRef = _db.ref('/config/keymap');

    _forceSub = _forceRef!.onValue.listen((event) {
      final val = event.snapshot.value;
      if (val is int) {
        _data = GloveData(hxValue: val, lastKey: _data.lastKey);
        _isConnected = true;
        notifyListeners();
      } else if (val is double) {
        _data = GloveData(hxValue: val.toInt(), lastKey: _data.lastKey);
        _isConnected = true;
        notifyListeners();
      }
    }, onError: (e) {
      _isConnected = false;
      notifyListeners();
      print('❌ Firebase force listener error: $e');
    });

    _keymapSub = _keymapRef!.onValue.listen((event) {
      final val = event.snapshot.value;
      if (val is String && val.length == 4) {
        _keyMap = {
          'index1': val[0],
          'index2': val[1],
          'index3': val[2],
          'index4': val[3],
        };
        notifyListeners();
        print('🔄 Keymap dari Firebase: $val');
      }
    }, onError: (e) {
      print('❌ Firebase keymap listener error: $e');
    });
  }

  // Tidak ada koneksi BLE lagi.

  // Parsing tidak diperlukan; nilai langsung dari Firebase.

  // ==============================================================
  // BAGIAN E: CLEANUP
  // ==============================================================
  void disconnect() async {
    await _forceSub?.cancel();
    await _keymapSub?.cancel();
    _forceSub = null;
    _keymapSub = null;
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

  // Konstruktor: otomatis start Firebase listeners
  GloveProvider() {
    startFirebase();
  }
}