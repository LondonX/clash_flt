import 'package:json_annotation/json_annotation.dart';

part 'proxy.g.dart';

@JsonSerializable()
class Proxy {
  final String name;
  final String type;
  final String server;
  Duration? delay;
  Proxy({
    required this.name,
    required this.type,
    required this.server,
    this.delay,
  });

  factory Proxy.fromJson(Map<String, dynamic> json) {
    return _$ProxyFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ProxyToJson(this);
  }

  @override
  String toString() {
    return 'Proxy(name: $name, type: $type, server: $server, delay: $delay)';
  }

  String get uniqueKey => "n:${name}t:${type}s:$server";
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
