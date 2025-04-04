import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../services/camera_service.dart';
import '../utils/custom_route.dart';
import 'camera_details_screen.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/armadillo_logo.png',
          ),
        ),
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
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFe9e9e6), 
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
          _buildCameraList(),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('S.O.S'),
                      content: const Text('Enviando pedido de socorro...'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff1b1c),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded),
                    SizedBox(width: 8),
                    Text('S.O.S'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(24),
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
                Text(camera.address),
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
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Ver detalhes',
                  onPressed: () => _navigateToCameraDetails(context, camera),
                ),
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

  void _navigateToCameraDetails(BuildContext context, Camera camera) {
    Navigator.push(
      context,
      CustomPageRoute(
        child: CameraDetailsScreen(camera: camera),
      ),
    );
  }
}