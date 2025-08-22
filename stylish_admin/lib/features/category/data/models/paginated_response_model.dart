
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: json['results'] != null
          ? List<T>.from(json['results'].map((item) => fromJsonT(item)))
          : [],
    );
  }

  bool get hasNextPage => next != null;
  bool get hasPreviousPage => previous != null;
  
  // Extract page number from URL
  int? get nextPageNumber {
    if (next == null) return null;
    final uri = Uri.parse(next!);
    return int.tryParse(uri.queryParameters['page'] ?? '');
  }
  
  int? get previousPageNumber {
    if (previous == null) return null;
    final uri = Uri.parse(previous!);
    return int.tryParse(uri.queryParameters['page'] ?? '');
  }
}