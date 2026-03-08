import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.body,
    this.userId,
  });

  final int id;
  final String title;
  final String body;

  @JsonKey(name: 'user_id')
  final int? userId;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}
