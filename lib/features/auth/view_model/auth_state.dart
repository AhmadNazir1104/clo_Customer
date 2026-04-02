abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class OtpSent extends AuthState {
  final String phoneNumber;
  final String verificationId;
  const OtpSent({required this.phoneNumber, required this.verificationId});
}

/// OTP verified — new user, needs profile setup
class AuthNewUser extends AuthState {
  final String uid;
  final String phoneNumber;
  const AuthNewUser({required this.uid, required this.phoneNumber});
}

/// OTP verified — existing user, go to home
class AuthExistingUser extends AuthState {
  final String uid;
  const AuthExistingUser({required this.uid});
}

/// Profile saved successfully (new user setup complete)
class AccountSetupSuccess extends AuthState {
  const AccountSetupSuccess();
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
}
