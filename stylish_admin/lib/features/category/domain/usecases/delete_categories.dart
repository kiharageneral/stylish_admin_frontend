
import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/category/domain/repositories/category_repository.dart';

class DeleteCategory implements UseCase<void, String> {
  final CategoryRepository repository;

  DeleteCategory(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteCategory(id);
  }
}