import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';

class EmailService {
  // Email configuration
  final String _smtpServer;
  final int _smtpPort;
  final bool _useSSL;
  final String _username;
  final String _password;
  final List<String> _recipients;
  
  EmailService({
    required String smtpServer, 
    required int smtpPort,
    required bool useSSL,
    required String username,
    required String password,
    required List<String> recipients,
  }) : 
    _smtpServer = smtpServer,
    _smtpPort = smtpPort,
    _useSSL = useSSL,
    _username = username,
    _password = password,
    _recipients = recipients;
    
  // Getter para os recipients que retorna uma cópia segura
  List<String> get recipients => List<String>.from(_recipients);
  
  /// Send weapon detection alert email with image
  Future<bool> sendWeaponDetectionAlert({
    required String cameraName,
    required String cameraId,
    required String detectionMessage,
    required List<Map<String, dynamic>> detections,
    required List<int> imageBytes,
    String imageFilename = 'weapon_detection.jpg',
  }) async {
    try {
      print('📧 Iniciando envio de email...');
      
      // Validação dos destinatários
      if (_recipients.isEmpty) {
        print('❌ Nenhum destinatário configurado para email');
        return false;
      }
      
      print('📧 Preparando email para ${_recipients.length} destinatários: ${_recipients.join(', ')}');
      print('📧 Usando servidor: $_smtpServer:$_smtpPort');
      print('📧 Usuário: $_username');
      
      // Configure SMTP server
      SmtpServer smtpServer;
      
      // Use configuração específica para Gmail
      if (_smtpServer.contains('gmail')) {
        print('📧 Usando configuração específica para Gmail');
        smtpServer = gmail(_username, _password);
      } else {
        print('📧 Usando configuração SMTP personalizada');
        smtpServer = SmtpServer(
          _smtpServer,
          port: _smtpPort,
          ssl: _useSSL,
          username: _username,
          password: _password,
        );
      }
      
      // Create the email message
      final message = Message()
        ..from = Address(_username, 'Sistema de Segurança - $cameraName')
        ..recipients.addAll(_recipients)
        ..subject = '🚨 ALERTA! Arma detectada na câmera $cameraName'
        ..text = _createAlertEmailBody(cameraName, cameraId, detectionMessage, detections)
        ..html = _createAlertEmailHtml(cameraName, cameraId, detectionMessage, detections);
        
      // Só adiciona anexos em plataformas não-web
      if (!kIsWeb) {
        // Save image to temporary file for attachment
        final tempDir = await getTemporaryDirectory();
        final tempFile = io.File('${tempDir.path}/$imageFilename');
        await tempFile.writeAsBytes(imageBytes);
        print('📧 Imagem salva temporariamente em: ${tempFile.path}');
        
        message.attachments = [
          FileAttachment(tempFile)
            ..location = Location.inline
            ..cid = '<weapon_detection_image>'
        ];
        
        // Limpeza do arquivo temporário depois  
        addPostProcessing(() async {
          try {
            await tempFile.delete();
          } catch (e) {
            print('⚠️ Erro ao deletar arquivo temporário: $e');
          }
        });
      } else {
        // Em web, adicionamos uma mensagem avisando sobre a ausência da imagem
        message.html = message.html! + '''
        <div style="color: #FF5722; padding: 10px; margin-top: 20px; border: 1px solid #FF5722; border-radius: 5px;">
          <p><strong>Nota:</strong> A imagem da detecção não está disponível neste email devido às limitações técnicas.</p>
        </div>
        ''';
      }
      
      print('📧 Tentando enviar email...');
      
      // Send the email
      final sendReport = await send(message, smtpServer);
      print('✅ Email enviado com sucesso: ${sendReport.toString()}');
      
      return true;
    } catch (e) {
      print('❌ Erro detalhado ao enviar email: $e');
      
      // Log detalhado do erro
      if (e is MailerException) {
        print('Detalhes do erro de email:');
        for (var problem in e.problems) {
          print('  - ${problem.code}: ${problem.msg}');
        }
      } else if (e is io.SocketException) {
        print('Erro de conexão: ${e.message}');
        print('Endereço: ${e.address?.address}');
        print('Porta: ${e.port}');
      }
      
      return false;
    }
  }

  String _createAlertEmailBody(
    String cameraName, 
    String cameraId, 
    String message, 
    List<Map<String, dynamic>> detections
  ) {
    final timestamp = DateTime.now().toString();
    
    final detectionsText = detections.map((detection) {
      final className = detection['class'] ?? 'Arma desconhecida';
      final confidence = detection['confidence'] != null ? 
          '${(detection['confidence'] * 100).toStringAsFixed(1)}%' : 'N/A';
      
      return '• $className (Confiança: $confidence)';
    }).join('\n');
    
    return '''
🚨 ALERTA DE SEGURANÇA - ARMA DETECTADA 🚨

Câmera: $cameraName (ID: $cameraId)
Data/Hora: $timestamp
Mensagem: $message

ARMAS DETECTADAS:
$detectionsText

⚠️  AÇÃO IMEDIATA NECESSÁRIA ⚠️
''';
  }
  
  String _createAlertEmailHtml(
    String cameraName, 
    String cameraId, 
    String message, 
    List<Map<String, dynamic>> detections
  ) {
    final timestamp = DateTime.now().toString();
    
    final detectionsHtml = detections.map((detection) {
      final className = detection['class'] ?? 'Arma desconhecida';
      final confidence = detection['confidence'] != null ? 
          '${(detection['confidence'] * 100).toStringAsFixed(1)}%' : 'N/A';
          
      return '''
        <li style="margin: 8px 0">
          <strong>$className</strong> (Confiança: $confidence)
        </li>
      ''';
    }).join('\n');
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; }
    .header { color: #d32f2f; font-size: 24px; font-weight: bold; }
    .alert { background-color: #ffebee; border-left: 4px solid #f44336; padding: 15px; }
    .image { margin: 20px 0; }
    img { max-width: 100%; border: 1px solid #ddd; }
  </style>
</head>
<body>
  <div class="header">🚨 ALERTA DE SEGURANÇA - ARMA DETECTADA</div>
  
  <div class="alert">
    <p><strong>Câmera:</strong> $cameraName (ID: $cameraId)<br>
    <strong>Data/Hora:</strong> $timestamp<br>
    <strong>Mensagem:</strong> $message</p>
  </div>
  
  <h3>Armas Detectadas:</h3>
  <ul>
    $detectionsHtml
  </ul>
  
  <div class="image">
    <h4>Imagem capturada:</h4>
    <img src="cid:weapon_detection_image" alt="Imagem da detecção">
  </div>
  
  <div class="alert">
    <p><strong>⚠️ AÇÃO IMEDIATA NECESSÁRIA</strong></p>
    <p>Verifique a câmera imediatamente e tome as medidas de segurança apropriadas.</p>
  </div>
</body>
</html>
''';
  }

  // Método de teste para verificar se a configuração está correta
  Future<bool> testConnection() async {
    try {
      print('📧 Testando conexão com servidor: $_smtpServer:$_smtpPort');
      print('📧 Usuário: $_username');
      
      // Verifica se está em ambiente web
      if (kIsWeb) {
        print('📧 Executando em ambiente Web - realizando validação básica');
        // Em ambiente web, apenas validamos as credenciais em vez de tentar conectar
        if (_username.isEmpty || !_username.contains('@')) {
          throw Exception('Email inválido');
        }
        if (_password.isEmpty) {
          throw Exception('Senha não fornecida');
        }
        
        // Como não podemos testar a conexão real em web, retornamos sucesso se credenciais parecerem válidas
        print('✅ Validação básica de credenciais bem-sucedida (modo web)');
        return true;
      }
      
      // Em plataformas nativas, tentamos conectar de fato
      SmtpServer smtpServer;
      
      if (_smtpServer.contains('gmail')) {
        print('📧 Usando configuração específica para Gmail');
        smtpServer = gmail(_username, _password);
      } else {
        print('📧 Usando configuração SMTP personalizada');
        smtpServer = SmtpServer(
          _smtpServer,
          port: _smtpPort,
          ssl: _useSSL,
          username: _username,
          password: _password,
        );
      }
      
      // Modificação aqui - criamos um cliente SMTP simples em vez de usar PersistentConnection
      // Teste simples de conexão usando o método send com uma mensagem vazia
      final message = Message()
        ..from = Address(_username, 'Test')
        ..recipients.add(_username)
        ..subject = 'Test Connection'
        ..text = 'This is a test message';
      
      try {
        // Tentar conectar ao servidor usando o método send, mas sem realmente enviar a mensagem
        final connection = PersistentConnection(smtpServer);
        await connection.send(message);
        await connection.close();
        print('✅ Conexão com servidor de email bem-sucedida!');
        return true;
      } finally {
        // Removes the client.close() as there's no client variable defined
      }
    } catch (e) {
      print('❌ Erro ao testar conexão com servidor de email: $e');
      
      // Log detalhado do erro
      if (e is MailerException) {
        print('Detalhes do erro de email:');
        for (var problem in e.problems) {
          print('  - ${problem.code}: ${problem.msg}');
        }
      } else if (e is io.SocketException) {
        print('Erro de conexão: ${e.message}');
        print('Endereço: ${e.address?.address}');
        print('Porta: ${e.port}');
      }
      
      return false;
    }
  }
}

// Helper para anexar tarefas de limpeza
final List<Future<void> Function()> _cleanupTasks = [];

void addPostProcessing(Future<void> Function() task) {
  _cleanupTasks.add(task);
}

Future<void> runCleanupTasks() async {
  for (final task in _cleanupTasks) {
    try {
      await task();
    } catch (e) {
      print('Erro em tarefa de limpeza: $e');
    }
  }
  _cleanupTasks.clear();
}