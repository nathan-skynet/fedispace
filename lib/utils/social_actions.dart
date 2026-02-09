import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/core/logger.dart';

/// Helper class for social media actions
class SocialActions {
  /// Share a status to other apps
  static Future<void> shareStatus(Status status, {BuildContext? context}) async {
    try {
      final String shareText = _buildShareText(status);
      
      appLogger.debug('Sharing status: ${status.id}');
      
      await Share.share(
        shareText,
        subject: 'Check out this post!',
      );
    } catch (e, stackTrace) {
      appLogger.error('Failed to share status', e, stackTrace);
    }
  }

  /// Build share text from status
  static String _buildShareText(Status status) {
    final buffer = StringBuffer();
    
    // Add author info
    if (status.account != null) {
      buffer.writeln('@${status.account!.username}:');
    }
    
    // Add content
    if (status.content != null && status.content!.isNotEmpty) {
      // Strip HTML tags from content
      final cleanContent = _stripHtmlTags(status.content!);
      buffer.writeln(cleanContent);
      buffer.writeln();
    }
    
    // Add URL
    if (status.url != null && status.url!.isNotEmpty) {
      buffer.writeln(status.url);
    }
    
    return buffer.toString().trim();
  }

  /// Strip HTML tags from text
  static String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  /// Share status URL only
  static Future<void> shareStatusUrl(String url) async {
    try {
      appLogger.debug('Sharing URL: $url');
      await Share.share(url);
    } catch (e, stackTrace) {
      appLogger.error('Failed to share URL', e, stackTrace);
    }
  }
}
