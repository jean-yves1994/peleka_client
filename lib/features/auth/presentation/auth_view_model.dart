import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/storage/onboarding_prefs.dart';
import '../domain/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool loading;
  final bool onboardingSeen;
  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.loading = false,
    this.onboardingSeen = false,
  });
  AuthState copyWith({AuthStatus? status, User? user, String? error, bool? loading, bool? onboardingSeen}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        loading: loading ?? false,
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      );
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final OnboardingPrefs _onboarding;
  AuthViewModel(this._repo, this._onboarding) : super(const AuthState(status: AuthStatus.unknown)) {
    bootstrap();
  }

  Future<void> bootstrap() async {
    bool seen = false;
    User? user;
    try {
      seen = await _onboarding.seen().timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      user = await _repo.currentUser().timeout(const Duration(seconds: 3));
    } catch (_) {}
    state = AuthState(
      status: user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user,
      onboardingSeen: seen,
    );
  }

  Future<bool> login({String? email, String? phone, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final u = await _repo.login(email: email, phone: phone, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: u, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString().replaceAll('ApiException: ', ''));
      return false;
    }
  }

  Future<bool> register({String? email, String? phone, required String password, required String fullName}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final u = await _repo.register(email: email, phone: phone, password: password, fullName: fullName);
      state = state.copyWith(status: AuthStatus.authenticated, user: u, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString().replaceAll('ApiException: ', ''));
      return false;
    }
  }

  Future<void> markOnboardingSeen() async {
    await _onboarding.markSeen();
    state = state.copyWith(onboardingSeen: true);
  }

  Future<void> logout() async {
    await _repo.logout();
    // Flip to unauthenticated → the router's redirect moves the user to /login.
    // Keep onboardingSeen = true so logout lands on /login, not onboarding.
    state = const AuthState(status: AuthStatus.unauthenticated, onboardingSeen: true);
  }

  Future<void> refreshProfile(User u) async {
    state = state.copyWith(user: u, status: AuthStatus.authenticated);
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) =>
    AuthViewModel(ref.watch(authRepositoryProvider), ref.watch(onboardingPrefsProvider)));
