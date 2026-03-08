/// Generic paginated response DTO.
///
/// Maps a paginated API response like:
/// ```json
/// {
///   "data": [...],
///   "page": 1,
///   "total_pages": 10,
///   "total_items": 200
/// }
/// ```
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.page,
    required this.totalPages,
    required this.totalItems,
  });

  final List<T> data;
  final int page;
  final int totalPages;
  final int totalItems;

  bool get hasMore => page < totalPages;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      data: (json['data'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalItems: json['total_items'] as int? ?? 0,
    );
  }
}
