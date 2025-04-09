import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/camera.dart';
import '../services/camera_service.dart';
import '../services/camera_group_service.dart';
import '../utils/custom_route.dart';
import 'camera_details_screen.dart';
import 'camera_form_screen.dart';
import 'group_list_screen.dart';
import 'welcome_screen.dart';

class CameraListScreen extends StatefulWidget {
  const CameraListScreen({super.key});

  @override
  State<CameraListScreen> createState() => _CameraListScreenState();
}

class _CameraListScreenState extends State<CameraListScreen> with SingleTickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final CameraGroupService _groupService = CameraGroupService();
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGroupId = '';
  bool _showSearchBar = false;
  List<Camera> _cachedCameras = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
        _searchController.addListener(() {
      if (_showSearchBar && _searchController.text.isNotEmpty) {
        setState(() {});
      }
    });
        _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _cameraService.getCameras();
      await _groupService.getGroups();
      _cachedCameras = List.from(_cameraService.cameras);
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Camera> get _filteredCameras {
    if (_cachedCameras.isEmpty || _cachedCameras.length != _cameraService.cameras.length) {
      _cachedCameras = List.from(_cameraService.cameras);
    }
    
    List<Camera> cameras;
    if (_selectedGroupId.isEmpty || _groupService.isDefaultGroup(_selectedGroupId)) {
      cameras = _cachedCameras;
    } else {
      cameras = _cachedCameras.where((c) => c.groupId == _selectedGroupId).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      return cameras.where((camera) {
        return camera.name.toLowerCase().contains(query) ||
            camera.address.toLowerCase().contains(query) ||
            camera.ipAddress.toLowerCase().contains(query) ||
            camera.brand.toLowerCase().contains(query) ||
            camera.model.toLowerCase().contains(query);
      }).toList();
    }
    
    return cameras;
  }

  String _getSelectedGroupName() {
    if (_selectedGroupId.isEmpty) {
      return 'Todas as Câmeras';
    }
    
    final group = _groupService.getGroupById(_selectedGroupId);
    return group?.name ?? 'Todas as Câmeras';
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final customYellow = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      body: RepaintBoundary(
        child: Stack(
          children: [
            Container(
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
            ),
            
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: statusBarHeight + 60,
              child: Container(
                padding: EdgeInsets.only(top: statusBarHeight),
                decoration: BoxDecoration(
                  color: customYellow,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), 
                  child: Row(
                    mainAxisSize: MainAxisSize.max, 
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/armadillo_logo.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      if (!_showSearchBar)
                        Expanded(
                          child: Center(
                            child: Text(
                              'Câmeras Cadastradas',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      
                      if (_showSearchBar)
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(
                              begin: 1.0, 
                              end: 0.0,   
                            ),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(value * 100, 0), 
                                child: Opacity(
                                  opacity: 1.0 - value,  
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Pesquisar...',
                                      hintStyle: TextStyle(color: Colors.grey.shade600),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade700, size: 20),
                                      prefixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
                                      suffixIcon: IconButton(
                                        iconSize: 18,
                                        icon: Icon(Icons.clear, color: Colors.grey.shade700),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(maxWidth: 36),
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 15, height: 1.1),
                                    cursorColor: const Color(0xFFffc112),
                                    textAlignVertical: TextAlignVertical.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      IconButton(
                        icon: _showSearchBar 
                            ? const Icon(Icons.search_off)
                            : const Icon(Icons.search),
                        splashRadius: 24,
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
                          HapticFeedback.lightImpact(); 
                          
                          if (!_showSearchBar) {
                            setState(() {
                              _showSearchBar = true;
                            });
                            
                            Future.delayed(const Duration(milliseconds: 350), () {
                              if (mounted) {
                                FocusScope.of(context).requestFocus(FocusNode());
                              }
                            });
                          } else {
                            _searchController.clear();
                            setState(() {
                              _showSearchBar = false;
                              _searchQuery = '';
                            });
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                      
                      if (!_showSearchBar)
                        IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Sair',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: _showLogoutDialog,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              top: statusBarHeight + 60,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: _navigateToGroupSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder,
                          size: 18,
                          color: customYellow,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getSelectedGroupName(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            Positioned(
              top: statusBarHeight + 110,
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                children: [
                  _buildStatusBar(),
                  Expanded(
                    child: _buildCameraList(),
                  ),
                ],
              ),
            ),
            

            Positioned(
              bottom: 16, 
              left: 20,
              child: SizedBox(
                height: 56, 
                width: 120,
                child: ElevatedButton(
                  onPressed: _showSOSDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff1b1c),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFFff1b1c).withAlpha(128),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'S.O.S',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCameraForm(context),
        label: const Text('Nova Câmera'),
        icon: const Icon(Icons.add_circle_outline),
        elevation: 4,
      ),
    );
  }

  Widget _buildStatusBar() {
    final activeCount = _cameraService.cameras.where((camera) => camera.isActive).length;
    final inactiveCount = _cameraService.cameras.length - activeCount;
    final totalCount = _cameraService.cameras.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),  
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center( 
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildCountBadge(
              label: 'Total',
              count: totalCount,
              color: Colors.grey[700]!,
              backgroundColor: Colors.grey[200]!,
            ),
            _buildCountBadge(
              label: 'Ativas',
              count: activeCount,
              color: Colors.white,
              backgroundColor: Colors.green,
            ),
            _buildCountBadge(
              label: 'Inativas',
              count: inactiveCount,
              color: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

 
  Widget _buildCountBadge({
    required String label,
    required int count,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12, 
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13, 
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraList() {
    return RepaintBoundary(
      key: ValueKey('camera_list_container'),
      child: RefreshIndicator(
        color: const Color(0xFFffc112),
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 40,
        onRefresh: () async {
          await _cameraService.getCameras();
          await _groupService.getGroups();
          _cachedCameras = List.from(_cameraService.cameras);
          if (mounted) setState(() {});
          return Future.value();
        },
        child: StreamBuilder<List<Camera>>(
          stream: _cameraService.streamCameras(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cachedCameras.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            

            if (snapshot.hasError) {
              print('Error loading cameras: ${snapshot.error}');
              if (_cachedCameras.isNotEmpty) {
              } else {
                return Center(
                  child: Text('Erro ao carregar câmeras: ${snapshot.error}'),
                );
              }
            }
            
            final cameras = _filteredCameras;
            
            if (_cameraService.cameras.isEmpty && _cachedCameras.isEmpty) {
              return _buildEmptyListWithRefresh();
            }
            
            if (_searchQuery.isNotEmpty && cameras.isEmpty) {
              return _buildEmptyListWithRefresh(isSearchResult: true);
            }
            
            return ListView.builder(
              key: ValueKey(_cacheKey),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                final camera = cameras[index];
                return RepaintBoundary(
                  key: ValueKey('camera_${camera.id}'),
                  child: _buildCameraCard(camera),
                );
              },
              cacheExtent: 500,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyListWithRefresh({bool isSearchResult = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSearchResult ? Icons.search_off : Icons.videocam_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isSearchResult ? 'Nenhuma câmera encontrada' : 'Nenhuma câmera cadastrada',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSearchResult
                      ? 'Não foram encontrados resultados para "$_searchQuery"'
                      : 'Adicione sua primeira câmera clicando no botão abaixo',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Puxe para baixo para atualizar',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraCard(Camera camera) {
    final group = _groupService.getGroupById(camera.groupId);
    final groupName = group?.name ?? 'Sem grupo';
    final groupColor = group != null ? Color(group.colorValue) : Colors.grey;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToCameraDetails(context, camera),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: camera.isActive ? Colors.green.withAlpha(128) : Colors.red.withAlpha(128),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: camera.isActive ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        camera.isActive ? Icons.check_circle_outline : Icons.error_outline,
                        color: camera.isActive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        camera.isActive ? 'Ativa' : 'Inativa',
                        style: TextStyle(
                          color: camera.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.videocam,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              camera.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    camera.address,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.router, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'IP: ${camera.ipAddress}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.business, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${camera.brand} ${camera.model}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: groupColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: groupColor.withAlpha(128),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder,
                                    size: 12,
                                    color: groupColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    groupName,
                                    style: TextStyle(
                                      fontSize: 11,
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
                ),
                
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
                          onTap: () => _navigateToCameraDetails(context, camera),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Detalhes',
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
                          onTap: () => _navigateToCameraForm(context, camera: camera),
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
                          onTap: () => _showDeleteDialog(camera),
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

  void _navigateToCameraForm(BuildContext context, {Camera? camera}) async {
    final result = await Navigator.push(
      context,
      CustomPageRoute(
        child: CameraFormScreen(camera: camera),
      ),
    );

    if (result == true) {
      await _cameraService.getCameras();
      await _groupService.getGroups();
      _cachedCameras = List.from(_cameraService.cameras);
      setState(() {});
    }
  }

  void _showDeleteDialog(Camera camera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Excluir câmera'),
          ],
        ),
        content: Text('Deseja realmente excluir a câmera ${camera.name}?'),
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
              _cameraService.deleteCamera(camera.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Câmera ${camera.name} excluída com sucesso'),
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

  void _navigateToCameraDetails(BuildContext context, Camera camera) async {
    final result = await Navigator.push(
      context,
      CustomPageRoute(
        child: CameraDetailsScreen(camera: camera),
      ),
    );

    if (result == true) {
      await _cameraService.getCameras();
      await _groupService.getGroups();
      _cachedCameras = List.from(_cameraService.cameras);
      setState(() {});
    }
  }
  
  void _navigateToGroupSelector() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupListScreen()),
    );
    
    if (result != null) {
      setState(() {
        _selectedGroupId = result.toString();
        _cachedCameras = List.from(_cameraService.cameras);
      });
    }
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.grey),
            SizedBox(width: 8),
            Text('Sair do aplicativo'),
          ],
        ),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sair'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showSOSDialog() {
    HapticFeedback.heavyImpact();
    
    final dialogContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text('Enviando pedido de socorro...'),
        SizedBox(height: 16),
        LinearProgressIndicator(
          backgroundColor: Color(0xFFffcccb),
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFff1b1c)),
        ),
      ],
    );
    
    showDialog(
      context: context,
      builder: (context) => RepaintBoundary(
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFff1b1c)),
              SizedBox(width: 8),
              Text('S.O.S', style: TextStyle(color: Color(0xFFff1b1c))),
            ],
          ),
          content: dialogContent,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFff1b1c),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pedido de socorro enviado com sucesso'),
                    backgroundColor: Color(0xFFff1b1c),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  String get _cacheKey => '${_searchQuery}_${_selectedGroupId}_${_cameraService.cameras.length}';

}