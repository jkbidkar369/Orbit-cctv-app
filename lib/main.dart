import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

void main() {
  runApp(const OrbitApp());
}

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit Smart CCTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D47A1), // Orbit Navy Blue
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
      home: const OrbitHomeScreen(),
    );
  }
}

// ---------------- 1. HOME SCREEN (DEVICE LIST) ----------------
class OrbitHomeScreen extends StatefulWidget {
  const OrbitHomeScreen({super.key});

  @override
  State<OrbitHomeScreen> createState() => _OrbitHomeScreenState();
}

class _OrbitHomeScreenState extends State<OrbitHomeScreen> {
  // Saved Orbit Devices
  List<Map<String, String>> orbitDevices = [
    {"name": "Office DVR", "serial": "ORB-10023", "status": "Online"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORBIT Surveillance', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
            onPressed: () async {
              // Open QR Scanner
              final scannedSerial = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScanScreen()),
              );

              if (scannedSerial != null) {
                setState(() {
                  orbitDevices.add({
                    "name": "Orbit Device ${orbitDevices.length + 1}",
                    "serial": scannedSerial.toString(),
                    "status": "Online"
                  });
                });
              }
            },
          ),
        ],
      ),
      body: orbitDevices.isEmpty
          ? const Center(child: Text("Koi Orbit DVR/NVR add nahi hai. '+' par click karein."))
          : ListView.builder(
              itemCount: orbitDevices.length,
              itemBuilder: (context, index) {
                final device = orbitDevices[index];
                return Card(
                  color: const Color(0xFF242424),
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.videocam, color: Colors.blueAccent, size: 36),
                    title: Text(device['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("UID: ${device['serial']}"),
                    trailing: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 32),
                    onTap: () {
                      // Navigate to Live Grid View
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrbitLiveGridScreen(deviceName: device['name']!),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- 2. QR CODE SCANNER SCREEN ----------------
class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Orbit QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

// ---------------- 3. LIVE MULTI-CHANNEL STREAM SCREEN ----------------
class OrbitLiveGridScreen extends StatefulWidget {
  final String deviceName;
  const OrbitLiveGridScreen({super.key, required this.deviceName});

  @override
  State<OrbitLiveGridScreen> createState() => _OrbitLiveGridScreenState();
}

class _OrbitLiveGridScreenState extends State<OrbitLiveGridScreen> {
  late VlcPlayerController _vlcController;

  // Orbit Test Stream URL (Replace with your Orbit Cloud/RTSP Link)
  final String testRtspUrl = "rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4";

  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.network(
      testRtspUrl,
      hwAcc: HwAcc.full, // Hardware acceleration for smooth playback
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: Column(
        children: [
          // 4-Channel Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(4),
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              children: [
                // Channel 1: Live Stream
                Container(
                  color: Colors.black,
                  child: VlcPlayer(
                    controller: _vlcController,
                    aspectRatio: 16 / 9,
                    placeholder: const Center(child: CircularProgressIndicator()),
                  ),
                ),
                // Channel 2: Offline / Blank Placeholder
                _buildOfflineChannel("CAM 02"),
                // Channel 3: Offline / Blank Placeholder
                _buildOfflineChannel("CAM 03"),
                // Channel 4: Offline / Blank Placeholder
                _buildOfflineChannel("CAM 04"),
              ],
            ),
          ),
          // PTZ & Control Bar (Hik-Connect Style)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.camera_alt), onPressed: () {}),
                IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
                IconButton(icon: const Icon(Icons.volume_up), onPressed: () {}),
                IconButton(icon: const Icon(Icons.fullscreen), onPressed: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOfflineChannel(String title) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(title, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}
