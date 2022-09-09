// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Proxy _$ProxyFromJson(Map<String, dynamic> json) => Proxy(
      name: json['name'] as String,
      type: json['type'] as String,
      server: json['server'] as String,
      delay: json['delay'] as int?,
    );

Map<String, dynamic> _$ProxyToJson(Proxy instance) => <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'server': instance.server,
      'delay': instance.delay,
    };
