import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';

class DirectPythonBridge {
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _pythonExecutable;
  String? _scriptPath;
  String? _modelPath;
  Process? _detectorProcess;
  // Removed unused field '_random'
  
  /// Initialize the weapon detector
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      print('Initializing violence detector with model: violence_detectorAerithV2.pt');
      
      // Find Python executable without relying on Platform API
      _pythonExecutable = await _findPythonExecutableWithoutPlatform();
      if (_pythonExecutable == null) {
        print('Python not found. Cannot proceed with detection.');
        return false;
      }
      
      // Find script path from existing files in the project
      _scriptPath = await _findDetectorScript();
      if (_scriptPath == null) {
        print('Detector script not found. Creating one...');
        _scriptPath = await _createDetectorScript();
        if (_scriptPath == null) {
          print('Failed to create detector script.');
          return false;
        }
      }
      
      // Find model path
      _modelPath = await _findModelPath();
      if (_modelPath == null) {
        print('Model not found. Detection cannot proceed.');
        return false;
      }
      
      // Start the detector process in background mode
      final success = await _startDetectorProcess();
      if (!success) {
        print('Failed to start detector process.');
        return false;
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Failed to initialize weapon detector: $e');
      return false;
    }
  }
  
  /// Find Python executable without using Platform API
  Future<String?> _findPythonExecutableWithoutPlatform() async {
    // A list of many possible Python locations
    final possiblePaths = [
      // Standard path entries
      'python',
      'python3',
      'py',
      
      // Windows specific paths with version numbers
      r'C:\Python39\python.exe',
      r'C:\Python310\python.exe',
      r'C:\Python311\python.exe',
      
      // Windows user install locations
      r'C:\Users\Rafael\AppData\Local\Programs\Python\Python39\python.exe',
      r'C:\Users\Rafael\AppData\Local\Programs\Python\Python310\python.exe',
      r'C:\Users\Rafael\AppData\Local\Programs\Python\Python311\python.exe',
      
      // Windows Microsoft Store locations
      r'C:\Users\Rafael\AppData\Local\Microsoft\WindowsApps\python.exe',
      r'C:\Users\Rafael\AppData\Local\Microsoft\WindowsApps\python3.exe',
      
      // Anaconda/Miniconda locations
      r'C:\Users\Rafael\anaconda3\python.exe',
      r'C:\Users\Rafael\miniconda3\python.exe',
    ];
    
    for (final path in possiblePaths) {
      try {
        final result = await Process.run(path, ['-V']);
        if (result.exitCode == 0) {
          print('Found Python at: $path');
          return path;
        }
      } catch (e) {
        // Continue to the next path
      }
    }
    
    print('Python not found. Cannot proceed with detection');
    return null;
  }
  
  /// Find existing detector script
  Future<String?> _findDetectorScript() async {
    final possiblePaths = [
      'lib/algoritmo/IA.py',
      'lib/algoritmo/weapon_detector.py',
      r'c:\Users\Rafael\Desktop\app\CRUDCameras\lib\algoritmo\IA.py',
      r'c:\Users\Rafael\Desktop\app\CRUDCameras\lib\algoritmo\weapon_detector.py',
    ];
    
    for (final path in possiblePaths) {
      if (await File(path).exists()) {
        print('Found detector script at: $path');
        return path;
      }
    }
    return null;
  }
  
  /// Create a detector script based on the existing IA.py
  Future<String?> _createDetectorScript() async {
    final scriptPath = 'weapon_detector.py';
    
    try {
      final scriptFile = File(scriptPath);
      await scriptFile.writeAsString('''
import os
import sys
import json
import cv2
import numpy as np
import time
from PIL import Image
import base64
import io
import traceback

# Try to use the existing project's IA module
try:
    print("Trying to import WeaponDetector from IA module")
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    from IA import WeaponDetector
    print("Successfully imported WeaponDetector from IA")
except Exception as e:
    print(f"Error importing from IA module: {e}")
    traceback.print_exc()
    
    # Fallback implementation if IA module can't be imported
    try:
        print("Using fallback YOLOv5 implementation")
        import torch
        
        class WeaponDetector:
            def __init__(self, model_path=None):
                """Initialize the weapon detector with the given model path"""
                if model_path is None:
                    # Try to find the model in common locations
                    possible_paths = [
                        os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'models', 'violence_detectorAerithV2.pt'),
                        r'c:\\Users\\Rafael\\Desktop\\app\\CRUDCameras\\models\\violence_detectorAerithV2.pt',
                        os.path.join(os.getcwd(), 'models', 'violence_detectorAerithV2.pt'),
                    ]
                    
                    for path in possible_paths:
                        if os.path.exists(path):
                            model_path = path
                            break
                            
                    if model_path is None:
                        raise FileNotFoundError("Could not find the model file")
                        
                print(f"Loading model from {model_path}")
                self.model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path)
                self.model.conf = 0.25  # Confidence threshold
                self.model.iou = 0.45   # NMS IoU threshold
                print("Model loaded successfully")
                self.running = True
            
            def process_frame(self, frame):
                """Process a frame and return detection results"""
                # Run inference
                results = self.model(frame)
                
                # Extract results
                detections = []
                weapons_detected = False
                
                # Convert results to JSON-serializable format
                for pred in results.xyxy[0].tolist():  # xyxypred format: x1, y1, x2, y2, confidence, class
                    x1, y1, x2, y2, conf, cls = pred
                    class_name = self.model.names[int(cls)]
                    
                    # Determine if this is a weapon
                    if class_name.lower() in ['gun', 'knife', 'weapon', 'pistol', 'rifle']:
                        weapons_detected = True
                    
                    detections.append({
                        'class': class_name,
                        'confidence': float(conf),
                        'box': [float(x1), float(y1), float(x2), float(y2)]
                    })
                
                # Create result dictionary that mimics the original IA.py output
                self.latest_result = {
                    'weapons_detected': weapons_detected,
                    'alert_triggered': weapons_detected,
                    'detections': [(det['class'], det['confidence'], det['box']) for det in detections]
                }
                
                # Create notification if needed
                if weapons_detected:
                    self.notification = {'message': 'Arma detectada!'}
                else:
                    self.notification = None
            
            def start(self):
                """Start the detector"""
                self.running = True
                return True
                
            def stop(self):
                """Stop the detector"""
                self.running = False
            
            def get_latest_result(self):
                """Get the latest result"""
                return getattr(self, 'latest_result', None)
            
            def get_notification(self):
                """Get latest notification"""
                return getattr(self, 'notification', None)
    except Exception as e:
        print(f"Failed to create fallback implementation: {e}")
        traceback.print_exc()
        sys.exit(1)

def process_image(image_path, model_path=None):
    """Process an image file and return detection results"""
    try:
        # Create detector instance
        detector = WeaponDetector(model_path)
        
        # Read the image
        img = cv2.imread(image_path)
        if img is None:
            print(f"Failed to read image: {image_path}")
            return {"error": "Failed to read image"}
            
        # Process the frame
        detector.process_frame(img)
        
        # Get results
        result = detector.get_latest_result()
        notification = detector.get_notification();
        
        if result == null {
            return {
                'weapons_detected': false,
                'notification': false,
                'message': null,
                'detections': []
            };
        }
        
        // Format detections
        detections_list = [];
        for (class_name, confidence, box) in result.get('detections', []) {
          detections_list.add({
            'class': class_name,
            'confidence': confidence,
            'box': box
          });
        }
        
        return {
            'weapons_detected': result.get('weapons_detected', false),
            'alert_triggered': result.get('alert_triggered', false),
            'detections': detections_list,
            'notification': notification != null,
            'message': notification['message'] != null ? notification['message'] : null
        };
            
    } catch (e) {
        print(f"Error processing image: {e}");
        traceback.print_exc();
        return {"error": str(e)};
    }

def main():
    """Main function to be called when script is run directly"""
    if len(sys.argv) < 2:
        print("Usage: python weapon_detector.py <image_path> [<model_path>]");
        return 1;
        
    image_path = sys.argv[1];
    model_path = sys.argv[2] if len(sys.argv) > 2 else null;
    
    result = process_image(image_path, model_path);
    
    # Print result as JSON
    print(json.dumps(result));
    return 0;
}

if __name__ == "__main__":
    sys.exit(main())
''');
      return scriptPath;
    } catch (e) {
      print('Error creating detector script: $e');
      return null;
    }
  }
  
  /// Find the model file
  Future<String?> _findModelPath() async {
    final possiblePaths = [
      'models/violence_detectorAerithV2.pt',
      r'c:\Users\Rafael\Desktop\app\CRUDCameras\models\violence_detectorAerithV2.pt',
      r'violence_detectorAerithV2.pt',
    ];
    
    for (final path in possiblePaths) {
      if (await File(path).exists()) {
        print('Found model at: $path');
        return path;
      }
    }
    
    print('Could not find model file violence_detectorAerithV2.pt');
    return null;
  }
  
  /// Start detector process in background for better performance
  Future<bool> _startDetectorProcess() async {
    if (_pythonExecutable == null || _scriptPath == null || _modelPath == null) {
      print('Cannot start detector process: missing required paths');
      return false;
    }
    
    try {
      print('Starting detector process...');
      
      // Create a test image to verify everything works
      final testImage = await _createTestImage();
      
      // Run once to validate
      final result = await Process.run(
        _pythonExecutable!,
        [_scriptPath!, testImage.path, _modelPath!],
      );
      
      if (result.exitCode != 0) {
        print('Error validating detector: ${result.stderr}');
        return false;
      } else {
        print('Detector validation successful: ${result.stdout}');
      }
      
      return true;
    } catch (e) {
      print('Error starting detector process: $e');
      return false;
    }
  }
  
  /// Create a test image for validation
  Future<File> _createTestImage() async {
    try {
      final fileName = 'test_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(fileName);
      
      // Create a simple black image (10×10 pixels)
      final bytes = List<int>.filled(10 * 10 * 3, 0);
      await file.writeAsBytes(bytes);
      
      return file;
    } catch (e) {
      print('Error creating test image: $e');
      rethrow;
    }
  }

  /// Process an image file using the actual model
  Future<Map<String, dynamic>?> processImageFile(String imagePath) async {
    if (!_isInitialized) {
      print('Detector not initialized');
      return null;
    }
    
    if (_isProcessing) {
      print('Already processing an image');
      return null;
    }
    
    _isProcessing = true;
    
    try {
      // Check if the file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        print('Image file not found: $imagePath');
        _isProcessing = false;
        return null;
      }
      
      // Use Python to process the image
      final result = await Process.run(
        _pythonExecutable!,
        [_scriptPath!, imagePath, _modelPath!],
      );
      
      if (result.exitCode == 0) {
        try {
          final jsonResponse = jsonDecode(result.stdout as String);
          _isProcessing = false;
          return jsonResponse;
        } catch (e) {
          print('Error parsing JSON response: $e');
          print('Response: ${result.stdout}');
        }
      } else {
        print('Error running Python detector: ${result.stderr}');
      }
      
      _isProcessing = false;
      return null;
    } catch (e) {
      print('Error processing image file: $e');
      _isProcessing = false;
      return null;
    }
  }
  
  /// Process a camera frame
  Future<Map<String, dynamic>?> processFrame(CameraImage image) async {
    if (!_isInitialized || _isProcessing) {
      return null;
    }
    
    _isProcessing = true;
    
    try {
      // Save camera frame to a temp file
      final tempFile = await _saveImageToTempFile(image);
      if (tempFile == null) {
        _isProcessing = false;
        return null;
      }
      
      // Process the temp file
      final result = await processImageFile(tempFile.path);
      
      // Clean up
      try {
        await tempFile.delete();
      } catch (e) {
        print('Error deleting temp file: $e');
      }
      
      _isProcessing = false;
      return result;
    } catch (e) {
      print('Error processing camera frame: $e');
      _isProcessing = false;
      return null;
    }
  }
  
  /// Save camera image to temp file
  Future<File?> _saveImageToTempFile(CameraImage image) async {
    try {
      final tempFileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempFileName);
      
      // For YUV420 format (most common)
      if (image.format.group == ImageFormatGroup.yuv420) {
        // This is just the Y plane, which is a grayscale representation
        await tempFile.writeAsBytes(image.planes[0].bytes);
        return tempFile;
      } 
      
      // For JPEG format
      if (image.format.group == ImageFormatGroup.jpeg) {
        await tempFile.writeAsBytes(image.planes[0].bytes);
        return tempFile;
      }
      
      print('Unsupported image format: ${image.format.group}');
      return null;
    } catch (e) {
      print('Error saving image to temp file: $e');
      return null;
    }
  }

  /// Stop the detector
  Future<void> dispose() async {
    _isInitialized = false;
    
    if (_detectorProcess != null) {
      try {
        _detectorProcess!.kill();
        _detectorProcess = null;
      } catch (e) {
        print('Error stopping detector process: $e');
      }
    }
  }
}