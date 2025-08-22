import 'package:stylish_admin/features/chat/data/models/service_check_model.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_health_entity.dart';

class ChatHealthModel extends ChatHealthEntity {
  const ChatHealthModel({
    required super.status,
    required super.timestamp,
    required super.version,
    required super.checks,
    super.activeSessions,
  });

  factory ChatHealthModel.fromJson(Map<String, dynamic> json) {
    return ChatHealthModel(
      status: json['status'] as String? ?? 'unknown',
      timestamp: _parseTimestamp(json['timestamp']),
      version: json['version'] as String? ?? '1.0.0',
      checks: _parseChecks(json['checks']),
      activeSessions: json['active_sessions'] as int?,
    );
  }

  /// Parse timestamp from various formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (timestamp is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Parse service checks from JSON
  static Map<String, dynamic> _parseChecks(dynamic checks) {
    if (checks == null) return {};

    if (checks is Map<String, dynamic>) {
      final parsedChecks = <String, dynamic>{};

      for (final entry in checks.entries) {
        final checkData = entry.value;

        if (checkData is Map<String, dynamic> &&
            checkData.containsKey('status') &&
            checkData.containsKey('response_time')) {
          try {
            parsedChecks[entry.key] = ServiceCheckModel.fromJson({
              'service_name': entry.key,
              ...checkData,
            });
          } catch (e) {
            parsedChecks[entry.key] = checkData;
          }
        } else {
          parsedChecks[entry.key] = checkData;
        }
      }
      return parsedChecks;
    }
    return {};
  }
}
