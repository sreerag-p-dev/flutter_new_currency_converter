abstract class AuthEvent {}

class LoginWithEmail extends AuthEvent {
  final String email;
  final String password;

  LoginWithEmail(this.email, this.password);
}

class SignUpWithEmail extends AuthEvent {
  final String email;
  final String password;

  SignUpWithEmail(this.email, this.password);
}

class LoginWithGoogle extends AuthEvent {}

class ForgotPassword extends AuthEvent {
  final String email;

  ForgotPassword(this.email);
}
