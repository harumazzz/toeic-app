import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../i18n/strings.g.dart';

part 'writing_draft_manager.freezed.dart';
part 'writing_draft_manager.g.dart';

class WritingDraftManager {
  const WritingDraftManager._();
  static const String _keyPrefix = 'writing_draft_';
  static Timer? _saveTimer;
  static void saveDraft(final int promptId, final String content) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = '$_keyPrefix$promptId';

        final draftData = WritingDraft(
          content: content,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          promptId: promptId,
        );

        await prefs.setString(key, jsonEncode(draftData.toJson()));
      } catch (e) {
        debugPrint('Error saving draft: $e');
      }
    });
  }

  static Future<String?> loadDraft(final int promptId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$promptId';
      final draftJson = prefs.getString(key);

      if (draftJson == null) {
        return null;
      }

      final draftData = WritingDraft.fromJson(
        jsonDecode(draftJson) as Map<String, dynamic>,
      );

      final draftDate = DateTime.fromMillisecondsSinceEpoch(
        draftData.timestamp,
      );
      final daysDifference = DateTime.now().difference(draftDate).inDays;

      if (daysDifference > 7) {
        await clearDraft(promptId);
        return null;
      }

      return draftData.content;
    } catch (e) {
      debugPrint('Error loading draft: $e');
      return null;
    }
  }

  static Future<void> clearDraft(final int promptId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$promptId';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  static Future<List<DraftInfo>> getAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        ...prefs.getKeys().where((final key) => key.startsWith(_keyPrefix)),
      ];

      final drafts = <DraftInfo>[];

      for (final key in keys) {
        final draftJson = prefs.getString(key);
        if (draftJson != null) {
          try {
            final draftData = WritingDraft.fromJson(
              jsonDecode(draftJson) as Map<String, dynamic>,
            );

            drafts.add(
              DraftInfo(
                promptId: draftData.promptId,
                content: draftData.content,
                lastModified: DateTime.fromMillisecondsSinceEpoch(
                  draftData.timestamp,
                ),
                wordCount: draftData.content.trim().isEmpty
                    ? 0
                    : draftData.content.trim().split(RegExp(r'\s+')).length,
              ),
            );
          } catch (e) {
            debugPrint('Error parsing draft from key $key: $e');
          }
        }
      }
      drafts.sort(
        (final a, final b) => b.lastModified.compareTo(a.lastModified),
      );
      return drafts;
    } catch (e) {
      debugPrint('Error getting all drafts: $e');
      return [];
    }
  }

  static Future<void> clearAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (final key) => key.startsWith(_keyPrefix),
      );

      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing all drafts: $e');
    }
  }

  static Future<bool> hasDraft(final int promptId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$promptId';
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('Error checking draft existence: $e');
      return false;
    }
  }

  static Future<int?> getDraftAge(final int promptId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$promptId';
      final draftJson = prefs.getString(key);

      if (draftJson == null) {
        return null;
      }

      final draftData = WritingDraft.fromJson(
        jsonDecode(draftJson) as Map<String, dynamic>,
      );

      final draftDate = DateTime.fromMillisecondsSinceEpoch(
        draftData.timestamp,
      );
      return DateTime.now().difference(draftDate).inHours;
    } catch (e) {
      debugPrint('Error getting draft age: $e');
      return null;
    }
  }

  static void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }
}

@freezed
abstract class WritingDraft with _$WritingDraft {
  const factory WritingDraft({
    required final String content,
    required final int timestamp,
    required final int promptId,
  }) = _WritingDraft;

  factory WritingDraft.fromJson(final Map<String, dynamic> json) =>
      _$WritingDraftFromJson(json);
}

@freezed
abstract class DraftInfo with _$DraftInfo {
  const factory DraftInfo({
    required final int promptId,
    required final String content,
    required final DateTime lastModified,
    required final int wordCount,
  }) = _DraftInfo;
}

extension DraftInfoExtension on DraftInfo {
  String get preview {
    const maxLength = 100;
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }

  String timeAgo(final BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

    if (difference.inDays > 0) {
      final days = difference.inDays;
      final dayText = days == 1 ? context.t.common.day : context.t.common.days;
      return '$days $dayText ${context.t.common.ago}';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      final hourText = hours == 1
          ? context.t.common.hour
          : context.t.common.hours;
      return '$hours $hourText ${context.t.common.ago}';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      final minuteText = minutes == 1
          ? context.t.common.minute
          : context.t.common.minutes;
      return '$minutes $minuteText ${context.t.common.ago}';
    } else {
      return context.t.common.justNow;
    }
  }
}
