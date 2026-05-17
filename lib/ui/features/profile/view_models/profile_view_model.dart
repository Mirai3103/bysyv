import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/repositories/user_repository.dart';
import '../../../../domain/models/auth_session.dart';
import '../../../../domain/models/pixiv_creator.dart';
import '../../auth/view_models/auth_controller.dart';

final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((ref) {
  final viewModel = ProfileViewModel(
    authController: ref.watch(authControllerProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
  viewModel.load();
  return viewModel;
});

class ProfileState {
  const ProfileState({
    this.session,
    this.creator,
    this.isLoading = true,
    this.errorMessage,
  });

  final AuthSession? session;
  final PixivCreator? creator;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  ProfileState copyWith({
    AuthSession? session,
    PixivCreator? creator,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      session: session ?? this.session,
      creator: creator ?? this.creator,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required AuthController authController,
    required UserRepository userRepository,
  }) : _authController = authController,
       _userRepository = userRepository;

  final AuthController _authController;
  final UserRepository _userRepository;

  ProfileState _state = const ProfileState();
  ProfileState get state => _state;

  Future<void> load() async {
    final session = _authController.session;
    _state = _state.copyWith(session: session, isLoading: true, clearError: true);
    notifyListeners();

    if (session == null || session.userId.isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'No active Pixiv session.',
      );
      notifyListeners();
      return;
    }

    try {
      final creator = await _userRepository.detail(session.userId);
      _state = _state.copyWith(
        creator: creator,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      _state = _state.copyWith(isLoading: false, clearError: true);
    }

    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> logout() => _authController.logout();
}
