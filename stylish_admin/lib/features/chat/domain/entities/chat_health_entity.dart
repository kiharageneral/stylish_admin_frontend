import 'package:equatable/equatable.dart';

class ChatHealthEntity extends Equatable {
  final String status;
  final DateTime timestamp;
  final String version;
  final Map<String, dynamic> checks;
  final int? activeSessions;

  const ChatHealthEntity({
    required this.status,
    required this.timestamp,
    required this.version,
    required this.checks,
    this.activeSessions,
  });

  bool get isHealthy => status.toLowerCase() == 'healthy';
  @override
  List<Object?> get props => [
    status,
    timestamp,
    version,
    checks,
    activeSessions,
  ];
}
