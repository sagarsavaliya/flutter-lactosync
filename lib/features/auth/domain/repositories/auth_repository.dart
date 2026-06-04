import '../../domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<void> signupSendOtp({
    required String firstName,
    required String lastName,
    required String mobile,
  });

  Future<String> signupVerifyOtp({required String mobile, required String otp});

  Future<AuthSession> signupComplete({
    required String signupToken,
    required String pin,
  });

  Future<AuthSession> register({
    required String ownerName,
    required String farmName,
    required String mobile,
    required String pin,
  });

  Future<AuthSession> login({required String mobile, required String pin});

  Future<void> sendOtp({required String mobile});

  Future<String> verifyOtp({required String mobile, required String otp});

  Future<void> resetPin({
    required String mobile,
    required String resetToken,
    required String pin,
  });

  Future<void> logout();

  Future<AuthSession?> readStoredSession();
}
