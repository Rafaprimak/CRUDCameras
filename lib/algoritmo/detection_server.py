from flask import Flask, request, jsonify
import numpy as np
import cv2
import base64
from IA import WeaponDetector
import threading
import time
import os
import sys

# Use environment variable for port or a random high port
port = int(os.environ.get('PORT', 5555))
model_path = os.environ.get('MODEL_PATH', None)

app = Flask(__name__)

# Global detector instance
detector = None

def initialize_detector():
    global detector
    try:
        # Make sure to use the specified model
        if model_path:
            print(f"Using specified model path: {model_path}")
            detector = WeaponDetector(model_path=model_path)
        else:
            detector = WeaponDetector()  # Will use default path from IA.py
            
        # Start the detector
        success = detector.start()
        print(f"Detector started: {success}")
        return success
    except Exception as e:
        print(f"Error initializing detector: {e}")
        return False

# Initialize the detector when server starts
initialize_detector()

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'ok', 
        'detector_running': detector is not None and detector.running,
        'model_path': model_path if model_path else 'default'
    })

@app.route('/detect', methods=['POST'])
def detect_weapons():
    global detector
    
    if detector is None or not detector.running:
        initialize_detector()
        if detector is None or not detector.running:
            return jsonify({'error': 'Detector is not running'}), 500
    
    # Get image from request
    if 'image' not in request.json:
        return jsonify({'error': 'No image provided'}), 400
    
    try:
        # Decode base64 image
        encoded_data = request.json['image']
        nparr = np.frombuffer(base64.b64decode(encoded_data), np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # Process frame
        detector.process_frame(image)
        
        # Check for notifications
        notification = detector.get_notification()
        
        # Get latest result
        result = detector.get_latest_result()
        
        if result is None:
            return jsonify({
                'weapons_detected': False,
                'notification': notification is not None,
                'message': notification['message'] if notification else None
            })
        
        # Format detection results
        detections_list = []
        for class_name, confidence, box in result.get('detections', []):
            detections_list.append({
                'class': class_name,
                'confidence': confidence,
                'box': box
            })
        
        return jsonify({
            'weapons_detected': result.get('weapons_detected', False),
            'alert_triggered': result.get('alert_triggered', False),
            'detections': detections_list,
            'notification': notification is not None,
            'message': notification['message'] if notification else None
        })
    
    except Exception as e:
        print(f"Error processing detection request: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/start', methods=['POST'])
def start_detector():
    global detector
    if detector is None:
        success = initialize_detector()
        return jsonify({'success': success})
        
    if not detector.running:
        success = detector.start()
        return jsonify({'success': success})
        
    return jsonify({'success': True, 'message': 'Detector already running'})

@app.route('/stop', methods=['POST'])
def stop_detector():
    global detector
    if detector and detector.running:
        detector.stop()
    return jsonify({'success': True})

if __name__ == '__main__':
    # Log startup info
    print(f"Starting detector server on port {port}...")
    print(f"Python executable: {sys.executable}")
    print(f"Current directory: {os.getcwd()}")
    print(f"Model path: {model_path}")
    
    try:
        # Try to start on the requested port
        app.run(host='127.0.0.1', port=port)
    except OSError as e:
        print(f"Error on port {port}: {e}")
        # Try a random higher port
        random_port = port + 100
        print(f"Trying alternate port {random_port}...")
        app.run(host='127.0.0.1', port=random_port)