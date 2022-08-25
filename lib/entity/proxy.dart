import 'package:json_annotation/json_annotation.dart';

part 'proxy.g.dart';

@JsonSerializable()
class Proxy {
  final String name;
  final String title;
  final String subtitle;
  final ProxyType type;
  final int delay;
  Proxy({
    required this.name,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.delay,
  });

  factory Proxy.fromJson(Map<String, dynamic> json) {
    return _$ProxyFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ProxyToJson(this);
  }

  @override
  String toString() {
    return 'Proxy(name: $name, title: $title, subtitle: $subtitle, type: $type, delay: $delay)';
  }

  String get uniqueKey => "n:${name}t:${title}st:${subtitle}ty:${type.name}";
}

enum ProxyType {
  direct,
  reject,

  shadowsocks,
  shadowsocksR,
  snell,
  socks5,
  http,
  vmess,
  trojan,

  relay,
  selector,
  fallback,
  uRLTest,
  loadBalance,

  unknown,
}
