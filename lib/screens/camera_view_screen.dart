// lib/screens/camera_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../models/camera.dart';
import '../services/camera_connection_service.dart';

class CameraViewScreen extends StatefulWidget {
  final Camera camera;

  const CameraViewScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraViewScreenState createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  final CameraConnectionService _connectionService = CameraConnectionService();
  VlcPlayerController? _videoPlayerController;
  bool _isConnecting = true;
  bool _connectionFailed = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    setState(() {
      _isConnecting = true;
      _connectionFailed = false;
    });

    try {
      // Verificar se a câmera está online
      bool isOnline = await _connectionService.pingCamera(widget.camera);
      
      if (!isOnline) {
        setState(() {
          _isConnecting = false;
          _connectionFailed = true;
          _errorMessage = 'Câmera não está respondendo';
        });
        return;
      }
      
      // Obter URL de streaming
      final rtspUrl = _connectionService.getRtspUrl(widget.camera);
      
      // Inicializar o player
      _videoPlayerController = VlcPlayerController.network(
        rtspUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
          rtp: VlcRtpOptions([
            VlcRtpOptions.rtpOverRtsp(true),
          ]),
        ),
      );

      // Ouvinte para erros de conexão
      _videoPlayerController!.addOnInitListener(() {
        setState(() {
          _isConnecting = false;
        });
      });
      
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError) {
          setState(() {
            _isConnecting = false;
            _connectionFailed = true;
            _errorMessage = 'Erro de conexão: ${_videoPlayerController!.value.errorDescription}';
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionFailed = true;
        _errorMessage = 'Erro: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camera.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializePlayer,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: _isConnecting 
                ? const Center(child: CircularProgressIndicator())
                : _connectionFailed
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializePlayer,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _videoPlayerController != null
                    ? VlcPlayer(
                        controller: _videoPlayerController!,
                        aspectRatio: 16 / 9,
                        placeholder: const Center(child: CircularProgressIndicator()),
                      )
                    : const Center(child: Text('Player não inicializado')),
            ),
          ),
          
          // Controles PTZ
          if (!_connectionFailed && !_isConnecting)
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPtzButton(Icons.arrow_upward, 'up'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPtzButton(Icons.arrow_back, 'left'),
                      const SizedBox(width: 50),
                      _buildPtzButton(Icons.arrow_forward, 'right'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPtzButton(Icons.arrow_downward, 'down'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPtzButton(IconData icon, String direction) {
    return ElevatedButton(
      onPressed: () {
        _connectionService.movePtz(widget.camera, direction, 0.5);
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
      child: Icon(icon),
    );
  }

  void _showSettingsDialog() {
    // Implementar um diálogo para ajustar configurações da câmera
  }
}