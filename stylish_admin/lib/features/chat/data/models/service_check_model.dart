import 'package:stylish_admin/features/chat/domain/entities/service_check_entity.dart';

class ServiceCheckModel extends ServiceCheckEntity {
  const ServiceCheckModel({
    required super.serviceName,
    required super.status,
    required super.responseTime,
    required super.timestamp,
    super.error,
    super.metadata,
  });

  factory ServiceCheckModel.fromJson(Map<String, dynamic> json) {
    return ServiceCheckModel(
      serviceName: json['service_name'] as String? ?? 'unknown',
      status: _parseStatus(json['status'] as String?),
      responseTime: (json['response_time'] as num?)?.toDouble() ?? 0.0,
      timestamp: _parseTimestamp(json['timestamp']),
      error: json['error'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Parse status string to enum
  static ServiceStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'healthy':
        return ServiceStatus.healthy;
      case 'degraded':
        return ServiceStatus.degraded;
      case 'unhealthy':
        return ServiceStatus.unhealthy;
      default:
        return ServiceStatus.unknown;
    }
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
}
