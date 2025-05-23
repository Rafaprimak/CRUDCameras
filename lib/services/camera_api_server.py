from flask import Flask, request, jsonify
import os
import json
import time
import threading
from datetime import datetime
import sys
import cv2
import base64
import numpy as np
from pathlib import Path

# Try to import flask_cors or install it
try:
    from flask_cors import CORS
except ImportError:
    print("Flask-CORS not found. Attempting to install...")
    import subprocess
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "flask-cors"])
        from flask_cors import CORS
        print("Flask-CORS installed successfully!")
    except Exception as e:
        print(f"Failed to install Flask-CORS: {e}")
        # Fallback implementation of CORS
        print("Using fallback CORS implementation")
        
        # Simple CORS implementation to use if flask_cors is unavailable
        def CORS(app):
            @app.after_request
            def add_cors_headers(response):
                response.headers.add('Access-Control-Allow-Origin', '*')
                response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
                response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
                return response
            return app

import os
import json
import time
import threading
from datetime import datetime
import sys
import cv2
import base64
import numpy as np
from pathlib import Path

# Add path for importing weapon detector
sys.path.append(str(Path(__file__).parent.parent))
try:
    from algoritmo.IA import WeaponDetector
except ImportError:
    try:
        from algoritmo.weapon_detector import WeaponDetector
    except ImportError:
        print("Warning: Could not import WeaponDetector. Detection functionality will be disabled.")
        WeaponDetector = None

# Global detector instance
detector = None

def initialize_detector():
    """Initialize the weapon detector with the model"""
    global detector
    
    if WeaponDetector is None:
        print("WeaponDetector module not available")
        return False
        
    try:
        # Look for model in common paths with better diagnostics
        model_paths = [
            Path(__file__).parent.parent.parent / 'models' / 'violence_detectorAerithV2.pt',
            Path('models/violence_detectorAerithV2.pt'),
            Path(r'c:\Users\Rafael\Desktop\crud\CRUDCameras\models\violence_detectorAerithV2.pt')
        ]
        
        # Print all potential paths for debugging
        print("Checking model paths:")
        for path in model_paths:
            print(f" - {path} (exists: {path.exists()})")
            
        model_path = None
        for path in model_paths:
            if path.exists():
                model_path = str(path)
                print(f"Found model at: {model_path}")
                break
                
        if model_path is None:
            print("ERROR: Could not find the model file. Please place it in one of these locations:")
            for path in model_paths:
                print(f" - {path}")
            return False
            
        # Initialize detector with more detailed logging
        print(f"Creating WeaponDetector with model_path={model_path}")
        detector = WeaponDetector(model_path=model_path)
        print("WeaponDetector instance created, calling start()...")
        success = detector.start()
        print(f"Weapon detector initialized and started: {success}")
        return success
    except Exception as e:
        print(f"ERROR initializing detector: {e}")
        import traceback
        traceback.print_exc()
        return False

# Configuration
port = int(os.environ.get('CAMERA_API_PORT', 5556))
data_file = os.environ.get('CAMERA_DATA_FILE', 'camera_analytics.json')

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# In-memory storage
camera_status = {}
camera_analytics = {}
incident_reports = []
active_alerts = []

# Load existing data if available
def load_data():
    try:
        if os.path.exists(data_file):
            with open(data_file, 'r') as f:
                data = json.load(f)
                return data.get('analytics', {}), data.get('incidents', [])
        return {}, []
    except Exception as e:
        print(f"Error loading data: {e}")
        return {}, []

# Save data periodically
def save_data():
    while True:
        try:
            with open(data_file, 'w') as f:
                json.dump({
                    'analytics': camera_analytics,
                    'incidents': incident_reports
                }, f)
            print(f"Data saved to {data_file}")
        except Exception as e:
            print(f"Error saving data: {e}")
        time.sleep(300)  # Save every 5 minutes

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.now().isoformat(),
        'cameras_tracked': len(camera_status)
    })

# Camera status endpoints
@app.route('/cameras/status', methods=['GET'])
def get_all_camera_status():
    return jsonify(camera_status)

@app.route('/cameras/<camera_id>/status', methods=['GET'])
def get_camera_status(camera_id):
    if camera_id in camera_status:
        return jsonify(camera_status[camera_id])
    return jsonify({'error': 'Camera not found'}), 404

@app.route('/cameras/<camera_id>/status', methods=['POST'])
def update_camera_status(camera_id):
    data = request.json
    if not data:
        return jsonify({'error': 'No data provided'}), 400
        
    # Update camera status
    if camera_id not in camera_status:
        camera_status[camera_id] = {}
    
    camera_status[camera_id].update(data)
    camera_status[camera_id]['last_update'] = datetime.now().isoformat()
    
    # Update analytics
    if camera_id not in camera_analytics:
        camera_analytics[camera_id] = {
            'connection_history': [],
            'uptime_seconds': 0,
            'failure_count': 0
        }
    
    # Record connection status changes
    if 'connected' in data:
        camera_analytics[camera_id]['connection_history'].append({
            'timestamp': datetime.now().isoformat(),
            'connected': data['connected']
        })
        
        # Limit history size
        if len(camera_analytics[camera_id]['connection_history']) > 100:
            camera_analytics[camera_id]['connection_history'] = camera_analytics[camera_id]['connection_history'][-100:]
            
        # Update failure count
        if not data['connected']:
            camera_analytics[camera_id]['failure_count'] += 1
    
    return jsonify({'success': True})

# Analytics endpoints
@app.route('/analytics', methods=['GET'])
def get_analytics():
    return jsonify(camera_analytics)

@app.route('/analytics/<camera_id>', methods=['GET'])
def get_camera_analytics(camera_id):
    if camera_id in camera_analytics:
        return jsonify(camera_analytics[camera_id])
    return jsonify({'error': 'Camera analytics not found'}), 404

# Incident reporting endpoints
@app.route('/incidents', methods=['GET'])
def get_incidents():
    return jsonify(incident_reports)

@app.route('/incidents', methods=['POST'])
def create_incident():
    data = request.json
    if not data or 'description' not in data:
        return jsonify({'error': 'Invalid incident data'}), 400
        
    # Create incident report
    incident = {
        'id': len(incident_reports) + 1,
        'timestamp': datetime.now().isoformat(),
        'description': data['description'],
        'camera_id': data.get('camera_id'),
        'severity': data.get('severity', 'medium'),
        'status': 'open'
    }
    
    incident_reports.append(incident)
    return jsonify(incident)

# Alert management endpoints
@app.route('/alerts', methods=['GET'])
def get_alerts():
    return jsonify(active_alerts)

@app.route('/alerts', methods=['POST'])
def create_alert():
    data = request.json
    if not data or 'message' not in data:
        return jsonify({'error': 'Invalid alert data'}), 400
        
    # Create alert
    alert = {
        'id': len(active_alerts) + 1,
        'timestamp': datetime.now().isoformat(),
        'message': data['message'],
        'camera_id': data.get('camera_id'),
        'type': data.get('type', 'info'),
        'acknowledged': False
    }
    
    active_alerts.append(alert)
    return jsonify(alert)

@app.route('/alerts/<int:alert_id>/acknowledge', methods=['POST'])
def acknowledge_alert(alert_id):
    for alert in active_alerts:
        if alert['id'] == alert_id:
            alert['acknowledged'] = True
            return jsonify(alert)
    
    return jsonify({'error': 'Alert not found'}), 404

# Detection endpoints
@app.route('/detection/status', methods=['GET'])
def get_detection_status():
    global detector
    detector_state = "not initialized"
    
    if detector is not None:
        detector_state = "running" if getattr(detector, 'running', False) else "not running"
    
    return jsonify({
        'status': detector_state,
        'available': detector is not None
    })

@app.route('/detection/start', methods=['GET', 'POST'])
def start_detection():
    global detector
    
    if detector is None:
        success = initialize_detector()
        if not success:
            return jsonify({'error': 'Failed to initialize detector'}), 500
    
    if hasattr(detector, 'start'):
        success = detector.start()
        return jsonify({'success': success})
    
    return jsonify({'success': False, 'error': 'Detector not properly initialized'}), 500

@app.route('/detection/stop', methods=['POST'])
def stop_detection():
    global detector
    
    if detector is not None and hasattr(detector, 'stop'):
        detector.stop()
        return jsonify({'success': True})
    
    return jsonify({'success': False, 'error': 'Detector not running'}), 400

@app.route('/detection/detect', methods=['POST'])
def detect_objects():
    global detector
    
    # Check if detector is initialized
    if detector is None:
        success = initialize_detector()
        if not success:
            return jsonify({'error': 'Detector not available'}), 500
    
    # Get image from request
    if not request.json or 'image' not in request.json:
        return jsonify({'error': 'No image provided'}), 400
    
    try:
        # Decode base64 image
        encoded_data = request.json['image']
        camera_id = request.json.get('camera_id')
        
        nparr = np.frombuffer(base64.b64decode(encoded_data), np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            return jsonify({'error': 'Invalid image data'}), 400
        
        # Process the frame
        detector.process_frame(image)
        
        # Get detection result
        result = detector.get_latest_result()
        
        # Check for notifications
        notification = detector.get_notification()
        
        # If weapons detected, create an alert
        if result and result.get('weapons_detected'):
            alert_message = notification['message'] if notification and 'message' in notification else "Arma detectada!"
            
            # Create alert
            alert = {
                'id': len(active_alerts) + 1,
                'timestamp': datetime.now().isoformat(),
                'message': alert_message,
                'camera_id': camera_id,
                'type': 'danger',
                'acknowledged': False
            }
            active_alerts.append(alert)
        
        # Format detections for JSON response
        detections_list = []
        if result and 'detections' in result:
            for detection in result['detections']:
                if isinstance(detection, tuple) and len(detection) >= 3:
                    class_name, confidence, box = detection
                    detections_list.append({
                        'class': class_name,
                        'confidence': confidence,
                        'box': box
                    })
                else:
                    # Handle alternative formats
                    detections_list.append(detection)
        
        return jsonify({
            'weapons_detected': result.get('weapons_detected', False) if result else False,
            'alert_triggered': result.get('alert_triggered', False) if result else False,
            'detections': detections_list,
            'notification': notification is not None,
            'message': notification['message'] if notification else None
        })
    
    except Exception as e:
        print(f"Error processing detection: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/detection/diagnostics', methods=['GET'])
def detector_diagnostics():
    """Endpoint for checking detector status and configuration"""
    global detector
    
    # Check Python path for debugging
    python_paths = sys.path
    
    # Check if model file exists
    model_paths = [
        str(Path(__file__).parent.parent.parent / 'models' / 'violence_detectorAerithV2.pt'),
        str(Path('models/violence_detectorAerithV2.pt')),
        r'c:\Users\Rafael\Desktop\crud\CRUDCameras\models\violence_detectorAerithV2.pt'
    ]
    existing_models = [path for path in model_paths if os.path.exists(path)]
    
    # Check detector initialization
    detector_info = "Not initialized"
    if detector is not None:
        detector_info = {
            "running": getattr(detector, "running", False),
            "model_path": getattr(detector, "model_path", "Unknown"),
            "model_loaded": getattr(detector, "model", None) is not None,
            "class": detector.__class__.__name__
        }
    
    return jsonify({
        "detector": detector_info,
        "model_paths_checked": model_paths,
        "existing_models": existing_models,
        "python_path": python_paths,
        "current_directory": os.getcwd()
    })

if __name__ == '__main__':
    # Load existing data
    loaded_analytics, loaded_incidents = load_data()
    camera_analytics = loaded_analytics
    incident_reports = loaded_incidents
    
    # Start data saving thread
    save_thread = threading.Thread(target=save_data, daemon=True)
    save_thread.start()
    
    # Initialize weapon detector with better error handling
    print("Initializing weapon detector...")
    detector_initialized = initialize_detector()
    if detector_initialized:
        print("Weapon detector initialized successfully.")
    else:
        print("WARNING: Weapon detector initialization failed. Detection features will be disabled.")
    
    # Log startup info
    print(f"Starting camera API server on port {port}...")
    print(f"Current directory: {os.getcwd()}")
    print(f"Python version: {sys.version}")
    print(f"OpenCV version: {cv2.__version__}")
    
    # Check if detector is working
    if detector is not None and hasattr(detector, 'running'):
        print(f"Detector running status: {detector.running}")
    else:
        print("Detector not properly initialized")
    
    try:
        app.run(host='0.0.0.0', port=port, debug=True)
    except Exception as e:
        print(f"Error starting server: {e}")