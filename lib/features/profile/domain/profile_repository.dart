import 'models/profile.dart';

abstract class ProfileRepository {
  Future<List<Profile>> getItems({required int page, int? limit});
}
