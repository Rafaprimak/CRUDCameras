import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/camera.dart';
import '../services/camera_service.dart';
import '../services/camera_group_service.dart';
import 'camera_form_screen.dart';

class CameraDetailsScreen extends StatefulWidget {
  final Camera camera;

  const CameraDetailsScreen({super.key, required this.camera});

  @override
  State<CameraDetailsScreen> createState() => _CameraDetailsScreenState();
}

class _CameraDetailsScreenState extends State<CameraDetailsScreen> with SingleTickerProviderStateMixin {
  late Camera _camera;
  final CameraService _cameraService = CameraService();
  final CameraGroupService _groupService = CameraGroupService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _camera = widget.camera;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customYellow = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, 
        backgroundColor: customYellow,
        elevation: 2,
        title: const Text(
          'Detalhes da Câmera',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar câmera',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => CameraFormScreen(camera: _camera),
                ),
              );
              
              if (result == true) {
                setState(() {
                  final updatedCamera = _cameraService.getCameraById(_camera.id);
                  if (updatedCamera != null) {
                    _camera = updatedCamera;
                  }
                });
              }
            },
          ),
        ],
      ),
      
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              customYellow.withAlpha(13), 
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context),
                    const SizedBox(height: 24),
                    
                    _buildInfoCard(
                      context,
                      'Informações Gerais',
                      Icons.info_outline,
                      [
                        _buildInfoRow(context, Icons.camera_alt, 'Nome:', _camera.name),
                        _buildInfoRow(context, Icons.location_on, 'Endereço:', _camera.address), 
                        _buildInfoRow(context, Icons.business, 'Marca:', _camera.brand),
                        _buildInfoRow(context, Icons.devices, 'Modelo:', _camera.model),
                        _buildGroupInfoRow(context),
                      ],
                    ),
                    
                    _buildInfoCard(
                      context,
                      'Configurações de Rede',
                      Icons.router,
                      [
                        _buildInfoRow(context, Icons.wifi, 'Endereço IP:', _camera.ipAddress),
                      ],
                    ),
                    
                    _buildStatusCard(context),
                    
                    const SizedBox(height: 24),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildActionButton(
                            context, 
                            'Testar Conexão', 
                            Icons.network_check, 
                            Colors.blue,
                            () => _showTestConnectionDialog(context),
                          ),
                          _buildActionButton(
                            context, 
                            _camera.isActive ? 'Desativar' : 'Ativar', 
                            _camera.isActive ? Icons.do_not_disturb : Icons.check_circle_outline, 
                            _camera.isActive ? Colors.red : Colors.green,
                            () => _showToggleActiveDialog(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final customYellow = Theme.of(context).colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: customYellow.withAlpha(26), // 0.1 * 255 ≈ 26
                shape: BoxShape.circle,
                border: Border.all(
                  color: _camera.isActive ? Colors.green : Colors.red,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 40,
                color: customYellow,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _camera.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ) ?? const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_camera.isActive ? Colors.green : Colors.red).withAlpha(26), // 0.1 * 255 ≈ 26
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _camera.isActive ? Icons.check_circle : Icons.cancel,
                          color: _camera.isActive ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _camera.isActive ? 'Câmera Ativa' : 'Câmera Inativa',
                          style: TextStyle(
                            color: _camera.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData titleIcon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  titleIcon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final Color iconColor = Colors.grey[600] ?? Colors.grey;
    final Color labelColor = Colors.grey[700] ?? Colors.grey;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoRow(BuildContext context) {
    final group = _groupService.getGroupById(_camera.groupId);
    final groupName = group?.name ?? 'Sem grupo';
    final groupColor = group != null ? Color(group.colorValue) : Colors.grey;
    final iconCode = group != null ? 
        _getIconCode(group.iconName) : 
        Icons.folder.codePoint;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.folder,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grupo:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: groupColor.withAlpha(26), // 0.1 * 255 ≈ 26
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: groupColor.withAlpha(128), // 0.5 * 255 ≈ 128
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconData(
                          iconCode,
                          fontFamily: 'MaterialIcons',
                        ),
                        size: 16,
                        color: groupColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        groupName,
                        style: TextStyle(
                          fontSize: 14,
                          color: groupColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getIconCode(String iconName) {
    final Map<String, int> iconMap = {
      'folder': Icons.folder.codePoint,
      'home': Icons.home.codePoint,
      'business': Icons.business.codePoint,
      'videocam': Icons.videocam.codePoint,
      'security': Icons.security.codePoint,
      'visibility': Icons.visibility.codePoint,
      'location_on': Icons.location_on.codePoint,
      'shield': Icons.shield.codePoint,
      'warning': Icons.warning.codePoint,
      'camera_alt': Icons.camera_alt.codePoint,
      'meeting_room': Icons.meeting_room.codePoint,
      'store': Icons.store.codePoint,
      'warehouse': Icons.warehouse.codePoint,
      'garage': Icons.garage.codePoint,
      'terrain': Icons.terrain.codePoint,
      'other_houses': Icons.other_houses.codePoint,
    };
    
    return iconMap[iconName] ?? Icons.folder.codePoint;
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.graphic_eq,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _camera.isActive ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26), // 0.1 * 255 ≈ 26
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _camera.isActive ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_camera.isActive ? Colors.green : Colors.red).withAlpha(51), // 0.2 * 255 ≈ 51
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _camera.isActive ? Icons.visibility : Icons.visibility_off,
                      color: _camera.isActive ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${_camera.isActive ? 'Ativa' : 'Inativa'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _camera.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _camera.isActive 
                              ? 'Esta câmera está operando normalmente.'
                              : 'Esta câmera está temporariamente desativada.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
    );
  }

  void _showTestConnectionDialog(BuildContext context) {
    Future<bool> testConnection() async {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FutureBuilder<bool>(
        future: testConnection(),
        builder: (context, snapshot) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.network_check, color: Colors.blue),
                SizedBox(width: 8),
                Text('Teste de Conexão'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Testando conexão com ${_camera.ipAddress}...',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else if (snapshot.hasData && snapshot.data == true)
                  Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Conexão estabelecida com sucesso!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A câmera ${_camera.name} está respondendo corretamente.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Falha na conexão!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Não foi possível estabelecer conexão com ${_camera.ipAddress}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? 'Cancelar'
                      : 'Fechar'
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showToggleActiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _camera.isActive ? Icons.do_not_disturb : Icons.check_circle_outline,
              color: _camera.isActive ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_camera.isActive ? 'Desativar Câmera' : 'Ativar Câmera'),
            ),
          ],
        ),
        content: Text(
          _camera.isActive
              ? 'Deseja desativar a câmera ${_camera.name}?'
              : 'Deseja ativar a câmera ${_camera.name}?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(
                  _camera.isActive ? Icons.cancel : Icons.check_circle,
                  size: 18,
                ),
                label: Text(_camera.isActive ? 'Desativar' : 'Ativar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _camera.isActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  try {
                    final updatedCamera = Camera(
                      id: _camera.id,
                      name: _camera.name,
                      brand: _camera.brand,
                      model: _camera.model,
                      ipAddress: _camera.ipAddress,
                      address: _camera.address,
                      isActive: !_camera.isActive,
                      groupId: _camera.groupId,
                    );
                    
                    _cameraService.updateCamera(updatedCamera);
                    
                    setState(() {
                      _camera = updatedCamera;
                    });
                    
                    final snackBar = SnackBar(
                      content: Text(
                        updatedCamera.isActive
                            ? 'Câmera ${updatedCamera.name} ativada com sucesso!'
                            : 'Câmera ${updatedCamera.name} desativada com sucesso!'
                      ),
                      backgroundColor: updatedCamera.isActive ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 2),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    
                    Navigator.of(ctx).pop();
                    
                  } catch (e) {
                    final errorSnackBar = SnackBar(
                      content: Text('Erro ao atualizar status da câmera: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 3),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}