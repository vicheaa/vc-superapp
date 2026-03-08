// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  body: json['body'] as String,
  userId: (json['user_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'user_id': instance.userId,
};
