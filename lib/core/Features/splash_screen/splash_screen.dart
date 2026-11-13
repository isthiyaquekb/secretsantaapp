import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:secretsantaapp/core/Features/draw/all_done_screen.dart';
import 'package:secretsantaapp/core/Features/draw/whos_drawing_screen.dart';
import 'package:secretsantaapp/core/Features/participants/participants_screen.dart';
import 'package:secretsantaapp/core/constants/app_assets.dart';
import 'package:secretsantaapp/core/data/draw_repository.dart';
import 'package:secretsantaapp/core/theme/app_colors.dart';
import 'package:secretsantaapp/core/widgets/snowfall_overlay.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _twinkle;

  late final Animation<double> _circleScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoTilt;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _starScale;
  late final Animation<double> _subtitleFade;

  bool _started = false;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    CurvedAnimation curve(double begin, double end, Curve c) =>
        CurvedAnimation(parent: _intro, curve: Interval(begin, end, curve: c));

    _circleScale = curve(0.0, 0.35, Curves.easeOutBack);
    _logoScale = curve(0.15, 0.6, Curves.elasticOut);
    _logoFade = curve(0.15, 0.35, Curves.easeOut);
    _logoTilt = Tween<double>(begin: -0.15, end: 0.0)
        .animate(curve(0.15, 0.65, Curves.easeOutCubic));
    _titleFade = curve(0.5, 0.8, Curves.easeOut);
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(curve(0.5, 0.8, Curves.easeOutCubic));
    _starScale = curve(0.7, 0.9, Curves.easeOutBack);
    _subtitleFade = curve(0.8, 1.0, Curves.easeOut);

    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  Future<void> _run() async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      _intro.value = 1;
      await Future.delayed(const Duration(milliseconds: 600));
    } else {
      try {
        await _intro.forward();
      } on TickerCanceled {
        return;
      }
      _twinkle.repeat(reverse: true);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    if (!mounted) return;
    await _goNext();
  }

  Future<void> _goNext() async {
    final state = await DrawRepository.instance.load();
    if (!mounted) return;
    final Widget next = !state.isDrawn
        ? const ParticipantsScreen()
        : state.isComplete
            ? const AllDoneScreen()
            : const WhosDrawingScreen();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SnowfallOverlay(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circle + logo
              ScaleTransition(
                scale: _circleScale,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerHigh
                        : AppColors.lightSurfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _intro,
                      builder: (context, child) => Opacity(
                        opacity: _logoFade.value.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: _logoTilt.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(220),
                        child: SvgPicture.asset(
                          AppAssets.appLogoSvg,
                          width: 220,
                          height: 220,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.card_giftcard,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title + star
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Secret Santa', style: theme.textTheme.displayMedium),
                      const SizedBox(width: 6),
                      ScaleTransition(
                        scale: _starScale,
                        child: AnimatedBuilder(
                          animation: _twinkle,
                          builder: (context, child) => Opacity(
                            opacity: 0.7 + 0.3 * _twinkle.value,
                            child: Transform.scale(
                              scale: 1.0 + 0.2 * _twinkle.value,
                              child: child,
                            ),
                          ),
                          child: Text(
                            '★',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              FadeTransition(
                opacity: _subtitleFade,
                child: Text(
                  'Holiday Office Exchange',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    letterSpacing: 0.5,
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