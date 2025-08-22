
import 'package:equatable/equatable.dart';

class PaginatedResponseEntity<T> extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponseEntity({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

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
  
  @override
  List<Object?> get props => [count, next, previous, results];
}