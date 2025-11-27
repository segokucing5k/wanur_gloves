import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  // ==============================================================
  // 1. UUID & STATE
  // ==============================================================
  
  // UUID ESP32 (Harus sama persis dengan di gloves.ino)
  final Guid SERVICE_UUID = Guid("12345678-1234-1234-1234-1234567890ab");
  final Guid CHAR_NOTIFY_UUID = Guid("abcd1234-1234-1234-1234-1234567890ab"); // Kirim sensor -> Flutter (NOTIFY)
  final Guid CHAR_WRITE_UUID = Guid("eebb5566-1234-1234-1234-1234567890ab"); // Kirim keymap -> ESP32 (WRITE)

  // --- STATE UTAMA ---
  GloveData _data = GloveData();
  bool _isConnected = false;
  bool _isScanning = false;
  
  // --- STATE KONEKSI INTERAL ---
  BluetoothDevice? _device;
  StreamSubscription? _dataStream;
  StreamSubscription? _connectionStream;
  
  // --- CHARACTERISTICS ---
  BluetoothCharacteristic? _notifyChar; // Untuk menerima data (NOTIFY)
  BluetoothCharacteristic? _writeChar; // Untuk mengirim data (WRITE)

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

  // 2. Kirim Keymap Baru ke ESP32 (FUNGSI PENTING BARU)
  Future<void> sendKeymapToESP() async {
    if (_writeChar == null || !_isConnected) {
      print("❌ Gagal Kirim: Characteristic WRITE atau koneksi tidak siap.");
      return;
    }

    // Ambil 4 karakter dari keymap dalam urutan ESP32 (f, g, h, j)
    String keymapString = _keyMap['index1']! + _keyMap['index2']! + _keyMap['index3']! + _keyMap['index4']!;

    if (keymapString.length != 4) {
      print("❌ Gagal Kirim: Keymap tidak 4 karakter.");
      return;
    }

    try {
      // Konversi String menjadi Uint8List (Byte Array)
      List<int> bytes = keymapString.codeUnits;
      
      await _writeChar!.write(
        Uint8List.fromList(bytes),
        withoutResponse: true,
      );
      print("✅ Keymap dikirim: $keymapString");
    } catch (e) {
      print("❌ Error saat mengirim keymap: $e");
    }
  }

  // ==============================================================
  // BAGIAN B: FUNGSI SCAN DAN KONEK
  // (Logika SCAN dan Connect tetap sama, hanya ganti UUID)
  // ==============================================================
  Future<void> scanAndConnect() async {
    print("🔍 Memulai Scan...");
    // ... (Logika scan & error handling) ...
    // (Tambahkan permission_handler jika belum)

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print("❌ Error: Bluetooth HP Mati!");
        return;
      }

      _isScanning = true;
      notifyListeners();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
        withNames: ["ESP32-Gloves"] // Filter lebih cepat berdasarkan nama GATT
      );

      // Cari hasil scan dan filter
      var results = await FlutterBluePlus.scanResults.first;
      BluetoothDevice? foundDevice;

      for (ScanResult r in results) {
          if (r.device.platformName == "ESP32-Gloves") {
            foundDevice = r.device;
            break;
          }
      }

      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();

      if (foundDevice != null) {
        print("✅ Ketemu Device: ${foundDevice.platformName}");
        _connect(foundDevice);
      } else {
        print("⏱️ Device 'ESP32-Gloves' tidak ditemukan.");
      }
      
    } catch (e) {
      print("❌ Error saat scan: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  // ==============================================================
  // BAGIAN C: PROSES KONEKSI INTERNAL
  // ==============================================================
  Future<void> _connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      
      _device = device;
      _isConnected = true;
      notifyListeners();

      _connectionStream = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print("⚠️ Koneksi terputus!");
          disconnect();
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        if (service.uuid == SERVICE_UUID) {
          for (var characteristic in service.characteristics) {
            
            if (characteristic.uuid == CHAR_NOTIFY_UUID) {
              _notifyChar = characteristic;
              await characteristic.setNotifyValue(true);
              _dataStream = characteristic.lastValueStream.listen(_parseData);
              print("🎉 CHAR_NOTIFY SIAP!");
            
            } else if (characteristic.uuid == CHAR_WRITE_UUID) {
              _writeChar = characteristic;
              print("🎉 CHAR_WRITE SIAP!");
            }
          }
        }
      }
      
      if (_notifyChar == null || _writeChar == null) {
        print("❌ Service/Characteristic (Notify atau Write) Salah!");
        disconnect();
      }
      
    } catch (e) {
      print("❌ Gagal Konek: $e");
      disconnect();
    }
  }

  // ==============================================================
  // BAGIAN D: PARSING DATA (DARI JSON STRING)
  // ==============================================================
  void _parseData(List<int> raw) {
    if (raw.isEmpty) return;

    try {
      // 1. Konversi Byte Array menjadi String JSON
      String jsonString = utf8.decode(raw); 
      
      // 2. Parsing JSON
      final Map<String, dynamic> decodedJson = jsonDecode(jsonString);

      // 3. Update GloveData
      _data = GloveData(
        // hx dikirim sebagai long, di Dart dibaca sebagai int
        hxValue: decodedJson['hx'] ?? 0, 
        // key dikirim sebagai string
        lastKey: decodedJson['key'] ?? 'N/A',
      );

      notifyListeners();
      
    } catch (e) {
      print("❌ Parsing JSON Error: $e | Raw Data: ${raw.toString()}");
    }
  }

  // ==============================================================
  // BAGIAN E: CLEANUP
  // ==============================================================
  void disconnect() async {
    await _dataStream?.cancel();
    await _connectionStream?.cancel();
    await _device?.disconnect();
    
    _dataStream = null;
    _connectionStream = null;
    _device = null;
    _notifyChar = null;
    _writeChar = null;
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
}