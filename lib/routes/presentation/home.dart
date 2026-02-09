import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fedispace/l10n/app_localizations.dart';

class presentation extends StatefulWidget {
  const presentation({Key? key}) : super(key: key);

  @override
  State<presentation> createState() => _presentationState();
}

class _presentationState extends State<presentation>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _bgController;
  int _currentPage = 0;

  // Slide accent colors for gradients
  static const _slideColors = [
    Color(0xFFFF6B35), // Pixelfed — warm orange
    Color(0xFF6C63FF), // Fediverse — purple
    Color(0xFF00E676), // Privacy — green
  ];

  static const _slideIcons = [
    Icons.camera_alt_rounded,
    Icons.public_rounded,
    Icons.shield_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onDone() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final size = MediaQuery.of(context).size;

    final slides = [
      _SlideData(
        title: l.presentPixelfedTitle,
        description: l.presentPixelfedDesc,
        imagePath: 'assets/images/pixelfed.png',
        color: _slideColors[0],
        icon: _slideIcons[0],
      ),
      _SlideData(
        title: l.presentFediverseTitle,
        description: l.presentFediverseDesc,
        imagePath: 'assets/images/fediverse.png',
        color: _slideColors[1],
        icon: _slideIcons[1],
      ),
      _SlideData(
        title: l.presentPrivacyTitle,
        description: l.presentPrivacyDesc,
        imagePath: 'assets/images/privacy.png',
        color: _slideColors[2],
        icon: _slideIcons[2],
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Animated gradient background ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  _slideColors[_currentPage].withValues(alpha: 0.15),
                  const Color(0xFF0A0A0F),
                ],
              ),
            ),
          ),

          // ── Page content ──
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _onDone,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      return _SlideWidget(
                        data: slides[index],
                        screenSize: size,
                      );
                    },
                  ),
                ),

                // ── Bottom bar: dots + button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Row(
                    children: [
                      // Page dots
                      Row(
                        children: List.generate(slides.length, (i) {
                          final isActive = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(right: 8),
                            width: isActive ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive
                                  ? _slideColors[_currentPage]
                                  : Colors.white.withValues(alpha: 0.2),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      // Next / Done button
                      _buildActionButton(slides.length),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(int totalSlides) {
    final isLast = _currentPage == totalSlides - 1;
    const accentColor = Color(0xFF00F3FF);

    return GestureDetector(
      onTap: () {
        if (isLast) {
          _onDone();
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isLast ? 120 : 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isLast
                ? [accentColor, accentColor.withValues(alpha: 0.7)]
                : [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
          ),
          border: Border.all(
            color: isLast
                ? accentColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
          boxShadow: isLast
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLast
              ? const Text(
                  'Get Started',
                  style: TextStyle(
                    color: Color(0xFF0A0A0F),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide data model
// ─────────────────────────────────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String description;
  final String imagePath;
  final Color color;
  final IconData icon;

  const _SlideData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.color,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide widget
// ─────────────────────────────────────────────────────────────────────────────

class _SlideWidget extends StatefulWidget {
  final _SlideData data;
  final Size screenSize;

  const _SlideWidget({required this.data, required this.screenSize});

  @override
  State<_SlideWidget> createState() => _SlideWidgetState();
}

class _SlideWidgetState extends State<_SlideWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Image container with glow ──
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow behind image
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: d.color.withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Glass container
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.03),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Center(
                          child: Image.asset(
                            d.imagePath,
                            width: 90,
                            height: 90,
                            errorBuilder: (_, __, ___) => Icon(
                              d.icon,
                              size: 60,
                              color: d.color.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ── Title ──
              Text(
                d.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: d.color.withValues(alpha: 0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Accent line ──
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: d.color,
                ),
              ),

              const SizedBox(height: 24),

              // ── Description in glass card ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  d.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
