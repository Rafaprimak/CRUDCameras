import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../services/camera_service.dart';

class CameraFormScreen extends StatefulWidget {
  final Camera? camera;

  const CameraFormScreen({super.key, this.camera});

  @override
  State<CameraFormScreen> createState() => _CameraFormScreenState();
}

class _CameraFormScreenState extends State<CameraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CameraService _cameraService = CameraService();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _ipAddressController = TextEditingController();
  bool _isActive = true;

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, 
        title: Text(_isEditing ? 'Editar Câmera' : 'Adicionar Câmera'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Endereço'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o endereço';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a marca';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o modelo';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ipAddressController,
                decoration: const InputDecoration(labelText: 'Endereço IP'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o endereço IP';
                  }
                  final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                  if (!ipRegex.hasMatch(value)) {
                    return 'Por favor, informe um endereço IP válido';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Ativa'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFffc112), 
                  foregroundColor: Colors.black, 
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(_isEditing ? 'Atualizar' : 'Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCamera() {
    if (_formKey.currentState!.validate()) {
      if (_isEditing) {
        final updatedCamera = Camera(
          id: widget.camera!.id,
          name: _nameController.text,
          brand: _brandController.text,
          model: _modelController.text,
          ipAddress: _ipAddressController.text,
          address: _addressController.text,
          isActive: _isActive,
        );
        _cameraService.updateCamera(updatedCamera);
      } else {
        _cameraService.addCamera(
          _nameController.text,
          _brandController.text,
          _modelController.text,
          _ipAddressController.text,
          _addressController.text,
        );
      }
      Navigator.pop(context, true);
    }
  }
}