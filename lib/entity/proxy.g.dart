// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Proxy _$ProxyFromJson(Map<String, dynamic> json) => Proxy(
      name: json['name'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      type: $enumDecode(_$ProxyTypeEnumMap, json['type']),
      delay: json['delay'] as int,
    );

Map<String, dynamic> _$ProxyToJson(Proxy instance) => <String, dynamic>{
      'name': instance.name,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'type': _$ProxyTypeEnumMap[instance.type]!,
      'delay': instance.delay,
    };

const _$ProxyTypeEnumMap = {
  ProxyType.direct: 'direct',
  ProxyType.reject: 'reject',
  ProxyType.shadowsocks: 'shadowsocks',
  ProxyType.shadowsocksR: 'shadowsocksR',
  ProxyType.snell: 'snell',
  ProxyType.socks5: 'socks5',
  ProxyType.http: 'http',
  ProxyType.vmess: 'vmess',
  ProxyType.trojan: 'trojan',
  ProxyType.relay: 'relay',
  ProxyType.selector: 'selector',
  ProxyType.fallback: 'fallback',
  ProxyType.uRLTest: 'uRLTest',
  ProxyType.loadBalance: 'loadBalance',
  ProxyType.unknown: 'unknown',
};
