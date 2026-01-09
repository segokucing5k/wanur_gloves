import 'dart:async';
import 'dart:convert';
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
  // BLE UUIDs - Sesuai dengan ESP32 BleKeyboard Custom
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String charUUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // Single characteristic untuk TX & RX

  // BLE Variables
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic; // Untuk kirim DAN terima data
  StreamSubscription<List<int>>? _rxSubscription;
  List<ScanResult> _scanResults = [];

  // --- STATE UTAMA ---
  GloveData _data = GloveData();
  bool _isConnected = false;
  bool _isScanning = false;

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
  List<ScanResult> get scanResults => _scanResults;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // ==============================================================
  // BAGIAN A: CHECK BONDED DEVICES (untuk BleKeyboard)
  // ==============================================================

  // Check apakah device sudah paired/bonded
  Future<bool> isDeviceBonded(BluetoothDevice device) async {
    try {
      // Get list bonded devices
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      return bondedDevices.any((d) => d.remoteId == device.remoteId);
    } catch (e) {
      print("Error checking bonded devices: $e");
      return false;
    }
  }

  // Auto-connect ke bonded device (kalau ada WanurGlove)
  Future<bool> autoConnectBondedDevice() async {
    try {
      print("🔍 Checking for bonded WanurGlove devices...");
      final bondedDevices = await FlutterBluePlus.bondedDevices;

      if (bondedDevices.isEmpty) {
        print("⚠️ No bonded devices found");
        return false;
      }

      print("📱 Found ${bondedDevices.length} bonded device(s)");

      // Cari device yang sudah terhubung dengan service UUID kita
      for (var device in bondedDevices) {
        print(
            "🔍 Checking bonded device: ${device.platformName} (${device.remoteId})");

        // Connect dulu untuk cek services
        try {
          await device.connect(timeout: const Duration(seconds: 10));
          await Future.delayed(const Duration(milliseconds: 500));

          final services = await device.discoverServices();
          final hasWanurService = services.any((s) => s.uuid
              .toString()
              .toLowerCase()
              .contains(serviceUUID.toLowerCase()));

          if (hasWanurService) {
            print("✅ Found WanurGlove bonded device: ${device.platformName}");
            // Langsung connect menggunakan method yang sudah ada
            await connectToDevice(device);
            return true;
          } else {
            print("⚠️ Device tidak punya WanurGlove service, disconnect...");
            await device.disconnect();
          }
        } catch (e) {
          print("⚠️ Failed to check device ${device.platformName}: $e");
          try {
            await device.disconnect();
          } catch (_) {}
        }
      }

      print("⚠️ No WanurGlove device found in bonded devices");
      return false;
    } catch (e) {
      print("❌ Error in autoConnectBondedDevice: $e");
      return false;
    }
  }

  // ==============================================================
  // BAGIAN B: LOGIKA MAPPING & PENGIRIMAN DATA
  // ==============================================================

  // 1. Ubah Huruf Tombol (Di UI Flutter)
  void updateLocalKey(String fingerName, String newKey) {
    if (newKey.length != 1) return;
    _keyMap[fingerName] = newKey;
    notifyListeners();
    print("🔧 Mapping Lokal Update: $fingerName -> $newKey");
  }

  // 2. Kirim Keymap Baru ke ESP32 via BLE
  Future<void> sendKeymapToESP() async {
    final keymapString = _keyMap['index1']! +
        _keyMap['index2']! +
        _keyMap['index3']! +
        _keyMap['index4']!;
    if (keymapString.length != 4) {
      print("❌ Gagal Kirim: Keymap tidak 4 karakter.");
      return;
    }

    if (_dataCharacteristic == null || !_isConnected) {
      print("❌ BLE belum terhubung. Tidak bisa kirim keymap.");
      return;
    }

    try {
      // Kirim sebagai bytes
      await _dataCharacteristic!.write(utf8.encode(keymapString));
      print("✅ Keymap dikirim via BLE: $keymapString");
    } catch (e) {
      print("❌ Error kirim keymap: $e");
    }
  }

  // ==============================================================
  // BAGIAN C: BLE SCAN & CONNECT
  // ==============================================================

  // Scan untuk mencari device BLE
  Future<void> startScan() async {
    if (_isScanning) return;

    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    try {
      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        // Sort: WanurGlove devices first (by service UUID)
        _scanResults = results;
        _scanResults.sort((a, b) {
          final aHasService = a.advertisementData.serviceUuids.any((uuid) =>
              uuid.toString().toLowerCase() == serviceUUID.toLowerCase());
          final bHasService = b.advertisementData.serviceUuids.any((uuid) =>
              uuid.toString().toLowerCase() == serviceUUID.toLowerCase());

          // WanurGlove devices di atas
          if (aHasService && !bHasService) return -1;
          if (!aHasService && bHasService) return 1;

          // Sort by signal strength (RSSI)
          return b.rssi.compareTo(a.rssi);
        });
        notifyListeners();
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();

      _isScanning = false;
      notifyListeners();
      print("✅ Scan selesai. Ditemukan ${_scanResults.length} devices.");
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      print("❌ Error saat scan: $e");
    }
  }

  // Connect ke device BLE
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print(
          "🔄 Connecting to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}...");

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      print("✅ Connected to device!");

      // Discover services
      await _discoverServices();

      // Verify connection
      if (_dataCharacteristic == null) {
        throw Exception("WanurGlove service not found on this device");
      }
    } catch (e) {
      print("❌ Error connecting: $e");
      _isConnected = false;
      _connectedDevice = null;
      _dataCharacteristic = null;
      notifyListeners();
      rethrow; // Throw error ke UI untuk ditampilkan
    }
  }

  // Discover BLE services dan setup characteristics
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    try {
      print("🔍 Discovering services...");
      List<BluetoothService> services =
          await _connectedDevice!.discoverServices();

      print("📋 Found ${services.length} services");

      for (BluetoothService service in services) {
        print("   Service: ${service.uuid}");

        // Cari service WanurGlove
        if (service.uuid.toString().toLowerCase() ==
            serviceUUID.toLowerCase()) {
          print("✅ Found WanurGlove Service!");

          for (BluetoothCharacteristic char in service.characteristics) {
            String charUuidStr = char.uuid.toString().toLowerCase();
            print("      Char: $charUuidStr");
            print(
                "      Properties: notify=${char.properties.notify}, write=${char.properties.write}");

            // Characteristic utama - untuk kirim DAN terima data
            if (charUuidStr == charUUID.toLowerCase()) {
              _dataCharacteristic = char;
              print("      ✅ This is our characteristic!");

              // Subscribe untuk terima data (notify)
              if (char.properties.notify) {
                await char.setNotifyValue(true);
                _rxSubscription =
                    char.lastValueStream.listen(_handleIncomingData);
                print("      ✅ Notify subscribed!");
              }

              // Check write capability
              if (char.properties.write ||
                  char.properties.writeWithoutResponse) {
                print("      ✅ Write ready!");
              }
            }
          }
        }
      }

      if (_dataCharacteristic != null) {
        print("🎉 BLE setup complete!");
      } else {
        print("⚠️ Warning: WanurGlove characteristic tidak ditemukan");
        print("💡 Pastikan ESP32 sudah running dengan UUID yang benar");
      }
    } catch (e) {
      print("❌ Error discovering services: $e");
      rethrow;
    }
  }

  // Handle data yang diterima dari ESP32
  void _handleIncomingData(List<int> value) {
    try {
      // Data dari ESP32 adalah angka loadcell (sebagai string)
      String received = utf8.decode(value);
      print("📥 Received: $received");

      // Parse sebagai integer
      int loadcellValue = int.tryParse(received.trim()) ?? 0;

      // Update data
      _data = GloveData(hxValue: loadcellValue, lastKey: _data.lastKey);
      notifyListeners();
    } catch (e) {
      print("❌ Error parsing data: $e");
    }
  }

  // ==============================================================
  // BAGIAN E: CLEANUP
  // ==============================================================
  Future<void> disconnect() async {
    try {
      // Cancel subscription
      await _rxSubscription?.cancel();
      _rxSubscription = null;

      // Disconnect device
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _connectedDevice = null;
      _dataCharacteristic = null;
      _isConnected = false;
      _data = GloveData(); // Reset data

      notifyListeners();
      print("✅ BLE Disconnected");
    } catch (e) {
      print("❌ Error during disconnect: $e");
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  // Konstruktor
  GloveProvider() {
    print("✅ GloveProvider initialized dengan BLE support");
  }
}
