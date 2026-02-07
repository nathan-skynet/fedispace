import 'package:flutter/material.dart';

/// Instagram-style bottom navigation bar with 5 tabs
/// Matches the modern Instagram UI with icons and active state indicators
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFDBDBDB);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search,
                activeIcon: Icons.search,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.video_library_outlined,
                activeIcon: Icons.video_library,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    Key? key,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Center(
          child: Icon(
            isActive ? activeIcon : icon,
            size: 26,
            color: isActive
                ? Theme.of(context).iconTheme.color
                : Theme.of(context).iconTheme.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _ProfileNavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Center(
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Theme.of(context).iconTheme.color ?? Colors.black
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null
                    ? Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
