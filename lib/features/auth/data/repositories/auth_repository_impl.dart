import 'package:dio/dio.dart';



import '../../../../core/network/api_exception.dart';

import '../../../../core/storage/session_storage.dart';

import '../../../../core/storage/token_storage.dart';

import '../../domain/entities/auth_session.dart';

import '../../domain/repositories/auth_repository.dart';



class AuthRepositoryImpl implements AuthRepository {

  AuthRepositoryImpl(this._dio, this._tokenStorage, this._sessionStorage);



  final Dio _dio;

  final TokenStorage _tokenStorage;

  final SessionStorage _sessionStorage;



  @override

  Future<void> signupSendOtp({

    required String firstName,

    required String lastName,

    required String mobile,

  }) async {

    await _dio.post<Map<String, dynamic>>(

      '/auth/signup/send-otp',

      data: {

        'first_name': firstName,

        'last_name': lastName,

        'mobile': mobile,

      },

    );

  }



  @override

  Future<String> signupVerifyOtp({

    required String mobile,

    required String otp,

  }) async {

    final response = await _dio.post<Map<String, dynamic>>(

      '/auth/signup/verify-otp',

      data: {'mobile': mobile, 'otp': otp},

    );

    final data = _readData(response.data);

    return data['signup_token'] as String;

  }



  @override

  Future<AuthSession> signupComplete({

    required String signupToken,

    required String pin,

  }) async {

    final response = await _dio.post<Map<String, dynamic>>(

      '/auth/signup/complete',

      data: {

        'signup_token': signupToken,

        'pin': pin,

        'pin_confirmation': pin,

      },

    );

    return _persistSession(response.data);

  }



  @override

  Future<AuthSession> register({

    required String ownerName,

    required String farmName,

    required String mobile,

    required String pin,

  }) async {

    final response = await _dio.post<Map<String, dynamic>>(

      '/auth/register',

      data: {

        'owner_name': ownerName,

        'farm_name': farmName,

        'mobile': mobile,

        'pin': pin,

        'pin_confirmation': pin,

      },

    );

    return _persistSession(response.data);

  }



  @override

  Future<AuthSession> login({required String mobile, required String pin}) async {

    final response = await _dio.post<Map<String, dynamic>>(

      '/auth/login',

      data: {'mobile': mobile, 'pin': pin},

    );

    return _persistSession(response.data);

  }



  @override

  Future<void> sendOtp({required String mobile}) async {

    await _dio.post<Map<String, dynamic>>(

      '/auth/forgot-pin/send-otp',

      data: {'mobile': mobile},

    );

  }



  @override

  Future<String> verifyOtp({required String mobile, required String otp}) async {

    final response = await _dio.post<Map<String, dynamic>>(

      '/auth/forgot-pin/verify-otp',

      data: {'mobile': mobile, 'otp': otp},

    );

    final data = _readData(response.data);

    return data['reset_token'] as String;

  }



  @override

  Future<void> resetPin({

    required String mobile,

    required String resetToken,

    required String pin,

  }) async {

    await _dio.post<Map<String, dynamic>>(

      '/auth/forgot-pin/reset',

      data: {

        'mobile': mobile,

        'reset_token': resetToken,

        'pin': pin,

        'pin_confirmation': pin,

      },

    );

  }



  @override

  Future<void> logout() async {

    await _tokenStorage.clearToken();

    await _sessionStorage.clearSession();

  }



  @override

  Future<AuthSession?> readStoredSession() => _sessionStorage.readSession();



  Future<AuthSession> persistSessionFromResponse(Map<String, dynamic>? body) =>

      _persistSession(body);



  Future<AuthSession> _persistSession(Map<String, dynamic>? body) async {

    final data = _readData(body);

    final token = data['token'] as String;

    final session = _sessionFromData(data, token);

    await _tokenStorage.saveToken(token);

    await _sessionStorage.saveSession(session);

    return session;

  }



  Map<String, dynamic> _readData(Map<String, dynamic>? body) {

    if (body == null || body['success'] != true) {

      throw ApiException('API_ERROR', 'Unexpected server response.');

    }

    return Map<String, dynamic>.from(body['data'] as Map);

  }



  AuthSession _sessionFromData(Map<String, dynamic> data, String token) {

    final owner = Map<String, dynamic>.from(data['owner'] as Map);

    final farm = Map<String, dynamic>.from(data['farm'] as Map);

    final onboardingRaw = Map<String, dynamic>.from(

      data['onboarding'] as Map? ?? {},

    );



    final firstName = owner['first_name'] as String? ?? '';

    final lastName = owner['last_name'] as String? ?? '';

    final ownerName = owner['name'] as String? ?? '$firstName $lastName'.trim();



    return AuthSession(

      token: token,

      ownerName: ownerName,

      firstName: firstName,

      lastName: lastName,

      mobile: owner['mobile'] as String,

      farmId: farm['id'] as int,

      farmName: farm['name'] as String? ?? '',

      onboarding: OnboardingState.fromJson({
        ...onboardingRaw,
        'route': onboardingRaw['route'] ??
            _routeForStep(onboardingRaw['current_step'] as String? ?? 'farm_profile'),
      }),
    );
  }

  String _routeForStep(String step) {
    return switch (step) {
      'farm_profile' => '/onboarding/farm',
      'products_setup' => '/onboarding/products',
      'first_customer' => '/onboarding/customer',
      'first_subscription' => '/onboarding/dashboard',
      'completed' => '/owner/home',
      _ => '/onboarding/farm',
    };
  }
}


