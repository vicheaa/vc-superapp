import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../domain/models/profile.dart';
import '../domain/profile_repository.dart';

// 1. Local State
class ProfileState {
  const ProfileState({
    this.items = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<Profile> items;
  final bool isLoading;
  final String? errorMessage;
}

// 2. Notifier
final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  late final ProfileRepository _repository;

  @override
  Future<ProfileState> build() async {
    _repository = getIt<ProfileRepository>();
    return _loadData();
  }

  Future<ProfileState> _loadData() async {
    try {
      final items = await _repository.getItems(page: 1);
      return ProfileState(items: items, isLoading: false);
    } catch (e) {
      return ProfileState(isLoading: false, errorMessage: e.toString());
    }
  }
}
