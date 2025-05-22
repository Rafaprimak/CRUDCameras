import cv2
import numpy as np
import os
import time
import queue
import threading
from collections import deque
import traceback

class WeaponDetector:
    def __init__(self, model_path=None, conf_threshold=0.25, detection_threshold=2, cooldown_period=10):
        """
        Initialize the weapon detection model
        
        Args:
            model_path: Path to the YOLO model file
            conf_threshold: Minimum confidence for detection
            detection_threshold: Number of detections required to trigger alert
            cooldown_period: Seconds to wait before a new alert can be triggered
        """
        # Set defaults
        if model_path is None:
            model_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'models')
            model_path = os.path.join(model_dir, 'violence_detectorAerithV2.pt')
        
        # Model parameters
        self.conf_threshold = conf_threshold
        self.detection_threshold = detection_threshold
        self.cooldown_period = cooldown_period
        self.model_path = model_path
        
        # Detection state tracking
        self.recent_detections = deque(maxlen=10)  # Reduced size for faster response
        self.last_notification_time = 0
        self.detection_active = False
        
        # Processing queues and threading
        self.frame_queue = queue.Queue(maxsize=5)  # Smaller queue to reduce latency
        self.result_queue = queue.Queue()
        self.notification_queue = queue.Queue()
        self.running = False
        self.model = None
        
        # Try to load the model immediately
        self._load_model(model_path)
        
    def _load_model(self, model_path):
        """Load the weapon detection model"""
        if not os.path.exists(model_path):
            print(f"Error: Model file not found at {model_path}")
            return
            
        try:
            print(f"Loading model from: {model_path}")
            # Try YOLOv8 first (ultralytics package)
            try:
                from ultralytics import YOLO
                self.model = YOLO(model_path)
                print("Model loaded successfully with ultralytics YOLO")
            except ImportError:
                # Fall back to YOLOv5 with torch hub
                import torch
                self.model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path)
                self.model.conf = self.conf_threshold
                self.model.iou = 0.45  # NMS IoU threshold
                print("Model loaded successfully with torch.hub YOLOv5")
        except Exception as e:
            print(f"Error loading model: {e}")
            traceback.print_exc()
            self.model = None
            
    def start(self):
        """Start the detection thread"""
        if self.model is None:
            print("Cannot start - model not loaded")
            return False
            
        self.running = True
        self.detection_thread = threading.Thread(target=self._detection_loop)
        self.detection_thread.daemon = True
        self.detection_thread.start()
        print("Weapon detection started")
        return True
        
    def stop(self):
        """Stop the detection thread"""
        self.running = False
        if hasattr(self, 'detection_thread') and self.detection_thread.is_alive():
            self.detection_thread.join(timeout=2.0)
        print("Weapon detection stopped")
        
    def process_frame(self, frame):
        """Add a frame to the processing queue"""
        if self.running:
            try:
                # Replace the oldest frame if queue is full to avoid blocking
                if self.frame_queue.full():
                    try:
                        self.frame_queue.get_nowait()
                    except queue.Empty:
                        pass
                
                self.frame_queue.put(frame, block=False)
                return True
            except queue.Full:
                return False
        else:
            # Auto-start if not running
            if self.model is not None:
                self.start()
                return self.process_frame(frame)
        return False
        
    def _detection_loop(self):
        """Main detection thread loop"""
        while self.running:
            try:
                # Get frame from queue with timeout to allow checking running state
                frame = self.frame_queue.get(timeout=0.5)  # Shorter timeout for responsiveness
                
                # Perform detection
                if hasattr(self.model, 'predict'):  # YOLOv8 style
                    results = self.model.predict(
                        source=frame,
                        conf=self.conf_threshold,
                        verbose=False
                    )
                else:  # YOLOv5 style
                    results = self.model(frame)
                
                # Process results
                weapons_detected = False
                detections = []
                
                # Different processing depending on the model type
                if hasattr(results, 'xyxy'):  # YOLOv5 style results
                    for pred in results.xyxy[0].tolist():
                        x1, y1, x2, y2, conf, cls = pred
                        class_name = self.model.names[int(cls)]
                        
                        if self._is_weapon_class(class_name):
                            weapons_detected = True
                            
                        detections.append((class_name, float(conf), (x1, y1, x2, y2)))
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
                                
                                if self._is_weapon_class(class_name):
                                    weapons_detected = True
                                    
                                detections.append((class_name, conf, (x1, y1, x2, y2)))
                
                # Update detection history
                self.recent_detections.append(weapons_detected)
                
                # Check if we should trigger notification
                self._check_detection_threshold()
                
                # Store processed results
                self.result_queue.put({
                    'frame': frame,
                    'weapons_detected': weapons_detected,
                    'detections': detections,
                    'alert_triggered': self.detection_active
                })
                
                self.frame_queue.task_done()
                
            except queue.Empty:
                pass  # Just continue if no frames
            except Exception as e:
                print(f"Error in detection loop: {e}")
                traceback.print_exc()
                
    def _is_weapon_class(self, class_name):
        """Check if the class name represents a weapon"""
        weapon_classes = ['gun', 'pistol', 'rifle', 'knife', 'weapon', 'firearms', 'arma']
        class_lower = class_name.lower()
        return any(wc in class_lower for wc in weapon_classes)
                
    def _check_detection_threshold(self):
        """Check if detection threshold has been reached and trigger notification if necessary"""
        if not self.recent_detections:
            return
            
        # Count True values in the recent detections
        detection_count = sum(1 for d in self.recent_detections if d)
        
        # Check for cooldown period
        current_time = time.time()
        time_since_last_notification = current_time - self.last_notification_time
        
        if detection_count >= self.detection_threshold and time_since_last_notification > self.cooldown_period:
            if not self.detection_active:
                self.detection_active = True
                self.last_notification_time = current_time
                self._send_notification("ALERTA: Arma detectada pela câmera!")
                print("🚨 WEAPON ALERT TRIGGERED! 🚨")
                
        # Reset detection active state if no detections for a while
        elif detection_count == 0 and self.detection_active:
            self.detection_active = False
            
    def _send_notification(self, message):
        """Send a notification about detected weapon"""
        print(f"WEAPON ALERT: {message}")
        
        # Clear any old notifications
        while not self.notification_queue.empty():
            try:
                self.notification_queue.get_nowait()
            except queue.Empty:
                break
                
        # Add the new notification
        self.notification_queue.put({
            'message': message,
            'timestamp': time.time()
        })
        
    def get_latest_result(self):
        """Get the latest processing result if available"""
        try:
            return self.result_queue.get(block=False)
        except queue.Empty:
            return None
            
    def get_notification(self):
        """Get pending notification if available"""
        try:
            return self.notification_queue.get(block=False)
        except queue.Empty:
            return None