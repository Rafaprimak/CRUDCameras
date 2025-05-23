import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../algoritmo/direct_python_bridge.dart'; // Changed import
import '../models/camera.dart' as camera_model;

class DeviceCameraViewScreen extends StatefulWidget {
  final camera_model.Camera cameraInfo;
  
  const DeviceCameraViewScreen({Key? key, required this.cameraInfo}) : super(key: key);
  
  @override
  _DeviceCameraViewScreenState createState() => _DeviceCameraViewScreenState();
}

class _DeviceCameraViewScreenState extends State<DeviceCameraViewScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isDetectionEnabled = false;
  bool _isDetectorReady = false;
  DirectPythonBridge? _weaponDetector; // Changed type
  bool _weaponDetected = false;
  String _lastDetectionMessage = '';
  Timer? _detectionTimer;
  int _processingFrameCount = 0;
  bool _isInitializing = true;
  String _detectionServerUrl = 'http://127.0.0.1:5556'; // Replace with your server address
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAll();
  }
  
  Future<void> _initializeAll() async {
    try {
      // Initialize detector first - this might take some time
      await _initializeDetector();
      
      // Then initialize the camera
      await _initializeCamera();
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print("Error during initialization: $e");
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _showError('Erro ao inicializar: $e');
      }
    }
  }

  Future<void> _initializeDetector() async {
    // Use the direct Python bridge
    _weaponDetector = DirectPythonBridge();
    
    try {
      final initialized = await _weaponDetector!.initialize();
      
      if (mounted) {
        setState(() {
          _isDetectorReady = initialized;
        });
      }
      
      if (!initialized) {
        _showError('Não foi possível inicializar o detector de armas. Funcionando em modo limitado.');
      } else {
        print('Weapon detector initialized successfully');
      }
    } catch (e) {
      print('Error initializing detector: $e');
      if (mounted) {
        _showError('Erro ao inicializar detector: $e');
      }
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        _showError('Nenhuma câmera encontrada no dispositivo');
        return;
      }
      
      // Use the first camera by default (usually back camera)
      final CameraDescription camera = _cameras.first;
      
      // Initialize controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      print('Error initializing camera: $e');
      _showError('Erro ao inicializar câmera: $e');
    }
  }
  
  void _startDetection() {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        !_isDetectorReady) {
      return;
    }
    
    // Use a timer to regularly sample frames rather than process every frame
    // More conservative timing to reduce load (every 1 second)
    _detectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_processingFrameCount < 1) { // Only allow one concurrent processing
        _processingFrameCount++;
        _captureAndProcessFrame();
      }
    });
  }
  
  void _captureAndProcessFrame() async {
    try {
      if (_cameraController?.value.isInitialized != true) {
        _processingFrameCount--;
        return;
      }
      
      // Take a picture
      final XFile file = await _cameraController!.takePicture();
      
      // Read file as bytes
      final bytes = await File(file.path).readAsBytes();
      
      // Convert to base64
      final base64Image = base64Encode(bytes);
      
      // Send to server
      final response = await http.post(
        Uri.parse('$_detectionServerUrl/detection/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'camera_id': widget.cameraInfo.id,
        }),
      );
      
      _processingFrameCount--;
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            _weaponDetected = result['weapons_detected'] == true;
            if (result['notification'] == true && result['message'] != null) {
              _lastDetectionMessage = result['message'];
              // Add haptic feedback for detection
              HapticFeedback.heavyImpact();
            } else if (_weaponDetected) {
              _lastDetectionMessage = 'Arma detectada!';
              HapticFeedback.heavyImpact();
            }
          });
        }
      } else {
        print('Error from detection server: ${response.statusCode} - ${response.body}');
      }
      
      // Clean up the temporary file
      try {
        await File(file.path).delete();
      } catch (e) {
        print('Error deleting temporary file: $e');
      }
      
    } catch (e) {
      _processingFrameCount--;
      print('Error capturing frame: $e');
    }
  }
  
  void _stopDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
  }
  
  @override
  void dispose() {
    _stopDetection();
    if (_cameraController != null) {
      _cameraController!.dispose();
      _cameraController = null;
    }
    _weaponDetector?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only handle lifecycle changes if the camera was initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      // Free resources when app is inactive
      _stopDetection();
      _cameraController?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize when app is resumed
      _initializeCamera().then((_) {
        if (_isDetectionEnabled && _isDetectorReady) {
          _startDetection();
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _toggleDetection() {
    setState(() {
      _isDetectionEnabled = !_isDetectionEnabled;
    });
    
    if (_isDetectionEnabled && _isDetectorReady) {
      _startDetection();
    } else {
      _stopDetection();
    }
  }
  
  void _showServerSettingsDialog() {
    final serverController = TextEditingController(text: _detectionServerUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações do Servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                labelText: 'URL do Servidor',
                hintText: 'http://127.0.0.1:5556'
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _detectionServerUrl = serverController.text;
              });
              Navigator.pop(context);
              // You could save this to SharedPreferences for persistence
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Câmera: ${widget.cameraInfo.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações do Servidor',
            onPressed: _showServerSettingsDialog,
          ),
          if (_isDetectorReady)
            IconButton(
              icon: Icon(_isDetectionEnabled ? Icons.security : Icons.security_outlined),
              tooltip: _isDetectionEnabled ? 'Desativar detecção' : 'Ativar detecção',
              onPressed: _toggleDetection,
            ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Alternar câmera',
            onPressed: _cameras.length > 1 ? _switchCamera : null,
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Inicializando a câmera e o detector...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera Preview
                      _isInitialized && _cameraController != null
                          ? CameraPreview(_cameraController!)
                          : const Center(child: Text('Câmera não disponível')),
                      
                      // Weapon detection alert
                      if (_weaponDetected)
                        Positioned(
                          top: 20,
                          left: 0,
                          right: 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _lastDetectionMessage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                      // Detector status indicator
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isDetectorReady ? 
                                    (_isDetectionEnabled ? Colors.green : Colors.orange) : 
                                    Colors.red,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isDetectorReady ? 
                                  (_isDetectionEnabled ? "Detector ativo" : "Detector pronto") : 
                                  "Detector desconectado",
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Controls
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_camera),
                        color: Colors.white,
                        onPressed: _capturePhoto,
                      ),
                      IconButton(
                        icon: Icon(_isDetectionEnabled ? Icons.visibility : Icons.visibility_off),
                        color: _isDetectionEnabled ? Colors.green : Colors.white,
                        onPressed: _isDetectorReady ? _toggleDetection : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      // Briefly disable detection while taking a photo
      final wasDetectionEnabled = _isDetectionEnabled;
      if (wasDetectionEnabled) {
        _stopDetection();
      }
      
      await _cameraController!.takePicture();
      
      // Re-enable detection if it was enabled
      if (wasDetectionEnabled && mounted) {
        setState(() {
          _isDetectionEnabled = true;
        });
        _startDetection();
      }
      
      // Show a success message
      if (!mounted) return;
      
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto capturada com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // You could show the captured photo in a dialog or navigate to a photo view screen
      
    } catch (e) {
      _showError('Erro ao capturar foto: $e');
    }
  }
  
  void _switchCamera() async {
    if (_cameras.length <= 1) return;
    
    final currentCameraIndex = _cameras.indexOf(_cameraController!.description);
    final nextCameraIndex = (currentCameraIndex + 1) % _cameras.length;
    
    // Stop detection before switching
    final wasDetectionEnabled = _isDetectionEnabled;
    if (wasDetectionEnabled) {
      _stopDetection();
    }
    
    // Dispose the old camera controller
    await _cameraController?.dispose();
    _cameraController = null;
    
    if (!mounted) return;
    
    setState(() {
      _isInitialized = false;
    });
    
    // Create and initialize the new camera controller
    _cameraController = CameraController(
      _cameras[nextCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          
          // Restore detection state if it was enabled before
          if (wasDetectionEnabled) {
            _isDetectionEnabled = true;
          }
        });
        
        // Restart detection if needed
        if (wasDetectionEnabled && _isDetectorReady) {
          _startDetection();
        }
      }
    } catch (e) {
      _showError('Erro ao trocar câmera: $e');
    }
  }
}