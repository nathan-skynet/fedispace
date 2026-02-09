import 'package:flutter/material.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Modern search bar with glassmorphic background
class InstagramSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  const InstagramSearchBar({
    Key? key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: CyberpunkTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.borderDark, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        readOnly: readOnly,
        autofocus: autofocus,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: CyberpunkTheme.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: CyberpunkTheme.textTertiary,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: false,
        ),
      ),
    );
  }
}

/// Action button with subtle tap animation
class InstagramActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  const InstagramActionButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.size = 26,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: size,
          color: color ?? CyberpunkTheme.textWhite,
        ),
      ),
    );
  }
}

/// Follow button with gradient accent
class InstagramFollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onPressed;
  final double? width;

  const InstagramFollowButton({
    Key? key,
    required this.isFollowing,
    required this.onPressed,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 34,
      child: isFollowing
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: CyberpunkTheme.textWhite,
                side: const BorderSide(color: CyberpunkTheme.borderDark, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Following', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('Follow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
    );
  }
}

/// Loading indicator with neon cyan
class InstagramLoadingIndicator extends StatelessWidget {
  final double size;

  const InstagramLoadingIndicator({
    Key? key,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(CyberpunkTheme.neonCyan),
      ),
    );
  }
}

/// Subtle divider
class InstagramDivider extends StatelessWidget {
  const InstagramDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: CyberpunkTheme.borderDark,
    );
  }
}

/// Glassmorphic container helper
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: CyberpunkTheme.cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
      ),
      child: child,
    );
  }
}

/// Section header
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    Key? key,
    required this.title,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CyberpunkTheme.textWhite,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CyberpunkTheme.neonCyan,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
