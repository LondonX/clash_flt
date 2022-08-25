// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FetchStatus _$FetchStatusFromJson(Map<String, dynamic> json) => FetchStatus(
      action: $enumDecode(_$FetchActionEnumMap, json['action']),
      args: (json['args'] as List<dynamic>).map((e) => e as String).toList(),
      progress: json['progress'] as int,
      max: json['max'] as int,
    );

Map<String, dynamic> _$FetchStatusToJson(FetchStatus instance) =>
    <String, dynamic>{
      'action': _$FetchActionEnumMap[instance.action]!,
      'args': instance.args,
      'progress': instance.progress,
      'max': instance.max,
    };

const _$FetchActionEnumMap = {
  FetchAction.fetchConfiguration: 'fetchConfiguration',
  FetchAction.fetchProviders: 'fetchProviders',
  FetchAction.verifying: 'verifying',
};
