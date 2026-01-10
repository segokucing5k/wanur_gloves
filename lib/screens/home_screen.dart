import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glove_provider.dart';
import 'measurement_screen.dart'; // Page Genggaman
import 'touch_menu_screen.dart'; // Page Menu Kalibrasi
import 'game_webview_screen.dart'; // Page Game

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    // Auto-connect saat app dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final glove = context.read<GloveProvider>();
      _tryAutoConnect(glove);
    });
  }

  Future<void> _tryAutoConnect(GloveProvider glove) async {
    // Jangan auto-connect kalau sudah connected
    if (glove.isConnected) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      final success = await glove.autoConnectBondedDevice();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Auto-connected to paired device!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ No paired WanurGlove device found"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Auto-connect failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Auto-connect failed: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  // Dialog untuk scan BLE devices
  void _showScanDialog(BuildContext context) {
    final glove = context.read<GloveProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A2D),
        title: const Text(
          "Scan BLE Devices",
          style: TextStyle(color: Colors.cyanAccent),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Consumer<GloveProvider>(
            builder: (context, glove, child) {
              if (glove.isScanning) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.cyanAccent),
                      SizedBox(height: 16),
                      Text("Scanning...",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                );
              }

              if (glove.scanResults.isEmpty) {
                return const Center(
                  child: Text(
                    "Press Scan button to search for devices",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: glove.scanResults.length,
                itemBuilder: (context, index) {
                  final result = glove.scanResults[index];

                  // Cek apakah device ini punya service WanurGlove
                  final hasWanurService = result.advertisementData.serviceUuids
                      .any((uuid) =>
                          uuid.toString().toLowerCase() ==
                          "4fafc201-1fb5-459e-8fcc-c5c9c331914b");

                  final deviceName = result.device.platformName.isEmpty
                      ? (hasWanurService
                          ? "🎯 MediGrip Device"
                          : "Unknown Device")
                      : result.device.platformName;

                  // MAC Address (untuk identifikasi)
                  final macAddress = result.device.remoteId.toString();

                  return ListTile(
                    leading: Icon(
                        hasWanurService ? Icons.sensors : Icons.bluetooth,
                        color: hasWanurService
                            ? Colors.greenAccent
                            : Colors.cyanAccent),
                    title: Text(
                      deviceName,
                      style: TextStyle(
                        color:
                            hasWanurService ? Colors.greenAccent : Colors.white,
                        fontWeight: hasWanurService
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MAC: $macAddress",
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        if (hasWanurService)
                          const Text(
                            "✅ WanurGlove Service Detected",
                            style: TextStyle(
                                color: Colors.greenAccent, fontSize: 10),
                          ),
                      ],
                    ),
                    trailing: Text(
                      "${result.rssi} dBm",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    onTap: () async {
                      // Tutup dialog scan
                      Navigator.pop(context);

                      // Check apakah device sudah bonded
                      final isBonded =
                          await glove.isDeviceBonded(result.device);

                      bool shouldProceed = true;

                      // Kalau belum bonded, kasih instruksi pairing
                      if (!isBonded) {
                        shouldProceed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF121A2D),
                                title: const Text(
                                  "⚠️ Pairing Required (First Time)",
                                  style: TextStyle(color: Colors.orangeAccent),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "This device is not paired yet. Pairing is required for BleKeyboard connection.",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Steps:",
                                      style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "1. Open Settings → Bluetooth\n"
                                      "2. Find 'MediGrip-Controller'\n"
                                      "3. Tap to Pair\n"
                                      "4. Return to this app\n"
                                      "5. Tap 'Continue' below",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "MAC: $macAddress",
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel",
                                        style:
                                            TextStyle(color: Colors.white70)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF00BFA5)),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                        "Already Paired - Continue",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      }

                      if (!shouldProceed) return;

                      // Show loading dialog
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF121A2D),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                  color: Colors.cyanAccent),
                              const SizedBox(height: 16),
                              Text(
                                isBonded
                                    ? "Connecting to paired device..."
                                    : "Connecting...",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );

                      // Try connect
                      try {
                        await glove.connectToDevice(result.device);

                        // Close loading dialog
                        if (context.mounted) Navigator.pop(context);

                        // Show success message
                        if (context.mounted && glove.isConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Connected to MediGrip Device!"),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        // Close loading dialog
                        if (context.mounted) Navigator.pop(context);

                        // Show error message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text("❌ Connection failed: ${e.toString()}"),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5)),
            onPressed: () {
              glove.startScan();
            },
            child: const Text("Scan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. AMBIL DATA PROVIDER
    final glove = context.watch<GloveProvider>();

    // 2. LOGIKA SAPAAN OTOMATIS (MAGIC DISINI 🌟)
    // Kita ambil jam saat ini (format 0-23)
    var hour = DateTime.now().hour;
    String greeting;

    if (hour < 11) {
      greeting = "Good Morning";
    } else if (hour < 15) {
      greeting = "Good Afternoon";
    } else if (hour < 19) {
      greeting = "Good Evening";
    } else {
      greeting = "Good Night";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B101F), // Deep Navy sesuai gambar

      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "WanurGlove",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // BLUETOOTH AUTO-CONNECT BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isRetrying
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      glove.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth,
                      color: glove.isConnected
                          ? Colors.greenAccent
                          : Colors.cyanAccent,
                    ),
                    onPressed: () {
                      final glove = context.read<GloveProvider>();
                      _tryAutoConnect(glove);
                    },
                    tooltip:
                        glove.isConnected ? "Reconnect" : "Connect to MediGrip",
                  ),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER TEXT DYNAMIC ---
            Text(
              "Hello, $greeting!",
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent),
            ),
            Text(
              "Ready to excercise today?",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),

            const SizedBox(height: 24),

            // STATUS INFO - BLE Connection
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: const Color(0xFF121A2D),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.cyanAccent.withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(
                      glove.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: glove.isConnected
                          ? Colors.greenAccent
                          : Colors.white54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          glove.isConnected
                              ? "Connected to WanurGlove"
                              : "⚠️ No Device Connected",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          glove.isConnected
                              ? "Device connected!"
                              : "Connecting to device...",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- CARD 1: MAGIC TILES GAME ---
            ActionCard(
              title: "Training Game",
              subtitle: "Play rhythm game for finger training",
              icon: Icons.piano,
              themeColor: const Color(0xFF6A1B9A),
              buttonText: "Start Game",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GameWebViewScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // --- CARD 2: FINGER CALIBRATION (TOUCH SENSOR) ---
            ActionCard(
              title: "Finger Calibration",
              subtitle: "Check sensor response",
              icon: Icons.touch_app,
              themeColor: const Color(0xFF4A5240),
              buttonText: "Start Calibration",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TouchMenuScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // --- CARD 3: GRIP MEASUREMENT (LOADCELL) ---
            ActionCard(
              title: "Grip Measurement",
              subtitle: "Measure hand grip strength",
              icon: Icons.back_hand,
              themeColor: const Color(0xFF00BFA5),
              buttonText: "Start Measure",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MeasurementScreen()),
                );
              },
            ),

            const SizedBox(height: 24),
            // === AKSI KEYMAP ===
            // Container(
            //   padding: const EdgeInsets.all(15),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF121A2D),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         "Keymap",
            //         style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
            //       ),
            //       const SizedBox(height: 8),
            //       Text(
            //         "Saat ini: ${glove.keyMap['index1']}${glove.keyMap['index2']}${glove.keyMap['index3']}${glove.keyMap['index4']}",
            //         style: const TextStyle(color: Colors.white70),
            //       ),
            //       const SizedBox(height: 8),
            //       Row(
            //         children: [
            //           ElevatedButton(
            //             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
            //             onPressed: () async {
            //               await glove.sendKeymapToESP();
            //             },
            //             child: const Text("Kirim ke ESP", style: TextStyle(color: Colors.white)),
            //           ),
            //           const SizedBox(width: 8),
            //           OutlinedButton(
            //             onPressed: () {
            //               // contoh toggle cepat
            //               final cur = glove.keyMap;
            //               context.read<GloveProvider>().updateLocalKey('index1', cur['index1'] == 'f' ? 'a' : 'f');
            //             },
            //             child: const Text("Ubah Cepat"),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}

// --- WIDGET KARTU (Tidak Berubah) ---
class ActionCard extends StatelessWidget {
  final String title, subtitle, buttonText;
  final IconData icon;
  final Color themeColor;
  final VoidCallback onPressed;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
    required this.themeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: themeColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              child:
                  Text(buttonText, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
