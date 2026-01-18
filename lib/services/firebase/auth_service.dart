import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  // placeholder for auth methods
  String? get currentUserId => null;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
