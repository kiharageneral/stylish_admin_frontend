import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/exceptions.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/network/network_info.dart';
import 'package:stylish_admin/features/chat/data/datasources/chat_remoted_datasource.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_analytics_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_feedback_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_health_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_response_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_session_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_message_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_session_entity.dart';
import 'package:stylish_admin/features/chat/domain/repository/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });
  @override
  Future<Either<Failure, void>> clearSessionMessages(String sessionId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.clearSessionMessages(sessionId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ChatSessionEntity>> createSession({
    Map<String, dynamic>? context,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final session = await remoteDataSource.createSession(context: context);
        return Right(session);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ChatAnalyticsEntity>> getAnalytics({
    int days = 30,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAnalytics(days: days);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ChatHealthEntity>> getHealthStatus() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getHealthStatus();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, PaginatedMessageEntity>> getSessionMessages(
    String sessionId, {
    required int page,
    required int pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSessionMessages(
          sessionId,
          page: page,
          pageSize: pageSize,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, PaginatedSessionEntity>> getSessions({
    required int page,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final sessions = await remoteDataSource.getSessions(page: page);
        return Right(sessions);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendFeeback(ChatFeedbackEntity feedback) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendFeedback(feedback);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ChatResponseEntity>> sendQuery(
    String query, {
    String? sessionId,
    Map<String, dynamic>? context,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.sendQuery(
          query,
          sessionId: sessionId,
          context: context,
        );
        return Right(response);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(
          ServerFailure(message: 'Unexpected error: ${e.toString()}'),
        );
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
