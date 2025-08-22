import 'package:equatable/equatable.dart';

enum ServiceStatus {
  healthy,
  degraded,
  unhealthy,
  unknown;

  bool get isOperational =>
      this == ServiceStatus.healthy || this == ServiceStatus.degraded;

  bool get isCritical => this == ServiceStatus.unhealthy;

  String get displayName {
    switch (this) {
      case ServiceStatus.healthy:
        return 'Healthy';

      case ServiceStatus.degraded:
        return 'Degraded';
      case ServiceStatus.unhealthy:
        return 'Unhealthy';
      case ServiceStatus.unknown:
        return 'Unknown';
    }
  }
}

class ServiceCheckEntity extends Equatable {
  final String serviceName;
  final ServiceStatus status;
  final double responseTime;
  final String? error;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ServiceCheckEntity({
    required this.serviceName,
    required this.status,
    required this.responseTime,
    this.error,
    required this.timestamp,
    this.metadata,
  });

  bool get isPassing => status.isOperational;
  bool get isFailing => status.isCritical;

  String get description {
    if (error != null) {
      return 'Service $serviceName is ${status.displayName.toLowerCase()}: $error';
    }
    return 'Service $serviceName is ${status.displayName.toLowerCase()} (${responseTime.toStringAsFixed(2)}ms)';
  }

  ServiceCheckEntity copyWith({
    String? serviceName,
    ServiceStatus? status,
    double? responseTime,
    String? error,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ServiceCheckEntity(
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      responseTime: responseTime ?? this.responseTime,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    serviceName,
    status,
    responseTime,
    error,
    timestamp,
    metadata,
  ];
}
