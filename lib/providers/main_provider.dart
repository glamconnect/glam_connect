import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/services/auth_service.dart';

class MainProviderState {
  final bool isLoading;
  final bool isUserLoggedIn;
  final UserModel? currentUser;
  final int selectedMainPageIndex;

  MainProviderState({
    this.isLoading = true,
    this.isUserLoggedIn = false,
    this.currentUser,
    this.selectedMainPageIndex = 0,
  });

  MainProviderState copyWith({
    bool? isLoading,
    bool? isUserLoggedIn,
    UserModel? currentUser,
    int? selectedMainPageIndex,
  }) {
    return MainProviderState(
      isLoading: isLoading ?? this.isLoading,
      isUserLoggedIn: isUserLoggedIn ?? this.isUserLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      selectedMainPageIndex: selectedMainPageIndex ?? this.selectedMainPageIndex,
    );
  }
}

class MainProviderNotifier extends StateNotifier<MainProviderState> {
  final AuthService _authService;

  MainProviderNotifier(this._authService) : super(MainProviderState()) {
    // Check if user is logged in when provider is initialized
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await getIfUserLoggedIn();
    setIsLoading(false);
  }

  Future<void> getIfUserLoggedIn() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      state = state.copyWith(
        isUserLoggedIn: true,
        currentUser: currentUser,
      );
    } else {
      state = state.copyWith(
        isUserLoggedIn: false,
        currentUser: null,
      );
    }
  }

  void setIsLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setSelectedPage(int index) {
    state = state.copyWith(selectedMainPageIndex: index);
  }

  Future<void> logout() async {
    await _authService.signOut();
    state = state.copyWith(
      isUserLoggedIn: false,
      currentUser: null,
      selectedMainPageIndex: 0,
    );
  }
}

final mainProvider = StateNotifierProvider<MainProviderNotifier, MainProviderState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return MainProviderNotifier(authService);
});
