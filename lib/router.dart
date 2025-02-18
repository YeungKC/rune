import 'dart:io';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;

import 'main.dart';

import 'config/theme.dart';
import 'config/routes.dart';

import 'routes/welcome.dart' as welcome;

import 'widgets/rune_stack.dart';
import 'widgets/shortcuts/router_actions_manager.dart';
import 'widgets/navigation_bar/flip_animation.dart';
import 'widgets/navigation_bar/navigation_bar.dart';
import 'widgets/navigation_bar/navigation_back_button.dart';
import 'widgets/banding_animation/branding_animation.dart';
import 'widgets/playback_controller/cover_art_disk.dart';
import 'widgets/playback_controller/playback_controller.dart';

import 'screens/bsod/bsod.dart';

import 'providers/crash.dart';
import 'providers/library_path.dart';
import 'providers/responsive_providers.dart';
import 'providers/transition_calculation.dart';

import 'theme.dart';

class RouterFrame extends StatefulWidget {
  final AppTheme appTheme;

  const RouterFrame({
    super.key,
    required this.child,
    required this.shellContext,
    required this.appTheme,
  });

  final Widget child;
  final BuildContext? shellContext;

  @override
  State<RouterFrame> createState() => _RouterFrameState();
}

class _RouterFrameState extends State<RouterFrame>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  void _updateWindowEffectCallback() {
    if (Platform.isLinux) return;
    if (Platform.isAndroid) return;

    final theme = FluentTheme.of(context);
    updateWindowEffect(theme);
  }

  void updateWindowEffect(FluentThemeData theme) {
    if (Platform.isLinux) return;
    if (Platform.isAndroid) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.appTheme.setEffect(theme);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.appTheme.addListener(_updateWindowEffectCallback);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateWindowEffectCallback();
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.appTheme.removeListener(_updateWindowEffectCallback);
    super.dispose();
  }

  String _lastRoute = '';
  RouteRelation _lastCompareResult = RouteRelation.same;

  Widget _applyAnimation(Widget child, RouteRelation relation) {
    const distance = 0.1;
    const curve = Curves.easeOutQuint;

    Animation<Offset> createSlideAnimation(Offset begin) {
      return Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: curve,
        ),
      );
    }

    Animation<double> createFadeAnimation() {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: curve,
        ),
      );
    }

    Animation<double> createScaleAnimation() {
      return Tween<double>(begin: 1.1, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: curve,
        ),
      );
    }

    Widget applySlideAndFade(Offset begin) {
      return SlideTransition(
        position: createSlideAnimation(begin),
        child: FadeTransition(
          opacity: createFadeAnimation(),
          child: child,
        ),
      );
    }

    switch (relation) {
      case RouteRelation.parent:
        return applySlideAndFade(const Offset(0, -distance));
      case RouteRelation.child:
        return applySlideAndFade(const Offset(0, distance));
      case RouteRelation.sameLevelAhead:
        return SlideTransition(
          position: createSlideAnimation(const Offset(-distance, 0)),
          child: child,
        );
      case RouteRelation.sameLevelBehind:
        return SlideTransition(
          position: createSlideAnimation(const Offset(distance, 0)),
          child: child,
        );
      case RouteRelation.same:
        return child;
      case RouteRelation.crossLevel:
        return ScaleTransition(
          scale: createScaleAnimation(),
          child: FadeTransition(
            opacity: createFadeAnimation(),
            child: child,
          ),
        );
      default:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) {
    FluentLocalizations.of(context);

    final calculator = Provider.of<TransitionCalculationProvider>(context);
    final path = GoRouterState.of(context).fullPath ?? "/";

    if (path == _lastRoute) {
      return _applyAnimation(widget.child, _lastCompareResult);
    }

    final relation = calculator.compareRoute(path);
    calculator.registerRoute(path);
    _lastRoute = path;
    _lastCompareResult = relation;
    _animationController.reset();
    _animationController.forward();

    return NavigationShortcutManager(
      child: _applyAnimation(widget.child, relation),
    );
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: "/library",
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        final library = Provider.of<LibraryPathProvider>(context);
        final r = Provider.of<ResponsiveProvider>(context);
        final crash = Provider.of<CrashProvider>(context);

        final isCar = r.smallerOrEqualTo(DeviceType.car, false);
        final isZune = r.smallerOrEqualTo(DeviceType.zune, false);
        final diskOnRight = r.smallerOrEqualTo(DeviceType.car, false);

        final showDisk = isZune || isCar;

        if (library.currentPath == null) {
          return const welcome.WelcomePage();
        }

        if (library.scanning) {
          return const welcome.ScanningPage();
        }

        if (crash.report != null) {
          return Bsod(report: crash.report!);
        }

        final mainContent = FocusTraversalOrder(
          order: const NumericFocusOrder(2),
          child: RouterFrame(
            shellContext: _shellNavigatorKey.currentContext,
            appTheme: appTheme,
            child: child,
          ),
        );

        final path = GoRouterState.of(context).fullPath ?? "/";

        return Stack(
          children: [
            if (!disableBrandingAnimation) const BrandingAnimation(),
            ScaleFadeContainer(
              delay: disableBrandingAnimation
                  ? const Duration(milliseconds: 0)
                  : const Duration(milliseconds: 4350),
              duration: disableBrandingAnimation
                  ? const Duration(milliseconds: 200)
                  : const Duration(milliseconds: 500),
              child: FlipAnimationContext(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: RuneStack(
                    alignment: diskOnRight
                        ? Alignment.centerRight
                        : Alignment.bottomCenter,
                    children: [
                      if (path == '/cover_wall' && !showDisk) mainContent,
                      if (!showDisk)
                        const FocusTraversalOrder(
                          order: NumericFocusOrder(3),
                          child: PlaybackController(),
                        ),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: DeviceTypeBuilder(
                          deviceType: const [
                            DeviceType.band,
                            DeviceType.dock,
                            DeviceType.tv
                          ],
                          builder: (context, activeBreakpoint) {
                            final isSmallView =
                                activeBreakpoint == DeviceType.band ||
                                    activeBreakpoint == DeviceType.dock;

                            if (!isSmallView) return const NavigationBar();

                            return const Positioned(
                              top: -12,
                              left: -12,
                              child: NavigationBackButton(),
                            );
                          },
                        ),
                      ),
                      if (!(path == '/cover_wall' && !showDisk)) mainContent,
                      if (showDisk)
                        const FocusTraversalOrder(
                          order: NumericFocusOrder(4),
                          child: CoverArtDisk(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      routes: routes,
    ),
  ],
);

class ScaleFadeContainer extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const ScaleFadeContainer({
    super.key,
    required this.child,
    this.delay = const Duration(seconds: 0),
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  ScaleFadeContainerState createState() => ScaleFadeContainerState();
}

class ScaleFadeContainerState extends State<ScaleFadeContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
