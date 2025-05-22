import cv2
import numpy as np
import os
import time
import queue
import threading
from ultralytics import YOLO
from collections import deque
import onnxruntime as ort

class WeaponDetector:
    def __init__(self, model_path=None, conf_threshold=0.5, detection_threshold=3, cooldown_period=30):
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
        
        # Detection state tracking
        self.recent_detections = deque(maxlen=30)  # Stores recent detection states (True/False)
        self.last_notification_time = 0
        self.notification_queue = queue.Queue()
        self.detection_active = False
        
        # Processing queues and threading
        self.frame_queue = queue.Queue(maxsize=10)
        self.result_queue = queue.Queue()
        self.running = False
        self._load_model(model_path)
        
    def _load_model(self, model_path):
        """Load the weapon detection model"""
        try:
            print(f"Loading model from: {model_path}")
            self.model = YOLO(model_path)
            print("Model loaded successfully")
        except Exception as e:
            print(f"Error loading model: {e}")
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
                self.frame_queue.put(frame, block=False)
                return True
            except queue.Full:
                return False
        return False
        
    def _detection_loop(self):
        """Main detection thread loop"""
        while self.running:
            try:
                # Get frame from queue with timeout to allow checking running state
                frame = self.frame_queue.get(timeout=1.0)
                
                # Perform detection
                results = self.model.predict(
                    source=frame,
                    conf=self.conf_threshold,
                    verbose=False
                )
                
                # Process results
                weapons_detected = False
                detections = []
                
                if results and len(results) > 0:
                    for result in results:
                        # Check for weapons in the detected objects
                        if result.boxes is not None and len(result.boxes) > 0:
                            for box in result.boxes:
                                if box.conf >= self.conf_threshold:
                                    # Get class name and check if it's a weapon
                                    cls = int(box.cls[0])
                                    class_name = self.model.names[cls]
                                    
                                    # Assuming "weapon" or "gun" or similar would be in class names
                                    if "weapon" in class_name.lower() or "gun" in class_name.lower():
                                        weapons_detected = True
                                        x1, y1, x2, y2 = box.xyxy[0].tolist()
                                        confidence = float(box.conf[0])
                                        detections.append((class_name, confidence, (x1, y1, x2, y2)))
                
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
                pass
            except Exception as e:
                print(f"Error in detection loop: {e}")
                
    def _check_detection_threshold(self):
        """Check if detection threshold has been reached and trigger notification if necessary"""
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
                
        # Reset detection active state if no detections for a while
        elif detection_count == 0 and self.detection_active:
            self.detection_active = False
    
    def _send_notification(self, message):
        """Send a notification about detected weapon"""
        print(f"WEAPON ALERT: {message}")
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