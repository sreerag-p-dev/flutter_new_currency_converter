import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  int _activeDotIndex = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _dotTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          _activeDotIndex = (_activeDotIndex + 1) % 3;
        });
      }
    });

    // Navigate to Login screen after delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 6 : 5,
      height: active ? 6 : 5,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.white,
              Color(
                0xFFE8F0F2,
              ), // Very subtle greenish/blueish tint towards the edges
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Logo Stack
              Stack(
                alignment: Alignment.center,
                children: [
                  // Rotated white background with shadow and green dot
                  Transform.rotate(
                    angle: -0.2, // ~ -11.5 degrees
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFFF3F4F6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 25,
                                spreadRadius: 5,
                                offset: const Offset(5, 5),
                              ),
                            ],
                          ),
                        ),
                        // Green dot indicator
                        Positioned(
                          top: 0,
                          right: -5,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80), // Vibrant green
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dark blue center square
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: const Color(0xFF151924), // Very dark navy
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF151924).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.currency_exchange_rounded,
                        color: Color(0xFF8B9BB4), // Muted grey-blue
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // App Name Text
              Text(
                'CurrencyPro',
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF151924),
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle Text
              Text(
                'PRECISION EXCHANGE',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 3.5,
                ),
              ),
              const Spacer(flex: 2),
              // Bottom Loading Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(active: _activeDotIndex == 0),
                  const SizedBox(width: 6),
                  _buildDot(active: _activeDotIndex == 1),
                  const SizedBox(width: 6),
                  _buildDot(active: _activeDotIndex == 2),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'SECURE CONNECTION',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
