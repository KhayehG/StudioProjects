import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

class XpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> awardXp(String userId, int amount) async {
    try {
      if (amount <= 0) {
        return;
      }

      final DocumentReference<Map<String, dynamic>> userRef =
          _db.collection('users').doc(userId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await userRef.get();
      final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};

      final int currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final String previousLevel =
          (data['currentLevel'] as String?)?.toLowerCase().trim() ?? 'beginner';
      final String selectedLanguage =
          (data['selectedLanguage'] as String?)?.trim().isNotEmpty == true
              ? (data['selectedLanguage'] as String).trim()
              : '';
      final String existingCurrentLanguage =
          (data['currentLanguage'] as String?)?.trim() ?? '';
      final String currentLanguageOut = selectedLanguage.isNotEmpty
          ? selectedLanguage
          : (existingCurrentLanguage.isNotEmpty ? existingCurrentLanguage : 'English');

      final int newXp = currentXp + amount;
      final String newLevel = levelFromXp(newXp);

      final Map<String, dynamic> mergeData = <String, dynamic>{
        'xp': newXp,
        'currentLevel': newLevel,
        'currentLanguage': currentLanguageOut,
      };

      await userRef.set(mergeData, SetOptions(merge: true));

      if (newLevel != previousLevel) {
        final List<String> newBadges = <String>[];
        if (newLevel == 'intermediate' && previousLevel == 'beginner') {
          newBadges.add('Intermediate Achiever');
        } else if (newLevel == 'advanced') {
          if (previousLevel == 'beginner') {
            newBadges.add('Intermediate Achiever');
            newBadges.add('Advanced Scholar');
          } else if (previousLevel == 'intermediate') {
            newBadges.add('Advanced Scholar');
          }
        }
        if (newBadges.isNotEmpty) {
          await userRef.set(
            <String, dynamic>{
              'badgesEarned': FieldValue.arrayUnion(newBadges),
            },
            SetOptions(merge: true),
          );
        }
      }
    } catch (e, st) {
      debugPrint('XpService.awardXp error: $e');
      debugPrint('$st');
    }
  }

  int xpToNextLevel(int currentXp) {
    if (currentXp < AppConstants.xpIntermediateMin) {
      return AppConstants.xpIntermediateMin - currentXp;
    }
    if (currentXp < AppConstants.xpAdvancedMin) {
      return AppConstants.xpAdvancedMin - currentXp;
    }
    return 0;
  }

  String levelFromXp(int xp) {
    if (xp >= AppConstants.xpAdvancedMin) {
      return 'advanced';
    }
    if (xp >= AppConstants.xpIntermediateMin) {
      return 'intermediate';
    }
    return 'beginner';
  }

  bool isLevelUnlocked(int userXp, String difficulty) {
    final String d = difficulty.toLowerCase().trim();
    if (d == 'beginner') {
      return true;
    }
    if (d == 'intermediate') {
      return userXp >= AppConstants.xpIntermediateMin;
    }
    if (d == 'advanced') {
      return userXp >= AppConstants.xpAdvancedMin;
    }
    return false;
  }

  Future<bool> isLessonUnlocked(
    String userId,
    String lessonId,
    String language,
    String difficulty,
    int lessonOrder,
    List<String> completedLessons,
  ) async {
    try {
      if (lessonOrder <= 1) {
        return true;
      }

      final String langNorm = language.trim();
      final String diffNorm = difficulty.toLowerCase().trim();

      final QuerySnapshot<Map<String, dynamic>> prior = await _db
          .collection('lessons')
          .where('language', isEqualTo: langNorm)
          .where('difficulty', isEqualTo: diffNorm)
          .where('order', isLessThan: lessonOrder)
          .orderBy('order')
          .get();

      final Set<String> done = completedLessons.toSet();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in prior.docs) {
        if (!done.contains(doc.id)) {
          return false;
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('XpService.isLessonUnlocked error: $e');
      debugPrint('$st');
      return false;
    }
  }
}
