import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_management_system/screens/dashboard_screen.dart';
import 'package:student_management_system/screens/login_screen.dart';
import 'package:student_management_system/utils/shared_prefs_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lightSweepAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _iconsOpacityAnimation;

  final String _titleText = "Student Management System";
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _checkLoginStatus();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _lightSweepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    _textScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _iconsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => _isLoggedIn ? const DashboardScreen() : const LoginScreen(),
            ),
          );
        });
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final currentLength = (_textOpacityAnimation.value * _titleText.length).clamp(0, _titleText.length).toInt();
          final visibleText = _titleText.substring(0, currentLength);

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: LightSweepPainter(_lightSweepAnimation.value),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: _textOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _textScaleAnimation.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return RadialGradient(
                              center: Alignment.center,
                              radius: 1.2,
                              colors: [
                                Colors.blue.withOpacity(0.7),
                                Colors.white,
                                Colors.blue.withOpacity(0.7),
                              ],
                              stops: const [0.1, 0.5, 0.9],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Text(
                            visibleText,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Opacity(
                      opacity: _iconsOpacityAnimation.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildIconContainer(Icons.person),
                          const SizedBox(width: 40),
                          _buildIconContainer(Icons.school),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

class LightSweepPainter extends CustomPainter {
  final double animationValue;

  LightSweepPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final double sweepPosition = size.width * (animationValue * 1.5 - 0.25);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.blue.withOpacity(0.1),
        Colors.blue.withOpacity(0.3),
        Colors.blue.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
      transform: GradientRotation(0.2),
    ).createShader(Rect.fromLTWH(
      sweepPosition - size.width / 2,
      0,
      size.width,
      size.height,
    ));

    paint.shader = gradient;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(LightSweepPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
