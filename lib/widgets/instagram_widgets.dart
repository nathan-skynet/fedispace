import 'package:flutter/material.dart';

/// Instagram-style search bar
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
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
            color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: false,
        ),
      ),
    );
  }
}

/// Instagram-style action button (for posts, stories, etc.)
class InstagramActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  const InstagramActionButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      ),
    );
  }
}

/// Instagram-style follow button
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: width,
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing
              ? (isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF))
              : const Color(0xFF0095F6),
          foregroundColor: isFollowing
              ? (isDark ? Colors.white : Colors.black)
              : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isFollowing
                ? BorderSide(
                    color: isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB),
                    width: 1,
                  )
                : BorderSide.none,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Instagram-style loading indicator
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
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E8E8E)),
      ),
    );
  }
}

/// Instagram-style divider
class InstagramDivider extends StatelessWidget {
  const InstagramDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 0.5,
      color: isDark ? const Color(0xFF262626) : const Color(0xFFDBDBDB),
    );
  }
}
