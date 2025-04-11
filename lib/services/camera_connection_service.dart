import 'dart:async';
//import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/camera.dart';
import 'onvif_service.dart';

class CameraConnectionService {
  static final CameraConnectionService _instance = CameraConnectionService._internal();
  final Map<String, OnvifService> _onvifServices = {};
  
  factory CameraConnectionService() {
    return _instance;
  }
  
  CameraConnectionService._internal();
  
  // Verifica se uma câmera está acessível
  Future<bool> pingCamera(Camera camera) async {
    try {
      final ipAddress = camera.ipAddress;
      final response = await http.get(
        Uri.parse('http://$ipAddress/'),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Erro ao conectar com câmera: $e');
      return false;
    }
  }
  
  // Obter URL de streaming RTSP para a câmera
  String getRtspUrl(Camera camera) {
    final credentials = '${camera.username}:${camera.password}';
    final ipAddress = camera.ipAddress;
    final port = camera.port;
    
    switch (camera.brand.toLowerCase()) {
      case 'hikvision':
        return 'rtsp://$credentials@$ipAddress:$port/h264/ch1/main/av_stream';
      case 'dahua':
        return 'rtsp://$credentials@$ipAddress:$port/cam/realmonitor?channel=1&subtype=0';
      case 'axis':
        return 'rtsp://$credentials@$ipAddress:$port/axis-media/media.amp';
      case 'foscam':
        return 'rtsp://$credentials@$ipAddress:$port/videoMain';
      default:
        return 'rtsp://$credentials@$ipAddress:$port/stream1';
    }
  }
  
  // Obter ou criar instância ONVIF para a câmera
  Future<OnvifService?> _getOnvifService(Camera camera) async {
    if (!_onvifServices.containsKey(camera.id)) {
      final onvifService = OnvifService(
        ipAddress: camera.ipAddress,
        port: camera.onvifPort ?? 80, // Adicione este campo ao modelo Camera
        username: camera.username,
        password: camera.password,
      );
      
      final initialized = await onvifService.initialize();
      if (initialized) {
        _onvifServices[camera.id] = onvifService;
      } else {
        return null;
      }
    }
    
    return _onvifServices[camera.id];
  }
  
  // Comando de PTZ (Pan/Tilt/Zoom)
  Future<bool> movePtz(Camera camera, String direction, double speed) async {
    try {
      final onvifService = await _getOnvifService(camera);
      if (onvifService == null) {
        return false;
      }
      
      return await onvifService.movePtz(direction, speed);
    } catch (e) {
      print('Erro ao enviar comando PTZ: $e');
      return false;
    }
  }
  
  // Parar movimento PTZ
  Future<bool> stopPtz(Camera camera) async {
    try {
      final onvifService = await _getOnvifService(camera);
      if (onvifService == null) {
        return false;
      }
      
      return await onvifService.stopPtz();
    } catch (e) {
      print('Erro ao parar movimento: $e');
      return false;
    }
  }
}