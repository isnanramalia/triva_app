import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper class untuk share functionality menggunakan share_plus package
class ShareHelper {
  /// Share text/link ke aplikasi lain
  /// 
  /// Parameters:
  /// - [text]: Text atau link yang akan di-share
  /// - [subject]: Subject untuk email (optional)
  /// - [sharePositionOrigin]: Position untuk iPad share sheet (optional)
  static Future<void> shareText({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      rethrow;
    }
  }

  /// Share trip invite link
  /// 
  /// Parameters:
  /// - [tripName]: Nama trip
  /// - [tripEmoji]: Emoji trip
  /// - [inviteLink]: Link invite
  static Future<void> shareTripInvite({
    required String tripName,
    required String tripEmoji,
    required String inviteLink,
  }) async {
    final message = 'Join my trip "$tripEmoji $tripName" on Triva!\n$inviteLink';
    final subject = 'Join $tripEmoji $tripName';
    
    try {
      await Share.share(
        message,
        subject: subject,
      );
    } catch (e) {
      debugPrint('Error sharing trip invite: $e');
      rethrow;
    }
  }

  /// Share file
  /// 
  /// Parameters:
  /// - [filePath]: Path ke file yang akan di-share
  /// - [mimeType]: MIME type file (optional)
  /// - [text]: Text tambahan (optional)
  static Future<void> shareFile({
    required String filePath,
    String? mimeType,
    String? text,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath, mimeType: mimeType)],
        text: text,
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  /// Share multiple files
  /// 
  /// Parameters:
  /// - [filePaths]: List path file yang akan di-share
  /// - [text]: Text tambahan (optional)
  static Future<void> shareFiles({
    required List<String> filePaths,
    String? text,
  }) async {
    try {
      final files = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(
        files,
        text: text,
      );
    } catch (e) {
      debugPrint('Error sharing files: $e');
      rethrow;
    }
  }

  /// Check if sharing is available on the platform
  static bool get isAvailable {
    // share_plus NOT available on web
    return !kIsWeb;
  }
}

/// Extension untuk kemudahan penggunaan
extension ShareContext on BuildContext {
  /// Share text dari BuildContext
  Future<void> shareText(String text, {String? subject}) async {
    // Get share position for iPad
    final box = findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    await ShareHelper.shareText(
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share trip invite dari BuildContext
  Future<void> shareTripInvite({
    required String tripName,
    required String tripEmoji,
    required String inviteLink,
  }) async {
    await ShareHelper.shareTripInvite(
      tripName: tripName,
      tripEmoji: tripEmoji,
      inviteLink: inviteLink,
    );
  }
}