// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_mesage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogMessage _$LogMessageFromJson(Map<String, dynamic> json) => LogMessage(
      level: $enumDecode(_$LogMessageLevelEnumMap, json['level']),
      message: json['message'] as String,
      time: json['time'] as int,
    );

Map<String, dynamic> _$LogMessageToJson(LogMessage instance) =>
    <String, dynamic>{
      'level': _$LogMessageLevelEnumMap[instance.level]!,
      'message': instance.message,
      'time': instance.time,
    };

const _$LogMessageLevelEnumMap = {
  LogMessageLevel.debug: 'debug',
  LogMessageLevel.info: 'info',
  LogMessageLevel.warning: 'warning',
  LogMessageLevel.error: 'error',
  LogMessageLevel.silent: 'silent',
  LogMessageLevel.unknown: 'unknown',
};
