// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyGroup _$ProxyGroupFromJson(Map<String, dynamic> json) => ProxyGroup(
      name: json['name'] as String,
      type: json['type'] as String,
      proxies:
          (json['proxies'] as List<dynamic>).map((e) => e as String).toList(),
      url: json['url'] as String?,
      interval: json['interval'] as int?,
    );

Map<String, dynamic> _$ProxyGroupToJson(ProxyGroup instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'proxies': instance.proxies,
      'url': instance.url,
      'interval': instance.interval,
    };
