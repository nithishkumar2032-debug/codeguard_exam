/// Result returned from server-authoritative candidate response persistence.
class SaveResponseResult {
  final bool success;
  final String? status;
  final String? message;
  final DateTime? serverTime;

  const SaveResponseResult({
    required this.success,
    this.status,
    this.message,
    this.serverTime,
  });

  factory SaveResponseResult.fromJson(Map<String, dynamic> json) {
    final serverTimeStr =
        json['serverTime'] as String? ?? json['server_time'] as String?;
    return SaveResponseResult(
      success: json['success'] as bool? ?? false,
      status: json['status'] as String?,
      message: json['message'] as String?,
      serverTime: serverTimeStr != null
          ? DateTime.tryParse(serverTimeStr)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'status': status,
        'message': message,
        'serverTime': serverTime?.toIso8601String(),
      };
}
