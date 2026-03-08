import 'models/post.dart';

/// Abstract repository contract for Home feature.
abstract class HomeRepository {
  Future<List<Post>> getPosts({required int page, int? limit});
}
