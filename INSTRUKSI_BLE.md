# 📘 Implementasi BLE untuk WanurGlove

## ✅ Yang Sudah Dikerjakan:

### 1. **Dependencies**
- ✅ `flutter_blue_plus: ^1.32.12` sudah ditambahkan di `pubspec.yaml`
- ✅ `flutter pub get` sudah dijalankan

### 2. **GloveProvider** 
- ✅ Import `flutter_blue_plus`
- ✅ UUID disesuaikan dengan ESP32 BleKeyboard Custom
- ✅ Method `startScan()` - Scan BLE devices
- ✅ Method `connectToDevice()` - Connect ke ESP32
- ✅ Method `sendKeymapToESP()` - Kirim keymap via BLE
- ✅ Method `_handleIncomingData()` - Terima data loadcell dari ESP32
- ✅ Method `disconnect()` - Disconnect BLE

### 3. **Home Screen**
- ✅ Icon Bluetooth untuk scan/connect
- ✅ Dialog scan BLE devices
- ✅ List devices yang ditemukan

### 4. **Android Permissions**
- ✅ Semua permission BLE sudah ada di `AndroidManifest.xml`

---

## 🔧 Konfigurasi UUID BLE

### ESP32 UUID (dari kode Anda):
```cpp
#define MY_SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b" 
#define MY_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"
```

### Flutter UUID (sudah disesuaikan):
```dart
static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
static const String charUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
```

✅ **UUID sudah match!**

---

## 📝 Cara Penggunaan:

### 1. Di Flutter App
```bash
flutter run
```

### 2. Alur Testing:
1. ✅ Klik icon Bluetooth di Home Screen
2. ✅ Klik tombol "Scan"
3. ✅ Pilih device "MediGrip-Controller"
4. ✅ Tunggu connected
5. ✅ Data loadcell akan muncul otomatis (dari `bleKeyboard.sendMyData()`)
6. ✅ Test kirim keymap dari UI (diterima di `bleKeyboard.getDataChar()`)

---

## 📡 Alur Data BLE:

```
ESP32 → Flutter (Notify):
- Loadcell value setiap 500ms
- Format: String angka ("1234")
- Method ESP32: bleKeyboard.sendMyData(dataKirim.c_str())

Flutter → ESP32 (Write):  
- Keymap update (4 karakter)
- Format: "fghj"
- Method ESP32: bleKeyboard.getDataChar(huruf, sizeof(huruf))
```

---

## 🐛 Troubleshooting:

### Device tidak muncul saat scan?
- ✅ Pastikan ESP32 sudah running
- ✅ Restart ESP32
- ✅ Pastikan Bluetooth HP nyala
- ✅ Check Serial Monitor: "BLE Keyboard Started"

### Connected tapi tidak ada data?
- ✅ Cek Serial Monitor ESP32: "(BLE Connected)"
- ✅ Pastikan `bleKeyboard.isConnected()` return true
- ✅ Cek apakah loadcell sudah ready: `scale.is_ready()`
- ✅ Test kirim manual dari nRFConnect dulu

### Data tidak update?
- ✅ Pastikan notify enabled di characteristic
- ✅ Cek interval 500ms di ESP32 tidak terlalu cepat
- ✅ Lihat log Flutter: "📥 Received: ..."

### Keymap tidak berubah di ESP32?
- ✅ Cek `bleKeyboard.getDataChar()` dipanggil di loop
- ✅ Pastikan write berhasil (cek log Flutter: "✅ Keymap dikirim")
- ✅ Cek Serial Monitor ESP32: "Keymap Diupdate: ..."

---

## 📚 File Penting:

1. ✅ `lib/providers/glove_provider.dart` - BLE logic
2. ✅ `lib/screens/home_screen.dart` - Scan & Connect UI
3. ✅ ESP32 Code - BleKeyboard Custom (sudah siap)

---

## 🎯 Next Steps (Opsional):

### Reconnect Otomatis
Tambahkan di `GloveProvider`:
```dart
void _setupAutoReconnect() {
  _connectedDevice?.connectionState.listen((state) {
    if (state == BluetoothConnectionState.disconnected) {
      print("⚠️ Disconnected. Auto-reconnecting...");
      Future.delayed(Duration(seconds: 2), () {
        connectToDevice(_connectedDevice!);
      });
    }
  });
}
```

### Filter Scan Results
Hanya tampilkan "MediGrip":
```dart
_scanResults = results.where((r) => 
  r.device.platformName.contains("MediGrip")
).toList();
```

### Connection Timeout Handler
```dart
await device.connect(timeout: Duration(seconds: 10))
  .timeout(Duration(seconds: 15), onTimeout: () {
    print("❌ Connection timeout");
    throw Exception("Timeout");
  });
```

---

**Status**: ✅ Ready to Test!

Silakan test langsung dengan ESP32 Anda yang sudah custom. Kode BleKeyboard tidak perlu diubah! 🚀

---

## **OPSI 1: Ubah ESP32 ke BLE Server Standar** (RECOMMENDED)

Ganti library ESP32 dari `BleKeyboard` ke **BLE Server biasa** dengan custom service.

### Kode ESP32 Baru (ganti seluruhnya):

```cpp
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <HX711.h>

// ==========================================
// 1. PINOUT
// ==========================================
#define LOADCELL_DOUT 6
#define LOADCELL_SCK  7

#define ROW_PIN 4
int COL_PINS[4] = {10, 5, 3, 2}; 

char keymap[5] = {'f','g','h','j', '\0'};

// ==========================================
// 2. BLE UUIDs (PENTING!)
// ==========================================
// Service UUID - Custom untuk WanurGlove
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// TX Characteristic - ESP32 kirim data ke Flutter (Loadcell)
#define CHARACTERISTIC_UUID_TX "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// RX Characteristic - ESP32 terima data dari Flutter (Keymap)
#define CHARACTERISTIC_UUID_RX "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

// ==========================================
// 3. OBJEK GLOBAL
// ==========================================
HX711 scale;

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
BLECharacteristic* pRxCharacteristic = NULL;
bool deviceConnected = false;

unsigned long lastKeyTime[4] = {0,0,0,0};
unsigned long lastHeartbeat = 0;
unsigned long lastLoadcellSend = 0;

// ==========================================
// 4. BLE CALLBACKS
// ==========================================
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("✅ BLE Client Connected!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("❌ BLE Client Disconnected!");
      // Restart advertising
      pServer->getAdvertising()->start();
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      if (value.length() >= 4) {
        for(int i=0; i<4; i++){
          keymap[i] = value[i];
        }
        keymap[4] = '\0';
        
        Serial.print("📥 Keymap Updated: ");
        Serial.println(keymap);
      }
    }
};

// ==========================================
// 5. SETUP
// ==========================================
void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("\n\n=== MEDIGRIP SYSTEM (BLE MODE) ===");

  // --- BLE SETUP ---
  BLEDevice::init("MediGrip-Controller");
  
  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create TX Characteristic (Notify)
  pTxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTxCharacteristic->addDescriptor(new BLE2902());

  // Create RX Characteristic (Write)
  pRxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE
  );
  pRxCharacteristic->setCallbacks(new MyCallbacks());

  // Start service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("✅ BLE Server Started. Menunggu koneksi...");

  // --- LOADCELL SETUP ---
  scale.begin(LOADCELL_DOUT, LOADCELL_SCK);
  Serial.print("✅ Loadcell Ready");
  // scale.set_scale(420.0);
  // scale.tare();

  // --- GPIO SETUP ---
  pinMode(ROW_PIN, OUTPUT);
  digitalWrite(ROW_PIN, LOW);
  for(int i=0; i<4; i++) pinMode(COL_PINS[i], INPUT_PULLUP);
  
  Serial.println("\n=== LOOP START ===");
}

// ==========================================
// 6. LOOP
// ==========================================
void loop() {
  // --- HEARTBEAT ---
  if (millis() - lastHeartbeat > 3000) {
    lastHeartbeat = millis();
    Serial.print(deviceConnected ? "🟢 Connected | " : "🔵 Waiting | ");
    Serial.println(keymap);
  }

  // --- BUTTON DETECTION (Optional: bisa di-comment jika tidak pakai) ---
  for (int i = 0; i < 4; i++) {
    if (digitalRead(COL_PINS[i]) == LOW) {
      if (millis() - lastKeyTime[i] > 150) { 
        lastKeyTime[i] = millis();
        Serial.printf("🔘 Button %d -> '%c'\n", i, keymap[i]);
      }
    }
  }

  // --- KIRIM LOADCELL DATA VIA BLE ---
  if (deviceConnected && millis() - lastLoadcellSend > 500) {
    lastLoadcellSend = millis();
    
    long reading = 0; 
    if (scale.is_ready()) {
      reading = scale.get_units(1); 
    }

    // Kirim sebagai string
    String dataStr = String(reading);
    pTxCharacteristic->setValue(dataStr.c_str());
    pTxCharacteristic->notify();
    
    // Debug (bisa di-comment jika terlalu banyak)
    // Serial.printf("📤 Sent: %ld\n", reading);
  }

  delay(10);
}
```

### Update di Flutter (GloveProvider):

Tambahkan UUID yang sama:

```dart
// Di glove_provider.dart, tambahkan konstanta UUID:
class GloveProvider with ChangeNotifier {
  // BLE UUIDs - HARUS SAMA dengan ESP32!
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String txCharUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String rxCharUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  
  // ... rest of code
```

Dan update method `_discoverServices()`:

```dart
Future<void> _discoverServices() async {
  if (_connectedDevice == null) return;
  
  try {
    List<BluetoothService> services = await _connectedDevice!.discoverServices();
    
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
        print("✅ Found WanurGlove Service!");
        
        for (BluetoothCharacteristic char in service.characteristics) {
          // TX (ESP32 -> Flutter)
          if (char.uuid.toString().toLowerCase() == txCharUUID.toLowerCase()) {
            _rxCharacteristic = char;
            await char.setNotifyValue(true);
            _rxSubscription = char.lastValueStream.listen(_handleIncomingData);
            print("✅ TX Characteristic subscribed!");
          }
          
          // RX (Flutter -> ESP32)
          if (char.uuid.toString().toLowerCase() == rxCharUUID.toLowerCase()) {
            _txCharacteristic = char;
            print("✅ RX Characteristic ready!");
          }
        }
      }
    }
  } catch (e) {
    print("❌ Error: $e");
  }
}
```

---

## **OPSI 2: Tetap Pakai BleKeyboard** (Lebih Rumit)

Jika ingin tetap pakai `BleKeyboard`, Flutter harus:
1. Connect sebagai HID client
2. Parse keystroke events
3. Tidak bisa kirim keymap update (harus hardcode di ESP32)

**Tidak recommended** karena terlalu kompleks.

---

## 📝 Langkah-Langkah Testing:

### 1. Upload Kode ESP32 Baru (Opsi 1)
```bash
# Di Arduino IDE, upload kode BLE Server
```

### 2. Test di Flutter
```bash
flutter run
```

### 3. Alur Testing:
1. Klik icon Bluetooth di Home Screen
2. Klik tombol "Scan"
3. Pilih device "MediGrip-Controller"
4. Tunggu connected
5. Data loadcell akan muncul otomatis
6. Test kirim keymap dari UI

---

## 🐛 Troubleshooting:

### Device tidak muncul saat scan?
- Pastikan ESP32 sudah running
- Restart ESP32
- Pastikan Bluetooth HP nyala

### Connected tapi tidak ada data?
- Cek UUID di ESP32 dan Flutter harus **SAMA PERSIS**
- Cek Serial Monitor ESP32 apakah ada error
- Pastikan characteristic notify sudah aktif

### Permission error?
- Request permission dulu (sudah auto di flutter_blue_plus)
- Cek Settings > App > Permissions

---

## 📚 File yang Perlu Diupdate:

1. ✅ `pubspec.yaml` - Sudah OK
2. ✅ `lib/providers/glove_provider.dart` - Sudah OK
3. ✅ `lib/screens/home_screen.dart` - Sudah OK
4. ⚠️ **ESP32 Code** - PERLU DIGANTI (gunakan kode di atas)
5. ⚠️ `glove_provider.dart` - Tambahkan UUID constants

---

**Rekomendasi**: Gunakan **OPSI 1** untuk hasil terbaik! 🚀
