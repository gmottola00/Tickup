// presentation/pages/shell/main_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/widgets/bottom_nav_bar.dart';
import 'package:tickup/providers/navigation_provider.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _bottomNavAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _bottomNavSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  // Scroll controller per nascondere la bottom nav durante lo scroll
  ScrollController? _activeScrollController;
  bool _isScrolling = false;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Setup animazioni
    _setupAnimations();
  }

  void _setupAnimations() {
    // Bottom Navigation animation
    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bottomNavSlideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _bottomNavAnimationController,
      curve: Curves.easeInOut,
    ));

    // FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Start with nav visible
    _bottomNavAnimationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bottomNavAnimationController.dispose();
    _fabAnimationController.dispose();
    _activeScrollController?.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gestisci il ciclo di vita dell'app
    switch (state) {
      case AppLifecycleState.resumed:
        // App tornata in primo piano
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App in background
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onAppResumed() {
    // Refresh dati quando l'app torna attiva
    HapticFeedback.lightImpact();
    // Puoi invalidare provider specifici qui se necessario
  }

  void _onAppPaused() {
    // Salva stato se necessario
  }

  // Gestione scroll per auto-hide della bottom nav
  void _handleScroll() {
    if (_activeScrollController == null) return;

    final currentScrollPosition = _activeScrollController!.position.pixels;
    final maxScroll = _activeScrollController!.position.maxScrollExtent;

    // Non nascondere se siamo vicini al top o bottom
    if (currentScrollPosition <= 0 || currentScrollPosition >= maxScroll) {
      _showBottomNav();
      return;
    }

    // Determina direzione dello scroll
    if (currentScrollPosition > _lastScrollPosition &&
        currentScrollPosition > 100) {
      // Scrolling giù - nascondi
      _hideBottomNav();
    } else if (currentScrollPosition < _lastScrollPosition) {
      // Scrolling su - mostra
      _showBottomNav();
    }

    _lastScrollPosition = currentScrollPosition;
  }

  void _hideBottomNav() {
    if (!_isScrolling) {
      _isScrolling = true;
      ref.read(hideBottomNavProvider.notifier).state = true;
      _bottomNavAnimationController.reverse();
      _fabAnimationController.reverse();
    }
  }

  void _showBottomNav() {
    if (_isScrolling) {
      _isScrolling = false;
      ref.read(hideBottomNavProvider.notifier).state = false;
      _bottomNavAnimationController.forward();
      _fabAnimationController.forward();
    }
  }

  // Registra scroll controller dalla pagina child
  void _registerScrollController(ScrollController? controller) {
    if (_activeScrollController != controller) {
      _activeScrollController?.removeListener(_handleScroll);
      _activeScrollController = controller;
      _activeScrollController?.addListener(_handleScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hideBottomNav = ref.watch(hideBottomNavProvider);
    final currentTabIndex = ref.watch(currentTabIndexProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determina se mostrare il FAB
    final showFab = currentTabIndex == 0; // Solo nella tab Giochi

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Main content con SafeArea
            SafeArea(
              bottom: false, // Permetti al contenuto di andare sotto la nav
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _registerScrollController(notification.context
                        ?.findRenderObject() as ScrollController?);
                  }
                  return false;
                },
                child: widget.child,
              ),
            ),

            // Gradient overlay per bottom nav (effetto sfumato)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: hideBottomNav ? 0 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDarkMode ? const Color(0xFF111827) : Colors.white)
                              .withOpacity(0),
                          (isDarkMode ? const Color(0xFF111827) : Colors.white)
                              .withOpacity(0.5),
                          (isDarkMode ? const Color(0xFF111827) : Colors.white)
                              .withOpacity(0.9),
                          isDarkMode ? const Color(0xFF111827) : Colors.white,
                        ],
                        stops: const [0, 0.3, 0.7, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Bottom Navigation Bar animata
        bottomNavigationBar: AnimatedBuilder(
          animation: _bottomNavSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 100 * (1 - _bottomNavSlideAnimation.value)),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _bottomNavSlideAnimation.value,
                child: const ModernBottomNavigation(),
              ),
            );
          },
        ),

        // Floating Action Button (solo in alcune tab)
        floatingActionButton: showFab
            ? AnimatedBuilder(
                animation: _fabScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabScaleAnimation.value,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: hideBottomNav ? const Offset(0, 2) : Offset.zero,
                      child: _buildFloatingActionButton(context),
                    ),
                  );
                },
              )
            : null,

        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        // Abilita il contenuto a estendersi sotto la nav
        extendBody: true,
        extendBodyBehindAppBar: true,
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Spazio per la bottom nav
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showQuickPlayDialog(context);
        },
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.bolt),
        label: const Text('Azioni'),
        elevation: 8,
        highlightElevation: 12,
      ),
    );
  }

  void _showQuickPlayDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickActionsBottomSheet(),
    );
  }
}

// Bottom sheet per azioni rapide
class QuickActionsBottomSheet extends StatelessWidget {
  const QuickActionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              'Azioni rapide',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              context.push(AppRoute.prize);
            },
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_box, color: theme.colorScheme.primary),
            ),
            title: const Text(
              'Aggiungi prodotto',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Crea un nuovo premio/prodotto'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
