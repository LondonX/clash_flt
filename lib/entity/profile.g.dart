// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
      filePath: json['file-path'] as String,
      port: json['port'] as int,
      socksPort: json['socks-port'] as int,
      allowLan: json['allow-lan'] as bool?,
      mode: json['mode'] as String,
      logLevel: json['log-level'] as String,
      externalController: json['external-controller'] as String?,
      proxies: (json['proxies'] as List<dynamic>)
          .map((e) => Proxy.fromJson(e as Map<String, dynamic>))
          .toList(),
      proxyGroups: (json['proxy-groups'] as List<dynamic>)
          .map((e) => ProxyGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      rules: (json['rules'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'file-path': instance.filePath,
      'port': instance.port,
      'socks-port': instance.socksPort,
      'allow-lan': instance.allowLan,
      'mode': instance.mode,
      'log-level': instance.logLevel,
      'external-controller': instance.externalController,
      'proxies': instance.proxies,
      'proxy-groups': instance.proxyGroups,
      'rules': instance.rules,
    };
