import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class OnvifService {
  final String ipAddress;
  final int port;
  final String username;
  final String password;
  String? _deviceServiceUri;
  String? _ptzServiceUri;
  String? _mediaServiceUri;
  String? _authToken;

  OnvifService({
    required this.ipAddress,
    this.port = 80,
    this.username = 'admin',
    this.password = 'admin',
  });

  Future<bool> initialize() async {
    try {
      // Discover ONVIF services
      final success = await _discoverServices();
      if (success) {
        await _getAuthToken();
      }
      return success;
    } catch (e) {
      print('Erro ao inicializar ONVIF: $e');
      return false;
    }
  }

  Future<bool> _discoverServices() async {
    try {
      final envelope = '''
      <Envelope xmlns="http://www.w3.org/2003/05/soap-envelope">
        <Body>
          <GetServices xmlns="http://www.onvif.org/ver10/device/wsdl">
            <IncludeCapability>false</IncludeCapability>
          </GetServices>
        </Body>
      </Envelope>
      ''';
      
      final response = await http.post(
        Uri.parse('http://$ipAddress:$port/onvif/device_service'),
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
        },
        body: envelope,
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        print('Erro na resposta ONVIF: ${response.statusCode}');
        return false;
      }
      
      final document = xml.XmlDocument.parse(response.body);
      
      // Extract service URIs
      _deviceServiceUri = _extractServiceUri(document, 'Device');
      _ptzServiceUri = _extractServiceUri(document, 'PTZ');
      _mediaServiceUri = _extractServiceUri(document, 'Media');
      
      return _deviceServiceUri != null;
    } catch (e) {
      print('Erro ao descobrir serviços ONVIF: $e');
      return false;
    }
  }
  
  String? _extractServiceUri(xml.XmlDocument document, String nameSpace) {
    try {
      final services = document.findAllElements('tds:Service');
      for (var service in services) {
        final namespace = service.findElements('tds:Namespace').single.text;
        if (namespace.contains(nameSpace)) {
          return service.findElements('tds:XAddr').single.text;
        }
      }
      return null;
    } catch (e) {
      print('Erro ao extrair URI de serviço para $nameSpace: $e');
      return null;
    }
  }
  
  Future<bool> _getAuthToken() async {
    try {
      // Create authentication elements
      final envelope = '''
      <Envelope xmlns="http://www.w3.org/2003/05/soap-envelope">
        <Body>
          <GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/>
        </Body>
      </Envelope>
      ''';
      
      final response = await http.post(
        Uri.parse('http://$ipAddress:$port/onvif/device_service'),
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
        },
        body: envelope,
      );
      
      if (response.statusCode == 200) {
        _authToken = "Obtained"; // Simplificado para este exemplo
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erro ao obter token de autenticação: $e');
      return false;
    }
  }
  
  // Mover a câmera usando PTZ (Pan/Tilt/Zoom)
  Future<bool> movePtz(String direction, double speed) async {
    if (_ptzServiceUri == null || _authToken == null) {
      return false;
    }
    
    try {
      double panSpeed = 0.0;
      double tiltSpeed = 0.0;
      
      switch (direction) {
        case 'left':
          panSpeed = -speed;
          break;
        case 'right':
          panSpeed = speed;
          break;
        case 'up':
          tiltSpeed = speed;
          break;
        case 'down':
          tiltSpeed = -speed;
          break;
      }
      
      final envelope = '''
      <Envelope xmlns="http://www.w3.org/2003/05/soap-envelope">
        <Header>
          <Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
            <UsernameToken>
              <Username>$username</Username>
              <Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">$password</Password>
            </UsernameToken>
          </Security>
        </Header>
        <Body>
          <ContinuousMove xmlns="http://www.onvif.org/ver20/ptz/wsdl">
            <ProfileToken>Profile_1</ProfileToken>
            <Velocity>
              <PanTilt x="$panSpeed" y="$tiltSpeed" xmlns="http://www.onvif.org/ver10/schema"/>
              <Zoom x="0" xmlns="http://www.onvif.org/ver10/schema"/>
            </Velocity>
          </ContinuousMove>
        </Body>
      </Envelope>
      ''';
      
      final response = await http.post(
        Uri.parse(_ptzServiceUri!),
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
        },
        body: envelope,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao mover câmera: $e');
      return false;
    }
  }
  
  // Parar movimento PTZ
  Future<bool> stopPtz() async {
    if (_ptzServiceUri == null || _authToken == null) {
      return false;
    }
    
    try {
      final envelope = '''
      <Envelope xmlns="http://www.w3.org/2003/05/soap-envelope">
        <Header>
          <Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
            <UsernameToken>
              <Username>$username</Username>
              <Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">$password</Password>
            </UsernameToken>
          </Security>
        </Header>
        <Body>
          <Stop xmlns="http://www.onvif.org/ver20/ptz/wsdl">
            <ProfileToken>Profile_1</ProfileToken>
            <PanTilt>true</PanTilt>
            <Zoom>true</Zoom>
          </Stop>
        </Body>
      </Envelope>
      ''';
      
      final response = await http.post(
        Uri.parse(_ptzServiceUri!),
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
        },
        body: envelope,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao parar movimento da câmera: $e');
      return false;
    }
  }
}