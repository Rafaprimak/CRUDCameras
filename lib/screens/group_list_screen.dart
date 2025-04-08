import 'package:flutter/material.dart';
import '../models/camera_group.dart';
import '../services/camera_group_service.dart';
import '../services/camera_service.dart';
import 'group_form_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final CameraGroupService _groupService = CameraGroupService();
  final CameraService _cameraService = CameraService();

  @override
  Widget build(BuildContext context) {
    final customYellow = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: customYellow,
        elevation: 2,
        title: const Text(
          'Grupos de Câmeras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          child: _buildGroupList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToGroupForm(context),
        label: const Text('Novo Grupo'),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: customYellow,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
    );
  }

  Widget _buildGroupList() {
    if (_groupService.groups.isEmpty) {
      return const Center(
        child: Text('Nenhum grupo encontrado'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 72),
      itemCount: _groupService.groups.length,
      itemBuilder: (context, index) {
        final group = _groupService.groups[index];
        final cameraCount = _cameraService.getCamerasByGroup(group.id).length;
        
        return _buildGroupCard(group, cameraCount);
      },
    );
  }

  Widget _buildGroupCard(CameraGroup group, int cameraCount) {
    final isDefault = group.id == _groupService.defaultGroupId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context, group.id);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(group.colorValue).withAlpha(128),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(group.colorValue).withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconData(
                            _getIconCode(group.iconName),
                            fontFamily: 'MaterialIcons',
                          ),
                          color: Color(group.colorValue),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                group.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '$cameraCount câmeras',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (!isDefault)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _navigateToGroupForm(context, group: group),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Editar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showDeleteDialog(group),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Excluir',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToGroupForm(BuildContext context, {CameraGroup? group}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupFormScreen(group: group),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showDeleteDialog(CameraGroup group) {
    final camerasInGroup = _cameraService.getCamerasByGroup(group.id).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir grupo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja realmente excluir o grupo ${group.name}?'),
            if (camerasInGroup > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Este grupo contém $camerasInGroup câmeras que serão movidas para o grupo padrão.',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Excluir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final defaultGroupId = _groupService.defaultGroupId;
              final camerasToMove = _cameraService.getCamerasByGroup(group.id);
              
              for (final camera in camerasToMove) {
                _cameraService.updateCameraGroup(camera.id, defaultGroupId);
              }
              
              _groupService.deleteGroup(group.id);
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Grupo ${group.name} excluído com sucesso'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              
              setState(() {});
            },
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
}