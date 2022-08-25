import 'package:json_annotation/json_annotation.dart';

part 'log_mesage.g.dart';

@JsonSerializable()
class LogMessage {
  final LogMessageLevel level;
  final String message;
  final int time;
  LogMessage({
    required this.level,
    required this.message,
    required this.time,
  });

  factory LogMessage.fromJson(Map<String, dynamic> json) {
    return _$LogMessageFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$LogMessageToJson(this);
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);
}

enum LogMessageLevel {
  debug,
  info,
  warning,
  error,
  silent,
  unknown,
}
