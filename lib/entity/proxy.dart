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

  @override
  bool operator ==(covariant Proxy other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.type == type &&
        other.delay == delay;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        title.hashCode ^
        subtitle.hashCode ^
        type.hashCode ^
        delay.hashCode;
  }
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
