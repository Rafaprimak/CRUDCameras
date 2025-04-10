import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/camera_group_service.dart';
import '../services/user_service.dart';
import 'camera_list_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _showButton = false;
  bool _showLoginForm = false;
  bool _showRegistrationForm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registrationFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
    
    Timer(const Duration(milliseconds: 800), () {
      setState(() {
        _showButton = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isFormVisible = _showLoginForm || _showRegistrationForm;
    
    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFffc112).withAlpha(26),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom, // Account for system UI
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFffc112).withAlpha(26),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFffc112).withAlpha(39),
                    ),
                  ),
                ),
                
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width > 600 ? 40 : 20,
                      vertical: MediaQuery.of(context).size.height < 600 ? 20 : 40, // Adjust based on height
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          height: isFormVisible ? 
                            (MediaQuery.of(context).size.height > 650 ? 160 : 
                             (MediaQuery.of(context).size.height > 600 ? 130 : 120)) : 
                            (MediaQuery.of(context).size.width > 380 ? 270 : 
                             (MediaQuery.of(context).size.width > 340 ? 220 : 190)),
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _fadeInAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: 'app_logo',
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    width: isFormVisible ? 
                                      (MediaQuery.of(context).size.height > 650 ? 90 : 75) : 140,
                                    height: isFormVisible ? 
                                      (MediaQuery.of(context).size.height > 650 ? 90 : 75) : 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          Colors.white.withAlpha(230),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFffc112).withAlpha(77),
                                          blurRadius: 25,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 5),
                                        ),
                                        BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 15,
                                          spreadRadius: -5,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(isFormVisible ? 6 : 14),
                                    child: Center(
                                      child: Container(
                                        padding: EdgeInsets.all(isFormVisible ? 5 : 10),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFffc112),
                                              Color(0xFFff7f11),
                                            ],
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Image.asset(
                                            'assets/images/armadillo_logo.png',
                                            width: isFormVisible ? 
                                              (MediaQuery.of(context).size.height > 650 ? 50 : 40) : 90,
                                            height: isFormVisible ? 
                                              (MediaQuery.of(context).size.height > 650 ? 50 : 40) : 90,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isFormVisible ? 6 : 16),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 500),
                                    style: TextStyle(
                                      fontSize: isFormVisible ? 
                                        (MediaQuery.of(context).size.width > 380 ? 28 : 22) : 
                                        (MediaQuery.of(context).size.width > 380 ? 44 : 32),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                      height: 1.0,
                                      letterSpacing: isFormVisible ? 1.0 : 1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withAlpha(26),
                                          offset: const Offset(1, 2),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Text('Armadillo'),
                                  ),
                                ),
                                if (!isFormVisible) 
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Sistema de Segurança inteligente',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.width < 340 ? 10 : 12,
                                            height: 0.9,
                                            color: Colors.black54,
                                            fontWeight: MediaQuery.of(context).size.width < 340 ? 
                                              FontWeight.w300 : FontWeight.w400,
                                            letterSpacing: MediaQuery.of(context).size.width < 340 ? 0.0 : 0.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isFormVisible ? 
                          (MediaQuery.of(context).size.height < 600 ? 5 : 10) : // Less spacing
                          (MediaQuery.of(context).size.height < 600 ? 20 : 30)), // Less spacing
                        
                        AnimatedOpacity(
                          opacity: _showButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: !_showLoginForm && !_showRegistrationForm
                              ? AnimatedScale(
                                  key: const ValueKey('start_button'),
                                  scale: _showButton ? 1.0 : 0.8,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _showLoginForm = true;
                                      });
                                      HapticFeedback.mediumImpact();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFffc112),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      elevation: 4,
                                      shadowColor: const Color(0xFFffc112).withAlpha(128),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Iniciar'),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded),
                                      ],
                                    ),
                                  ),
                                )
                              : _showLoginForm 
                                  ? _buildLoginForm()
                                  : _buildRegistrationForm(),
                          ),
                        ),
                        
                        if (_showButton && !isFormVisible)
                          AnimatedOpacity(
                            opacity: _showButton ? 0.7 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Text(
                                'Versão 1.0.0',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Container(
        key: const ValueKey('login_form'),
        width: screenWidth > 450 ? 300 : screenWidth * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showLoginForm = false;
                      });
                    },
                    child: const Text('Voltar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_loginFormKey.currentState!.validate()) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFffc112),
                            ),
                          ),
                        );
                        
                        try {
                          final userService = UserService();
                          await userService.loginUser(
                            _emailController.text.trim(),
                            _passwordController.text
                          );
                          
                          final groupService = CameraGroupService();
                          await groupService.initialize();
                          
                          if (mounted) Navigator.pop(context);
                          
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => 
                                    const CameraListScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOutCubic;
                                  
                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));
                                  
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 600),
                              ),
                            );
                          }
                        } catch (error) {
                          if (mounted) Navigator.pop(context);
                          
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Erro no Login'),
                                content: Text(
                                  'Não foi possível realizar o login: ${error.toString()}',
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFffc112),
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFffc112),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showRegistrationForm = true;
                    _showLoginForm = false;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Text(
                  'Não tem uma conta? Cadastre-se aqui',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final verticalSpacing = screenHeight < 600 ? 10.0 : 15.0;
    
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Container(
        key: const ValueKey('registration_form'),
        width: screenWidth > 450 ? 330 : screenWidth * 0.85,
        padding: EdgeInsets.all(screenHeight < 600 ? 15 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _registrationFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Criar uma Conta',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: verticalSpacing + 5),
              TextFormField(
                controller: _regNameController,
                decoration: InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalSpacing),
              TextFormField(
                controller: _regEmailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                    return 'Por favor, insira um email válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalSpacing),
              TextFormField(
                controller: _regPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalSpacing),
              TextFormField(
                controller: _regConfirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme sua senha';
                  }
                  if (value != _regPasswordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              SizedBox(height: screenHeight < 600 ? 15 : 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showRegistrationForm = false;
                        _showLoginForm = true;
                      });
                    },
                    child: const Text('Voltar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_registrationFormKey.currentState!.validate()) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFffc112),
                            ),
                          ),
                        );
                        
                        try {
                          final userService = UserService();
                          await userService.registerUser(
                            _regNameController.text.trim(),
                            _regEmailController.text.trim(),
                            _regPasswordController.text
                          );
                          
                          if (mounted) Navigator.pop(context);
                          
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cadastro Realizado!'),
                                content: const Text(
                                  'Sua conta foi criada com sucesso. Agora você pode fazer login.',
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _showRegistrationForm = false;
                                        _showLoginForm = true;
                                        _regNameController.clear();
                                        _regEmailController.clear();
                                        _regPasswordController.clear();
                                        _regConfirmPasswordController.clear();
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFffc112),
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (error) {
                          if (mounted) Navigator.pop(context);
                          
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Erro no Cadastro'),
                                content: Text(
                                  'Não foi possível completar o cadastro: ${error.toString()}',
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFffc112),
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFffc112),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    ),
                    child: const Text('Cadastrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}