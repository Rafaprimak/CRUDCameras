import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/camera_group.dart';
import '../services/camera_group_service.dart';
import '../services/auth_service.dart'; // Add this import

class GroupFormScreen extends StatefulWidget {
  final CameraGroup? group;

  const GroupFormScreen({super.key, this.group});

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CameraGroupService _groupService = CameraGroupService();
  final AuthService _authService = AuthService(); // Add this line
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedIcon = 'folder';
  int _selectedColor = 0xFF9E9E9E;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description;
      _selectedIcon = widget.group!.iconName;
      _selectedColor = widget.group!.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
          _isEditing ? 'Editar Grupo' : 'Criar Grupo',
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
                                  _isEditing ? 'Editando grupo' : 'Novo grupo',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isEditing
                                      ? 'Atualize as informações do grupo'
                                      : 'Organize suas câmeras de forma personalizada',
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
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome do Grupo',
                            prefixIcon: const Icon(Icons.group),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um nome para o grupo';
                            }
                            return null;
                          },
                          style: const TextStyle(fontSize: 16),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Descrição (opcional)',
                            prefixIcon: const Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 2,
                          style: const TextStyle(fontSize: 16),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ],
                    ),
                    
                    _buildSectionCard(
                      title: 'Aparência',
                      titleIcon: Icons.palette,
                      children: [
                        _buildIconSelector(),
                        const SizedBox(height: 16),
                        _buildColorSelector(),
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
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _saveGroup();
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

  Widget _buildIconSelector() {
    final Map<String, IconData> icons = {
      'folder': Icons.folder,
      'home': Icons.home,
      'business': Icons.business,
      'videocam': Icons.videocam,
      'security': Icons.security,
      'visibility': Icons.visibility,
      'location_on': Icons.location_on,
      'shield': Icons.shield,
      'warning': Icons.warning,
      'camera_alt': Icons.camera_alt,
      'meeting_room': Icons.meeting_room,
      'store': Icons.store,
      'warehouse': Icons.warehouse,
      'garage': Icons.garage,
      'terrain': Icons.terrain,
      'other_houses': Icons.other_houses,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ícone do Grupo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final iconName = icons.keys.elementAt(index);
              final iconData = icons.values.elementAt(index);
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = iconName;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedIcon == iconName 
                        ? Color(_selectedColor).withAlpha(51)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedIcon == iconName
                          ? Color(_selectedColor)
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: _selectedIcon == iconName
                        ? Color(_selectedColor)
                        : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    final List<int> colors = [
      0xFF9E9E9E, 
      0xFFffc112, 
      0xFF4CAF50, 
      0xFF2196F3, 
      0xFF9C27B0, 
      0xFFE91E63, 
      0xFFF44336, 
      0xFFFF9800, 
      0xFF795548, 
      0xFF607D8B, 
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor do Grupo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.black
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveGroup() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_isEditing) {
          final updatedGroup = CameraGroup(
            id: widget.group!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            iconName: _selectedIcon,
            colorValue: _selectedColor,
            userId: widget.group!.userId,
          );
          
          await _groupService.updateGroup(updatedGroup);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Grupo ${updatedGroup.name} atualizado com sucesso'),
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
          final newGroup = CameraGroup(
            id: '',
            name: _nameController.text,
            description: _descriptionController.text,
            iconName: _selectedIcon,
            colorValue: _selectedColor,
            userId: _authService.userId, // Use AuthService for user ID
          );
          
          await _groupService.addGroup(newGroup);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Grupo ${newGroup.name} criado com sucesso'),
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
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar grupo: ${error.toString()}'),
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