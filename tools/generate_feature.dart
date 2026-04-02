import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tools/generate_feature.dart <feature_name>');
    exit(1);
  }

  final featureName = args.first.toLowerCase();
  final pascalName = featureName[0].toUpperCase() + featureName.substring(1);

  final baseDir = 'lib/features/$featureName';
  
  // 1. Create Structure
  print('Creating directory structure...');
  Directory('$baseDir/data').createSync(recursive: true);
  Directory('$baseDir/domain/models').createSync(recursive: true);
  Directory('$baseDir/presentation').createSync(recursive: true);

  // 2. Write Files
  print('Generating boilerplate files...');
  _writeModel(baseDir, featureName, pascalName);
  _writeRepositoryInterface(baseDir, featureName, pascalName);
  _writeApiService(baseDir, featureName, pascalName);
  _writeRepositoryImpl(baseDir, featureName, pascalName);
  _writeScreen(baseDir, featureName, pascalName);

  // 3. Inject DI
  print('Injecting into Dependency Injection (get_it)...');
  await _injectIntoDI(featureName, pascalName);

  // 4. Inject Router
  print('Injecting into Router (GoRouter)...');
  await _injectIntoRouter(featureName, pascalName);

  print('✅ Feature "$pascalName" successfully generated!');
}

void _writeModel(String base, String name, String pascal) {
  File('$base/domain/models/$name.dart').writeAsStringSync('''
class $pascal {
  const $pascal({required this.id});

  final String id;

  factory $pascal.fromJson(Map<String, dynamic> json) {
    return $pascal(
      id: json['id'] as String,
    );
  }
}
''');
}

void _writeRepositoryInterface(String base, String name, String pascal) {
  File('$base/domain/${name}_repository.dart').writeAsStringSync('''
import 'models/$name.dart';

abstract class ${pascal}Repository {
  Future<List<$pascal>> getItems({required int page, int? limit});
}
''');
}

void _writeApiService(String base, String name, String pascal) {
  File('$base/data/${name}_api_service.dart').writeAsStringSync('''
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/network/api_result.dart';
import '../../../data/network/base_api_service.dart';
import '../domain/models/$name.dart';

class ${pascal}ApiService extends BaseApiService {
  ${pascal}ApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ApiResult<List<$pascal>>> getItems({
    required int page,
    int? limit,
  }) {
    return request<List<$pascal>>(
      call: _dio.get(
        '/\${name}s', // Change according to your API
        queryParameters: {
          '_page': page,
          '_limit': limit,
        },
      ),
      mapper: (data) {
        final list = data as List<dynamic>;
        return list.map((json) => $pascal.fromJson(json as Map<String, dynamic>)).toList();
      },
    );
  }
}
''');
}

void _writeRepositoryImpl(String base, String name, String pascal) {
  File('$base/data/${name}_repository_impl.dart').writeAsStringSync('''
import '../../../core/error/failure.dart';
import '../domain/${name}_repository.dart';
import '../domain/models/$name.dart';
import '${name}_api_service.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  ${pascal}RepositoryImpl({required ${pascal}ApiService apiService})
      : _apiService = apiService;

  final ${pascal}ApiService _apiService;

  @override
  Future<List<$pascal>> getItems({required int page, int? limit}) async {
    final result = await _apiService.getItems(page: page, limit: limit);

    return result.when(
      success: (data) => data,
      failure: (message, statusCode) => throw NetworkFailure(message: message),
    );
  }
}
''');
}

void _writeScreen(String base, String name, String pascal) {
  File('$base/presentation/${name}_screen.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../domain/${name}_repository.dart';
import '../domain/models/$name.dart';

// 1. Local State
class ${pascal}State {
  const ${pascal}State({
    this.items = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<$pascal> items;
  final bool isLoading;
  final String? errorMessage;
}

// 2. Notifier
final ${name}Provider = AsyncNotifierProvider<${pascal}Notifier, ${pascal}State>(${pascal}Notifier.new);

class ${pascal}Notifier extends AsyncNotifier<${pascal}State> {
  late final ${pascal}Repository _repository;

  @override
  Future<${pascal}State> build() async {
    _repository = getIt<${pascal}Repository>();
    return _loadData();
  }

  Future<${pascal}State> _loadData() async {
    try {
      final items = await _repository.getItems(page: 1);
      return ${pascal}State(items: items, isLoading: false);
    } catch (e) {
      return ${pascal}State(isLoading: false, errorMessage: e.toString());
    }
  }
}

// 3. UI Screen
class ${pascal}Screen extends ConsumerWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${name}Provider);

    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: state.when(
        data: (data) {
          if (data.isLoading) return const Center(child: CircularProgressIndicator());
          if (data.errorMessage != null) return Center(child: Text(data.errorMessage!));
          
          return ListView.builder(
            itemCount: data.items.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Item \${data.items[index].id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: \$err')),
      ),
    );
  }
}
''');
}

Future<void> _injectIntoDI(String name, String pascal) async {
  final file = File('lib/core/di/injection.dart');
  var content = await file.readAsString();

  // Inject Import
  final importMarker = '// [GENERATED_IMPORTS_INJECTION]';
  final importCode = '''
import '../../features/$name/data/${name}_api_service.dart';
import '../../features/$name/data/${name}_repository_impl.dart';
import '../../features/$name/domain/${name}_repository.dart';
$importMarker''';
  content = content.replaceFirst(importMarker, importCode);

  // Inject Dependency
  final depMarker = '// [GENERATED_DEPENDENCIES_INJECTION]';
  final depCode = '''
  // ── Feature: $pascal ──
  getIt.registerLazySingleton<${pascal}ApiService>(
    () => ${pascal}ApiService(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<${pascal}Repository>(
    () => ${pascal}RepositoryImpl(apiService: getIt<${pascal}ApiService>()),
  );

  $depMarker''';
  content = content.replaceFirst(depMarker, depCode);

  await file.writeAsString(content);
}

Future<void> _injectIntoRouter(String name, String pascal) async {
  final file = File('lib/core/router/app_router.dart');
  var content = await file.readAsString();

  // Inject Import
  final importMarker = '// [GENERATED_IMPORTS_ROUTER]';
  final importCode = '''
import '../../features/$name/presentation/${name}_screen.dart';
$importMarker''';
  content = content.replaceFirst(importMarker, importCode);

  // Inject Route
  final routeMarker = '// [GENERATED_ROUTES_ROUTER]';
  final routeCode = '''
      GoRoute(
        path: '/$name',
        name: '$name',
        builder: (context, state) => const ${pascal}Screen(),
      ),
      $routeMarker''';
  content = content.replaceFirst(routeMarker, routeCode);

  await file.writeAsString(content);
}
