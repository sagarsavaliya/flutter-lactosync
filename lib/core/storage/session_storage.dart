import 'dart:convert';



import 'package:shared_preferences/shared_preferences.dart';



import '../../features/auth/domain/entities/auth_session.dart';



class SessionStorage {

  SessionStorage(this._prefs);



  static const _sessionKey = 'auth_session';



  final SharedPreferences _prefs;



  Future<void> saveSession(AuthSession session) async {

    await _prefs.setString(_sessionKey, jsonEncode({

      'token': session.token,

      'ownerName': session.ownerName,

      'firstName': session.firstName,

      'lastName': session.lastName,

      'mobile': session.mobile,

      'farmId': session.farmId,

      'farmName': session.farmName,

      'onboarding': {

        'current_step': session.onboarding.currentStep,

        'route': session.onboarding.route,

        'is_completed': session.onboarding.isCompleted,

        'checklist': session.onboarding.checklist,

      },

    }));

  }



  Future<AuthSession?> readSession() async {

    final raw = _prefs.getString(_sessionKey);

    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;

    return AuthSession(

      token: map['token'] as String,

      ownerName: map['ownerName'] as String,

      firstName: map['firstName'] as String? ?? '',

      lastName: map['lastName'] as String? ?? '',

      mobile: map['mobile'] as String,

      farmId: map['farmId'] as int,

      farmName: map['farmName'] as String? ?? '',

      onboarding: OnboardingState.fromJson(

        Map<String, dynamic>.from(map['onboarding'] as Map? ?? {}),

      ),

    );

  }



  Future<void> clearSession() async {

    await _prefs.remove(_sessionKey);

  }

}


