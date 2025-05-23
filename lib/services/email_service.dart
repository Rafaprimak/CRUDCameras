import 'dart:io';
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

  /// Send weapon detection alert email with image
  Future<bool> sendWeaponDetectionAlert({
    required String cameraName,
    required String cameraId,
    required String detectionMessage,
    required List<Map<String, dynamic>> detections,
    required List<int> imageBytes,
    String imageFilename = 'detection.jpg',
  }) async {
    try {
      // Save image to temporary file for attachment
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$imageFilename');
      await tempFile.writeAsBytes(imageBytes);
      
      // Configure SMTP server
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _smtpPort,
        ssl: _useSSL,
        username: _username,
        password: _password,
      );
      
      // Create the email message
      final message = Message()
        ..from = Address(_username, 'Sistema de Segurança')
        ..recipients.addAll(_recipients)
        ..subject = 'ALERTA! Arma detectada na câmera $cameraName'
        ..text = _createAlertEmailBody(cameraName, cameraId, detectionMessage, detections)
        ..html = _createAlertEmailHtml(cameraName, cameraId, detectionMessage, detections)
        ..attachments = [
          FileAttachment(tempFile)
            ..location = Location.inline
            ..cid = '<image>'
        ];
      
      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
      
      // Clean up the temp file
      await tempFile.delete();
      
      return true;
    } catch (e) {
      print('Error sending email: $e');
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
      final className = detection['class'] ?? 'Desconhecido';
      final confidence = detection['confidence'] != null ? 
          '${(detection['confidence'] * 100).toStringAsFixed(1)}%' : 'N/A';
      
      return '- $className (Confiança: $confidence)';
    }).join('\n');
    
    return '''
ALERTA DE SEGURANÇA - ARMA DETECTADA

Câmera: $cameraName (ID: $cameraId)
Data/Hora: $timestamp
Mensagem: $message

Detecções:
$detectionsText

Este é um email automático gerado pelo sistema de monitoramento de segurança.
Por favor, tome as medidas apropriadas imediatamente.
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
      final className = detection['class'] ?? 'Desconhecido';
      final confidence = detection['confidence'] != null ? 
          '${(detection['confidence'] * 100).toStringAsFixed(1)}%' : 'N/A';
          
      return '<li><strong>$className</strong> (Confiança: $confidence)</li>';
    }).join('\n');
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .alert { background-color: #ffdddd; border-left: 6px solid #f44336; padding: 16px; }
    .header { color: #f44336; font-size: 24px; font-weight: bold; }
    .camera { font-size: 18px; margin: 12px 0; }
    .image-container { margin: 20px 0; }
    .detections { margin: 16px 0; }
  </style>
</head>
<body>
  <div class="alert">
    <div class="header">⚠️ ALERTA DE SEGURANÇA - ARMA DETECTADA</div>
    <div class="camera">Câmera: <strong>$cameraName</strong> (ID: $cameraId)</div>
    <div>Data/Hora: $timestamp</div>
    <div><strong>$message</strong></div>
    
    <div class="image-container">
      <img src="cid:image" alt="Imagem da detecção" style="max-width: 100%; border: 1px solid #ddd;" />
    </div>
    
    <div class="detections">
      <strong>Detecções:</strong>
      <ul>
        $detectionsHtml
      </ul>
    </div>
    
    <p>Este é um email automático gerado pelo sistema de monitoramento de segurança.<br>
    Por favor, tome as medidas apropriadas imediatamente.</p>
  </div>
</body>
</html>
''';
  }
}