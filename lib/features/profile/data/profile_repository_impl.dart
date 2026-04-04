import '../../../core/error/failure.dart';
import '../domain/profile_repository.dart';
import '../domain/models/profile.dart';
import 'profile_api_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ProfileApiService apiService})
      : _apiService = apiService;

  final ProfileApiService _apiService;

  @override
  Future<List<Profile>> getItems({required int page, int? limit}) async {
    final result = await _apiService.getItems(page: page, limit: limit);

    return result.when(
      success: (data) => data,
      failure: (message, statusCode) => throw NetworkFailure(message: message),
    );
  }
}
