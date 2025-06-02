import os
import sys
import json
import cv2
import numpy as np
import time
import traceback

class WeaponDetector:
    """Standalone weapon detector using YOLOv5 or YOLOv8"""
    
    def __init__(self, model_path=None):
        """Initialize the weapon detector"""
        self.model = None
        self.notification = None
        self.latest_result = None
        self.running = False
        
        # Find the model file if not specified
        if model_path is None:
            possible_paths = [
                os.path.join(os.path.dirname(__file__), '..', '..', 'models', 'violence_detectorAerithV2.pt'),
                r'c:\Users\Rafael\Desktop\app\CRUDCameras\models\violence_detectorAerithV2.pt',
                os.path.join(os.getcwd(), 'models', 'violence_detectorAerithV2.pt'),
            ]
            
            for path in possible_paths:
                if os.path.exists(path):
                    model_path = path
                    break
                    
        if model_path is None or not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found at: {model_path}")
            
        print(f"Loading model from {model_path}")
        
        # Try to use different YOLO backends, starting with the most likely
        try:
            # Try YOLOv8 first (ultralytics package)
            from ultralytics import YOLO
            self.model = YOLO(model_path)
            print("Model loaded successfully with ultralytics.YOLO")
        except Exception as e:
            print(f"Failed to load with ultralytics.YOLO: {e}")
            try:
                # Try YOLOv5 using torch hub
                import torch
                self.model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path)
                self.model.conf = 0.25  # Confidence threshold
                self.model.iou = 0.45   # NMS IoU threshold
                print("Model loaded successfully with torch.hub (YOLOv5)")
            except Exception as e2:
                print(f"Failed to load with torch.hub: {e2}")
                traceback.print_exc()
                raise RuntimeError("Could not load model with any available backend")
                
        self.running = True
        print("Detector initialized successfully")
    
    def process_frame(self, frame):
        """Process a frame and detect weapons"""
        if not self.running or self.model is None:
            return False
            
        try:
            # Process the frame with the model
            results = self.model(frame)
            
            # Extract detection results
            detections = []
            weapons_detected = False
            
            # Different processing depending on the model type
            if hasattr(results, 'xyxy'):  # YOLOv5 style results
                for pred in results.xyxy[0].tolist():
                    x1, y1, x2, y2, conf, cls = pred
                    class_name = self.model.names[int(cls)]
                    
                    # Check if this is a weapon
                    if self._is_weapon_class(class_name):
                        weapons_detected = True
                        
                    detections.append((class_name, float(conf), [float(x1), float(y1), float(x2), float(y2)]))
            else:  # YOLOv8 style results
                for r in results:
                    if r.boxes is not None:
                        for box in r.boxes:
                            # Get class ID and name
                            cls = int(box.cls[0])
                            class_name = self.model.names[cls]
                            conf = float(box.conf[0])
                            
                            # Get bounding box
                            x1, y1, x2, y2 = box.xyxy[0].tolist()
                            
                            # Check if this is a weapon
                            if self._is_weapon_class(class_name):
                                weapons_detected = True
                                
                            detections.append((class_name, conf, [x1, y1, x2, y2]))
            
            # Update latest result
            self.latest_result = {
                'weapons_detected': weapons_detected,
                'alert_triggered': weapons_detected,
                'detections': detections
            }
            
            # Create notification if weapon detected
            if weapons_detected:
                self.notification = {'message': 'ALERTA: Arma detectada pela câmera!'}
                print("🚨 WEAPON DETECTED! 🚨")
            else:
                self.notification = None
                
            return True
        except Exception as e:
            print(f"Error processing frame: {e}")
            traceback.print_exc()
            return False
            
    def _is_weapon_class(self, class_name):
        """Check if the class name represents a weapon that should trigger alerts"""
        # APENAS estas classes específicas devem gerar alertas
        weapon_classes = ['gun', 'pistol', 'rifle', 'firearms', 'knife', 'weapon']
        class_lower = class_name.lower()
        
        # Verificação exata para evitar falsos positivos
        for weapon_class in weapon_classes:
            if weapon_class in class_lower:
                return True
        
        return False
    
    def start(self):
        """Start the detector"""
        self.running = True
        return True
        
    def stop(self):
        """Stop the detector"""
        self.running = False
        
    def get_latest_result(self):
        """Get the latest detection result"""
        return self.latest_result
        
    def get_notification(self):
        """Get any pending notifications"""
        notification = self.notification
        self.notification = None  # Clear after getting
        return notification

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
        notification = detector.get_notification()
        
        # Format detection results for JSON
        if result is None:
            return {
                'weapons_detected': False,
                'notification': False,
                'message': None,
                'detections': []
            }
        
        # Format detections for JSON response
        detections_list = []
        for class_name, confidence, box in result.get('detections', []):
            detections_list.append({
                'class': class_name,
                'confidence': confidence,
                'box': box
            })
        
        return {
            'weapons_detected': result.get('weapons_detected', False),
            'alert_triggered': result.get('alert_triggered', False),
            'detections': detections_list,
            'notification': notification is not None,
            'message': notification['message'] if notification else None
        }
    
    except Exception as e:
        print(f"Error processing image: {e}")
        traceback.print_exc()
        return {"error": str(e)}

def main():
    """Main function to be called when script is run directly"""
    if len(sys.argv) < 2:
        print("Usage: python weapon_detector.py <image_path> [<model_path>]")
        return 1
        
    image_path = sys.argv[1]
    model_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    result = process_image(image_path, model_path)
    
    # Print result as JSON
    print(json.dumps(result))
    return 0

if __name__ == "__main__":
    sys.exit(main())