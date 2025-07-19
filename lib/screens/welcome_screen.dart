import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _shapeControllers;
  late List<Animation<double>> _shapeAnimations;
  late List<Animation<double>> _floatingAnimations;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  late AnimationController _titleController;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize shape animations
    _shapeControllers = List.generate(5, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 2400 + (index * 200)),
        vsync: this,
      );
    });
    
    _shapeAnimations = _shapeControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutQuart),
      );
    }).toList();
    
    // Floating animations
    _floatingAnimations = _shapeControllers.map((controller) {
      final floatController = AnimationController(
        duration: Duration(milliseconds: 8000 + (math.Random().nextInt(4000))),
        vsync: this,
      );
      floatController.repeat(reverse: true);
      return Tween<double>(begin: 0.0, end: 15.0).animate(
        CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
      );
    }).toList();
    
    // Fade controller for background gradient
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    // Title animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    
    _startAnimations();
  }
  
  void _startAnimations() async {
    // Start background fade
    _fadeController.forward();
    
    // Start shapes with delays
    for (int i = 0; i < _shapeControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 300 + (i * 100)));
      _shapeControllers[i].forward();
    }
    
    // Start title animation
    await Future.delayed(const Duration(milliseconds: 500));
    _titleController.forward();
  }

  @override
  void dispose() {
    for (var controller in _shapeControllers) {
      controller.dispose();
    }
    _fadeController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF030303),
              Color(0xFF0A0A0A),
              Color(0xFF030303),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background gradient overlay
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.3,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.5,
                        colors: [
                          Color(0xFF4F46E5),
                          Colors.transparent,
                          Color(0xFFE11D48),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Geometric shapes
            ...List.generate(5, (index) => _buildGeometricShape(index, size)),
            
            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF030303),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // Badge
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _titleAnimation.value)),
                          child: Opacity(
                            opacity: _titleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                                color: Colors.white.withOpacity(0.03),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE11D48),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lost & Found Collective',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Main title
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _titleAnimation.value)),
                          child: Opacity(
                            opacity: _titleAnimation.value,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.white, Color(0xCCFFFFFF)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds),
                                  child: Text(
                                    'Find What Matters',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: size.width > 400 ? 42 : 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Colors.white,
                                      Color(0xFFEC4899),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Connect Communities',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: size.width > 400 ? 42 : 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Subtitle
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _titleAnimation.value)),
                          child: Opacity(
                            opacity: _titleAnimation.value * 0.8,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Reuniting lost items with their owners through innovative mobile technology and community connection.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.4),
                                  height: 1.6,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // Action buttons
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _titleAnimation.value)),
                          child: Opacity(
                            opacity: _titleAnimation.value,
                            child: Column(
                              children: [
                                // Login button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(context, '/login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Register button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(context, '/register'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Create Account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.9),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGeometricShape(int index, Size size) {
    final shapeConfigs = [
      {'width': 300.0, 'height': 80.0, 'left': -0.05, 'top': 0.15, 'rotation': 12.0, 'color': const Color(0xFF4F46E5)},
      {'width': 250.0, 'height': 70.0, 'right': -0.02, 'top': 0.7, 'rotation': -15.0, 'color': const Color(0xFFE11D48)},
      {'width': 180.0, 'height': 50.0, 'left': 0.05, 'bottom': 0.1, 'rotation': -8.0, 'color': const Color(0xFF8B5CF6)},
      {'width': 120.0, 'height': 35.0, 'right': 0.15, 'top': 0.12, 'rotation': 20.0, 'color': const Color(0xFFF59E0B)},
      {'width': 90.0, 'height': 25.0, 'left': 0.2, 'top': 0.08, 'rotation': -25.0, 'color': const Color(0xFF06B6D4)},
    ];
    
    final config = shapeConfigs[index];
    
    return AnimatedBuilder(
      animation: Listenable.merge([_shapeAnimations[index], _floatingAnimations[index]]),
      builder: (context, child) {
        final slideValue = _shapeAnimations[index].value;
        final floatValue = _floatingAnimations[index].value;
        
        return Positioned(
          left: config['left'] != null ? size.width * (config['left'] as double) : null,
          right: config['right'] != null ? size.width * (config['right'] as double) : null,
          top: config['top'] != null ? size.height * (config['top'] as double) : null,
          bottom: config['bottom'] != null ? size.height * (config['bottom'] as double) : null,
          child: Transform.translate(
            offset: Offset(
              0, 
              (-150 * (1 - slideValue)) + floatValue,
            ),
            child: Transform.rotate(
              angle: (config['rotation'] as double) * math.pi / 180,
              child: Opacity(
                opacity: slideValue * 0.8,
                child: Container(
                  width: config['width'] as double,
                  height: config['height'] as double,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(config['height'] as double),
                    gradient: LinearGradient(
                      colors: [
                        (config['color'] as Color).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(config['height'] as double),
                      gradient: RadialGradient(
                        center: const Alignment(0.5, 0.5),
                        radius: 0.7,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 