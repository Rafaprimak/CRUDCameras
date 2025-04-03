import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../services/camera_service.dart';
import '../utils/custom_route.dart';
import 'camera_form_screen.dart';
import 'welcome_screen.dart';

class CameraListScreen extends StatefulWidget {
  const CameraListScreen({super.key});

  @override
  State<CameraListScreen> createState() => _CameraListScreenState();
}

class _CameraListScreenState extends State<CameraListScreen> {
  final CameraService _cameraService = CameraService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Câmeras Cadastradas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair do aplicativo'),
                  content: const Text('Tem certeza que deseja sair?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const WelcomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _buildCameraList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCameraForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCameraList() {
    final cameras = _cameraService.cameras;
    
    if (cameras.isEmpty) {
      return const Center(
        child: Text('Nenhuma câmera cadastrada'),
      );
    }
    
    return ListView.builder(
      itemCount: cameras.length,
      itemBuilder: (context, index) {
        final camera = cameras[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: camera.isActive ? Colors.green.shade300 : Colors.red.shade300,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: camera.isActive ? Colors.green : Colors.red,
              ),
            ),
            title: Text(camera.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${camera.brand} ${camera.model}'),
                Text('IP: ${camera.ipAddress}'),
                Text(
                  camera.isActive ? 'Ativa' : 'Inativa',
                  style: TextStyle(
                    color: camera.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToCameraForm(context, camera: camera),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToCameraForm(BuildContext context, {Camera? camera}) async {
    final result = await Navigator.push(
      context,
      CustomPageRoute(
        child: CameraFormScreen(camera: camera),
      ),
    );

    if (result != null) {
      setState(() {});
    }
  }

  void _showDeleteDialog(Camera camera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir câmera'),
        content: Text('Deseja realmente excluir a câmera ${camera.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _cameraService.deleteCamera(camera.id);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}