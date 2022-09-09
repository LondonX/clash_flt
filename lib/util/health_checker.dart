import 'dart:isolate';

import 'package:dart_ping/dart_ping.dart';

import '../entity/proxy.dart';

class HealthChecker {
  static Future<void> healthCheckAll(List<Proxy> proxies) async {
    final resultPort = ReceivePort();
    Isolate.spawn<_HealthCheck>(
      _healthCheckAll,
      _HealthCheck(
        proxies: proxies,
        sendPort: resultPort.sendPort,
      ),
    );
    final results = List<Duration?>.from(await resultPort.first);
    for (var i = 0; i < proxies.length; i++) {
      proxies[i].delay = results[i];
    }
  }

  static Future<void> healthCheck(Proxy proxy) async {
    await _healthCheck(proxy);
  }
}

Future<void> _healthCheckAll(_HealthCheck healthCheckAll) async {
  final proxies = healthCheckAll.proxies;
  final results = await Future.wait(
    proxies.map((e) => _healthCheck(e)).toList(),
  );
  healthCheckAll.sendPort.send(results);
}

Future<Duration?> _healthCheck(Proxy proxy) async {
  try {
    final pingData =
        await Ping(proxy.server, count: 1, timeout: 3).stream.first;
    proxy.delay = pingData.response?.time;
    return proxy.delay;
  } catch (_) {}
  return null;
}

class _HealthCheck {
  final List<Proxy> proxies;
  final SendPort sendPort;
  const _HealthCheck({
    required this.proxies,
    required this.sendPort,
  });
}
