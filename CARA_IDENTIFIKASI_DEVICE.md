# 🔧 Cara Menandai Device ESP32

## Sekarang di Flutter App:

### ✅ **Device Anda akan ditandai dengan:**
1. **Icon Hijau** 🟢 (`sensors` icon) - jika punya WanurGlove service
2. **Text Hijau Bold** - "🎯 MediGrip Device"
3. **Badge "✅ WanurGlove Service Detected"**
4. **MAC Address** ditampilkan untuk identifikasi

### ❌ **Device lain:**
- Icon Biru biasa (`bluetooth` icon)
- Text "Unknown Device"
- Tidak ada badge

---

## 📱 **Cara Menggunakan:**

1. Tap icon Bluetooth → Scan
2. **Cari device dengan icon HIJAU dan tulisan "🎯 MediGrip Device"**
3. Atau catat **MAC Address ESP32** dari Serial Monitor
4. Tap device tersebut untuk connect

---

## 🔧 **OPTIONAL: Fix ESP32 agar Ada Nama**

Jika ingin device name muncul (bukan "Unknown"), tambahkan di ESP32:

### Kode ESP32 yang sekarang:
```cpp
BleKeyboard bleKeyboard("MediGrip-Controller", "ESP32C3", 100);
```

**Pastikan parameter pertama** `"MediGrip-Controller"` sudah benar.

### Jika masih Unknown, coba set advertising manual:

```cpp
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  // Set device name SEBELUM begin()
  bleKeyboard.setName("MediGrip-Controller"); // ← Tambahkan ini
  bleKeyboard.begin();
  
  Serial.println("BLE Keyboard Started");
  // ... rest of code
}
```

---

## 🎯 **Cara Termudah: Lihat MAC Address**

### Di ESP32 Serial Monitor:
Tambahkan ini di setup():
```cpp
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  bleKeyboard.begin();
  
  // Print MAC Address
  Serial.print("MAC Address: ");
  Serial.println(BLEDevice::getAddress().toString().c_str());
  
  // ... rest of code
}
```

### Di Flutter App:
- MAC Address akan muncul di bawah nama device
- Cocokkan dengan yang di Serial Monitor

---

## 📋 **Yang Sudah Diupdate di Flutter:**

✅ Icon berbeda untuk WanurGlove device (hijau)  
✅ Nama "🎯 MediGrip Device" untuk device Anda  
✅ MAC Address ditampilkan  
✅ Badge "WanurGlove Service Detected"  
✅ Sorting otomatis (WanurGlove di atas)

Sekarang device Anda lebih mudah dikenali! 🎉
