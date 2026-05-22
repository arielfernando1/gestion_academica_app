class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  String? _userEmail;

  String? get userEmail => _userEmail;
  bool get isLoggedIn => _userEmail != null;

  void login(String email) => _userEmail = email;

  void logout() => _userEmail = null;
}
