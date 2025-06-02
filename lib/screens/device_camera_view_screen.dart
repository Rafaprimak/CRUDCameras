import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../algoritmo/direct_python_bridge.dart';
import '../models/camera.dart' as camera_model;
import '../services/email_service.dart';

class DeviceCameraViewScreen extends StatefulWidget {
  final camera_model.Camera cameraInfo;
  
  const DeviceCameraViewScreen({Key? key, required this.cameraInfo}) : super(key: key);
  
  @override
  _DeviceCameraViewScreenState createState() => _DeviceCameraViewScreenState();
}

class _DeviceCameraViewScreenState extends State<DeviceCameraViewScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isDetectionEnabled = false;
  bool _isDetectorReady = false;
  DirectPythonBridge? _weaponDetector;
  bool _weaponDetected = false;
  String _lastDetectionMessage = '';
  Timer? _detectionTimer;
  int _processingFrameCount = 0;
  bool _isInitializing = true;
  String _detectionServerUrl = 'http://192.168.3.8:5556';
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _lastWeaponDetectedState = false;
  late EmailService _emailService;
  bool _emailNotificationsEnabled = false;
  String _emailConfigured = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAll();
    _initializeNotifications();
    _initializeEmailService();
  }
  
  Future<void> _initializeAll() async {
    try {
      await _initializeDetector();
      await _initializeCamera();
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print("Error during initialization: $e");
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _showError('Erro ao inicializar: $e');
      }
    }
  }

  Future<void> _initializeDetector() async {
    _weaponDetector = DirectPythonBridge();
    
    try {
      final initialized = await _weaponDetector!.initialize();
      
      if (mounted) {
        setState(() {
          _isDetectorReady = initialized;
        });
      }
      
      if (!initialized) {
        _showError('Não foi possível inicializar o detector de armas. Funcionando em modo limitado.');
      } else {
        print('Weapon detector initialized successfully');
      }
    } catch (e) {
      print('Error initializing detector: $e');
      if (mounted) {
        _showError('Erro ao inicializar detector: $e');
      }
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        _showError('Nenhuma câmera encontrada no dispositivo');
        return;
      }
      
      final CameraDescription camera = _cameras.first;
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      print('Error initializing camera: $e');
      _showError('Erro ao inicializar câmera: $e');
    }
  }
  
  void _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          print('Notification tapped: ${details.payload}');
        },
      );
      
      // Verificação de plataforma envolvida em try-catch
      try {
        // Verifica se as classes de plataforma específica estão disponíveis antes
        final isPlatformAvailable = Platform.isAndroid || Platform.isIOS;
        
        if (isPlatformAvailable) {
          if (Platform.isIOS) {
            await _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                );
          } else if (Platform.isAndroid) {
            await _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestPermission();
          }
        }
      } catch (e) {
        // Silenciosamente ignora erros de plataforma (ex: na web)
        print('Ignorando erro de plataforma em notificações: $e');
      }
    } catch (e) {
      print('Erro ao inicializar sistema de notificações: $e');
    }
  }
  
  void _initializeEmailService() {
    try {
      _emailService = EmailService(
        smtpServer: 'smtp.gmail.com',
        smtpPort: 587,
        useSSL: false, // Para Gmail, o método factory 'gmail' será usado
        username: 'rafaprimak1@gmail.com',
        password: 'idht rkmg hypo fbfs', // IMPORTANTE: revogue esta senha e crie uma nova após corrigir o problema
        recipients: [], // Lista vazia inicialmente
      );
      
      _emailConfigured = 'rafaprimak1@gmail.com';
      _emailNotificationsEnabled = false;
      
      print('📧 Serviço de email inicializado');
    } catch (e) {
      print('❌ Erro ao inicializar serviço de email: $e');
    }
  }
  
  void _startDetection() {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        !_isDetectorReady) {
      return;
    }
    
    _detectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_processingFrameCount < 1) {
        _processingFrameCount++;
        _captureAndProcessFrame();
      }
    });
  }
  
  void _captureAndProcessFrame() async {
    if (_cameraController?.value.isInitialized != true) {
      _processingFrameCount--;
      return;
    }
    
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List bytes = await imageFile.readAsBytes();
      final String base64Image = base64.encode(bytes);
      
      try {
        final response = await http.post(
          Uri.parse('$_detectionServerUrl/detection/detect'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image': base64Image,
            'camera_id': widget.cameraInfo.id,
          }),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          
          if (mounted) {
            setState(() {
              _weaponDetected = result['weapons_detected'] == true;
              
              if (result['detections'] != null) {
                print('Detecções encontradas:');
                for (var detection in result['detections']) {
                  final isWeapon = detection['is_weapon'] ?? false;
                  print('  - ${detection['class']} (${detection['confidence']?.toStringAsFixed(2)}) [${isWeapon ? 'ARMA' : 'OUTROS'}]');
                }
              }
              
              if (_weaponDetected && !_lastWeaponDetectedState) {
                final message = result['message'] ?? 
                  'Arma detectada na câmera ${widget.cameraInfo.name}!';
                
                print('🚨 ENVIANDO ALERTA: $message');
                
                _showWeaponDetectionNotification(message);
                
                if (_emailNotificationsEnabled && _weaponDetected) {
                  final weaponDetections = (result['detections'] as List?)
                      ?.where((detection) => detection['is_weapon'] == true)
                      .toList() ?? [];
                  
                  if (weaponDetections.isNotEmpty) {
                    _sendDetectionEmail(
                      bytes,
                      message,
                      weaponDetections,
                    );
                  }
                }
              }
              
              _lastWeaponDetectedState = _weaponDetected;
              
              if (result['notification'] == true && result['message'] != null) {
                _lastDetectionMessage = result['message'];
                HapticFeedback.heavyImpact();
              } else if (_weaponDetected) {
                _lastDetectionMessage = 'Arma detectada!';
                HapticFeedback.heavyImpact();
              }
            });
          }
        } else {
          print('Server error: ${response.statusCode} - ${response.body}');
          if (mounted && _processingFrameCount <= 1) {
            _showConnectionError();
          }
        }
      } catch (e) {
        print('Network error: $e');
        if (mounted && _processingFrameCount <= 1) {
          _showConnectionError();
        }
      } finally {
        try {
          await File(imageFile.path).delete().catchError((_) => File(imageFile.path));
        } catch (_) {}
      }
    } catch (e) {
      print('Camera capture error: $e');
    } finally {
      _processingFrameCount--;
    }
  }

  Future<void> _sendDetectionEmail(
    Uint8List imageBytes,
    String detectionMessage,
    List weaponDetections
  ) async {
    try {
      // Verificar se o serviço de email está corretamente configurado
      if (_emailService.recipients.isEmpty) {
        print('❌ Nenhum destinatário configurado. Configure as notificações por email.');
        return;
      }
      
      final formattedDetections = weaponDetections.map<Map<String, dynamic>?>((detection) {
        if (detection is Map) {
          final className = detection['class']?.toString().toLowerCase() ?? '';
          final weaponClasses = ['gun', 'pistol', 'rifle', 'firearms', 'knife', 'weapon'];
          final isWeapon = weaponClasses.any((weaponClass) => className.contains(weaponClass));
          
          if (isWeapon) {
            return {
              'class': detection['class'] ?? 'Arma desconhecida',
              'confidence': detection['confidence'] ?? 0.0,
              'box': detection['box'] ?? [],
            };
          }
        } else if (detection is List && detection.length >= 3) {
          final className = detection[0]?.toString().toLowerCase() ?? '';
          final weaponClasses = ['gun', 'pistol', 'rifle', 'firearms', 'knife', 'weapon'];
          final isWeapon = weaponClasses.any((weaponClass) => className.contains(weaponClass));
          
          if (isWeapon) {
            return {
              'class': detection[0] ?? 'Arma desconhecida',
              'confidence': detection[1] ?? 0.0,
              'box': detection[2] ?? [],
            };
          }
        }
        // Changed from return null; to return a nullable map type
        return null; 
      }).where((detection) => detection != null).cast<Map<String, dynamic>>().toList();
      
      if (formattedDetections.isEmpty) {
        print('❌ Nenhuma detecção de arma válida após filtragem');
        return;
      }
      
      print('📧 Enviando email com ${formattedDetections.length} detecções de armas...');
      
      final success = await _emailService.sendWeaponDetectionAlert(
        cameraName: widget.cameraInfo.name,
        cameraId: widget.cameraInfo.id,
        detectionMessage: detectionMessage,
        detections: formattedDetections,
        imageBytes: imageBytes,
        imageFilename: 'weapon_detection_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      if (success) {
        print('✅ Email de alerta enviado com sucesso');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.email, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Email de alerta enviado com sucesso!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ Falha ao enviar email de alerta');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.email_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Falha ao enviar email de alerta'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao enviar email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao enviar email: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showEmailSettingsDialog() {
    final emailController = TextEditingController(text: _emailConfigured);
    final passwordController = TextEditingController();
    final recipientController = TextEditingController();
    
    final recipients = <String>[];
    
    try {
      if (_emailService.recipients.isNotEmpty) {
        recipients.addAll(_emailService.recipients);
      }
    } catch (e) {
      print('Erro ao obter recipients existentes: $e');
    }
    
    bool emailEnabled = _emailNotificationsEnabled;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 8),
                Text('Configurações de Email'),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text('Dicas importantes:', 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Para Gmail, use uma "Senha de App" em vez da senha normal\n'
                            '• Ative a verificação em 2 etapas no Gmail\n'
                            '• Emails serão enviados APENAS quando armas forem detectadas',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Remetente',
                        hintText: 'seu.email@gmail.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Senha de App (Gmail)',
                        hintText: 'xxxx xxxx xxxx xxxx',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        helperText: 'Use Senha de App, não a senha normal',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    const Text('Destinatários dos Alertas:', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: recipientController,
                            decoration: const InputDecoration(
                              labelText: 'Email do Destinatário',
                              hintText: 'destinatario@email.com',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_add),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onSubmitted: (value) {
                              if (value.isNotEmpty && value.contains('@')) {
                                setDialogState(() {
                                  recipients.add(value);
                                  recipientController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        // CORREÇÃO: Adicionamos try-catch para mais segurança
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () {
                            try {
                              if (recipientController.text.isNotEmpty && 
                                  recipientController.text.contains('@')) {
                                setDialogState(() {
                                  recipients.add(recipientController.text);
                                  recipientController.clear();
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Digite um email válido'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Erro ao adicionar destinatário: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao adicionar destinatário: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (recipients.isNotEmpty) ...[
                      const Text('Lista de Destinatários:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        // FIX 2: Definir altura fixa e não usar ListView.builder
                        // que causa problemas de layout em AlertDialog
                        height: 120,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        // Substituir ListView.builder por Column + SingleChildScrollView
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (int index = 0; index < recipients.length; index++)
                                Card(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.email, size: 16, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(recipients[index], 
                                            style: const TextStyle(fontSize: 14)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, 
                                            size: 18, color: Colors.red),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setDialogState(() {
                                              recipients.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: emailEnabled ? Colors.green.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: emailEnabled ? Colors.green.shade200 : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            emailEnabled ? Icons.notifications_active : Icons.notifications_off,
                            color: emailEnabled ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ativar notificações por email',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: emailEnabled ? Colors.green.shade800 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Switch(
                            value: emailEnabled,
                            onChanged: (value) {
                              setDialogState(() {
                                emailEnabled = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    // Adicionar botão de teste após os campos de email e senha
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Testar Configuração de Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        if (emailController.text.isEmpty || 
                            !emailController.text.contains('@') ||
                            passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Preencha email e senha para testar'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        
                        // Mostrar indicador de progresso
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Testando conexão com servidor de email...'),
                              ],
                            ),
                          ),
                        );
                        
                        // Criar uma instância temporária do EmailService para teste
                        final testService = EmailService(
                          smtpServer: 'smtp.gmail.com',
                          smtpPort: 587,
                          useSSL: false,
                          username: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          recipients: ['test@example.com'], // Apenas para teste
                        );
                        
                        // Testar conexão
                        final success = await testService.testConnection();
                        
                        // Fechar diálogo de progresso
                        Navigator.of(context).pop();
                        
                        // Mostrar resultado
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  success ? Icons.check_circle : Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    success
                                        ? 'Conexão com servidor de email bem-sucedida!'
                                        : 'Falha ao conectar ao servidor de email. Verifique os logs.',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Configuração'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  try {
                    if (emailEnabled) {
                      if (emailController.text.isEmpty || 
                          !emailController.text.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Digite um email válido'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Digite a senha de app'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (recipients.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Adicione pelo menos um destinatário'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }
                    
                    if (emailEnabled) {
                      _emailService = EmailService(
                        smtpServer: 'smtp.gmail.com',
                        smtpPort: 587,
                        useSSL: false,
                        username: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        recipients: List<String>.from(recipients), // Criamos uma cópia segura
                      );
                      
                      setState(() {
                        _emailConfigured = emailController.text.trim();
                        _emailNotificationsEnabled = emailEnabled;
                      });
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(emailEnabled 
                                ? 'Notificações por email ativadas! (${recipients.length} destinatários)' 
                                : 'Notificações por email desativadas'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      // Desabilitar notificações
                      setState(() {
                        _emailNotificationsEnabled = false;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.notifications_off, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Notificações por email desativadas'),
                            ],
                          ),
                          backgroundColor: Colors.grey,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Erro ao salvar configurações: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar configurações: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        }
      ),
    );
  }
  
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showServerSettingsDialog() {
    final serverController = TextEditingController(text: _detectionServerUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Configurações do Servidor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digite o endereço IP do seu computador onde o servidor está rodando:',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                labelText: 'URL do Servidor',
                hintText: 'http://192.168.x.x:5556',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.network_check),
              label: const Text('Testar Conexão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                try {
                  final response = await http.get(
                    Uri.parse('${serverController.text}/health'),
                  ).timeout(const Duration(seconds: 3));
                  
                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conexão com servidor estabelecida com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Servidor encontrado, mas retornou erro: ${response.statusCode}'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao conectar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
            onPressed: () {
              setState(() {
                _detectionServerUrl = serverController.text;
              });
              Navigator.pop(context);
              _testServerConnection();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _testServerConnection() async {
    try {
      print('Testing connection to: $_detectionServerUrl/health');
      final response = await http.get(
        Uri.parse('$_detectionServerUrl/health'),
      ).timeout(const Duration(seconds: 3));
      
      print('Server response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final detectorStarted = await _startDetector();
        
        setState(() {
          _isDetectorReady = detectorStarted;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(detectorStarted 
              ? 'Conexão com servidor estabelecida e detector iniciado!' 
              : 'Conexão com servidor estabelecida, mas detector não pôde ser iniciado.'),
            backgroundColor: detectorStarted ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error testing server connection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível conectar ao servidor: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _startDetector() async {
    try {
      final response = await http.post(
        Uri.parse('$_detectionServerUrl/detection/start'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error starting detector: $e');
      return false;
    }
  }

  Future<void> _showWeaponDetectionNotification(String message) async {
    try {
      // Não pode ser const porque contém o parâmetro message que é dinâmico
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'weapon_detection_channel',
        'Weapon Detection Alerts',
        channelDescription: 'Notificações de detecção de armas',
        importance: Importance.max,
        priority: Priority.high,
        color: Colors.red,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
        styleInformation: BigTextStyleInformation(
          message, // Valor dinâmico, não permite const
          htmlFormatBigText: false,
          contentTitle: '🚨 ALERTA DE SEGURANÇA',
          htmlFormatContentTitle: false,
          summaryText: 'Sistema de Detecção de Armas',
          htmlFormatSummaryText: false,
        ),
      );

      // Esta parte pode continuar const
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'weapon_alert',
      );

      // Precisa ser final porque combina const com não-const
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Usa um ID único baseado no timestamp
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _notificationsPlugin.show(
        notificationId,
        '🚨 ALERTA DE SEGURANÇA',
        message,
        platformChannelSpecifics,
        payload: 'weapon_detected_${widget.cameraInfo.id}',
      );

      print('✅ Notificação local enviada: $message');
    } catch (e) {
      print('❌ Erro ao mostrar notificação: $e');
    }
  }

  void _showConnectionError() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Erro de conexão com o servidor de detecção'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Configurar',
          textColor: Colors.white,
          onPressed: _showServerSettingsDialog,
        ),
      ),
    );
  }

  void _toggleDetection() {
    if (!_isDetectorReady) {
      _showError('Detector não está pronto. Verifique a conexão com o servidor.');
      return;
    }

    if (_isDetectionEnabled) {
      _stopDetection();
    } else {
      _startDetection();
    }

    setState(() {
      _isDetectionEnabled = !_isDetectionEnabled;
    });

    final message = _isDetectionEnabled 
        ? 'Detecção de armas ativada' 
        : 'Detecção de armas desativada';
        
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isDetectionEnabled ? Icons.security : Icons.security_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: _isDetectionEnabled ? Colors.green : Colors.grey[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    HapticFeedback.mediumImpact();
  }

  void _stopDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _processingFrameCount = 0;
    
    if (mounted) {
      setState(() {
        _weaponDetected = false;
        _lastDetectionMessage = '';
        _lastWeaponDetectedState = false;
      });
    }
    
    print('🛑 Detecção parada');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      if (_isDetectionEnabled) {
        _stopDetection();
      }
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera().then((_) {
        if (_isDetectionEnabled && _isDetectorReady) {
          _startDetection();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopDetection();
    _cameraController?.dispose();
    _weaponDetector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Câmera: ${widget.cameraInfo.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'Configurações de Email',
            onPressed: _showEmailSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações do Servidor',
            onPressed: _showServerSettingsDialog,
          ),
          if (_isDetectorReady)
            IconButton(
              icon: Icon(_isDetectionEnabled ? Icons.security : Icons.security_outlined),
              tooltip: _isDetectionEnabled ? 'Desativar detecção' : 'Ativar detecção',
              onPressed: _toggleDetection,
            ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Alternar câmera',
            onPressed: _cameras.length > 1 ? _switchCamera : null,
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Inicializando a câmera e o detector...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera Preview
                      if (_isInitialized && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      
                      // Weapon detection alert
                      if (_weaponDetected)
                        Container(
                          color: Colors.red.withOpacity(0.3),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning,
                                  size: 80,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '🚨 ARMA DETECTADA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_lastDetectionMessage.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _lastDetectionMessage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Controls
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isDetectionEnabled ? Icons.security : Icons.security_outlined,
                          color: _isDetectionEnabled ? Colors.green : Colors.white,
                          size: 32,
                        ),
                        onPressed: _isDetectorReady ? _toggleDetection : null,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _capturePhoto,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _showServerSettingsDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      final wasDetectionEnabled = _isDetectionEnabled;
      if (wasDetectionEnabled) {
        _stopDetection();
      }
      
      await _cameraController!.takePicture();
      
      if (wasDetectionEnabled && mounted) {
        setState(() {
          _isDetectionEnabled = true;
        });
        _startDetection();
      }
      
      if (!mounted) return;
      
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto capturada com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
    } catch (e) {
      _showError('Erro ao capturar foto: $e');
    }
  }
  
  void _switchCamera() async {
    if (_cameras.length <= 1) return;
    
    final currentCameraIndex = _cameras.indexOf(_cameraController!.description);
    final nextCameraIndex = (currentCameraIndex + 1) % _cameras.length;
    
    final wasDetectionEnabled = _isDetectionEnabled;
    if (wasDetectionEnabled) {
      _stopDetection();
    }
    
    await _cameraController?.dispose();
    _cameraController = null;
    
    if (!mounted) return;
    
    setState(() {
      _isInitialized = false;
    });
    
    _cameraController = CameraController(
      _cameras[nextCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          if (wasDetectionEnabled) {
            _isDetectionEnabled = true;
          }
        });
        
        if (wasDetectionEnabled && _isDetectorReady) {
          _startDetection();
        }
      }
    } catch (e) {
      _showError('Erro ao trocar câmera: $e');
    }
  }
}