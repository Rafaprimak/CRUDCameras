import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/camera.dart';
import '../services/camera_service.dart';
import '../services/camera_group_service.dart';

class CameraFormScreen extends StatefulWidget {
  final Camera? camera;

  const CameraFormScreen({super.key, this.camera});

  @override
  State<CameraFormScreen> createState() => _CameraFormScreenState();
}

class _CameraFormScreenState extends State<CameraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CameraService _cameraService = CameraService();
  final CameraGroupService _groupService = CameraGroupService();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _ipAddressController = TextEditingController();
  bool _isActive = true;
  String _selectedGroupId = '';

  bool get _isEditing => widget.camera != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.camera!.name;
      _brandController.text = widget.camera!.brand;
      _modelController.text = widget.camera!.model;
      _ipAddressController.text = widget.camera!.ipAddress;
      _addressController.text = widget.camera!.address;
      _isActive = widget.camera!.isActive;
      _selectedGroupId = widget.camera!.groupId;
    } else {
      _selectedGroupId = _groupService.defaultGroupId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _ipAddressController.dispose();
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
        title: Text(
          _isEditing ? 'Editar Câmera' : 'Adicionar Câmera',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: customYellow.withAlpha(26),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: customYellow,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _isEditing ? Icons.edit_note : Icons.add_circle_outline,
                              color: customYellow,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditing ? 'Editando câmera' : 'Nova câmera',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isEditing
                                      ? 'Atualize as informações da câmera'
                                      : 'Preencha os dados para cadastrar uma nova câmera',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSectionCard(
                      title: 'Informações Básicas',
                      titleIcon: Icons.info_outline,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          labelText: 'Nome da Câmera',
                          icon: Icons.camera_alt,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _brandController,
                                labelText: 'Marca',
                                icon: Icons.business,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira uma marca';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _modelController,
                                labelText: 'Modelo',
                                icon: Icons.devices,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira um modelo';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    _buildSectionCard(
                      title: 'Configurações de Rede',
                      titleIcon: Icons.router,
                      children: [
                        _buildTextField(
                          controller: _ipAddressController,
                          labelText: 'Endereço IP',
                          icon: Icons.wifi,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um endereço IP';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    _buildSectionCard(
                      title: 'Localização',
                      titleIcon: Icons.location_on,
                      children: [
                        _buildTextField(
                          controller: _addressController,
                          labelText: 'Endereço',
                          icon: Icons.home,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um endereço';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    _buildSectionCard(
                      title: 'Grupo',
                      titleIcon: Icons.folder,
                      children: [
                        _buildGroupSelector(),
                      ],
                    ),
                    
                    _buildSectionCard(
                      title: 'Status',
                      titleIcon: Icons.settings,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: (_isActive ? Colors.green : Colors.red).withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isActive ? Colors.green : Colors.red,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isActive = !_isActive;
                                });
                                HapticFeedback.selectionClick();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (_isActive ? Colors.green : Colors.red).withAlpha(60),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isActive ? Icons.visibility : Icons.visibility_off,
                                        color: _isActive ? Colors.green : Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Câmera Ativa',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _isActive ? 'A câmera está ativa' : 'A câmera está inativa',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isActive,
                                      activeColor: Colors.green,
                                      activeTrackColor: Colors.green.withAlpha(128),
                                      inactiveThumbColor: Colors.red,
                                      inactiveTrackColor: Colors.red.withAlpha(128),
                                      onChanged: (value) {
                                        setState(() {
                                          _isActive = value;
                                        });
                                        HapticFeedback.selectionClick();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customYellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(150, 48), // Fixed size for better rendering
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            // Trigger a rebuild before saving (helps with rendering)
                            setState(() {});
                            // Wait a tiny moment for the UI to update
                            Future.microtask(() => _saveCamera());
                          },
                        ),
                      ],
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

  Widget _buildSectionCard({
    required String title,
    required IconData titleIcon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16, height: 1.1),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }

  Widget _buildGroupSelector() {
    final groups = _groupService.groups;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grupo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Material(
            color: Colors.transparent,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGroupId,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: BorderRadius.circular(8),
                itemHeight: 56,
                items: groups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 32,
                          height: 32,
                          child: Icon(
                            IconData(
                              _getIconCode(group.iconName),
                              fontFamily: 'MaterialIcons',
                            ),
                            color: Color(group.colorValue),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          group.name, 
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGroupId = value;
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
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

  Future<void> _saveCamera() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
        
        if (_isEditing) {
          final updatedCamera = Camera(
            id: widget.camera!.id,
            name: _nameController.text,
            brand: _brandController.text,
            model: _modelController.text,
            ipAddress: _ipAddressController.text,
            address: _addressController.text,
            isActive: _isActive,
            groupId: _selectedGroupId,
          );
          
          // Wait for the update to complete
          await _cameraService.updateCamera(updatedCamera);
          
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Câmera ${updatedCamera.name} atualizada com sucesso'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final cameraName = _nameController.text;
          final newCamera = Camera(
            id: '', 
            name: cameraName,
            brand: _brandController.text,
            model: _modelController.text,
            ipAddress: _ipAddressController.text,
            address: _addressController.text,
            isActive: _isActive,
            groupId: _selectedGroupId,
          );

          // Wait for the camera to be added
          await _cameraService.addCamera(newCamera);
          
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Câmera $cameraName cadastrada com sucesso'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Ensure we have the latest data
        await _cameraService.getCameras();
        
        // Wait a short moment for the UI to update
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Return to the list screen with result true to trigger refresh
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (error) {
        // Close loading dialog if it's showing
        if (mounted) Navigator.of(context).pop();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar câmera: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}