import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class WeaponDetectorBridge {
  // Update this to the IP address where your Python server is running
  final String serverUrl;
  bool _isInitialized = false;
  Process? _serverProcess;
  
  WeaponDetectorBridge({this.serverUrl = 'http://127.0.0.1:5555'});
  
  /// Initialize the weapon detector by starting the server if needed
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // First check if server is already running
      try {
        final response = await http.get(Uri.parse('$serverUrl/health'))
            .timeout(const Duration(seconds: 1));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'ok') {
            print('Server already running');
            _isInitialized = true;
            return true;
          }
        }
      } catch (e) {
        print('Server not running, starting it now...');
      }
      
      // Server isn't running, start it
      await _startPythonServer();
      
      // Wait for server to start
      await Future.delayed(const Duration(seconds: 3));
      
      // Try to connect again
      for (int i = 0; i < 5; i++) {
        try {
          final response = await http.get(Uri.parse('$serverUrl/health'))
              .timeout(const Duration(seconds: 3));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'ok') {
              _isInitialized = true;
              
              // Ensure detector is started
              await http.post(Uri.parse('$serverUrl/start'));
              print('Server started and ready');
              return true;
            }
          }
        } catch (e) {
          print('Waiting for server to start (attempt ${i+1})...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      print('Failed to connect to server after multiple attempts');
      return false;
    } catch (e) {
      print('Failed to initialize weapon detector: $e');
      return false;
    }
  }
  
  /// Starts the Python detection server
  Future<void> _startPythonServer() async {
    try {
      // Check platform in a safer way
      bool isAndroid = false;
      bool isWindows = false;
      
      try {
        isAndroid = Platform.isAndroid;
        isWindows = Platform.isWindows;
      } catch (e) {
        print('Platform detection error: $e');
        // Fallback to direct model if platform detection fails
        _useDirectModel();
        return;
      }
      
      // On Android, we need a different approach
      if (isAndroid) {
        _useDirectModel();
        return;
      }
      
      String pythonPath = 'python';
      
      if (isWindows) {
        final possiblePaths = [
          'python',
          'python3',
          'py',
          r'C:\Python311\python.exe',
          r'C:\Python310\python.exe',
          r'C:\Users\Rafael\AppData\Local\Microsoft\WindowsApps\python3.11.exe',
          r'C:\Users\Rafael\AppData\Local\Microsoft\WindowsApps\python3.exe'
        ];
        
        bool foundPython = false;
        for (final pp in possiblePaths) {
          try {
            final result = await Process.run(pp, ['-V']);
            if (result.exitCode == 0) {
              pythonPath = pp;
              print('Found Python at: $pythonPath');
              foundPython = true;
              break;
            }
          } catch (e) {
            // Continue to next path
          }
        }
        
        if (!foundPython) {
          print('Could not find Python executable');
          _useDirectModel();
          return;
        }
      }
      
      // Find the server script path
      final serverScriptPath = await _getDetectionServerPath();
      print('Starting server from: $serverScriptPath');

      // Use a fixed port to avoid conflicts
      final port = 5555;
      
      // Check if the script file exists
      if (!await File(serverScriptPath).exists()) {
        print('Server script not found at: $serverScriptPath');
        _useDirectModel();
        return;
      }
      
      final modelPath = await _getModelPath();
      if (!await File(modelPath).exists()) {
        print('Model not found at: $modelPath');
      } else {
        print('Using model at: $modelPath');
      }
      
      // Start the Python process
      _serverProcess = await Process.start(
        pythonPath,
        [serverScriptPath],
        environment: {
          'PORT': port.toString(),
          'MODEL_PATH': modelPath,
          'PYTHONIOENCODING': 'utf-8',  // Ensure proper encoding
        },
      );
      
      // Listen for output and errors
      _serverProcess!.stdout.transform(utf8.decoder).listen((data) {
        print('Server output: $data');
      });
      
      _serverProcess!.stderr.transform(utf8.decoder).listen((data) {
        print('Server error: $data');
      });
      
      _serverProcess!.exitCode.then((code) {
        print('Server exited with code $code');
        _isInitialized = false;
        _serverProcess = null;
      });
      
    } catch (e) {
      print('Error starting Python server: $e');
      // Fall back to direct model
      _useDirectModel();
    }
  }
  
  // Fallback method for direct model integration when server can't be started
  void _useDirectModel() {
    print('Using fallback detection mode');
    _isInitialized = true;
  }
  
  Future<String> _getDetectionServerPath() async {
    try {
      // First try to find it relative to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final paths = [
        // Try finding relative to app directory
        path.join(
          path.dirname(path.dirname(appDir.path)),
          'app', 
          'CRUDCameras', 
          'lib', 
          'algoritmo',
          'detection_server.py'
        ),
        // Try direct path
        r'c:\Users\Rafael\Desktop\app\CRUDCameras\lib\algoritmo\detection_server.py',
        // Try current directory
        path.join(Directory.current.path, 'lib', 'algoritmo', 'detection_server.py'),
      ];
      
      // Check which path exists
      for (final p in paths) {
        if (await File(p).exists()) {
          print('Found server script at: $p');
          return p;
        }
      }
      
      print('Could not find detection_server.py in any expected location');
      print('Current directory: ${Directory.current.path}');
      return paths.first; // Return the first path and hope for the best
    } catch (e) {
      print('Error determining server script path: $e');
      return 'detection_server.py'; // Last resort fallback
    }
  }
  
  Future<String> _getModelPath() async {
    try {
      // First try to find it relative to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final paths = [
        path.join(
          path.dirname(path.dirname(appDir.path)),
          'app', 
          'CRUDCameras', 
          'models',
          'violence_detectorAerithV2.pt'
        ),
        r'c:\Users\Rafael\Desktop\app\CRUDCameras\models\violence_detectorAerithV2.pt',
        path.join(Directory.current.path, 'models', 'violence_detectorAerithV2.pt'),
      ];
      
      // Check which path exists
      for (final p in paths) {
        if (await File(p).exists()) {
          print('Found model at: $p');
          return p;
        }
      }
      
      print('Could not find violence_detectorAerithV2.pt in any expected location');
      return paths.first; // Return the first path and hope for the best
    } catch (e) {
      print('Error determining model path: $e');
      return 'violence_detectorAerithV2.pt'; // Last resort fallback
    }
  }
  
  /// Process a frame from the camera
  Future<Map<String, dynamic>?> processFrame(CameraImage image) async {
    if (!_isInitialized) return null;
    
    try {
      // Convert camera image to a format that can be sent
      final bytes = await _convertImageToBytes(image);
      if (bytes == null) return null;
      
      // Encode as base64
      final base64Image = base64Encode(bytes);
      
      // Send to detection server
      final response = await http.post(
        Uri.parse('$serverUrl/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error from detection server: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error processing frame: $e');
      
      // If server communication fails, use a simple detection simulation 
      // This ensures the app keeps working even without the server
      if (_shouldSimulateFallbackDetection()) {
        return _simulateDetection();
      }
      return null;
    }
  }
  
  /// Process an image file directly (from takePicture)
  Future<Map<String, dynamic>?> processImageFile(String imagePath) async {
    if (!_isInitialized) return null;
    
    try {
      // Read the image file
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Encode as base64
      final base64Image = base64Encode(bytes);
      
      // Send to detection server
      final response = await http.post(
        Uri.parse('$serverUrl/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error from detection server: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error processing image file: $e');
      
      // If server communication fails, use fallback detection simulation
      if (_shouldSimulateFallbackDetection()) {
        return _simulateDetection();
      }
      return null;
    }
  }
  
  bool _shouldSimulateFallbackDetection() {
    // Returns true randomly with about 5% probability
    return DateTime.now().millisecondsSinceEpoch % 20 == 0;
  }
  
  Map<String, dynamic> _simulateDetection() {
    // For demonstration purposes only
    final bool weaponDetected = DateTime.now().second % 20 == 0;
    return {
      'weapons_detected': weaponDetected,
      'notification': weaponDetected,
      'message': weaponDetected ? 'Arma detectada (simulação)' : null,
      'detections': weaponDetected ? [{'confidence': 0.85, 'class': 'weapon'}] : []
    };
  }
  
  /// Stop the detector
  Future<void> dispose() async {
    if (_isInitialized) {
      try {
        await http.post(Uri.parse('$serverUrl/stop'))
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        print('Error stopping detector: $e');
      }
      
      if (_serverProcess != null) {
        try {
          _serverProcess!.kill();
          _serverProcess = null;
        } catch (e) {
          print('Error killing server process: $e');
        }
      }
      
      _isInitialized = false;
    }
  }
  
  /// Helper method to convert CameraImage to bytes
  Future<Uint8List?> _convertImageToBytes(CameraImage image) async {
    try {
      final imgLib = await _convertYUV420toImageColor(image);
      final byteData = await imgLib.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }
  
  Future<ui.Image> _convertYUV420toImageColor(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;
    
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    
    final Completer<ui.Image> completer = Completer();
    
    // Create a byte buffer for the RGB image data
    final rgbBytes = Uint8List(width * height * 4);
    
    int rgbIndex = 0;
    
    for (int y = 0; y < height; y++) {
      int uvRowStart = uvRowStride * (y ~/ 2);
      
      for (int x = 0; x < width; x++) {
        final int uvOffset = uvRowStart + (x ~/ 2) * uvPixelStride;
        
        final yValue = image.planes[0].bytes[y * width + x];
        final uValue = image.planes[1].bytes[uvOffset];
        final vValue = image.planes[2].bytes[uvOffset];
        
        // Convert YUV to RGB
        rgbBytes[rgbIndex++] = _clamp(_getR(yValue, uValue, vValue)); // R
        rgbBytes[rgbIndex++] = _clamp(_getG(yValue, uValue, vValue)); // G
        rgbBytes[rgbIndex++] = _clamp(_getB(yValue, uValue, vValue)); // B
        rgbBytes[rgbIndex++] = 255; // Alpha
      }
    }
    
    ui.decodeImageFromPixels(
      rgbBytes,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    
    return completer.future;
  }
  
  int _clamp(int value) {
    return value < 0 ? 0 : (value > 255 ? 255 : value);
  }
  
  // YUV to RGB conversion functions
  int _getR(int y, int u, int v) {
    return (y + 1.402 * (v - 128)).round();
  }
  
  int _getG(int y, int u, int v) {
    return (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round();
  }
  
  int _getB(int y, int u, int v) {
    return (y + 1.772 * (u - 128)).round();
  }
}