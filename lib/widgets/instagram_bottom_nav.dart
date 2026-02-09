import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Modern bottom navigation bar with cyberpunk accents
/// Clean layout with subtle active state indicators + animated glow halos
class InstagramBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? profileImageUrl;

  const InstagramBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: CyberpunkTheme.borderDark,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                isCreate: true,
              ),
              _NavItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum_rounded,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _ProfileNavItem(
                imageUrl: profileImageUrl,
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isCreate;

  const _NavItem({
    Key? key,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
    this.isCreate = false,
  }) : super(key: key);

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? CyberpunkTheme.neonCyan : CyberpunkTheme.textTertiary;

    return Expanded(
      child: InkWell(
        onTap: widget.onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: widget.isActive
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CyberpunkTheme.neonCyan.withOpacity(_glowAnimation.value),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        )
                      : null,
                  child: child,
                );
              },
              child: AnimatedScale(
                scale: widget.isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isActive ? widget.activeIcon : widget.icon,
                  size: 30,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavItem extends StatefulWidget {
  final String? imageUrl;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileNavItem({
    Key? key,
    this.imageUrl,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ProfileNavItem> createState() => _ProfileNavItemState();
}

class _ProfileNavItemState extends State<_ProfileNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: widget.onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: widget.isActive
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CyberpunkTheme.neonCyan.withOpacity(_glowAnimation.value),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        )
                      : null,
                  child: child,
                );
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isActive
                        ? CyberpunkTheme.neonCyan
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: CircleAvatar(
                    backgroundColor: CyberpunkTheme.cardDark,
                    backgroundImage: widget.imageUrl != null
                        ? CachedNetworkImageProvider(widget.imageUrl!)
                        : null,
                    child: widget.imageUrl == null
                        ? const Icon(Icons.person, size: 16, color: CyberpunkTheme.textTertiary)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
